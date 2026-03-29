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

// (Mock data generation removed - using live Websocket ticks)

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

/* ── Theme Colors ── */
const DARK = {
  bg: '#1e2028', panel: '#262933', topBar: '#1e2028',
  text: '#f1f5f9', textMid: '#cbd5e1', textDim: '#64748b',
  green: '#10b981', red: '#ef4444', accent: '#3b82f6', orange: '#f59e0b',
  chartBg: '#1e2028', gridLine: '#2d3342',
  sellBg: '#ef4444', buyBg: '#10b981',
  navBtnBg: '#262933', navBtnText: '#64748b', navBtnActiveBg: '#3b82f620', navBtnActiveText: '#3b82f6',
};
const LIGHT = {
  bg: '#f8fafc', panel: '#ffffff', topBar: '#f8fafc',
  text: '#0f172a', textMid: '#334155', textDim: '#94a3b8',
  green: '#10b981', red: '#ef4444', accent: '#3b82f6', orange: '#f59e0b',
  chartBg: '#ffffff', gridLine: '#f1f5f9',
  sellBg: '#ef4444', buyBg: '#10b981',
  navBtnBg: '#ffffff', navBtnText: '#94a3b8', navBtnActiveBg: '#3b82f615', navBtnActiveText: '#3b82f6',
};

