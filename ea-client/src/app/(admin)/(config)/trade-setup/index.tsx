import { useState, useEffect, useRef, useCallback } from 'react';
import { LuPlay, LuPause, LuPlus, LuTrash2, LuMonitor, LuPencil, LuX } from 'react-icons/lu';

const allStrategies = ['Scalper Pro', 'Trend Rider', 'Grid Master', 'Breakout Hunter', 'Mean Revert'];
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

type SetupForm = {
  symbol: string; strategy: string; timeframe: string; lotSize: number; riskPercent: number; mt5Instance: string;
  tpEnabled: boolean; tpMode: string; tpValue: number;
  slEnabled: boolean; slMode: string; slValue: number;
  trailingStopEnabled: boolean; trailingStopPoints: number;
};

import { getWsUrl } from '@/utils/config';

const defaultForm: SetupForm = {
  symbol: '', strategy: 'Scalper Pro', timeframe: 'M5', lotSize: 0.01, riskPercent: 2, mt5Instance: '',
  tpEnabled: false, tpMode: 'pips', tpValue: 50,
  slEnabled: false, slMode: 'pips', slValue: 30,
  trailingStopEnabled: false, trailingStopPoints: 50,
};

const WS_URL = getWsUrl();

const modeLabel = (m: string) => profitModes.find(p => p.value === m)?.label || m;
const modeUnit = (m: string) => m === 'rr' ? 'R' : m === 'pips' ? 'pips' : '$';
const selectCls = "form-select text-xs";
const inputCls = "form-input form-input-sm";

// Toggle Switch Component
const Toggle = ({ checked, onChange, disabled }: { checked: boolean; onChange: (v: boolean) => void; disabled?: boolean }) => (
  <label className={`relative inline-flex items-center ${disabled ? 'opacity-50' : 'cursor-pointer'}`}>
    <input type="checkbox" checked={checked} onChange={e => !disabled && onChange(e.target.checked)} className="peer sr-only" />
    <div className="h-5 w-9 rounded-full bg-default-200 after:absolute after:left-[2px] after:top-0.5 after:h-4 after:w-4 after:rounded-full after:bg-white after:transition-all peer-checked:bg-primary peer-checked:after:translate-x-full dark:bg-default-100 peer-checked:dark:bg-primary" />
  </label>
);

