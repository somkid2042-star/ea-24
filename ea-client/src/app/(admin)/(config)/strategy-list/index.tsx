import { useState } from 'react';
import { LuPlus, LuSettings, LuTrash2, LuPlay, LuPause, LuCopy } from 'react-icons/lu';

type Strategy = {
  id: number;
  name: string;
  type: string;
  description: string;
  indicators: string[];
  winRate: number;
  totalTrades: number;
  status: 'active' | 'inactive';
};

const mockStrategies: Strategy[] = [
  { id: 1, name: 'Scalper Pro', type: 'Scalper', description: 'Fast entry/exit on M1-M5 with tight stop-loss', indicators: ['RSI', 'Bollinger Bands', 'EMA 9/21'], winRate: 72.4, totalTrades: 1850, status: 'active' },
  { id: 2, name: 'Trend Rider', type: 'Trend Following', description: 'Follow major trends on H1-H4 with trailing stop', indicators: ['MACD', 'EMA 50/200', 'ADX'], winRate: 61.8, totalTrades: 420, status: 'active' },
  { id: 3, name: 'Grid Master', type: 'Grid', description: 'Multi-level grid with dynamic spacing', indicators: ['ATR', 'Support/Resistance'], winRate: 55.2, totalTrades: 3200, status: 'inactive' },
  { id: 4, name: 'Breakout Hunter', type: 'Breakout', description: 'Trade breakouts from consolidation zones', indicators: ['Volume', 'Bollinger Bands', 'ATR'], winRate: 58.9, totalTrades: 680, status: 'active' },
  { id: 5, name: 'Mean Revert', type: 'Mean Reversion', description: 'Counter-trend strategy on overbought/oversold', indicators: ['RSI', 'Stochastic', 'CCI'], winRate: 67.5, totalTrades: 920, status: 'inactive' },
];

const StrategyList = () => {
  const [strategies, setStrategies] = useState(mockStrategies);

  const toggleStatus = (id: number) => {
    setStrategies(strategies.map(s => s.id === id ? { ...s, status: s.status === 'active' ? 'inactive' : 'active' } : s));
  };

  const removeStrategy = (id: number) => {
    setStrategies(strategies.filter(s => s.id !== id));
  };

  return (
    <main className="space-y-5">
      <div className="flex items-center justify-between">
        <div>
          <h4 className="text-lg font-semibold text-default-900">Strategy List</h4>
          <p className="text-sm text-default-500">Manage your trading strategies</p>
        </div>
        <a href="/strategy/builder" className="btn bg-primary/10 text-primary hover:bg-primary hover:text-white">
          <LuPlus className="size-4" /> New Strategy
        </a>
      </div>

      <div className="grid gap-4">
        {strategies.map(s => (
          <div key={s.id} className="card !p-5 transition hover:shadow-md">
            <div className="flex items-start justify-between">
              <div className="flex-1">
                <div className="flex items-center gap-3">
                  <h5 className="text-sm font-semibold text-default-900">{s.name}</h5>
                  <span className="rounded-full bg-primary/10 px-2.5 py-0.5 text-[10px] font-medium text-primary">{s.type}</span>
                  <span className={`rounded-full px-2 py-0.5 text-[10px] font-medium ${
                    s.status === 'active' ? 'bg-green-100 text-green-700 dark:bg-green-500/20 dark:text-green-400' : 'bg-default-100 text-default-500 dark:bg-default-200/10'
                  }`}>
                    {s.status === 'active' ? '● Active' : '○ Inactive'}
                  </span>
                </div>
                <p className="mt-1 text-xs text-default-500">{s.description}</p>
                <div className="mt-2 flex flex-wrap gap-1">
                  {s.indicators.map(ind => (
                    <span key={ind} className="rounded bg-default-100 dark:bg-default-200/10 px-2 py-0.5 text-[10px] text-default-600">{ind}</span>
                  ))}
                </div>
              </div>
              <div className="flex items-center gap-4 ml-4">
                <div className="text-center">
                  <p className="text-lg font-bold text-default-900">{s.winRate}%</p>
                  <p className="text-[10px] text-default-400">Win Rate</p>
                </div>
                <div className="text-center">
                  <p className="text-lg font-bold text-default-900">{s.totalTrades.toLocaleString()}</p>
                  <p className="text-[10px] text-default-400">Trades</p>
                </div>
                <div className="flex gap-2">
                  <button onClick={() => toggleStatus(s.id)} className={`btn btn-icon btn-sm ${s.status === 'active' ? 'bg-warning/10 text-warning hover:bg-warning hover:text-white' : 'bg-success/10 text-success hover:bg-success hover:text-white'}`} title={s.status === 'active' ? 'Pause' : 'Activate'}>
                    {s.status === 'active' ? <LuPause className="size-4" /> : <LuPlay className="size-4" />}
                  </button>
                  <button className="btn btn-icon btn-sm bg-default-500/10 text-default-600 hover:bg-primary/10 hover:text-primary" title="Duplicate"><LuCopy className="size-4" /></button>
                  <button className="btn btn-icon btn-sm bg-default-500/10 text-default-600 hover:bg-primary/10 hover:text-primary" title="Settings"><LuSettings className="size-4" /></button>
                  <button onClick={() => removeStrategy(s.id)} className="btn btn-icon btn-sm bg-danger/10 text-danger hover:bg-danger hover:text-white" title="Delete"><LuTrash2 className="size-4" /></button>
                </div>
              </div>
            </div>
          </div>
        ))}
      </div>
    </main>
  );
};

export default StrategyList;
