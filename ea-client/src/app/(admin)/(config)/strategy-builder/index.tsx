import { useState } from 'react';
import { LuSave, LuPlus, LuTrash2 } from 'react-icons/lu';

const indicatorOptions = ['RSI', 'MACD', 'Bollinger Bands', 'EMA', 'SMA', 'ATR', 'ADX', 'Stochastic', 'CCI', 'Volume', 'Ichimoku', 'Fibonacci'];
const strategyTypes = ['Scalper', 'Trend Following', 'Grid', 'Breakout', 'Mean Reversion', 'Martingale', 'Hedging'];

const StrategyBuilder = () => {
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

  return (
    <main className="space-y-5">
      <div className="flex items-center justify-between">
        <div>
          <h4 className="text-lg font-semibold text-default-900">Strategy Builder</h4>
          <p className="text-sm text-default-500">Create a new trading strategy</p>
        </div>
        <nav className="text-sm text-default-500">Strategy Config &gt; Builder</nav>
      </div>

      {/* Basic Info */}
      <div className="rounded-xl border border-default-200 bg-white p-5">
        <h5 className="mb-4 text-sm font-semibold text-default-900">Basic Information</h5>
        <div className="grid grid-cols-1 gap-4 md:grid-cols-3">
          <div>
            <label className="mb-1.5 block text-sm font-medium text-default-700">Strategy Name</label>
            <input type="text" value={name} onChange={e => setName(e.target.value)} placeholder="e.g. Scalper Pro v2" className="w-full rounded-md border border-default-200 px-3 py-2.5 text-sm focus:border-primary focus:outline-none" />
          </div>
          <div>
            <label className="mb-1.5 block text-sm font-medium text-default-700">Type</label>
            <select value={type} onChange={e => setType(e.target.value)} className="w-full rounded-md border border-default-200 px-3 py-2.5 text-sm focus:border-primary focus:outline-none">
              {strategyTypes.map(t => <option key={t} value={t}>{t}</option>)}
            </select>
          </div>
          <div>
            <label className="mb-1.5 block text-sm font-medium text-default-700">Description</label>
            <input type="text" value={description} onChange={e => setDescription(e.target.value)} placeholder="Brief description" className="w-full rounded-md border border-default-200 px-3 py-2.5 text-sm focus:border-primary focus:outline-none" />
          </div>
        </div>
      </div>

      {/* Indicators */}
      <div className="rounded-xl border border-default-200 bg-white p-5">
        <h5 className="mb-4 text-sm font-semibold text-default-900">Indicators ({selectedIndicators.length} selected)</h5>
        <div className="flex flex-wrap gap-2">
          {indicatorOptions.map(ind => (
            <button
              key={ind}
              onClick={() => toggleIndicator(ind)}
              className={`rounded-lg px-3 py-1.5 text-xs font-medium transition ${
                selectedIndicators.includes(ind)
                  ? 'bg-primary text-white'
                  : 'border border-default-200 text-default-600 hover:bg-default-50'
              }`}
            >
              {ind}
            </button>
          ))}
        </div>
      </div>

      {/* Rules */}
      <div className="rounded-xl border border-default-200 bg-white p-5">
        <div className="mb-4 flex items-center justify-between">
          <h5 className="text-sm font-semibold text-default-900">Rules ({rules.length})</h5>
          <button onClick={addRule} className="inline-flex items-center gap-1 rounded-md bg-primary/10 px-2.5 py-1 text-xs font-medium text-primary hover:bg-primary/20">
            <LuPlus className="size-3" /> Add Rule
          </button>
        </div>
        <div className="space-y-3">
          {rules.map((rule, i) => (
            <div key={rule.id} className="flex items-center gap-3 rounded-lg border border-default-200 p-3">
              <span className="flex size-6 items-center justify-center rounded-full bg-primary/10 text-xs font-bold text-primary">{i + 1}</span>
              <select
                value={rule.condition}
                onChange={e => setRules(rules.map(r => r.id === rule.id ? { ...r, condition: e.target.value } : r))}
                className="rounded-md border border-default-200 px-2 py-1.5 text-xs focus:border-primary focus:outline-none"
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
                className="flex-1 rounded-md border border-default-200 px-3 py-1.5 text-xs focus:border-primary focus:outline-none"
              />
              <button onClick={() => removeRule(rule.id)} className="rounded p-1 text-red-400 hover:bg-red-50">
                <LuTrash2 className="size-3.5" />
              </button>
            </div>
          ))}
        </div>
      </div>

      {/* Risk Management */}
      <div className="rounded-xl border border-default-200 bg-white p-5">
        <h5 className="mb-4 text-sm font-semibold text-default-900">Risk Management</h5>
        <div className="grid grid-cols-2 gap-4 md:grid-cols-4">
          <div>
            <label className="mb-1 block text-xs text-default-500">Default Lot Size</label>
            <input type="number" step="0.01" defaultValue="0.01" className="w-full rounded-md border border-default-200 px-3 py-2 text-sm focus:border-primary focus:outline-none" />
          </div>
          <div>
            <label className="mb-1 block text-xs text-default-500">Max Risk per Trade (%)</label>
            <input type="number" step="0.5" defaultValue="2" className="w-full rounded-md border border-default-200 px-3 py-2 text-sm focus:border-primary focus:outline-none" />
          </div>
          <div>
            <label className="mb-1 block text-xs text-default-500">Stop Loss (pips)</label>
            <input type="number" defaultValue="20" className="w-full rounded-md border border-default-200 px-3 py-2 text-sm focus:border-primary focus:outline-none" />
          </div>
          <div>
            <label className="mb-1 block text-xs text-default-500">Take Profit (pips)</label>
            <input type="number" defaultValue="40" className="w-full rounded-md border border-default-200 px-3 py-2 text-sm focus:border-primary focus:outline-none" />
          </div>
        </div>
      </div>

      <div className="flex gap-3">
        <button className="inline-flex items-center gap-2 rounded-md bg-primary px-5 py-2.5 text-sm font-medium text-white hover:bg-primary/90">
          <LuSave className="size-4" /> Save Strategy
        </button>
        <a href="/strategy/list" className="rounded-md border border-default-200 px-5 py-2.5 text-sm font-medium text-default-600 hover:bg-default-100">Cancel</a>
      </div>
    </main>
  );
};

export default StrategyBuilder;