const TradeSetup = () => {
  const [wsConnected, setWsConnected] = useState(false);
  const [setups, setSetups] = useState<TradeSetupItem[]>([]);
  const [mt5Instances, setMt5Instances] = useState<Mt5Instance[]>([]);
  const [marketWatch, setMarketWatch] = useState<MarketWatchSymbol[]>([]);
  const [showForm, setShowForm] = useState(false);
  const [editId, setEditId] = useState<number | null>(null);
  const [form, setForm] = useState<SetupForm>({ ...defaultForm });
  const [deleteModal, setDeleteModal] = useState<{ show: boolean; id: number; symbol: string }>({ show: false, id: 0, symbol: '' });
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
    };
    if (editId) msg.setup_id = editId;
    send(msg);
    setShowForm(false);
    setEditId(null);
  };

  const confirmDelete = () => { send({ action: 'delete_trade_setup', setup_id: deleteModal.id }); setDeleteModal({ show: false, id: 0, symbol: '' }); };
  const toggleStatus = (id: number) => send({ action: 'toggle_trade_setup', setup_id: id });
  const getMt5Name = (id: string) => mt5Instances.find(i => i.id === id)?.broker_name || id || '—';

  const f = form;
  const setF = (patch: Partial<SetupForm>) => setForm(prev => ({ ...prev, ...patch }));

  return (
    <main className="space-y-5">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h4 className="text-lg font-semibold text-default-900">Trade Setup</h4>
          <p className="text-sm text-default-500">Configure trading pairs, TP/SL, and trailing stop</p>
        </div>
        <div className="flex items-center gap-2">
          {marketWatch.length > 0 && (
            <span className="rounded-full bg-blue-100 dark:bg-blue-500/20 px-2.5 py-0.5 text-[10px] font-medium text-blue-700 dark:text-blue-400">{marketWatch.length} symbols</span>
          )}
          <button onClick={openAddForm} className="btn bg-primary/10 text-primary hover:bg-primary hover:text-white">
            <LuPlus className="size-4" /> Add Setup
          </button>
        </div>
      </div>

      {/* Form (Add / Edit) */}
      {showForm && (
        <div className="rounded-xl border border-primary/20 bg-primary/5 dark:bg-primary/10 p-5 space-y-4">
          <div className="flex items-center justify-between">
            <h5 className="text-sm font-semibold text-default-900">{editId ? '✏️ Edit Setup' : '➕ New Trade Setup'}</h5>
            <button onClick={() => { setShowForm(false); setEditId(null); }} className="text-default-400 hover:text-default-600"><LuX className="size-4" /></button>
          </div>

          {/* MT5 Instance */}
          <div>
            <label className="mb-1 block text-xs font-medium text-default-500">MT5 Instance</label>
            {mt5Instances.length > 0 ? (
              <div className="flex flex-wrap gap-2">
                {mt5Instances.map(inst => (
                  <button key={inst.id} onClick={() => setF({ mt5Instance: inst.id })}
                    className={`btn disabled:opacity-40 ${f.mt5Instance === inst.id ? 'bg-primary/20 text-primary border border-primary' : 'bg-default-500/10 text-default-600 hover:bg-primary/10 hover:text-primary'}`}>
                    <LuMonitor className="size-4" />{inst.broker_name}
                    {inst.ea_deployed && <span className="rounded bg-green-500/20 px-1 text-[9px] text-green-600 dark:text-green-400">EA</span>}
                  </button>
                ))}
              </div>
            ) : <p className="text-xs text-yellow-600 dark:text-yellow-400">⚠ No running MT5 instances.</p>}
          </div>

          {/* Symbol / Strategy / TF / Lot */}
          <div className="grid grid-cols-2 gap-3 md:grid-cols-4">
            <div>
              <label className="mb-1 block text-xs text-default-500">Symbol <span className="text-[9px] text-blue-500">(Market Watch)</span></label>
              {marketWatch.length > 0 ? (
                <select value={f.symbol} onChange={e => setF({ symbol: e.target.value })} className={selectCls}>
                  {marketWatch.map(m => <option key={m.symbol} value={m.symbol}>{m.symbol} ({m.spread.toFixed(1)} sp)</option>)}
                </select>
              ) : <p className="rounded-md border border-yellow-300/50 bg-yellow-50 dark:bg-yellow-500/10 px-2 py-1.5 text-[10px] text-yellow-600 dark:text-yellow-400">⏳ Waiting for Market Watch...</p>}
            </div>
            <div>
              <label className="mb-1 block text-xs text-default-500">Strategy</label>
              <select value={f.strategy} onChange={e => setF({ strategy: e.target.value })} className={selectCls}>
                {allStrategies.map(s => <option key={s} value={s}>{s}</option>)}
              </select>
            </div>
            <div>
              <label className="mb-1 block text-xs text-default-500">Timeframe</label>
              <select value={f.timeframe} onChange={e => setF({ timeframe: e.target.value })} className={selectCls}>
                {timeframes.map(t => <option key={t} value={t}>{t}</option>)}
              </select>
            </div>
            <div>
              <label className="mb-1 block text-xs text-default-500">Lot Size</label>
              <input type="number" step="0.01" min="0.01" value={f.lotSize} onChange={e => setF({ lotSize: Number(e.target.value) })} className={inputCls} />
            </div>
          </div>

          {/* TP / SL / Trailing Stop — each with toggle */}
          <div className="grid grid-cols-1 gap-4 md:grid-cols-3">
            {/* TP */}
            <div className={`rounded-lg border p-3 transition ${f.tpEnabled ? 'border-green-200 dark:border-green-500/30 bg-green-50/50 dark:bg-green-500/5' : 'border-default-200 dark:border-default-100 bg-default-50/50 dark:bg-default-100/30'}`}>
              <div className="flex items-center justify-between mb-2">
                <p className={`text-xs font-semibold ${f.tpEnabled ? 'text-green-700 dark:text-green-400' : 'text-default-400'}`}>✅ Take Profit</p>
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
                <p className={`text-xs font-semibold ${f.slEnabled ? 'text-red-700 dark:text-red-400' : 'text-default-400'}`}>🛑 Stop Loss</p>
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
                <p className={`text-xs font-semibold ${f.trailingStopEnabled ? 'text-blue-700 dark:text-blue-400' : 'text-default-400'}`}>📐 Trailing Stop</p>
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

          {/* Risk */}
          <div className="max-w-xs">
            <label className="mb-1 block text-xs text-default-500">Risk %</label>
            <input type="number" step="0.5" min="0.1" max="100" value={f.riskPercent} onChange={e => setF({ riskPercent: Number(e.target.value) })} className={inputCls} />
          </div>

          <div className="flex gap-2 pt-1">
            <button onClick={saveSetup} disabled={!wsConnected || !f.symbol} className="btn bg-primary/10 text-primary hover:bg-primary hover:text-white disabled:opacity-40">
              {editId ? 'Update Setup' : 'Save to Server'}
            </button>
            <button onClick={() => { setShowForm(false); setEditId(null); }} className="btn bg-default-500/10 text-default-600 hover:bg-default-500 hover:text-white">Cancel</button>
          </div>
        </div>
      )}

      {/* Setup Cards */}
      <div className="grid gap-4 md:grid-cols-2">
        {setups.map(s => (
          <div key={s.id} className={`card !p-5 transition hover:shadow-md ${editId === s.id ? '!border-primary ring-2 ring-primary/20' : ''}`}>
            <div className="flex items-center justify-between mb-3">
              <div className="flex items-center gap-2">
                <span className="text-lg font-bold text-primary">{s.symbol}</span>
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
        ))}
      </div>

      {setups.length === 0 && !showForm && (
        <div className="rounded-xl border border-dashed border-default-300 dark:border-default-400/20 p-10 text-center">
          <p className="text-default-400">No trade setups yet — click "Add Setup" to create one</p>
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
