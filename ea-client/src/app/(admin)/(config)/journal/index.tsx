import { useState, useEffect, useRef, useCallback, useMemo } from 'react';
import { LuCalendar, LuTrendingUp, LuTrendingDown, LuClock, LuTarget } from 'react-icons/lu';
import { getWsUrl } from '@/utils/config';

type Deal = { ticket: number; order: number; pos_id: number; symbol: string; type: string; volume: number; price: number; profit: number; swap: number; commission: number; magic: number; time: string; comment: string; };

const WS_URL = getWsUrl();

const strategyNameMap: Record<string, string> = {
  'SMC': 'Smart Money Concept', 'ICT': 'ICT Strategy', 'Fibonacci': 'Fibonacci Retracement',
  'Scalping': 'Scalper Pro', 'BreakoutRetest': 'Breakout Retest', 'MeanReversion': 'Mean Reversion',
  'TrendFollowing': 'Trend Following', 'OrderBlock': 'Order Block', 'FairValueGap': 'Fair Value Gap',
  'LiquiditySweep': 'Liquidity Sweep', 'Manual': 'เปิดเอง', 'EA-Web': 'เปิดเอง',
};

const TradingJournal = () => {
  const [deals, setDeals] = useState<Deal[]>([]);
  const [filterSymbol, setFilterSymbol] = useState('all');
  const [filterStrategy, setFilterStrategy] = useState('all');
  const wsRef = useRef<WebSocket | null>(null);

  const connectWs = useCallback(() => {
    const ws = new WebSocket(WS_URL);
    ws.onopen = () => { ws.send(JSON.stringify({ action: 'get_trade_history' })); };
    ws.onclose = () => setTimeout(connectWs, 3000);
    ws.onmessage = (evt) => {
      try {
        const data = JSON.parse(evt.data);
        if (data.type === 'trade_history' || data.type === 'trade_history_db') {
          setDeals((prev) => {
            const map = new Map(prev.map(d => [d.ticket, d]));
            (data.deals || []).forEach((d: Deal) => map.set(d.ticket, d));
            return Array.from(map.values()).sort((a, b) => b.time.localeCompare(a.time));
          });
        }
      } catch {}
    };
    wsRef.current = ws;
  }, []);

  useEffect(() => { connectWs(); return () => { wsRef.current?.close(); }; }, [connectWs]);

  const parseStrategy = (comment: string) => {
    if (!comment) return 'Manual';
    if (comment.startsWith('EA24-')) return comment.slice(5);
    return comment || 'Manual';
  };

  const symbols = useMemo(() => Array.from(new Set(deals.map(d => d.symbol))).sort(), [deals]);
  const strategies = useMemo(() => Array.from(new Set(deals.map(d => parseStrategy(d.comment)))).sort(), [deals]);

  const filtered = useMemo(() => {
    return deals.filter(d => {
      if (filterSymbol !== 'all' && d.symbol !== filterSymbol) return false;
      if (filterStrategy !== 'all' && parseStrategy(d.comment) !== filterStrategy) return false;
      return true;
    });
  }, [deals, filterSymbol, filterStrategy]);

  // Heatmap data (last 30 days)
  const heatmap = useMemo(() => {
    const now = Date.now();
    const days: { date: string; profit: number; count: number }[] = [];
    for (let i = 29; i >= 0; i--) {
      const d = new Date(now - i * 86400000);
      const key = d.toISOString().split('T')[0];
      days.push({ date: key, profit: 0, count: 0 });
    }
    for (const d of deals) {
      const day = (d.time.split(' ')[0] || d.time.split('T')[0]);
      const entry = days.find(x => x.date === day);
      if (entry) { entry.profit += d.profit + d.swap + d.commission; entry.count++; }
    }
    return days;
  }, [deals]);

  return (
    <main className="space-y-5">
      <div className="flex items-center justify-between flex-wrap gap-3">
        <div>
          <h4 className="text-lg font-semibold text-default-900">📓 Trading Journal</h4>
          <p className="mt-1 text-sm text-default-500">บันทึกทุกออเดอร์อัตโนมัติ</p>
        </div>
        <div className="flex gap-2">
          <select value={filterSymbol} onChange={(e) => setFilterSymbol(e.target.value)}
            className="px-3 py-1.5 rounded-xl bg-default-100 dark:bg-default-200/10 text-xs text-default-900 border border-default-200 dark:border-default-300/10">
            <option value="all">ทุกคู่เงิน</option>
            {symbols.map(s => <option key={s} value={s}>{s}</option>)}
          </select>
          <select value={filterStrategy} onChange={(e) => setFilterStrategy(e.target.value)}
            className="px-3 py-1.5 rounded-xl bg-default-100 dark:bg-default-200/10 text-xs text-default-900 border border-default-200 dark:border-default-300/10">
            <option value="all">ทุกกลยุทธ์</option>
            {strategies.map(s => <option key={s} value={s}>{strategyNameMap[s] || s}</option>)}
          </select>
        </div>
      </div>

      {/* Heatmap */}
      <div className="card !p-5">
        <h5 className="text-sm font-semibold text-default-900 mb-3 flex items-center gap-2"><LuCalendar className="size-4 text-primary" /> Heat Map (30 วัน)</h5>
        <div className="flex flex-wrap gap-1">
          {heatmap.map(h => {
            const bg = h.count === 0 ? 'bg-default-100 dark:bg-default-200/10' : h.profit >= 0 ? h.profit > 50 ? 'bg-green-500' : 'bg-green-300 dark:bg-green-500/60' : h.profit < -50 ? 'bg-red-500' : 'bg-red-300 dark:bg-red-500/60';
            return (
              <div key={h.date} title={`${h.date}: ${h.count > 0 ? `${h.profit >= 0 ? '+' : ''}$${h.profit.toFixed(2)} (${h.count} เทรด)` : 'ไม่มีเทรด'}`}
                className={`size-7 rounded-md ${bg} transition-all hover:scale-125 cursor-default`} />
            );
          })}
        </div>
        <div className="flex items-center gap-3 mt-2 text-[10px] text-default-400">
          <span className="flex items-center gap-1"><span className="size-3 rounded bg-red-500" /> ขาดทุนมาก</span>
          <span className="flex items-center gap-1"><span className="size-3 rounded bg-red-300 dark:bg-red-500/60" /> ขาดทุน</span>
          <span className="flex items-center gap-1"><span className="size-3 rounded bg-default-100 dark:bg-default-200/10" /> ไม่มีเทรด</span>
          <span className="flex items-center gap-1"><span className="size-3 rounded bg-green-300 dark:bg-green-500/60" /> กำไร</span>
          <span className="flex items-center gap-1"><span className="size-3 rounded bg-green-500" /> กำไรมาก</span>
        </div>
      </div>

      {/* Journal Cards */}
      <div className="space-y-3">
        {filtered.length > 0 ? filtered.slice(0, 50).map(d => {
          const net = d.profit + d.swap + d.commission;
          const strat = parseStrategy(d.comment);
          const stratDisplay = strategyNameMap[strat] || strat;
          const isBuy = d.type === 'BUY';
          return (
            <div key={d.ticket} className="card !p-4 hover:shadow-lg transition-shadow">
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-3">
                  <div className={`size-10 rounded-xl flex items-center justify-center ${isBuy ? 'bg-green-500/10 text-green-500' : 'bg-red-500/10 text-red-500'}`}>
                    {isBuy ? <LuTrendingUp className="size-5" /> : <LuTrendingDown className="size-5" />}
                  </div>
                  <div>
                    <div className="flex items-center gap-2">
                      <span className="text-sm font-bold text-default-900">{d.symbol}</span>
                      <span className={`rounded px-2 py-0.5 text-[10px] font-bold text-white ${isBuy ? 'bg-green-500' : 'bg-red-500'}`}>{d.type}</span>
                      <span className="text-[10px] text-default-400">{d.volume.toFixed(2)} lot</span>
                    </div>
                    <div className="flex items-center gap-3 mt-0.5 text-xs text-default-500">
                      <span className="flex items-center gap-1"><LuTarget className="size-3" />{stratDisplay}</span>
                      <span className="flex items-center gap-1"><LuClock className="size-3" />{d.time}</span>
                    </div>
                  </div>
                </div>
                <div className="text-right">
                  <p className={`text-base font-bold ${net >= 0 ? 'text-green-600 dark:text-green-400' : 'text-red-600 dark:text-red-400'}`}>{net >= 0 ? '+' : ''}${net.toFixed(2)}</p>
                  <p className="text-[10px] text-default-400">@ {d.price}</p>
                </div>
              </div>
            </div>
          );
        }) : (
          <div className="card !p-8 text-center text-default-400 text-sm">ยังไม่มีข้อมูล Trading Journal</div>
        )}
      </div>
    </main>
  );
};

export default TradingJournal;
