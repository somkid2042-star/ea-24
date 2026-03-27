import { useState, useEffect, useRef, useCallback } from 'react';
import {
  LuWallet,
  LuActivity,
  LuTrendingUp,
  LuTrendingDown,
  LuChartColumn,
  LuTarget,
  LuClock,
  LuShieldAlert,
  LuWifi,
  LuWifiOff,
  LuInfo,
  LuPercent,
  LuPlus,
  LuX,
  LuChevronDown,
} from 'react-icons/lu';

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

type AccountData = {
  balance: number;
  equity: number;
  profit: number;
  margin: number;
  free_margin: number;
  currency: string;
  positions: Position[];
  positions_count: number;
  trading_enabled: boolean;
};

type MarketWatchSymbol = { symbol: string; bid: number; ask: number; spread: number; digits: number; };
type TradeResult = { action: string; success: boolean; symbol?: string; direction?: string; lot?: number; ticket?: number; error?: string; };

const WS_HOST = import.meta.env.VITE_WS_HOST || window.location.hostname;
const WS_URL = `ws://${WS_HOST}:8080`;

const TradingDashboard = () => {
  const [wsConnected, setWsConnected] = useState(false);
  const [eaConnected, setEaConnected] = useState(false);
  const [account, setAccount] = useState<AccountData | null>(null);
  const [lastTick, setLastTick] = useState<{ symbol: string; bid: number; ask: number; spread: number } | null>(null);
  const [pnlHistory, setPnlHistory] = useState<number[]>([]);
  const [showRiskInfo, setShowRiskInfo] = useState(false);
  const [marketWatch, setMarketWatch] = useState<MarketWatchSymbol[]>([]);
  // Open Trade Dialog state
  const [showOpenTrade, setShowOpenTrade] = useState(false);
  const [tradeSymbol, setTradeSymbol] = useState('');
  const [tradeDir, setTradeDir] = useState<'BUY' | 'SELL'>('BUY');
  const [tradeLot, setTradeLot] = useState(0.01);
  const [tradeSL, setTradeSL] = useState(0);
  const [tradeTP, setTradeTP] = useState(0);
  // Close confirmation
  const [closeModal, setCloseModal] = useState<{ show: boolean; ticket: number; symbol: string }>({ show: false, ticket: 0, symbol: '' });
  // Trade result toast
  const [toast, setToast] = useState<TradeResult | null>(null);
  const wsRef = useRef<WebSocket | null>(null);

  const connectWs = useCallback(() => {
    const ws = new WebSocket(WS_URL);
    ws.onopen = () => setWsConnected(true);
    ws.onclose = () => { setWsConnected(false); setEaConnected(false); setTimeout(connectWs, 3000); };
    ws.onmessage = (evt) => {
      try {
        const data = JSON.parse(evt.data);
        if (data.type === 'welcome' || data.type === 'ea_info') setEaConnected(data.ea_connected ?? true);
        if (data.type === 'account_data') {
          setAccount(data as AccountData);
          setEaConnected(true);
          setPnlHistory(prev => { const next = [...prev, data.profit as number]; return next.length > 30 ? next.slice(-30) : next; });
        }
        if (data.type === 'tick') setLastTick({ symbol: data.symbol, bid: data.bid, ask: data.ask, spread: data.spread });
        if (data.type === 'market_watch') {
          setMarketWatch(data.symbols || []);
          if (data.symbols?.length > 0 && !tradeSymbol) setTradeSymbol(data.symbols[0].symbol);
        }
        if (data.type === 'trade_result') {
          setToast(data as TradeResult);
          setTimeout(() => setToast(null), 5000);
        }
      } catch { /* */ }
    };
    wsRef.current = ws;
  }, []);

  useEffect(() => { connectWs(); return () => { wsRef.current?.close(); }; }, [connectWs]);

  const send = (msg: object) => { if (wsRef.current?.readyState === 1) wsRef.current.send(JSON.stringify(msg)); };

  const handleOpenTrade = () => {
    send({ action: 'open_trade', symbol: tradeSymbol, direction: tradeDir, lot_size: tradeLot, sl: tradeSL, tp: tradeTP, comment: 'EA-Web' });
    setShowOpenTrade(false);
  };

  const handleCloseTrade = () => {
    send({ action: 'close_trade', ticket: closeModal.ticket });
    setCloseModal({ show: false, ticket: 0, symbol: '' });
  };

  // Computed
  const balance = account?.balance ?? 0;
  const equity = account?.equity ?? 0;
  const profit = account?.profit ?? 0;
  const margin = account?.margin ?? 0;
  const freeMargin = account?.free_margin ?? 0;
  const positions = account?.positions ?? [];
  const activeTrades = positions.length;
  const totalPnl = positions.reduce((sum, p) => sum + p.pnl, 0);
  const totalSwap = positions.reduce((sum, p) => sum + p.swap, 0);
  const winCount = positions.filter(p => p.pnl >= 0).length;
  const lossCount = activeTrades - winCount;
  const winRate = activeTrades > 0 ? (winCount / activeTrades * 100) : 0;
  const maxDrawdown = balance > 0 ? Math.abs(Math.min(0, profit)) / balance * 100 : 0;
  const totalRiskUsd = positions.reduce((sum, p) => sum + (p.pnl < 0 ? Math.abs(p.pnl) : 0), 0);
  const riskPercent = balance > 0 ? (totalRiskUsd / balance * 100) : 0;
  const marginLevel = margin > 0 ? (equity / margin * 100) : 0;
  const totalLots = positions.reduce((sum, p) => sum + p.volume, 0);

  const selectCls = "w-full rounded-md border border-default-200 bg-white dark:bg-gray-800 px-2 py-1.5 text-xs text-black dark:text-white focus:border-primary focus:outline-none";
  const inputCls = "w-full rounded-md border border-default-200 bg-transparent px-2 py-1.5 text-xs focus:border-primary focus:outline-none dark:text-white";

  return (
    <main className="space-y-5">
      {/* Toast Notification */}
      {toast && (
        <div className={`fixed top-4 right-4 z-50 min-w-[300px] rounded-xl border p-4 shadow-2xl backdrop-blur-sm transition-all animate-in slide-in-from-right ${toast.success ? 'border-green-200 bg-green-50/95 dark:border-green-500/30 dark:bg-green-900/90' : 'border-red-200 bg-red-50/95 dark:border-red-500/30 dark:bg-red-900/90'}`}>
          <div className="flex items-center gap-3">
            <div className={`rounded-full p-1.5 ${toast.success ? 'bg-green-500' : 'bg-red-500'}`}>
              {toast.success ? <LuTrendingUp className="size-4 text-white" /> : <LuX className="size-4 text-white" />}
            </div>
            <div className="flex-1">
              <p className={`text-sm font-semibold ${toast.success ? 'text-green-800 dark:text-green-200' : 'text-red-800 dark:text-red-200'}`}>
                {toast.action === 'open' ? (toast.success ? 'Trade Opened!' : 'Open Failed') : (toast.success ? 'Trade Closed!' : 'Close Failed')}
              </p>
              <p className="text-xs text-default-500">
                {toast.symbol && `${toast.symbol} `}{toast.direction && `${toast.direction} `}{toast.lot && `${toast.lot} lot`}
                {toast.error && <span className="text-red-500"> — {toast.error}</span>}
              </p>
            </div>
            <button onClick={() => setToast(null)} className="text-default-400 hover:text-default-600"><LuX className="size-4" /></button>
          </div>
        </div>
      )}

      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h4 className="text-lg font-semibold text-default-900">Active Trading</h4>
          <p className="mt-1 text-sm text-default-500">{eaConnected ? '🟢 Real-time data from MT5' : '⏳ Waiting for MT5...'}</p>
        </div>
        <div className="flex items-center gap-2">
          <span className={`inline-flex items-center gap-1.5 rounded-full px-3 py-1 text-xs font-medium ${wsConnected && eaConnected ? 'bg-green-100 text-green-700 dark:bg-green-500/20 dark:text-green-400' : wsConnected ? 'bg-yellow-100 text-yellow-700 dark:bg-yellow-500/20 dark:text-yellow-400' : 'bg-red-100 text-red-700 dark:bg-red-500/20 dark:text-red-400'}`}>
            {wsConnected ? <LuWifi className="size-3.5" /> : <LuWifiOff className="size-3.5" />}
            {wsConnected && eaConnected ? ' Live' : wsConnected ? ' Server Only' : ' Offline'}
          </span>
          {lastTick && <span className="rounded-full bg-default-100 dark:bg-default-50 px-3 py-1 text-xs text-default-600">{lastTick.symbol} {lastTick.bid.toFixed(lastTick.bid > 100 ? 2 : 5)}</span>}
          <button onClick={() => { setShowOpenTrade(true); if (marketWatch.length > 0 && !tradeSymbol) setTradeSymbol(marketWatch[0].symbol); }} disabled={!eaConnected} className="inline-flex items-center gap-1.5 rounded-md bg-primary px-3 py-2 text-xs font-medium text-white hover:bg-primary/90 disabled:opacity-40">
            <LuPlus className="size-3.5" /> Open Trade
          </button>
        </div>
      </div>

      {/* Open Trade Dialog */}
      {showOpenTrade && (
        <div className="rounded-xl border border-primary/20 bg-primary/5 dark:bg-primary/10 p-5 space-y-4">
          <div className="flex items-center justify-between">
            <h5 className="text-sm font-semibold text-default-900">📈 Open New Trade</h5>
            <button onClick={() => setShowOpenTrade(false)} className="text-default-400 hover:text-default-600"><LuX className="size-4" /></button>
          </div>

          {/* BUY / SELL Selector */}
          <div className="grid grid-cols-2 gap-2">
            <button onClick={() => setTradeDir('BUY')} className={`rounded-lg py-3 text-sm font-bold transition ${tradeDir === 'BUY' ? 'bg-green-500 text-white shadow-lg shadow-green-500/30' : 'border border-green-200 dark:border-green-500/30 text-green-600 dark:text-green-400 hover:bg-green-50 dark:hover:bg-green-500/10'}`}>
              ▲ BUY
            </button>
            <button onClick={() => setTradeDir('SELL')} className={`rounded-lg py-3 text-sm font-bold transition ${tradeDir === 'SELL' ? 'bg-red-500 text-white shadow-lg shadow-red-500/30' : 'border border-red-200 dark:border-red-500/30 text-red-600 dark:text-red-400 hover:bg-red-50 dark:hover:bg-red-500/10'}`}>
              ▼ SELL
            </button>
          </div>

          <div className="grid grid-cols-2 gap-3 md:grid-cols-4">
            <div>
              <label className="mb-1 block text-xs text-default-500">Symbol</label>
              {marketWatch.length > 0 ? (
                <select value={tradeSymbol} onChange={e => setTradeSymbol(e.target.value)} className={selectCls}>
                  {marketWatch.map(m => <option key={m.symbol} value={m.symbol}>{m.symbol} ({m.spread.toFixed(1)} sp)</option>)}
                </select>
              ) : <input value={tradeSymbol} onChange={e => setTradeSymbol(e.target.value)} className={inputCls} placeholder="XAUUSD" />}
            </div>
            <div>
              <label className="mb-1 block text-xs text-default-500">Lot Size</label>
              <input type="number" step="0.01" min="0.01" value={tradeLot} onChange={e => setTradeLot(Number(e.target.value))} className={inputCls} />
            </div>
            <div>
              <label className="mb-1 block text-xs text-default-500">Stop Loss (price, 0 = none)</label>
              <input type="number" step="0.01" min="0" value={tradeSL} onChange={e => setTradeSL(Number(e.target.value))} className={inputCls} />
            </div>
            <div>
              <label className="mb-1 block text-xs text-default-500">Take Profit (price, 0 = none)</label>
              <input type="number" step="0.01" min="0" value={tradeTP} onChange={e => setTradeTP(Number(e.target.value))} className={inputCls} />
            </div>
          </div>

          {/* Live price info */}
          {tradeSymbol && (() => {
            const sym = marketWatch.find(m => m.symbol === tradeSymbol);
            return sym ? (
              <div className="flex items-center gap-4 rounded-lg bg-default-50 dark:bg-default-100/50 p-3">
                <div className="text-center"><p className="text-[10px] text-default-400">BID</p><p className="text-sm font-bold text-red-500">{sym.bid.toFixed(sym.digits)}</p></div>
                <div className="text-center"><p className="text-[10px] text-default-400">Spread</p><p className="text-xs font-semibold text-default-600">{sym.spread.toFixed(1)}</p></div>
                <div className="text-center"><p className="text-[10px] text-default-400">ASK</p><p className="text-sm font-bold text-green-500">{sym.ask.toFixed(sym.digits)}</p></div>
              </div>
            ) : null;
          })()}

          <div className="flex gap-2">
            <button onClick={handleOpenTrade} disabled={!tradeSymbol} className={`rounded-md px-6 py-2.5 text-xs font-bold text-white transition ${tradeDir === 'BUY' ? 'bg-green-500 hover:bg-green-600' : 'bg-red-500 hover:bg-red-600'} disabled:opacity-40`}>
              {tradeDir} {tradeSymbol} ({tradeLot} lot)
            </button>
            <button onClick={() => setShowOpenTrade(false)} className="rounded-md border border-default-200 px-4 py-2 text-xs font-medium text-default-600 hover:bg-default-100">Cancel</button>
          </div>
        </div>
      )}

      {/* Account Summary Cards */}
      <div className="grid grid-cols-2 gap-4 lg:grid-cols-5">
        <div className="group rounded-xl border border-default-200 bg-white dark:bg-default-50 p-5 transition hover:shadow-md">
          <div className="mb-3 flex items-center justify-between"><span className="text-xs font-medium uppercase tracking-wider text-default-400">Balance</span><div className="rounded-lg bg-blue-50 dark:bg-blue-500/20 p-2 text-blue-500"><LuWallet className="size-4" /></div></div>
          <p className="text-2xl font-bold text-default-900">${balance.toLocaleString('en-US', { minimumFractionDigits: 2 })}</p>
          <p className="mt-1 text-xs text-default-500">{account?.currency || 'USD'} account</p>
        </div>
        <div className="group rounded-xl border border-default-200 bg-white dark:bg-default-50 p-5 transition hover:shadow-md">
          <div className="mb-3 flex items-center justify-between"><span className="text-xs font-medium uppercase tracking-wider text-default-400">Equity</span><div className="rounded-lg bg-violet-50 dark:bg-violet-500/20 p-2 text-violet-500"><LuActivity className="size-4" /></div></div>
          <p className="text-2xl font-bold text-default-900">${equity.toLocaleString('en-US', { minimumFractionDigits: 2 })}</p>
          <p className="mt-1 text-xs text-default-500">Balance ± floating P&L</p>
        </div>
        <div className="group rounded-xl border border-default-200 bg-white dark:bg-default-50 p-5 transition hover:shadow-md">
          <div className="mb-3 flex items-center justify-between"><span className="text-xs font-medium uppercase tracking-wider text-default-400">Open P&L</span><div className={`rounded-lg p-2 ${profit >= 0 ? 'bg-green-50 dark:bg-green-500/20 text-green-500' : 'bg-red-50 dark:bg-red-500/20 text-red-500'}`}>{profit >= 0 ? <LuTrendingUp className="size-4" /> : <LuTrendingDown className="size-4" />}</div></div>
          <p className={`text-2xl font-bold ${profit >= 0 ? 'text-green-600' : 'text-red-600'}`}>{profit >= 0 ? '+' : ''}${profit.toFixed(2)}</p>
          <p className="mt-1 text-xs text-default-500">{balance > 0 ? `${profit >= 0 ? '+' : ''}${((profit / balance) * 100).toFixed(2)}% return` : '—'}</p>
        </div>
        <div className="group rounded-xl border border-default-200 bg-white dark:bg-default-50 p-5 transition hover:shadow-md">
          <div className="mb-3 flex items-center justify-between"><span className="text-xs font-medium uppercase tracking-wider text-default-400">Active Trades</span><div className="rounded-lg bg-amber-50 dark:bg-amber-500/20 p-2 text-amber-500"><LuChartColumn className="size-4" /></div></div>
          <p className="text-2xl font-bold text-default-900">{activeTrades}</p>
          <p className="mt-1 text-xs text-default-500">{totalLots > 0 ? `${totalLots.toFixed(2)} lots total` : 'No open positions'}</p>
        </div>
        <div className="group relative rounded-xl border border-default-200 bg-white dark:bg-default-50 p-5 transition hover:shadow-md">
          <div className="mb-3 flex items-center justify-between"><span className="text-xs font-medium uppercase tracking-wider text-default-400">Risk %</span><button onClick={() => setShowRiskInfo(!showRiskInfo)} className="rounded-lg bg-orange-50 dark:bg-orange-500/20 p-2 text-orange-500 hover:bg-orange-100 dark:hover:bg-orange-500/30 transition">{showRiskInfo ? <LuInfo className="size-4" /> : <LuPercent className="size-4" />}</button></div>
          <p className={`text-2xl font-bold ${riskPercent > 5 ? 'text-red-600' : riskPercent > 2 ? 'text-yellow-600' : 'text-green-600'}`}>{riskPercent.toFixed(2)}%</p>
          <p className="mt-1 text-xs text-default-500">${totalRiskUsd.toFixed(2)} at risk</p>
          <div className="mt-2 h-1.5 w-full rounded-full bg-default-100 overflow-hidden"><div className={`h-full rounded-full transition-all ${riskPercent > 5 ? 'bg-red-500' : riskPercent > 2 ? 'bg-yellow-500' : 'bg-green-500'}`} style={{ width: `${Math.min(riskPercent * 10, 100)}%` }} /></div>
        </div>
      </div>

      {/* Risk Info */}
      {showRiskInfo && (
        <div className="rounded-xl border border-orange-200 dark:border-orange-500/30 bg-orange-50/50 dark:bg-orange-500/5 p-5">
          <div className="flex items-start gap-3">
            <div className="mt-0.5 rounded-lg bg-orange-100 dark:bg-orange-500/20 p-2"><LuInfo className="size-4 text-orange-500" /></div>
            <div className="flex-1">
              <h5 className="text-sm font-semibold text-default-900 mb-2">Risk % คืออะไร?</h5>
              <div className="space-y-2 text-xs text-default-600 dark:text-default-400">
                <p><strong>Risk %</strong> = (ยอดขาดทุนรวมที่เปิดอยู่ / ยอดบาลานซ์) × 100</p>
                <p>เป็นตัวบอกว่า <strong>ตอนนี้คุณเสี่ยงเงินกี่ % ของบัญชี</strong> จากสถานะที่เปิดอยู่ทั้งหมดที่กำลังขาดทุน</p>
                <div className="grid grid-cols-3 gap-2 mt-3">
                  <div className="rounded-lg bg-green-50 dark:bg-green-500/10 p-2 text-center"><p className="text-green-600 dark:text-green-400 font-bold">0-2%</p><p className="text-[10px] text-default-500">ความเสี่ยงต่ำ ✅</p></div>
                  <div className="rounded-lg bg-yellow-50 dark:bg-yellow-500/10 p-2 text-center"><p className="text-yellow-600 dark:text-yellow-400 font-bold">2-5%</p><p className="text-[10px] text-default-500">ปานกลาง ⚠️</p></div>
                  <div className="rounded-lg bg-red-50 dark:bg-red-500/10 p-2 text-center"><p className="text-red-600 dark:text-red-400 font-bold">&gt;5%</p><p className="text-[10px] text-default-500">ความเสี่ยงสูง 🔴</p></div>
                </div>
                <p className="mt-2 text-default-500"><strong>ตัวอย่าง:</strong> บาลานซ์ $10,000 / Risk 2% = ยอมขาดทุนได้สูงสุด $200 ต่อเทรด</p>
              </div>
            </div>
            <button onClick={() => setShowRiskInfo(false)} className="text-default-400 hover:text-default-600 text-lg leading-none">×</button>
          </div>
        </div>
      )}

      {/* P&L Chart + Quick Stats */}
      <div className="grid grid-cols-1 gap-5 lg:grid-cols-3">
        <div className="lg:col-span-2 rounded-xl border border-default-200 bg-white dark:bg-default-50 p-5">
          <div className="mb-4 flex items-center justify-between">
            <h5 className="text-sm font-semibold text-default-900">Profit & Loss</h5>
            <span className={`text-sm font-bold ${profit >= 0 ? 'text-green-600' : 'text-red-600'}`}>{profit >= 0 ? '+' : ''}${profit.toFixed(2)} total</span>
          </div>
          <div className="flex items-end gap-0.5" style={{ height: 200 }}>
            {(pnlHistory.length > 0 ? pnlHistory : [0]).map((val, i) => {
              const maxVal = Math.max(1, ...pnlHistory.map(Math.abs));
              const height = Math.max(4, Math.abs(val) / maxVal * 180);
              return (<div key={i} className="flex-1 flex flex-col justify-end"><div className={`w-full rounded-t transition-all ${val >= 0 ? 'bg-green-500' : 'bg-red-400'}`} style={{ height }} title={`$${val.toFixed(2)}`} /></div>);
            })}
          </div>
          {pnlHistory.length === 0 && <p className="text-center text-sm text-default-400 mt-4">{eaConnected ? 'Collecting data...' : 'Connect MT5 to see live P&L chart'}</p>}
        </div>
        <div className="rounded-xl border border-default-200 bg-white dark:bg-default-50 p-5">
          <h5 className="mb-4 text-sm font-semibold text-default-900">Quick Stats</h5>
          <div className="space-y-4">
            <div className="flex items-center gap-3"><div className="rounded-lg bg-green-50 dark:bg-green-500/20 p-2.5"><LuTarget className="size-4 text-green-500" /></div><div className="flex-1"><p className="text-xs text-default-500">Win / Loss</p><p className="text-lg font-bold text-default-900">{winCount} / {lossCount}</p></div><div className="text-right"><p className="text-xs text-default-400">Win Rate</p><p className={`text-sm font-bold ${winRate >= 50 ? 'text-green-600' : 'text-red-600'}`}>{winRate.toFixed(0)}%</p></div></div>
            <div className="flex items-center gap-3"><div className="rounded-lg bg-blue-50 dark:bg-blue-500/20 p-2.5"><LuChartColumn className="size-4 text-blue-500" /></div><div className="flex-1"><p className="text-xs text-default-500">Margin Level</p><p className={`text-lg font-bold ${marginLevel > 500 ? 'text-green-600' : marginLevel > 200 ? 'text-yellow-600' : marginLevel > 0 ? 'text-red-600' : 'text-default-900'}`}>{marginLevel > 0 ? `${marginLevel.toFixed(0)}%` : '—'}</p></div></div>
            <div className="flex items-center gap-3"><div className="rounded-lg bg-violet-50 dark:bg-violet-500/20 p-2.5"><LuClock className="size-4 text-violet-500" /></div><div className="flex-1"><p className="text-xs text-default-500">Total Swap</p><p className={`text-lg font-bold ${totalSwap >= 0 ? 'text-green-600' : 'text-red-600'}`}>{totalSwap >= 0 ? '+' : ''}${totalSwap.toFixed(2)}</p></div></div>
            <div className="flex items-center gap-3"><div className="rounded-lg bg-red-50 dark:bg-red-500/20 p-2.5"><LuShieldAlert className="size-4 text-red-500" /></div><div className="flex-1"><p className="text-xs text-default-500">Drawdown</p><p className="text-lg font-bold text-red-600">-{maxDrawdown.toFixed(1)}%</p></div><div className="h-2 w-20 rounded-full bg-default-100 overflow-hidden"><div className="h-full rounded-full bg-red-400" style={{ width: `${Math.min(maxDrawdown, 100)}%` }} /></div></div>
          </div>
        </div>
      </div>

      {/* Active Positions Table */}
      <div className="rounded-xl border border-default-200 bg-white dark:bg-default-50 overflow-hidden">
        <div className="px-5 py-4 border-b border-default-200 flex items-center justify-between">
          <h5 className="text-sm font-semibold text-default-900">Active Positions</h5>
          <div className="flex items-center gap-3">
            {activeTrades > 0 && <span className={`text-xs font-bold ${totalPnl >= 0 ? 'text-green-600' : 'text-red-600'}`}>Total: {totalPnl >= 0 ? '+' : ''}${totalPnl.toFixed(2)}</span>}
            <span className="text-xs text-default-500">{activeTrades} open trade{activeTrades !== 1 ? 's' : ''}</span>
          </div>
        </div>
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
                <th className="px-4 py-3">Risk%</th>
                <th className="px-4 py-3">Swap</th>
                <th className="px-4 py-3">Time</th>
                <th className="px-4 py-3 text-center">Action</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-default-200">
              {positions.length > 0 ? positions.map(pos => {
                const posRisk = balance > 0 && pos.pnl < 0 ? (Math.abs(pos.pnl) / balance * 100) : 0;
                return (
                <tr key={pos.ticket} className="hover:bg-default-50/50 dark:hover:bg-default-100/30 transition">
                  <td className="px-4 py-3 font-semibold text-primary">{pos.symbol}</td>
                  <td className="px-4 py-3"><span className={`rounded px-2 py-0.5 text-[10px] font-bold text-white ${pos.type === 'BUY' ? 'bg-green-500' : 'bg-red-500'}`}>{pos.type}</span></td>
                  <td className="px-4 py-3 tabular-nums">{pos.volume.toFixed(2)}</td>
                  <td className="px-4 py-3 tabular-nums">{pos.open_price}</td>
                  <td className="px-4 py-3 tabular-nums font-medium">{pos.current_price}</td>
                  <td className="px-4 py-3 tabular-nums text-red-500">{pos.sl > 0 ? pos.sl : '—'}</td>
                  <td className="px-4 py-3 tabular-nums text-green-500">{pos.tp > 0 ? pos.tp : '—'}</td>
                  <td className={`px-4 py-3 tabular-nums font-bold ${pos.pnl >= 0 ? 'text-green-600' : 'text-red-600'}`}>{pos.pnl >= 0 ? '+' : ''}${pos.pnl.toFixed(2)}</td>
                  <td className="px-4 py-3 tabular-nums">{posRisk > 0 ? <span className={`text-xs font-semibold ${posRisk > 2 ? 'text-red-600' : posRisk > 1 ? 'text-yellow-600' : 'text-default-500'}`}>{posRisk.toFixed(2)}%</span> : <span className="text-xs text-green-600">—</span>}</td>
                  <td className="px-4 py-3 tabular-nums text-default-500">${pos.swap.toFixed(2)}</td>
                  <td className="px-4 py-3 text-xs text-default-500">{pos.open_time}</td>
                  <td className="px-4 py-3 text-center">
                    <button onClick={() => setCloseModal({ show: true, ticket: pos.ticket, symbol: pos.symbol })} className="rounded-md bg-red-500 px-3 py-1 text-[10px] font-bold text-white hover:bg-red-600 transition">
                      Close
                    </button>
                  </td>
                </tr>
                );
              }) : (
                <tr><td colSpan={12} className="px-5 py-8 text-center text-default-400">{eaConnected ? 'No open positions' : 'Connect MT5 to see live positions'}</td></tr>
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* Account Footer */}
      {account && (
        <div className="grid grid-cols-2 gap-4 md:grid-cols-5">
          {[
            { label: 'Free Margin', value: `$${freeMargin.toFixed(2)}`, color: freeMargin > 0 ? 'text-default-900' : 'text-red-600' },
            { label: 'Margin Used', value: `$${margin.toFixed(2)}`, color: 'text-default-900' },
            { label: 'Margin Level', value: marginLevel > 0 ? `${marginLevel.toFixed(0)}%` : '—', color: marginLevel > 500 ? 'text-green-600' : marginLevel > 200 ? 'text-yellow-600' : 'text-red-600' },
            { label: 'Currency', value: account.currency, color: 'text-default-900' },
            { label: 'Trading', value: account.trading_enabled ? '✅ Enabled' : '🔴 Disabled', color: 'text-default-900' },
          ].map(item => (
            <div key={item.label} className="rounded-xl border border-default-200 bg-white dark:bg-default-50 p-4">
              <p className="text-xs font-medium uppercase text-default-400">{item.label}</p>
              <p className={`mt-1 text-sm font-bold ${item.color}`}>{item.value}</p>
            </div>
          ))}
        </div>
      )}

      {/* Close Confirmation Modal */}
      {closeModal.show && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 backdrop-blur-sm" onClick={() => setCloseModal({ show: false, ticket: 0, symbol: '' })}>
          <div className="mx-4 w-full max-w-sm rounded-2xl bg-white dark:bg-gray-900 p-6 shadow-2xl" onClick={e => e.stopPropagation()}>
            <div className="mb-4 flex size-12 items-center justify-center rounded-full bg-red-100 dark:bg-red-500/20 mx-auto"><LuChevronDown className="size-6 text-red-600 dark:text-red-400" /></div>
            <h3 className="mb-2 text-center text-base font-semibold text-default-900">Close Position?</h3>
            <p className="mb-6 text-center text-sm text-default-500">Close <span className="font-semibold text-primary">{closeModal.symbol}</span> #{closeModal.ticket} at market price?</p>
            <div className="flex gap-3">
              <button onClick={() => setCloseModal({ show: false, ticket: 0, symbol: '' })} className="flex-1 rounded-lg border border-default-200 px-4 py-2.5 text-sm font-medium text-default-700 hover:bg-default-50 dark:text-default-300 dark:hover:bg-default-100">Cancel</button>
              <button onClick={handleCloseTrade} className="flex-1 rounded-lg bg-red-600 px-4 py-2.5 text-sm font-medium text-white hover:bg-red-700">Close Trade</button>
            </div>
          </div>
        </div>
      )}
    </main>
  );
};

export default TradingDashboard;
