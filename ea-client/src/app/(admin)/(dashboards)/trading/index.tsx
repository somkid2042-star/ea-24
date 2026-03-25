import { useState } from 'react';
import { LuTrendingUp, LuTrendingDown, LuWallet, LuActivity, LuChartColumn, LuClock, LuTarget, LuShieldAlert } from 'react-icons/lu';
import PageMeta from '@/components/PageMeta';

type Position = {
  id: number;
  symbol: string;
  type: 'BUY' | 'SELL';
  lot: number;
  entry: number;
  current: number;
  pnl: number;
  ea: string;
  time: string;
};

type EAPerf = {
  name: string;
  trades: number;
  winRate: number;
  profit: number;
  status: 'running' | 'paused';
};

const mockPositions: Position[] = [
  { id: 1, symbol: 'EURUSD', type: 'BUY', lot: 0.05, entry: 1.08450, current: 1.08520, pnl: 35.00, ea: 'EA-24 Scalper', time: '14:23' },
  { id: 2, symbol: 'GBPUSD', type: 'SELL', lot: 0.10, entry: 1.26780, current: 1.26650, pnl: 130.00, ea: 'EA-24 Trend', time: '09:15' },
  { id: 3, symbol: 'XAUUSD', type: 'BUY', lot: 0.02, entry: 2645.50, current: 2643.20, pnl: -46.00, ea: 'EA-24 Grid', time: '11:42' },
  { id: 4, symbol: 'USDJPY', type: 'SELL', lot: 0.03, entry: 150.450, current: 150.380, pnl: 14.07, ea: 'EA-24 Scalper', time: '15:01' },
  { id: 5, symbol: 'AUDUSD', type: 'BUY', lot: 0.08, entry: 0.65230, current: 0.65310, pnl: 64.00, ea: 'EA-24 Trend', time: '08:30' },
];

const mockEAPerf: EAPerf[] = [
  { name: 'EA-24 Scalper', trades: 147, winRate: 72.4, profit: 1245.60, status: 'running' },
  { name: 'EA-24 Trend', trades: 83, winRate: 65.1, profit: 2890.30, status: 'running' },
  { name: 'EA-24 Grid', trades: 256, winRate: 58.2, profit: -320.50, status: 'paused' },
];

const pnlData = [120, 95, 180, -40, 210, 150, 320, 280, 190, 350, 410, 380, 290, 520, 470, 390, 310, 560, 480, 610];

