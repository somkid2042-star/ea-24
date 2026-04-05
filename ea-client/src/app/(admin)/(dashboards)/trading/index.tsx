import { useState, useEffect, useRef, useCallback, useMemo, lazy, Suspense, type ReactNode } from 'react';
import { useNavigate } from 'react-router-dom';
import { createChart, ColorType, CandlestickSeries, createSeriesMarkers } from 'lightweight-charts';
import type { IChartApi, ISeriesApi } from 'lightweight-charts';
import {
  LuLayoutDashboard, LuServer, LuShieldCheck,
  LuWorkflow, LuBriefcase, LuHistory,
  LuSlidersHorizontal, LuPlus, LuX, LuChevronDown,
  LuSun, LuMoon, LuChartCandlestick, LuSettings, LuRefreshCw,
  LuChartNoAxesCombined, LuBell, LuShieldAlert, LuBookOpen, LuGrid2X2, LuBot, LuBrain,
  LuZoomIn, LuZoomOut, LuMaximize2, LuMinimize2
} from 'react-icons/lu';
import { getWsUrl } from '@/utils/config';
import { useLayoutContext } from '@/context/useLayoutContext';

/* ── Lazy-loaded page components ── */
const MT5Page = lazy(() => import('@/app/(admin)/(config)/mt5/index'));
const ServerPage = lazy(() => import('@/app/(admin)/(config)/server/index'));

const SecurityPage = lazy(() => import('@/app/(admin)/(config)/security/index'));
const StrategyBuilderPage = lazy(() => import('@/app/(admin)/(config)/strategy-builder/index'));

const TradeActivePage = lazy(() => import('@/app/(admin)/(config)/trade-active/index'));
const TradeSetupPage = lazy(() => import('@/app/(admin)/(config)/trade-setup/index'));
const TradeHistoryPage = lazy(() => import('@/app/(admin)/(config)/trade-history/index'));
const PnlReportPage = lazy(() => import('@/app/(admin)/(config)/pnl-report/index'));
const NotificationsPage = lazy(() => import('@/app/(admin)/(config)/notifications/index'));
const RiskManagementPage = lazy(() => import('@/app/(admin)/(config)/risk-management/index'));
const JournalPage = lazy(() => import('@/app/(admin)/(config)/journal/index'));
const MultiChartPage = lazy(() => import('@/app/(admin)/(config)/multi-chart/index'));
const DashboardAiPage = lazy(() => import('@/app/(admin)/(dashboards)/dashboard-ai/index'));
const AiSettingsPage = lazy(() => import('@/app/(admin)/(config)/ai-settings/index'));

/* ── Types ── */
type Position = { ticket: number; symbol: string; type: string; volume: number; open_price: number; current_price: number; pnl: number; swap: number; sl: number; tp: number; magic: number; open_time: string; comment: string; };
type AccountData = { balance: number; equity: number; profit: number; margin: number; free_margin: number; currency: string; positions: Position[]; positions_count: number; trading_enabled: boolean; };
type MarketWatchSymbol = { symbol: string; bid: number; ask: number; spread: number; digits: number; serverTime?: number; };
type TradeResult = { action: string; success: boolean; symbol?: string; direction?: string; lot?: number; ticket?: number; error?: string; };
type AlertMsg = { type: 'alert'; level: 'info' | 'warning' | 'error'; title: string; message: string; };
type OHLCCandle = { time: number; open: number; high: number; low: number; close: number; };
type ChartMarker = { time: number; position: 'aboveBar' | 'belowBar'; color: string; shape: 'arrowUp' | 'arrowDown' | 'circle'; text: string; };
type StrategySignalEntry = { setup_id: number; signal: string; symbol: string; strategy: string; reason: string; timestamp: string; price?: number; };

// Color map for 10 strategies + Auto
const STRATEGY_COLORS: Record<string, string> = {
  'Scalper Pro': '#e6194b', 'Trend Rider': '#3cb44b', 'Grid Master': '#ffe119',
  'Breakout Hunter': '#4363d8', 'Mean Revert': '#f58231', 'SMC': '#911eb4',
  'ICT': '#42d4f4', 'Fibonacci': '#f032e6', 'Momentum Surge': '#bfef45',
  'Session Sniper': '#fabed4', 'Auto': '#ffffff',
};

const CHART_TIMEFRAMES = ['M1', 'M5', 'M15', 'M30', 'H1', 'H4', 'D1'];
const tfToSeconds = (tf: string): number => {
  switch(tf) { case 'M1': return 60; case 'M5': return 300; case 'M15': return 900; case 'M30': return 1800; case 'H1': return 3600; case 'H4': return 14400; case 'D1': return 86400; default: return 60; }
};

const WS_URL = getWsUrl();

/* ── Panel definitions ── */
type PanelKey = 'chart' | 'mt5' | 'server' | 'security' | 'strategies' | 'trades' | 'setup' | 'history' | 'report' | 'notify' | 'risk' | 'journal' | 'multichart' | 'dashboard-ai' | 'ai';
type NavItem = { key: PanelKey; icon: ReactNode; label: string; badge?: boolean };

/* ── Grouped Navigation ── */
type NavGroup = { id: string; label: string; items: NavItem[] };