const LiveChart = ({ symbol, bid, L, darkMode }: { symbol: string, bid: number, L: any, darkMode: boolean }) => {
  const chartContainerRef = useRef<HTMLDivElement>(null);
  const chartRef = useRef<IChartApi | null>(null);
  const seriesRef = useRef<ISeriesApi<"Area"> | null>(null);
  const lastTimeRef = useRef<number>(0);

  useEffect(() => {
    if (!chartContainerRef.current) return;
    const chart = createChart(chartContainerRef.current, {
      layout: { background: { type: ColorType.Solid, color: 'transparent' }, textColor: L.textDim },
      grid: { vertLines: { color: L.gridLine }, horzLines: { color: L.gridLine } },
      rightPriceScale: { borderVisible: false },
      timeScale: { borderVisible: false, timeVisible: true, secondsVisible: true },
      crosshair: { mode: 1 },
    });
    
    const series = chart.addSeries(AreaSeries, {
      lineColor: L.accent,
      topColor: L.accent + '40',
      bottomColor: L.accent + '00',
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
    setTimeout(handleResize, 50); // initial resize
    
    return () => {
      window.removeEventListener('resize', handleResize);
      chart.remove();
    };
  }, [L, darkMode]);

  useEffect(() => {
    if (seriesRef.current) {
      seriesRef.current.setData([]);
      lastTimeRef.current = 0;
    }
  }, [symbol]);

  useEffect(() => {
    if (seriesRef.current && bid > 0) {
      let time = Math.floor(Date.now() / 1000);
      // Ensure time is strictly increasing to prevent TV errors
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
  const L = darkMode ? DARK : LIGHT;
  const wsRef = useRef<WebSocket | null>(null);

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
  // Trade buttons were removed from the top bar in previous step, so handleOpenTrade is unused here for now.
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
        <div style={{ flex: 1, display: 'flex', flexDirection: 'column', overflow: 'auto', padding: 16, gap: 16 }}>
          {/* Account Overview */}
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 12 }}>
            {[
              { label: 'Balance', value: `$${balance.toLocaleString('en-US', { minimumFractionDigits: 2 })}`, color: L.text },
              { label: 'Equity', value: `$${equity.toLocaleString('en-US', { minimumFractionDigits: 2 })}`, color: profit >= 0 ? L.green : L.red },
              { label: 'Profit', value: `${profit >= 0 ? '+' : ''}$${profit.toFixed(2)}`, color: profit >= 0 ? L.green : L.red },
              { label: 'Margin', value: `$${(account?.margin ?? 0).toFixed(2)}`, color: L.textMid },
            ].map(item => (
              <div key={item.label} style={{ background: L.panel, borderRadius: 20, padding: '16px 20px', display: 'flex', flexDirection: 'column', justifyContent: 'center' }}>
                <div style={{ fontSize: 12, color: L.textDim, marginBottom: 4, fontWeight: 500 }}>{item.label}</div>
                <div style={{ fontSize: 20, fontWeight: 700, color: item.color }}>{item.value}</div>
              </div>
            ))}
          </div>

          {/* Chart & Open Positions Split */}
          <div style={{ flex: 1, display: 'flex', flexDirection: 'column', gap: 16, minHeight: 0 }}>
            <div style={{ flex: 1, background: L.panel, borderRadius: 20, padding: '20px 24px', display: 'flex', flexDirection: 'column', minHeight: 250 }}>
              <div style={{ fontSize: 14, fontWeight: 700, color: L.text, marginBottom: 16, display: 'flex', justifyContent: 'space-between' }}>
                <span>{activeSymbol} Live Data</span>
                <span style={{ fontSize: 11, color: L.textDim, fontWeight: 500 }}>{eaConnected ? 'Live Connection' : 'Disconnected'}</span>
              </div>
              <div style={{ flex: 1, position: 'relative' }}>
                <div style={{ position: 'absolute', inset: 0 }}>
                  <LiveChart symbol={activeSymbol} bid={bid} L={L} darkMode={darkMode} />
                </div>
              </div>
            </div>

            <div style={{ background: L.panel, borderRadius: 20, padding: '20px 24px', maxHeight: 220, overflow: 'auto', flexShrink: 0 }}>
              <div style={{ fontSize: 13, fontWeight: 700, color: L.text, marginBottom: 16 }}>Open Positions ({positions.length})</div>
              {positions.length > 0 ? (
                <table style={{ width: '100%', borderCollapse: 'collapse' }}>
                <thead>
                  <tr>
                    {['Symbol', 'Type', 'Volume', 'Open Price', 'Current', 'P&L', 'SL', 'TP', ''].map(h => (
                      <th key={h} style={{ fontSize: 11, color: L.textDim, fontWeight: 600, textAlign: h === '' ? 'right' : 'left', paddingBottom: 12 }}>{h}</th>
                    ))}
                  </tr>
                </thead>
                <tbody>
                  {positions.map((pos, i) => (
                    <tr key={pos.ticket} style={{ background: i % 2 === 0 ? 'transparent' : (darkMode ? '#ffffff05' : '#00000003'), borderRadius: 12 }}>
                      <td style={{ fontSize: 13, fontWeight: 600, color: L.text, padding: '12px 10px', borderRadius: '12px 0 0 12px' }}>{pos.symbol}</td>
                      <td style={{ fontSize: 12, color: pos.type === 'BUY' ? L.green : L.red, fontWeight: 600 }}>{pos.type}</td>
                      <td style={{ fontSize: 12, color: L.textMid, fontWeight: 500 }}>{pos.volume}</td>
                      <td style={{ fontSize: 12, color: L.textMid, fontFamily: 'monospace' }}>{pos.open_price}</td>
                      <td style={{ fontSize: 12, color: L.textMid, fontFamily: 'monospace' }}>{pos.current_price}</td>
                      <td style={{ fontSize: 12, fontWeight: 700, color: pos.pnl >= 0 ? L.green : L.red }}>{pos.pnl >= 0 ? '+' : ''}{pos.pnl.toFixed(2)}</td>
                      <td style={{ fontSize: 11, color: L.textDim, fontWeight: 500 }}>{pos.sl || '—'}</td>
                      <td style={{ fontSize: 11, color: L.textDim, fontWeight: 500 }}>{pos.tp || '—'}</td>
                      <td style={{ textAlign: 'right', paddingRight: 10, borderRadius: '0 12px 12px 0' }}>
                        <button
                          onClick={() => setCloseModal({ show: true, ticket: pos.ticket, symbol: pos.symbol })}
                          style={{ background: L.red + '15', color: L.red, border: 'none', borderRadius: 10, padding: '6px 12px', fontSize: 11, fontWeight: 700, cursor: 'pointer', transition: 'all 0.2s', boxShadow: 'none' }}
                        >Close</button>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            ) : (
              <div style={{ textAlign: 'center', padding: '40px 0', color: L.textDim, fontSize: 13 }}>
                {eaConnected ? 'No open positions' : 'Waiting for MT5 connection...'}
              </div>
            )}
            </div>
          </div>

          {/* Market Watch Grid */}
          <div style={{ background: 'transparent', padding: '0' }}>
            <div style={{ fontSize: 14, fontWeight: 700, color: L.text, marginBottom: 16, paddingLeft: 4 }}>Market Watch</div>
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(170px, 1fr))', gap: 12 }}>
              {marketWatch.map(m => (
                <div
                  key={m.symbol}
                  onClick={() => setActiveSymbol(m.symbol)}
                  style={{
                    background: activeSymbol === m.symbol ? (L.accent + '20') : L.panel,
                    borderRadius: 16, padding: '14px 16px', cursor: 'pointer',
                    transition: 'all 0.2s cubic-bezier(0.4, 0, 0.2, 1)',
                    transform: activeSymbol === m.symbol ? 'scale(1.02)' : 'scale(1)',
                    boxShadow: activeSymbol === m.symbol ? `0 4px 12px ${L.accent}15` : 'none',
                    border: 'none',
                  }}
                >
                  <div style={{ fontSize: 13, fontWeight: 700, color: activeSymbol === m.symbol ? L.accent : L.text }}>{m.symbol}</div>
                  <div style={{ fontSize: 18, fontWeight: 700, color: L.text, marginTop: 4, fontFamily: 'monospace' }}>{m.bid.toFixed(m.digits)}</div>
                  <div style={{ fontSize: 11, color: L.textDim, marginTop: 2, fontWeight: 500 }}>Spread: {m.spread.toFixed(1)}</div>
                </div>
              ))}
              {marketWatch.length === 0 && (
                <div style={{ gridColumn: '1 / -1', textAlign: 'center', padding: '20px 0', color: L.textDim, fontSize: 12 }}>Waiting for market data...</div>
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
    <div style={{ position: 'fixed', inset: 0, zIndex: 9999, display: 'flex', flexDirection: 'column', fontFamily: "'CamingoCode', monospace", background: L.bg, color: L.text, borderRadius: 20, overflow: 'hidden', border: 'none' }}>

      {/* ═══ TOP BAR ═══ */}
      <div data-tauri-drag-region className="flex items-center justify-between px-5" style={{ height: 52, background: L.topBar }}>
        {/* Left: Traffic lights + Logo */}
        <div className="flex items-center gap-4">
          {/* macOS Traffic Light Buttons */}
          <div className="flex items-center" style={{ gap: 8 }}>
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
        <div className="flex items-center gap-2">
          <span className="text-[13px] font-bold text-default-900">{activeSymbol}</span>
          <span className="text-[13px] text-default-300">—</span>
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
        <div className="hide-sb flex flex-col gap-2 p-2 overflow-auto" style={{ width: 300, scrollbarWidth: 'none', background: L.panel }}>

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
        <div style={{ width: 72, borderRadius: 0, display: 'flex', flexDirection: 'column', alignItems: 'center', paddingTop: 12, gap: 8, overflowY: 'auto', background: L.panel }}>
          {NAV.map(item => {
            if ('divider' in item) return <div key={item.key} style={{ width: 32, height: 1, margin: '4px 0' }} />;
            const active = activePanel === item.key;
            return (
              <button
                key={item.key}
                onClick={() => setActivePanel(item.key)}
                style={{
                  width: 44, height: 44, borderRadius: 14,
                  background: active ? L.navBtnActiveBg : L.navBtnBg,
                  color: active ? L.navBtnActiveText : L.navBtnText,
                  border: 'none',
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                  cursor: 'pointer', transition: 'all 0.2s',
                  boxShadow: active ? '0 2px 8px rgba(41,98,255,0.15)' : '0 1px 3px rgba(0,0,0,0.08)',
                }}
                title={item.label}
              >
                {item.icon}
              </button>
            );
          })}
          {/* Theme Toggle */}
          <div className="mt-auto flex flex-col items-center gap-2 pb-3">
            <button
              onClick={() => setDarkMode(!darkMode)}
              className="btn btn-icon bg-default-100 text-default-500 hover:bg-default-200 hover:text-default-800 transition-all"
              style={{ width: 36, height: 36, borderRadius: 12 }}
              title={darkMode ? 'Light Mode' : 'Dark Mode'}
            >
              {darkMode ? <LuSun size={16} /> : <LuMoon size={16} />}
            </button>
            {/* Connection */}
            <div className="flex flex-col items-center gap-1">
              <div className={`size-2 rounded-full ${eaConnected ? 'bg-success' : 'bg-danger'}`} />
              <span className="text-[7px] text-default-400">{eaConnected ? 'ON' : 'OFF'}</span>
            </div>
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
