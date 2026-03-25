import { LuX } from 'react-icons/lu';

type Trade = {
  id: number;
  symbol: string;
  type: 'BUY' | 'SELL';
  lot: number;
  entry: number;
  current: number;
  sl: number;
  tp: number;
  pnl: number;
  strategy: string;
  openTime: string;
  duration: string;
};

const mockTrades: Trade[] = [
  { id: 1, symbol: 'EURUSD', type: 'BUY', lot: 0.05, entry: 1.08450, current: 1.08520, sl: 1.08250, tp: 1.08750, pnl: 35.00, strategy: 'Scalper Pro', openTime: '2025-03-26 14:23', duration: '1h 12m' },
  { id: 2, symbol: 'GBPUSD', type: 'SELL', lot: 0.10, entry: 1.26780, current: 1.26650, sl: 1.27000, tp: 1.26300, pnl: 130.00, strategy: 'Trend Rider', openTime: '2025-03-26 09:15', duration: '6h 20m' },
  { id: 3, symbol: 'XAUUSD', type: 'BUY', lot: 0.02, entry: 2645.50, current: 2643.20, sl: 2640.00, tp: 2655.00, pnl: -46.00, strategy: 'Grid Master', openTime: '2025-03-26 11:42', duration: '3h 53m' },
  { id: 4, symbol: 'USDJPY', type: 'SELL', lot: 0.03, entry: 150.450, current: 150.380, sl: 150.700, tp: 150.000, pnl: 14.07, strategy: 'Scalper Pro', openTime: '2025-03-26 15:01', duration: '0h 34m' },
  { id: 5, symbol: 'AUDUSD', type: 'BUY', lot: 0.08, entry: 0.65230, current: 0.65310, sl: 0.65050, tp: 0.65500, pnl: 64.00, strategy: 'Trend Rider', openTime: '2025-03-26 08:30', duration: '7h 05m' },
  { id: 6, symbol: 'BTCUSD', type: 'BUY', lot: 0.01, entry: 87250.0, current: 87480.0, sl: 86800.0, tp: 88000.0, pnl: 23.00, strategy: 'Breakout Hunter', openTime: '2025-03-26 10:00', duration: '5h 35m' },
];

const ActiveTrades = () => {
  const totalPnl = mockTrades.reduce((s, t) => s + t.pnl, 0);

  return (
    <main className="space-y-5">
      <div className="flex items-center justify-between">
        <div>
          <h4 className="text-lg font-semibold text-default-900">Active Trades</h4>
          <p className="text-sm text-default-500">{mockTrades.length} open positions</p>
        </div>
        <div className={`rounded-lg px-4 py-2 text-sm font-bold ${totalPnl >= 0 ? 'bg-green-50 text-green-700' : 'bg-red-50 text-red-700'}`}>
          Floating P&L: {totalPnl >= 0 ? '+' : ''}${totalPnl.toFixed(2)}
        </div>
      </div>

      <div className="rounded-xl border border-default-200 bg-white overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left text-sm">
            <thead className="border-b border-default-200 bg-default-50/50 text-xs uppercase text-default-400">
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
                <th className="px-4 py-3">Action</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-default-100">
              {mockTrades.map(t => (
                <tr key={t.id} className="transition hover:bg-default-50/50">
                  <td className="px-4 py-3 font-semibold text-primary">{t.symbol}</td>
                  <td className="px-4 py-3">
                    <span className={`inline-flex rounded px-2 py-0.5 text-xs font-bold ${t.type === 'BUY' ? 'bg-green-100 text-green-700' : 'bg-red-100 text-red-700'}`}>{t.type}</span>
                  </td>
                  <td className="px-4 py-3 text-default-600">{t.lot}</td>
                  <td className="px-4 py-3 font-mono text-xs text-default-600">{t.entry}</td>
                  <td className="px-4 py-3 font-mono text-xs text-default-900 font-medium">{t.current}</td>
                  <td className="px-4 py-3 font-mono text-xs text-red-400">{t.sl}</td>
                  <td className="px-4 py-3 font-mono text-xs text-green-500">{t.tp}</td>
                  <td className={`px-4 py-3 font-semibold ${t.pnl >= 0 ? 'text-green-600' : 'text-red-600'}`}>
                    {t.pnl >= 0 ? '+' : ''}${t.pnl.toFixed(2)}
                  </td>
                  <td className="px-4 py-3 text-xs text-default-500">{t.strategy}</td>
                  <td className="px-4 py-3 text-xs text-default-400">{t.duration}</td>
                  <td className="px-4 py-3">
                    <button className="inline-flex items-center gap-1 rounded bg-red-500 px-2 py-1 text-[10px] font-medium text-white hover:bg-red-600">
                      <LuX className="size-3" /> Close
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </main>
  );
};

export default ActiveTrades;
