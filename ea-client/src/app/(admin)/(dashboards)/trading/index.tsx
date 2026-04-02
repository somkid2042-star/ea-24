import { useState, useEffect, useRef, useCallback, lazy, Suspense, type ReactNode } from 'react';
import { useNavigate } from 'react-router-dom';
import { createChart, ColorType, CandlestickSeries } from 'lightweight-charts';
import type { IChartApi, ISeriesApi } from 'lightweight-charts';
import {
  LuLayoutDashboard, LuServer, LuShieldCheck,
  LuWorkflow, LuBriefcase, LuHistory,
  LuSlidersHorizontal, LuPlus, LuX, LuChevronDown,
  LuSun, LuMoon, LuChartCandlestick, LuSettings, LuRefreshCw
} from 'react-icons/lu';
import { getWsUrl } from '@/utils/config';

/* ── Lazy-loaded page components ── */
const MT5Page = lazy(() => import('@/app/(admin)/(config)/mt5/index'));
const ServerPage = lazy(() => import('@/app/(admin)/(config)/server/index'));

const SecurityPage = lazy(() => import('@/app/(admin)/(config)/security/index'));
const StrategyBuilderPage = lazy(() => import('@/app/(admin)/(config)/strategy-builder/index'));

const TradeActivePage = lazy(() => import('@/app/(admin)/(config)/trade-active/index'));
const TradeSetupPage = lazy(() => import('@/app/(admin)/(config)/trade-setup/index'));
const TradeHistoryPage = lazy(() => import('@/app/(admin)/(config)/trade-history/index'));

/* ── Types ── */
type Position = { ticket: number; symbol: string; type: string; volume: number; open_price: number; current_price: number; pnl: number; swap: number; sl: number; tp: number; magic: number; open_time: string; comment: string; };
type AccountData = { balance: number; equity: number; profit: number; margin: number; free_margin: number; currency: string; positions: Position[]; positions_count: number; trading_enabled: boolean; };
type MarketWatchSymbol = { symbol: string; bid: number; ask: number; spread: number; digits: number; };
type TradeResult = { action: string; success: boolean; symbol?: string; direction?: string; lot?: number; ticket?: number; error?: string; };
type AlertMsg = { type: 'alert'; level: 'info' | 'warning' | 'error'; title: string; message: string; };
type OHLCCandle = { time: number; open: number; high: number; low: number; close: number; };

const CHART_TIMEFRAMES = ['M1', 'M5', 'M15', 'M30', 'H1', 'H4', 'D1'];
const tfToSeconds = (tf: string): number => {
  switch(tf) { case 'M1': return 60; case 'M5': return 300; case 'M15': return 900; case 'M30': return 1800; case 'H1': return 3600; case 'H4': return 14400; case 'D1': return 86400; default: return 60; }
};

const WS_URL = getWsUrl();

/* ── Panel definitions ── */
type PanelKey = 'chart' | 'mt5' | 'server' | 'security' | 'strategies' | 'trades' | 'setup' | 'history';
type NavItem = { key: PanelKey; icon: ReactNode; label: string; badge?: boolean } | { key: string; divider: true };

const TOP_NAV: NavItem[] = [
  { key: 'chart', icon: <LuLayoutDashboard size={20} />, label: 'Home' },
  { key: 'strategies', icon: <LuWorkflow size={20} />, label: 'Strategies' },
  { key: 'trades', icon: <LuBriefcase size={20} />, label: 'Trades' },
  { key: 'setup', icon: <LuSlidersHorizontal size={20} />, label: 'Setup' },
  { key: 'history', icon: <LuHistory size={20} />, label: 'History' },
];

const BOTTOM_NAV: NavItem[] = [
  { key: 'security', icon: <LuShieldCheck size={20} />, label: 'Security' },
  { key: 'mt5', icon: <LuChartCandlestick size={20} />, label: 'MT5' },
  { key: 'server', icon: <LuServer size={20} />, label: 'Server' },
];

const PANEL_COMPONENTS: Record<Exclude<PanelKey, 'chart'>, React.LazyExoticComponent<React.ComponentType>> = {
  mt5: MT5Page,
  server: ServerPage,
  security: SecurityPage,
  strategies: StrategyBuilderPage,
  trades: TradeActivePage,
  setup: TradeSetupPage,
  history: TradeHistoryPage,
};

/* ── Chart Colors (MT5 style) ── */
const CHART_DARK = { text: '#848e9c', grid: '#1e222d', bg: '#1a1d29', up: '#089981', down: '#f23645', cross: '#555' };
const CHART_LIGHT = { text: '#787b86', grid: '#e9ecf1', bg: '#ffffff', up: '#089981', down: '#f23645', cross: '#999' };

