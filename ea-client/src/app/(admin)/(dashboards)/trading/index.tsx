import { useState, useEffect, useRef, useCallback, lazy, Suspense, type ReactNode } from 'react';
import { useNavigate } from 'react-router-dom';
import { createChart, ColorType, CandlestickSeries, HistogramSeries, type IChartApi, type Time } from 'lightweight-charts';
import {
  LuMonitorDot, LuChartCandlestick, LuServer, LuDatabase, LuShieldCheck,
  LuList, LuWrench, LuFlaskConical, LuArrowLeftRight, LuHistory,
  LuSearch, LuSettings, LuPlus, LuX,
  LuChevronRight, LuChevronDown,
  LuMousePointer, LuCrosshair, LuPencilLine, LuType, LuRuler, LuLayoutGrid,
} from 'react-icons/lu';
import { getWsUrl } from '@/utils/config';

/* ── Lazy-loaded page components ── */
const MT5Page = lazy(() => import('@/app/(admin)/(config)/mt5/index'));
const ServerPage = lazy(() => import('@/app/(admin)/(config)/server/index'));
const DatabasePage = lazy(() => import('@/app/(admin)/(config)/database/index'));
const SecurityPage = lazy(() => import('@/app/(admin)/(config)/security/index'));
const StrategyListPage = lazy(() => import('@/app/(admin)/(config)/strategy-list/index'));
const StrategyBuilderPage = lazy(() => import('@/app/(admin)/(config)/strategy-builder/index'));
const StrategyBacktestPage = lazy(() => import('@/app/(admin)/(config)/strategy-backtest/index'));
const TradeActivePage = lazy(() => import('@/app/(admin)/(config)/trade-active/index'));
const TradeSetupPage = lazy(() => import('@/app/(admin)/(config)/trade-setup/index'));
const TradeHistoryPage = lazy(() => import('@/app/(admin)/(config)/trade-history/index'));

/* ── Types ── */
type Position = { ticket: number; symbol: string; type: string; volume: number; open_price: number; current_price: number; pnl: number; swap: number; sl: number; tp: number; magic: number; open_time: string; comment: string; };
type AccountData = { balance: number; equity: number; profit: number; margin: number; free_margin: number; currency: string; positions: Position[]; positions_count: number; trading_enabled: boolean; };
type MarketWatchSymbol = { symbol: string; bid: number; ask: number; spread: number; digits: number; };
type TradeResult = { action: string; success: boolean; symbol?: string; direction?: string; lot?: number; ticket?: number; error?: string; };
type AlertMsg = { type: 'alert'; level: 'info' | 'warning' | 'error'; title: string; message: string; };

const WS_URL = getWsUrl();

// (Mock data generation removed - using live Websocket ticks)

/* ── Panel definitions ── */
type PanelKey = 'chart' | 'mt5' | 'server' | 'database' | 'security' | 'strategies' | 'builder' | 'backtest' | 'trades' | 'setup' | 'history';
type NavItem = { key: PanelKey; icon: ReactNode; label: string; badge?: boolean } | { key: string; divider: true };

const NAV: NavItem[] = [
  { key: 'chart', icon: <LuMonitorDot size={20} />, label: 'Chart', badge: true },
  { key: 'mt5', icon: <LuChartCandlestick size={20} />, label: 'MT5' },
  { key: 'server', icon: <LuServer size={20} />, label: 'Server' },
  { key: 'database', icon: <LuDatabase size={20} />, label: 'Database' },
  { key: 'security', icon: <LuShieldCheck size={20} />, label: 'Security' },
  { key: 'd1', divider: true },
  { key: 'strategies', icon: <LuList size={20} />, label: 'Strategies' },
  { key: 'builder', icon: <LuWrench size={20} />, label: 'Builder' },
  { key: 'backtest', icon: <LuFlaskConical size={20} />, label: 'Backtest' },
  { key: 'trades', icon: <LuArrowLeftRight size={20} />, label: 'Trades' },
  { key: 'history', icon: <LuHistory size={20} />, label: 'History' },
];

const PANEL_COMPONENTS: Record<Exclude<PanelKey, 'chart'>, React.LazyExoticComponent<React.ComponentType>> = {
  mt5: MT5Page,
  server: ServerPage,
  database: DatabasePage,
  security: SecurityPage,
  strategies: StrategyListPage,
  builder: StrategyBuilderPage,
  backtest: StrategyBacktestPage,
  trades: TradeActivePage,
  setup: TradeSetupPage,
  history: TradeHistoryPage,
};

