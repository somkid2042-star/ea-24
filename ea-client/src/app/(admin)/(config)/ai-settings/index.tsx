import { useState, useRef, useCallback, useEffect } from 'react';
import { LuCheck, LuX, LuSparkles, LuKey, LuZap, LuChevronDown, LuChevronUp, LuPlus, LuTrash2, LuMail, LuExternalLink } from 'react-icons/lu';
import { openUrl as tauriOpen } from '@tauri-apps/plugin-opener';
import { getWsUrl } from '@/utils/config';

const WS_URL = getWsUrl();

interface AiModel {
  id: string;
  name: string;
}

const AiSettings = () => {
  const [wsConnected, setWsConnected] = useState(false);
  const [selectedModel, setSelectedModel] = useState('');
  const [models, setModels] = useState<AiModel[]>([]);
  const [testResult, setTestResult] = useState<{ success: boolean; message: string } | null>(null);
  const [testing, setTesting] = useState(false);
  const [emails, setEmails] = useState<{address: string, password: string, apiKey: string}[]>([{address: '', password: '', apiKey: ''}]);
  const [showEmailSection, setShowEmailSection] = useState(false);
  const [emailSaved, setEmailSaved] = useState(false);

  const hideEmailTimeoutRef = useRef<ReturnType<typeof setTimeout> | null>(null);
  const wsRef = useRef<WebSocket | null>(null);

  // Auto-hide feature for Email/Account section
  const resetEmailHideTimer = useCallback(() => {
    if (hideEmailTimeoutRef.current) clearTimeout(hideEmailTimeoutRef.current);
    hideEmailTimeoutRef.current = setTimeout(() => {
      setShowEmailSection(false);
    }, 60000); // Auto hide after 60 seconds
  }, []);

  useEffect(() => {
    if (showEmailSection) resetEmailHideTimer();
    return () => { if (hideEmailTimeoutRef.current) clearTimeout(hideEmailTimeoutRef.current); };
  }, [showEmailSection, resetEmailHideTimer]);

  const connectWs = useCallback(() => {
    const ws = new WebSocket(WS_URL);
    ws.onopen = () => {
      setWsConnected(true);
      ws.send(JSON.stringify({ action: 'get_server_config' }));
      ws.send(JSON.stringify({ action: 'get_ai_models' }));
    };
    ws.onclose = () => { setWsConnected(false); setTimeout(connectWs, 3000); };
    ws.onmessage = (evt) => {
      try {
        const data = JSON.parse(evt.data);
        if (data.type === 'server_config' && data.config) {
          const c = data.config;
          if (c.gemini_model) setSelectedModel(c.gemini_model);
          if (c.gmail_address || c.gmail_app_password || c.gemini_api_key) {
            const addrs = (c.gmail_address || '').split(',').map((x: string) => x.trim());
            const passes = (c.gmail_app_password || '').split(',').map((x: string) => x.trim());
            const keys = (c.gemini_api_key || '').split(',').map((x: string) => x.trim());
            const length = Math.max(addrs.length, passes.length, keys.length, 1);
            const loaded = [];
            for (let i = 0; i < length; i++) {
              loaded.push({ 
                address: addrs[i] || '', 
                password: passes[i] || '',
                apiKey: keys[i] || ''
              });
            }
            if (loaded.length > 0) setEmails(loaded);
            else setEmails([{address: '', password: '', apiKey: ''}]);
          }
        }
        if (data.type === 'ai_models') {
          setModels(data.models || []);
        }
        if (data.type === 'ai_test_result') {
          if (testTimeoutRef.current) { clearTimeout(testTimeoutRef.current); testTimeoutRef.current = null; }
          setTesting(false);
          setTestResult({ success: data.success, message: data.message });
          setTimeout(() => setTestResult(null), 5000);
        }
        if (data.type === 'config_saved') {
          setEmailSaved(true);
          setTimeout(() => setEmailSaved(false), 2000);
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

  const saveEmailConfig = (list?: typeof emails) => {
    const listToSave = list || emails;
    const validEmails = listToSave.filter(e => e.address.trim() || e.password.trim() || e.apiKey.trim());
    const toSave = validEmails.length > 0 ? validEmails : [{address: '', password: '', apiKey: ''}];
    saveConfig('gmail_address', toSave.map(e => e.address).join(','));
    saveConfig('gmail_app_password', toSave.map(e => e.password).join(','));
    saveConfig('gemini_api_key', toSave.map(e => e.apiKey).join(','));
  };

  const moveEmailUp = (index: number) => {
    if (index === 0) return;
    const next = [...emails];
    const temp = next[index - 1];
    next[index - 1] = next[index];
    next[index] = temp;
    setEmails(next);
    saveEmailConfig(next);
  };

  const moveEmailDown = (index: number) => {
    if (index === emails.length - 1) return;
    const next = [...emails];
    const temp = next[index + 1];
    next[index + 1] = next[index];
    next[index] = temp;
    setEmails(next);
    saveEmailConfig(next);
  };

  const testTimeoutRef = useRef<ReturnType<typeof setTimeout> | null>(null);
  const testAi = () => {
    setTesting(true); setTestResult(null);
    const orderedKeys = emails.map(e => e.apiKey).filter(k => k.trim());
      
    if (orderedKeys.length > 0) {
      saveConfig('gemini_api_key', orderedKeys.join(','));
    }
    saveConfig('gemini_model', selectedModel);
    setTimeout(() => send({ action: 'test_ai' }), 300);
    // Timeout 15s — ถ้า server ไม่ตอบกลับให้แสดง error
    if (testTimeoutRef.current) clearTimeout(testTimeoutRef.current);
    testTimeoutRef.current = setTimeout(() => {
      setTesting(prev => {
        if (prev) {
          setTestResult({ success: false, message: 'หมดเวลา — Server ไม่ตอบกลับภายใน 15 วินาที (ตรวจสอบว่า ea-server รันอยู่หรือไม่)' });
        }
        return false;
      });
    }, 15000);
  };

  return (
    <main className="space-y-5">
      <div className="flex items-center justify-between">
        <div>
          <h4 className="text-lg font-semibold text-default-900">🔑 จัดการ API Key ทั้งหมด</h4>
          <p className="mt-1 text-sm text-default-500">จัดการหน้ากำหนดให้ AI ใช้ API Key อันไหน และตั้งค่า Google Gemini โมเดล</p>
        </div>
        <div className={`rounded-full px-3 py-1 text-xs font-medium ${wsConnected ? 'bg-green-100 dark:bg-green-500/20 text-green-600' : 'bg-red-100 dark:bg-red-500/20 text-red-600'}`}>
          {wsConnected ? 'เชื่อมต่อแล้ว' : 'ไม่เชื่อมต่อ'}
        </div>
      </div>

      {/* Global Setting (Model Selection & Test) */}
      <div className="card !p-6 space-y-4">
        <div className="flex items-center justify-between">
          <div>
            <h5 className="text-sm font-semibold text-default-900 mb-1 flex items-center gap-2">
              <div className="size-8 rounded-lg bg-violet-500/10 flex items-center justify-center"><LuSparkles className="size-4 text-violet-500" /></div>
              ตั้งค่าระบบ AI
            </h5>
            <p className="text-xs text-default-500">
              เลือกรุ่นปัญญาประดิษฐ์ (โมเดล) สำหรับการวิเคราะห์ตลาด และทดสอบการเชื่อมต่อ
            </p>
          </div>
        </div>

        {/* Model Selection */}
        <div className="flex gap-2 items-center">
          <div className="relative flex-1">
            <select
              value={selectedModel}
              onChange={(e) => setSelectedModel(e.target.value)}
              className="w-full px-4 py-2.5 rounded-xl bg-default-100 dark:bg-default-200/10 text-sm text-default-900 border border-default-200 dark:border-default-300/10 focus:outline-none focus:ring-2 focus:ring-violet-500/30 appearance-none cursor-pointer"
            >
              <option value="">เลือกโมเดล (ค่าเริ่มต้น: Gemini 2.5 Flash)</option>
              {models.map(m => (
                <option key={m.id} value={m.id}>{m.name}</option>
              ))}
            </select>
            <LuChevronDown className="size-4 absolute right-3 top-1/2 -translate-y-1/2 text-default-400 pointer-events-none" />
          </div>
          <button onClick={testAi} disabled={testing || !emails.some(e => e.apiKey.trim())}
            className="btn px-4 py-2.5 rounded-xl bg-violet-600 text-white hover:bg-violet-700 text-sm font-medium flex items-center gap-2 border-none disabled:opacity-50">
            {testing ? <><LuSparkles className="size-4 animate-spin" /> กำลังทดสอบ...</> : <><LuZap className="size-4" /> ทดสอบ</>}
          </button>
        </div>

        {testResult && (
          <div className={`px-4 py-3 rounded-xl text-sm font-medium flex items-center gap-2 ${testResult.success ? 'bg-green-50 dark:bg-green-500/10 text-green-600' : 'bg-red-50 dark:bg-red-500/10 text-red-600'}`}>
            {testResult.success ? <><LuCheck className="size-4" /> ✅ AI ตอบกลับ: {testResult.message}</> : <><LuX className="size-4" /> ❌ {testResult.message}</>}
          </div>
        )}
      </div>

      {/* Email Setup */}
      <div className="card !p-6 space-y-4 mt-6">
        <div className="flex items-center justify-between">
          <div>
            <h5 className="text-sm font-semibold text-default-900 mb-1 flex items-center gap-2">
              <div className="size-8 rounded-lg bg-blue-500/10 flex items-center justify-center"><LuMail className="size-4 text-blue-500" /></div>
              จัดการบัญชีและ API Key
              <span className="text-xs font-normal text-default-400">({emails.filter(e => e.address.trim() || e.password.trim() || e.apiKey.trim()).length} บัญชี)</span>
              {emailSaved && <span className="text-xs font-semibold text-green-500 ml-2 animate-in fade-in">บันทึกสำเร็จ ✅</span>}
            </h5>
            <p className="text-xs text-default-500">
              จดบันทึกบัญชีของ Google พร้อมกับ API Key ประจำบัญชีเพื่อให้ AI นำไปใช้งาน และสั่งล็อกอินเพื่อสร้าง Key ใหม่ได้ทันที
            </p>
          </div>
          <button
            onClick={() => setShowEmailSection(!showEmailSection)}
            className="flex items-center gap-1.5 text-xs font-medium text-blue-500 hover:text-blue-600 px-3 py-1.5 rounded-lg hover:bg-blue-500/10 transition-colors"
          >
            {showEmailSection ? <><LuChevronUp className="size-4" /> ซ่อน</> : <><LuChevronDown className="size-4" /> แสดง</>}
          </button>
        </div>

        {showEmailSection && (
        <div className="space-y-4 animate-in fade-in slide-in-from-top-2 bg-default-50 dark:bg-default-100/5 p-4 rounded-xl border border-default-200/50">
          {emails.map((acc, i) => (
            <div 
              key={i} 
              className="flex gap-3 pb-3 border-b border-default-200/50 last:border-0 last:pb-0 items-center group"
            >
              <div className="flex flex-col gap-0.5 shrink-0 -ml-1">
                <button 
                  onClick={() => moveEmailUp(i)}
                  disabled={i === 0}
                  className="p-0.5 text-default-400 hover:text-blue-500 hover:bg-blue-500/10 rounded disabled:opacity-20 disabled:hover:bg-transparent disabled:hover:text-default-400 transition-colors"
                  title="เลื่อนขึ้น"
                >
                  <LuChevronUp className="size-3.5" />
                </button>
                <button 
                  onClick={() => moveEmailDown(i)}
                  disabled={i === emails.length - 1}
                  className="p-0.5 text-default-400 hover:text-blue-500 hover:bg-blue-500/10 rounded disabled:opacity-20 disabled:hover:bg-transparent disabled:hover:text-default-400 transition-colors"
                  title="เลื่อนลง"
                >
                  <LuChevronDown className="size-3.5" />
                </button>
              </div>
              <div className="w-8 h-8 rounded-full bg-blue-500/10 flex items-center justify-center shrink-0" title="Email">
                <LuMail className="size-4 text-blue-500" />
              </div>
              <div className="flex-1">
                <input
                  type="text"
                  value={acc.address}
                  onChange={(e) => {
                    resetEmailHideTimer();
                    const next = [...emails];
                    next[i].address = e.target.value;
                    setEmails(next);
                  }}
                  onKeyDown={(e) => { if (e.key === 'Enter') saveEmailConfig(); }}
                  placeholder={`Email #${i + 1}`}
                  className="w-full px-4 py-2.5 rounded-xl bg-default-100 dark:bg-default-200/10 text-default-900 border border-default-200 dark:border-default-300/10 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500/50 transition-all font-medium"
                />
              </div>

              <div className="w-8 h-8 rounded-full bg-violet-500/10 flex items-center justify-center shrink-0 ml-1" title="API Key">
                <LuKey className="size-4 text-violet-500" />
              </div>
              <div className="flex-[1.5] relative">
                <input
                  type="text"
                  value={acc.apiKey}
                  onChange={(e) => {
                    resetEmailHideTimer();
                    const next = [...emails];
                    next[i].apiKey = e.target.value;
                    setEmails(next);
                  }}
                  onKeyDown={(e) => { if (e.key === 'Enter') saveEmailConfig(); }}
                  placeholder={`AI API Key #${i + 1}`}
                  className="w-full px-4 py-2.5 rounded-xl bg-default-100 dark:bg-default-200/10 text-default-900 border border-default-200 dark:border-default-300/10 text-sm focus:outline-none focus:ring-2 focus:ring-violet-500/50 transition-all font-mono"
                />
              </div>

              <div className="flex items-center gap-2 ml-1">
                <button
                  onClick={() => tauriOpen(`https://accounts.google.com/v3/signin/identifier?authuser=0&continue=https%3A%2F%2Faistudio.google.com%2Fapikey&ec=GAlAwAE&flowEntry=AddSession&flowName=GlifWebSignIn&hl=th&service=accountsettings&Email=${encodeURIComponent(acc.address)}`)}
                  className="h-10 px-4 rounded-xl bg-blue-500/10 hover:bg-blue-500/20 text-blue-600 font-bold text-xs flex items-center justify-center shrink-0 transition-colors gap-2"
                  title="ล็อกอินบัญชีนี้ในเบราว์เซอร์"
                >
                  <LuExternalLink className="size-4" /> Login
                </button>
                {emails.length > 1 && (
                  <button
                    onClick={() => {
                      if (window.confirm('ยืนยัน: คุณต้องการลบบัญชีนี้ออกจากระบบใช่หรือไม่?')) {
                        setEmails(emails.filter((_, j) => j !== i));
                      }
                    }}
                    className="h-10 w-10 rounded-xl bg-red-500/10 hover:bg-red-500/20 text-red-500 flex items-center justify-center shrink-0 transition-colors"
                    title="ลบบัญชีนี้"
                  >
                    <LuTrash2 className="size-4" />
                  </button>
                )}
              </div>
            </div>
          ))}
          <button
            onClick={() => {
              resetEmailHideTimer();
              setEmails([...emails, {address: '', password: '', apiKey: ''}]);
            }}
            className="flex items-center gap-2 text-xs text-blue-500 hover:text-blue-600 font-medium px-2 py-1.5 rounded-lg hover:bg-blue-500/10 transition-colors"
          >
            <LuPlus className="size-3.5" /> เพิ่มบัญชี
          </button>
        </div>
        )}
      </div>

    </main>
  );
};

export default AiSettings;
