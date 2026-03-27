import { useState, useEffect, useRef, useCallback } from 'react';
import { TbX } from 'react-icons/tb';
import { LuCheck, LuTrendingUp, LuTrendingDown } from 'react-icons/lu';
import SimplebarClient from '@/components/client-wrapper/SimplebarClient';

type TradeSetupItem = {
  id: number; symbol: string; strategy: string; timeframe: string; lotSize: number;
  tpEnabled: boolean; tpMode: string; tpValue: number;
  slEnabled: boolean; slMode: string; slValue: number;
  trailingStopEnabled: boolean; trailingStopPoints: number;
  status: string;
};
type Deal = {
  ticket: number; symbol: string; type: string; volume: number; price: number;
  profit: number; swap: number; commission: number; time: string;
};
import { getWsUrl } from '@/utils/config';

type Position = {
  ticket: number; symbol: string; type: string; volume: number;
  open_price: number; current_price: number; pnl: number; swap: number;
  sl: number; tp: number; open_time: string;
};

const WS_URL = getWsUrl();

const Customizer = () => {
  const [isOpen, setIsOpen] = useState(false);
  const [setups, setSetups] = useState<TradeSetupItem[]>([]);
  const [selectedSetup, setSelectedSetup] = useState<number | null>(null);
  const [deals, setDeals] = useState<Deal[]>([]);
  const [positions, setPositions] = useState<Position[]>([]);
  const wsRef = useRef<WebSocket | null>(null);

  if (typeof window !== 'undefined') {
    window.__openCustomizer = () => setIsOpen(true);
  }

  const connectWs = useCallback(() => {
    if (wsRef.current && wsRef.current.readyState <= 1) return;
    const ws = new WebSocket(WS_URL);
    ws.onopen = () => { ws.send(JSON.stringify({ action: 'get_trade_setups' })); };
    ws.onclose = () => { setTimeout(() => { if (isOpen) connectWs(); }, 3000); };
    ws.onmessage = (evt) => {
      try {
        const data = JSON.parse(evt.data);
        if (data.type === 'trade_setups') setSetups(data.setups || []);
        if (data.type === 'trade_history') setDeals(data.deals || []);
        if (data.type === 'account_data') setPositions(data.positions || []);
      } catch { /* */ }
    };
    wsRef.current = ws;
  }, [isOpen]);

  useEffect(() => {
    if (isOpen) connectWs();
    return () => { if (!isOpen && wsRef.current) { wsRef.current.close(); wsRef.current = null; } };
  }, [isOpen, connectWs]);

  const selectedData = setups.find(s => s.id === selectedSetup);
  const modeUnit = (m: string) => m === 'rr' ? 'R' : m === 'pips' ? 'pips' : '$';
  const totalPnl = positions.reduce((s, p) => s + p.pnl, 0);

  return (
    <>
      {isOpen && (
        <div className="fixed inset-0 bg-black/50 z-[79] transition-opacity" onClick={() => setIsOpen(false)} />
      )}

      <div
        id="theme-customization"
        className={`fixed inset-y-0 end-0 bottom-0 flex flex-col max-w-sm w-full z-80 overflow-hidden bg-card dark:bg-default-100 transition-transform duration-300 ${isOpen ? 'translate-x-0' : 'translate-x-full rtl:-translate-x-full'}`}
      >
        <div className="min-h-16 flex items-center text-default-600 border-b border-dashed border-default-900/10 px-6 gap-3">
          <h5 className="text-base grow">Settings</h5>
          <button type="button" onClick={() => setIsOpen(false)} className="btn size-9 rounded-full btn-sm hover:bg-default-150">
            <TbX className="text-xl" />
          </button>
        </div>

        <SimplebarClient className="h-full flex-grow overflow-y-auto">
          <div className="divide-y divide-dashed divide-default-200">

            {/* Trade Setups Section */}
            <div className="p-6">
              <h5 className="text-sm font-semibold text-default-800 mb-4">Trade Setup</h5>
              {setups.length > 0 ? (
                <div className="grid grid-cols-2 gap-2">
                  {setups.map(s => (
                    <button key={s.id} onClick={() => setSelectedSetup(selectedSetup === s.id ? null : s.id)}
                      className={`relative rounded-lg border-2 p-3 text-left transition-all hover:shadow-sm ${selectedSetup === s.id ? 'border-primary bg-primary/5 dark:bg-primary/10 shadow-md' : 'border-default-200 hover:border-default-300'}`}>
                      {selectedSetup === s.id && (
                        <div className="absolute top-1.5 right-1.5 size-5 rounded-full bg-green-500 flex items-center justify-center">
                          <LuCheck className="size-3 text-white" />
                        </div>
                      )}
                      <p className="text-xs font-bold text-primary truncate">{s.symbol}</p>
                      <p className="text-[10px] text-default-500 mt-0.5">{s.strategy}</p>
                      <p className="text-[10px] text-default-400">{s.timeframe} · {s.lotSize} lot</p>
                      <div className="flex gap-1 mt-1.5 flex-wrap">
                        {s.tpEnabled && <span className="rounded bg-green-100 dark:bg-green-500/20 px-1 text-[8px] font-medium text-green-600 dark:text-green-400">TP</span>}
                        {s.slEnabled && <span className="rounded bg-red-100 dark:bg-red-500/20 px-1 text-[8px] font-medium text-red-600 dark:text-red-400">SL</span>}
                        {s.trailingStopEnabled && <span className="rounded bg-blue-100 dark:bg-blue-500/20 px-1 text-[8px] font-medium text-blue-600 dark:text-blue-400">TS</span>}
                        <span className={`rounded px-1 text-[8px] font-medium ${s.status === 'active' ? 'bg-green-100 dark:bg-green-500/20 text-green-600 dark:text-green-400' : 'bg-yellow-100 dark:bg-yellow-500/20 text-yellow-600 dark:text-yellow-400'}`}>
                          {s.status === 'active' ? '●' : '⏸'}
                        </span>
                      </div>
                    </button>
                  ))}
                </div>
              ) : (
                <p className="text-xs text-default-400">No trade setups configured</p>
              )}

              {/* Selected Setup Details */}
              {selectedData && (
                <div className="mt-4 rounded-lg border border-primary/20 bg-primary/5 dark:bg-primary/10 p-3">
                  <h6 className="text-xs font-semibold text-primary mb-2">{selectedData.symbol} — {selectedData.strategy}</h6>
                  <div className="grid grid-cols-2 gap-1 text-[10px]">
                    <span className="text-default-500">Timeframe:</span><span className="font-medium text-default-800">{selectedData.timeframe}</span>
                    <span className="text-default-500">Lot Size:</span><span className="font-medium text-default-800">{selectedData.lotSize}</span>
                    {selectedData.tpEnabled && (<><span className="text-default-500">Take Profit:</span><span className="font-medium text-green-600">{selectedData.tpValue} {modeUnit(selectedData.tpMode)}</span></>)}
                    {selectedData.slEnabled && (<><span className="text-default-500">Stop Loss:</span><span className="font-medium text-red-600">{selectedData.slValue} {modeUnit(selectedData.slMode)}</span></>)}
                    {selectedData.trailingStopEnabled && (<><span className="text-default-500">Trailing Stop:</span><span className="font-medium text-blue-600">{selectedData.trailingStopPoints} pts</span></>)}
                  </div>
                </div>
              )}
            </div>

            {/* Active Positions (Current Orders) */}
            <div className="p-6">
              <div className="flex items-center justify-between mb-4">
                <h5 className="text-sm font-semibold text-default-800">Active Orders</h5>
                {positions.length > 0 && (
                  <span className={`text-xs font-bold ${totalPnl >= 0 ? 'text-green-600' : 'text-red-600'}`}>
                    {totalPnl >= 0 ? '+' : ''}${totalPnl.toFixed(2)}
                  </span>
                )}
              </div>
              {positions.length > 0 ? (
                <div className="space-y-1.5">
                  {positions.map(pos => (
                    <div key={pos.ticket} className="rounded-lg bg-default-50 dark:bg-default-50/50 px-3 py-2.5">
                      <div className="flex items-center gap-2">
                        <div className={`rounded p-1 ${pos.type === 'BUY' ? 'bg-green-100 dark:bg-green-500/20' : 'bg-red-100 dark:bg-red-500/20'}`}>
                          {pos.type === 'BUY' ? <LuTrendingUp className="size-3 text-green-600 dark:text-green-400" /> : <LuTrendingDown className="size-3 text-red-600 dark:text-red-400" />}
                        </div>
                        <div className="flex-1 min-w-0">
                          <div className="flex items-center gap-1.5">
                            <span className="text-[11px] font-bold text-default-800">{pos.symbol}</span>
                            <span className={`rounded px-1.5 py-0.5 text-[8px] font-bold text-white ${pos.type === 'BUY' ? 'bg-green-500' : 'bg-red-500'}`}>{pos.type}</span>
                            <span className="text-[9px] text-default-400">{pos.volume} lot</span>
                          </div>
                          <div className="flex items-center gap-2 mt-0.5 text-[9px] text-default-400">
                            <span>Entry: {pos.open_price}</span>
                            <span>→ {pos.current_price}</span>
                            {pos.sl > 0 && <span className="text-red-400">SL: {pos.sl}</span>}
                            {pos.tp > 0 && <span className="text-green-400">TP: {pos.tp}</span>}
                          </div>
                        </div>
                        <span className={`text-xs font-bold tabular-nums ${pos.pnl >= 0 ? 'text-green-600' : 'text-red-600'}`}>
                          {pos.pnl >= 0 ? '+' : ''}${pos.pnl.toFixed(2)}
                        </span>
                      </div>
                    </div>
                  ))}
                </div>
              ) : (
                <p className="text-xs text-default-400">No open positions</p>
              )}
            </div>

            {/* Trade History Section */}
            <div className="p-6">
              <h5 className="text-sm font-semibold text-default-800 mb-4">Trade History</h5>
              {deals.length > 0 ? (
                <div className="space-y-1.5 max-h-64 overflow-y-auto">
                  {[...deals].reverse().slice(0, 20).map(d => {
                    const net = d.profit + d.swap + d.commission;
                    return (
                      <div key={d.ticket} className="flex items-center gap-2 rounded-lg bg-default-50 dark:bg-default-50/50 px-3 py-2">
                        <div className={`rounded p-1 ${d.type === 'BUY' ? 'bg-green-100 dark:bg-green-500/20' : 'bg-red-100 dark:bg-red-500/20'}`}>
                          {d.type === 'BUY' ? <LuTrendingUp className="size-3 text-green-600 dark:text-green-400" /> : <LuTrendingDown className="size-3 text-red-600 dark:text-red-400" />}
                        </div>
                        <div className="flex-1 min-w-0">
                          <p className="text-[11px] font-semibold text-default-800 truncate">{d.symbol}</p>
                          <p className="text-[9px] text-default-400">{d.time} · {d.volume} lot</p>
                        </div>
                        <span className={`text-xs font-bold tabular-nums ${net >= 0 ? 'text-green-600' : 'text-red-600'}`}>
                          {net >= 0 ? '+' : ''}${net.toFixed(2)}
                        </span>
                      </div>
                    );
                  })}
                  {deals.length > 20 && (
                    <p className="text-center text-[10px] text-default-400 pt-1">+{deals.length - 20} more deals</p>
                  )}
                </div>
              ) : (
                <p className="text-xs text-default-400">No trade history available</p>
              )}
              {deals.length > 0 && (() => {
                const totalNet = deals.reduce((s, d) => s + d.profit + d.swap + d.commission, 0);
                const wins = deals.filter(d => d.profit >= 0).length;
                return (
                  <div className="mt-3 flex items-center gap-3 rounded-lg border border-default-200 p-2">
                    <div className="text-center flex-1">
                      <p className="text-[9px] text-default-400">Net P&L</p>
                      <p className={`text-xs font-bold ${totalNet >= 0 ? 'text-green-600' : 'text-red-600'}`}>{totalNet >= 0 ? '+' : ''}${totalNet.toFixed(2)}</p>
                    </div>
                    <div className="w-px h-6 bg-default-200" />
                    <div className="text-center flex-1">
                      <p className="text-[9px] text-default-400">Win Rate</p>
                      <p className="text-xs font-bold text-default-800">{(wins / deals.length * 100).toFixed(0)}%</p>
                    </div>
                    <div className="w-px h-6 bg-default-200" />
                    <div className="text-center flex-1">
                      <p className="text-[9px] text-default-400">Deals</p>
                      <p className="text-xs font-bold text-default-800">{deals.length}</p>
                    </div>
                  </div>
                );
              })()}
            </div>

          </div>
        </SimplebarClient>

        <div className="p-4 flex border-t border-dashed border-default-900/10">
          <button onClick={() => setIsOpen(false)} className="btn bg-primary text-white grow">
            Done
          </button>
        </div>
      </div>
    </>
  );
};

export default Customizer;

declare global {
  interface Window {
    __openCustomizer?: () => void;
  }
}