const DRAW_TOOLS = [LuMousePointer, LuCrosshair, LuPencilLine, LuType, LuRuler, LuLayoutGrid];

/* ── Light Theme Colors ── */
const L = {
  bg: '#ffffff', panel: '#f8f9fa', border: '#e0e3eb', borderLight: '#eff1f3',
  text: '#131722', textMid: '#4a4a4a', textDim: '#9598a1',
  green: '#089981', red: '#f23645', accent: '#2962ff', orange: '#f7931a',
  chartBg: '#ffffff', gridLine: '#f0f3fa',
  sellBg: '#f23645', buyBg: '#089981',
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
  const [rightTab, setRightTab] = useState<'alerts' | 'history' | 'system'>('alerts');
  const [expandedCat, setExpandedCat] = useState<string | null>('Forex');
  const [activePanel, setActivePanel] = useState<PanelKey>('chart');
  const wsRef = useRef<WebSocket | null>(null);
  const chartContainerRef = useRef<HTMLDivElement>(null);
  const chartRef = useRef<IChartApi | null>(null);
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const candleSeriesRef = useRef<any>(null);
  const activeCandleRef = useRef<{ time: Time; open: number; high: number; low: number; close: number } | null>(null);

  /* ── WebSocket ── */
  const connectWs = useCallback(() => {
    const ws = new WebSocket(WS_URL);
    ws.onclose = () => { setEaConnected(false); setTimeout(connectWs, 3000); };
    ws.onmessage = (evt) => {
      try {
        const data = JSON.parse(evt.data);
        if (data.type === 'welcome' || data.type === 'ea_info') setEaConnected(data.ea_connected ?? true);
        if (data.type === 'account_data') { setAccount(data as AccountData); setEaConnected(true); }
        if (data.type === 'market_watch') {
          setMarketWatch(data.symbols || []);
          if (data.symbols?.length > 0 && activeSymbol === 'XAUUSD' && !data.symbols.find((s: MarketWatchSymbol) => s.symbol === 'XAUUSD')) setActiveSymbol(data.symbols[0].symbol);
        }
        if (data.type === 'trade_result') { setToast(data as TradeResult); setTimeout(() => setToast(null), 5000); }
        if (data.type === 'alert') { setAlert(data as AlertMsg); setTimeout(() => setAlert(null), 8000); }
        if (data.type === 'history' && data.symbol === activeSymbol && candleSeriesRef.current) {
          // data.candles is an array of { time, open, high, low, close }
          if (data.candles && data.candles.length > 0) {
            candleSeriesRef.current.setData(data.candles);
            // Record the last historical candle as our active candle base
            activeCandleRef.current = data.candles[data.candles.length - 1];
          } else {
            candleSeriesRef.current.setData([]);
            activeCandleRef.current = null;
          }
        }
        if (data.type === 'tick' && data.symbol === activeSymbol && candleSeriesRef.current) {
          const now = new Date();
          // Group ticks into 1-minute candles for display
          now.setSeconds(0, 0);
          const time = Math.floor(now.getTime() / 1000) as Time;
          
          const currentCandle = activeCandleRef.current;
          let updatedCandle;
          
          if (!currentCandle || currentCandle.time !== time) {
            // New candle
            updatedCandle = { time, open: data.bid, high: data.bid, low: data.bid, close: data.bid };
          } else {
            // Update existing candle
            updatedCandle = {
              time,
              open: currentCandle.open,
              high: Math.max(currentCandle.high, data.bid),
              low: Math.min(currentCandle.low, data.bid),
              close: data.bid,
            };
          }
          activeCandleRef.current = updatedCandle;
          candleSeriesRef.current.update(updatedCandle);
        }
      } catch { /* */ }
    };
    wsRef.current = ws;
  }, [activeSymbol]);

  useEffect(() => { connectWs(); return () => { wsRef.current?.close(); }; }, [connectWs]);
  const send = (msg: object) => { if (wsRef.current?.readyState === 1) wsRef.current.send(JSON.stringify(msg)); };
  // Trade buttons were removed from the top bar in previous step, so handleOpenTrade is unused here for now.
  const handleCloseTrade = () => { send({ action: 'close_trade', ticket: closeModal.ticket }); setCloseModal({ show: false, ticket: 0, symbol: '' }); };

  /* ── Chart ── */
  useEffect(() => {
    if (activePanel !== 'chart') return;
    if (!chartContainerRef.current) return;
    const el = chartContainerRef.current;
    const chart = createChart(el, {
      width: el.clientWidth, height: el.clientHeight,
      layout: { background: { type: ColorType.Solid, color: L.chartBg }, textColor: L.textDim },
      grid: { vertLines: { color: L.gridLine }, horzLines: { color: L.gridLine } },
      crosshair: { mode: 0 },
      rightPriceScale: { borderColor: L.border },
      timeScale: { borderColor: L.border, timeVisible: true },
    });
    const cs = chart.addSeries(CandlestickSeries, { upColor: L.green, downColor: L.red, borderUpColor: L.green, borderDownColor: L.red, wickUpColor: L.green, wickDownColor: L.red });
    const vs = chart.addSeries(HistogramSeries, { color: L.green, priceFormat: { type: 'volume' }, priceScaleId: '' });
    vs.priceScale().applyOptions({ scaleMargins: { top: 0.85, bottom: 0 } });
    
    // Clear data and request history for the active symbol
    cs.setData([]);
    vs.setData([]);
    activeCandleRef.current = null;
    send({ action: 'get_history', symbol: activeSymbol, limit: 300 });
    
    chart.timeScale().fitContent();
    chartRef.current = chart;
    candleSeriesRef.current = cs;
    const ro = new ResizeObserver(() => chart.applyOptions({ width: el.clientWidth, height: el.clientHeight }));
    ro.observe(el);
    return () => { ro.disconnect(); chart.remove(); };
  }, [activeSymbol, activePanel]);

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
    ? marketWatch.map(m => ({ symbol: m.symbol, last: m.bid, change: +(Math.random() * 40 - 20).toFixed(2), pct: +(Math.random() * 4 - 2).toFixed(2) }))
    : [{ symbol: 'XAUUSD', last: 2350.50, change: 12.30, pct: 0.52 }, { symbol: 'EURUSD', last: 1.0842, change: -0.0012, pct: -0.11 }, { symbol: 'GBPUSD', last: 1.2654, change: 0.0034, pct: 0.27 }, { symbol: 'USDJPY', last: 150.32, change: -0.45, pct: -0.30 }];

  /* ── Render Panel Content ── */
  const renderPanel = () => {
    if (activePanel === 'chart') {
      return (
        <div style={{ flex: 1, display: 'flex', flexDirection: 'column' }}>
          <div style={{ flex: 1, position: 'relative' }}>
            <div ref={chartContainerRef} style={{ position: 'absolute', inset: 0 }} />
            {/* Drawing tools float */}
            <div className="flex gap-0.5 bg-card border border-default-200 rounded-lg p-1 shadow-sm" style={{ position: 'absolute', bottom: 48, left: '50%', transform: 'translateX(-50%)' }}>
              {DRAW_TOOLS.map((Icon, i) => (
                <button key={i} className="btn btn-icon rounded-full bg-transparent text-default-400 hover:bg-default-100 hover:text-default-700" style={{ width: 28, height: 28 }}>
                  <Icon size={14} />
                </button>
              ))}
            </div>
          </div>
          {/* Bottom tabs */}
          <div className="flex items-center h-8.5 bg-default-50 border-t border-default-200">
            <button className="btn btn-icon rounded-full bg-transparent text-default-400 hover:text-default-700" style={{ width: 34, height: 34, borderRight: `1px solid ${L.border}`, borderRadius: 0 }}><LuPlus size={14} /></button>
            {wl.slice(0, 6).map(w => (
              <button key={w.symbol} onClick={() => setActiveSymbol(w.symbol)} className={`btn btn-sm rounded-full text-xs font-medium ${activeSymbol === w.symbol ? 'bg-card text-default-800 shadow-sm' : 'bg-transparent text-default-400 hover:text-default-700'}`} style={{ borderRadius: 0, borderRight: `1px solid ${L.border}`, height: '100%' }}>
                {w.symbol}
              </button>
            ))}
          </div>
        </div>
      );
    }

    // Lazy-loaded page panel
    const PanelComponent = PANEL_COMPONENTS[activePanel];
    if (!PanelComponent) return null;
    return (
      <div style={{ flex: 1, overflow: 'auto', background: L.bg }}>
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
    <div style={{ position: 'fixed', inset: 0, zIndex: 9999, display: 'flex', flexDirection: 'column', fontFamily: "'Inter', -apple-system, BlinkMacSystemFont, sans-serif", background: L.bg, color: L.text }}>

      {/* ═══ TOP BAR ═══ */}
      <div className="flex items-center justify-between px-4 border-b border-default-200" style={{ height: 48, background: L.panel }}>
        {/* Left */}
        <div className="flex items-center gap-4">
          <div className="flex items-center gap-2 cursor-pointer" onClick={() => { navigate('/'); setActivePanel('chart'); }}>
            <div className="size-8 rounded-xl bg-default-900 flex items-center justify-center">
              <span className="text-[9px] font-black text-white tracking-tight">EA24</span>
            </div>
            <div>
              <div className="text-[13px] font-bold text-default-900">EA-24</div>
              <div className="text-[8px] text-default-400">algorithmic trading</div>
            </div>
          </div>
        </div>

        {/* Center ticker */}
        <div className="flex items-center gap-3">
          <span className="text-[13px] font-bold text-default-900">{activeSymbol}</span>
          <span className="text-[13px] font-bold text-default-900">{bid > 0 ? bid.toFixed(digits) : '—'}</span>
          <span className={`text-xs font-semibold ${profit >= 0 ? 'text-success' : 'text-danger'}`}>
            {profit >= 0 ? '+' : ''}{profit.toFixed(2)} ({balance > 0 ? ((profit / balance) * 100).toFixed(2) : '0.00'}%)
          </span>
        </div>

        {/* Right balance */}
        <div className="flex items-center gap-5">
          <div className="text-right">
            <div className="text-[10px] text-default-400">Balance</div>
            <div className="text-xs font-bold text-default-900">${balance.toLocaleString('en-US', { minimumFractionDigits: 2 })}</div>
          </div>
          <div className="text-right">
            <div className="text-[10px] text-default-400">Equity</div>
            <div className={`text-xs font-bold ${profit >= 0 ? 'text-success' : 'text-danger'}`}>${equity.toLocaleString('en-US', { minimumFractionDigits: 2 })}</div>
          </div>
          <div className="size-8 rounded-full" style={{ background: 'linear-gradient(135deg, #8b5cf6, #ec4899)' }} />
        </div>
      </div>



      {/* ═══ MAIN AREA ═══ */}
      <div style={{ display: 'flex', flex: 1, overflow: 'hidden' }}>

        {/* ── CONTENT AREA (Chart or Page Panel) ── */}
        {renderPanel()}

        {/* ── RIGHT SIDEBAR (Cards) ── */}
        <style>{`.hide-sb::-webkit-scrollbar{display:none}`}</style>
        <div className="hide-sb flex flex-col gap-2 p-2 overflow-auto bg-default-50 border-l border-default-200" style={{ width: 300, scrollbarWidth: 'none' }}>

          {/* Watchlist Card */}
          <div className="card">
            <div className="card-header">
              <h6 className="card-title text-sm">Watchlist</h6>
              <div className="flex gap-1">
                <button className="btn btn-icon rounded-full bg-default-100 text-default-500 hover:bg-default-200 hover:text-default-800" style={{ width: 28, height: 28 }}><LuPlus size={12} /></button>
                <button className="btn btn-icon rounded-full bg-default-100 text-default-500 hover:bg-default-200 hover:text-default-800" style={{ width: 28, height: 28 }}><LuSettings size={12} /></button>
              </div>
            </div>
            <div className="card-body" style={{ padding: '8px 16px' }}>
              <table className="w-full">
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
                    <tr key={w.symbol} onClick={() => setActiveSymbol(w.symbol)} className="cursor-pointer hover:bg-default-50 transition-colors">
                      <td className={`text-xs py-1 font-semibold ${activeSymbol === w.symbol ? 'text-default-900' : 'text-default-600'}`}>{w.symbol}</td>
                      <td className="text-xs py-1 text-right font-mono">{w.last.toFixed(w.last > 100 ? 2 : 4)}</td>
                      <td className={`text-xs py-1 text-right font-mono ${w.change >= 0 ? 'text-success' : 'text-danger'}`}>{w.change >= 0 ? '+' : ''}{w.change.toFixed(2)}</td>
                      <td className={`text-xs py-1 text-right font-mono ${w.pct >= 0 ? 'text-success' : 'text-danger'}`}>{w.pct >= 0 ? '+' : ''}{w.pct.toFixed(2)}%</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>

          {/* Categories Card */}
          <div className="card">
            <div className="card-body" style={{ padding: '8px 16px' }}>
              {['Shares', 'Futures', 'Cryptocurrencies'].map(cat => (
                <button key={cat} onClick={() => setExpandedCat(expandedCat === cat ? null : cat)} className="flex w-full items-center justify-between py-1.5 text-xs text-default-500 hover:text-default-800 transition-colors bg-transparent border-0">
                  <span>{cat}</span>
                  <LuChevronRight size={12} style={{ transform: expandedCat === cat ? 'rotate(90deg)' : 'none', transition: 'transform 0.15s' }} />
                </button>
              ))}
            </div>
          </div>

          {/* Alerts / History / System Card */}
          <div className="card" style={{ flex: 1, overflow: 'hidden', display: 'flex', flexDirection: 'column' }}>
            <div className="card-header" style={{ minHeight: 'auto', padding: '8px 16px' }}>
              <div className="flex bg-default-100 rounded-full p-0.5 w-full">
                {(['alerts', 'history', 'system'] as const).map(t => (
                  <button key={t} onClick={() => setRightTab(t)} className={`flex-1 rounded-full py-1.5 text-[10px] font-medium capitalize transition-all border-0 ${rightTab === t ? 'bg-card text-default-800 shadow-sm' : 'bg-transparent text-default-400'}`}>
                    {t}
                  </button>
                ))}
              </div>
            </div>
            <div className="card-body" style={{ padding: '8px 16px', flex: 1, overflow: 'auto', display: 'flex', flexDirection: 'column' }}>
              <div className="flex items-center gap-1.5 mb-2">
                <button className="btn btn-icon rounded-full bg-default-100 text-default-500 hover:bg-default-200" style={{ width: 24, height: 24 }}><LuPlus size={12} /></button>
                <div className="relative flex-1">
                  <LuSearch size={11} className="absolute left-1.5 top-1/2 -translate-y-1/2 text-default-300" />
                  <input placeholder="Search..." className="form-input !h-6 !text-[10px] !pl-5 !rounded-full" />
                </div>
              </div>
              <div style={{ flex: 1, overflow: 'auto' }}>
                {positions.length > 0 ? positions.map(pos => (
                  <div key={pos.ticket} className="card mb-1.5" style={{ boxShadow: 'none' }}>
                    <div className="card-body" style={{ padding: 8 }}>
                      <div className="flex justify-between items-center">
                        <span className="text-xs font-semibold text-default-800">{pos.symbol} — {pos.type}</span>
                        <span className={`text-[9px] font-bold px-1.5 py-0.5 rounded-full ${pos.pnl >= 0 ? 'bg-success/10 text-success' : 'bg-danger/10 text-danger'}`}>
                          {pos.pnl >= 0 ? '+' : ''}${pos.pnl.toFixed(2)}
                        </span>
                      </div>
                      <div className="flex justify-between mt-1 text-[9px] text-default-400">
                        <span>{pos.volume} lot @ {pos.open_price}</span>
                        <button onClick={() => setCloseModal({ show: true, ticket: pos.ticket, symbol: pos.symbol })} className="btn btn-sm rounded-full text-danger font-semibold bg-transparent border-0 text-[9px] p-0">Close</button>
                      </div>
                    </div>
                  </div>
                )) : (
                  <div className="text-center py-6 text-xs text-default-300">{eaConnected ? 'No open positions' : 'Waiting for MT5...'}</div>
                )}
              </div>
            </div>
          </div>

          {/* Symbol Info Card */}
          <div className="card">
            <div className="card-body" style={{ padding: '12px 16px' }}>
              <div className="flex items-center gap-2 mb-2">
                <div className="size-7 rounded-full flex items-center justify-center text-[8px] font-bold text-white" style={{ background: `linear-gradient(135deg, ${L.orange}, #ff6b00)` }}>Au</div>
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

        {/* ═══ RIGHT NAV TOOLBAR ═══ */}
        <div className="card" style={{ width: 72, borderRadius: 0, borderLeft: `1px solid ${L.border}`, display: 'flex', flexDirection: 'column', alignItems: 'center', paddingTop: 12, gap: 8, overflowY: 'auto', boxShadow: 'none' }}>
          {NAV.map(item => {
            if ('divider' in item) return <div key={item.key} className="w-8 border-t border-default-200 my-1" />;
            const active = activePanel === item.key;
            return (
              <button
                key={item.key}
                onClick={() => setActivePanel(item.key)}
                className={`btn btn-icon rounded-full transition-all duration-200 relative ${
                  active
                    ? 'bg-primary/10 text-primary shadow-md border border-primary/20'
                    : 'bg-default-100 text-default-500 hover:bg-default-200 hover:text-default-800 shadow-sm border border-default-200/50 hover:shadow-md'
                }`}
                style={{ width: 44, height: 44 }}
                title={item.label}
              >
                {item.icon}
                {item.badge && (
                  <span className="absolute top-1.5 right-1.5 size-2 rounded-full bg-danger" />
                )}
              </button>
            );
          })}
          {/* Connection */}
          <div className="mt-auto pb-3 flex flex-col items-center gap-1">
            <div className={`size-2 rounded-full ${eaConnected ? 'bg-success' : 'bg-danger'}`} />
            <span className="text-[7px] text-default-400">{eaConnected ? 'ON' : 'OFF'}</span>
          </div>
        </div>
      </div>

      {/* ═══ TOAST ═══ */}
      {toast && (
        <div className={`fixed top-4 right-20 z-[999999] min-w-70 rounded-xl p-3 text-white text-xs shadow-lg ${toast.success ? 'bg-success' : 'bg-danger'}`}>
          <div className="font-bold">{toast.action === 'open' ? (toast.success ? 'Trade Opened!' : 'Open Failed') : (toast.success ? 'Trade Closed!' : 'Close Failed')}</div>
          <div className="text-[10px] opacity-80 mt-0.5">{toast.symbol} {toast.direction} {toast.lot && `${toast.lot} lot`}{toast.error && ` — ${toast.error}`}</div>
          <button onClick={() => setToast(null)} className="btn btn-icon rounded-full absolute top-1 right-2 bg-transparent text-white border-0 p-0"><LuX size={14} /></button>
        </div>
      )}
      {alert && (
        <div className="fixed top-16 right-20 z-[999999] min-w-70 rounded-xl p-3 text-white text-xs shadow-lg bg-warning">
          <div className="font-bold">{alert.title}</div>
          <div className="text-[10px] opacity-80 mt-0.5">{alert.message}</div>
          <button onClick={() => setAlert(null)} className="btn btn-icon rounded-full absolute top-1 right-2 bg-transparent text-white border-0 p-0"><LuX size={14} /></button>
        </div>
      )}

      {/* ═══ CLOSE MODAL ═══ */}
      {closeModal.show && (
        <div className="fixed inset-0 z-[99999] flex items-center justify-center bg-black/30" onClick={() => setCloseModal({ show: false, ticket: 0, symbol: '' })}>
          <div className="card" style={{ width: 360, borderRadius: 16, padding: 24 }} onClick={e => e.stopPropagation()}>
            <div className="text-center mb-4">
              <div className="size-12 rounded-full bg-danger/10 flex items-center justify-center mx-auto">
                <LuChevronDown size={24} className="text-danger" />
              </div>
            </div>
            <h3 className="text-center text-base font-bold text-default-900 mb-2">Close Position?</h3>
            <p className="text-center text-sm text-default-400 mb-6">Close <span className="text-primary font-semibold">{closeModal.symbol}</span> #{closeModal.ticket} at market?</p>
            <div className="flex gap-3">
              <button onClick={() => setCloseModal({ show: false, ticket: 0, symbol: '' })} className="btn rounded-full flex-1 bg-default-100 text-default-800 hover:bg-default-200 py-2.5 text-sm font-medium">Cancel</button>
              <button onClick={handleCloseTrade} className="btn rounded-full flex-1 bg-danger text-white hover:bg-danger/90 py-2.5 text-sm font-medium">Close Trade</button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default TradingDashboard;
