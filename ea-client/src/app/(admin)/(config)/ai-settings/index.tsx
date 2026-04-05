import { useState, useRef, useCallback, useEffect } from 'react';
import { LuCheck, LuX, LuSparkles, LuKey, LuZap, LuChevronDown, LuChevronUp, LuPlus, LuTrash2, LuLoader, LuMail, LuExternalLink } from 'react-icons/lu';
import { getWsUrl } from '@/utils/config';

const WS_URL = getWsUrl();

interface AiModel {
  id: string;
  name: string;
}

const AiSettings = () => {
  const [wsConnected, setWsConnected] = useState(false);
  const [apiKeys, setApiKeys] = useState<string[]>(['']);
  const [activeIndex, setActiveIndex] = useState(0);
  const [showKeysSection, setShowKeysSection] = useState(false);
  const [keyStatus, setKeyStatus] = useState<Record<number, { valid: boolean; name: string; checking: boolean }>>({});
  const [selectedModel, setSelectedModel] = useState('');
  const [models, setModels] = useState<AiModel[]>([]);
  const [testResult, setTestResult] = useState<{ success: boolean; message: string } | null>(null);
  const [testing, setTesting] = useState(false);
  const [emails, setEmails] = useState<{address: string, password: string}[]>([{address: '', password: ''}]);
  const [showEmailSection, setShowEmailSection] = useState(false);
  const [emailSaved, setEmailSaved] = useState(false);

  const hideTimeoutRef = useRef<ReturnType<typeof setTimeout> | null>(null);
  const hideEmailTimeoutRef = useRef<ReturnType<typeof setTimeout> | null>(null);
  const wsRef = useRef<WebSocket | null>(null);

  // Auto-hide feature when showKeysSection is true
  const resetHideTimer = useCallback(() => {
    if (hideTimeoutRef.current) clearTimeout(hideTimeoutRef.current);
    hideTimeoutRef.current = setTimeout(() => {
      setShowKeysSection(false);
    }, 60000); // Auto hide after 60 seconds
  }, []);

  useEffect(() => {
    if (showKeysSection) resetHideTimer();
    return () => { if (hideTimeoutRef.current) clearTimeout(hideTimeoutRef.current); };
  }, [showKeysSection, resetHideTimer]);

  // Auto-hide feature for Email section
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

  // Validate API key by calling Google's API
  const validateKey = async (index: number, key: string) => {
    setKeyStatus(prev => ({ ...prev, [index]: { valid: false, name: '', checking: true } }));
    try {
      const res = await fetch(`https://generativelanguage.googleapis.com/v1beta/models?key=${key}`);
      if (res.ok) {
        // Key is valid - extract project info from key format
        const data = await res.json();
        const modelCount = data.models?.length || 0;
        const keyPreview = `${key.slice(0, 8)}...${key.slice(-4)}`;
        setKeyStatus(prev => ({ ...prev, [index]: { valid: true, name: `ใช้งานได้ (${modelCount} โมเดล) • ${keyPreview}`, checking: false } }));
      } else {
        const err = await res.json().catch(() => null);
        const msg = err?.error?.message || `HTTP ${res.status}`;
        setKeyStatus(prev => ({ ...prev, [index]: { valid: false, name: msg, checking: false } }));
      }
    } catch (e) {
      setKeyStatus(prev => ({ ...prev, [index]: { valid: false, name: `เชื่อมต่อไม่ได้: ${e}`, checking: false } }));
    }
  };

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
          if (c.gemini_api_key) {
            const keys = c.gemini_api_key.split(',').map((k: string) => k.trim()).filter((k: string) => k);
            setApiKeys(keys.length > 0 ? keys : ['']);
            setActiveIndex(0); // The first key is always the active one based on our save logic
          }
          if (c.gemini_model) setSelectedModel(c.gemini_model);
          if (c.gmail_address || c.gmail_app_password) {
            const addrs = (c.gmail_address || '').split(',').map((x: string) => x.trim());
            const passes = (c.gmail_app_password || '').split(',').map((x: string) => x.trim());
            const length = Math.max(addrs.length, passes.length, 1);
            const loaded = [];
            for (let i = 0; i < length; i++) {
              loaded.push({ address: addrs[i] || '', password: passes[i] || '' });
            }
            if (loaded.length > 0) setEmails(loaded);
            else setEmails([{address: '', password: ''}]);
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

  const saveEmailConfig = () => {
    const validEmails = emails.filter(e => e.address.trim() || e.password.trim());
    const toSave = validEmails.length > 0 ? validEmails : [{address: '', password: ''}];
    saveConfig('gmail_address', toSave.map(e => e.address).join(','));
    saveConfig('gmail_app_password', toSave.map(e => e.password).join(','));
  };

  const testTimeoutRef = useRef<ReturnType<typeof setTimeout> | null>(null);
  const testAi = () => {
    setTesting(true); setTestResult(null);
    // Move the active index API key to the first position so the backend uses it immediately
    const orderedKeys = apiKeys[activeIndex] 
      ? [apiKeys[activeIndex], ...apiKeys.filter((_, idx) => idx !== activeIndex)].filter(k => k.trim()) 
      : apiKeys.filter(k => k.trim());
      
    saveConfig('gemini_api_key', orderedKeys.join(','));
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

      {/* API Key Setup */}
      <div className="card !p-6 space-y-4">
        <div className="flex items-center justify-between">
          <div>
            <h5 className="text-sm font-semibold text-default-900 mb-1 flex items-center gap-2">
              <div className="size-8 rounded-lg bg-violet-500/10 flex items-center justify-center"><LuKey className="size-4 text-violet-500" /></div>
              Google AI Studio API Key
              <span className="text-xs font-normal text-default-400">({apiKeys.filter(k => k.trim()).length} คีย์)</span>
            </h5>
            <p className="text-xs text-default-500">
              ไปที่ <a href="https://aistudio.google.com/apikey" target="_blank" rel="noreferrer" className="text-violet-500 underline">aistudio.google.com/apikey</a> 
              {' '}เพื่อสร้าง API Key ฟรี
            </p>
          </div>
          <button
            onClick={() => setShowKeysSection(!showKeysSection)}
            className="flex items-center gap-1.5 text-xs font-medium text-violet-500 hover:text-violet-600 px-3 py-1.5 rounded-lg hover:bg-violet-500/10 transition-colors"
          >
            {showKeysSection ? <><LuChevronUp className="size-4" /> ซ่อน</> : <><LuChevronDown className="size-4" /> แสดง</>}
          </button>
        </div>

        {showKeysSection && (
        <div className="space-y-4 animate-in fade-in slide-in-from-top-2 bg-default-50 dark:bg-default-100/5 p-4 rounded-xl border border-default-200/50">
          {apiKeys.map((key, i) => (
            <div key={i} className="space-y-2 pb-3 border-b border-default-200/50 last:border-0 last:pb-0">
              <div className="flex gap-3 items-center">
                <label className="flex items-center justify-center shrink-0 w-8 h-8 rounded-full bg-violet-500/10 text-violet-600 font-bold text-sm cursor-pointer hover:bg-violet-500/20 transition-colors" title="กำหนดให้ AI ใช้คีย์นี้">
                  <input 
                    type="radio" 
                    name="activeApiKey" 
                    className="hidden" 
                    checked={activeIndex === i} 
                    onChange={() => setActiveIndex(i)} 
                  />
                  {activeIndex === i ? <LuCheck className="size-4" /> : i + 1}
                </label>
                
                <div className="relative flex-1">
                  <input
                    type="text"
                    value={key}
                    onChange={(e) => {
                      resetHideTimer();
                      const next = [...apiKeys];
                      next[i] = e.target.value;
                      setApiKeys(next);
                      setKeyStatus(prev => { const n = {...prev}; delete n[i]; return n; });
                    }}
                    onBlur={() => {
                      if (key.trim().length > 10) validateKey(i, key.trim());
                    }}
                    placeholder={`API Key #${i + 1}`}
                    className={`w-full px-4 py-2.5 rounded-xl bg-default-100 dark:bg-default-200/10 text-default-900 border focus:outline-none focus:ring-2 focus:ring-violet-500/30 font-mono text-sm ${
                      keyStatus[i]?.valid === true ? 'border-green-500/50' : keyStatus[i]?.valid === false ? 'border-red-500/50' : 'border-default-200 dark:border-default-300/10'
                    }`}
                  />
                </div>
                {apiKeys.length > 1 && (
                  <button
                    onClick={() => {
                      setApiKeys(apiKeys.filter((_, j) => j !== i));
                      if (activeIndex === i) setActiveIndex(0);
                      else if (activeIndex > i) setActiveIndex(activeIndex - 1);
                      setKeyStatus(prev => { const n = {...prev}; delete n[i]; return n; });
                    }}
                    className="size-9 rounded-lg bg-red-500/10 hover:bg-red-500/20 text-red-500 flex items-center justify-center shrink-0 transition-colors"
                    title="ลบคีย์นี้"
                  >
                    <LuTrash2 className="size-4" />
                  </button>
                )}
              </div>
              
              <div className="flex items-center justify-between ml-11">
                {/* Key status badge */}
                {keyStatus[i] && (
                  <div className={`flex items-center gap-1.5 text-xs ${
                    keyStatus[i].checking ? 'text-default-400' : keyStatus[i].valid ? 'text-green-500' : 'text-red-500'
                  }`}>
                    {keyStatus[i].checking ? (
                      <><LuLoader className="size-3 animate-spin" /> กำลังตรวจสอบ...</>
                    ) : keyStatus[i].valid ? (
                      <><LuCheck className="size-3" /> ✅ {keyStatus[i].name}</>
                    ) : (
                      <><LuX className="size-3" /> ❌ {keyStatus[i].name}</>
                    )}
                  </div>
                )}
                {!keyStatus[i] && <div/>}
                
                {activeIndex === i && (
                  <span className="text-xs font-semibold text-violet-600 bg-violet-100 dark:bg-violet-500/20 px-2 py-0.5 rounded-md">
                    🌟 ใช้งานหลัก
                  </span>
                )}
              </div>
            </div>
          ))}
          <button
            onClick={() => {
              resetHideTimer();
              setApiKeys([...apiKeys, '']);
            }}
            className="flex items-center gap-2 text-xs text-violet-500 hover:text-violet-600 font-medium px-2 py-1.5 rounded-lg hover:bg-violet-500/10 transition-colors"
          >
            <LuPlus className="size-3.5" /> เพิ่ม API Key
          </button>
        </div>
        )}

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
          <button onClick={testAi} disabled={testing || !apiKeys.some(k => k.trim())}
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
              บันทึกบัญชี Email สำหรับเข้าสู่ระบบ
              <span className="text-xs font-normal text-default-400">({emails.filter(e => e.address.trim() || e.password.trim()).length} บัญชี)</span>
              {emailSaved && <span className="text-xs font-semibold text-green-500 ml-2 animate-in fade-in">บันทึกสำเร็จ ✅</span>}
            </h5>
            <p className="text-xs text-default-500">
              สมุดจดบันทึก Username และ Password สำหรับล็อกอินผ่านเบราว์เซอร์อย่างรวดเร็ว (ไม่ได้ใช้ส่งการแจ้งเตือน)
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
            <div key={i} className="flex flex-col sm:flex-row gap-4 pb-4 border-b border-default-200/50 last:border-0 last:pb-0">
              <div className="space-y-2 flex-1">
                <label className="text-xs font-semibold text-default-900 flex items-center gap-2">
                  <LuMail className="size-3.5 text-blue-500" /> Email
                </label>
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
                  placeholder="name@gmail.com"
                  className="w-full px-3 py-2 rounded-lg bg-default-100 dark:bg-default-200/10 text-default-900 border border-default-200 dark:border-default-300/10 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500/50 transition-all font-medium"
                />
              </div>

              <div className="space-y-2 flex-1">
                <label className="text-xs font-semibold text-default-900 flex items-center gap-2">
                  <LuKey className="size-3.5 text-orange-500" /> Password
                </label>
                <div className="relative">
                  <input
                    type="text"
                    value={acc.password}
                    onChange={(e) => {
                      resetEmailHideTimer();
                      const next = [...emails];
                      next[i].password = e.target.value;
                      setEmails(next);
                    }}
                    onKeyDown={(e) => { if (e.key === 'Enter') saveEmailConfig(); }}
                    placeholder="password1234"
                    className="w-full px-3 py-2 rounded-lg bg-default-100 dark:bg-default-200/10 text-default-900 border border-default-200 dark:border-default-300/10 text-sm focus:outline-none focus:ring-2 focus:ring-orange-500/50 transition-all font-mono"
                  />
                </div>
              </div>

              <div className="flex items-end gap-2">
                <a
                  href={`https://accounts.google.com/AccountChooser/signinchooser?Email=${encodeURIComponent(acc.address)}`}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="h-[38px] px-3 rounded-lg bg-blue-500/10 hover:bg-blue-500/20 text-blue-600 font-medium text-xs flex items-center justify-center shrink-0 transition-colors gap-1.5"
                  title="ล็อกอินบัญชีนี้ในเบราว์เซอร์"
                >
                  <LuExternalLink className="size-3.5" /> Login
                </a>
                {emails.length > 1 && (
                  <button
                    onClick={() => setEmails(emails.filter((_, j) => j !== i))}
                    className="h-[38px] w-[38px] rounded-lg bg-red-500/10 hover:bg-red-500/20 text-red-500 flex items-center justify-center shrink-0 transition-colors"
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
              setEmails([...emails, {address: '', password: ''}]);
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
