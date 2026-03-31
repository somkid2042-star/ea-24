import { useState, useEffect, useRef, useCallback, lazy, Suspense, type ReactNode } from 'react';
import { useNavigate } from 'react-router-dom';
import { createChart, ColorType, AreaSeries } from 'lightweight-charts';
import type { IChartApi, ISeriesApi } from 'lightweight-charts';
import {
  LuChartCandlestick, LuServer, LuDatabase, LuShieldCheck,
  LuList, LuWrench, LuFlaskConical, LuArrowLeftRight, LuHistory,
  LuSettings, LuPlus, LuX, LuChevronDown,
  LuSun, LuMoon,
} from 'react-icons/lu';
import { FiHome } from 'react-icons/fi';
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

/* ── Panel definitions ── */
type PanelKey = 'chart' | 'mt5' | 'server' | 'database' | 'security' | 'strategies' | 'builder' | 'backtest' | 'trades' | 'setup' | 'history';
type NavItem = { key: PanelKey; icon: ReactNode; label: string; badge?: boolean } | { key: string; divider: true };

const NAV: NavItem[] = [
  { key: 'chart', icon: <FiHome size={20} />, label: 'Home' },
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

/* ── Chart Colors (theme-aware) ── */
const CHART_DARK = { textDim: '#64748b', gridLine: '#1e2230', accent: '#3b82f6' };
const CHART_LIGHT = { textDim: '#94a3b8', gridLine: '#f1f5f9', accent: '#3b82f6' };

const LiveChart = ({ symbol, bid, darkMode }: { symbol: string, bid: number, darkMode: boolean }) => {
  const chartContainerRef = useRef<HTMLDivElement>(null);
  const chartRef = useRef<IChartApi | null>(null);
  const seriesRef = useRef<ISeriesApi<"Area"> | null>(null);
  const lastTimeRef = useRef<number>(0);
  const C = darkMode ? CHART_DARK : CHART_LIGHT;

  useEffect(() => {
    if (!chartContainerRef.current) return;
    const chart = createChart(chartContainerRef.current, {
      layout: { background: { type: ColorType.Solid, color: 'transparent' }, textColor: C.textDim },
      grid: { vertLines: { color: C.gridLine }, horzLines: { color: C.gridLine } },
      rightPriceScale: { borderVisible: false },
      timeScale: { borderVisible: false, timeVisible: true, secondsVisible: true },
      crosshair: { mode: 1 },
    });
    
    const series = chart.addSeries(AreaSeries, {
      lineColor: C.accent,
      topColor: C.accent + '40',
      bottomColor: C.accent + '00',
      lineWidth: 2,
    });
    
    chartRef.current = chart;
    seriesRef.current = series;

    const handleResize = () => {
      if (chartContainerRef.current) {
        chart.applyOptions({ width: chartContainerRef.current.clientWidth, height: chartContainerRef.current.clientHeight });
      }
    };
    window.addEventListener('resize', handleResize);
    setTimeout(handleResize, 50);
    
    return () => {
      window.removeEventListener('resize', handleResize);
      chart.remove();
    };
  }, [darkMode]);

  useEffect(() => {
    if (seriesRef.current) {
      seriesRef.current.setData([]);
      lastTimeRef.current = 0;
    }
  }, [symbol]);

  useEffect(() => {
    if (seriesRef.current && bid > 0) {
      let time = Math.floor(Date.now() / 1000);
      if (time <= lastTimeRef.current) {
         time = lastTimeRef.current + 1;
      }
      lastTimeRef.current = time;
      seriesRef.current.update({ time: time as any, value: bid });
    }
  }, [bid]);

  return <div ref={chartContainerRef} style={{ width: '100%', height: '100%', flex: 1, minHeight: 0 }} />;
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
  const wsRef = useRef<WebSocket | null>(null);

  /* ── Sync data-theme attribute with darkMode state ── */
  useEffect(() => {
    document.documentElement.setAttribute('data-theme', darkMode ? 'dark' : 'light');
  }, [darkMode]);

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
      } catch { /* */ }
    };
    wsRef.current = ws;
  }, [activeSymbol]);

  useEffect(() => { connectWs(); return () => { wsRef.current?.close(); }; }, [connectWs]);
  const send = (msg: object) => { if (wsRef.current?.readyState === 1) wsRef.current.send(JSON.stringify(msg)); };
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
            <div className="card flex-1 !rounded-2xl !p-5 flex flex-col" style={{ minHeight: 250 }}>
              <div className="text-sm font-bold text-default-900 mb-4 flex justify-between items-center">
                <span>{activeSymbol} Live Data</span>
                <span className={`text-[11px] font-medium flex items-center gap-1.5 ${eaConnected ? 'text-success' : 'text-danger'}`}>
                  <span className={`inline-block size-1.5 rounded-full ${eaConnected ? 'bg-success animate-pulse' : 'bg-danger'}`} />
                  {eaConnected ? 'Live' : 'Offline'}
                </span>
              </div>
              <div className="flex-1 relative">
                <div className="absolute inset-0">
                  <LiveChart symbol={activeSymbol} bid={bid} darkMode={darkMode} />
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
    <div className="fixed inset-0 z-[9999] flex flex-col font-body bg-body-bg text-body-color overflow-hidden border-none">

      {/* ═══ TOP BAR ═══ */}
      <div data-tauri-drag-region className="flex items-center justify-between px-5 w-full shrink-0 bg-card dark:bg-[#151821] border-b border-default-200/60 dark:border-default-300/10" style={{ height: 52 }}>
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
        <div className="flex items-center gap-5">
          <div className="text-right hidden sm:block">
            <div className="text-[10px] text-default-400">Balance</div>
            <div className="text-xs font-bold text-default-900">${balance.toLocaleString('en-US', { minimumFractionDigits: 2 })}</div>
          </div>
          <div className="text-right hidden sm:block">
            <div className="text-[10px] text-default-400">Equity</div>
            <div className={`text-xs font-bold ${profit >= 0 ? 'text-success' : 'text-danger'}`}>${equity.toLocaleString('en-US', { minimumFractionDigits: 2 })}</div>
          </div>
          <div className="size-8 rounded-full shrink-0" style={{ background: 'linear-gradient(135deg, #8b5cf6, #ec4899)' }} />
        </div>
      </div>



      {/* ═══ MAIN AREA ═══ */}
      <div className="flex flex-col lg:flex-row flex-1 overflow-hidden relative">

        {/* ── CONTENT AREA (Chart or Page Panel) ── */}
        <div className="flex flex-col flex-1 overflow-auto h-full pb-16 lg:pb-0">
          {renderPanel()}
        </div>

        {/* ── RIGHT SIDEBAR (Cards) ── */}
        <style>{`.hide-sb::-webkit-scrollbar{display:none}`}</style>
        <div className="hide-sb flex flex-col gap-2 p-2 w-full lg:w-[300px] shrink-0 pb-20 lg:pb-2 overflow-auto" style={{ background: 'transparent' }}>

          {/* Watchlist Card */}
          <div className="card">
            <div className="card-header">
              <h6 className="card-title text-sm">Watchlist</h6>
              <div className="flex gap-1">
                <button className="btn btn-icon rounded-full bg-default-100 dark:bg-default-200/10 text-default-500 hover:bg-default-200 hover:text-default-800 dark:hover:bg-default-300/20" style={{ width: 28, height: 28 }}><LuPlus size={12} /></button>
                <button className="btn btn-icon rounded-full bg-default-100 dark:bg-default-200/10 text-default-500 hover:bg-default-200 hover:text-default-800 dark:hover:bg-default-300/20" style={{ width: 28, height: 28 }}><LuSettings size={12} /></button>
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

        {/* ═══ RIGHT NAV TOOLBAR (Bottom Bar on Mobile) ═══ */}
        <div className="absolute bottom-0 left-0 right-0 h-16 lg:static lg:h-auto lg:w-[72px] shrink-0 flex flex-row lg:flex-col items-center justify-around lg:justify-start lg:pt-3 lg:pb-3 gap-2 lg:gap-3 overflow-x-auto lg:overflow-y-auto bg-card/80 dark:bg-[#151821]/80 backdrop-blur-md lg:bg-transparent lg:dark:bg-transparent border-t border-default-200/60 dark:border-default-300/10 lg:border-t-0 lg:backdrop-blur-none">
          {NAV.map(item => {
            if ('divider' in item) return <div key={item.key} className="hidden lg:block w-8 h-px bg-default-200 dark:bg-default-300/10 my-1 shrink-0" />;
            const active = activePanel === item.key;
            return (
              <button
                key={item.key}
                onClick={() => setActivePanel(item.key)}
                className={`shrink-0 flex items-center justify-center transition-all cursor-pointer border-none rounded-xl ${
                  active 
                    ? 'bg-primary/10 text-primary shadow-sm shadow-primary/10' 
                    : 'bg-card dark:bg-default-200/5 text-default-400 hover:text-default-700 dark:hover:text-default-600 hover:bg-default-100 dark:hover:bg-default-200/10'
                }`}
                style={{ width: 40, height: 40 }}
                title={item.label}
              >
                {item.icon}
              </button>
            );
          })}
          {/* Theme Toggle & Connection */}
          <div className="lg:mt-auto flex flex-row lg:flex-col items-center gap-4 lg:gap-2 px-4 lg:px-0">
            <button
              onClick={() => setDarkMode(!darkMode)}
              className="btn btn-icon shrink-0 bg-default-100 dark:bg-default-200/10 text-default-500 hover:bg-default-200 hover:text-default-800 dark:hover:bg-default-300/20 dark:hover:text-default-800 transition-all border-none"
              style={{ width: 36, height: 36, borderRadius: 12 }}
              title={darkMode ? 'Light Mode' : 'Dark Mode'}
            >
              {darkMode ? <LuSun size={16} /> : <LuMoon size={16} />}
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
              <button onClick={() => setCloseModal({ show: false, ticket: 0, symbol: '' })} className="btn rounded-full flex-1 bg-default-100 dark:bg-default-200/10 text-default-800 dark:text-default-700 hover:bg-default-200 dark:hover:bg-default-300/20 py-2.5 text-sm font-medium border-none">Cancel</button>
              <button onClick={handleCloseTrade} className="btn rounded-full flex-1 bg-danger text-white hover:bg-danger/90 py-2.5 text-sm font-medium border-none">Close Trade</button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default TradingDashboard;