const CandleChart = ({ symbol, candles, bid, darkMode, chartTf }: {
  symbol: string; candles: OHLCCandle[]; bid: number; darkMode: boolean; chartTf: string;
}) => {
  const containerRef = useRef<HTMLDivElement>(null);
  const chartRef = useRef<IChartApi | null>(null);
  const seriesRef = useRef<ISeriesApi<"Candlestick"> | null>(null);
  const lastCandleRef = useRef<OHLCCandle | null>(null);
  const lastLocalTfIndexRef = useRef<number>(0);

  useEffect(() => {
    if (!containerRef.current) return;
    const C = darkMode ? CHART_DARK : CHART_LIGHT;
    const el = containerRef.current;
    // Use explicit dimensions — fallback for WebKitGTK where clientWidth/Height can be 0
    const initW = el.clientWidth || el.offsetWidth || el.parentElement?.clientWidth || 600;
    const initH = el.clientHeight || el.offsetHeight || el.parentElement?.clientHeight || 400;
    const chart = createChart(el, {
      width: initW,
      height: initH,
      layout: { attributionLogo: false, background: { type: ColorType.Solid, color: C.bg }, textColor: C.text, fontFamily: "'Inter', sans-serif" },
      localization: { locale: 'en-US' },
      grid: { vertLines: { visible: false }, horzLines: { visible: false } },
      rightPriceScale: { borderVisible: false, scaleMargins: { top: 0.08, bottom: 0.08 } },
      timeScale: { barSpacing: 20, borderVisible: false, timeVisible: true, secondsVisible: false, rightOffset: 5 },
      crosshair: { mode: 0, horzLine: { color: C.cross, style: 3 }, vertLine: { color: C.cross, style: 3 } },
    });
    const series = chart.addSeries(CandlestickSeries, {
      upColor: C.up, downColor: C.down,
      borderUpColor: C.up, borderDownColor: C.down,
      wickUpColor: C.up, wickDownColor: C.down,
    });
    chartRef.current = chart;
    seriesRef.current = series;
    let resizeTimeout: any = null;
    const handleResize = () => {
      if (!containerRef.current) return;
      const w = Math.floor(containerRef.current.clientWidth || containerRef.current.offsetWidth || 600);
      const h = Math.floor(containerRef.current.clientHeight || containerRef.current.offsetHeight || 400);
      const opts = chart.options();
      if (w > 0 && h > 0 && (Math.abs(opts.width - w) > 2 || Math.abs(opts.height - h) > 2)) {
        chart.applyOptions({ width: w, height: h });
      }
    };
    window.addEventListener('resize', () => {
      clearTimeout(resizeTimeout);
      resizeTimeout = setTimeout(handleResize, 100);
    });
    // Use ResizeObserver for reliable size detection (critical for Tauri WebKitGTK)
    let ro: ResizeObserver | null = null;
    if (typeof ResizeObserver !== 'undefined') {
      ro = new ResizeObserver(() => {
        clearTimeout(resizeTimeout);
        resizeTimeout = setTimeout(handleResize, 50);
      });
      ro.observe(el);
    }
    // Multiple delayed resizes for WebKitGTK which may report 0 initially
    setTimeout(handleResize, 50);
    setTimeout(handleResize, 200);
    setTimeout(handleResize, 500);
    return () => { 
      clearTimeout(resizeTimeout);
      window.removeEventListener('resize', handleResize); 
      ro?.disconnect(); 
      chart.remove(); 
    };
  }, []); // Run only once

  useEffect(() => {
    if (!chartRef.current || !seriesRef.current) return;
    const C = darkMode ? CHART_DARK : CHART_LIGHT;
    chartRef.current.applyOptions({
      layout: { background: { type: ColorType.Solid, color: C.bg }, textColor: C.text },
      crosshair: { horzLine: { color: C.cross }, vertLine: { color: C.cross } }
    });
    seriesRef.current.applyOptions({
      upColor: C.up, downColor: C.down,
      borderUpColor: C.up, borderDownColor: C.down,
      wickUpColor: C.up, wickDownColor: C.down,
    });
  }, [darkMode]);

  useEffect(() => {
    if (!seriesRef.current) return;
    if (candles.length === 0) { seriesRef.current.setData([]); lastCandleRef.current = null; return; }
    const sorted = [...candles].sort((a, b) => a.time - b.time);
    const deduped: OHLCCandle[] = [];
    for (const c of sorted) { 
      const t = Math.floor(Number(c.time));
      if (Number.isNaN(t)) continue;
      if (deduped.length === 0 || t > deduped[deduped.length - 1].time) {
        deduped.push({ 
          time: t, 
          open: Number(c.open), high: Number(c.high), low: Number(c.low), close: Number(c.close) 
        });
      }
    }
    seriesRef.current.setData(deduped.map(c => ({ time: c.time as any, open: c.open, high: c.high, low: c.low, close: c.close })));
    lastCandleRef.current = deduped[deduped.length - 1];
    lastLocalTfIndexRef.current = Math.floor(Date.now() / 1000 / tfToSeconds(chartTf));
    
    // Automatically scale on first load only if we have data
    if (deduped.length > 0) {
      setTimeout(() => chartRef.current?.timeScale().scrollToRealTime(), 100);
    }
  }, [candles, chartTf]);

  useEffect(() => {
    if (!seriesRef.current || bid <= 0) return;
    const last = lastCandleRef.current;
    if (!last) return;
    
    const tfSecs = tfToSeconds(chartTf);
    const currentLocalIndex = Math.floor(Date.now() / 1000 / tfSecs);
    let targetTime = last.time;
    
    if (currentLocalIndex > lastLocalTfIndexRef.current) {
      const diffIndex = currentLocalIndex - lastLocalTfIndexRef.current;
      targetTime = last.time + (diffIndex * tfSecs);
    }
    
    if (targetTime === last.time) {
      const u = { time: targetTime as any, open: last.open, high: Math.max(last.high, bid), low: Math.min(last.low, bid), close: bid };
      seriesRef.current.update(u);
      lastCandleRef.current = u;
    } else {
      const u = { time: targetTime as any, open: bid, high: bid, low: bid, close: bid };
      seriesRef.current.update(u);
      lastCandleRef.current = u;
      lastLocalTfIndexRef.current = currentLocalIndex;
    }
  }, [bid, chartTf]);

  useEffect(() => { if (seriesRef.current) { seriesRef.current.setData([]); lastCandleRef.current = null; } }, [symbol]);

  return <div ref={containerRef} style={{ width: '100%', height: '100%', flex: 1, minHeight: 300 }} />;
};

