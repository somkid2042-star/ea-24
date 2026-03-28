import { useState, useEffect, useRef, useCallback } from 'react';
import {
  LuWifi,
  LuWifiOff,
  LuTrendingUp,
  LuTrendingDown,
  LuChartColumn,
  LuTarget,
  LuCalendar,
} from 'react-icons/lu';

import { getWsUrl } from '@/utils/config';

type Deal = {
  ticket: number;
  order: number;
  pos_id: number;
  symbol: string;
  type: string;
  volume: number;
  price: number;
  profit: number;
  swap: number;
  commission: number;
  magic: number;
  time: string;
  comment: string;
};

const WS_URL = getWsUrl();

const TradeHistory = () => {
  const [wsConnected, setWsConnected] = useState(false);
  const [deals, setDeals] = useState<Deal[]>([]);
  const wsRef = useRef<WebSocket | null>(null);

  const connectWs = useCallback(() => {
    const ws = new WebSocket(WS_URL);
    ws.onopen = () => {
      setWsConnected(true);
      // Request historical deals from DB on connect
      ws.send(JSON.stringify({ action: 'get_trade_history' }));
    };
    ws.onclose = () => { setWsConnected(false); setTimeout(connectWs, 3000); };
    ws.onmessage = (evt) => {
      try {
        const data = JSON.parse(evt.data);
        if (data.type === 'trade_history' || data.type === 'trade_history_db') {
          setDeals((prev) => {
            const newDeals: Deal[] = data.deals || [];
            const map = new Map(prev.map(d => [d.ticket, d]));
            newDeals.forEach(d => map.set(d.ticket, d));
            return Array.from(map.values()).sort((a, b) => a.time.localeCompare(b.time));
          });
        }
      } catch { /* */ }
    };
    wsRef.current = ws;
  }, []);

  useEffect(() => { connectWs(); return () => { wsRef.current?.close(); }; }, [connectWs]);

  // Stats
  const totalDeals = deals.length;
  const totalProfit = deals.reduce((sum, d) => sum + d.profit, 0);
  const totalSwap = deals.reduce((sum, d) => sum + d.swap, 0);
  const totalComm = deals.reduce((sum, d) => sum + d.commission, 0);
  const netProfit = totalProfit + totalSwap + totalComm;
  const winDeals = deals.filter(d => d.profit >= 0);
  const lossDeals = deals.filter(d => d.profit < 0);
  const winRate = totalDeals > 0 ? (winDeals.length / totalDeals * 100) : 0;
  const avgWin = winDeals.length > 0 ? winDeals.reduce((s, d) => s + d.profit, 0) / winDeals.length : 0;
  const avgLoss = lossDeals.length > 0 ? lossDeals.reduce((s, d) => s + d.profit, 0) / lossDeals.length : 0;
  const profitFactor = Math.abs(lossDeals.reduce((s, d) => s + d.profit, 0)) > 0 ? winDeals.reduce((s, d) => s + d.profit, 0) / Math.abs(lossDeals.reduce((s, d) => s + d.profit, 0)) : winDeals.length > 0 ? 999 : 0;
  const totalVolume = deals.reduce((sum, d) => sum + d.volume, 0);

  // Symbol breakdown
  const symbolMap = new Map<string, { count: number; profit: number }>();
  deals.forEach(d => {
    const e = symbolMap.get(d.symbol) || { count: 0, profit: 0 };
    e.count++;
    e.profit += d.profit;
    symbolMap.set(d.symbol, e);
  });
  const symbolStats = Array.from(symbolMap.entries()).sort((a, b) => b[1].count - a[1].count);

  return (
    <main className="space-y-5">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h4 className="text-lg font-semibold text-default-900">Trade History</h4>
          <p className="mt-1 text-sm text-default-500">Last 30 days closed deals from MT5</p>
        </div>
        <div className="flex items-center gap-2">
          <span className="rounded-full bg-default-100 dark:bg-default-50 px-2.5 py-0.5 text-[10px] font-medium text-default-600">{totalDeals} deals</span>
          <span className={`inline-flex items-center gap-1.5 rounded-full px-3 py-1 text-xs font-medium ${wsConnected ? 'bg-green-100 text-green-700 dark:bg-green-500/20 dark:text-green-400' : 'bg-red-100 text-red-700 dark:bg-red-500/20 dark:text-red-400'}`}>
            {wsConnected ? <LuWifi className="size-3.5" /> : <LuWifiOff className="size-3.5" />}{wsConnected ? ' Connected' : ' Offline'}
          </span>
        </div>
      </div>

      {/* Summary Cards */}
      <div className="grid grid-cols-2 gap-4 lg:grid-cols-5">
        <div className="rounded-xl border border-default-200 bg-white dark:bg-default-50 p-5">
          <div className="mb-3 flex items-center justify-between"><span className="text-xs font-medium uppercase tracking-wider text-default-400">Net Profit</span><div className={`rounded-lg p-2 ${netProfit >= 0 ? 'bg-green-50 dark:bg-green-500/20 text-green-500' : 'bg-red-50 dark:bg-red-500/20 text-red-500'}`}>{netProfit >= 0 ? <LuTrendingUp className="size-4" /> : <LuTrendingDown className="size-4" />}</div></div>
          <p className={`text-2xl font-bold ${netProfit >= 0 ? 'text-green-600' : 'text-red-600'}`}>{netProfit >= 0 ? '+' : ''}${netProfit.toFixed(2)}</p>
          <p className="mt-1 text-xs text-default-500">Profit + Swap + Comm</p>
        </div>
        <div className="rounded-xl border border-default-200 bg-white dark:bg-default-50 p-5">
          <div className="mb-3 flex items-center justify-between"><span className="text-xs font-medium uppercase tracking-wider text-default-400">Win Rate</span><div className="rounded-lg bg-green-50 dark:bg-green-500/20 p-2 text-green-500"><LuTarget className="size-4" /></div></div>
          <p className={`text-2xl font-bold ${winRate >= 50 ? 'text-green-600' : 'text-red-600'}`}>{winRate.toFixed(1)}%</p>
          <p className="mt-1 text-xs text-default-500">{winDeals.length}W / {lossDeals.length}L</p>
        </div>
        <div className="rounded-xl border border-default-200 bg-white dark:bg-default-50 p-5">
          <div className="mb-3 flex items-center justify-between"><span className="text-xs font-medium uppercase tracking-wider text-default-400">Profit Factor</span><div className="rounded-lg bg-blue-50 dark:bg-blue-500/20 p-2 text-blue-500"><LuChartColumn className="size-4" /></div></div>
          <p className={`text-2xl font-bold ${profitFactor >= 1 ? 'text-green-600' : 'text-red-600'}`}>{profitFactor > 100 ? '∞' : profitFactor.toFixed(2)}</p>
          <p className="mt-1 text-xs text-default-500">Gross Win ÷ Gross Loss</p>
        </div>
        <div className="rounded-xl border border-default-200 bg-white dark:bg-default-50 p-5">
          <div className="mb-3 flex items-center justify-between"><span className="text-xs font-medium uppercase tracking-wider text-default-400">Avg Win / Loss</span></div>
          <p className="text-sm font-bold text-green-600">+${avgWin.toFixed(2)}</p>
          <p className="text-sm font-bold text-red-600">${avgLoss.toFixed(2)}</p>
        </div>
        <div className="rounded-xl border border-default-200 bg-white dark:bg-default-50 p-5">
          <div className="mb-3 flex items-center justify-between"><span className="text-xs font-medium uppercase tracking-wider text-default-400">Total Volume</span><div className="rounded-lg bg-violet-50 dark:bg-violet-500/20 p-2 text-violet-500"><LuCalendar className="size-4" /></div></div>
          <p className="text-2xl font-bold text-default-900">{totalVolume.toFixed(2)}</p>
          <p className="mt-1 text-xs text-default-500">lots traded</p>
        </div>
      </div>

      {/* Symbol Breakdown + Fees */}
      <div className="grid grid-cols-1 gap-5 lg:grid-cols-3">
        {/* Symbol breakdown */}
        <div className="lg:col-span-2 rounded-xl border border-default-200 bg-white dark:bg-default-50 p-5">
          <h5 className="mb-4 text-sm font-semibold text-default-900">By Symbol</h5>
          {symbolStats.length > 0 ? (
            <div className="space-y-3">
              {symbolStats.map(([sym, stat]) => (
                <div key={sym} className="flex items-center gap-3">
                  <span className="min-w-[80px] text-sm font-bold text-primary">{sym}</span>
                  <div className="flex-1 h-2 rounded-full bg-default-100 overflow-hidden">
                    <div className={`h-full rounded-full ${stat.profit >= 0 ? 'bg-green-500' : 'bg-red-400'}`} style={{ width: `${Math.min(100, (stat.count / Math.max(1, totalDeals)) * 100)}%` }} />
                  </div>
                  <span className="text-xs text-default-500">{stat.count} deals</span>
                  <span className={`min-w-[70px] text-right text-xs font-bold ${stat.profit >= 0 ? 'text-green-600' : 'text-red-600'}`}>{stat.profit >= 0 ? '+' : ''}${stat.profit.toFixed(2)}</span>
                </div>
              ))}
            </div>
          ) : <p className="text-sm text-default-400">No trade history yet</p>}
        </div>

        {/* Fees */}
        <div className="rounded-xl border border-default-200 bg-white dark:bg-default-50 p-5">
          <h5 className="mb-4 text-sm font-semibold text-default-900">Fees & Costs</h5>
          <div className="space-y-3">
            <div className="flex items-center justify-between"><span className="text-xs text-default-500">Gross Profit</span><span className={`text-sm font-bold ${totalProfit >= 0 ? 'text-green-600' : 'text-red-600'}`}>{totalProfit >= 0 ? '+' : ''}${totalProfit.toFixed(2)}</span></div>
            <div className="flex items-center justify-between"><span className="text-xs text-default-500">Total Swap</span><span className={`text-sm font-bold ${totalSwap >= 0 ? 'text-green-600' : 'text-red-600'}`}>{totalSwap >= 0 ? '+' : ''}${totalSwap.toFixed(2)}</span></div>
            <div className="flex items-center justify-between"><span className="text-xs text-default-500">Total Commission</span><span className={`text-sm font-bold ${totalComm >= 0 ? 'text-green-600' : 'text-red-600'}`}>{totalComm >= 0 ? '+' : ''}${totalComm.toFixed(2)}</span></div>
            <hr className="border-default-200" />
            <div className="flex items-center justify-between"><span className="text-sm font-semibold text-default-900">Net Profit</span><span className={`text-lg font-bold ${netProfit >= 0 ? 'text-green-600' : 'text-red-600'}`}>{netProfit >= 0 ? '+' : ''}${netProfit.toFixed(2)}</span></div>
          </div>
        </div>
      </div>

      {/* Deals Table */}
      <div className="rounded-xl border border-default-200 bg-white dark:bg-default-50 overflow-hidden">
        <div className="px-5 py-4 border-b border-default-200 flex items-center justify-between">
          <h5 className="text-sm font-semibold text-default-900">Closed Deals</h5>
          <span className="text-xs text-default-500">{totalDeals} deals (last 30 days)</span>
        </div>
        <div className="overflow-x-auto">
          <table className="w-full text-left text-sm">
            <thead className="border-b border-default-200 bg-default-50/50 text-xs uppercase text-default-400">
              <tr>
                <th className="px-4 py-3">Time</th>
                <th className="px-4 py-3">Symbol</th>
                <th className="px-4 py-3">Type</th>
                <th className="px-4 py-3">Volume</th>
                <th className="px-4 py-3">Price</th>
                <th className="px-4 py-3">Profit</th>
                <th className="px-4 py-3">Swap</th>
                <th className="px-4 py-3">Comm</th>
                <th className="px-4 py-3">Net</th>
                <th className="px-4 py-3">Comment</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-default-200">
              {deals.length > 0 ? [...deals].reverse().map(d => {
                const net = d.profit + d.swap + d.commission;
                return (
                <tr key={d.ticket} className="hover:bg-default-50/50 dark:hover:bg-default-100/30 transition">
                  <td className="px-4 py-3 text-xs text-default-500 whitespace-nowrap">{d.time}</td>
                  <td className="px-4 py-3 font-semibold text-primary">{d.symbol}</td>
                  <td className="px-4 py-3"><span className={`rounded px-2 py-0.5 text-[10px] font-bold text-white ${d.type === 'BUY' ? 'bg-green-500' : 'bg-red-500'}`}>{d.type}</span></td>
                  <td className="px-4 py-3 tabular-nums">{d.volume.toFixed(2)}</td>
                  <td className="px-4 py-3 tabular-nums">{d.price}</td>
                  <td className={`px-4 py-3 tabular-nums font-bold ${d.profit >= 0 ? 'text-green-600' : 'text-red-600'}`}>{d.profit >= 0 ? '+' : ''}${d.profit.toFixed(2)}</td>
                  <td className="px-4 py-3 tabular-nums text-default-500">${d.swap.toFixed(2)}</td>
                  <td className="px-4 py-3 tabular-nums text-default-500">${d.commission.toFixed(2)}</td>
                  <td className={`px-4 py-3 tabular-nums font-bold ${net >= 0 ? 'text-green-600' : 'text-red-600'}`}>{net >= 0 ? '+' : ''}${net.toFixed(2)}</td>
                  <td className="px-4 py-3 text-xs text-default-400">{d.comment || '—'}</td>
                </tr>
                );
              }) : (
                <tr><td colSpan={10} className="px-5 py-8 text-center text-default-400">{wsConnected ? 'No closed deals in last 30 days' : 'Connect to see trade history'}</td></tr>
              )}
            </tbody>
          </table>
        </div>
      </div>
    </main>
  );
};

export default TradeHistory;
