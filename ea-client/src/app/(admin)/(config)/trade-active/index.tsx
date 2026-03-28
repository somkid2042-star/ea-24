import { useState, useEffect, useRef, useCallback } from 'react';
import { LuX } from 'react-icons/lu';
import { getWsUrl } from '@/utils/config';

type Position = {
  ticket: number;
  symbol: string;
  type: string;
  volume: number;
  open_price: number;
  current_price: number;
  pnl: number;
  swap: number;
  sl: number;
  tp: number;
  magic: number;
  open_time: string;
  comment: string;
};

const WS_URL = getWsUrl();

const ActiveTrades = () => {
  const [wsConnected, setWsConnected] = useState(false);
  const [positions, setPositions] = useState<Position[]>([]);
  const wsRef = useRef<WebSocket | null>(null);

  const connectWs = useCallback(() => {
    const ws = new WebSocket(WS_URL);
    ws.onopen = () => setWsConnected(true);
    ws.onclose = () => { setWsConnected(false); setTimeout(connectWs, 3000); };
    ws.onmessage = (evt) => {
      try {
        const data = JSON.parse(evt.data);
        if (data.type === 'account_data') {
          setPositions(data.positions || []);
        }
      } catch { /* */ }
    };
    wsRef.current = ws;
  }, []);

  useEffect(() => { connectWs(); return () => { wsRef.current?.close(); }; }, [connectWs]);

  const send = (msg: object) => { if (wsRef.current?.readyState === 1) wsRef.current.send(JSON.stringify(msg)); };

  const closeTrade = (ticket: number) => {
    if (confirm(`Are you sure you want to close position #${ticket}?`)) {
      send({ action: 'close_trade', ticket });
    }
  };

  const totalPnl = positions.reduce((s, t) => s + t.pnl, 0);

  return (
    <main className="space-y-5">
      <div className="flex items-center justify-between">
        <div>
          <h4 className="text-lg font-semibold text-default-900">Active Trades</h4>
          <p className="text-sm text-default-500">{positions.length} open positions</p>
        </div>
        <div className="flex items-center gap-3">
          <div className={`rounded-lg px-4 py-2 text-sm font-bold ${totalPnl >= 0 ? 'bg-green-50 dark:bg-green-500/20 text-green-700 dark:text-green-400' : 'bg-red-50 dark:bg-red-500/20 text-red-700 dark:text-red-400'}`}>
            Floating P&L: {totalPnl >= 0 ? '+' : ''}${totalPnl.toFixed(2)}
          </div>
        </div>
      </div>

      <div className="rounded-xl border border-default-200 bg-white dark:bg-default-50 overflow-hidden">
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
              {positions.length > 0 ? positions.map(t => (
                <tr key={t.ticket} className="transition hover:bg-default-50/50">
                  <td className="px-4 py-3 font-semibold text-primary">{t.symbol}</td>
                  <td className="px-4 py-3">
                    <span className={`inline-flex rounded px-2 py-0.5 text-xs font-bold ${t.type === 'BUY' ? 'bg-green-100 text-green-700' : 'bg-red-100 text-red-700'}`}>{t.type}</span>
                  </td>
                  <td className="px-4 py-3 text-default-600">{t.volume.toFixed(2)}</td>
                  <td className="px-4 py-3 font-mono text-xs text-default-600">{t.open_price}</td>
                  <td className="px-4 py-3 font-mono text-xs text-default-900 font-medium">{t.current_price}</td>
                  <td className="px-4 py-3 font-mono text-xs text-red-400">{t.sl}</td>
                  <td className="px-4 py-3 font-mono text-xs text-green-500">{t.tp}</td>
                  <td className={`px-4 py-3 font-semibold ${t.pnl >= 0 ? 'text-green-600' : 'text-red-600'}`}>
                    {t.pnl >= 0 ? '+' : ''}${t.pnl.toFixed(2)}
                  </td>
                  <td className="px-4 py-3 text-xs text-default-500">{t.comment || 'EA-Web'}</td>
                  <td className="px-4 py-3 text-xs text-default-400 text-nowrap">{t.open_time}</td>
                  <td className="px-4 py-3">
                    <button onClick={() => closeTrade(t.ticket)} className="btn btn-sm bg-danger/10 text-danger hover:bg-danger hover:text-white">
                      <LuX className="size-3" /> Close
                    </button>
                  </td>
                </tr>
              )) : (
                <tr>
                  <td colSpan={11} className="px-4 py-8 text-center text-sm text-default-500">
                    {wsConnected ? 'No open positions' : 'Connecting to MT5...'}
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </div>
    </main>
  );
};

export default ActiveTrades;