const NAV_GROUPS: NavGroup[] = [
  {
    id: 'main',
    label: 'หลัก',
    items: [
      { key: 'chart', icon: <LuLayoutDashboard size={18} />, label: 'หน้าหลัก' },
      { key: 'multichart', icon: <LuGrid2X2 size={18} />, label: 'Multi-Chart' },
    ],
  },
  {
    id: 'trading',
    label: 'การเทรด',
    items: [
      { key: 'strategies', icon: <LuWorkflow size={18} />, label: 'กลยุทธ์' },
      { key: 'trades', icon: <LuBriefcase size={18} />, label: 'ออเดอร์' },
      { key: 'setup', icon: <LuSlidersHorizontal size={18} />, label: 'ตั้งค่าเทรด' },
      { key: 'history', icon: <LuHistory size={18} />, label: 'ประวัติ' },
      { key: 'report', icon: <LuChartNoAxesCombined size={18} />, label: 'P&L Report' },
      { key: 'journal', icon: <LuBookOpen size={18} />, label: 'บันทึก' },
    ],
  },
  {
    id: 'ai',
    label: 'AI & เครื่องมือ',
    items: [
      { key: 'ai', icon: <LuBrain size={18} />, label: '🤖 AI Engine' },
      { key: 'dashboard-ai', icon: <LuBot size={18} />, label: 'Dashboard AI' },
    ],
  },
];

const SETTINGS_ITEMS: NavItem[] = [
  { key: 'mt5', icon: <LuChartCandlestick size={18} />, label: 'MT5 Connection' },
  { key: 'server', icon: <LuServer size={18} />, label: 'Server' },
  { key: 'security', icon: <LuShieldCheck size={18} />, label: 'Security & License' },
  { key: 'risk', icon: <LuShieldAlert size={18} />, label: 'Risk Management' },
  { key: 'notify', icon: <LuBell size={18} />, label: 'Notifications' },
];

const PANEL_COMPONENTS: Record<Exclude<PanelKey, 'chart'>, React.LazyExoticComponent<React.ComponentType>> = {
  mt5: MT5Page,
  server: ServerPage,
  security: SecurityPage,
  strategies: StrategyBuilderPage,
  trades: TradeActivePage,
  setup: TradeSetupPage,
  history: TradeHistoryPage,
  report: PnlReportPage,
  notify: NotificationsPage,
  risk: RiskManagementPage,
  journal: JournalPage,
  multichart: MultiChartPage,
  'dashboard-ai': DashboardAiPage,
  ai: AiSettingsPage,
};

/* ── Chart Colors (MT5 style) ── */
const CHART_DARK = { text: '#848e9c', grid: '#1e222d', bg: '#1a1d29', up: '#089981', down: '#f23645', cross: '#555' };
const CHART_LIGHT = { text: '#787b86', grid: '#e9ecf1', bg: '#ffffff', up: '#089981', down: '#f23645', cross: '#999' };

type ChartPriceLine = { price: number; color: string; text: string; };

