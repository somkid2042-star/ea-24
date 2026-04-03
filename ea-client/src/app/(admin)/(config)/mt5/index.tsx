import { useState, useEffect, useRef, useCallback } from 'react';
import {
  LuCpu,
  LuLink,
} from 'react-icons/lu';



type EaLiveStatus = {
  connected: boolean;
  version: string;
  symbol: string;
  latestVersion: string;
  updateAvailable: boolean;
};

import { getWsUrl } from '@/utils/config';



const WS_URL = getWsUrl();
const WS_HOST = WS_URL.replace(/^ws:\/\//, '').split(':')[0] || window.location.hostname;


const MT5Settings = () => {
  const [wsConnected, setWsConnected] = useState(false);
  const [eaStatus, setEaStatus] = useState<EaLiveStatus>({
    connected: false,
    version: '-',
    symbol: '-',
    latestVersion: '-',
    updateAvailable: false,
  });
  const [tradingEnabled, setTradingEnabled] = useState(true);
  const wsRef = useRef<WebSocket | null>(null);

  // WebSocket connection
  const connectWs = useCallback(() => {
    const ws = new WebSocket(WS_URL);

    ws.onopen = () => {
      setWsConnected(true);
      ws.send(JSON.stringify({ action: 'scan_mt5' }));
    };

    ws.onclose = () => {
      setWsConnected(false);
      setEaStatus((prev) => ({ ...prev, connected: false }));
      // Reconnect after 3 seconds
      setTimeout(connectWs, 3000);
    };

    ws.onmessage = (evt) => {
      try {
        const data = JSON.parse(evt.data);

        switch (data.type) {
          case 'welcome':
            setEaStatus({
              connected: data.ea_connected || false,
              version: data.ea_version || '-',
              symbol: data.ea_symbol || '-',
              latestVersion: data.latest_ea_version || '-',
              updateAvailable: data.update_available || false,
            });
            break;

          case 'ea_info':
            setEaStatus({
              connected: true,
              version: data.version || '-',
              symbol: data.symbol || '-',
              latestVersion: data.latest_version || '-',
              updateAvailable: data.update_available || false,
            });
            break;

          case 'mt5_instances':
            // Also update EA status from scan response (real-time polling)
            if (data.ea_connected !== undefined) {
              setEaStatus((prev) => ({
                ...prev,
                connected: data.ea_connected,
                version: data.ea_version || prev.version,
                symbol: data.ea_symbol || prev.symbol,
              }));
            }
            break;

        }
      } catch {
        // ignore
      }
    };

    wsRef.current = ws;
  }, []);

  useEffect(() => {
    connectWs();
    return () => {
      wsRef.current?.close();
    };
  }, [connectWs]);

  // Real-time polling: auto-refresh every 5 seconds
  useEffect(() => {
    const interval = setInterval(() => {
      if (wsRef.current?.readyState === 1) {
        wsRef.current.send(JSON.stringify({ action: 'scan_mt5' }));
      }
    }, 5000);
    return () => clearInterval(interval);
  }, []);



  const sendAction = (action: string, extra?: Record<string, string>) => {
    if (wsRef.current?.readyState === 1) {
      wsRef.current.send(JSON.stringify({ action, ...extra }));
    }
  };

  const handleToggleTrading = () => {
    const newState = !tradingEnabled;
    setTradingEnabled(newState);
    sendAction(newState ? 'start_trading' : 'stop_trading');
  };

  return (
    <main className="space-y-6">
      <style>{`
        ::-webkit-scrollbar { display: none; }
        * { scrollbar-width: none; }
      `}</style>
      {/* Page Header */}
      <div className="flex items-center justify-between">
        <div>
          <h4 className="text-lg font-semibold text-default-900">MT5 Settings</h4>
          <p className="mt-1 text-sm text-default-500">
            Auto-discover MetaTrader 5 instances & manage Expert Advisors
          </p>
        </div>
      </div>

      {/* Target EA Upload Section removed per user request */}

      {/* Section 1: EA Live Status */}
      <div className="card">
        <div className="p-5">
          <div className="mb-4 flex items-center gap-2">
            <LuCpu className="size-5 text-primary" />
            <h5 className="text-base font-semibold text-default-900">EA Live Status</h5>
          </div>

          <div className="grid grid-cols-2 gap-4 md:grid-cols-4">
            {/* Connection Status */}
            <div className="rounded-xl border border-default-200/60 dark:border-default-300/10 bg-default-50/50 dark:bg-default-200/5 p-4">
              <p className="text-xs font-medium uppercase text-default-400">Connection</p>
              <div className="mt-2 flex items-center gap-2">
                <span
                  className={`size-3 rounded-full ${eaStatus.connected ? 'bg-green-500 animate-pulse' : 'bg-red-400'}`}
                />
                <span className={`text-sm font-semibold ${eaStatus.connected ? 'text-green-600 dark:text-green-400' : 'text-red-500'}`}>
                  {eaStatus.connected ? 'Online' : 'Offline'}
                </span>
              </div>
            </div>

            {/* EA Version */}
            <div className="rounded-xl border border-default-200/60 dark:border-default-300/10 bg-default-50/50 dark:bg-default-200/5 p-4">
              <p className="text-xs font-medium uppercase text-default-400">EA Version</p>
              <p className="mt-2 text-sm font-semibold text-default-900">
                v{eaStatus.version}
                {eaStatus.updateAvailable && (
                  <span className="ml-2 rounded bg-amber-100 px-1.5 py-0.5 text-[10px] text-amber-700 dark:bg-amber-500/20 dark:text-amber-400">
                    Update → v{eaStatus.latestVersion}
                  </span>
                )}
              </p>
            </div>

            {/* Symbol */}
            <div className="rounded-xl border border-default-200/60 dark:border-default-300/10 bg-default-50/50 dark:bg-default-200/5 p-4">
              <p className="text-xs font-medium uppercase text-default-400">Symbol</p>
              <p className="mt-2 text-sm font-bold text-primary">{eaStatus.symbol || '-'}</p>
            </div>

            {/* Trading Status */}
            <div className="rounded-xl border border-default-200/60 dark:border-default-300/10 bg-default-50/50 dark:bg-default-200/5 p-4 relative">
              <p className="text-xs font-medium uppercase text-default-400">Algo Trading</p>
              <div className="mt-2 flex items-center justify-between">
                <span
                  className={`inline-flex items-center gap-1.5 rounded-full px-2.5 py-1 text-xs font-medium ${
                    tradingEnabled
                      ? 'bg-green-100 text-green-700 dark:bg-green-500/20 dark:text-green-400'
                      : 'bg-red-100 text-red-700 dark:bg-red-500/20 dark:text-red-400'
                  }`}
                >
                  <span className={`size-1.5 rounded-full ${tradingEnabled ? 'bg-green-500' : 'bg-red-500'}`}></span>
                  {tradingEnabled ? 'Enabled' : 'Disabled'}
                </span>
                
                {/* Global Toggle Switch */}
                <button
                  onClick={handleToggleTrading}
                  disabled={!eaStatus.connected || !wsConnected}
                  className={`relative inline-flex h-6 w-11 items-center rounded-full transition-colors duration-200 focus:outline-none disabled:opacity-40 ${
                    tradingEnabled ? 'bg-green-500' : 'bg-default-300 dark:bg-default-600'
                  }`}
                  title={tradingEnabled ? 'Click to Stop Trading' : 'Click to Start Trading'}
                >
                  <span
                    className={`inline-block size-4 rounded-full bg-white shadow-sm transition-transform duration-200 ${
                      tradingEnabled ? 'translate-x-6' : 'translate-x-1'
                    }`}
                  />
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>





      {/* Section 3: Connection Info */}
      <div className="card">
        <div className="p-5">
          <div className="mb-4 flex items-center gap-2">
            <LuLink className="size-5 text-primary" />
            <h5 className="text-base font-semibold text-default-900">Connection Info</h5>
          </div>

          <div className="grid grid-cols-1 gap-4 md:grid-cols-3">
            <div className="rounded-xl border border-default-200/60 dark:border-default-300/10 bg-default-50/50 dark:bg-default-200/5 p-4">
              <p className="text-xs font-medium uppercase text-default-400">WebSocket Server</p>
              <p className="mt-1 font-mono text-sm text-default-900">{WS_URL}</p>
              <p className={`mt-1 text-xs ${wsConnected ? 'text-green-600 dark:text-green-400' : 'text-red-500'}`}>
                {wsConnected ? '● Connected' : '○ Disconnected'}
              </p>
            </div>
            <div className="rounded-xl border border-default-200/60 dark:border-default-300/10 bg-default-50/50 dark:bg-default-200/5 p-4">
              <p className="text-xs font-medium uppercase text-default-400">MT5 TCP Server</p>
              <p className="mt-1 font-mono text-sm text-default-900">{WS_HOST}:8081</p>
              <p className={`mt-1 text-xs ${eaStatus.connected ? 'text-green-600 dark:text-green-400' : 'text-default-400'}`}>
                {eaStatus.connected ? '● EA Connected' : '○ Waiting for EA'}
              </p>
            </div>
            <div className="rounded-xl border border-default-200/60 dark:border-default-300/10 bg-default-50/50 dark:bg-default-200/5 p-4">
              <p className="text-xs font-medium uppercase text-default-400">Server EA Version</p>
              <p className="mt-1 font-mono text-sm text-default-900">v{eaStatus.latestVersion}</p>
              <p className="mt-1 text-xs text-default-400">Latest version on server</p>
            </div>
          </div>
        </div>
      </div>
    </main>
  );
};

export default MT5Settings;
