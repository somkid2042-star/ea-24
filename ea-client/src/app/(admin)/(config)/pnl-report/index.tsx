import { useState, useEffect, useRef, useCallback, useMemo } from 'react';
import { createChart, ColorType, LineSeries } from 'lightweight-charts';
import type { IChartApi } from 'lightweight-charts';
import { LuTrendingUp, LuTrendingDown, LuTarget, LuChartColumn, LuCalendar, LuChartNoAxesCombined, LuFilter } from 'react-icons/lu';
import { getWsUrl } from '@/utils/config';
import { useLayoutContext } from '@/context/useLayoutContext';

type Deal = { ticket: number; order: number; pos_id: number; symbol: string; type: string; volume: number; price: number; profit: number; swap: number; commission: number; magic: number; time: string; comment: string; };

const WS_URL = getWsUrl();
const CHART_DARK = { bg: '#1a1d29', text: '#848e9c', line: '#089981', cross: '#555' };
const CHART_LIGHT = { bg: '#ffffff', text: '#787b86', line: '#089981', cross: '#999' };

const PnlReport = () => {
  const { theme } = useLayoutContext();
  const darkMode = theme === 'dark';
  const [deals, setDeals] = useState<Deal[]>([]);
  const [filter, setFilter] = useState<'7d' | '30d' | 'all'>('30d');
  const chartRef = useRef<HTMLDivElement>(null);
  const chartApiRef = useRef<IChartApi | null>(null);
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
            return Array.from(map.values()).sort((a, b) => a.time.localeCompare(b.time));
          });
        }
      } catch {}
    };
    wsRef.current = ws;
  }, []);

  useEffect(() => { connectWs(); return () => { wsRef.current?.close(); }; }, [connectWs]);

  // Filter deals by date range
  const filteredDeals = useMemo(() => {
    if (filter === 'all') return deals;
    const now = Date.now();
    const ms = filter === '7d' ? 7 * 86400000 : 30 * 86400000;
    return deals.filter(d => now - new Date(d.time).getTime() < ms);
  }, [deals, filter]);

  // Stats
  const totalDeals = filteredDeals.length;
  const winDeals = filteredDeals.filter(d => d.profit >= 0);
  const lossDeals = filteredDeals.filter(d => d.profit < 0);
  const winRate = totalDeals > 0 ? (winDeals.length / totalDeals * 100) : 0;
  const totalProfit = filteredDeals.reduce((s, d) => s + d.profit + d.swap + d.commission, 0);
  const avgWin = winDeals.length > 0 ? winDeals.reduce((s, d) => s + d.profit, 0) / winDeals.length : 0;
  const avgLoss = lossDeals.length > 0 ? lossDeals.reduce((s, d) => s + d.profit, 0) / lossDeals.length : 0;
  const grossWin = winDeals.reduce((s, d) => s + d.profit, 0);
  const grossLoss = Math.abs(lossDeals.reduce((s, d) => s + d.profit, 0));
  const profitFactor = grossLoss > 0 ? grossWin / grossLoss : winDeals.length > 0 ? 999 : 0;

  // Max Drawdown
  const { maxDrawdown, equityCurve } = useMemo(() => {
    let equity = 0, peak = 0, maxDD = 0;
    const curve: { time: number; value: number }[] = [];
    for (const d of filteredDeals) {
      equity += d.profit + d.swap + d.commission;
      peak = Math.max(peak, equity);
      maxDD = Math.max(maxDD, peak - equity);
      const t = Math.floor(new Date(d.time).getTime() / 1000);
      curve.push({ time: t, value: parseFloat(equity.toFixed(2)) });
    }
    // Deduplicate by time
    const deduped: typeof curve = [];
    for (const p of curve) {
      if (deduped.length === 0 || p.time > deduped[deduped.length - 1].time) deduped.push(p);
      else deduped[deduped.length - 1] = p;
    }
    return { maxDrawdown: maxDD, equityCurve: deduped };
  }, [filteredDeals]);

  // Strategy breakdown
  const strategyStats = useMemo(() => {
    const map = new Map<string, { count: number; profit: number; wins: number }>();
    for (const d of filteredDeals) {
      const c = d.comment || 'Manual';
      const name = c.startsWith('EA24-') ? c.slice(5) : c || 'Manual';
      const e = map.get(name) || { count: 0, profit: 0, wins: 0 };
      e.count++;
      e.profit += d.profit;
      if (d.profit >= 0) e.wins++;
      map.set(name, e);
    }
    return Array.from(map.entries()).sort((a, b) => b[1].profit - a[1].profit);
  }, [filteredDeals]);

  // Best/Worst day
  const { bestDay, worstDay } = useMemo(() => {
    const dayMap = new Map<string, number>();
    for (const d of filteredDeals) {
      const day = d.time.split(' ')[0] || d.time.split('T')[0];
      dayMap.set(day, (dayMap.get(day) || 0) + d.profit + d.swap + d.commission);
    }
    let best = { day: '-', value: 0 }, worst = { day: '-', value: 0 };
    for (const [day, val] of dayMap) {
      if (val > best.value) best = { day, value: val };
      if (val < worst.value) worst = { day, value: val };
    }
    return { bestDay: best, worstDay: worst };
  }, [filteredDeals]);

  // Chart
  useEffect(() => {
    if (!chartRef.current || equityCurve.length === 0) return;
    const C = darkMode ? CHART_DARK : CHART_LIGHT;
    const el = chartRef.current;
    el.innerHTML = '';
    const chart = createChart(el, {
      width: el.clientWidth || 600, height: el.clientHeight || 300,
      layout: { attributionLogo: false, background: { type: ColorType.Solid, color: C.bg }, textColor: C.text, fontFamily: "'Inter', sans-serif" },
      grid: { vertLines: { visible: false }, horzLines: { visible: false } },
      rightPriceScale: { borderVisible: false },
      timeScale: { borderVisible: false, timeVisible: true },
      crosshair: { horzLine: { color: C.cross, style: 3 }, vertLine: { color: C.cross, style: 3 } },
    });
    const series = chart.addSeries(LineSeries, {
      color: totalProfit >= 0 ? '#089981' : '#f23645',
      lineWidth: 2,
      crosshairMarkerVisible: true,
    });
    series.setData(equityCurve.map(p => ({ time: p.time as any, value: p.value })));
    chartApiRef.current = chart;
    const ro = new ResizeObserver(() => { chart.applyOptions({ width: el.clientWidth, height: el.clientHeight }); });
    ro.observe(el);
    return () => { ro.disconnect(); chart.remove(); };
  }, [equityCurve, darkMode, totalProfit]);

  return (
    <main className="space-y-5">
      <div className="flex items-center justify-between">
        <div>
          <h4 className="text-lg font-semibold text-default-900">P&L Report</h4>
          <p className="mt-1 text-sm text-default-500">สรุปผลกำไร/ขาดทุนและสถิติการเทรด</p>
        </div>
        <div className="flex items-center gap-1 bg-default-100 dark:bg-default-200/20 rounded-lg p-0.5">
          {(['7d', '30d', 'all'] as const).map(f => (
            <button key={f} onClick={() => setFilter(f)}
              className={`px-3 py-1 rounded-md text-xs font-semibold transition-all ${filter === f ? 'bg-primary text-white shadow-sm' : 'text-default-500 hover:text-default-800 dark:hover:text-white'}`}
            >{f === '7d' ? '7 วัน' : f === '30d' ? '30 วัน' : 'ทั้งหมด'}</button>
          ))}
        </div>
      </div>

      {/* Equity Curve */}
      <div className="card !p-5">
        <h5 className="text-sm font-semibold text-default-900 mb-3 flex items-center gap-2"><LuChartNoAxesCombined className="size-4 text-primary" /> Equity Curve</h5>
        <div ref={chartRef} style={{ width: '100%', height: 280 }} />
      </div>

      {/* Stat Cards */}
      <div className="grid grid-cols-2 gap-4 lg:grid-cols-5">
        <div className="card !p-5">
          <div className="mb-3 flex items-center justify-between"><span className="text-xs font-medium uppercase tracking-wider text-default-400">กำไรสุทธิ</span>{totalProfit >= 0 ? <LuTrendingUp className="size-4 text-green-500" /> : <LuTrendingDown className="size-4 text-red-500" />}</div>
          <p className={`text-2xl font-bold ${totalProfit >= 0 ? 'text-green-600 dark:text-green-400' : 'text-red-600 dark:text-red-400'}`}>{totalProfit >= 0 ? '+' : ''}${totalProfit.toFixed(2)}</p>
          <p className="mt-1 text-xs text-default-500">{totalDeals} ออเดอร์</p>
        </div>
        <div className="card !p-5">
          <div className="mb-3 flex items-center justify-between"><span className="text-xs font-medium uppercase tracking-wider text-default-400">Win Rate</span><LuTarget className="size-4 text-green-500" /></div>
          <p className={`text-2xl font-bold ${winRate >= 50 ? 'text-green-600 dark:text-green-400' : 'text-red-600 dark:text-red-400'}`}>{winRate.toFixed(1)}%</p>
          <p className="mt-1 text-xs text-default-500">{winDeals.length}W / {lossDeals.length}L</p>
        </div>
        <div className="card !p-5">
          <div className="mb-3 flex items-center justify-between"><span className="text-xs font-medium uppercase tracking-wider text-default-400">Profit Factor</span><LuChartColumn className="size-4 text-blue-500" /></div>
          <p className={`text-2xl font-bold ${profitFactor >= 1 ? 'text-green-600 dark:text-green-400' : 'text-red-600 dark:text-red-400'}`}>{profitFactor > 100 ? '∞' : profitFactor.toFixed(2)}</p>
        </div>
        <div className="card !p-5">
          <div className="mb-3 flex items-center justify-between"><span className="text-xs font-medium uppercase tracking-wider text-default-400">Max Drawdown</span><LuTrendingDown className="size-4 text-red-500" /></div>
          <p className="text-2xl font-bold text-red-600 dark:text-red-400">-${maxDrawdown.toFixed(2)}</p>
        </div>
        <div className="card !p-5">
          <div className="mb-3"><span className="text-xs font-medium uppercase tracking-wider text-default-400">Avg Win / Loss</span></div>
          <p className="text-sm font-bold text-green-600 dark:text-green-400">+${avgWin.toFixed(2)}</p>
          <p className="text-sm font-bold text-red-600 dark:text-red-400">${avgLoss.toFixed(2)}</p>
        </div>
      </div>

      {/* Best/Worst + Strategy Breakdown */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-5">
        <div className="card !p-5">
          <h5 className="text-sm font-semibold text-default-900 mb-4 flex items-center gap-2"><LuCalendar className="size-4 text-primary" /> Best / Worst Day</h5>
          <div className="space-y-3">
            <div className="flex justify-between items-center"><span className="text-xs text-default-500">🏆 วันที่ดีที่สุด</span><div className="text-right"><p className="text-sm font-bold text-green-600 dark:text-green-400">+${bestDay.value.toFixed(2)}</p><p className="text-[10px] text-default-400">{bestDay.day}</p></div></div>
            <hr className="border-default-200/60 dark:border-default-300/10" />
            <div className="flex justify-between items-center"><span className="text-xs text-default-500">💀 วันที่แย่ที่สุด</span><div className="text-right"><p className="text-sm font-bold text-red-600 dark:text-red-400">${worstDay.value.toFixed(2)}</p><p className="text-[10px] text-default-400">{worstDay.day}</p></div></div>
          </div>
        </div>
        <div className="lg:col-span-2 card !p-5">
          <h5 className="text-sm font-semibold text-default-900 mb-4 flex items-center gap-2"><LuFilter className="size-4 text-primary" /> ผลลัพธ์แต่ละกลยุทธ์</h5>
          <div className="space-y-3">
            {strategyStats.length > 0 ? strategyStats.map(([name, stat]) => (
              <div key={name} className="flex items-center gap-3">
                <span className="min-w-[120px] text-sm font-bold text-primary truncate">{name}</span>
                <div className="flex-1 h-2.5 rounded-full bg-default-100 dark:bg-default-200/10 overflow-hidden">
                  <div className={`h-full rounded-full ${stat.profit >= 0 ? 'bg-green-500' : 'bg-red-400'}`} style={{ width: `${Math.min(100, Math.max(5, (stat.count / Math.max(1, totalDeals)) * 100))}%` }} />
                </div>
                <span className="text-xs text-default-500 min-w-[50px]">{stat.count} เทรด</span>
                <span className="text-xs text-default-500 min-w-[50px]">{((stat.wins / Math.max(1, stat.count)) * 100).toFixed(0)}% win</span>
                <span className={`min-w-[80px] text-right text-xs font-bold ${stat.profit >= 0 ? 'text-green-600 dark:text-green-400' : 'text-red-600 dark:text-red-400'}`}>{stat.profit >= 0 ? '+' : ''}${stat.profit.toFixed(2)}</span>
              </div>
            )) : <p className="text-sm text-default-400">ยังไม่มีข้อมูล</p>}
          </div>
        </div>
      </div>
    </main>
  );
};

export default PnlReport;
