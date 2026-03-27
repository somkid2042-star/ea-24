import { useState, useEffect, useRef, useCallback } from 'react';
import {
  LuChartCandlestick,
  LuCircleCheck,
  LuCircleX,
  LuCpu,
  LuFolderOpen,
  LuLink,
  LuMonitorSmartphone,
  LuPackage,
  LuPlay,
  LuRefreshCw,
  LuSquare,
  LuWifi,
  LuWifiOff,
} from 'react-icons/lu';

type Mt5Instance = {
  id: string;
  broker_name: string;
  install_path: string;
  terminal_exe: string;
  ea_deployed: boolean;
  ea_version: string;
  has_experts_dir: boolean;
  mt5_running: boolean;
};

type EaLiveStatus = {
  connected: boolean;
  version: string;
  symbol: string;
  latestVersion: string;
  updateAvailable: boolean;
};

import { getWsUrl } from '@/utils/config';

type ActionStatus = {
  type: 'idle' | 'loading' | 'success' | 'error';
  message: string;
};

const WS_URL = getWsUrl();
const WS_HOST = WS_URL.replace(/^ws:\/\//, '').split(':')[0] || window.location.hostname;

const MT5Settings = () => {
  const [instances, setInstances] = useState<Mt5Instance[]>([]);
  const [scanning, setScanning] = useState(false);
  const [wsConnected, setWsConnected] = useState(false);
  const [eaStatus, setEaStatus] = useState<EaLiveStatus>({
    connected: false,
    version: '-',
    symbol: '-',
    latestVersion: '-',
    updateAvailable: false,
  });
  const [tradingEnabled, setTradingEnabled] = useState(true);
  const [actionStatuses, setActionStatuses] = useState<Record<string, ActionStatus>>({});
  const wsRef = useRef<WebSocket | null>(null);

  // WebSocket connection
  const connectWs = useCallback(() => {
    const ws = new WebSocket(WS_URL);

    ws.onopen = () => {
      setWsConnected(true);
      // Auto-scan on connect
      ws.send(JSON.stringify({ action: 'scan_mt5' }));
      setScanning(true);
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
            setInstances(data.instances || []);
            setScanning(false);
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

          case 'deploy_status':
            setActionStatuses((prev) => ({
              ...prev,
              [`deploy_${data.instance_id || 'all'}`]: {
                type: data.status === 'success' ? 'success' : 'error',
                message: data.status === 'success' ? 'EA deployed!' : 'Deploy failed',
              },
            }));
            // Auto re-scan after deploy
            if (data.status === 'success' && wsRef.current?.readyState === 1) {
              setTimeout(() => {
                wsRef.current?.send(JSON.stringify({ action: 'scan_mt5' }));
              }, 500);
            }
            break;

          case 'launch_status':
            setActionStatuses((prev) => ({
              ...prev,
              [`launch_${data.instance_id || ''}`]: {
                type: data.status === 'success' ? 'success' : 'error',
                message: data.status === 'success' ? 'MT5 launched!' : 'Launch failed',
              },
            }));
            // Auto re-scan after launch to update running state & EA connection
            if (data.status === 'success') {
              setTimeout(() => {
                wsRef.current?.send(JSON.stringify({ action: 'scan_mt5' }));
              }, 3000);
            }
            break;

          case 'setup_webrequest_status':
            setActionStatuses((prev) => ({
              ...prev,
              [`webrequest_${data.instance_id || ''}`]: {
                type: data.status === 'success' ? 'success' : 'error',
                message: data.status === 'success' ? 'Done' : 'Failed',
              },
            }));
            break;

          case 'close_mt5_status':
            setActionStatuses((prev) => ({
              ...prev,
              [`close_${data.instance_id || ''}`]: {
                type: data.status === 'success' ? 'success' : 'error',
                message: data.status === 'success' ? 'MT5 closed' : 'Failed',
              },
            }));
            // Refresh instances to update running state
            setTimeout(() => sendAction('scan_mt5'), 2000);
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

  // Clear action status after 3 seconds
  useEffect(() => {
    const timers: ReturnType<typeof setTimeout>[] = [];
    for (const key in actionStatuses) {
      if (actionStatuses[key].type !== 'idle' && actionStatuses[key].type !== 'loading') {
        timers.push(
          setTimeout(() => {
            setActionStatuses((prev) => ({
              ...prev,
              [key]: { type: 'idle', message: '' },
            }));
          }, 3000)
        );
      }
    }
    return () => timers.forEach(clearTimeout);
  }, [actionStatuses]);

  const sendAction = (action: string, extra?: Record<string, string>) => {
    if (wsRef.current?.readyState === 1) {
      wsRef.current.send(JSON.stringify({ action, ...extra }));
    }
  };

  const handleScan = () => {
    setScanning(true);
    sendAction('scan_mt5');
  };

  const handleDeploy = (instanceId: string) => {
    setActionStatuses((prev) => ({
      ...prev,
      [`deploy_${instanceId}`]: { type: 'loading', message: 'Deploying...' },
    }));
    sendAction('deploy_ea_to', { instance_id: instanceId });
  };

  const handleLaunch = (instanceId: string) => {
    setActionStatuses((prev) => ({
      ...prev,
      [`launch_${instanceId}`]: { type: 'loading', message: 'Launching...' },
    }));
    sendAction('launch_mt5', { instance_id: instanceId });
  };

  const handleToggleTrading = () => {
    const newState = !tradingEnabled;
    setTradingEnabled(newState);
    sendAction(newState ? 'start_trading' : 'stop_trading');
  };

  const handleToggleMt5 = (instanceId: string, isRunning: boolean) => {
    if (isRunning) {
      setActionStatuses((prev) => ({
        ...prev,
        [`close_${instanceId}`]: { type: 'loading', message: 'Closing...' },
      }));
      sendAction('close_mt5', { instance_id: instanceId });
    } else {
      handleLaunch(instanceId);
    }
  };

  const getActionStatus = (key: string): ActionStatus =>
    actionStatuses[key] || { type: 'idle', message: '' };

  return (
    <main className="space-y-6">
      {/* Page Header */}
      <div className="flex items-center justify-between">
        <div>
          <h4 className="text-lg font-semibold text-default-900">MT5 Settings</h4>
          <p className="mt-1 text-sm text-default-500">
            Auto-discover MetaTrader 5 instances & manage Expert Advisors
          </p>
        </div>
        <div className="flex items-center gap-2">
          <span
            className={`inline-flex items-center gap-1.5 rounded-full px-3 py-1 text-xs font-medium ${
              wsConnected
                ? 'bg-green-100 text-green-700 dark:bg-green-500/20 dark:text-green-400'
                : 'bg-red-100 text-red-700 dark:bg-red-500/20 dark:text-red-400'
            }`}
          >
            {wsConnected ? <LuWifi className="size-3.5" /> : <LuWifiOff className="size-3.5" />}
            {wsConnected ? 'Server Connected' : 'Server Offline'}
          </span>
        </div>
      </div>

      {/* Section 1: EA Live Status */}
      <div className="card">
        <div className="p-5">
          <div className="mb-4 flex items-center gap-2">
            <LuCpu className="size-5 text-primary" />
            <h5 className="text-base font-semibold text-default-900">EA Live Status</h5>
          </div>

          <div className="grid grid-cols-2 gap-4 md:grid-cols-4">
            {/* Connection Status */}
            <div className="rounded-lg border border-default-100 bg-default-50/50 p-4 dark:bg-default-50/20">
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
            <div className="rounded-lg border border-default-100 bg-default-50/50 p-4 dark:bg-default-50/20">
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
            <div className="rounded-lg border border-default-100 bg-default-50/50 p-4 dark:bg-default-50/20">
              <p className="text-xs font-medium uppercase text-default-400">Symbol</p>
              <p className="mt-2 text-sm font-bold text-primary">{eaStatus.symbol || '-'}</p>
            </div>

            {/* Trading Status */}
            <div className="rounded-lg border border-default-100 bg-default-50/50 p-4 dark:bg-default-50/20">
              <p className="text-xs font-medium uppercase text-default-400">Trading</p>
              <div className="mt-2 flex items-center gap-2">
                <span
                  className={`inline-flex items-center gap-1 rounded-full px-2.5 py-0.5 text-xs font-medium ${
                    tradingEnabled
                      ? 'bg-green-100 text-green-700 dark:bg-green-500/20 dark:text-green-400'
                      : 'bg-red-100 text-red-700 dark:bg-red-500/20 dark:text-red-400'
                  }`}
                >
                  {tradingEnabled ? '● Enabled' : '○ Disabled'}
                </span>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Section 2: MT5 Instances */}
      <div className="card">
        <div className="p-5">
          <div className="mb-4 flex items-center justify-between">
            <div className="flex items-center gap-2">
              <LuMonitorSmartphone className="size-5 text-primary" />
              <h5 className="text-base font-semibold text-default-900">
                MT5 Instances
                {instances.length > 0 && (
                  <span className="ml-2 rounded-full bg-primary/10 px-2 py-0.5 text-xs font-normal text-primary">
                    {instances.length} found
                  </span>
                )}
              </h5>
            </div>
            <button
              onClick={handleScan}
              disabled={scanning || !wsConnected}
              className="inline-flex items-center gap-1.5 rounded-lg border border-default-200 px-3 py-1.5 text-xs font-medium text-default-700 transition hover:bg-default-100 dark:hover:bg-default-50 disabled:opacity-40"
            >
              <LuRefreshCw className={`size-3.5 ${scanning ? 'animate-spin' : ''}`} />
              {scanning ? 'Scanning...' : 'Scan Again'}
            </button>
          </div>

          {/* Loading state */}
          {scanning && instances.length === 0 && (
            <div className="flex items-center justify-center py-12">
              <div className="text-center">
                <LuRefreshCw className="mx-auto size-8 animate-spin text-primary/50" />
                <p className="mt-3 text-sm text-default-500">Scanning for MetaTrader 5 installations...</p>
              </div>
            </div>
          )}

          {/* No instances */}
          {!scanning && instances.length === 0 && (
            <div className="flex items-center justify-center py-12">
              <div className="text-center">
                <LuMonitorSmartphone className="mx-auto size-10 text-default-300" />
                <p className="mt-3 text-sm font-medium text-default-500">No MT5 instances found</p>
                <p className="mt-1 text-xs text-default-400">
                  Make sure MetaTrader 5 is installed on this machine
                </p>
              </div>
            </div>
          )}

          {/* Instance Cards */}
          <div className="space-y-3">
            {instances.map((inst) => {
              const deployStatus = getActionStatus(`deploy_${inst.id}`);

              return (
                <div
                  key={inst.id}
                  className="rounded-xl border border-default-200 bg-gradient-to-r from-default-50/50 to-default-50/10 p-5 transition hover:shadow-md hover:shadow-primary/5 dark:from-default-100 dark:to-default-50"
                >
                  <div className="flex flex-col gap-4 md:flex-row md:items-center md:justify-between">
                    {/* Instance Info */}
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center gap-3">
                        <div className="flex size-10 shrink-0 items-center justify-center rounded-lg bg-primary/10">
                          <LuChartCandlestick className="size-5 text-primary" />
                        </div>
                        <div className="min-w-0">
                          <h6 className="truncate text-sm font-semibold text-default-900">
                            {inst.broker_name || 'MetaTrader 5'}
                          </h6>
                          <div className="mt-0.5 flex items-center gap-1.5 text-xs text-default-400">
                            <LuFolderOpen className="size-3 shrink-0" />
                            <span className="truncate font-mono">{inst.install_path}</span>
                          </div>
                        </div>
                      </div>

                      {/* EA Status Badge */}
                      <div className="mt-3 flex flex-wrap items-center gap-2">
                        <span
                          className={`inline-flex items-center gap-1 rounded-full px-2.5 py-0.5 text-xs font-medium ${
                            inst.ea_deployed
                              ? 'bg-green-100 text-green-700 dark:bg-green-500/20 dark:text-green-400'
                              : 'bg-default-100 text-default-500 dark:bg-default-200/10 dark:text-default-400'
                          }`}
                        >
                          {inst.ea_deployed ? (
                            <>
                              <LuCircleCheck className="size-3" /> EA Deployed
                            </>
                          ) : (
                            <>
                              <LuCircleX className="size-3" /> No EA
                            </>
                          )}
                        </span>
                        {inst.ea_deployed && inst.ea_version !== '-' && (
                          <span className="rounded bg-blue-100 px-2 py-0.5 text-[10px] font-medium text-blue-700 dark:bg-blue-500/20 dark:text-blue-400">
                            v{inst.ea_version}
                          </span>
                        )}
                        <span className="rounded bg-default-100 px-2 py-0.5 text-[10px] font-mono text-default-400 dark:bg-default-200/10">
                          {inst.id.substring(0, 12)}...
                        </span>
                      </div>
                     {/* Status Indicators */}
                     <div className="mt-3 flex flex-wrap items-center gap-3">
                        <span className={`inline-flex items-center gap-1.5 text-xs font-medium ${
                          eaStatus?.connected ? 'text-green-600 dark:text-green-400' : 'text-red-400'
                        }`}>
                          <span className={`inline-block size-2 rounded-full ${eaStatus?.connected ? 'bg-green-500' : 'bg-red-400'}`} />
                          EA Connection
                        </span>
                        <span className={`inline-flex items-center gap-1.5 text-xs font-medium ${
                          tradingEnabled ? 'text-green-600 dark:text-green-400' : 'text-red-400'
                        }`}>
                          <span className={`inline-block size-2 rounded-full ${tradingEnabled ? 'bg-green-500' : 'bg-red-400'}`} />
                          Algo Trading
                        </span>
                        {inst.mt5_running && eaStatus.connected && (
                          <span className="inline-flex items-center gap-1.5 text-xs font-medium text-green-600 dark:text-green-400">
                            <span className="relative flex size-2">
                              <span className="absolute inline-flex size-full animate-ping rounded-full bg-green-400 opacity-75" />
                              <span className="relative inline-flex size-2 rounded-full bg-green-500" />
                            </span>
                            EA Active
                          </span>
                        )}
                     </div>
                    </div>

                    {/* Action Buttons */}
                    <div className="flex shrink-0 flex-wrap items-center gap-3">
                      {/* Deploy EA Button - hidden if version matches server */}
                      {(!inst.ea_deployed || inst.ea_version !== eaStatus.latestVersion) && (
                        <button
                          onClick={() => handleDeploy(inst.id)}
                          disabled={deployStatus.type === 'loading' || !wsConnected}
                          className={`inline-flex items-center gap-1.5 rounded-lg px-4 py-2 text-xs font-medium transition disabled:opacity-40 ${
                            inst.ea_deployed
                              ? 'border border-blue-200 bg-blue-50 text-blue-600 hover:bg-blue-100 dark:border-blue-500/30 dark:bg-blue-500/10 dark:text-blue-400 dark:hover:bg-blue-500/20'
                              : 'bg-blue-500 text-white hover:bg-blue-600 dark:bg-blue-600 dark:hover:bg-blue-700'
                          }`}
                        >
                          {deployStatus.type === 'loading' ? (
                            <><LuRefreshCw className="size-3.5 animate-spin" /> Deploying...</>
                          ) : deployStatus.type === 'success' ? (
                            <><LuCircleCheck className="size-3.5" /> Deployed!</>
                          ) : (
                            <><LuPackage className="size-3.5" /> {inst.ea_deployed ? 'Update EA' : 'Deploy EA'}</>
                          )}
                        </button>
                      )}

                      {/* Stop/Start Trading per instance */}
                      <button
                        onClick={handleToggleTrading}
                        disabled={!eaStatus.connected || !wsConnected}
                        className={`inline-flex items-center gap-1.5 rounded-lg px-3 py-2 text-xs font-medium transition disabled:opacity-40 ${
                          tradingEnabled
                            ? 'bg-amber-500 text-white hover:bg-amber-600'
                            : 'bg-green-500 text-white hover:bg-green-600'
                        }`}
                      >
                        {tradingEnabled ? (
                          <><LuSquare className="size-3" /> Stop Trading</>
                        ) : (
                          <><LuPlay className="size-3" /> Start Trading</>
                        )}
                      </button>

                      {/* Open Chart + EA button (only when MT5 is running and EA is NOT active) */}
                      {inst.mt5_running && !eaStatus.connected && (
                        <button
                          onClick={() => handleLaunch(inst.id)}
                          disabled={getActionStatus(`launch_${inst.id}`).type === 'loading' || !wsConnected}
                          className="inline-flex items-center gap-1.5 rounded-lg bg-primary px-3 py-2 text-xs font-medium text-white transition hover:bg-primary/90 disabled:opacity-40"
                        >
                          {getActionStatus(`launch_${inst.id}`).type === 'loading' ? (
                            <><LuRefreshCw className="size-3 animate-spin" /> Opening...</>
                          ) : (
                            <><LuChartCandlestick className="size-3" /> Open Chart + EA</>
                          )}
                        </button>
                      )}

                      {/* MT5 Toggle Switch - shows real per-instance status */}
                      <div className="flex items-center gap-2">
                        <span className="text-xs font-medium text-default-500">MT5</span>
                        <button
                          onClick={() => handleToggleMt5(inst.id, inst.mt5_running)}
                          disabled={(!inst.ea_deployed && !inst.mt5_running) || !wsConnected}
                          className={`relative inline-flex h-6 w-11 items-center rounded-full transition-colors duration-200 focus:outline-none disabled:opacity-40 ${
                            inst.mt5_running
                              ? 'bg-green-500'
                              : 'bg-default-300 dark:bg-default-600'
                          }`}
                          title={inst.mt5_running ? 'MT5 is running' : 'Click to open MT5 + EA'}
                        >
                          <span
                            className={`inline-block size-4 rounded-full bg-white shadow-sm transition-transform duration-200 ${
                              inst.mt5_running ? 'translate-x-6' : 'translate-x-1'
                            }`}
                          />
                        </button>
                      </div>
                    </div>
                  </div>
                </div>
              );
            })}
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
            <div className="rounded-lg border border-default-100 bg-default-50/50 p-4 dark:bg-default-50/20">
              <p className="text-xs font-medium uppercase text-default-400">WebSocket Server</p>
              <p className="mt-1 font-mono text-sm text-default-900">{WS_URL}</p>
              <p className={`mt-1 text-xs ${wsConnected ? 'text-green-600 dark:text-green-400' : 'text-red-500'}`}>
                {wsConnected ? '● Connected' : '○ Disconnected'}
              </p>
            </div>
            <div className="rounded-lg border border-default-100 bg-default-50/50 p-4 dark:bg-default-50/20">
              <p className="text-xs font-medium uppercase text-default-400">MT5 TCP Server</p>
              <p className="mt-1 font-mono text-sm text-default-900">{WS_HOST}:8081</p>
              <p className={`mt-1 text-xs ${eaStatus.connected ? 'text-green-600 dark:text-green-400' : 'text-default-400'}`}>
                {eaStatus.connected ? '● EA Connected' : '○ Waiting for EA'}
              </p>
            </div>
            <div className="rounded-lg border border-default-100 bg-default-50/50 p-4 dark:bg-default-50/20">
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
