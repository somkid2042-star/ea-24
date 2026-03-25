import { useState } from 'react';
import { LuMonitorSmartphone, LuPlus, LuRefreshCw, LuTrash2, LuPlay, LuSquare, LuSettings, LuChartCandlestick, LuLink, LuCircleCheck, LuCircleX } from 'react-icons/lu';

type MT5Instance = {
  id: number;
  name: string;
  path: string;
  status: 'running' | 'stopped';
  account: string;
  server: string;
};

type EAConfig = {
  id: number;
  name: string;
  symbol: string;
  timeframe: string;
  magicNumber: number;
  lotSize: number;
  riskPercent: number;
  maxSpread: number;
  slippage: number;
  status: 'active' | 'inactive';
};

// Mock data
const mockInstances: MT5Instance[] = [
  { id: 1, name: 'MetaTrader 5 - ICMarkets', path: 'C:\\Program Files\\MetaTrader 5 IC', status: 'running', account: '5012345', server: 'ICMarketsSC-Demo' },
  { id: 2, name: 'MetaTrader 5 - Exness', path: 'C:\\Program Files\\MetaTrader 5 Exness', status: 'stopped', account: '7890123', server: 'Exness-MT5Real' },
  { id: 3, name: 'MetaTrader 5 - XM', path: 'C:\\Program Files\\MetaTrader 5 XM', status: 'running', account: '1234567', server: 'XMGlobal-MT5' },
];

const mockEAs: EAConfig[] = [
  { id: 1, name: 'EA-24 Scalper', symbol: 'EURUSD', timeframe: 'M5', magicNumber: 240001, lotSize: 0.01, riskPercent: 2, maxSpread: 15, slippage: 3, status: 'active' },
  { id: 2, name: 'EA-24 Trend', symbol: 'GBPUSD', timeframe: 'H1', magicNumber: 240002, lotSize: 0.05, riskPercent: 3, maxSpread: 20, slippage: 5, status: 'active' },
  { id: 3, name: 'EA-24 Grid', symbol: 'XAUUSD', timeframe: 'M15', magicNumber: 240003, lotSize: 0.02, riskPercent: 1.5, maxSpread: 30, slippage: 5, status: 'inactive' },
];

const symbols = ['EURUSD', 'GBPUSD', 'USDJPY', 'AUDUSD', 'XAUUSD', 'BTCUSD', 'US30', 'NAS100'];
const timeframes = ['M1', 'M5', 'M15', 'M30', 'H1', 'H4', 'D1', 'W1'];