const TradingDashboard = () => {
  const navigate = useNavigate();
  const [eaConnected, setEaConnected] = useState(false);
  const [account, setAccount] = useState<AccountData | null>(null);
  const [marketWatch, setMarketWatch] = useState<MarketWatchSymbol[]>([]);
  const [activeSymbol, setActiveSymbol] = useState('XAUUSD');
  const [closeModal, setCloseModal] = useState<{ show: boolean; ticket: number; symbol: string }>({ show: false, ticket: 0, symbol: '' });
  const [toast, setToast] = useState<TradeResult | null>(null);
  const [alert, setAlert] = useState<AlertMsg | null>(null);
  const [activePanel, setActivePanel] = useState<PanelKey>('chart');
  const [darkMode, setDarkMode] = useState(true);
  const [chartTf, setChartTf] = useState('M5');
  const [candles, setCandles] = useState<OHLCCandle[]>([]);
  const [isLoadingHistory, setIsLoadingHistory] = useState(false);
  const wsRef = useRef<WebSocket | null>(null);

  /* ── Sync data-theme attribute with darkMode state ── */
  useEffect(() => {
    document.documentElement.setAttribute('data-theme', darkMode ? 'dark' : 'light');
  }, [darkMode]);

   /* ── WebSocket ── */
  const chartTfRef = useRef(chartTf);
  chartTfRef.current = chartTf;
  const activeSymbolRef = useRef(activeSymbol);
  activeSymbolRef.current = activeSymbol;

  const fetchHistoryState = useRef<string>('');
  
  const requestHistory = useCallback((ws?: WebSocket | null) => {
    const target = ws || wsRef.current;
    if (target?.readyState === 1) {
      setIsLoadingHistory(true);
      const stateKey = `${activeSymbolRef.current}_${chartTfRef.current}`;
      fetchHistoryState.current = stateKey;
      target.send(JSON.stringify({ action: 'get_history', symbol: activeSymbolRef.current, timeframe: chartTfRef.current, limit: 500 }));
      target.send(JSON.stringify({ action: 'request_candles', symbol: activeSymbolRef.current, timeframe: chartTfRef.current }));
    }
  }, []);

  const connectWs = useCallback(() => {
    const ws = new WebSocket(WS_URL);
    ws.onopen = () => {
      // Request history as soon as WS connects
      setTimeout(() => requestHistory(ws), 500);
    };
    ws.onclose = () => { setEaConnected(false); setTimeout(connectWs, 3000); };
    ws.onmessage = (evt) => {
      try {
        const data = JSON.parse(evt.data);
        if (data.type === 'welcome' || data.type === 'ea_info') {
          const wasConnected = data.ea_connected ?? true;
          setEaConnected(wasConnected);
          // Only re-request if we haven't fetched for the current config yet
          if (wasConnected && fetchHistoryState.current !== `${activeSymbolRef.current}_${chartTfRef.current}`) {
            setTimeout(() => requestHistory(), 1000);
          }
        }
        if (data.type === 'account_data') { setAccount(data as AccountData); setEaConnected(true); }
        if (data.type === 'market_watch') {
          setMarketWatch(data.symbols || []);
          if (data.symbols?.length > 0 && activeSymbol === 'XAUUSD' && !data.symbols.find((s: MarketWatchSymbol) => s.symbol === 'XAUUSD')) setActiveSymbol(data.symbols[0].symbol);
        }
        if (data.type === 'trade_result') { setToast(data as TradeResult); setTimeout(() => setToast(null), 5000); }
        if (data.type === 'alert') { setAlert(data as AlertMsg); setTimeout(() => setAlert(null), 8000); }
        if (data.type === 'history') {
          if (data.candles) setCandles(data.candles);
          setIsLoadingHistory(false);
        }
        // Handle candle_data from EA (historical backfill) (removed redundant refresh loop)
      } catch { /* */ }
    };
    wsRef.current = ws;
  }, [activeSymbol, requestHistory]);

  useEffect(() => { connectWs(); return () => { wsRef.current?.close(); }; }, [connectWs]);
  const send = (msg: object) => { if (wsRef.current?.readyState === 1) wsRef.current.send(JSON.stringify(msg)); };

  // Request candle history on symbol/timeframe change
  useEffect(() => {
    const t = setTimeout(() => requestHistory(), 300);
    return () => clearTimeout(t);
  }, [activeSymbol, chartTf, requestHistory]);
  const handleCloseTrade = () => { send({ action: 'close_trade', ticket: closeModal.ticket }); setCloseModal({ show: false, ticket: 0, symbol: '' }); };

  /* ── Computed ── */
  const balance = account?.balance ?? 0;
  const equity = account?.equity ?? 0;
  const profit = account?.profit ?? 0;
  const positions = account?.positions ?? [];
  const sym = marketWatch.find(m => m.symbol === activeSymbol);
  const bid = sym?.bid ?? 0;
  const ask = sym?.ask ?? 0;
  const digits = sym?.digits ?? 2;
  const spread = sym?.spread ?? 0;
  const wl = marketWatch.length > 0
    ? marketWatch.map(m => ({ symbol: m.symbol, last: m.bid, change: 0, pct: 0 }))
    : [];

  const renderPanel = () => {
    if (activePanel === 'chart') {
      return (
        <div className="flex-1 flex flex-col overflow-auto p-4 gap-4">
          {/* Account Overview */}
          <div className="grid grid-cols-2 lg:grid-cols-4 gap-3 lg:gap-4 w-full">
            {[
              { label: 'Balance', value: `$${balance.toLocaleString('en-US', { minimumFractionDigits: 2 })}`, colorClass: 'text-default-900' },
              { label: 'Equity', value: `$${equity.toLocaleString('en-US', { minimumFractionDigits: 2 })}`, colorClass: profit >= 0 ? 'text-success' : 'text-danger' },
              { label: 'Profit', value: `${profit >= 0 ? '+' : ''}$${profit.toFixed(2)}`, colorClass: profit >= 0 ? 'text-success' : 'text-danger' },
              { label: 'Margin', value: `$${(account?.margin ?? 0).toFixed(2)}`, colorClass: 'text-default-600' },
            ].map(item => (
              <div key={item.label} className="card !rounded-2xl !p-4 lg:!p-5">
                <div className="text-[11px] text-default-400 dark:text-default-500 font-medium uppercase tracking-wider mb-1">{item.label}</div>
                <div className={`text-xl font-bold ${item.colorClass}`}>{item.value}</div>
              </div>
            ))}
          </div>

          {/* Chart & Open Positions Split */}
          <div className="flex-1 flex flex-col gap-4 min-h-0">
            <div className="card flex-1 !rounded-2xl !p-5 flex flex-col" style={{ minHeight: 300 }}>
              <div className="text-sm font-bold text-default-900 mb-3 flex justify-between items-center">
                <span>{activeSymbol}</span>
                <div className="flex items-center gap-2">
                  <div className="flex bg-default-100 dark:bg-default-200/20 rounded-lg p-0.5">
                    {CHART_TIMEFRAMES.map(tf => (
                      <button key={tf} onClick={() => setChartTf(tf)}
                        className={`px-2 py-0.5 rounded-md text-[10px] font-semibold transition-all ${chartTf === tf ? 'bg-primary text-white shadow-sm' : 'text-default-500 hover:text-default-800 dark:hover:text-white'}`}
                      >{tf}</button>
                    ))}
                  </div>
                  <span className={`text-[11px] font-medium flex items-center gap-1.5 ${eaConnected ? 'text-success' : 'text-danger'}`}>
                    <span className={`inline-block size-1.5 rounded-full ${eaConnected ? 'bg-success animate-pulse' : 'bg-danger'}`} />
                    {eaConnected ? 'Live' : 'Offline'}
                  </span>
                  <span className="text-[10px] text-default-400 font-mono">({candles.length})</span>
                </div>
              </div>
              <div className="flex-1 relative" style={{ minHeight: 300 }}>
                <div style={{ position: 'absolute', top: 0, left: 0, right: 0, bottom: 0 }}>
                  {isLoadingHistory && (
                    <div className="absolute inset-0 z-50 flex flex-col items-center justify-center bg-card/60 backdrop-blur-sm rounded-lg" style={{ pointerEvents: 'none' }}>
                      <LuRefreshCw className="size-8 text-primary animate-spin mb-2" />
                      <span className="text-sm font-medium text-default-700">Loading Chart...</span>
                    </div>
                  )}
                  <CandleChart symbol={activeSymbol} candles={candles} bid={bid} darkMode={darkMode} chartTf={chartTf} />
                </div>
              </div>
            </div>

            <div className="card !rounded-2xl !p-5 flex-shrink-0" style={{ maxHeight: 220, overflow: 'auto' }}>
              <div className="text-[13px] font-bold text-default-900 mb-4">Open Positions ({positions.length})</div>
              {positions.length > 0 ? (
                <div className="w-full overflow-x-auto whitespace-nowrap">
                  <table className="w-full" style={{ minWidth: 600 }}>
                  <thead>
                    <tr>
                      {['Symbol', 'Type', 'Volume', 'Open Price', 'Current', 'P&L', 'SL', 'TP', ''].map(h => (
                        <th key={h} className={`text-[11px] text-default-400 font-semibold pb-3 ${h === '' ? 'text-right' : 'text-left'}`}>{h}</th>
                      ))}
                    </tr>
                  </thead>
                  <tbody>
                    {positions.map((pos, i) => (
                      <tr key={pos.ticket} className={`${i % 2 === 0 ? '' : 'bg-default-50/50 dark:bg-default-200/5'} transition-colors`}>
                        <td className="text-[13px] font-semibold text-default-900 py-3 px-1">{pos.symbol}</td>
                        <td className={`text-xs font-semibold ${pos.type === 'BUY' ? 'text-success' : 'text-danger'}`}>{pos.type}</td>
                        <td className="text-xs text-default-600">{pos.volume}</td>
                        <td className="text-xs text-default-600 font-mono">{pos.open_price}</td>
                        <td className="text-xs text-default-600 font-mono">{pos.current_price}</td>
                        <td className={`text-xs font-bold ${pos.pnl >= 0 ? 'text-success' : 'text-danger'}`}>{pos.pnl >= 0 ? '+' : ''}{pos.pnl.toFixed(2)}</td>
                        <td className="text-[11px] text-default-400">{pos.sl || '—'}</td>
                        <td className="text-[11px] text-default-400">{pos.tp || '—'}</td>
                        <td className="text-right pr-2">
                          <button
                            onClick={() => setCloseModal({ show: true, ticket: pos.ticket, symbol: pos.symbol })}
                            className="btn btn-sm bg-danger/10 text-danger hover:bg-danger hover:text-white"
                          >Close</button>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
                </div>
            ) : (
              <div className="text-center py-8 text-default-400 text-[13px]">
                {eaConnected ? 'No open positions' : 'Waiting for MT5 connection...'}
              </div>
            )}
            </div>
          </div>

        </div>
      );
    }

    // Lazy-loaded page panel
    const PanelComponent = PANEL_COMPONENTS[activePanel];
    if (!PanelComponent) return null;
    return (
      <div className="flex-1 overflow-auto bg-body-bg">
        <Suspense fallback={
          <div className="flex items-center justify-center h-full">
            <div className="text-center">
              <div className="size-8 border-3 border-primary/30 border-t-primary rounded-full animate-spin mx-auto mb-3" />
              <p className="text-sm text-default-400">Loading...</p>
            </div>
          </div>
        }>
          <PanelComponent />
        </Suspense>
      </div>
    );
  };

  return (
    <div className="fixed inset-0 z-[9999] flex flex-col font-body bg-body-bg text-body-color overflow-hidden rounded-2xl shadow-2xl">

      {/* ═══ TOP BAR ═══ */}
      <div data-tauri-drag-region className="flex items-center justify-between px-5 w-full shrink-0 bg-card dark:bg-[#151821] border-b border-default-200/60 dark:border-default-300/10 rounded-t-2xl" style={{ height: 52 }}>
        {/* Left: Traffic lights + Logo */}
        <div className="flex items-center gap-4">
          <div className="hidden sm:flex items-center" style={{ gap: 8 }}>
            <button
              onClick={async () => { const { getCurrentWindow } = await import('@tauri-apps/api/window'); getCurrentWindow().close(); }}
              className="group rounded-full bg-[#ff5f57] hover:brightness-90 transition-all flex items-center justify-center"
              style={{ width: 14, height: 14, padding: 0, border: 'none' }}
              title="Close"
            >
              <span className="text-[9px] text-[#4d0000] opacity-0 group-hover:opacity-100 leading-none font-bold">✕</span>
            </button>
            <button
              onClick={async () => { const { getCurrentWindow } = await import('@tauri-apps/api/window'); getCurrentWindow().minimize(); }}
              className="group rounded-full bg-[#febc2e] hover:brightness-90 transition-all flex items-center justify-center"
              style={{ width: 14, height: 14, padding: 0, border: 'none' }}
              title="Minimize"
            >
              <span className="text-[10px] text-[#995700] opacity-0 group-hover:opacity-100 leading-none font-bold">−</span>
            </button>
            <button
              onClick={async () => { const { getCurrentWindow } = await import('@tauri-apps/api/window'); getCurrentWindow().toggleMaximize(); }}
              className="group rounded-full bg-[#28c840] hover:brightness-90 transition-all flex items-center justify-center"
              style={{ width: 14, height: 14, padding: 0, border: 'none' }}
              title="Maximize"
            >
              <span className="text-[8px] text-[#006500] opacity-0 group-hover:opacity-100 leading-none font-bold">⤢</span>
            </button>
          </div>
          <div className="flex items-center gap-2 cursor-pointer" onClick={() => { navigate('/'); setActivePanel('chart'); }}>
            <div className="size-8 rounded-xl bg-default-900 dark:bg-primary flex items-center justify-center">
              <span className="text-[9px] font-black text-white tracking-tight">EA24</span>
            </div>
            <div className="hidden sm:block">
              <div className="text-[13px] font-bold text-default-900">EA-24</div>
              <div className="text-[8px] text-default-400">algorithmic trading</div>
            </div>
          </div>
        </div>

        {/* Center ticker */}
        <div className="hidden sm:flex items-center gap-2">
          <span className="text-[13px] font-bold text-default-900">{activeSymbol}</span>
          <span className="text-[13px] text-default-300">—</span>
          <span className={`text-xs font-semibold ${profit >= 0 ? 'text-success' : 'text-danger'}`}>
            {profit >= 0 ? '+' : ''}{profit.toFixed(2)} ({balance > 0 ? ((profit / balance) * 100).toFixed(2) : '0.00'}%)
          </span>
        </div>

        {/* Right balance */}
        <div className="flex items-center gap-5 pr-2">
          <div className="text-right hidden sm:block">
            <div className="text-[10px] text-default-400">Balance</div>
            <div className="text-xs font-bold text-default-900">${balance.toLocaleString('en-US', { minimumFractionDigits: 2 })}</div>
          </div>
          <div className="text-right hidden sm:block">
            <div className="text-[10px] text-default-400">Equity</div>
            <div className={`text-xs font-bold ${profit >= 0 ? 'text-success' : 'text-danger'}`}>${equity.toLocaleString('en-US', { minimumFractionDigits: 2 })}</div>
          </div>
        </div>
      </div>



      {/* ═══ MAIN AREA ═══ */}
      <div className="flex flex-col lg:flex-row flex-1 min-h-0 relative">

        {/* ── CONTENT AREA (Chart or Page Panel) ── */}
        <div className="flex flex-col flex-1 min-h-0 overflow-auto pb-16 lg:pb-0 px-4 lg:px-6 pt-2">
          {renderPanel()}
        </div>

        {/* ── RIGHT SIDEBAR (Cards) — only on Dashboard ── */}
        {activePanel === 'chart' && (
          <>
            <style>{`.hide-sb::-webkit-scrollbar{display:none}`}</style>
            <div className="hide-sb flex flex-col gap-2 p-2 w-full lg:w-[300px] shrink-0 pb-20 lg:pb-2 overflow-auto" style={{ background: 'transparent' }}>

              {/* Watchlist Card */}
              <div className="card">
                <div className="card-header">
                  <h6 className="card-title text-sm">Watchlist</h6>
                  <div className="flex gap-1">
                    <button className="btn btn-icon rounded-full bg-default-100 dark:bg-default-200/10 text-default-500 hover:bg-default-200 hover:text-default-800 dark:hover:bg-default-300/20 dark:hover:text-white" style={{ width: 28, height: 28 }}><LuPlus size={12} /></button>
                    <button className="btn btn-icon rounded-full bg-default-100 dark:bg-default-200/10 text-default-500 hover:bg-default-200 hover:text-default-800 dark:hover:bg-default-300/20 dark:hover:text-white" style={{ width: 28, height: 28 }}><LuSettings size={12} /></button>
                  </div>
                </div>
                <div className="card-body overflow-x-auto" style={{ padding: '8px 16px' }}>
                  <table className="w-full min-w-[200px]">
                    <thead>
                      <tr>
                        <th className="text-[10px] text-default-400 font-medium text-left pb-1.5">Symbol</th>
                        <th className="text-[10px] text-default-400 font-medium text-right pb-1.5">Last</th>
                        <th className="text-[10px] text-default-400 font-medium text-right pb-1.5">Change</th>
                        <th className="text-[10px] text-default-400 font-medium text-right pb-1.5">%</th>
                      </tr>
                    </thead>
                    <tbody>
                      {wl.map(w => (
                        <tr key={w.symbol} onClick={() => setActiveSymbol(w.symbol)} className="cursor-pointer hover:bg-default-50 dark:hover:bg-default-200/10 transition-colors">
                          <td className={`text-xs py-1 font-semibold ${activeSymbol === w.symbol ? 'text-primary' : 'text-default-700'}`}>{w.symbol}</td>
                          <td className="text-xs py-1 text-right font-mono text-default-600">{w.last.toFixed(w.last > 100 ? 2 : 4)}</td>
                          <td className={`text-xs py-1 text-right font-mono ${w.change >= 0 ? 'text-success' : 'text-danger'}`}>{w.change >= 0 ? '+' : ''}{w.change.toFixed(2)}</td>
                          <td className={`text-xs py-1 text-right font-mono ${w.pct >= 0 ? 'text-success' : 'text-danger'}`}>{w.pct >= 0 ? '+' : ''}{w.pct.toFixed(2)}%</td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              </div>


              {/* Symbol Info Card */}
              <div className="card">
                <div className="card-body" style={{ padding: '12px 16px' }}>
                  <div className="flex items-center gap-2 mb-2">
                    <div className="size-7 rounded-full flex items-center justify-center text-[8px] font-bold text-white shrink-0 bg-gradient-to-br from-amber-500 to-orange-600">Au</div>
                    <div>
                      <div className="text-sm font-bold text-default-900">{activeSymbol}</div>
                      <div className="text-[9px] text-default-400">MetaTrader 5</div>
                    </div>
                  </div>
                  <div className="text-xl font-bold text-default-900">{bid > 0 ? bid.toFixed(digits) : '—'} <span className="text-[10px] text-default-400">{account?.currency || 'USD'}</span></div>
                  {bid > 0 && (
                    <div className="flex gap-3 text-[10px] text-default-400 mt-1">
                      <span>Bid: <span className="text-danger">{bid.toFixed(digits)}</span></span>
                      <span>Ask: <span className="text-success">{ask.toFixed(digits)}</span></span>
                      <span>Spread: {spread.toFixed(1)}</span>
                    </div>
                  )}
                </div>
              </div>
            </div>
          </>
        )}

        {/* ═══ RIGHT NAV TOOLBAR (Bottom Bar on Mobile) ═══ */}
        <style>{`
          .mac-tooltip { position: relative; }
          .mac-tooltip::before {
            content: attr(data-tip);
            position: absolute;
            right: calc(100% + 10px);
            top: 50%;
            transform: translateY(-50%) scale(0.92);
            padding: 4px 10px;
            border-radius: 6px;
            background: rgba(30,30,30,0.92);
            color: #f0f0f0;
            font-size: 12px;
            font-weight: 500;
            letter-spacing: 0.01em;
            white-space: nowrap;
            pointer-events: none;
            opacity: 0;
            transition: opacity 0.15s ease, transform 0.15s ease;
            box-shadow: 0 2px 8px rgba(0,0,0,0.22);
            z-index: 99999;
          }
          .mac-tooltip::after {
            content: '';
            position: absolute;
            right: calc(100% + 4px);
            top: 50%;
            transform: translateY(-50%);
            border: 4px solid transparent;
            border-left-color: rgba(30,30,30,0.92);
            pointer-events: none;
            opacity: 0;
            transition: opacity 0.15s ease;
            z-index: 99999;
          }
          .mac-tooltip:hover::before {
            opacity: 1;
            transform: translateY(-50%) scale(1);
            transition-delay: 0.4s;
          }
          .mac-tooltip:hover::after {
            opacity: 1;
            transition-delay: 0.4s;
          }
          @media (max-width: 1023px) {
            .mac-tooltip::before, .mac-tooltip::after { display: none; }
          }
        `}</style>
        <div className="absolute bottom-0 left-0 right-0 h-16 lg:static lg:h-auto lg:w-[72px] shrink-0 flex flex-row lg:flex-col items-center justify-around lg:justify-start lg:pt-3 lg:pb-3 gap-2 lg:gap-3 overflow-x-auto lg:overflow-visible bg-card/80 dark:bg-card/80 backdrop-blur-md lg:bg-transparent lg:dark:bg-transparent lg:backdrop-blur-none border-t border-default-200/60 dark:border-default-300/10 lg:border-none z-50">
          {TOP_NAV.map(item => {
            if ('divider' in item) return null;
            const active = activePanel === item.key;
            return (
              <button
                key={item.key}
                onClick={() => setActivePanel(item.key)}
                data-tip={item.label}
                className={`mac-tooltip shrink-0 flex items-center justify-center transition-all cursor-pointer border-none rounded-xl ${
                  active 
                    ? 'bg-primary/10 text-primary shadow-sm shadow-primary/10' 
                    : 'bg-default-200/80 dark:bg-default-200/40 text-default-700 dark:text-default-300 hover:text-default-900 dark:hover:text-white hover:bg-default-300 dark:hover:bg-default-200/60'
                }`}
                style={{ width: 40, height: 40 }}
              >
                {item.icon}
              </button>
            );
          })}
          {/* Theme Toggle & Connection */}
          <div className="lg:mt-auto flex flex-row lg:flex-col items-center gap-3 lg:gap-3 px-4 lg:px-0">
            {BOTTOM_NAV.map(item => {
              if ('divider' in item) return null;
              const active = activePanel === item.key;
              return (
                <button
                  key={item.key}
                  onClick={() => setActivePanel(item.key)}
                  data-tip={item.label}
                  className={`mac-tooltip shrink-0 flex items-center justify-center transition-all cursor-pointer border-none rounded-xl ${
                    active 
                      ? 'bg-primary/10 text-primary shadow-sm shadow-primary/10' 
                      : 'bg-default-200/80 dark:bg-default-200/40 text-default-700 dark:text-default-300 hover:text-default-900 dark:hover:text-white hover:bg-default-300 dark:hover:bg-default-200/60'
                  }`}
                  style={{ width: 40, height: 40 }}
                >
                  {item.icon}
                </button>
              );
            })}
            <button
              onClick={() => setDarkMode(!darkMode)}
              data-tip={darkMode ? 'Light Mode' : 'Dark Mode'}
              className="mac-tooltip shrink-0 flex items-center justify-center transition-all cursor-pointer border-none rounded-xl bg-default-200/80 dark:bg-default-200/40 text-default-700 dark:text-default-300 hover:bg-default-300 hover:text-default-900 dark:hover:bg-default-200/60 dark:hover:text-white"
              style={{ width: 40, height: 40 }}
            >
              {darkMode ? <LuSun size={20} /> : <LuMoon size={20} />}
            </button>
            {/* Connection */}
            <div className="flex flex-col items-center gap-1 shrink-0">
              <div className={`size-2 rounded-full ${eaConnected ? 'bg-success' : 'bg-danger'}`} />
              <span className="text-[7px] text-default-400 hidden lg:block">{eaConnected ? 'ON' : 'OFF'}</span>
            </div>
          </div>
        </div>
      </div>

      {/* ═══ TOAST & ALERTS ═══ */}
      {toast && (
        <div className={`fixed top-4 right-4 lg:right-20 z-[999999] min-w-[280px] rounded-xl p-3 text-white text-xs shadow-lg ${toast.success ? 'bg-success' : 'bg-danger'}`}>
          <div className="font-bold">{toast.action === 'open' ? (toast.success ? 'Trade Opened!' : 'Open Failed') : (toast.success ? 'Trade Closed!' : 'Close Failed')}</div>
          <div className="text-[10px] opacity-80 mt-0.5">{toast.symbol} {toast.direction} {toast.lot && `${toast.lot} lot`}{toast.error && ` — ${toast.error}`}</div>
          <button onClick={() => setToast(null)} className="btn btn-icon rounded-full absolute top-1 right-2 bg-transparent text-white border-0 p-0 hover:bg-white/20"><LuX size={14} /></button>
        </div>
      )}
      {alert && (
        <div className="fixed top-16 right-4 lg:right-20 z-[999999] min-w-[280px] rounded-xl p-3 text-white text-xs shadow-lg bg-warning">
          <div className="font-bold">{alert.title}</div>
          <div className="text-[10px] opacity-80 mt-0.5">{alert.message}</div>
          <button onClick={() => setAlert(null)} className="btn btn-icon rounded-full absolute top-1 right-2 bg-transparent text-white border-0 p-0 hover:bg-white/20"><LuX size={14} /></button>
        </div>
      )}

      {/* ═══ CLOSE MODAL ═══ */}
      {closeModal.show && (
        <div className="fixed inset-0 z-[99999] flex items-center justify-center bg-black/30 backdrop-blur-sm" onClick={() => setCloseModal({ show: false, ticket: 0, symbol: '' })}>
          <div className="card m-4 !p-6" style={{ width: '100%', maxWidth: 360 }} onClick={e => e.stopPropagation()}>
            <div className="text-center mb-4">
              <div className="size-12 rounded-full bg-danger/10 flex items-center justify-center mx-auto">
                <LuChevronDown size={24} className="text-danger" />
              </div>
            </div>
            <h3 className="text-center text-base font-bold text-default-900 mb-2">Close Position?</h3>
            <p className="text-center text-sm text-default-400 mb-6">Close <span className="text-primary font-semibold">{closeModal.symbol}</span> #{closeModal.ticket} at market?</p>
            <div className="flex gap-3">
              <button onClick={() => setCloseModal({ show: false, ticket: 0, symbol: '' })} className="btn rounded-full flex-1 bg-default-100 dark:bg-default-200/10 text-default-800 dark:text-default-700 hover:bg-default-200 dark:hover:bg-default-300/20 dark:hover:text-white py-2.5 text-sm font-medium border-none">Cancel</button>
              <button onClick={handleCloseTrade} className="btn rounded-full flex-1 bg-danger text-white hover:bg-danger/90 py-2.5 text-sm font-medium border-none">Close Trade</button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default TradingDashboard;
