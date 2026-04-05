import React, { useState, useEffect, useRef, useCallback } from 'react';
import { LuX, LuBot, LuSave, LuClock, LuMessageCircle } from 'react-icons/lu';
import { getWsUrl } from '@/utils/config';

type Position = {
  ticket: number;
  symbol: string;
  type: string;
  volume: number;
  open_price: number;
  current_price: number;
  pnl: number;
  swap: number;
  sl: number;
  tp: number;
  magic: number;
  open_time: string;
  comment: string;
};

const WS_URL = getWsUrl();

const Toggle = ({ checked, onChange }: { checked: boolean; onChange: (v: boolean) => void }) => (
  <button onClick={() => onChange(!checked)} className={`relative inline-flex h-5 w-10 shrink-0 cursor-pointer items-center justify-center rounded-full focus:outline-none transition-colors ${checked ? 'bg-[#229ED9]' : 'bg-default-300 dark:bg-default-200/30'}`}>
    <span className={`pointer-events-none inline-block h-3.5 w-3.5 transform rounded-full shadow ring-0 transition duration-200 ease-in-out bg-white ${checked ? 'translate-x-2.5' : '-translate-x-2.5'}`} />
  </button>
);

const ActiveTrades = () => {
  const [wsConnected, setWsConnected] = useState(false);
  const [positions, setPositions] = useState<Position[]>([]);
  const [closedMap, setClosedMap] = useState<Record<string, boolean>>({});
  
  // AI Advisor States (Per Ticket)
  const [showAiSetupTicket, setShowAiSetupTicket] = useState<number | null>(null);
  const [aiConfigs, setAiConfigs] = useState<Record<number, { enabled: boolean; interval: number; telegram: boolean }>>({});
  
  const wsRef = useRef<WebSocket | null>(null);

  const connectWs = useCallback(() => {
    const ws = new WebSocket(WS_URL);
    ws.onopen = () => {
      setWsConnected(true);
      ws.send(JSON.stringify({ action: 'get_server_config' }));
      ws.send(JSON.stringify({ action: 'get_tracked_symbols' }));
    };
    ws.onclose = () => { setWsConnected(false); setTimeout(connectWs, 3000); };
    ws.onmessage = (evt) => {
      try {
        const data = JSON.parse(evt.data);
        if (data.type === 'account_data') {
          setPositions(data.positions || []);
        }
        if (data.type === 'tracked_symbols' && data.closed_map) {
          setClosedMap(data.closed_map);
        }
        if (data.type === 'server_config' && data.config) {
          const loadedConfigs: Record<number, any> = {};
          
          Object.keys(data.config).forEach(key => {
            if (key.startsWith('ai_trade_care_enabled_')) {
              const ticket = parseInt(key.replace('ai_trade_care_enabled_', ''));
              if (!loadedConfigs[ticket]) loadedConfigs[ticket] = { enabled: false, interval: 15, telegram: true };
              loadedConfigs[ticket].enabled = data.config[key] === 'true';
            }
            if (key.startsWith('ai_trade_care_interval_')) {
              const ticket = parseInt(key.replace('ai_trade_care_interval_', ''));
              if (!loadedConfigs[ticket]) loadedConfigs[ticket] = { enabled: false, interval: 15, telegram: true };
              loadedConfigs[ticket].interval = parseInt(data.config[key] || '15', 10);
            }
            if (key.startsWith('ai_trade_care_telegram_')) {
              const ticket = parseInt(key.replace('ai_trade_care_telegram_', ''));
              if (!loadedConfigs[ticket]) loadedConfigs[ticket] = { enabled: false, interval: 15, telegram: true };
              loadedConfigs[ticket].telegram = data.config[key] !== 'false';
            }
          });
          
          setAiConfigs(prev => ({...prev, ...loadedConfigs}));
        }
      } catch { /* */ }
    };
    wsRef.current = ws;
  }, []);

  useEffect(() => { 
    connectWs(); 
    
    // Poll tracked symbols every 15s to keep market closed status updated
    const interval = setInterval(() => {
      if (wsRef.current?.readyState === WebSocket.OPEN) {
        wsRef.current.send(JSON.stringify({ action: 'get_tracked_symbols' }));
      }
    }, 15000);
    
    return () => { 
      clearInterval(interval);
      wsRef.current?.close(); 
    }; 
  }, [connectWs]);

  const send = (msg: object) => { if (wsRef.current?.readyState === 1) wsRef.current.send(JSON.stringify(msg)); };

  const closeTrade = (ticket: number) => {
    if (confirm(`Are you sure you want to close position #${ticket}?`)) {
      send({ action: 'close_trade', ticket });
    }
  };

  const handleAiConfigChange = (ticket: number, field: string, value: any) => {
    setAiConfigs(prev => ({
      ...prev,
      [ticket]: { ...(prev[ticket] || { enabled: false, interval: 15, telegram: true }), [field]: value }
    }));
  };

  const saveAiConfig = (ticket: number) => {
    const config = aiConfigs[ticket] || { enabled: false, interval: 15, telegram: true };
    send({ action: 'set_server_config', config_key: `ai_trade_care_enabled_${ticket}`, config_value: config.enabled.toString() });
    send({ action: 'set_server_config', config_key: `ai_trade_care_interval_${ticket}`, config_value: config.interval.toString() });
    send({ action: 'set_server_config', config_key: `ai_trade_care_telegram_${ticket}`, config_value: config.telegram.toString() });
    setShowAiSetupTicket(null);
  };

  const totalPnl = positions.reduce((s, t) => s + t.pnl, 0);

  return (
    <main className="space-y-5">
      <div className="flex items-center justify-between">
        <div>
          <h4 className="text-lg font-semibold text-default-900">Active Trades</h4>
          <p className="text-sm text-default-500">{positions.length} open positions</p>
        </div>
        <div className="flex items-center gap-3">
          <div className={`rounded-lg px-4 py-2 text-sm font-bold ${totalPnl >= 0 ? 'bg-green-50 dark:bg-green-500/20 text-green-700 dark:text-green-400' : 'bg-red-50 dark:bg-red-500/20 text-red-700 dark:text-red-400'}`}>
            Floating P&L: {totalPnl >= 0 ? '+' : ''}${totalPnl.toFixed(2)}
          </div>
        </div>
      </div>

      <div className="card overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left text-sm">
            <thead className="border-b border-default-200/60 dark:border-default-300/10 bg-default-50/50 dark:bg-default-200/5 text-xs uppercase text-default-400">
              <tr>
                <th className="px-4 py-3">Symbol</th>
                <th className="px-4 py-3">Type</th>
                <th className="px-4 py-3">Lot</th>
                <th className="px-4 py-3">Entry</th>
                <th className="px-4 py-3">Current</th>
                <th className="px-4 py-3">SL</th>
                <th className="px-4 py-3">TP</th>
                <th className="px-4 py-3">P&L</th>
                <th className="px-4 py-3">Strategy</th>
                <th className="px-4 py-3">Duration</th>
                <th className="px-4 py-3 text-right">Action</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-default-200/60 dark:divide-default-300/10">
              {positions.length > 0 ? positions.map(t => {
                const isMarketClosed = closedMap[t.symbol] === true;
                return (
                <React.Fragment key={t.ticket}>
                  <tr className="transition hover:bg-default-50/50 dark:hover:bg-default-200/5">
                    <td className="px-4 py-3 font-semibold text-primary">{t.symbol}</td>
                    <td className="px-4 py-3">
                      <span className={`inline-flex rounded px-2 py-0.5 text-xs font-bold ${t.type === 'BUY' ? 'bg-green-100 text-green-700 dark:bg-green-500/20 dark:text-green-400' : 'bg-red-100 text-red-700 dark:bg-red-500/20 dark:text-red-400'}`}>{t.type}</span>
                    </td>
                    <td className="px-4 py-3 text-default-600">{t.volume.toFixed(2)}</td>
                    <td className="px-4 py-3 font-mono text-xs text-default-600">{t.open_price}</td>
                    <td className="px-4 py-3 font-mono text-xs text-default-900 font-medium">{t.current_price}</td>
                    <td className="px-4 py-3 font-mono text-xs text-red-400">{t.sl}</td>
                    <td className="px-4 py-3 font-mono text-xs text-green-500">{t.tp}</td>
                    <td className={`px-4 py-3 font-semibold ${t.pnl >= 0 ? 'text-green-600 dark:text-green-400' : 'text-red-600 dark:text-red-400'}`}>
                      {t.pnl >= 0 ? '+' : ''}${t.pnl.toFixed(2)}
                    </td>
                    <td className="px-4 py-3 text-xs text-default-500">{t.comment || 'EA-Web'}</td>
                    <td className="px-4 py-3 text-xs text-default-400 text-nowrap">{t.open_time}</td>
                    <td className="px-4 py-3 text-right">
                      {isMarketClosed ? (
                        <span className="inline-block rounded-md bg-black/5 dark:bg-black/20 px-3 py-1 font-bold text-black dark:text-default-400 text-xs shadow-sm">
                          Market Closed
                        </span>
                      ) : (
                        <div className="flex items-center justify-end gap-2">
                          <button 
                            onClick={() => setShowAiSetupTicket(showAiSetupTicket === t.ticket ? null : t.ticket)} 
                            className={`btn btn-sm border-none py-1 px-2.5 flex items-center ${aiConfigs[t.ticket]?.enabled ? 'bg-[#229ED9] text-white hover:bg-[#1f8fc4]' : 'bg-[#229ED9]/10 text-[#229ED9] hover:bg-[#229ED9] hover:text-white'}`}
                          >
                            <LuBot className="size-3 mr-1" /> {aiConfigs[t.ticket]?.enabled ? 'AI On' : 'EA Setup'}
                          </button>
                          <button onClick={() => closeTrade(t.ticket)} className="btn btn-sm bg-danger/10 text-danger hover:bg-danger hover:text-white border-none py-1 px-2.5">
                            <LuX className="size-3 mr-1" /> Close
                          </button>
                        </div>
                      )}
                    </td>
                  </tr>
                  
                  {/* Expanded EA Config Row */}
                  {!isMarketClosed && showAiSetupTicket === t.ticket && (
                    <tr className="bg-default-50/50 dark:bg-[#131826]">
                      <td colSpan={11} className="p-0">
                        <div className="p-4 border-l-4 border-[#229ED9] ml-4 my-2 mr-4 rounded-lg bg-white dark:bg-[#0A0D14] shadow-sm">
                          <div className="flex items-center gap-2 mb-3">
                            <LuBot className="size-4 text-[#229ED9]" />
                            <h5 className="text-sm font-semibold text-default-900">Configure AI Care for #{t.ticket}</h5>
                          </div>
                          
                          <div className="grid md:grid-cols-3 gap-4">
                             <div className="flex items-center justify-between p-3 rounded-md bg-default-50 dark:bg-[#131826]">
                               <div>
                                 <label className="text-[11px] font-bold text-gray-500 block">Enable EA</label>
                                 <span className="text-[10px] text-default-400">บอทวิเคราะห์ไม้นี้</span>
                               </div>
                               <Toggle checked={aiConfigs[t.ticket]?.enabled || false} onChange={v => handleAiConfigChange(t.ticket, 'enabled', v)} />
                             </div>
                
                             <div className="p-3 rounded-md bg-default-50 dark:bg-[#131826]">
                                 <label className="text-[11px] font-bold text-gray-500 block mb-1"><LuClock className="inline size-3 mr-1"/>Analyze Every (min)</label>
                                 <input type="number" min="1" max="120" value={aiConfigs[t.ticket]?.interval || 15} onChange={e => handleAiConfigChange(t.ticket, 'interval', parseInt(e.target.value) || 15)} className="w-full px-2 py-1 text-xs font-semibold rounded bg-white dark:bg-[#0A0D14] border border-default-200 dark:border-white/5 outline-none" />
                             </div>
                
                             <div className="flex items-center justify-between p-3 rounded-md bg-default-50 dark:bg-[#131826]">
                               <div>
                                 <label className="text-[11px] font-bold text-gray-500 block"><LuMessageCircle className="inline size-3 mr-1"/>Telegram Report</label>
                                 <span className="text-[10px] text-default-400">ส่งอัปเดตทางแชท</span>
                               </div>
                               <Toggle checked={aiConfigs[t.ticket]?.telegram ?? true} onChange={v => handleAiConfigChange(t.ticket, 'telegram', v)} />
                             </div>
                          </div>
                          
                          <div className="mt-3 flex justify-end gap-2">
                             <button onClick={() => setShowAiSetupTicket(null)} className="btn btn-sm bg-default-100 text-default-600 hover:bg-default-200 border-none py-1 px-4">Cancel</button>
                             <button onClick={() => saveAiConfig(t.ticket)} className="btn btn-sm bg-[#229ED9] text-white hover:bg-[#1f8fc4] border-none py-1 px-4 shadow-sm shadow-[#229ED9]/20"><LuSave className="size-3 mr-1" /> Save Setup</button>
                          </div>
                        </div>
                      </td>
                    </tr>
                  )}
                </React.Fragment>
              )}) : (
                <tr>
                  <td colSpan={11} className="px-4 py-8 text-center text-sm text-default-500">
                    {wsConnected ? 'No open positions' : 'Connecting to MT5...'}
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </div>
    </main>
  );
};

export default ActiveTrades;
