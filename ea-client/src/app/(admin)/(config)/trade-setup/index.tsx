import React, { useState, useEffect, useRef, useCallback } from 'react';
import { LuPlay, LuPause, LuPlus, LuTrash2, LuMonitor, LuPencil, LuX, LuActivity, LuChevronDown, LuRadar, LuLoader, LuShieldAlert, LuClock, LuPin, LuZap, LuCircleX, LuTarget, LuRuler, LuTriangleAlert, LuSave } from 'react-icons/lu';

const allStrategies = ['Auto', 'Trend Rider', 'Breakout Hunter', 'Mean Revert', 'SMC', 'ICT', 'Fibonacci', 'Momentum Surge', 'Session Sniper', 'Engulfing Driver', 'Bollinger Squeeze', 'Pullback Sniper', 'Reversal Catcher', 'Golden Cross', 'Fractal Breakout'];
const specialStrategies = ['Scalper Pro', 'Grid Master'];
const timeframes = ['M1', 'M5', 'M15', 'M30', 'H1', 'H4', 'D1'];
const profitModes = [
  { value: 'rr', label: 'R:R' },
  { value: 'pips', label: 'Pips' },
  { value: 'usd', label: 'USD' },
];

type TradeSetupItem = {
  id: number;
  symbol: string;
  strategy: string;
  timeframe: string;
  lotSize: number;
  riskPercent: number;
  mt5Instance: string;
  tpEnabled: boolean;
  tpMode: string;
  tpValue: number;
  slEnabled: boolean;
  slMode: string;
  slValue: number;
  trailingStopEnabled: boolean;
  trailingStopPoints: number;
  status: 'active' | 'paused';
  createdAt: string;
};

type Mt5Instance = { id: string; broker_name: string; ea_deployed: boolean; };
type MarketWatchSymbol = { symbol: string; bid: number; ask: number; spread: number; digits: number; desc: string; };
type EngineSetupStatus = { setup_id: number; status: string; message: string; };

type SetupForm = {
  symbol: string; strategy: string; timeframe: string; lotSize: number; riskPercent: number; mt5Instance: string;
  tpEnabled: boolean; tpMode: string; tpValue: number;
  slEnabled: boolean; slMode: string; slValue: number;
  trailingStopEnabled: boolean; trailingStopPoints: number;
  scheduleEnabled: boolean; scheduleStart: string; scheduleEnd: string;
  intervalMinutes: number;
};

import { getWsUrl } from '@/utils/config';

const defaultForm: SetupForm = {
  symbol: '', strategy: 'Auto', timeframe: 'M5', lotSize: 0.01, riskPercent: 2, mt5Instance: '',
  tpEnabled: false, tpMode: 'pips', tpValue: 50,
  slEnabled: false, slMode: 'pips', slValue: 30,
  trailingStopEnabled: false, trailingStopPoints: 50,
  scheduleEnabled: false, scheduleStart: '00:00', scheduleEnd: '23:59',
  intervalMinutes: 5,
};

const WS_URL = getWsUrl();

const modeLabel = (m: string) => profitModes.find(p => p.value === m)?.label || m;
const modeUnit = (m: string) => m === 'rr' ? 'R' : m === 'pips' ? 'pips' : '$';
const selectCls = "w-full px-2.5 py-2 text-[11px] font-semibold rounded-lg bg-white dark:bg-[#131826] border border-default-200 dark:border-white/5 hover:border-default-300 dark:hover:border-white/10 text-default-800 dark:text-gray-200 focus:border-blue-500/50 outline-none transition-all shadow-inner cursor-pointer";
const inputCls = "w-full px-2.5 py-2 text-[11px] font-semibold rounded-lg bg-white dark:bg-[#131826] border border-default-200 dark:border-white/5 hover:border-default-300 dark:hover:border-white/10 text-default-800 dark:text-gray-200 focus:border-blue-500/50 outline-none transition-all shadow-inner";

// Toggle Switch Component
const Toggle = ({ checked, onChange, disabled }: { checked: boolean; onChange: (v: boolean) => void; disabled?: boolean }) => (
  <input type="checkbox" checked={checked} onChange={e => !disabled && onChange(e.target.checked)} disabled={disabled} className="form-switch" />
);

// Countdown timer for scan interval
const ScanCountdown = ({ intervalMin, active }: { intervalMin: number; active: boolean }) => {
  const [remaining, setRemaining] = React.useState(intervalMin * 60);

  React.useEffect(() => {
    if (!active || intervalMin <= 0) return;
    const totalSec = intervalMin * 60;
    const now = Math.floor(Date.now() / 1000);
    const elapsed = now % totalSec;
    setRemaining(totalSec - elapsed);
    const interval = setInterval(() => {
      const n = Math.floor(Date.now() / 1000);
      const e = n % totalSec;
      setRemaining(totalSec - e);
    }, 1000);
    return () => clearInterval(interval);
  }, [intervalMin, active]);

  if (!active || intervalMin <= 0) return null;

  const m = Math.floor(remaining / 60);
  const s = remaining % 60;
  return (
    <span className="inline-flex items-center gap-1 rounded-full bg-sky-100 dark:bg-sky-500/20 px-2 py-0.5 text-[10px] font-mono font-medium text-sky-700 dark:text-sky-400">
      <LuClock className="size-2.5" />
      {m.toString().padStart(2, '0')}:{s.toString().padStart(2, '0')}
    </span>
  );
};

