import { useState } from 'react';
import { LuPlay, LuPlus, LuTrash2, LuSettings } from 'react-icons/lu';

const allSymbols = ['EURUSD', 'GBPUSD', 'USDJPY', 'AUDUSD', 'NZDUSD', 'USDCAD', 'USDCHF', 'XAUUSD', 'XAGUSD', 'BTCUSD', 'ETHUSD', 'US30', 'NAS100', 'SPX500'];
const allStrategies = ['Scalper Pro', 'Trend Rider', 'Grid Master', 'Breakout Hunter', 'Mean Revert'];
const timeframes = ['M1', 'M5', 'M15', 'M30', 'H1', 'H4', 'D1'];

type TradeSetupItem = {
  id: number;
  symbol: string;
  strategy: string;
  timeframe: string;
  lotSize: number;
  riskPercent: number;
  status: 'active' | 'paused';
};

const mockSetups: TradeSetupItem[] = [
  { id: 1, symbol: 'EURUSD', strategy: 'Scalper Pro', timeframe: 'M5', lotSize: 0.05, riskPercent: 2, status: 'active' },
  { id: 2, symbol: 'GBPUSD', strategy: 'Trend Rider', timeframe: 'H1', lotSize: 0.10, riskPercent: 3, status: 'active' },
  { id: 3, symbol: 'XAUUSD', strategy: 'Grid Master', timeframe: 'M15', lotSize: 0.02, riskPercent: 1.5, status: 'paused' },
  { id: 4, symbol: 'BTCUSD', strategy: 'Breakout Hunter', timeframe: 'H4', lotSize: 0.01, riskPercent: 1, status: 'active' },
];

