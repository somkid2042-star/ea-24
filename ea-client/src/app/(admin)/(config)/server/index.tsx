import { useState, useEffect, useRef, useCallback } from 'react';
import {
  LuPlay,
  LuSquare,
  LuRefreshCw,
  LuServer,
  LuActivity,
  LuClock,
  LuCpu,
  LuLink,
} from 'react-icons/lu';

import { getWsUrl, setWsUrl } from '@/utils/config';

type ServerStatus = 'running' | 'stopped' | 'starting' | 'stopping' | 'restarting';

const WS_URL = getWsUrl();
// Extract host from WS_URL to use in MT5 connection info (fallback to window.location.hostname if parsing fails)
const WS_HOST = WS_URL.replace(/^ws:\/\//, '').split(':')[0] || window.location.hostname;
const LATEST_EA_VERSION = '2.04';

const ServerSettings = () => {
  const [wsConnected, setWsConnected] = useState(false);
  const [serverStatus, setServerStatus] = useState<ServerStatus>('stopped');
  const [eaConnected, setEaConnected] = useState(false);
  const [eaVersion, setEaVersion] = useState('-');

  const [uptime, setUptime] = useState('—');
  const [config, setConfig] = useState<Record<string, string>>({});
  const [inputUrl, setInputUrl] = useState(WS_URL);
  const [serverVersion, setServerVersion] = useState<string>('Unknown');
  const [updateStatus, setUpdateStatus] = useState<string>('');
  const wsRef = useRef<WebSocket | null>(null);
  // Server uptime: base seconds from server + local timestamp when received
  const serverUptimeBase = useRef<number | null>(null);
  const serverUptimeReceivedAt = useRef<number | null>(null);

  const updateServerUptime = (secs: number) => {
    serverUptimeBase.current = secs;
    serverUptimeReceivedAt.current = Date.now();
  };

  const connectWs = useCallback(() => {
    const ws = new WebSocket(WS_URL);

    ws.onopen = () => {
      setWsConnected(true);
      setServerStatus('running');
      // Fetch config from DB
      ws.send(JSON.stringify({ action: 'get_server_config' }));
    };

    ws.onclose = () => {
      setWsConnected(false);
      setServerStatus('stopped');
      setEaConnected(false);
      serverUptimeBase.current = null;
      serverUptimeReceivedAt.current = null;
      setUptime('—');
      setTimeout(connectWs, 3000);
    };

    ws.onmessage = (evt) => {
      try {
        const data = JSON.parse(evt.data);
        if (data.type === 'welcome') {
          setEaConnected(data.ea_connected || false);
          setEaVersion(data.ea_version || '-');
          if (data.server_version) setServerVersion(data.server_version);
          if (data.server_uptime_secs != null) updateServerUptime(data.server_uptime_secs);
        }
        if (data.type === 'update_status') {
          setUpdateStatus(data.message || data.status);
        }
        if (data.type === 'ea_info') {
          setEaConnected(true);
          setEaVersion(data.version || '-');
        }
        if (data.type === 'mt5_instances') {
          if (data.ea_connected !== undefined) {
            setEaConnected(data.ea_connected);
            setEaVersion(data.ea_version || '-');
          }
          if (data.server_uptime_secs != null) updateServerUptime(data.server_uptime_secs);
        }
        if (data.type === 'server_config') {
          setConfig(data.config || {});
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

  // Uptime ticker — uses server-provided base + local elapsed
  useEffect(() => {
    const interval = setInterval(() => {
      if (serverUptimeBase.current != null && serverUptimeReceivedAt.current != null && wsConnected) {
        const localElapsed = Math.floor((Date.now() - serverUptimeReceivedAt.current) / 1000);
        const totalSecs = serverUptimeBase.current + localElapsed;
        const d = Math.floor(totalSecs / 86400);
        const h = Math.floor((totalSecs % 86400) / 3600);
        const m = Math.floor((totalSecs % 3600) / 60);
        const s = totalSecs % 60;
        const hms = `${h.toString().padStart(2, '0')}:${m.toString().padStart(2, '0')}:${s.toString().padStart(2, '0')}`;
        setUptime(d > 0 ? `${d}d ${hms}` : hms);
      }
    }, 1000);
    return () => clearInterval(interval);
  }, [wsConnected]);

  // Poll for real-time updates
  useEffect(() => {
    const interval = setInterval(() => {
      if (wsRef.current?.readyState === 1) {
        wsRef.current.send(JSON.stringify({ action: 'scan_mt5' }));
      }
    }, 5000);
    return () => clearInterval(interval);
  }, []);

  const handleStart = () => {
    setServerStatus('starting');
    // Just trigger reconnection — if server process is running, it will connect
    connectWs();
  };

  const handleStop = () => {
    setServerStatus('stopping');
    // Send stop command to Rust server — it will exit(0)
    if (wsRef.current?.readyState === 1) {
      wsRef.current.send(JSON.stringify({ action: 'stop_server' }));
    }
  };

  const handleRestart = () => {
    setServerStatus('restarting');
    // Send restart command — Rust server will spawn new copy then exit
    if (wsRef.current?.readyState === 1) {
      wsRef.current.send(JSON.stringify({ action: 'restart_server' }));
    }
  };

  const handleCheckUpdate = () => {
    if (wsRef.current?.readyState === 1) {
      setUpdateStatus('Checking GitHub...');
      wsRef.current.send(JSON.stringify({ action: 'check_update' }));
    }
  };

  const handleSaveUrl = () => {
    let finalUrl = inputUrl.trim();
    if (finalUrl) {
      if (!finalUrl.startsWith('ws://') && !finalUrl.startsWith('wss://')) {
        finalUrl = `ws://${finalUrl}`;
      }
      setWsUrl(finalUrl);
      // Reload page to apply changes app-wide immediately
      window.location.reload();
    }
  };

  const statusColor: Record<ServerStatus, string> = {
    running: 'bg-green-500',
    stopped: 'bg-red-500',
    starting: 'bg-yellow-500',
    stopping: 'bg-yellow-500',
    restarting: 'bg-yellow-500',
  };

  const statusLabel: Record<ServerStatus, string> = {
    running: 'Running',
    stopped: 'Stopped',
    starting: 'Starting...',
    stopping: 'Stopping...',
    restarting: 'Restarting...',
  };

  return (
    <main className="space-y-6">
      {/* Page Header */}
      <div className="flex items-center justify-between">
        <div>
          <h4 className="text-lg font-semibold text-default-900">Server Control</h4>
          <p className="mt-1 text-sm text-default-500">
            Manage EA Trading Server — start, stop, restart and monitor status
          </p>
        </div>
      </div>


      {/* Server Status Card */}
      <div className="card">
        <div className="p-6">
          <div className="mb-5 flex items-center gap-2">
            <LuServer className="size-5 text-primary" />
            <h5 className="text-base font-semibold text-default-900">Server Status</h5>
          </div>

          <div className="flex flex-col gap-6 md:flex-row md:items-center md:justify-between">
            {/* Status Indicator */}
            <div className="flex items-center gap-4">
              <div className={`size-4 rounded-full ${statusColor[serverStatus]} animate-pulse`} />
              <div>
                <p className="text-xl font-bold text-default-900">{statusLabel[serverStatus]}</p>
                <p className="text-sm text-default-500">ea-server v2.0</p>
              </div>
            </div>

            {/* Control Buttons */}
            <div className="flex items-center gap-3">
              <button
                onClick={handleStart}
                disabled={serverStatus === 'running' || serverStatus === 'starting'}
                className="btn bg-success/10 text-success hover:bg-success hover:text-white disabled:opacity-40 disabled:cursor-not-allowed"
              >
                <LuPlay className="size-4" /> Start
              </button>
              <button
                onClick={handleStop}
                disabled={serverStatus === 'stopped' || serverStatus === 'stopping'}
                className="btn bg-danger/10 text-danger hover:bg-danger hover:text-white disabled:opacity-40 disabled:cursor-not-allowed"
              >
                <LuSquare className="size-4" /> Stop
              </button>
              <button
                onClick={handleRestart}
                disabled={serverStatus === 'stopped' || serverStatus === 'restarting'}
                className="btn bg-warning/10 text-warning hover:bg-warning hover:text-white disabled:opacity-40 disabled:cursor-not-allowed"
              >
                <LuRefreshCw className={`size-4 ${serverStatus === 'restarting' ? 'animate-spin' : ''}`} /> Restart
              </button>
            </div>
          </div>
        </div>
      </div>

      {/* Stats Grid */}
      <div className="grid grid-cols-2 gap-4 md:grid-cols-4">
        {/* Uptime */}
        <div className="card">
          <div className="p-4">
            <div className="mb-2 flex items-center gap-2">
              <LuClock className="size-4 text-blue-500" />
              <span className="text-xs font-medium uppercase text-default-500">Uptime</span>
            </div>
            <p className="text-lg font-bold tabular-nums text-default-900">{uptime}</p>
          </div>
        </div>

        {/* EA Connection */}
        <div className="card">
          <div className="p-4">
            <div className="mb-2 flex items-center gap-2">
              <LuCpu className="size-4 text-purple-500" />
              <span className="text-xs font-medium uppercase text-default-500">EA Connection</span>
            </div>
            <div className="flex items-center gap-2">
              <span className={`inline-block size-2.5 rounded-full ${eaConnected ? 'bg-green-500' : 'bg-red-500'}`} />
              <p className="text-lg font-bold text-default-900">{eaConnected ? 'Online' : 'Offline'}</p>
            </div>
          </div>
        </div>

        {/* Server Version */}
        <div className="card">
          <div className="p-4">
            <div className="mb-2 flex items-center justify-between">
              <div className="flex items-center gap-2">
                <LuActivity className="size-4 text-primary" />
                <span className="text-xs font-medium uppercase text-default-500">Server Version</span>
              </div>
              <button 
                onClick={handleCheckUpdate} 
                disabled={!wsConnected || updateStatus === 'Checking GitHub...'}
                className="text-[10px] font-medium text-primary hover:underline disabled:opacity-50"
              >
                Check Update
              </button>
            </div>
            <p className="text-lg font-bold text-default-900">v{serverVersion}</p>
            {updateStatus && <p className="mt-1 text-xs text-default-400">{updateStatus}</p>}
          </div>
        </div>

        {/* EA Version */}
        <div className="card">
          <div className="p-4">
            <div className="mb-2 flex items-center gap-2">
              <LuActivity className="size-4 text-emerald-500" />
              <span className="text-xs font-medium uppercase text-default-500">EA Version</span>
            </div>
            <p className="text-lg font-bold text-default-900">v{eaVersion}</p>
          </div>
        </div>


      </div>

      {/* Connection Info */}
      <div className="card">
        <div className="p-6">
          <div className="mb-5 flex items-center gap-2">
            <LuLink className="size-5 text-primary" />
            <h5 className="text-base font-semibold text-default-900">Connection Info</h5>
          </div>
          <div className="grid grid-cols-1 gap-4 md:grid-cols-3">
            <div className="rounded-lg border border-default-100 bg-default-50 p-4 dark:bg-default-100/50">
              <p className="mb-2 text-xs font-medium uppercase text-default-400">WebSocket Server URL</p>
              <div className="flex items-center gap-2">
                <input
                  type="text"
                  value={inputUrl}
                  onChange={(e) => setInputUrl(e.target.value)}
                  className="form-input w-full rounded-md border border-default-200 px-3 py-1.5 text-sm text-default-900 focus:border-primary focus:ring-primary dark:border-default-700"
                  placeholder="ws://127.0.0.1:8080"
                />
                <button
                  onClick={handleSaveUrl}
                  disabled={inputUrl === WS_URL}
                  className="btn bg-primary/10 text-primary hover:bg-primary hover:text-white disabled:opacity-50"
                >
                  Save
                </button>
              </div>
              <span className={`mt-2 inline-flex items-center gap-1 text-xs ${wsConnected ? 'text-green-600 dark:text-green-400' : 'text-red-500'}`}>
                <span className={`inline-block size-1.5 rounded-full ${wsConnected ? 'bg-green-500' : 'bg-red-500'}`} />
                {wsConnected ? 'Connected' : 'Disconnected'}
              </span>
            </div>
            <div className="rounded-lg border border-default-100 bg-default-50 p-4 dark:bg-default-100/50">
              <p className="mb-1 text-xs font-medium uppercase text-default-400">MT5 TCP Server</p>
              <p className="text-sm font-semibold text-default-800">{WS_HOST}:{config.tcp_port || '8081'}</p>
              <span className={`mt-1 inline-flex items-center gap-1 text-xs ${eaConnected ? 'text-green-600 dark:text-green-400' : 'text-default-400'}`}>
                <span className={`inline-block size-1.5 rounded-full ${eaConnected ? 'bg-green-500' : 'bg-default-300'}`} />
                {eaConnected ? 'EA Connected' : 'Waiting for EA'}
              </span>
            </div>
            <div className="rounded-lg border border-default-100 bg-default-50 p-4 dark:bg-default-100/50">
              <p className="mb-1 text-xs font-medium uppercase text-default-400">Server EA Version</p>
              <p className="text-sm font-semibold text-default-800">v{LATEST_EA_VERSION}</p>
              <span className="mt-1 inline-flex items-center gap-1 text-xs text-default-400">
                Latest version on server
              </span>
            </div>
          </div>
        </div>
      </div>
    </main>
  );
};

export default ServerSettings;
