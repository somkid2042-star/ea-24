import { useState, useEffect, useRef, useCallback } from 'react';
import {
  LuPlay,
  LuSquare,
  LuRefreshCw,
  LuServer,
  LuWifi,
  LuWifiOff,
  LuActivity,
  LuClock,
  LuCpu,
  LuLink,
} from 'react-icons/lu';

type ServerStatus = 'running' | 'stopped' | 'starting' | 'stopping' | 'restarting';

const ServerSettings = () => {
  const [wsConnected, setWsConnected] = useState(false);
  const [serverStatus, setServerStatus] = useState<ServerStatus>('stopped');
  const [eaConnected, setEaConnected] = useState(false);
  const [eaVersion, setEaVersion] = useState('-');
  const [eaSymbol, setEaSymbol] = useState('-');
  const [uptime, setUptime] = useState('—');
  const wsRef = useRef<WebSocket | null>(null);
  const uptimeStart = useRef<number | null>(null);

  const connectWs = useCallback(() => {
    const ws = new WebSocket('ws://127.0.0.1:8080');

    ws.onopen = () => {
      setWsConnected(true);
      setServerStatus('running');
      uptimeStart.current = Date.now();
    };

    ws.onclose = () => {
      setWsConnected(false);
      setServerStatus('stopped');
      setEaConnected(false);
      uptimeStart.current = null;
      setUptime('—');
      setTimeout(connectWs, 3000);
    };

    ws.onmessage = (evt) => {
      try {
        const data = JSON.parse(evt.data);
        if (data.type === 'welcome') {
          setEaConnected(data.ea_connected || false);
          setEaVersion(data.ea_version || '-');
          setEaSymbol(data.ea_symbol || '-');
        }
        if (data.type === 'ea_info') {
          setEaConnected(true);
          setEaVersion(data.version || '-');
          setEaSymbol(data.symbol || '-');
        }
        if (data.type === 'mt5_instances') {
          if (data.ea_connected !== undefined) {
            setEaConnected(data.ea_connected);
            setEaVersion(data.ea_version || '-');
            setEaSymbol(data.ea_symbol || '-');
          }
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

  // Uptime ticker
  useEffect(() => {
    const interval = setInterval(() => {
      if (uptimeStart.current && wsConnected) {
        const diff = Math.floor((Date.now() - uptimeStart.current) / 1000);
        const h = Math.floor(diff / 3600);
        const m = Math.floor((diff % 3600) / 60);
        const s = diff % 60;
        setUptime(`${h.toString().padStart(2, '0')}:${m.toString().padStart(2, '0')}:${s.toString().padStart(2, '0')}`);
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
        <div className="flex items-center gap-2">
          <span
            className={`inline-flex items-center gap-1.5 rounded-full px-3 py-1 text-xs font-medium ${
              wsConnected
                ? 'bg-green-100 text-green-700 dark:bg-green-500/20 dark:text-green-400'
                : 'bg-red-100 text-red-700 dark:bg-red-500/20 dark:text-red-400'
            }`}
          >
            {wsConnected ? <LuWifi className="size-3.5" /> : <LuWifiOff className="size-3.5" />}
            {wsConnected ? 'Connected' : 'Disconnected'}
          </span>
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
                className="inline-flex items-center gap-2 rounded-lg bg-green-600 px-4 py-2.5 text-sm font-medium text-white transition hover:bg-green-700 disabled:opacity-40 disabled:cursor-not-allowed"
              >
                <LuPlay className="size-4" /> Start
              </button>
              <button
                onClick={handleStop}
                disabled={serverStatus === 'stopped' || serverStatus === 'stopping'}
                className="inline-flex items-center gap-2 rounded-lg bg-red-600 px-4 py-2.5 text-sm font-medium text-white transition hover:bg-red-700 disabled:opacity-40 disabled:cursor-not-allowed"
              >
                <LuSquare className="size-4" /> Stop
              </button>
              <button
                onClick={handleRestart}
                disabled={serverStatus === 'stopped' || serverStatus === 'restarting'}
                className="inline-flex items-center gap-2 rounded-lg bg-amber-600 px-4 py-2.5 text-sm font-medium text-white transition hover:bg-amber-700 disabled:opacity-40 disabled:cursor-not-allowed"
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

        {/* Trading Symbol */}
        <div className="card">
          <div className="p-4">
            <div className="mb-2 flex items-center gap-2">
              <LuActivity className="size-4 text-orange-500" />
              <span className="text-xs font-medium uppercase text-default-500">Symbol</span>
            </div>
            <p className="text-lg font-bold text-default-900">{eaSymbol || '—'}</p>
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
              <p className="mb-1 text-xs font-medium uppercase text-default-400">WebSocket Server</p>
              <p className="text-sm font-semibold text-default-800">ws://127.0.0.1:8080</p>
              <span className={`mt-1 inline-flex items-center gap-1 text-xs ${wsConnected ? 'text-green-600 dark:text-green-400' : 'text-red-500'}`}>
                <span className={`inline-block size-1.5 rounded-full ${wsConnected ? 'bg-green-500' : 'bg-red-500'}`} />
                {wsConnected ? 'Connected' : 'Disconnected'}
              </span>
            </div>
            <div className="rounded-lg border border-default-100 bg-default-50 p-4 dark:bg-default-100/50">
              <p className="mb-1 text-xs font-medium uppercase text-default-400">MT5 TCP Server</p>
              <p className="text-sm font-semibold text-default-800">127.0.0.1:8081</p>
              <span className={`mt-1 inline-flex items-center gap-1 text-xs ${eaConnected ? 'text-green-600 dark:text-green-400' : 'text-default-400'}`}>
                <span className={`inline-block size-1.5 rounded-full ${eaConnected ? 'bg-green-500' : 'bg-default-300'}`} />
                {eaConnected ? 'EA Connected' : 'Waiting for EA'}
              </span>
            </div>
            <div className="rounded-lg border border-default-100 bg-default-50 p-4 dark:bg-default-100/50">
              <p className="mb-1 text-xs font-medium uppercase text-default-400">Server EA Version</p>
              <p className="text-sm font-semibold text-default-800">v2.01</p>
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
