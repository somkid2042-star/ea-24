import { useState, useEffect, useRef, useCallback } from 'react';
import { LuShieldCheck, LuSave, LuCheck, LuOctagon, LuGauge, LuDollarSign, LuLayers, LuTrendingDown, LuCircleCheck, LuCircleX } from 'react-icons/lu';
import { getWsUrl } from '@/utils/config';

const WS_URL = getWsUrl();

const RiskManagement = () => {
  const [_wsConnected, setWsConnected] = useState(false);
  const [maxDailyDrawdown, setMaxDailyDrawdown] = useState('100');
  const [maxTotalLot, setMaxTotalLot] = useState('1.0');
  const [maxPositions, setMaxPositions] = useState('5');
  const [riskStopEnabled, setRiskStopEnabled] = useState(true);
  const [emergencyStop, setEmergencyStop] = useState(false);
  const [saved, setSaved] = useState(false);
  const [currentDrawdown, setCurrentDrawdown] = useState(0);
  const [currentPositions, setCurrentPositions] = useState(0);
  const [currentLotTotal, setCurrentLotTotal] = useState(0);
  const wsRef = useRef<WebSocket | null>(null);

  const connectWs = useCallback(() => {
    const ws = new WebSocket(WS_URL);
    ws.onopen = () => {
      setWsConnected(true);
      ws.send(JSON.stringify({ action: 'get_server_config' }));
    };
    ws.onclose = () => { setWsConnected(false); setTimeout(connectWs, 3000); };
    ws.onmessage = (evt) => {
      try {
        const data = JSON.parse(evt.data);
        if (data.type === 'server_config' && data.config) {
          const c = data.config;
          if (c.max_daily_drawdown) setMaxDailyDrawdown(c.max_daily_drawdown);
          if (c.max_total_lot) setMaxTotalLot(c.max_total_lot);
          if (c.max_positions) setMaxPositions(c.max_positions);
          if (c.risk_stop_enabled !== undefined) setRiskStopEnabled(c.risk_stop_enabled === 'true');
          if (c.emergency_stop !== undefined) setEmergencyStop(c.emergency_stop === 'true');
        }
        if (data.type === 'account_data') {
          const positions = data.positions || [];
          setCurrentPositions(positions.length);
          setCurrentLotTotal(positions.reduce((s: number, p: any) => s + (p.volume || 0), 0));
          const totalPnl = positions.reduce((s: number, p: any) => s + (p.pnl || 0), 0);
          if (totalPnl < 0) setCurrentDrawdown(Math.abs(totalPnl));
        }
        if (data.type === 'config_saved') {
          setSaved(true);
          setTimeout(() => setSaved(false), 2000);
        }
      } catch {}
    };
    wsRef.current = ws;
  }, []);

  useEffect(() => { connectWs(); return () => { wsRef.current?.close(); }; }, [connectWs]);

  const send = (msg: object) => { if (wsRef.current?.readyState === 1) wsRef.current.send(JSON.stringify(msg)); };

  const saveAll = () => {
    send({ action: 'set_server_config', config_key: 'max_daily_drawdown', config_value: maxDailyDrawdown });
    send({ action: 'set_server_config', config_key: 'max_total_lot', config_value: maxTotalLot });
    send({ action: 'set_server_config', config_key: 'max_positions', config_value: maxPositions });
    send({ action: 'set_server_config', config_key: 'risk_stop_enabled', config_value: riskStopEnabled.toString() });
  };

  const toggleEmergencyStop = () => {
    const newVal = !emergencyStop;
    setEmergencyStop(newVal);
    send({ action: 'set_server_config', config_key: 'emergency_stop', config_value: newVal.toString() });
  };

  const ddPercent = parseFloat(maxDailyDrawdown) > 0 ? Math.min(100, (currentDrawdown / parseFloat(maxDailyDrawdown)) * 100) : 0;
  const lotPercent = parseFloat(maxTotalLot) > 0 ? Math.min(100, (currentLotTotal / parseFloat(maxTotalLot)) * 100) : 0;
  const posPercent = parseInt(maxPositions) > 0 ? Math.min(100, (currentPositions / parseInt(maxPositions)) * 100) : 0;

  const gaugeColor = (pct: number) => pct >= 80 ? 'bg-red-500' : pct >= 50 ? 'bg-yellow-500' : 'bg-green-500';

  return (
    <main className="space-y-5">
      <div className="flex items-center justify-between">
        <div>
          <h4 className="text-lg font-semibold text-default-900 flex items-center gap-2"><LuShieldCheck className="size-5 text-primary" /> Risk Management</h4>
          <p className="mt-1 text-sm text-default-500">ตั้งค่าขีดจำกัดเพื่อป้องกันการขาดทุน</p>
        </div>
      </div>

      {/* Emergency Stop */}
      <div className={`card !p-6 border-2 transition-colors ${emergencyStop ? 'border-red-500 bg-red-50/50 dark:bg-red-500/5' : 'border-transparent'}`}>
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className={`size-12 rounded-xl flex items-center justify-center ${emergencyStop ? 'bg-red-500' : 'bg-default-200 dark:bg-default-200/20'}`}>
              <LuOctagon className={`size-6 ${emergencyStop ? 'text-white' : 'text-default-500'}`} />
            </div>
            <div>
              <p className="text-base font-bold text-default-900 flex items-center gap-1.5"><LuOctagon className="size-4 text-red-500" /> Emergency Stop</p>
              <p className="text-xs text-default-500">หยุดเปิดออเดอร์ทุกกลยุทธ์ทันที</p>
            </div>
          </div>
          <button
            onClick={toggleEmergencyStop}
            className={`px-6 py-2.5 rounded-xl text-sm font-bold border-none transition-all ${emergencyStop ? 'bg-green-500 text-white hover:bg-green-600' : 'bg-red-500 text-white hover:bg-red-600'}`}
          >{emergencyStop ? <><LuCircleCheck className="size-4 inline" /> Resume</> : <><LuCircleX className="size-4 inline" /> Stop All</>}</button>
        </div>
      </div>

      {/* Live Risk Gauges */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-5">
        {[
          { label: 'Drawdown วันนี้', current: `$${currentDrawdown.toFixed(2)}`, max: `$${maxDailyDrawdown}`, pct: ddPercent, icon: <LuTrendingDown className="size-4" /> },
          { label: 'Lot รวม', current: `${currentLotTotal.toFixed(2)} lot`, max: `${maxTotalLot} lot`, pct: lotPercent, icon: <LuLayers className="size-4" /> },
          { label: 'จำนวน Position', current: `${currentPositions}`, max: maxPositions, pct: posPercent, icon: <LuGauge className="size-4" /> },
        ].map((g, i) => (
          <div key={i} className="card !p-5">
            <div className="flex items-center justify-between mb-3">
              <span className="text-xs font-medium uppercase tracking-wider text-default-400 flex items-center gap-1.5">{g.icon}{g.label}</span>
              <span className={`text-xs font-bold ${g.pct >= 80 ? 'text-red-500' : g.pct >= 50 ? 'text-yellow-500' : 'text-green-500'}`}>{g.pct.toFixed(0)}%</span>
            </div>
            <p className="text-xl font-bold text-default-900 mb-1">{g.current} <span className="text-xs text-default-400 font-normal">/ {g.max}</span></p>
            <div className="h-2 rounded-full bg-default-100 dark:bg-default-200/10 overflow-hidden">
              <div className={`h-full rounded-full transition-all ${gaugeColor(g.pct)}`} style={{ width: `${g.pct}%` }} />
            </div>
          </div>
        ))}
      </div>

      {/* Settings */}
      <div className="card !p-6">
        <h5 className="text-sm font-semibold text-default-900 mb-4 flex items-center gap-2"><LuShieldCheck className="size-4 text-primary" /> ตั้งค่าขีดจำกัด</h5>
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
          <div>
            <label className="text-xs font-medium text-default-500 mb-1.5 block">Max Drawdown ต่อวัน ($)</label>
            <div className="flex items-center gap-2">
              <LuDollarSign className="size-4 text-default-400" />
              <input type="number" value={maxDailyDrawdown} onChange={(e) => setMaxDailyDrawdown(e.target.value)}
                className="flex-1 px-4 py-2.5 rounded-xl bg-default-100 dark:bg-default-200/10 text-sm text-default-900 border border-default-200 dark:border-default-300/10 focus:outline-none focus:ring-2 focus:ring-primary/30" />
            </div>
          </div>
          <div>
            <label className="text-xs font-medium text-default-500 mb-1.5 block">Max Lot รวม</label>
            <input type="number" step="0.01" value={maxTotalLot} onChange={(e) => setMaxTotalLot(e.target.value)}
              className="w-full px-4 py-2.5 rounded-xl bg-default-100 dark:bg-default-200/10 text-sm text-default-900 border border-default-200 dark:border-default-300/10 focus:outline-none focus:ring-2 focus:ring-primary/30" />
          </div>
          <div>
            <label className="text-xs font-medium text-default-500 mb-1.5 block">Max Position พร้อมกัน</label>
            <input type="number" value={maxPositions} onChange={(e) => setMaxPositions(e.target.value)}
              className="w-full px-4 py-2.5 rounded-xl bg-default-100 dark:bg-default-200/10 text-sm text-default-900 border border-default-200 dark:border-default-300/10 focus:outline-none focus:ring-2 focus:ring-primary/30" />
          </div>
          <div className="flex items-center gap-3 p-3 rounded-xl bg-default-50 dark:bg-default-200/5">
            <div>
              <p className="text-sm font-semibold text-default-900">เปิดใช้ Risk Protection</p>
              <p className="text-xs text-default-500">หยุดเทรดอัตโนมัติเมื่อถึงขีดจำกัด</p>
            </div>
            <button onClick={() => setRiskStopEnabled(!riskStopEnabled)}
              className={`relative w-11 h-6 rounded-full transition-colors ml-auto ${riskStopEnabled ? 'bg-primary' : 'bg-default-300 dark:bg-default-200/30'}`}>
              <span className={`absolute top-0.5 left-0.5 size-5 rounded-full bg-white shadow transition-transform ${riskStopEnabled ? 'translate-x-5' : ''}`} />
            </button>
          </div>
        </div>
      </div>

      <button onClick={saveAll} className="btn w-full py-3 rounded-xl bg-primary text-white hover:bg-primary/90 text-sm font-semibold flex items-center justify-center gap-2 border-none">
        {saved ? <><LuCheck className="size-4" /> บันทึกแล้ว!</> : <><LuSave className="size-4" /> บันทึกการตั้งค่า</>}
      </button>
    </main>
  );
};

export default RiskManagement;