const MT5Settings = () => {
  const [instances] = useState<MT5Instance[]>(mockInstances);
  const [eas, setEAs] = useState<EAConfig[]>(mockEAs);
  const [showAddEA, setShowAddEA] = useState(false);
  const [newEA, setNewEA] = useState({ name: '', symbol: 'EURUSD', timeframe: 'M5', magicNumber: 0, lotSize: 0.01, riskPercent: 2, maxSpread: 15, slippage: 3 });
  const [connectionTest, setConnectionTest] = useState<'idle' | 'testing' | 'success' | 'failed'>('idle');

  const handleAddEA = () => {
    if (!newEA.name) return;
    setEAs([...eas, { ...newEA, id: Date.now(), status: 'inactive' }]);
    setNewEA({ name: '', symbol: 'EURUSD', timeframe: 'M5', magicNumber: 0, lotSize: 0.01, riskPercent: 2, maxSpread: 15, slippage: 3 });
    setShowAddEA(false);
  };

  const toggleEAStatus = (id: number) => {
    setEAs(eas.map(ea => ea.id === id ? { ...ea, status: ea.status === 'active' ? 'inactive' : 'active' } : ea));
  };

  const removeEA = (id: number) => {
    setEAs(eas.filter(ea => ea.id !== id));
  };

  const testConnection = () => {
    setConnectionTest('testing');
    setTimeout(() => setConnectionTest('success'), 1500);
  };

  return (
    <main className="space-y-6">
      {/* Page Header */}
      <div className="flex items-center justify-between">
        <div>
          <h4 className="text-lg font-semibold text-default-900">MT5 Settings</h4>
          <p className="mt-1 text-sm text-default-500">Manage MetaTrader 5 instances and Expert Advisors</p>
        </div>
        <nav className="text-sm text-default-500">
          Tailwick &gt; Config Server &gt; MT5 Settings
        </nav>
      </div>

      {/* Section 1: MT5 Instances */}
      <div className="rounded-lg border border-default-200 bg-white p-5 dark:bg-default-50">
        <div className="mb-4 flex items-center justify-between">
          <div className="flex items-center gap-2">
            <LuMonitorSmartphone className="size-5 text-primary" />
            <h5 className="text-base font-semibold text-default-900">
              MT5 Instances ({instances.length} found)
            </h5>
          </div>
          <div className="flex gap-2">
            <button className="inline-flex items-center gap-1.5 rounded-md border border-default-200 px-3 py-1.5 text-xs font-medium text-default-700 transition hover:bg-default-100">
              <LuRefreshCw className="size-3.5" /> Refresh
            </button>
            <button className="inline-flex items-center gap-1.5 rounded-md bg-primary px-3 py-1.5 text-xs font-medium text-white transition hover:bg-primary/90">
              <LuPlus className="size-3.5" /> Add Path
            </button>
          </div>
        </div>

        <div className="overflow-x-auto">
          <table className="w-full text-left text-sm">
            <thead className="border-b border-default-200 text-xs uppercase text-default-500">
              <tr>
                <th className="px-4 py-3">Instance Name</th>
                <th className="px-4 py-3">Path</th>
                <th className="px-4 py-3">Account</th>
                <th className="px-4 py-3">Server</th>
                <th className="px-4 py-3">Status</th>
                <th className="px-4 py-3">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-default-200">
              {instances.map(inst => (
                <tr key={inst.id} className="hover:bg-default-50/50">
                  <td className="px-4 py-3 font-medium text-default-900">{inst.name}</td>
                  <td className="px-4 py-3 text-default-500 font-mono text-xs">{inst.path}</td>
                  <td className="px-4 py-3 text-default-700">{inst.account}</td>
                  <td className="px-4 py-3 text-default-500">{inst.server}</td>
                  <td className="px-4 py-3">
                    <span className={`inline-flex items-center gap-1 rounded-full px-2.5 py-0.5 text-xs font-medium ${
                      inst.status === 'running' 
                        ? 'bg-green-100 text-green-700 dark:bg-green-500/20 dark:text-green-400' 
                        : 'bg-red-100 text-red-700 dark:bg-red-500/20 dark:text-red-400'
                    }`}>
                      <span className={`size-1.5 rounded-full ${inst.status === 'running' ? 'bg-green-500' : 'bg-red-500'}`} />
                      {inst.status === 'running' ? 'Running' : 'Stopped'}
                    </span>
                  </td>
                  <td className="px-4 py-3">
                    <div className="flex gap-1">
                      {inst.status === 'running' ? (
                        <button className="rounded p-1.5 text-orange-500 hover:bg-orange-50" title="Stop">
                          <LuSquare className="size-4" />
                        </button>
                      ) : (
                        <button className="rounded p-1.5 text-green-500 hover:bg-green-50" title="Start">
                          <LuPlay className="size-4" />
                        </button>
                      )}
                      <button className="rounded p-1.5 text-default-400 hover:bg-default-100" title="Settings">
                        <LuSettings className="size-4" />
                      </button>
                      <button className="rounded p-1.5 text-red-400 hover:bg-red-50" title="Remove">
                        <LuTrash2 className="size-4" />
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      {/* Section 2: EA Configuration */}
      <div className="rounded-lg border border-default-200 bg-white p-5 dark:bg-default-50">
        <div className="mb-4 flex items-center justify-between">
          <div className="flex items-center gap-2">
            <LuChartCandlestick className="size-5 text-primary" />
            <h5 className="text-base font-semibold text-default-900">
              Expert Advisors ({eas.length})
            </h5>
          </div>
          <button
            onClick={() => setShowAddEA(!showAddEA)}
            className="inline-flex items-center gap-1.5 rounded-md bg-primary px-3 py-1.5 text-xs font-medium text-white transition hover:bg-primary/90"
          >
            <LuPlus className="size-3.5" /> Add EA to Chart
          </button>
        </div>

        {/* Add EA Form */}
        {showAddEA && (
          <div className="mb-4 rounded-lg border border-primary/20 bg-primary/5 p-4">
            <h6 className="mb-3 text-sm font-semibold text-default-900">Add EA to Chart</h6>
            <div className="grid grid-cols-2 gap-3 md:grid-cols-4">
              <div>
                <label className="mb-1 block text-xs text-default-500">EA Name</label>
                <input
                  type="text"
                  value={newEA.name}
                  onChange={e => setNewEA({ ...newEA, name: e.target.value })}
                  placeholder="e.g. EA-24 Scalper"
                  className="w-full rounded-md border border-default-200 px-3 py-2 text-sm focus:border-primary focus:outline-none"
                />
              </div>
              <div>
                <label className="mb-1 block text-xs text-default-500">Symbol</label>
                <select
                  value={newEA.symbol}
                  onChange={e => setNewEA({ ...newEA, symbol: e.target.value })}
                  className="w-full rounded-md border border-default-200 px-3 py-2 text-sm focus:border-primary focus:outline-none"
                >
                  {symbols.map(s => <option key={s} value={s}>{s}</option>)}
                </select>
              </div>
              <div>
                <label className="mb-1 block text-xs text-default-500">Timeframe</label>
                <select
                  value={newEA.timeframe}
                  onChange={e => setNewEA({ ...newEA, timeframe: e.target.value })}
                  className="w-full rounded-md border border-default-200 px-3 py-2 text-sm focus:border-primary focus:outline-none"
                >
                  {timeframes.map(t => <option key={t} value={t}>{t}</option>)}
                </select>
              </div>
              <div>
                <label className="mb-1 block text-xs text-default-500">Magic Number</label>
                <input
                  type="number"
                  value={newEA.magicNumber}
                  onChange={e => setNewEA({ ...newEA, magicNumber: Number(e.target.value) })}
                  className="w-full rounded-md border border-default-200 px-3 py-2 text-sm focus:border-primary focus:outline-none"
                />
              </div>
              <div>
                <label className="mb-1 block text-xs text-default-500">Lot Size</label>
                <input
                  type="number"
                  step="0.01"
                  value={newEA.lotSize}
                  onChange={e => setNewEA({ ...newEA, lotSize: Number(e.target.value) })}
                  className="w-full rounded-md border border-default-200 px-3 py-2 text-sm focus:border-primary focus:outline-none"
                />
              </div>
              <div>
                <label className="mb-1 block text-xs text-default-500">Risk %</label>
                <input
                  type="number"
                  step="0.5"
                  value={newEA.riskPercent}
                  onChange={e => setNewEA({ ...newEA, riskPercent: Number(e.target.value) })}
                  className="w-full rounded-md border border-default-200 px-3 py-2 text-sm focus:border-primary focus:outline-none"
                />
              </div>
              <div>
                <label className="mb-1 block text-xs text-default-500">Max Spread (pts)</label>
                <input
                  type="number"
                  value={newEA.maxSpread}
                  onChange={e => setNewEA({ ...newEA, maxSpread: Number(e.target.value) })}
                  className="w-full rounded-md border border-default-200 px-3 py-2 text-sm focus:border-primary focus:outline-none"
                />
              </div>
              <div>
                <label className="mb-1 block text-xs text-default-500">Slippage (pts)</label>
                <input
                  type="number"
                  value={newEA.slippage}
                  onChange={e => setNewEA({ ...newEA, slippage: Number(e.target.value) })}
                  className="w-full rounded-md border border-default-200 px-3 py-2 text-sm focus:border-primary focus:outline-none"
                />
              </div>
            </div>
            <div className="mt-3 flex gap-2">
              <button
                onClick={handleAddEA}
                className="rounded-md bg-primary px-4 py-2 text-xs font-medium text-white hover:bg-primary/90"
              >
                Add EA
              </button>
              <button
                onClick={() => setShowAddEA(false)}
                className="rounded-md border border-default-200 px-4 py-2 text-xs font-medium text-default-600 hover:bg-default-100"
              >
                Cancel
              </button>
            </div>
          </div>
        )}

        {/* EA Table */}
        <div className="overflow-x-auto">
          <table className="w-full text-left text-sm">
            <thead className="border-b border-default-200 text-xs uppercase text-default-500">
              <tr>
                <th className="px-4 py-3">EA Name</th>
                <th className="px-4 py-3">Symbol</th>
                <th className="px-4 py-3">TF</th>
                <th className="px-4 py-3">Magic</th>
                <th className="px-4 py-3">Lot</th>
                <th className="px-4 py-3">Risk %</th>
                <th className="px-4 py-3">Spread</th>
                <th className="px-4 py-3">Slip</th>
                <th className="px-4 py-3">Status</th>
                <th className="px-4 py-3">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-default-200">
              {eas.map(ea => (
                <tr key={ea.id} className="hover:bg-default-50/50">
                  <td className="px-4 py-3 font-medium text-default-900">{ea.name}</td>
                  <td className="px-4 py-3 font-mono text-xs text-primary font-semibold">{ea.symbol}</td>
                  <td className="px-4 py-3 text-default-600">{ea.timeframe}</td>
                  <td className="px-4 py-3 font-mono text-xs text-default-500">{ea.magicNumber}</td>
                  <td className="px-4 py-3 text-default-700">{ea.lotSize}</td>
                  <td className="px-4 py-3 text-default-700">{ea.riskPercent}%</td>
                  <td className="px-4 py-3 text-default-500">{ea.maxSpread}</td>
                  <td className="px-4 py-3 text-default-500">{ea.slippage}</td>
                  <td className="px-4 py-3">
                    <button onClick={() => toggleEAStatus(ea.id)}>
                      <span className={`inline-flex items-center gap-1 rounded-full px-2.5 py-0.5 text-xs font-medium cursor-pointer ${
                        ea.status === 'active'
                          ? 'bg-green-100 text-green-700'
                          : 'bg-default-100 text-default-500'
                      }`}>
                        {ea.status === 'active' ? '● Active' : '○ Inactive'}
                      </span>
                    </button>
                  </td>
                  <td className="px-4 py-3">
                    <div className="flex gap-1">
                      <button className="rounded p-1.5 text-default-400 hover:bg-default-100" title="Edit">
                        <LuSettings className="size-4" />
                      </button>
                      <button
                        onClick={() => removeEA(ea.id)}
                        className="rounded p-1.5 text-red-400 hover:bg-red-50"
                        title="Remove"
                      >
                        <LuTrash2 className="size-4" />
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      {/* Section 3: Connection Settings */}
      <div className="rounded-lg border border-default-200 bg-white p-5 dark:bg-default-50">
        <div className="mb-4 flex items-center gap-2">
          <LuLink className="size-5 text-primary" />
          <h5 className="text-base font-semibold text-default-900">Connection Settings</h5>
        </div>

        <div className="grid grid-cols-1 gap-4 md:grid-cols-3">
          <div>
            <label className="mb-1.5 block text-sm font-medium text-default-700">MT5 Server</label>
            <input
              type="text"
              defaultValue="ICMarketsSC-Demo"
              className="w-full rounded-md border border-default-200 px-3 py-2.5 text-sm focus:border-primary focus:outline-none"
            />
          </div>
          <div>
            <label className="mb-1.5 block text-sm font-medium text-default-700">Login ID</label>
            <input
              type="text"
              defaultValue="5012345"
              className="w-full rounded-md border border-default-200 px-3 py-2.5 text-sm focus:border-primary focus:outline-none"
            />
          </div>
          <div>
            <label className="mb-1.5 block text-sm font-medium text-default-700">Password</label>
            <input
              type="password"
              defaultValue="password123"
              className="w-full rounded-md border border-default-200 px-3 py-2.5 text-sm focus:border-primary focus:outline-none"
            />
          </div>
        </div>

        <div className="mt-4 flex items-center gap-3">
          <button
            onClick={testConnection}
            disabled={connectionTest === 'testing'}
            className="inline-flex items-center gap-2 rounded-md bg-primary px-4 py-2 text-sm font-medium text-white hover:bg-primary/90 disabled:opacity-50"
          >
            {connectionTest === 'testing' ? (
              <><LuRefreshCw className="size-4 animate-spin" /> Testing...</>
            ) : (
              <><LuLink className="size-4" /> Test Connection</>
            )}
          </button>
          <button className="rounded-md border border-default-200 px-4 py-2 text-sm font-medium text-default-600 hover:bg-default-100">
            Save Settings
          </button>
          {connectionTest === 'success' && (
            <span className="inline-flex items-center gap-1 text-sm text-green-600">
              <LuCircleCheck className="size-4" /> Connected successfully
            </span>
          )}
          {connectionTest === 'failed' && (
            <span className="inline-flex items-center gap-1 text-sm text-red-600">
              <LuCircleX className="size-4" /> Connection failed
            </span>
          )}
        </div>
      </div>
    </main>
  );
};

export default MT5Settings;