const CandleChart = ({ symbol, candles, bid, darkMode, chartTf, markers, priceLines, serverTime, barSpacing = 10 }: {
  symbol: string; candles: OHLCCandle[]; bid: number; darkMode: boolean; chartTf: string; markers?: ChartMarker[]; priceLines?: ChartPriceLine[]; serverTime?: number; barSpacing?: number;
}) => {
  const containerRef = useRef<HTMLDivElement>(null);
  const chartRef = useRef<IChartApi | null>(null);
  const seriesRef = useRef<ISeriesApi<"Candlestick"> | null>(null);
  const lastCandleRef = useRef<OHLCCandle | null>(null);
  const lastLocalTfIndexRef = useRef<number>(0);
  const hasFitContentRef = useRef(false);
  const priceLinesRef = useRef<any[]>([]);
  const markersPluginRef = useRef<any>(null);

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
      timeScale: { barSpacing: 10, borderVisible: false, timeVisible: true, secondsVisible: false, rightOffset: 5 },
      crosshair: { mode: 0, horzLine: { color: C.cross, style: 3 }, vertLine: { color: C.cross, style: 3 } },
    });
    const series = chart.addSeries(CandlestickSeries, {
      upColor: C.up, downColor: C.down,
      borderUpColor: C.up, borderDownColor: C.down,
      wickUpColor: C.up, wickDownColor: C.down,
    });
    chartRef.current = chart;
    seriesRef.current = series;
    markersPluginRef.current = createSeriesMarkers(series, []);
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

  // Apply barSpacing changes dynamically without recreating chart
  useEffect(() => {
    if (!chartRef.current) return;
    chartRef.current.applyOptions({ timeScale: { barSpacing } });
  }, [barSpacing]);

  useEffect(() => {
    if (!seriesRef.current) return;
    if (candles.length === 0) { 
      seriesRef.current.setData([]); 
      lastCandleRef.current = null; 
      hasFitContentRef.current = false; // Reset so fitContent runs on next data
      return; 
    }
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
    
    // Show last ~80 candles so each candle is big, then scroll to latest
    if (deduped.length > 0 && !hasFitContentRef.current) {
      setTimeout(() => {
        const ts = chartRef.current?.timeScale();
        if (ts) {
          const totalBars = deduped.length;
          const visibleBars = 150;
          const from = Math.max(0, totalBars - visibleBars);
          ts.setVisibleLogicalRange({ from, to: totalBars + 5 });
        }
      }, 50);
      hasFitContentRef.current = true;
    }
  }, [candles, chartTf]);

  useEffect(() => {
    if (!seriesRef.current || bid <= 0) return;
    const last = lastCandleRef.current;
    if (!last) return;
    
    const tfSecs = tfToSeconds(chartTf);
    // Use MT5 server time when available, fallback to local time
    const nowSecs = serverTime && serverTime > 0 ? serverTime : Math.floor(Date.now() / 1000);
    const currentIndex = Math.floor(nowSecs / tfSecs);
    let targetTime = last.time;
    
    if (currentIndex > lastLocalTfIndexRef.current) {
      // Snap to MT5 server time boundary for accurate candle alignment
      targetTime = currentIndex * tfSecs;
    }
    
    if (targetTime === last.time) {
      const u = { time: targetTime as any, open: last.open, high: Math.max(last.high, bid), low: Math.min(last.low, bid), close: bid };
      seriesRef.current.update(u);
      lastCandleRef.current = u;
    } else {
      const u = { time: targetTime as any, open: bid, high: bid, low: bid, close: bid };
      seriesRef.current.update(u);
      lastCandleRef.current = u;
      lastLocalTfIndexRef.current = currentIndex;
    }
  }, [bid, chartTf, serverTime]);

  // Reset chart on symbol change only (timeframe reset handled in candle data effect above)
  useEffect(() => { if (seriesRef.current) { seriesRef.current.setData([]); lastCandleRef.current = null; hasFitContentRef.current = false; } }, [symbol]);

  // Render markers on chart using v5 createSeriesMarkers plugin
  useEffect(() => {
    if (!markersPluginRef.current) return;
    try {
      if (!markers || markers.length === 0) {
        markersPluginRef.current.setMarkers([]);
        return;
      }
      const sorted = markers
        .map(m => ({ ...m, time: m.time as any }))
        .sort((a, b) => (a.time as number) - (b.time as number));
      markersPluginRef.current.setMarkers(sorted);
    } catch (e) {
      console.warn('Markers error:', e);
    }
  }, [markers]);

  // Render horizontal price lines
  useEffect(() => {
    if (!seriesRef.current) return;
    priceLinesRef.current.forEach(line => {
      try { seriesRef.current?.removePriceLine(line); } catch (e) {}
    });
    priceLinesRef.current = [];

    if (priceLines && priceLines.length > 0) {
      priceLines.forEach(pl => {
        try {
          const line = seriesRef.current?.createPriceLine({
            price: pl.price,
            color: pl.color,
            lineWidth: 2,
            lineStyle: 2, // Dashed
            axisLabelVisible: true,
            title: pl.text,
          });
          if (line) priceLinesRef.current.push(line);
        } catch (e) {}
      });
    }
  }, [priceLines]);

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
  const [settingsOpen, setSettingsOpen] = useState(false);
  const settingsRef = useRef<HTMLDivElement>(null);
  const { theme, updateSettings } = useLayoutContext();
  const darkMode = theme === 'dark';
  const [chartTf, setChartTf] = useState('M5');
  const [chartBarSpacing, setChartBarSpacing] = useState(10);
  const [chartFullscreen, setChartFullscreen] = useState(false);

  // ESC key to exit fullscreen
  useEffect(() => {
    if (!chartFullscreen) return;
    const handleEsc = (e: KeyboardEvent) => { if (e.key === 'Escape') setChartFullscreen(false); };
    window.addEventListener('keydown', handleEsc);
    return () => window.removeEventListener('keydown', handleEsc);
  }, [chartFullscreen]);

  // isMarketClosedDynamic is defined below after state declarations

  const [candles, setCandles] = useState<OHLCCandle[]>([]);
  const [isLoadingHistory, setIsLoadingHistory] = useState(false);
  const [symbolDataStatus, setSymbolDataStatus] = useState<Record<string, 'none' | 'loading' | 'loaded'>>({});
  const [selectedPosition, setSelectedPosition] = useState<Position | null>(null);
  const [lastPriceUpdateTime, setLastPriceUpdateTime] = useState<Record<string, number>>({});
  const [, setTickFlip] = useState(0);
  const [strategySignals, setStrategySignals] = useState<StrategySignalEntry[]>([]);

  // ── Market close detection ──
  // Crypto symbols: ตลาดเปิด 24/7 ไม่มีวันปิด
  const CRYPTO_KEYWORDS = ['BTC', 'ETH', 'LTC', 'XRP', 'SOL', 'DOGE', 'ADA', 'DOT', 'MATIC', 'AVAX', 'LINK', 'UNI', 'SHIB', 'PEPE', 'BNB', 'TRX', 'NEAR', 'APT', 'ARB', 'OP', 'ATOM', 'FIL', 'EOS', 'BCH', 'ETC', 'CRYPTO'];
  const isCryptoSymbol = (sym: string): boolean => {
    const upper = sym.toUpperCase();
    return CRYPTO_KEYWORDS.some(k => upper.includes(k));
  };

  const isMarketClosedDynamic = useCallback((sym: string) => {
    // ขณะกำลังโหลดข้อมูล ห้ามแสดง "ตลาดปิด"
    if (isLoadingHistory) return false;

    // 1. Crypto = ตลาดเปิด 24/7
    if (isCryptoSymbol(sym)) return false;

    // 2. ตรวจสอบตารางเสาร์-อาทิตย์ (Forex/Gold/Indices)
    const now = new Date();
    const day = now.getUTCDay();
    const hour = now.getUTCHours();
    if (day === 5 && hour >= 21) return true; // วันศุกร์หลัง 21:00 UTC
    if (day === 6) return true; // วันเสาร์
    if (day === 0 && hour < 21) return true; // วันอาทิตย์ก่อน 21:00 UTC

    // 3. ตรวจสอบการอัปเดต Tick — ถ้าหยุดวิ่งเกิน 2 นาที
    const lastTickTime = lastPriceUpdateTime[sym];
    if (lastTickTime && (Date.now() - lastTickTime > 120000)) {
      return true;
    }

    // 4. ตรวจสอบผ่านอายุของแท่งเทียนล่าสุด
    if (candles && candles.length > 0 && ['M1', 'M5', 'M15', 'M30', 'H1'].includes(chartTf)) {
      const lastCandleTime = candles[candles.length - 1].time;
      const diffSeconds = (Date.now() / 1000) - lastCandleTime;
      if (diffSeconds > 14400) return true; // 4 ชั่วโมง
    }

    return false;
  }, [isLoadingHistory, lastPriceUpdateTime, candles, chartTf]);

  // Close settings flyout when clicking outside
  useEffect(() => {
    const handleClickOutside = (e: MouseEvent) => {
      if (settingsRef.current && !settingsRef.current.contains(e.target as Node)) {
        setSettingsOpen(false);
      }
    };
    if (settingsOpen) document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, [settingsOpen]);
  const wsRef = useRef<WebSocket | null>(null);

  useEffect(() => { const int = setInterval(() => setTickFlip(f => f+1), 5000); return () => clearInterval(int); }, []);

  // Memoize markers: combine position markers + strategy signal markers
  const chartMarkers = useMemo<ChartMarker[]>(() => {
    const markers: ChartMarker[] = [];
    const tfSecs = tfToSeconds(chartTf);

    // 1. Strategy signal markers (all 10 strategies)
    const symbolSignals = strategySignals.filter(s => s.symbol === activeSymbol);
    for (const sig of symbolSignals) {
      const sigTime = Math.floor(new Date(sig.timestamp).getTime() / 1000);
      if (isNaN(sigTime) || sigTime <= 0) continue;
      const snappedTime = Math.floor(sigTime / tfSecs) * tfSecs;
      const isBuy = sig.signal === 'BUY';
      const color = STRATEGY_COLORS[sig.strategy] || '#aaa';
      markers.push({
        time: snappedTime,
        position: isBuy ? 'belowBar' as const : 'aboveBar' as const,
        color,
        shape: isBuy ? 'arrowUp' as const : 'arrowDown' as const,
        text: `${sig.signal} ${sig.strategy}`,
      });
    }

    // 2. ALL open positions for the active symbol — always show entry points
    const allPositions = account?.positions ?? [];
    const symbolPositions = allPositions.filter(p => p.symbol === activeSymbol);
    for (const pos of symbolPositions) {
      // MT5 sends time as "YYYY.MM.DD HH:MM" — convert dots to dashes for JS parsing
      const timeStr = (pos.open_time || '').replace(/\./g, '-');
      const openTime = Math.floor(new Date(timeStr).getTime() / 1000);
      if (isNaN(openTime) || openTime <= 0) continue;
      const snappedTime = Math.floor(openTime / tfSecs) * tfSecs;
      const isBuy = pos.type === 'BUY';
      const comment = pos.comment || '';
      const strategyRaw = comment.startsWith('EA24-') ? comment.slice(5) : comment || 'Manual';
      const strategyMap: Record<string, string> = {
        'SMC': 'กลยุทธ์ SMC', 'ICT': 'กลยุทธ์ ICT', 'Fibonacci': 'กลยุทธ์ Fibonacci',
        'ScalperPro': 'Scalper Pro', 'TrendRider': 'Trend Rider', 'BreakoutHunter': 'Breakout Hunter',
        'MeanRevert': 'Mean Revert', 'GridMaster': 'Grid Master', 'MomentumSurge': 'Momentum Surge',
        'SessionSniper': 'Session Sniper', 'Manual': 'เปิดเอง', 'EA-Web': 'เปิดเอง',
      };
      const strategyThai = strategyMap[strategyRaw] || strategyRaw;
      const dirThai = isBuy ? 'ซื้อ' : 'ขาย';
      const isSelected = selectedPosition?.ticket === pos.ticket;
      markers.push({
        time: snappedTime,
        position: isBuy ? 'belowBar' as const : 'aboveBar' as const,
        color: isSelected ? (isBuy ? '#00ff88' : '#ff4466') : (isBuy ? '#089981' : '#f23645'),
        shape: isBuy ? 'arrowUp' as const : 'arrowDown' as const,
        text: `${dirThai} ${pos.volume} | ${strategyThai}`,
      });
    }

    // Sort by time (required by lightweight-charts)
    markers.sort((a, b) => a.time - b.time);
    return markers;
  }, [selectedPosition, chartTf, strategySignals, activeSymbol, account]);

  const chartPriceLines = useMemo<ChartPriceLine[]>(() => {
    if (!selectedPosition) return [];
    const isBuy = selectedPosition.type === 'BUY';
    const comment = selectedPosition.comment || '';
    const strategyRaw = comment.startsWith('EA24-') ? comment.slice(5) : comment || 'Manual';
    const strategyMap: Record<string, string> = {
      'SMC': 'กลยุทธ์ SMC', 'ICT': 'กลยุทธ์ ICT', 'Fibonacci': 'กลยุทธ์ Fibonacci',
      'Scalping': 'กลยุทธ์ Scalping', 'BreakoutRetest': 'กลยุทธ์ Breakout Retest',
      'MeanReversion': 'กลยุทธ์ Mean Reversion', 'TrendFollowing': 'กลยุทธ์ Trend Following',
      'OrderBlock': 'กลยุทธ์ Order Block', 'FairValueGap': 'กลยุทธ์ Fair Value Gap',
      'LiquiditySweep': 'กลยุทธ์ Liquidity Sweep', 'Manual': 'เปิดเอง', 'EA-Web': 'เปิดเอง',
    };
    const strategyThai = strategyMap[strategyRaw] || `กลยุทธ์ ${strategyRaw}`;
    return [{
      price: selectedPosition.open_price,
      color: isBuy ? '#089981' : '#f23645',
      text: `${isBuy ? 'BUY' : 'SELL'} เหตุผล: ${strategyThai}`,
    }];
  }, [selectedPosition]);

   /* ── WebSocket ── */
  const chartTfRef = useRef(chartTf);
  chartTfRef.current = chartTf;
  const activeSymbolRef = useRef(activeSymbol);
  activeSymbolRef.current = activeSymbol;

  const fetchHistoryState = useRef<string>('');
  
  const loadingTimeoutRef = useRef<any>(null);
  const candleCacheRef = useRef<Record<string, OHLCCandle[]>>({});

  const requestHistory = useCallback((ws?: WebSocket | null) => {
    const target = ws || wsRef.current;
    if (target?.readyState === 1) {
      setIsLoadingHistory(true);
      setSymbolDataStatus(prev => ({ ...prev, [activeSymbolRef.current]: 'loading' }));
      // Safety timeout: clear loading after 5s even if no response
      if (loadingTimeoutRef.current) clearTimeout(loadingTimeoutRef.current);
      loadingTimeoutRef.current = setTimeout(() => setIsLoadingHistory(false), 5000);
      const stateKey = `${activeSymbolRef.current}_${chartTfRef.current}`;
      fetchHistoryState.current = stateKey;
      target.send(JSON.stringify({ action: 'get_history', symbol: activeSymbolRef.current, timeframe: chartTfRef.current, limit: 200 }));
    }
  }, []);

  const connectWs = useCallback(() => {
    const ws = new WebSocket(WS_URL);
    console.log('[WS] Connecting to:', WS_URL);
    ws.onopen = () => {
      console.log('[WS] ✅ Connected successfully!');
      // Request history as soon as WS connects
      setTimeout(() => requestHistory(ws), 500);
      // Request strategy signals history
      setTimeout(() => { if (ws.readyState === 1) ws.send(JSON.stringify({ action: 'get_signals', limit: 50 })); }, 800);
    };
    ws.onerror = (err) => { console.error('[WS] ❌ Error:', err); };
    ws.onclose = (evt) => { console.log('[WS] Closed: code=', evt.code, 'reason=', evt.reason); setEaConnected(false); setTimeout(connectWs, 3000); };
    ws.onmessage = (evt) => {
      try {
        const data = JSON.parse(evt.data);
        if (data.type === 'welcome' || data.type === 'ea_info') {
          const wasConnected = data.ea_connected ?? true;
          setEaConnected(wasConnected);
          if (data.gap_status) {
            setSymbolDataStatus(prev => ({ ...prev, ...data.gap_status }));
          }
          // Always request history — server has DB history even if EA is offline
          if (fetchHistoryState.current !== `${activeSymbolRef.current}_${chartTfRef.current}`) {
            setTimeout(() => requestHistory(), 1000);
          }
        }
        if (data.type === 'account_data') { setAccount(data as AccountData); setEaConnected(true); }
        if (data.type === 'market_watch') {
          setMarketWatch(prev => {
             const now = Date.now();
             const next = data.symbols?.map((s: any) => ({ ...s, serverTime: data.server_time })) || [];
             setLastPriceUpdateTime(prevTime => {
                const newTimes = { ...prevTime };
                next.forEach((nxt: any) => {
                   const old = prev.find(p => p.symbol === nxt.symbol);
                   if (!old || old.bid !== nxt.bid || old.ask !== nxt.ask) {
                      newTimes[nxt.symbol] = now;
                   } else if (!newTimes[nxt.symbol]) {
                      newTimes[nxt.symbol] = now;
                   }
                });
                return newTimes;
             });
             return next;
          });
          if (data.symbols?.length > 0 && activeSymbol === 'XAUUSD' && !data.symbols.find((s: MarketWatchSymbol) => s.symbol === 'XAUUSD')) setActiveSymbol(data.symbols[0].symbol);
        }
        if (data.type === 'trade_result') { 
          setToast(data as TradeResult); 
          setTimeout(() => setToast(null), 5000); 
          if (data.error && data.error.includes("Market closed")) {
            setLastPriceUpdateTime(prev => ({ ...prev, [data.symbol || activeSymbolRef.current]: 0 }));
          }
        }
        if (data.type === 'alert') { setAlert(data as AlertMsg); setTimeout(() => setAlert(null), 8000); }
        if (data.type === 'gap_fill_status') {
          setSymbolDataStatus(prev => ({ ...prev, [data.symbol]: data.status }));
          if (data.status === 'loaded' && data.symbol === activeSymbolRef.current) {
             // EA finished loading candles — re-request from server DB which now has the data
             setTimeout(() => requestHistory(), 800);
          }
        }
        if (data.type === 'history') {
          // Prevent rendering stale data if user rapidly switched symbols
          if (data.symbol && data.symbol !== activeSymbolRef.current) return;
          // Accept data from mt5_direct regardless of timeframe mismatch 
          // (server might have sent M1 candles while user is on M5)
          // But only update chart if timeframe matches OR if we currently have no data
          if (data.timeframe && data.timeframe !== chartTfRef.current && data.source !== 'mt5_direct') return;
          
          if (data.candles && data.candles.length > 0) {
            // If source is mt5_direct but timeframe doesn't match,
            // don't set candles directly — instead trigger a re-request from DB
            if (data.source === 'mt5_direct' && data.timeframe !== chartTfRef.current) {
              setTimeout(() => requestHistory(), 500);
            } else {
              // Only update if data actually changed (prevent flickering)
              setCandles(prev => {
                if (prev.length === data.candles.length && prev.length > 0) {
                  const lastOld = prev[prev.length - 1];
                  const lastNew = data.candles[data.candles.length - 1];
                  if (lastOld.time === lastNew.time && lastOld.close === lastNew.close) return prev;
                }
                // Cache candles for fast symbol switching
                const cacheKey = `${data.symbol || activeSymbolRef.current}_${data.timeframe || chartTfRef.current}`;
                candleCacheRef.current[cacheKey] = data.candles;
                return data.candles;
              });
            }
          }
          setIsLoadingHistory(false);
          setSymbolDataStatus(prev => ({ ...prev, [data.symbol || activeSymbolRef.current]: 'loaded' }));
          if (loadingTimeoutRef.current) clearTimeout(loadingTimeoutRef.current);
        }
        // Live tick update — update marketWatch bid/ask + server_time in real-time for live candle
        if (data.type === 'tick' && data.symbol && data.bid) {
          setMarketWatch(prev => prev.map(m => 
            m.symbol === data.symbol 
              ? { ...m, bid: data.bid, ask: data.ask ?? m.ask, spread: data.spread ?? m.spread, serverTime: data.server_time ?? m.serverTime }
              : m
          ));
        }
        // Handle candle_data from EA (historical backfill) — only when chart is empty
        if (data.type === 'candle_data' && data.symbol === activeSymbolRef.current && data.candles?.length > 0) {
          // Only accept if chart currently has no data (avoid flickering from repeated broadcasts)
          setCandles(prev => {
            if (prev.length > 0) return prev; // Already have data, skip
            const tfMin = Number(data.timeframe || 5);
            const tfMap: Record<number, string> = { 1: 'M1', 5: 'M5', 15: 'M15', 30: 'M30', 60: 'H1', 240: 'H4', 1440: 'D1' };
            const tfLabel = tfMap[tfMin] || 'M5';
            if (tfLabel !== chartTfRef.current) {
              setTimeout(() => requestHistory(), 800);
              return prev;
            }
            const converted = data.candles.map((c: any) => ({
              time: c.t, open: c.o, high: c.h, low: c.l, close: c.c,
            }));
            setIsLoadingHistory(false);
            setSymbolDataStatus(p => ({ ...p, [data.symbol]: 'loaded' }));
            return converted;
          });
        }
        // Handle strategy_signal from engine (real-time)
        if (data.type === 'strategy_signal') {
          if (data.symbol && data.signal) {
            setStrategySignals(prev => {
              const entry: StrategySignalEntry = {
                setup_id: data.setup_id, signal: data.signal, symbol: data.symbol,
                strategy: data.strategy, reason: data.reason,
                timestamp: new Date().toISOString(),
              };
              return [entry, ...prev].slice(0, 100);
            });
          }
        }
        // Handle strategy_signals history (bulk from get_signals)
        if (data.type === 'strategy_signals') {
          if (data.signals) {
            setStrategySignals(data.signals.map((s: any) => ({
              setup_id: s.setup_id, signal: s.signal_type, symbol: s.symbol || '',
              strategy: s.strategy || '', reason: s.reason || '',
              timestamp: s.timestamp,
            })));
          }
        }
      } catch { /* */ }
    };
    wsRef.current = ws;
  }, []); // No deps — WebSocket stays alive across symbol/TF changes

  useEffect(() => { connectWs(); return () => { wsRef.current?.close(); }; }, [connectWs]);
  const send = (msg: object) => { if (wsRef.current?.readyState === 1) wsRef.current.send(JSON.stringify(msg)); };

  // Request candle history on symbol/timeframe change
  useEffect(() => {
    // Check cache first for instant switching
    const cacheKey = `${activeSymbol}_${chartTf}`;
    const cached = candleCacheRef.current[cacheKey];
    if (cached && cached.length > 0) {
      setCandles(cached);
      setIsLoadingHistory(false);
    } else {
      setCandles([]); // Clear chart immediately for new symbol/TF
      setIsLoadingHistory(true); // Show loading spinner immediately
    }
    fetchHistoryState.current = ''; // Reset so welcome handler won't block
    // Request fresh data immediately (no delay)
    requestHistory();
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
          {!chartFullscreen && (
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
          )}

          {/* Chart & Open Positions Split */}
          <div className={`flex-1 flex flex-col gap-4 min-h-0 ${chartFullscreen ? 'fixed inset-0 z-[9998] bg-body-bg p-2' : ''}`}>
            <div className={`card flex-1 !rounded-2xl !p-5 flex flex-col ${chartFullscreen ? '!rounded-none' : ''}`} style={{ minHeight: chartFullscreen ? undefined : 300 }}>
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
                  {/* Zoom controls */}
                  <div className="flex items-center bg-default-100 dark:bg-default-200/20 rounded-lg p-0.5 gap-0.5">
                    <button
                      onClick={() => setChartBarSpacing(prev => Math.max(3, prev - 2))}
                      className="p-1 rounded-md text-default-500 hover:text-default-800 dark:hover:text-white hover:bg-default-200 dark:hover:bg-default-300/20 transition-all"
                      title="ย่อแท่งเทียน"
                    >
                      <LuZoomOut size={13} />
                    </button>
                    <span className="text-[9px] text-default-400 font-mono w-5 text-center select-none">{chartBarSpacing}</span>
                    <button
                      onClick={() => setChartBarSpacing(prev => Math.min(40, prev + 2))}
                      className="p-1 rounded-md text-default-500 hover:text-default-800 dark:hover:text-white hover:bg-default-200 dark:hover:bg-default-300/20 transition-all"
                      title="ขยายแท่งเทียน"
                    >
                      <LuZoomIn size={13} />
                    </button>
                  </div>
                  {/* Fullscreen toggle */}
                  <button
                    onClick={() => setChartFullscreen(f => !f)}
                    className="p-1.5 rounded-lg bg-default-100 dark:bg-default-200/20 text-default-500 hover:text-default-800 dark:hover:text-white hover:bg-default-200 dark:hover:bg-default-300/20 transition-all"
                    title={chartFullscreen ? 'ย่อกราฟ (Esc)' : 'ขยายกราฟเต็มจอ'}
                  >
                    {chartFullscreen ? <LuMinimize2 size={13} /> : <LuMaximize2 size={13} />}
                  </button>
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

                  {/* Market Closed Overlay — displayed on chart */}
                  {isMarketClosedDynamic(activeSymbol) && (
                    <div className="absolute inset-0 z-40 flex items-center justify-center bg-black/30 dark:bg-black/50 backdrop-blur-[2px] rounded-lg pointer-events-none transition-all duration-300">
                      <div className="text-center bg-card/80 dark:bg-card/60 backdrop-blur-md px-12 py-8 rounded-3xl border border-danger/30 shadow-2xl transform scale-100">
                        <div className="text-4xl md:text-5xl font-black text-danger drop-shadow-lg tracking-wide flex items-center justify-center gap-3 uppercase">
                          <LuShieldAlert className="size-10 md:size-12 text-danger" />
                          Market Closed
                        </div>
                      </div>
                    </div>
                  )}
                  
                  <CandleChart symbol={activeSymbol} candles={candles} bid={bid} darkMode={darkMode} chartTf={chartTf}
                    markers={chartMarkers} priceLines={chartPriceLines} serverTime={sym?.serverTime}
                    barSpacing={chartBarSpacing}
                  />

                </div>
              </div>
            </div>

            {!chartFullscreen && <div className="card !rounded-2xl !p-5 flex-shrink-0" style={{ maxHeight: 220, overflow: 'auto' }}>
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
                      <tr key={pos.ticket}
                        onClick={() => {
                          setSelectedPosition(selectedPosition?.ticket === pos.ticket ? null : pos);
                          if (pos.symbol !== activeSymbol) setActiveSymbol(pos.symbol);
                        }}
                        className={`cursor-pointer transition-colors ${selectedPosition?.ticket === pos.ticket ? 'bg-primary/10 dark:bg-primary/20' : i % 2 === 0 ? 'hover:bg-default-50 dark:hover:bg-default-200/10' : 'bg-default-50/50 dark:bg-default-200/5 hover:bg-default-100 dark:hover:bg-default-200/15'}`}
                      >
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
                            onClick={(e) => { e.stopPropagation(); setCloseModal({ show: true, ticket: pos.ticket, symbol: pos.symbol }); }}
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
            </div>}
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
              <div className="text-[13px] font-bold text-default-900">EA-24 <span className="text-[10px] font-medium text-default-400">v5.9.1</span></div>
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
                      {wl.map(w => {
                        const isClosed = isMarketClosedDynamic(w.symbol);
                        return (
                          <tr key={w.symbol} onClick={() => setActiveSymbol(w.symbol)} className={`cursor-pointer hover:bg-default-50 dark:hover:bg-default-200/10 transition-colors ${isClosed ? 'opacity-50' : ''}`}>
                            <td className={`text-xs py-1 font-semibold flex items-center gap-1.5 ${activeSymbol === w.symbol ? 'text-primary' : 'text-default-700'}`}>
                              {isClosed ? (
                                <LuMoon size={10} className="text-default-500" />
                              ) : (
                                <div className={`size-1.5 rounded-full ${symbolDataStatus[w.symbol] === 'loaded' ? 'bg-success' : symbolDataStatus[w.symbol] === 'loading' ? 'bg-warning' : 'bg-danger'}`} />
                              )}
                              {w.symbol}
                            </td>
                            <td className="text-xs py-1 text-right font-mono text-default-600">{w.last.toFixed(w.last > 100 ? 2 : 4)}</td>
                            <td className={`text-xs py-1 text-right font-mono ${w.change >= 0 ? 'text-success' : 'text-danger'}`}>{w.change >= 0 ? '+' : ''}{w.change.toFixed(2)}</td>
                            <td className={`text-xs py-1 text-right font-mono ${w.pct >= 0 ? 'text-success' : 'text-danger'}`}>{w.pct >= 0 ? '+' : ''}{w.pct.toFixed(2)}%</td>
                          </tr>
                        );
                      })}
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
          /* Settings flyout animation */
          .settings-flyout {
            transform: translateX(10px);
            opacity: 0;
            pointer-events: none;
            transition: transform 0.2s cubic-bezier(0.4, 0, 0.2, 1), opacity 0.2s ease;
          }
          .settings-flyout.open {
            transform: translateX(0);
            opacity: 1;
            pointer-events: auto;
          }
          /* Group separator */
          .nav-group-label {
            font-size: 8px;
            font-weight: 700;
            letter-spacing: 0.08em;
            text-transform: uppercase;
            color: var(--color-default-400);
            padding: 0 0 4px 0;
            margin-top: 2px;
            text-align: center;
            user-select: none;
          }
        `}</style>
        <div className="absolute bottom-0 left-0 right-0 h-16 lg:static lg:h-auto lg:w-[72px] shrink-0 flex flex-row lg:flex-col items-center justify-around lg:justify-start lg:pt-3 lg:pb-3 gap-1 lg:gap-1 overflow-x-auto lg:overflow-visible bg-card/80 dark:bg-card/80 backdrop-blur-md lg:bg-transparent lg:dark:bg-transparent lg:backdrop-blur-none border-t border-default-200/60 dark:border-default-300/10 lg:border-none z-50">

          {/* Grouped Navigation */}
          {NAV_GROUPS.map((group, gi) => (
            <div key={group.id} className="flex flex-row lg:flex-col items-center gap-1 lg:gap-1.5">
              {/* Group label — desktop only */}
              <div className="nav-group-label hidden lg:block w-full">{group.label}</div>
              {group.items.map(item => {
                const active = activePanel === item.key;
                return (
                  <button
                    key={item.key}
                    onClick={() => { setActivePanel(item.key); setSettingsOpen(false); }}
                    data-tip={item.label}
                    className={`mac-tooltip shrink-0 flex items-center justify-center transition-all cursor-pointer border-none rounded-xl ${
                      active
                        ? 'bg-primary/10 text-primary shadow-sm shadow-primary/10'
                        : 'bg-default-200/80 dark:bg-default-200/40 text-default-700 dark:text-default-300 hover:text-default-900 dark:hover:text-white hover:bg-default-300 dark:hover:bg-default-200/60'
                    }`}
                    style={{ width: 38, height: 38 }}
                  >
                    {item.icon}
                  </button>
                );
              })}
              {/* Separator between groups — desktop only */}
              {gi < NAV_GROUPS.length - 1 && (
                <div className="hidden lg:block w-8 h-px bg-default-200 dark:bg-default-300/15 my-1" />
              )}
            </div>
          ))}

          {/* Bottom section: Settings, Theme, Connection */}
          <div className="lg:mt-auto flex flex-row lg:flex-col items-center gap-1.5 lg:gap-1.5 px-2 lg:px-0 relative" ref={settingsRef}>
            <div className="hidden lg:block w-8 h-px bg-default-200 dark:bg-default-300/15 my-1" />

            {/* ── Settings button ── */}
            <button
              onClick={() => setSettingsOpen(!settingsOpen)}
              data-tip="ตั้งค่า"
              className={`mac-tooltip shrink-0 flex items-center justify-center transition-all cursor-pointer border-none rounded-xl ${
                settingsOpen || SETTINGS_ITEMS.some(s => s.key === activePanel)
                  ? 'bg-primary/10 text-primary shadow-sm shadow-primary/10'
                  : 'bg-default-200/80 dark:bg-default-200/40 text-default-700 dark:text-default-300 hover:text-default-900 dark:hover:text-white hover:bg-default-300 dark:hover:bg-default-200/60'
              }`}
              style={{ width: 38, height: 38 }}
            >
              <LuSettings size={18} className={`transition-transform duration-300 ${settingsOpen ? 'rotate-90' : ''}`} />
            </button>

            {/* ── Settings Flyout Panel ── */}
            <div className={`settings-flyout ${settingsOpen ? 'open' : ''} absolute lg:bottom-0 lg:right-[calc(100%+12px)] bottom-[calc(100%+12px)] left-0 lg:left-auto`}>
              <div className="bg-card dark:bg-[#1e2130] rounded-2xl shadow-2xl dark:shadow-black/40 border border-default-200/60 dark:border-default-300/10 p-2 min-w-[200px]">
                <div className="px-3 pt-2 pb-1.5">
                  <div className="text-[11px] font-bold text-default-500 uppercase tracking-wider">⚙ ตั้งค่า</div>
                </div>
                <div className="flex flex-col gap-0.5">
                  {SETTINGS_ITEMS.map(item => {
                    const active = activePanel === item.key;
                    return (
                      <button
                        key={item.key}
                        onClick={() => { setActivePanel(item.key); setSettingsOpen(false); }}
                        className={`flex items-center gap-2.5 px-3 py-2 rounded-xl text-left transition-all border-none cursor-pointer ${
                          active
                            ? 'bg-primary/10 text-primary'
                            : 'text-default-600 dark:text-default-400 hover:bg-default-100 dark:hover:bg-default-200/10 hover:text-default-900 dark:hover:text-white'
                        }`}
                      >
                        <span className={`shrink-0 ${active ? 'text-primary' : 'text-default-400 dark:text-default-500'}`}>{item.icon}</span>
                        <span className="text-[13px] font-medium">{item.label}</span>
                        {active && <span className="ml-auto size-1.5 rounded-full bg-primary" />}
                      </button>
                    );
                  })}
                </div>
              </div>
            </div>

            {/* Theme Toggle */}
            <button
              onClick={() => updateSettings({ theme: darkMode ? 'light' : 'dark' })}
              data-tip={darkMode ? 'Light Mode' : 'Dark Mode'}
              className="mac-tooltip shrink-0 flex items-center justify-center transition-all cursor-pointer border-none rounded-xl bg-default-200/80 dark:bg-default-200/40 text-default-700 dark:text-default-300 hover:bg-default-300 hover:text-default-900 dark:hover:bg-default-200/60 dark:hover:text-white"
              style={{ width: 38, height: 38 }}
            >
              {darkMode ? <LuSun size={18} /> : <LuMoon size={18} />}
            </button>

            {/* Connection Status */}
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