const TradingDashboard = () => {
  const [selectedPeriod, setSelectedPeriod] = useState('today');

  const balance = 10000.00;
  const equity = 10197.07;
  const pnlToday = 197.07;
  const activeTrades = mockPositions.length;
  const totalPnl = mockPositions.reduce((sum, p) => sum + p.pnl, 0);

  const maxVal = Math.max(...pnlData.map(Math.abs));

  return (
    <>
      <PageMeta title="Dashboard" />
      <main className="space-y-5">
        {/* Header */}
        <div className="flex items-center justify-between">
          <div>
            <h4 className="text-lg font-semibold text-default-900">Trading Dashboard</h4>
            <p className="text-sm text-default-500">Real-time overview of your trading activity</p>
          </div>
          <div className="flex gap-1 rounded-lg border border-default-200 bg-white p-0.5">
            {['today', '7d', '30d', 'all'].map(p => (
              <button
                key={p}
                onClick={() => setSelectedPeriod(p)}
                className={`rounded-md px-3 py-1.5 text-xs font-medium transition ${
                  selectedPeriod === p ? 'bg-primary text-white' : 'text-default-600 hover:bg-default-100'
                }`}
              >
                {p === 'today' ? 'Today' : p === '7d' ? '7 Days' : p === '30d' ? '30 Days' : 'All Time'}
              </button>
            ))}
          </div>
        </div>

        {/* Account Summary Cards */}
        <div className="grid grid-cols-2 gap-4 lg:grid-cols-4">
          <div className="group rounded-xl border border-default-200 bg-white p-5 transition hover:shadow-md hover:shadow-primary/5">
            <div className="mb-3 flex items-center justify-between">
              <span className="text-xs font-medium uppercase tracking-wider text-default-400">Balance</span>
              <div className="rounded-lg bg-blue-50 p-2 text-blue-500"><LuWallet className="size-4" /></div>
            </div>
            <p className="text-2xl font-bold text-default-900">${balance.toLocaleString('en-US', { minimumFractionDigits: 2 })}</p>
            <p className="mt-1 text-xs text-default-500">Account balance</p>
          </div>
          <div className="group rounded-xl border border-default-200 bg-white p-5 transition hover:shadow-md hover:shadow-primary/5">
            <div className="mb-3 flex items-center justify-between">
              <span className="text-xs font-medium uppercase tracking-wider text-default-400">Equity</span>
              <div className="rounded-lg bg-violet-50 p-2 text-violet-500"><LuActivity className="size-4" /></div>
            </div>
            <p className="text-2xl font-bold text-default-900">${equity.toLocaleString('en-US', { minimumFractionDigits: 2 })}</p>
            <p className="mt-1 text-xs text-default-500">Including open P&L</p>
          </div>
          <div className="group rounded-xl border border-default-200 bg-white p-5 transition hover:shadow-md hover:shadow-primary/5">
            <div className="mb-3 flex items-center justify-between">
              <span className="text-xs font-medium uppercase tracking-wider text-default-400">P&L Today</span>
              <div className={`rounded-lg p-2 ${pnlToday >= 0 ? 'bg-green-50 text-green-500' : 'bg-red-50 text-red-500'}`}>
                {pnlToday >= 0 ? <LuTrendingUp className="size-4" /> : <LuTrendingDown className="size-4" />}
              </div>
            </div>
            <p className={`text-2xl font-bold ${pnlToday >= 0 ? 'text-green-600' : 'text-red-600'}`}>
              {pnlToday >= 0 ? '+' : ''}${pnlToday.toFixed(2)}
            </p>
            <p className="mt-1 text-xs text-default-500">{pnlToday >= 0 ? '+' : ''}{((pnlToday / balance) * 100).toFixed(2)}% return</p>
          </div>
          <div className="group rounded-xl border border-default-200 bg-white p-5 transition hover:shadow-md hover:shadow-primary/5">
            <div className="mb-3 flex items-center justify-between">
              <span className="text-xs font-medium uppercase tracking-wider text-default-400">Active Trades</span>
              <div className="rounded-lg bg-amber-50 p-2 text-amber-500"><LuChartColumn className="size-4" /></div>
            </div>
            <p className="text-2xl font-bold text-default-900">{activeTrades}</p>
            <p className={`mt-1 text-xs ${totalPnl >= 0 ? 'text-green-600' : 'text-red-600'}`}>
              Floating: {totalPnl >= 0 ? '+' : ''}${totalPnl.toFixed(2)}
            </p>
          </div>
        </div>

        {/* P&L Chart + Quick Stats */}
        <div className="grid grid-cols-1 gap-5 lg:grid-cols-3">
          {/* P&L Chart */}
          <div className="lg:col-span-2 rounded-xl border border-default-200 bg-white p-5">
            <div className="mb-4 flex items-center justify-between">
              <h5 className="text-sm font-semibold text-default-900">Profit & Loss</h5>
              <span className="text-xs text-green-600 font-medium">+$2,815.40 total</span>
            </div>
            <div className="flex items-end gap-1" style={{ height: 180 }}>
              {pnlData.map((val, i) => (
                <div key={i} className="flex-1 flex flex-col justify-end items-center">
                  <div
                    className={`w-full rounded-t transition-all hover:opacity-80 ${val >= 0 ? 'bg-gradient-to-t from-green-500 to-green-300' : 'bg-gradient-to-t from-red-500 to-red-300'}`}
                    style={{ height: `${(Math.abs(val) / maxVal) * 100}%`, minHeight: 4 }}
                  />
                </div>
              ))}
            </div>
            <div className="mt-2 flex justify-between text-[10px] text-default-400">
              <span>Mar 7</span><span>Mar 12</span><span>Mar 17</span><span>Mar 22</span><span>Mar 26</span>
            </div>
          </div>

          {/* Quick Stats */}
          <div className="rounded-xl border border-default-200 bg-white p-5">
            <h5 className="mb-4 text-sm font-semibold text-default-900">Quick Stats</h5>
            <div className="space-y-4">
              <div className="flex items-center gap-3">
                <div className="rounded-lg bg-green-50 p-2.5"><LuTarget className="size-4 text-green-500" /></div>
                <div className="flex-1">
                  <p className="text-xs text-default-500">Win Rate</p>
                  <p className="text-lg font-bold text-default-900">68.3%</p>
                </div>
                <div className="h-2 w-20 rounded-full bg-default-100 overflow-hidden">
                  <div className="h-full rounded-full bg-green-500" style={{ width: '68.3%' }} />
                </div>
              </div>
              <div className="flex items-center gap-3">
                <div className="rounded-lg bg-blue-50 p-2.5"><LuChartColumn className="size-4 text-blue-500" /></div>
                <div className="flex-1">
                  <p className="text-xs text-default-500">Total Trades</p>
                  <p className="text-lg font-bold text-default-900">486</p>
                </div>
              </div>
              <div className="flex items-center gap-3">
                <div className="rounded-lg bg-violet-50 p-2.5"><LuClock className="size-4 text-violet-500" /></div>
                <div className="flex-1">
                  <p className="text-xs text-default-500">Avg Duration</p>
                  <p className="text-lg font-bold text-default-900">2h 34m</p>
                </div>
              </div>
              <div className="flex items-center gap-3">
                <div className="rounded-lg bg-red-50 p-2.5"><LuShieldAlert className="size-4 text-red-500" /></div>
                <div className="flex-1">
                  <p className="text-xs text-default-500">Max Drawdown</p>
                  <p className="text-lg font-bold text-red-600">-4.2%</p>
                </div>
                <div className="h-2 w-20 rounded-full bg-default-100 overflow-hidden">
                  <div className="h-full rounded-full bg-red-400" style={{ width: '4.2%' }} />
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* Active Positions */}
        <div className="rounded-xl border border-default-200 bg-white p-5">
          <div className="mb-4 flex items-center justify-between">
            <h5 className="text-sm font-semibold text-default-900">Active Positions</h5>
            <span className="text-xs text-default-500">{mockPositions.length} open trades</span>
          </div>
          <div className="overflow-x-auto">
            <table className="w-full text-left text-sm">
              <thead className="border-b border-default-200 text-xs uppercase text-default-400">
                <tr>
                  <th className="px-3 py-2.5">Symbol</th>
                  <th className="px-3 py-2.5">Type</th>
                  <th className="px-3 py-2.5">Lot</th>
                  <th className="px-3 py-2.5">Entry</th>
                  <th className="px-3 py-2.5">Current</th>
                  <th className="px-3 py-2.5">P&L</th>
                  <th className="px-3 py-2.5">EA</th>
                  <th className="px-3 py-2.5">Time</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-default-100">
                {mockPositions.map(pos => (
                  <tr key={pos.id} className="transition hover:bg-default-50/50">
                    <td className="px-3 py-3 font-semibold text-primary">{pos.symbol}</td>
                    <td className="px-3 py-3">
                      <span className={`inline-flex rounded px-2 py-0.5 text-xs font-bold ${
                        pos.type === 'BUY' ? 'bg-green-100 text-green-700' : 'bg-red-100 text-red-700'
                      }`}>{pos.type}</span>
                    </td>
                    <td className="px-3 py-3 text-default-600">{pos.lot}</td>
                    <td className="px-3 py-3 font-mono text-xs text-default-600">{pos.entry}</td>
                    <td className="px-3 py-3 font-mono text-xs text-default-900">{pos.current}</td>
                    <td className={`px-3 py-3 font-semibold ${pos.pnl >= 0 ? 'text-green-600' : 'text-red-600'}`}>
                      {pos.pnl >= 0 ? '+' : ''}${pos.pnl.toFixed(2)}
                    </td>
                    <td className="px-3 py-3 text-xs text-default-500">{pos.ea}</td>
                    <td className="px-3 py-3 text-xs text-default-400">{pos.time}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>

        {/* EA Performance */}
        <div className="grid grid-cols-1 gap-4 md:grid-cols-3">
          {mockEAPerf.map(ea => (
            <div key={ea.name} className="rounded-xl border border-default-200 bg-white p-5 transition hover:shadow-md">
              <div className="mb-3 flex items-center justify-between">
                <h6 className="text-sm font-semibold text-default-900">{ea.name}</h6>
                <span className={`rounded-full px-2 py-0.5 text-[10px] font-medium ${
                  ea.status === 'running' ? 'bg-green-100 text-green-700' : 'bg-yellow-100 text-yellow-700'
                }`}>
                  {ea.status === 'running' ? '● Running' : '⏸ Paused'}
                </span>
              </div>
              <div className="grid grid-cols-3 gap-2 text-center">
                <div>
                  <p className="text-lg font-bold text-default-900">{ea.trades}</p>
                  <p className="text-[10px] text-default-400">Trades</p>
                </div>
                <div>
                  <p className="text-lg font-bold text-default-900">{ea.winRate}%</p>
                  <p className="text-[10px] text-default-400">Win Rate</p>
                </div>
                <div>
                  <p className={`text-lg font-bold ${ea.profit >= 0 ? 'text-green-600' : 'text-red-600'}`}>
                    ${ea.profit.toFixed(0)}
                  </p>
                  <p className="text-[10px] text-default-400">Profit</p>
                </div>
              </div>
              {/* Mini progress bar */}
              <div className="mt-3 h-1.5 w-full rounded-full bg-default-100 overflow-hidden">
                <div
                  className={`h-full rounded-full ${ea.profit >= 0 ? 'bg-gradient-to-r from-green-400 to-green-500' : 'bg-gradient-to-r from-red-400 to-red-500'}`}
                  style={{ width: `${ea.winRate}%` }}
                />
              </div>
            </div>
          ))}
        </div>
      </main>
    </>
  );
};

export default TradingDashboard;
