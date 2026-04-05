import { useState, useEffect, useRef } from 'react';
import { LuMail, LuKey, LuSave, LuExternalLink, LuEye, LuEyeOff } from 'react-icons/lu';
import { getWsUrl } from '@/utils/config';

const EmailSettings = () => {
  const [email, setEmail] = useState('');
  const [appPassword, setAppPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [connected, setConnected] = useState(false);
  const [saved, setSaved] = useState(false);
  const wsRef = useRef<WebSocket | null>(null);

  useEffect(() => {
    const WS_URL = getWsUrl();
    const ws = new WebSocket(WS_URL);
    
    ws.onopen = () => {
      setConnected(true);
      ws.send(JSON.stringify({ action: 'get_server_config' }));
    };
    
    ws.onclose = () => setConnected(false);

    ws.onmessage = (evt) => {
      try {
        const data = JSON.parse(evt.data);
        if (data.type === 'server_config' && data.config) {
          const c = data.config;
          if (c.gmail_address) setEmail(c.gmail_address);
          if (c.gmail_app_password) setAppPassword(c.gmail_app_password);
        }
        if (data.type === 'config_saved') {
          setSaved(true);
          setTimeout(() => setSaved(false), 2000);
        }
      } catch (e) {}
    };

    wsRef.current = ws;
    return () => ws.close();
  }, []);

  const saveConfig = () => {
    if (!wsRef.current || wsRef.current.readyState !== WebSocket.OPEN) return;
    wsRef.current.send(JSON.stringify({ action: 'set_server_config', config_key: 'gmail_address', config_value: email }));
    wsRef.current.send(JSON.stringify({ action: 'set_server_config', config_key: 'gmail_app_password', config_value: appPassword }));
  };

  return (
    <div className="space-y-6 animate-in fade-in slide-in-from-bottom-4 duration-500">
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-xl font-bold text-default-900 tracking-tight">📧 ตั้งค่า Email</h2>
          <p className="mt-1 text-sm text-default-500">บันทึกข้อมูล Gmail สำหรับส่งการแจ้งเตือน</p>
        </div>
        <div className={`rounded-full px-3 py-1 text-xs font-medium border ${connected ? 'bg-emerald-500/10 text-emerald-600 border-emerald-500/20' : 'bg-red-500/10 text-red-600 border-red-500/20'}`}>
          {connected ? '🟢 EA Server เชื่อมต่อแล้ว' : '🔴 ขาดการเชื่อมต่อ'}
        </div>
      </div>

      <div className="card p-6 space-y-6">
        <div className="grid gap-6 md:grid-cols-2">
          
          <div className="space-y-2">
            <label className="text-sm font-semibold text-default-900 mb-1 flex items-center gap-2">
              <div className="size-8 rounded-lg bg-blue-500/10 flex items-center justify-center"><LuMail className="size-4 text-blue-500" /></div>
              Gmail Address
            </label>
            <input
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              placeholder="example@gmail.com"
              className="w-full px-4 py-2.5 rounded-xl bg-background border border-default-200 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500/50 transition-all font-medium"
            />
          </div>

          <div className="space-y-2">
            <label className="text-sm font-semibold text-default-900 mb-1 flex items-center gap-2">
              <div className="size-8 rounded-lg bg-orange-500/10 flex items-center justify-center"><LuKey className="size-4 text-orange-500" /></div>
              App Password
            </label>
            <div className="relative">
              <input
                type={showPassword ? "text" : "password"}
                value={appPassword}
                onChange={(e) => setAppPassword(e.target.value)}
                placeholder="xxxx xxxx xxxx xxxx"
                className="w-full px-4 py-2.5 pr-10 rounded-xl bg-background border border-default-200 text-sm focus:outline-none focus:ring-2 focus:ring-orange-500/50 transition-all font-mono"
              />
              <button 
                type="button"
                onClick={() => setShowPassword(!showPassword)}
                className="absolute right-3 top-1/2 -translate-y-1/2 text-default-400 hover:text-default-700"
              >
                {showPassword ? <LuEyeOff size={18} /> : <LuEye size={18} />}
              </button>
            </div>
            <p className="text-xs text-default-400 mt-1">รหัสผ่าน 16 หลักจากการตั้งค่า App Passwords ของ Google</p>
          </div>
          
        </div>

        <div className="pt-4 border-t border-default-100 flex flex-wrap items-center gap-3">
          <button
            onClick={saveConfig}
            className="px-6 py-2.5 rounded-xl font-bold text-sm text-white shadow-lg bg-blue-600 hover:bg-blue-700 active:scale-95 transition-all flex items-center gap-2"
          >
            <LuSave className="size-4" />
            {saved ? 'บันทึกสำเร็จ ✅' : 'บันทึกข้อมูล'}
          </button>
          
          <a
            href="https://mail.google.com"
            target="_blank"
            rel="noopener noreferrer"
            className="px-6 py-2.5 rounded-xl font-bold text-sm bg-default-100 text-default-700 hover:bg-default-200 active:scale-95 transition-all flex items-center gap-2"
          >
            <LuExternalLink className="size-4" />
            เปิด Gmail
          </a>
        </div>
      </div>
    </div>
  );
};

export default EmailSettings;
