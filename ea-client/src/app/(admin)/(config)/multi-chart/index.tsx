import { useState, useEffect, useRef, useCallback } from 'react';
import { createChart, ColorType, CandlestickSeries } from 'lightweight-charts';
import type { IChartApi } from 'lightweight-charts';
import { LuGrid2X2, LuMaximize2 } from 'react-icons/lu';
import { getWsUrl } from '@/utils/config';
import { useLayoutContext } from '@/context/useLayoutContext';

type OHLCCandle = { time: number; open: number; high: number; low: number; close: number; };
type MarketWatchSymbol = { symbol: string; bid: number; ask: number; spread: number; digits: number; };

const WS_URL = getWsUrl();
const CHART_DARK = { text: '#848e9c', bg: '#1a1d29', up: '#089981', down: '#f23645', cross: '#555' };
const CHART_LIGHT = { text: '#787b86', bg: '#ffffff', up: '#089981', down: '#f23645', cross: '#999' };

const MiniChart = ({ symbol, darkMode, onSelect }: { symbol: string; darkMode: boolean; onSelect: (s: string) => void; }) => {
  const containerRef = useRef<HTMLDivElement>(null);
  const chartRef = useRef<IChartApi | null>(null);
  const wsRef = useRef<WebSocket | null>(null);
  const [bid, setBid] = useState(0);
  const [change, setChange] = useState(0);

  useEffect(() => {
    if (!containerRef.current) return;
    const C = darkMode ? CHART_DARK : CHART_LIGHT;
    const el = containerRef.current;
    const chart = createChart(el, {
      width: el.clientWidth || 300, height: el.clientHeight || 180,
      layout: { attributionLogo: false, background: { type: ColorType.Solid, color: C.bg }, textColor: C.text, fontFamily: "'Inter', sans-serif" },
      grid: { vertLines: { visible: false }, horzLines: { visible: false } },
      rightPriceScale: { borderVisible: false, visible: false },
      timeScale: { borderVisible: false, visible: false },
      crosshair: { mode: 0 },
      handleScroll: false, handleScale: false,
    });
    const series = chart.addSeries(CandlestickSeries, {
      upColor: C.up, downColor: C.down, borderUpColor: C.up, borderDownColor: C.down, wickUpColor: C.up, wickDownColor: C.down,
    });
    chartRef.current = chart;

    // Fetch candles
    const ws = new WebSocket(WS_URL);
    ws.onopen = () => {
      ws.send(JSON.stringify({ action: 'get_history', symbol, timeframe: 'M15', limit: 100 }));
    };
    ws.onmessage = (evt) => {
      try {
        const data = JSON.parse(evt.data);
        if (data.type === 'history' && data.candles) {
          const sorted = [...data.candles].sort((a: any, b: any) => a.time - b.time);
          const deduped: OHLCCandle[] = [];
          for (const c of sorted) {
            const t = Math.floor(Number(c.time));
            if (!isNaN(t) && (deduped.length === 0 || t > deduped[deduped.length - 1].time)) {
              deduped.push({ time: t, open: Number(c.open), high: Number(c.high), low: Number(c.low), close: Number(c.close) });
            }
          }
          if (deduped.length > 0) {
            series.setData(deduped.map(c => ({ time: c.time as any, open: c.open, high: c.high, low: c.low, close: c.close })));
            setBid(deduped[deduped.length - 1].close);
            const first = deduped[0].open;
            const last = deduped[deduped.length - 1].close;
            setChange(((last - first) / first) * 100);
          }
          chart.timeScale().fitContent();
        }
        if (data.type === 'market_watch' && data.symbols) {
          const sym = data.symbols.find((s: MarketWatchSymbol) => s.symbol === symbol);
          if (sym) setBid(sym.bid);
        }
      } catch {}
    };
    wsRef.current = ws;

    const ro = new ResizeObserver(() => {
      chart.applyOptions({ width: el.clientWidth, height: el.clientHeight });
    });
    ro.observe(el);

    return () => { ro.disconnect(); chart.remove(); ws.close(); };
  }, [symbol, darkMode]);

  return (
    <div className="card overflow-hidden cursor-pointer hover:shadow-lg transition-shadow group" onClick={() => onSelect(symbol)}>
      <div className="px-3 pt-3 flex items-center justify-between">
        <div>
          <span className="text-sm font-bold text-default-900">{symbol}</span>
          <p className="text-xs text-default-500 font-mono">{bid > 0 ? bid.toFixed(bid > 100 ? 2 : 5) : '—'}</p>
        </div>
        <div className="flex items-center gap-2">
          <span className={`text-xs font-bold ${change >= 0 ? 'text-green-500' : 'text-red-500'}`}>{change >= 0 ? '+' : ''}{change.toFixed(2)}%</span>
          <LuMaximize2 className="size-3.5 text-default-400 opacity-0 group-hover:opacity-100 transition-opacity" />
        </div>
      </div>
      <div ref={containerRef} style={{ width: '100%', height: 140 }} />
    </div>
  );
};

const MultiChart = () => {
  const { theme } = useLayoutContext();
  const darkMode = theme === 'dark';
  const [watchSymbols, setWatchSymbols] = useState<string[]>([]);
  const [_selectedSymbol, setSelectedSymbol] = useState<string | null>(null);
  const wsRef = useRef<WebSocket | null>(null);

  const connectWs = useCallback(() => {
    const ws = new WebSocket(WS_URL);
    ws.onmessage = (evt) => {
      try {
        const data = JSON.parse(evt.data);
        if (data.type === 'market_watch' && data.symbols) {
          const syms = (data.symbols as MarketWatchSymbol[]).map(s => s.symbol);
          if (syms.length > 0) setWatchSymbols(prev => prev.length === 0 ? syms.slice(0, 6) : prev);
        }
      } catch {}
    };
    ws.onclose = () => setTimeout(connectWs, 3000);
    wsRef.current = ws;
  }, []);

  useEffect(() => { connectWs(); return () => { wsRef.current?.close(); }; }, [connectWs]);

  const handleSelect = (s: string) => {
    setSelectedSymbol(s);
    // Navigate back — in the trading dashboard context, this triggers an event
    // For now just highlight
    alert(`กดเลือก ${s} — กลับไปที่หน้า Home เพื่อดูกราฟขนาดเต็ม`);
  };

  const displaySymbols = watchSymbols.length > 0 ? watchSymbols : ['XAUUSD', 'EURUSD', 'GBPUSD', 'USDJPY', 'AUDUSD', 'NZDUSD'];

  return (
    <main className="space-y-5">
      <div className="flex items-center justify-between">
        <div>
          <h4 className="text-lg font-semibold text-default-900">📈 Multi-Symbol Watch</h4>
          <p className="mt-1 text-sm text-default-500">ดูกราฟหลายคู่เงินพร้อมกัน (M15)</p>
        </div>
        <div className="flex items-center gap-2">
          <LuGrid2X2 className="size-4 text-default-400" />
          <span className="text-xs text-default-500">{displaySymbols.length} คู่เงิน</span>
        </div>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        {displaySymbols.map(s => (
          <MiniChart key={s} symbol={s} darkMode={darkMode} onSelect={handleSelect} />
        ))}
      </div>
    </main>
  );
};

export default MultiChart;