const TradeSetup = () => {
  const [setups, setSetups] = useState(mockSetups);
  const [showAdd, setShowAdd] = useState(false);
  const [newSetup, setNewSetup] = useState({ symbol: 'EURUSD', strategy: allStrategies[0], timeframe: 'M5', lotSize: 0.01, riskPercent: 2 });

  const addSetup = () => {
    setSetups([...setups, { ...newSetup, id: Date.now(), status: 'paused' }]);
    setShowAdd(false);
  };

  const toggleStatus = (id: number) => {
    setSetups(setups.map(s => s.id === id ? { ...s, status: s.status === 'active' ? 'paused' : 'active' } : s));
  };

  const removeSetup = (id: number) => {
    setSetups(setups.filter(s => s.id !== id));
  };

  return (
    <main className="space-y-5">
      <div className="flex items-center justify-between">
        <div>
          <h4 className="text-lg font-semibold text-default-900">Trade Setup</h4>
          <p className="text-sm text-default-500">Configure which pairs to trade with which strategy</p>
        </div>
        <button onClick={() => setShowAdd(!showAdd)} className="inline-flex items-center gap-1.5 rounded-md bg-primary px-3 py-2 text-xs font-medium text-white hover:bg-primary/90">
          <LuPlus className="size-3.5" /> Add Setup
        </button>
      </div>

      {/* Add Form */}
      {showAdd && (
        <div className="rounded-xl border border-primary/20 bg-primary/5 p-5">
          <h5 className="mb-3 text-sm font-semibold text-default-900">New Trade Setup</h5>
          <div className="grid grid-cols-2 gap-3 md:grid-cols-5">
            <div>
              <label className="mb-1 block text-xs text-default-500">Currency Pair</label>
              <select value={newSetup.symbol} onChange={e => setNewSetup({ ...newSetup, symbol: e.target.value })} className="w-full rounded-md border border-default-200 px-3 py-2 text-sm focus:border-primary focus:outline-none">
                {allSymbols.map(s => <option key={s} value={s}>{s}</option>)}
              </select>
            </div>
            <div>
              <label className="mb-1 block text-xs text-default-500">Strategy</label>
              <select value={newSetup.strategy} onChange={e => setNewSetup({ ...newSetup, strategy: e.target.value })} className="w-full rounded-md border border-default-200 px-3 py-2 text-sm focus:border-primary focus:outline-none">
                {allStrategies.map(s => <option key={s} value={s}>{s}</option>)}
              </select>
            </div>
            <div>
              <label className="mb-1 block text-xs text-default-500">Timeframe</label>
              <select value={newSetup.timeframe} onChange={e => setNewSetup({ ...newSetup, timeframe: e.target.value })} className="w-full rounded-md border border-default-200 px-3 py-2 text-sm focus:border-primary focus:outline-none">
                {timeframes.map(t => <option key={t} value={t}>{t}</option>)}
              </select>
            </div>
            <div>
              <label className="mb-1 block text-xs text-default-500">Lot Size</label>
              <input type="number" step="0.01" value={newSetup.lotSize} onChange={e => setNewSetup({ ...newSetup, lotSize: Number(e.target.value) })} className="w-full rounded-md border border-default-200 px-3 py-2 text-sm focus:border-primary focus:outline-none" />
            </div>
            <div>
              <label className="mb-1 block text-xs text-default-500">Risk %</label>
              <input type="number" step="0.5" value={newSetup.riskPercent} onChange={e => setNewSetup({ ...newSetup, riskPercent: Number(e.target.value) })} className="w-full rounded-md border border-default-200 px-3 py-2 text-sm focus:border-primary focus:outline-none" />
            </div>
          </div>
          <div className="mt-3 flex gap-2">
            <button onClick={addSetup} className="rounded-md bg-primary px-4 py-2 text-xs font-medium text-white hover:bg-primary/90">Add</button>
            <button onClick={() => setShowAdd(false)} className="rounded-md border border-default-200 px-4 py-2 text-xs font-medium text-default-600 hover:bg-default-100">Cancel</button>
          </div>
        </div>
      )}

      {/* Setup Cards */}
      <div className="grid gap-4 md:grid-cols-2">
        {setups.map(s => (
          <div key={s.id} className="rounded-xl border border-default-200 bg-white p-5 transition hover:shadow-md">
            <div className="flex items-center justify-between mb-3">
              <div className="flex items-center gap-2">
                <span className="text-lg font-bold text-primary">{s.symbol}</span>
                <span className={`rounded-full px-2 py-0.5 text-[10px] font-medium ${
                  s.status === 'active' ? 'bg-green-100 text-green-700' : 'bg-yellow-100 text-yellow-700'
                }`}>
                  {s.status === 'active' ? '● Active' : '⏸ Paused'}
                </span>
              </div>
              <div className="flex gap-1">
                <button onClick={() => toggleStatus(s.id)} className={`rounded p-1.5 ${s.status === 'active' ? 'text-orange-500 hover:bg-orange-50' : 'text-green-500 hover:bg-green-50'}`}>
                  <LuPlay className="size-4" />
                </button>
                <button className="rounded p-1.5 text-default-400 hover:bg-default-100"><LuSettings className="size-4" /></button>
                <button onClick={() => removeSetup(s.id)} className="rounded p-1.5 text-red-400 hover:bg-red-50"><LuTrash2 className="size-4" /></button>
              </div>
            </div>
            <div className="grid grid-cols-4 gap-2">
              <div className="rounded-lg bg-default-50 p-2 text-center">
                <p className="text-[10px] text-default-400">Strategy</p>
                <p className="text-xs font-semibold text-default-800">{s.strategy}</p>
              </div>
              <div className="rounded-lg bg-default-50 p-2 text-center">
                <p className="text-[10px] text-default-400">Timeframe</p>
                <p className="text-xs font-semibold text-default-800">{s.timeframe}</p>
              </div>
              <div className="rounded-lg bg-default-50 p-2 text-center">
                <p className="text-[10px] text-default-400">Lot</p>
                <p className="text-xs font-semibold text-default-800">{s.lotSize}</p>
              </div>
              <div className="rounded-lg bg-default-50 p-2 text-center">
                <p className="text-[10px] text-default-400">Risk</p>
                <p className="text-xs font-semibold text-default-800">{s.riskPercent}%</p>
              </div>
            </div>
          </div>
        ))}
      </div>
    </main>
  );
};

export default TradeSetup;
