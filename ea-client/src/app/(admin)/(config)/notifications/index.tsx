import { useState, useEffect, useRef, useCallback } from 'react';
import { LuBell, LuSend, LuSave, LuCheck, LuX, LuMessageCircle, LuShieldAlert, LuPlug } from 'react-icons/lu';
import { getWsUrl } from '@/utils/config';

const WS_URL = getWsUrl();

const NotificationSettings = () => {
  const [wsConnected, setWsConnected] = useState(false);
  const [telegramBotToken, setTelegramBotToken] = useState('');
  const [telegramChatId, setTelegramChatId] = useState('');
  const [notifyOnOpen, setNotifyOnOpen] = useState(true);
  const [notifyOnClose, setNotifyOnClose] = useState(true);
  const [notifyOnDisconnect, setNotifyOnDisconnect] = useState(true);
  const [notifyOnRisk, setNotifyOnRisk] = useState(true);
  const [testResult, setTestResult] = useState<'success' | 'error' | null>(null);
  const [saved, setSaved] = useState(false);
  const wsRef = useRef<WebSocket | null>(null);

  const connectWs = useCallback(() => {
    const ws = new WebSocket(WS_URL);
    ws.onopen = () => {
      setWsConnected(true);
      ws.send(JSON.stringify({ action: 'get_server_config' }));
    };
    ws.onclose = () => { setWsConnected(false); setTimeout(connectWs, 3000); };
    ws.onmessage = (evt) => {
      try {
        const data = JSON.parse(evt.data);
        if (data.type === 'server_config' && data.config) {
          const c = data.config;
          if (c.telegram_bot_token) setTelegramBotToken(c.telegram_bot_token);
          if (c.telegram_chat_id) setTelegramChatId(c.telegram_chat_id);
          if (c.notify_on_open !== undefined) setNotifyOnOpen(c.notify_on_open === 'true');
          if (c.notify_on_close !== undefined) setNotifyOnClose(c.notify_on_close === 'true');
          if (c.notify_on_disconnect !== undefined) setNotifyOnDisconnect(c.notify_on_disconnect === 'true');
          if (c.notify_on_risk !== undefined) setNotifyOnRisk(c.notify_on_risk === 'true');
        }
        if (data.type === 'telegram_notify_test') {
          setTestResult(data.success ? 'success' : 'error');
          setTimeout(() => setTestResult(null), 3000);
        }
        if (data.type === 'config_saved') {
          setSaved(true);
          setTimeout(() => setSaved(false), 2000);
        }
      } catch {}
    };
    wsRef.current = ws;
  }, []);

  useEffect(() => { connectWs(); return () => { wsRef.current?.close(); }; }, [connectWs]);

  const send = (msg: object) => { if (wsRef.current?.readyState === 1) wsRef.current.send(JSON.stringify(msg)); };

  const saveConfig = (key: string, value: string) => {
    send({ action: 'set_server_config', config_key: key, config_value: value });
  };

  const saveAll = () => {
    saveConfig('telegram_bot_token', telegramBotToken);
    saveConfig('telegram_chat_id', telegramChatId);
    saveConfig('notify_on_open', notifyOnOpen.toString());
    saveConfig('notify_on_close', notifyOnClose.toString());
    saveConfig('notify_on_disconnect', notifyOnDisconnect.toString());
    saveConfig('notify_on_risk', notifyOnRisk.toString());
  };

  const testTelegramNotify = () => {
    send({ action: 'test_telegram_notify' });
  };

  const toggles = [
    { label: 'เปิดออเดอร์ใหม่', desc: 'แจ้งเตือนเมื่อมีการเปิดออเดอร์', icon: <LuMessageCircle className="size-4" />, value: notifyOnOpen, onChange: setNotifyOnOpen },
    { label: 'ปิดออเดอร์', desc: 'แจ้งเตือนเมื่อมีการปิดออเดอร์พร้อมผลกำไร/ขาดทุน', icon: <LuCheck className="size-4" />, value: notifyOnClose, onChange: setNotifyOnClose },
    { label: 'EA หลุดการเชื่อมต่อ', desc: 'แจ้งเตือนเมื่อ MT5 หลุดจากเซิร์ฟเวอร์', icon: <LuPlug className="size-4" />, value: notifyOnDisconnect, onChange: setNotifyOnDisconnect },
    { label: 'ถึงขีดจำกัดความเสี่ยง', desc: 'แจ้งเตือนเมื่อ Drawdown ถึงค่าที่ตั้ง', icon: <LuShieldAlert className="size-4" />, value: notifyOnRisk, onChange: setNotifyOnRisk },
  ];

  return (
    <main className="space-y-5">
      <div className="flex items-center justify-between">
        <div>
          <h4 className="text-lg font-semibold text-default-900">🔔 การแจ้งเตือน (Notifications)</h4>
          <p className="mt-1 text-sm text-default-500">ตั้งค่าการแจ้งเตือนผ่าน Telegram Bot</p>
        </div>
        <div className={`rounded-full px-3 py-1 text-xs font-medium ${wsConnected ? 'bg-green-100 dark:bg-green-500/20 text-green-600' : 'bg-red-100 dark:bg-red-500/20 text-red-600'}`}>
          {wsConnected ? 'เชื่อมต่อแล้ว' : 'ไม่เชื่อมต่อ'}
        </div>
      </div>

      {/* Telegram Setup */}
      <div className="card !p-6 space-y-4">
        <div>
          <h5 className="text-sm font-semibold text-default-900 mb-2 flex items-center gap-2">
            <div className="size-8 rounded-lg bg-[#229ED9]/10 flex items-center justify-center"><LuBell className="size-4 text-[#229ED9]" /></div>
            Telegram Bot Setup
          </h5>
          <p className="text-xs text-default-500 mb-2">
            ทักแชท <a href="https://t.me/BotFather" target="_blank" rel="noreferrer" className="text-[#229ED9] underline">@BotFather</a> เพื่อสร้างบอทและรับ Token<br/>
            และสามารถรับ Chat ID ได้จาก <a href="https://t.me/userinfobot" target="_blank" rel="noreferrer" className="text-[#229ED9] underline">@userinfobot</a>
          </p>
        </div>
        
        <div className="flex gap-2">
          <input
            type="password"
            value={telegramBotToken}
            onChange={(e) => setTelegramBotToken(e.target.value)}
            placeholder="Bot Token (เช่น 123456:ABC-DEF...) 🔑"
            className="flex-1 px-4 py-2.5 rounded-xl bg-default-100 dark:bg-default-200/10 text-sm text-default-900 border border-default-200 dark:border-default-300/10 focus:outline-none focus:ring-2 focus:ring-[#229ED9]/30"
          />
        </div>

        <div className="flex gap-2">
          <input
            type="text"
            value={telegramChatId}
            onChange={(e) => setTelegramChatId(e.target.value)}
            placeholder="Chat ID (เช่น 123456789) 💬"
            className="flex-1 px-4 py-2.5 rounded-xl bg-default-100 dark:bg-default-200/10 text-sm text-default-900 border border-default-200 dark:border-default-300/10 focus:outline-none focus:ring-2 focus:ring-[#229ED9]/30"
          />
          <button onClick={testTelegramNotify} className="btn px-4 py-2.5 rounded-xl bg-[#229ED9] text-white hover:bg-[#1f8fc4] text-sm font-medium flex items-center gap-2 border-none">
            <LuSend className="size-4" /> ทดสอบ
          </button>
        </div>

        {testResult && (
          <div className={`px-4 py-2 rounded-lg text-sm font-medium flex items-center gap-2 ${testResult === 'success' ? 'bg-green-50 dark:bg-green-500/10 text-green-600' : 'bg-red-50 dark:bg-red-500/10 text-red-600'}`}>
            {testResult === 'success' ? <><LuCheck className="size-4" /> ส่งข้อความทดสอบเข้าแชทสำเร็จ!</> : <><LuX className="size-4" /> ส่งไม่สำเร็จ ตรวจสอบ Token หรือ Chat ID อีกครั้ง</>}
          </div>
        )}
      </div>

      {/* Event Toggles */}
      <div className="card !p-6">
        <h5 className="text-sm font-semibold text-default-900 mb-4">เหตุการณ์ที่จะแจ้งเตือน</h5>
        <div className="space-y-4">
          {toggles.map((t, i) => (
            <div key={i} className="flex items-center justify-between p-3 rounded-xl bg-default-50 dark:bg-default-200/5">
              <div className="flex items-center gap-3">
                <div className="size-8 rounded-lg bg-primary/10 flex items-center justify-center text-primary">{t.icon}</div>
                <div>
                  <p className="text-sm font-semibold text-default-900">{t.label}</p>
                  <p className="text-xs text-default-500">{t.desc}</p>
                </div>
              </div>
              <button
                onClick={() => t.onChange(!t.value)}
                className={`relative w-11 h-6 rounded-full transition-colors ${t.value ? 'bg-[#229ED9]' : 'bg-default-300 dark:bg-default-200/30'}`}
              >
                <span className={`absolute top-0.5 left-0.5 size-5 rounded-full bg-white shadow transition-transform ${t.value ? 'translate-x-5' : ''}`} />
              </button>
            </div>
          ))}
        </div>
      </div>

      {/* Save */}
      <button onClick={saveAll} className="btn w-full py-3 rounded-xl bg-[#229ED9] text-white hover:bg-[#1f8fc4] text-sm font-semibold flex items-center justify-center gap-2 border-none shadow-md shadow-[#229ED9]/20">
        {saved ? <><LuCheck className="size-4" /> บันทึกแล้ว!</> : <><LuSave className="size-4" /> บันทึกการตั้งค่า</>}
      </button>
    </main>
  );
};

export default NotificationSettings;