const TradeSetup = () => {
  const [wsConnected, setWsConnected] = useState(false);
  const [setups, setSetups] = useState<TradeSetupItem[]>([]);
  const [mt5Instances, setMt5Instances] = useState<Mt5Instance[]>([]);
  const [marketWatch, setMarketWatch] = useState<MarketWatchSymbol[]>([]);
  const [showForm, setShowForm] = useState(false);
  const [editId, setEditId] = useState<number | null>(null);
  const [form, setForm] = useState<SetupForm>({ ...defaultForm });
  const [deleteModal, setDeleteModal] = useState<{ show: boolean; id: number; symbol: string }>({ show: false, id: 0, symbol: '' });
  const [signals, setSignals] = useState<{setup_id: number; signal: string; symbol: string; strategy: string; reason: string; timestamp: string}[]>([]);
  const [signalLog, setSignalLog] = useState<any[]>([]);
  const [showSignalLog, setShowSignalLog] = useState(false);
  const [engineStatus, setEngineStatus] = useState<{ status: string; message: string; setups: EngineSetupStatus[] }>({ status: '', message: '', setups: [] });
  const wsRef = useRef<WebSocket | null>(null);

  const connectWs = useCallback(() => {
    const ws = new WebSocket(WS_URL);
    ws.onopen = () => { setWsConnected(true); ws.send(JSON.stringify({ action: 'get_trade_setups' })); ws.send(JSON.stringify({ action: 'get_running_mt5' })); };
    ws.onclose = () => { setWsConnected(false); setTimeout(connectWs, 3000); };
    ws.onmessage = (evt) => {
      try {
        const data = JSON.parse(evt.data);
        if (data.type === 'trade_setups') setSetups(data.setups || []);
        if (data.type === 'running_mt5') {
          setMt5Instances(data.instances || []);
          if (data.instances?.length > 0) setForm(prev => prev.mt5Instance === '' ? { ...prev, mt5Instance: data.instances[0].id } : prev);
        }
        if (data.type === 'market_watch') {
          setMarketWatch(data.symbols || []);
          if (data.symbols?.length > 0) setForm(prev => prev.symbol === '' ? { ...prev, symbol: data.symbols[0].symbol } : prev);
        }
        if (data.type === 'strategy_signal') {
          setSignals(prev => {
            const filtered = prev.filter(s => s.setup_id !== data.setup_id);
            return [{ setup_id: data.setup_id, signal: data.signal, symbol: data.symbol, strategy: data.strategy, reason: data.reason, timestamp: new Date().toISOString() }, ...filtered];
          });
        }
        if (data.type === 'strategy_signals') setSignalLog(data.signals || []);
        if (data.type === 'engine_status') {
          setEngineStatus({ status: data.status || '', message: data.message || '', setups: data.setups || [] });
        }
      } catch { /* */ }
    };
    wsRef.current = ws;
  }, []);

  useEffect(() => { connectWs(); return () => { wsRef.current?.close(); }; }, [connectWs]);
  const send = (msg: object) => { if (wsRef.current?.readyState === 1) wsRef.current.send(JSON.stringify(msg)); };

  const openAddForm = () => {
    setEditId(null);
    setForm({ ...defaultForm, mt5Instance: mt5Instances[0]?.id || '', symbol: marketWatch[0]?.symbol || '' });
    setShowForm(true);
    send({ action: 'get_running_mt5' });
  };

  const openEditForm = (s: TradeSetupItem) => {
    setEditId(s.id);
    setForm({
      symbol: s.symbol, strategy: s.strategy, timeframe: s.timeframe, lotSize: s.lotSize, riskPercent: s.riskPercent, mt5Instance: s.mt5Instance,
      tpEnabled: s.tpEnabled, tpMode: s.tpMode, tpValue: s.tpValue,
      slEnabled: s.slEnabled, slMode: s.slMode, slValue: s.slValue,
      trailingStopEnabled: s.trailingStopEnabled, trailingStopPoints: s.trailingStopPoints,
      scheduleEnabled: (s as any).scheduleEnabled ?? false, scheduleStart: (s as any).scheduleStart ?? '00:00', scheduleEnd: (s as any).scheduleEnd ?? '23:59',
      intervalMinutes: (s as any).intervalMinutes ?? 5,
    });
    setShowForm(true);
    send({ action: 'get_running_mt5' });
  };

  const saveSetup = () => {
    const msg: Record<string, unknown> = {
      action: editId ? 'update_trade_setup' : 'add_trade_setup',
      symbol: form.symbol, strategy: form.strategy, timeframe: form.timeframe,
      lot_size: form.lotSize, risk_percent: form.riskPercent, mt5_instance: form.mt5Instance,
      tp_enabled: form.tpEnabled, tp_mode: form.tpMode, tp_value: form.tpValue,
      sl_enabled: form.slEnabled, sl_mode: form.slMode, sl_value: form.slValue,
      trailing_stop_enabled: form.trailingStopEnabled, trailing_stop_points: form.trailingStopPoints,
      schedule_enabled: form.scheduleEnabled, schedule_start: form.scheduleStart, schedule_end: form.scheduleEnd,
      interval_minutes: form.intervalMinutes,
    };
    if (editId) msg.setup_id = editId;
    send(msg);
    setShowForm(false);
    setEditId(null);
  };

  const confirmDelete = () => { send({ action: 'delete_trade_setup', setup_id: deleteModal.id }); setDeleteModal({ show: false, id: 0, symbol: '' }); };
  const toggleStatus = (id: number) => send({ action: 'toggle_trade_setup', setup_id: id });
  const getMt5Name = (id: string) => mt5Instances.find(i => i.id === id)?.broker_name || id || '—';

  const getSetupEngineStatus = (setupId: number): EngineSetupStatus | null => {
    return engineStatus.setups.find(s => s.setup_id === setupId) || null;
  };

  const f = form;
  const setF = (patch: Partial<SetupForm>) => setForm(prev => ({ ...prev, ...patch }));

  return (
    <main className="space-y-5">

      {/* Header */}
      <div className="flex items-center justify-between mb-5">
        <div>
          <h4 className="text-lg font-semibold text-default-900">Trade Setup</h4>
          <p className="text-sm text-default-500">Configure trading pairs, TP/SL, and trailing stop</p>
        </div>
        <div className="flex items-center gap-2">
          {marketWatch.length > 0 && (
            <span className="rounded-full bg-blue-100 dark:bg-blue-500/20 px-2.5 py-0.5 text-[10px] font-medium text-blue-700 dark:text-blue-400">{marketWatch.length} symbols</span>
          )}
          <button onClick={openAddForm} className="btn bg-primary text-white text-nowrap border-0">
            <LuPlus className="size-4 me-1" />
            Add Setup
          </button>
        </div>
      </div>

      {/* Form (Add / Edit) */}
      {showForm && (
        <div className="rounded-xl border border-default-200 dark:border-white/5 bg-white dark:bg-[#0A0D14] shadow-sm mb-6">
          <div className="p-5 space-y-4">
            <div className="flex items-center justify-between mb-2">
              <h5 className="card-title text-default-900 flex items-center gap-1.5">{editId ? <><LuPencil className="size-3.5" /> Edit Setup</> : <><LuPlus className="size-3.5" /> New Trade Setup</>}</h5>
              <button onClick={() => { setShowForm(false); setEditId(null); }} className="text-default-400 hover:text-default-600"><LuX className="size-4" /></button>
            </div>

          {/* MT5 Instance */}
          <div className="mb-4">
            <label className="inline-block mb-1.5 text-[11px] font-bold text-gray-500 dark:text-gray-400 uppercase tracking-wider">MT5 Instance</label>
            {mt5Instances.length > 0 ? (
              <div className="flex flex-wrap gap-2">
                {mt5Instances.map(inst => (
                  <button key={inst.id} onClick={() => setF({ mt5Instance: inst.id })}
                    className={`btn btn-sm disabled:opacity-40 font-semibold ${f.mt5Instance === inst.id ? 'bg-primary/10 text-primary border border-primary/30 shadow-inner' : 'bg-default-50 dark:bg-[#131826] text-default-600 dark:text-gray-300 border border-default-200 dark:border-white/5 hover:bg-default-100 dark:hover:bg-white/5'}`}>
                    <LuMonitor className="size-4" />{inst.broker_name}
                    {inst.ea_deployed && <span className="rounded bg-green-500/20 px-1 text-[9px] text-green-600 dark:text-green-400">EA</span>}
                  </button>
                ))}
              </div>
            ) : <p className="text-xs text-yellow-600 dark:text-yellow-400 flex items-center gap-1"><LuTriangleAlert className="size-3" /> No running MT5 instances.</p>}
          </div>

          {/* Symbol / Strategy / TF / Lot */}
          <div className="grid lg:grid-cols-4 grid-cols-1 gap-5 mb-4">
            <div className="col-span-1 flex flex-col gap-1">
              <label className="inline-block mb-1 text-[11px] font-bold text-gray-500 dark:text-gray-400 uppercase tracking-wider">Symbol <span className="text-[9px] text-blue-500 lowercase font-normal">(market watch)</span></label>
              {marketWatch.length > 0 ? (
                <select value={f.symbol} onChange={e => setF({ symbol: e.target.value })} className={selectCls}>
                  {marketWatch.map(m => <option key={m.symbol} value={m.symbol}>{m.symbol} ({m.spread.toFixed(1)} sp)</option>)}
                </select>
              ) : <p className="rounded-md border border-yellow-300/50 bg-yellow-50 dark:bg-yellow-500/10 px-2 py-1.5 text-[10px] text-yellow-600 dark:text-yellow-400 flex items-center gap-1"><LuClock className="size-3" /> Waiting for Market Watch...</p>}
            </div>
            <div className="col-span-1 flex flex-col gap-1">
              <label className="inline-block mb-1 text-[11px] font-bold text-gray-500 dark:text-gray-400 uppercase tracking-wider">Strategy</label>
              <select value={f.strategy} onChange={e => setF({ strategy: e.target.value })} className={selectCls}>
                <optgroup label="Auto Mode">
                   <option value="Auto">Auto (15 Strategies)</option>
                </optgroup>
                <optgroup label="Standard Strategies">
                  {allStrategies.filter(s => s !== 'Auto').map(s => <option key={s} value={s}>{s}</option>)}
                </optgroup>
                <optgroup label="Specialized">
                  {specialStrategies.map(s => <option key={s} value={s}>{s}</option>)}
                </optgroup>
              </select>
            </div>
            <div className="col-span-1 flex flex-col gap-1">
              <label className="inline-block mb-1 text-[11px] font-bold text-gray-500 dark:text-gray-400 uppercase tracking-wider">Timeframe</label>
              <select value={f.timeframe} onChange={e => setF({ timeframe: e.target.value })} className={selectCls}>
                {timeframes.map(t => <option key={t} value={t}>{t}</option>)}
              </select>
            </div>
            <div className="col-span-1 flex flex-col gap-1">
              <label className="inline-block mb-1 text-[11px] font-bold text-gray-500 dark:text-gray-400 uppercase tracking-wider">Lot Size</label>
              <input type="number" step="0.01" min="0.01" value={f.lotSize} onChange={e => setF({ lotSize: Number(e.target.value) })} className={inputCls} />
            </div>
          </div>

          {/* Interval */}
          <div className="max-w-xs mb-4 flex flex-col gap-1">
            <label className="inline-block mb-1 text-[11px] font-bold text-gray-500 dark:text-gray-400 uppercase tracking-wider"><LuClock className="inline size-3.5 mr-1" />Scan Interval</label>
            <div className="flex items-center gap-2">
              <input type="number" step="1" min="1" max="1440" value={f.intervalMinutes} onChange={e => setF({ intervalMinutes: Number(e.target.value) })} className={inputCls} />
              <span className="text-[10px] text-default-400 whitespace-nowrap">min</span>
            </div>
            <p className="mt-1 text-[9px] text-default-400">Bot will re-analyze every {f.intervalMinutes} minute{f.intervalMinutes > 1 ? 's' : ''}</p>
          </div>

          {/* TP / SL / Trailing Stop — each with toggle */}
          <div className="grid grid-cols-1 gap-4 md:grid-cols-3">
            {/* TP */}
            <div className={`rounded-lg border p-3 transition ${f.tpEnabled ? 'border-green-200 dark:border-green-500/30 bg-green-50/50 dark:bg-green-500/5' : 'border-default-200 dark:border-default-100 bg-default-50/50 dark:bg-default-100/30'}`}>
              <div className="flex items-center justify-between mb-2">
                <p className={`text-xs font-semibold flex items-center gap-1 ${f.tpEnabled ? 'text-green-700 dark:text-green-400' : 'text-default-400'}`}><LuTarget className="size-3.5" /> Take Profit</p>
                <Toggle checked={f.tpEnabled} onChange={v => setF({ tpEnabled: v })} />
              </div>
              {f.tpEnabled ? (
                <div className="space-y-2">
                  <div><label className="mb-1 block text-[10px] text-default-400">Mode</label>
                    <select value={f.tpMode} onChange={e => setF({ tpMode: e.target.value })} className={selectCls}>{profitModes.map(m => <option key={m.value} value={m.value}>{m.label}</option>)}</select></div>
                  <div><label className="mb-1 block text-[10px] text-default-400">Value</label>
                    <div className="flex items-center gap-1"><input type="number" step="0.1" min="0" value={f.tpValue} onChange={e => setF({ tpValue: Number(e.target.value) })} className={inputCls} /><span className="text-[10px] text-default-400">{modeUnit(f.tpMode)}</span></div></div>
                </div>
              ) : <p className="text-xs text-default-400 mt-1">Enable to set Take Profit</p>}
            </div>

            {/* SL */}
            <div className={`rounded-lg border p-3 transition ${f.slEnabled ? 'border-red-200 dark:border-red-500/30 bg-red-50/50 dark:bg-red-500/5' : 'border-default-200 dark:border-default-100 bg-default-50/50 dark:bg-default-100/30'}`}>
              <div className="flex items-center justify-between mb-2">
                <p className={`text-xs font-semibold flex items-center gap-1 ${f.slEnabled ? 'text-red-700 dark:text-red-400' : 'text-default-400'}`}><LuCircleX className="size-3.5" /> Stop Loss</p>
                <Toggle checked={f.slEnabled} onChange={v => setF({ slEnabled: v })} />
              </div>
              {f.slEnabled ? (
                <div className="space-y-2">
                  <div><label className="mb-1 block text-[10px] text-default-400">Mode</label>
                    <select value={f.slMode} onChange={e => setF({ slMode: e.target.value })} className={selectCls}>{profitModes.map(m => <option key={m.value} value={m.value}>{m.label}</option>)}</select></div>
                  <div><label className="mb-1 block text-[10px] text-default-400">Value</label>
                    <div className="flex items-center gap-1"><input type="number" step="0.1" min="0" value={f.slValue} onChange={e => setF({ slValue: Number(e.target.value) })} className={inputCls} /><span className="text-[10px] text-default-400">{modeUnit(f.slMode)}</span></div></div>
                </div>
              ) : <p className="text-xs text-default-400 mt-1">Enable to set Stop Loss</p>}
            </div>

            {/* Trailing Stop */}
            <div className={`rounded-lg border p-3 transition ${f.trailingStopEnabled ? 'border-blue-200 dark:border-blue-500/30 bg-blue-50/50 dark:bg-blue-500/5' : 'border-default-200 dark:border-default-100 bg-default-50/50 dark:bg-default-100/30'}`}>
              <div className="flex items-center justify-between mb-2">
                <p className={`text-xs font-semibold flex items-center gap-1 ${f.trailingStopEnabled ? 'text-blue-700 dark:text-blue-400' : 'text-default-400'}`}><LuRuler className="size-3.5" /> Trailing Stop</p>
                <Toggle checked={f.trailingStopEnabled} onChange={v => setF({ trailingStopEnabled: v })} />
              </div>
              {f.trailingStopEnabled ? (
                <div>
                  <label className="mb-1 block text-[10px] text-default-400">Distance (points)</label>
                  <input type="number" step="1" min="1" value={f.trailingStopPoints} onChange={e => setF({ trailingStopPoints: Number(e.target.value) })} className={inputCls} />
                  <p className="mt-1 text-[9px] text-default-400">SL follows price at this distance</p>
                </div>
              ) : <p className="text-xs text-default-400 mt-1">Enable to auto-trail SL</p>}
            </div>
          </div>

          {/* Trading Schedule */}
          <div className={`rounded-lg border p-3 transition ${f.scheduleEnabled ? 'border-purple-200 dark:border-purple-500/30 bg-purple-50/50 dark:bg-purple-500/5' : 'border-default-200 dark:border-default-100 bg-default-50/50 dark:bg-default-100/30'}`}>
            <div className="flex items-center justify-between mb-2">
              <p className={`text-xs font-semibold ${f.scheduleEnabled ? 'text-purple-700 dark:text-purple-400' : 'text-default-400'}`}><LuClock className="inline size-3.5 mr-1" />Trading Schedule</p>
              <Toggle checked={f.scheduleEnabled} onChange={v => setF({ scheduleEnabled: v })} />
            </div>
            {f.scheduleEnabled ? (
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="mb-1 block text-[10px] text-default-400">Start Time</label>
                  <input type="time" value={f.scheduleStart} onChange={e => setF({ scheduleStart: e.target.value })} className={inputCls} />
                </div>
                <div>
                  <label className="mb-1 block text-[10px] text-default-400">End Time</label>
                  <input type="time" value={f.scheduleEnd} onChange={e => setF({ scheduleEnd: e.target.value })} className={inputCls} />
                </div>
                <p className="col-span-2 text-[9px] text-default-400">Bot will only trade between these hours (server time UTC)</p>
              </div>
            ) : <p className="text-xs text-default-400 mt-1">Enable to set trading hours</p>}
          </div>

          {/* Risk */}
          <div className="max-w-xs mb-4 flex flex-col gap-1">
            <label className="inline-block mb-1 text-[11px] font-bold text-gray-500 dark:text-gray-400 uppercase tracking-wider">Risk %</label>
            <input type="number" step="0.5" min="0.1" max="100" value={f.riskPercent} onChange={e => setF({ riskPercent: Number(e.target.value) })} className={inputCls} />
          </div>

          <div className="flex justify-end items-center mt-5">
            <div className="flex flex-wrap items-center gap-2">
              <button onClick={() => { setShowForm(false); setEditId(null); }} className="bg-default-200 text-default-500 text-nowrap border-0 btn hover:bg-default-300">
                Cancel
              </button>
              <button onClick={saveSetup} disabled={!wsConnected || !f.symbol} className="text-white border-0 btn text-nowrap bg-primary disabled:opacity-50">
                <LuSave className="size-4 me-1" />
                {editId ? 'Update Setup' : 'Save to Server'}
              </button>
            </div>
          </div>
          </div>
        </div>
      )}

      {/* Setup Cards */}
      <div className="grid gap-4 md:grid-cols-2">
        {setups.map(s => {
          const setupStatus = getSetupEngineStatus(s.id);

          return (
          <div key={s.id} className={`card !p-5 transition hover:shadow-md ${editId === s.id ? '!border-primary ring-2 ring-primary/20' : ''}`}>
            <div className="flex items-center justify-between mb-3">
              <div className="flex items-center gap-2">
                <span className="text-lg font-bold text-primary">{s.symbol}</span>
                <ScanCountdown intervalMin={(s as any).intervalMinutes ?? 5} active={s.status === 'active'} />
                <span className={`rounded-full px-2 py-0.5 text-[10px] font-medium ${s.status === 'active' ? 'bg-green-100 text-green-700 dark:bg-green-500/20 dark:text-green-400' : 'bg-yellow-100 text-yellow-700 dark:bg-yellow-500/20 dark:text-yellow-400'}`}>
                  {s.status === 'active' ? '● Active' : '⏸ Paused'}
                </span>
              </div>
              <div className="flex gap-1">
                <button onClick={() => openEditForm(s)} className="btn btn-icon btn-sm bg-primary/10 text-primary hover:bg-primary hover:text-white" title="Edit"><LuPencil className="size-4" /></button>
                <button onClick={() => toggleStatus(s.id)} className={`btn btn-icon btn-sm ${s.status === 'active' ? 'bg-warning/10 text-warning hover:bg-warning hover:text-white' : 'bg-success/10 text-success hover:bg-success hover:text-white'}`} title={s.status === 'active' ? 'Pause' : 'Activate'}>
                  {s.status === 'active' ? <LuPause className="size-4" /> : <LuPlay className="size-4" />}
                </button>
                <button onClick={() => setDeleteModal({ show: true, id: s.id, symbol: s.symbol })} className="btn btn-icon btn-sm bg-danger/10 text-danger hover:bg-danger hover:text-white" title="Delete"><LuTrash2 className="size-4" /></button>
              </div>
            </div>

            {s.mt5Instance && (
              <div className="mb-3">
                <span className="inline-flex items-center gap-1 rounded bg-blue-100 dark:bg-blue-500/20 px-2 py-0.5 text-[10px] font-medium text-blue-700 dark:text-blue-400"><LuMonitor className="size-3" />{getMt5Name(s.mt5Instance)}</span>
              </div>
            )}

            <div className="grid grid-cols-3 gap-2 mb-2">
              <div className="rounded-lg bg-default-50 dark:bg-default-100/50 p-2 text-center"><p className="text-[10px] text-default-400">Strategy</p><p className="text-xs font-semibold text-default-800">{s.strategy}</p></div>
              <div className="rounded-lg bg-default-50 dark:bg-default-100/50 p-2 text-center"><p className="text-[10px] text-default-400">Timeframe</p><p className="text-xs font-semibold text-default-800">{s.timeframe}</p></div>
              <div className="rounded-lg bg-default-50 dark:bg-default-100/50 p-2 text-center"><p className="text-[10px] text-default-400">Lot / Risk</p><p className="text-xs font-semibold text-default-800">{s.lotSize} / {s.riskPercent}%</p></div>
            </div>

            {/* Engine Status — per-card, detailed */}
            {s.status === 'active' && (() => {
              // Global issues first
              const globalStatus = engineStatus.status;
              if (globalStatus === 'waiting_ea') {
                return (
                  <div className="mb-2 rounded-lg px-3 py-2.5 flex items-center gap-2.5 bg-amber-50 dark:bg-amber-500/10 border border-amber-200/60 dark:border-amber-500/15">
                    <LuLoader className="size-4 text-amber-500 animate-spin shrink-0" />
                    <div>
                      <p className="text-xs font-semibold text-amber-700 dark:text-amber-400">Waiting for EA connection</p>
                      <p className="text-[10px] text-amber-600/70 dark:text-amber-400/60 mt-0.5">Make sure MT5 is running and EA is attached to a chart</p>
                    </div>
                  </div>
                );
              }
              if (globalStatus === 'waiting_account') {
                return (
                  <div className="mb-2 rounded-lg px-3 py-2.5 flex items-center gap-2.5 bg-amber-50 dark:bg-amber-500/10 border border-amber-200/60 dark:border-amber-500/15">
                    <LuLoader className="size-4 text-amber-500 animate-spin shrink-0" />
                    <div>
                      <p className="text-xs font-semibold text-amber-700 dark:text-amber-400">Waiting for account data</p>
                      <p className="text-[10px] text-amber-600/70 dark:text-amber-400/60 mt-0.5">EA connected but account info not yet received</p>
                    </div>
                  </div>
                );
              }
              if (globalStatus === 'drawdown_limit') {
                return (
                  <div className="mb-2 rounded-lg px-3 py-2.5 flex items-center gap-2.5 bg-red-50 dark:bg-red-500/10 border border-red-200/60 dark:border-red-500/15">
                    <LuShieldAlert className="size-4 text-red-500 shrink-0" />
                    <div>
                      <p className="text-xs font-semibold text-red-700 dark:text-red-400">Trading paused — Drawdown limit</p>
                      <p className="text-[10px] text-red-600/70 dark:text-red-400/60 mt-0.5">{engineStatus.message}</p>
                    </div>
                  </div>
                );
              }
              if (globalStatus === 'max_positions') {
                return (
                  <div className="mb-2 rounded-lg px-3 py-2.5 flex items-center gap-2.5 bg-red-50 dark:bg-red-500/10 border border-red-200/60 dark:border-red-500/15">
                    <LuShieldAlert className="size-4 text-red-500 shrink-0" />
                    <div>
                      <p className="text-xs font-semibold text-red-700 dark:text-red-400">Max positions reached</p>
                      <p className="text-[10px] text-red-600/70 dark:text-red-400/60 mt-0.5">{engineStatus.message}</p>
                    </div>
                  </div>
                );
              }
              if (!globalStatus || globalStatus === 'no_setups') {
                return (
                  <div className="mb-2 rounded-lg px-3 py-2.5 flex items-center gap-2.5 bg-default-50 dark:bg-default-100/30 border border-default-200/50 dark:border-default-100/20">
                    <LuLoader className="size-4 text-default-400 animate-spin shrink-0" />
                    <p className="text-xs font-medium text-default-400">Engine initializing...</p>
                  </div>
                );
              }
              // Per-setup status
              if (setupStatus) {
                const icons: Record<string, React.ReactNode> = {
                  loading_candles: <LuLoader className="size-4 text-amber-500 animate-spin shrink-0" />,
                  scanning: <LuRadar className="size-4 text-emerald-500 animate-pulse shrink-0" />,
                  cooldown: <LuClock className="size-4 text-sky-500 shrink-0" />,
                  has_position: <LuPin className="size-4 text-violet-500 shrink-0" />,
                  signal_sent: <LuZap className="size-4 text-green-500 shrink-0" />,
                };
                const colors: Record<string, { border: string; bg: string; title: string; desc: string }> = {
                  loading_candles: { border: 'border-amber-200/60 dark:border-amber-500/15', bg: 'bg-amber-50 dark:bg-amber-500/10', title: 'text-amber-700 dark:text-amber-400', desc: 'text-amber-600/70 dark:text-amber-400/60' },
                  scanning: { border: 'border-emerald-200/60 dark:border-emerald-500/15', bg: 'bg-emerald-50 dark:bg-emerald-500/10', title: 'text-emerald-700 dark:text-emerald-400', desc: 'text-emerald-600/70 dark:text-emerald-400/60' },
                  cooldown: { border: 'border-sky-200/60 dark:border-sky-500/15', bg: 'bg-sky-50 dark:bg-sky-500/10', title: 'text-sky-700 dark:text-sky-400', desc: 'text-sky-600/70 dark:text-sky-400/60' },
                  has_position: { border: 'border-violet-200/60 dark:border-violet-500/15', bg: 'bg-violet-50 dark:bg-violet-500/10', title: 'text-violet-700 dark:text-violet-400', desc: 'text-violet-600/70 dark:text-violet-400/60' },
                  signal_sent: { border: 'border-green-200/60 dark:border-green-500/15', bg: 'bg-green-50 dark:bg-green-500/10', title: 'text-green-700 dark:text-green-400', desc: 'text-green-600/70 dark:text-green-400/60' },
                };
                const icon = icons[setupStatus.status] || <LuRadar className="size-4 text-default-400 shrink-0" />;
                const clr = colors[setupStatus.status] || { border: 'border-default-200/50 dark:border-default-100/20', bg: 'bg-default-50 dark:bg-default-100/30', title: 'text-default-600', desc: 'text-default-400' };
                const descriptions: Record<string, string> = {
                  loading_candles: 'Requesting historical data from MT5. Need at least 50 candles to analyze.',
                  scanning: 'All indicators calculated. Analyzing for entry signals...',
                  cooldown: 'Recently traded this pair. Waiting before next signal.',
                  has_position: 'There is already an open position for this setup.',
                  signal_sent: 'Order command sent to MT5 terminal.',
                };
                return (
                  <div className={`mb-2 rounded-lg px-3 py-2.5 flex items-center gap-2.5 ${clr.bg} border ${clr.border}`}>
                    {icon}
                    <div className="flex-1 min-w-0">
                      <p className={`text-xs font-semibold ${clr.title}`}>{setupStatus.message}</p>
                      <p className={`text-[10px] mt-0.5 ${clr.desc}`}>{descriptions[setupStatus.status] || ''}</p>
                    </div>
                  </div>
                );
              }
              return null;
            })()}

            {/* Paused setup */}
            {s.status === 'paused' && (
              <div className="mb-2 rounded-lg border border-default-200/50 dark:border-default-100/20 px-3 py-2.5 flex items-center gap-2.5 bg-default-50 dark:bg-default-100/30">
                <LuPause className="size-4 text-default-400 shrink-0" />
                <p className="text-xs font-medium text-default-400">Engine paused for this setup</p>
              </div>
            )}

            {/* Last Signal Badge */}
            {(() => {
              const sig = signals.find(sg => sg.setup_id === s.id);
              if (!sig) return null;
              const isBuy = sig.signal === 'BUY';
              return (
                <div className={`mb-2 rounded-lg border px-3 py-2 ${isBuy ? 'border-green-300/50 dark:border-green-500/20 bg-green-50 dark:bg-green-500/10' : 'border-red-300/50 dark:border-red-500/20 bg-red-50 dark:bg-red-500/10'}`}>
                  <div className="flex items-center gap-2">
                    <LuActivity className={`size-3.5 ${isBuy ? 'text-green-600 dark:text-green-400' : 'text-red-600 dark:text-red-400'}`} />
                    <span className={`text-xs font-bold ${isBuy ? 'text-green-700 dark:text-green-400' : 'text-red-700 dark:text-red-400'}`}>{sig.signal}</span>
                    <span className="text-[10px] text-default-500 ml-auto">{new Date(sig.timestamp).toLocaleTimeString()}</span>
                  </div>
                  <p className="text-[10px] text-default-500 mt-0.5 truncate">{sig.reason}</p>
                </div>
              );
            })()}

            {/* TP / SL / TS indicators */}
            <div className="flex flex-wrap gap-2">
              {s.tpEnabled ? (
                <div className="rounded-lg border border-green-200/50 dark:border-green-500/20 bg-green-50/50 dark:bg-green-500/5 px-3 py-1.5 text-center">
                  <p className="text-[10px] text-green-600 dark:text-green-400">TP ({modeLabel(s.tpMode)})</p>
                  <p className="text-xs font-bold text-green-700 dark:text-green-400">{s.tpValue} {modeUnit(s.tpMode)}</p>
                </div>
              ) : (
                <div className="rounded-lg border border-default-200/50 dark:border-default-100/50 px-3 py-1.5 text-center opacity-50">
                  <p className="text-[10px] text-default-400">TP</p><p className="text-xs text-default-400">OFF</p>
                </div>
              )}
              {s.slEnabled ? (
                <div className="rounded-lg border border-red-200/50 dark:border-red-500/20 bg-red-50/50 dark:bg-red-500/5 px-3 py-1.5 text-center">
                  <p className="text-[10px] text-red-600 dark:text-red-400">SL ({modeLabel(s.slMode)})</p>
                  <p className="text-xs font-bold text-red-700 dark:text-red-400">{s.slValue} {modeUnit(s.slMode)}</p>
                </div>
              ) : (
                <div className="rounded-lg border border-default-200/50 dark:border-default-100/50 px-3 py-1.5 text-center opacity-50">
                  <p className="text-[10px] text-default-400">SL</p><p className="text-xs text-default-400">OFF</p>
                </div>
              )}
              {s.trailingStopEnabled ? (
                <div className="rounded-lg border border-blue-200/50 dark:border-blue-500/20 bg-blue-50/50 dark:bg-blue-500/5 px-3 py-1.5 text-center">
                  <p className="text-[10px] text-blue-600 dark:text-blue-400">Trailing</p>
                  <p className="text-xs font-bold text-blue-700 dark:text-blue-400">{s.trailingStopPoints} pts</p>
                </div>
              ) : (
                <div className="rounded-lg border border-default-200/50 dark:border-default-100/50 px-3 py-1.5 text-center opacity-50">
                  <p className="text-[10px] text-default-400">TS</p><p className="text-xs text-default-400">OFF</p>
                </div>
              )}
            </div>
          </div>
          );
        })}
      </div>

      {setups.length === 0 && !showForm && (
        <div className="rounded-xl border border-dashed border-default-300 dark:border-default-400/20 p-10 text-center">
          <p className="text-default-400">No trade setups yet — click "Add Setup" to create one</p>
        </div>
      )}

      {/* Signal Log */}
      {setups.length > 0 && (
        <div className="card !p-0 overflow-hidden">
          <button
            onClick={() => { setShowSignalLog(!showSignalLog); if (!showSignalLog) send({ action: 'get_signals', limit: 20 }); }}
            className="flex w-full items-center justify-between p-4 hover:bg-default-50 dark:hover:bg-default-100/30 transition"
          >
            <div className="flex items-center gap-2">
              <LuActivity className="size-4 text-primary" />
              <span className="text-sm font-semibold text-default-900">Strategy Signal Log</span>
              <span className="rounded-full bg-primary/10 px-2 py-0.5 text-[10px] font-medium text-primary">{signalLog.length}</span>
            </div>
            <LuChevronDown className={`size-4 text-default-400 transition ${showSignalLog ? 'rotate-180' : ''}`} />
          </button>
          {showSignalLog && (
            <div className="border-t border-default-200/50 dark:border-default-100/20">
              {signalLog.length > 0 ? (
                <div className="divide-y divide-default-200/50 dark:divide-default-100/20 max-h-64 overflow-y-auto">
                  {signalLog.map((sig: any) => (
                    <div key={sig.id} className="flex items-center gap-3 px-4 py-2.5 text-xs">
                      <span className={`rounded px-1.5 py-0.5 font-bold text-[10px] ${sig.signal_type === 'BUY' ? 'bg-green-100 text-green-700 dark:bg-green-500/20 dark:text-green-400' : 'bg-red-100 text-red-700 dark:bg-red-500/20 dark:text-red-400'}`}>{sig.signal_type}</span>
                      <span className="font-semibold text-default-800">{sig.symbol}</span>
                      <span className="text-default-500">{sig.strategy}</span>
                      <span className="text-default-400 truncate flex-1 max-w-xs">{sig.reason}</span>
                      <span className="text-default-400 text-[10px] ml-auto whitespace-nowrap">{new Date(sig.timestamp).toLocaleString()}</span>
                    </div>
                  ))}
                </div>
              ) : (
                <p className="p-4 text-center text-xs text-default-400">No signals recorded yet. Engine will generate signals when setups are active and EA is connected.</p>
              )}
            </div>
          )}
        </div>
      )}

      {/* Delete Confirmation Modal */}
      {deleteModal.show && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 backdrop-blur-sm" onClick={() => setDeleteModal({ show: false, id: 0, symbol: '' })}>
          <div className="mx-4 w-full max-w-sm rounded-2xl bg-card p-6 shadow-2xl" onClick={e => e.stopPropagation()}>
            <div className="mb-4 flex size-12 items-center justify-center rounded-full bg-red-100 dark:bg-red-500/20 mx-auto">
              <LuTrash2 className="size-6 text-red-600 dark:text-red-400" />
            </div>
            <h3 className="mb-2 text-center text-base font-semibold text-default-900">Delete Trade Setup?</h3>
            <p className="mb-6 text-center text-sm text-default-500">
              Are you sure you want to delete <span className="font-semibold text-primary">{deleteModal.symbol}</span>? This action cannot be undone.
            </p>
            <div className="flex gap-3">
              <button onClick={() => setDeleteModal({ show: false, id: 0, symbol: '' })} className="btn flex-1 bg-default-500/10 text-default-600 hover:bg-default-500 hover:text-white">Cancel</button>
              <button onClick={confirmDelete} className="btn flex-1 bg-danger/10 text-danger hover:bg-danger hover:text-white">Delete</button>
            </div>
          </div>
        </div>
      )}
    </main>
  );
};

export default TradeSetup;
