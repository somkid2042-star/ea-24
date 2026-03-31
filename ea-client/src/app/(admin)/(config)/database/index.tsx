import { useState, useEffect, useRef, useCallback } from 'react';
import {
  LuDatabase,
  LuSave,
  LuRefreshCw,
  LuHardDrive,
  LuActivity,
  LuTrendingUp,
  LuTrash2,
  LuCircleCheck,
} from 'react-icons/lu';

type DbStats = {
  total_ticks: number;
  total_trades: number;
  latest_tick_time: string;
  latest_trade_time: string;
  db_size_bytes: number;
  db_path: string;
};

import { getWsUrl } from '@/utils/config';

type ServerConfig = Record<string, string>;

const WS_URL = getWsUrl();

const formatBytes = (bytes: number) => {
  if (bytes === 0) return '0 B';
  const k = 1024;
  const sizes = ['B', 'KB', 'MB', 'GB'];
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  return `${(bytes / Math.pow(k, i)).toFixed(1)} ${sizes[i]}`;
};

const DatabaseSettings = () => {
  const [wsConnected, setWsConnected] = useState(false);
  const [stats, setStats] = useState<DbStats | null>(null);
  const [config, setConfig] = useState<ServerConfig>({});
  const [saving, setSaving] = useState(false);
  const [vacuuming, setVacuuming] = useState(false);
  const [saveSuccess, setSaveSuccess] = useState(false);
  const wsRef = useRef<WebSocket | null>(null);

  const connectWs = useCallback(() => {
    const ws = new WebSocket(WS_URL);

    ws.onopen = () => {
      setWsConnected(true);
      // Request initial data
      ws.send(JSON.stringify({ action: 'get_db_stats' }));
      ws.send(JSON.stringify({ action: 'get_server_config' }));
    };

    ws.onclose = () => {
      setWsConnected(false);
      setTimeout(connectWs, 3000);
    };

    ws.onmessage = (evt) => {
      try {
        const data = JSON.parse(evt.data);

        if (data.type === 'db_stats') {
          setStats(data.stats);
        }
        if (data.type === 'server_config') {
          setConfig(data.config);
        }
        if (data.type === 'config_saved') {
          setSaving(false);
          setSaveSuccess(true);
          setTimeout(() => setSaveSuccess(false), 2000);
        }
        if (data.type === 'vacuum_result') {
          setVacuuming(false);
          if (data.stats) setStats(data.stats);
        }
      } catch {
        // ignore
      }
    };

    wsRef.current = ws;
  }, []);

  useEffect(() => {
    connectWs();
    return () => { wsRef.current?.close(); };
  }, [connectWs]);

  // Auto-refresh stats every 5 seconds
  useEffect(() => {
    const interval = setInterval(() => {
      if (wsRef.current?.readyState === 1) {
        wsRef.current.send(JSON.stringify({ action: 'get_db_stats' }));
      }
    }, 5000);
    return () => clearInterval(interval);
  }, []);

  const handleSaveConfig = (key: string, value: string) => {
    if (wsRef.current?.readyState === 1) {
      setSaving(true);
      wsRef.current.send(JSON.stringify({
        action: 'set_server_config',
        config_key: key,
        config_value: value,
      }));
      setConfig(prev => ({ ...prev, [key]: value }));
    }
  };

  const handleVacuum = () => {
    if (wsRef.current?.readyState === 1) {
      setVacuuming(true);
      wsRef.current.send(JSON.stringify({ action: 'vacuum_db' }));
    }
  };

  const handleSaveAll = () => {
    Object.entries(config).forEach(([key, value]) => {
      handleSaveConfig(key, value);
    });
  };

  return (
    <main className="space-y-6">
      {/* Page Header */}
      <div className="flex items-center justify-between">
        <div>
          <h4 className="text-lg font-semibold text-default-900">Database Settings</h4>
          <p className="mt-1 text-sm text-default-500">
            SQLite database — real-time tick logging & server configuration
          </p>
        </div>
      </div>


      {/* Database Stats */}
      <div className="grid grid-cols-2 gap-4 md:grid-cols-4">
        <div className="card">
          <div className="p-4">
            <div className="mb-2 flex items-center gap-2">
              <LuActivity className="size-4 text-blue-500" />
              <span className="text-xs font-medium uppercase text-default-500">Total Ticks</span>
            </div>
            <p className="text-lg font-bold tabular-nums text-default-900">
              {stats ? stats.total_ticks.toLocaleString() : '—'}
            </p>
            <p className="mt-0.5 text-[10px] text-default-400">
              Last: {stats?.latest_tick_time || '—'}
            </p>
          </div>
        </div>

        <div className="card">
          <div className="p-4">
            <div className="mb-2 flex items-center gap-2">
              <LuTrendingUp className="size-4 text-green-500" />
              <span className="text-xs font-medium uppercase text-default-500">Total Trades</span>
            </div>
            <p className="text-lg font-bold tabular-nums text-default-900">
              {stats ? stats.total_trades.toLocaleString() : '—'}
            </p>
            <p className="mt-0.5 text-[10px] text-default-400">
              Last: {stats?.latest_trade_time || '—'}
            </p>
          </div>
        </div>

        <div className="card">
          <div className="p-4">
            <div className="mb-2 flex items-center gap-2">
              <LuHardDrive className="size-4 text-purple-500" />
              <span className="text-xs font-medium uppercase text-default-500">DB Size</span>
            </div>
            <p className="text-lg font-bold tabular-nums text-default-900">
              {stats ? formatBytes(stats.db_size_bytes) : '—'}
            </p>
          </div>
        </div>

        <div className="card">
          <div className="p-4">
            <div className="mb-2 flex items-center gap-2">
              <LuDatabase className="size-4 text-orange-500" />
              <span className="text-xs font-medium uppercase text-default-500">DB Path</span>
            </div>
            <p className="truncate text-sm font-medium text-default-900" title={stats?.db_path}>
              {stats?.db_path || '—'}
            </p>
          </div>
        </div>
      </div>

      {/* Database Configuration */}
      <div className="card">
        <div className="p-5">
          <div className="mb-4 flex items-center gap-2">
            <LuDatabase className="size-5 text-primary" />
            <h5 className="text-base font-semibold text-default-900">Database Configuration</h5>
          </div>
          <div className="grid grid-cols-1 gap-4 md:grid-cols-2">
            <div>
              <label className="mb-1.5 block text-sm font-medium text-default-700">Database Path</label>
              <input
                type="text"
                value={config.db_path || ''}
                onChange={e => setConfig(prev => ({ ...prev, db_path: e.target.value }))}
                className="form-input"
              />
            </div>
            <div>
              <label className="mb-1.5 block text-sm font-medium text-default-700">Tick Retention (days)</label>
              <input
                type="number"
                value={config.tick_retention_days || ''}
                onChange={e => setConfig(prev => ({ ...prev, tick_retention_days: e.target.value }))}
                className="form-input w-full rounded-md border border-default-200 px-3 py-2.5 text-sm text-default-900 focus:border-primary focus:ring-primary"
              />
            </div>
            <div>
              <label className="mb-1.5 block text-sm font-medium text-default-700">Backup Interval (hours)</label>
              <input
                type="number"
                value={config.backup_interval_hours || ''}
                onChange={e => setConfig(prev => ({ ...prev, backup_interval_hours: e.target.value }))}
                className="form-input w-full rounded-md border border-default-200 px-3 py-2.5 text-sm text-default-900 focus:border-primary focus:ring-primary"
              />
            </div>
          </div>
          <div className="mt-4 flex items-center gap-3">
            <button
              onClick={handleSaveAll}
              disabled={saving || !wsConnected}
              className="btn bg-primary/10 text-primary hover:bg-primary hover:text-white disabled:opacity-40"
            >
              {saveSuccess ? (
                <><LuCircleCheck className="size-4" /> Saved!</>
              ) : saving ? (
                <><LuRefreshCw className="size-4 animate-spin" /> Saving...</>
              ) : (
                <><LuSave className="size-4" /> Save Settings</>
              )}
            </button>
            <button
              onClick={handleVacuum}
              disabled={vacuuming || !wsConnected}
              className="btn bg-primary/10 text-primary hover:bg-primary hover:text-white disabled:opacity-40"
            >
              {vacuuming ? (
                <><LuRefreshCw className="size-4 animate-spin" /> Optimizing...</>
              ) : (
                <><LuTrash2 className="size-4" /> Optimize DB (VACUUM)</>
              )}
            </button>
          </div>
        </div>
      </div>

      {/* Port Configuration (read-only from server) */}
      <div className="card">
        <div className="p-5">
          <div className="mb-4 flex items-center gap-2">
            <LuActivity className="size-5 text-primary" />
            <h5 className="text-base font-semibold text-default-900">Server Ports</h5>
          </div>
          <div className="grid grid-cols-1 gap-4 md:grid-cols-3">
            <div className="rounded-xl border border-default-200/60 dark:border-default-300/10 bg-default-50/50 dark:bg-default-200/5 p-4">
              <p className="mb-1 text-xs font-medium uppercase text-default-400">WebSocket Port</p>
              <p className="text-sm font-semibold text-default-800">{config.ws_port || '8080'}</p>
              <span className="mt-1 text-[10px] text-default-400">Dashboard communication</span>
            </div>
            <div className="rounded-lg border border-default-100 bg-default-50 p-4 dark:bg-default-100/50">
              <p className="mb-1 text-xs font-medium uppercase text-default-400">TCP Port</p>
              <p className="text-sm font-semibold text-default-800">{config.tcp_port || '8081'}</p>
              <span className="mt-1 text-[10px] text-default-400">MT5 EA connection</span>
            </div>
            <div className="rounded-lg border border-default-100 bg-default-50 p-4 dark:bg-default-100/50">
              <p className="mb-1 text-xs font-medium uppercase text-default-400">HTTP Port</p>
              <p className="text-sm font-semibold text-default-800">{config.http_port || '4173'}</p>
              <span className="mt-1 text-[10px] text-default-400">Web dashboard serving</span>
            </div>
          </div>
        </div>
      </div>
    </main>
  );
};

export default DatabaseSettings;
