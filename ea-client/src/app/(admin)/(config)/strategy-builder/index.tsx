import { useState } from 'react';
import { LuSave, LuPlus, LuTrash2, LuPlay, LuPause, LuCopy, LuSettings } from 'react-icons/lu';

const indicatorOptions = ['RSI', 'MACD', 'Bollinger Bands', 'EMA', 'SMA', 'ATR', 'ADX', 'Stochastic', 'CCI', 'Volume', 'Ichimoku', 'Fibonacci'];
const strategyTypes = ['Scalper', 'Trend Following', 'Grid', 'Breakout', 'Mean Reversion', 'Martingale', 'Hedging'];

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

const StrategyUnified = () => {
  const [view, setView] = useState<'list' | 'builder'>('list');
  const [strategies, setStrategies] = useState<Strategy[]>([]);

  // Builder State
  const [name, setName] = useState('');
  const [type, setType] = useState(strategyTypes[0]);
  const [description, setDescription] = useState('');
  const [selectedIndicators, setSelectedIndicators] = useState<string[]>([]);
  const [rules, setRules] = useState([{ id: 1, condition: 'entry', description: '' }]);

  const toggleIndicator = (ind: string) => {
    setSelectedIndicators(prev => prev.includes(ind) ? prev.filter(i => i !== ind) : [...prev, ind]);
  };

  const addRule = () => setRules([...rules, { id: Date.now(), condition: 'entry', description: '' }]);
  const removeRule = (id: number) => setRules(rules.filter(r => r.id !== id));

  const handleSave = () => {
    if (!name) return;
    const newStrategy: Strategy = {
      id: Date.now(),
      name,
      type,
      description,
      indicators: selectedIndicators,
      winRate: 0,
      totalTrades: 0,
      status: 'inactive'
    };
    setStrategies([...strategies, newStrategy]);
    setView('list');
    // Reset form
    setName('');
    setType(strategyTypes[0]);
    setDescription('');
    setSelectedIndicators([]);
    setRules([{ id: 1, condition: 'entry', description: '' }]);
  };

  const toggleStatus = (id: number) => {
    setStrategies(strategies.map(s => s.id === id ? { ...s, status: s.status === 'active' ? 'inactive' : 'active' } : s));
  };

  const removeStrategy = (id: number) => {
    setStrategies(strategies.filter(s => s.id !== id));
  };

  if (view === 'list') {
    return (
      <main className="space-y-5">
        <div className="flex items-center justify-between">
          <div>
            <h4 className="text-lg font-semibold text-default-900">Strategies</h4>
            <p className="text-sm text-default-500">Manage your custom trading strategies</p>
          </div>
          <button onClick={() => setView('builder')} className="btn bg-primary/10 text-primary hover:bg-primary hover:text-white">
            <LuPlus className="size-4" /> New Strategy
          </button>
        </div>

        {strategies.length === 0 ? (
          <div className="card !p-12 text-center flex flex-col items-center justify-center">
            <div className="rounded-full bg-primary/10 p-4 mb-4">
              <LuSettings className="size-8 text-primary" />
            </div>
            <h5 className="text-lg font-semibold text-default-900">No Strategies Yet</h5>
            <p className="text-sm text-default-500 mt-2 max-w-sm">You haven't created any custom trading strategies. Click "New Strategy" to build one.</p>
            <button onClick={() => setView('builder')} className="btn mt-6 bg-primary text-white hover:bg-primary-600">
              <LuPlus className="size-4" /> Create First Strategy
            </button>
          </div>
        ) : (
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
                    <p className="mt-1 text-xs text-default-500">{s.description || 'No description'}</p>
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
        )}
      </main>
    );
  }

  return (
    <main className="space-y-5">
      <div className="flex items-center justify-between">
        <div>
          <h4 className="text-lg font-semibold text-default-900">Strategy Builder</h4>
          <p className="text-sm text-default-500">Create a new trading strategy</p>
        </div>
        <nav className="text-sm text-default-500">
          <button onClick={() => setView('list')} className="hover:text-primary transition-colors">Strategies</button>
          {' > '} Builder
        </nav>
      </div>

      {/* Basic Info */}
      <div className="card !p-5">
        <h5 className="mb-4 text-sm font-semibold text-default-900">Basic Information</h5>
        <div className="grid grid-cols-1 gap-4 md:grid-cols-3">
          <div>
            <label className="mb-1.5 block text-sm font-medium text-default-700">Strategy Name</label>
            <input type="text" value={name} onChange={e => setName(e.target.value)} placeholder="e.g. Scalper Pro v2" className="form-input" />
          </div>
          <div>
            <label className="mb-1.5 block text-sm font-medium text-default-700">Type</label>
            <select value={type} onChange={e => setType(e.target.value)} className="form-select">
              {strategyTypes.map(t => <option key={t} value={t}>{t}</option>)}
            </select>
          </div>
          <div>
            <label className="mb-1.5 block text-sm font-medium text-default-700">Description</label>
            <input type="text" value={description} onChange={e => setDescription(e.target.value)} placeholder="Brief description" className="form-input" />
          </div>
        </div>
      </div>

      {/* Indicators */}
      <div className="card !p-5">
        <h5 className="mb-4 text-sm font-semibold text-default-900">Indicators ({selectedIndicators.length} selected)</h5>
        <div className="flex flex-wrap gap-2">
          {indicatorOptions.map(ind => (
            <button
              key={ind}
              onClick={() => toggleIndicator(ind)}
              className={`btn disabled:opacity-40 btn-sm ${
                selectedIndicators.includes(ind)
                  ? 'bg-primary/20 text-primary border border-primary'
                  : 'bg-default-500/10 text-default-600 hover:bg-primary/10 hover:text-primary'
              }`}
            >
              {ind}
            </button>
          ))}
        </div>
      </div>

      {/* Rules */}
      <div className="card !p-5">
        <div className="mb-4 flex items-center justify-between">
          <h5 className="text-sm font-semibold text-default-900">Rules ({rules.length})</h5>
          <button onClick={addRule} className="btn btn-sm bg-primary/10 text-primary hover:bg-primary hover:text-white">
            <LuPlus className="size-4" /> Add Rule
          </button>
        </div>
        <div className="space-y-3">
          {rules.map((rule, i) => (
            <div key={rule.id} className="flex items-center gap-3 rounded-lg border border-default-200/60 dark:border-default-300/10 bg-default-50/30 dark:bg-default-200/5 p-3">
              <span className="flex size-6 items-center justify-center rounded-full bg-primary/10 text-xs font-bold text-primary">{i + 1}</span>
              <select
                value={rule.condition}
                onChange={e => setRules(rules.map(r => r.id === rule.id ? { ...r, condition: e.target.value } : r))}
                className="form-select !h-8 text-xs"
              >
                <option value="entry">Entry</option>
                <option value="exit">Exit</option>
                <option value="filter">Filter</option>
              </select>
              <input
                type="text"
                value={rule.description}
                onChange={e => setRules(rules.map(r => r.id === rule.id ? { ...r, description: e.target.value } : r))}
                placeholder="Describe the rule condition..."
                className="form-input form-input-sm flex-1"
              />
              <button onClick={() => removeRule(rule.id)} className="btn btn-icon btn-sm bg-danger/10 text-danger hover:bg-danger hover:text-white">
                <LuTrash2 className="size-4" />
              </button>
            </div>
          ))}
        </div>
      </div>

      {/* Risk Management */}
      <div className="card !p-5">
        <h5 className="mb-4 text-sm font-semibold text-default-900">Risk Management</h5>
        <div className="grid grid-cols-2 gap-4 md:grid-cols-4">
          <div>
            <label className="mb-1 block text-xs text-default-500">Default Lot Size</label>
            <input type="number" step="0.01" defaultValue="0.01" className="form-input" />
          </div>
          <div>
            <label className="mb-1 block text-xs text-default-500">Max Risk per Trade (%)</label>
            <input type="number" step="0.5" defaultValue="2" className="form-input" />
          </div>
          <div>
            <label className="mb-1 block text-xs text-default-500">Stop Loss (pips)</label>
            <input type="number" defaultValue="20" className="form-input" />
          </div>
          <div>
            <label className="mb-1 block text-xs text-default-500">Take Profit (pips)</label>
            <input type="number" defaultValue="40" className="form-input" />
          </div>
        </div>
      </div>

      <div className="flex gap-3">
        <button onClick={handleSave} className="btn bg-primary/10 text-primary hover:bg-primary hover:text-white">
          <LuSave className="size-4" /> Save Strategy
        </button>
        <button onClick={() => setView('list')} className="btn bg-default-500/10 text-default-600 hover:bg-default-500 hover:text-white">Cancel</button>
      </div>
    </main>
  );
};

export default StrategyUnified;
