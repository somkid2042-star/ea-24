import { useState, useEffect, useRef, useCallback } from 'react';
import { LuBrain, LuSend, LuSave, LuCheck, LuX, LuSparkles, LuKey, LuZap, LuMessageCircle, LuChevronDown, LuBot, LuShield, LuEye, LuEyeOff, LuPlus, LuTrash2 } from 'react-icons/lu';
import { getWsUrl } from '@/utils/config';

const WS_URL = getWsUrl();

interface AiModel {
  id: string;
  name: string;
}

interface ChatMessage {
  role: 'user' | 'ai';
  text: string;
  timestamp: number;
}

interface AiAnalysisResult {
  success: boolean;
  symbol?: string;
  timeframe?: string;
  recommendation?: string;
  confidence?: number;
  reasoning?: string;
  full_analysis?: string;
  model?: string;
  message?: string;
}

const AiSettings = () => {
  const [wsConnected, setWsConnected] = useState(false);
  const [apiKeys, setApiKeys] = useState<string[]>(['']);
  const [keyVisible, setKeyVisible] = useState<boolean[]>([false]);
  const [selectedModel, setSelectedModel] = useState('');
  const [aiEnabled, setAiEnabled] = useState(false);
  const [models, setModels] = useState<AiModel[]>([]);
  const [testResult, setTestResult] = useState<{ success: boolean; message: string } | null>(null);
  const [testing, setTesting] = useState(false);
  const [saved, setSaved] = useState(false);
  
  // Auto-Pilot Settings
  const [autoAnalyze, setAutoAnalyze] = useState(false);
  const [autoAnalyzeInterval, setAutoAnalyzeInterval] = useState('5');
  const [autoTargetSymbol, setAutoTargetSymbol] = useState('XAUUSD');
  const [autoAnalyzeTf, setAutoAnalyzeTf] = useState('M15');
  const [autoTrade, setAutoTrade] = useState(false);
  
  // Chat
  const [chatMessages, setChatMessages] = useState<ChatMessage[]>([]);
  const [chatInput, setChatInput] = useState('');
  const [chatLoading, setChatLoading] = useState(false);
  // Analysis
  const [analysisSymbol, setAnalysisSymbol] = useState('XAUUSD');
  const [analysisTf, setAnalysisTf] = useState('M15');
  const [analysis, setAnalysis] = useState<AiAnalysisResult | null>(null);
  const [analyzing, setAnalyzing] = useState(false);

  const wsRef = useRef<WebSocket | null>(null);
  const chatEndRef = useRef<HTMLDivElement>(null);

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
            setKeyVisible(new Array(keys.length || 1).fill(false));
          }
          if (c.gemini_model) setSelectedModel(c.gemini_model);
          if (c.ai_enabled !== undefined) setAiEnabled(c.ai_enabled === 'true');
          if (c.ai_auto_analyze !== undefined) setAutoAnalyze(c.ai_auto_analyze === 'true');
          if (c.ai_analyze_interval) setAutoAnalyzeInterval(c.ai_analyze_interval);
          if (c.ai_target_symbol) setAutoTargetSymbol(c.ai_target_symbol);
          if (c.ai_analyze_timeframe) setAutoAnalyzeTf(c.ai_analyze_timeframe);
          if (c.ai_auto_trade !== undefined) setAutoTrade(c.ai_auto_trade === 'true');
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
        if (data.type === 'ai_response') {
          setChatLoading(false);
          setChatMessages(prev => [...prev, {
            role: 'ai',
            text: data.success ? data.answer : `❌ ${data.answer}`,
            timestamp: Date.now(),
          }]);
        }
        if (data.type === 'ai_analysis') {
          setAnalyzing(false);
          setAnalysis(data);
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
  useEffect(() => { chatEndRef.current?.scrollIntoView({ behavior: 'smooth' }); }, [chatMessages]);

  const send = (msg: object) => { if (wsRef.current?.readyState === 1) wsRef.current.send(JSON.stringify(msg)); };

  const saveConfig = (key: string, value: string) => {
    send({ action: 'set_server_config', config_key: key, config_value: value });
  };

  const saveAll = () => {
    saveConfig('gemini_api_key', apiKeys.filter(k => k.trim()).join(','));
    saveConfig('gemini_model', selectedModel);
    saveConfig('ai_enabled', aiEnabled.toString());
    saveConfig('ai_auto_analyze', autoAnalyze.toString());
    saveConfig('ai_analyze_interval', autoAnalyzeInterval);
    saveConfig('ai_target_symbol', autoTargetSymbol);
    saveConfig('ai_analyze_timeframe', autoAnalyzeTf);
    saveConfig('ai_auto_trade', autoTrade.toString());
  };

  const testTimeoutRef = useRef<ReturnType<typeof setTimeout> | null>(null);
  const testAi = () => {
    setTesting(true); setTestResult(null);
    // Save key first, then test
    saveConfig('gemini_api_key', apiKeys.filter(k => k.trim()).join(','));
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

  const sendChat = () => {
    if (!chatInput.trim() || chatLoading) return;
    setChatMessages(prev => [...prev, { role: 'user', text: chatInput, timestamp: Date.now() }]);
    send({ action: 'ask_ai', question: chatInput });
    setChatInput('');
    setChatLoading(true);
  };

  const analyzeMarket = () => {
    setAnalyzing(true); setAnalysis(null);
    send({ action: 'analyze_market', symbol: analysisSymbol, timeframe: analysisTf, strategy: 'Auto' });
  };

  const recBg = (rec?: string) => {
    if (rec === 'BUY') return 'bg-emerald-500/15 text-emerald-400 border-emerald-500/30';
    if (rec === 'SELL') return 'bg-red-500/15 text-red-400 border-red-500/30';
    return 'bg-amber-500/15 text-amber-400 border-amber-500/30';
  };

  return (
    <main className="space-y-5">
      <div className="flex items-center justify-between">
        <div>
          <h4 className="text-lg font-semibold text-default-900">🤖 AI Trading Engine</h4>
          <p className="mt-1 text-sm text-default-500">ตั้งค่า Gemini AI สำหรับวิเคราะห์ตลาดอัตโนมัติ</p>
        </div>
        <div className={`rounded-full px-3 py-1 text-xs font-medium ${wsConnected ? 'bg-green-100 dark:bg-green-500/20 text-green-600' : 'bg-red-100 dark:bg-red-500/20 text-red-600'}`}>
          {wsConnected ? 'เชื่อมต่อแล้ว' : 'ไม่เชื่อมต่อ'}
        </div>
      </div>

      {/* API Key Setup */}
      <div className="card !p-6 space-y-4">
        <div>
          <h5 className="text-sm font-semibold text-default-900 mb-2 flex items-center gap-2">
            <div className="size-8 rounded-lg bg-violet-500/10 flex items-center justify-center"><LuKey className="size-4 text-violet-500" /></div>
            Google AI Studio API Key
          </h5>
          <p className="text-xs text-default-500 mb-2">
            ไปที่ <a href="https://aistudio.google.com/apikey" target="_blank" rel="noreferrer" className="text-violet-500 underline">aistudio.google.com/apikey</a> 
            {' '}เพื่อสร้าง API Key ฟรี (ไม่ต้องใช้บัตรเครดิต)
          </p>
        </div>

        <div className="space-y-2">
          {apiKeys.map((key, i) => (
            <div key={i} className="flex gap-2 items-center">
              <span className="text-xs text-default-400 w-5 text-center shrink-0">#{i + 1}</span>
              <div className="relative flex-1">
                <input
                  type={keyVisible[i] ? 'text' : 'password'}
                  value={key}
                  onChange={(e) => {
                    const next = [...apiKeys];
                    next[i] = e.target.value;
                    setApiKeys(next);
                  }}
                  placeholder={`API Key #${i + 1}`}
                  className="w-full px-4 py-2.5 pr-10 rounded-xl bg-default-100 dark:bg-default-200/10 text-sm text-default-900 border border-default-200 dark:border-default-300/10 focus:outline-none focus:ring-2 focus:ring-violet-500/30 font-mono"
                />
                <button
                  onClick={() => {
                    const next = [...keyVisible];
                    next[i] = !next[i];
                    setKeyVisible(next);
                  }}
                  className="absolute right-3 top-1/2 -translate-y-1/2 text-default-400 hover:text-default-600"
                  title={keyVisible[i] ? 'ซ่อน' : 'แสดง'}
                >
                  {keyVisible[i] ? <LuEyeOff className="size-4" /> : <LuEye className="size-4" />}
                </button>
              </div>
              {apiKeys.length > 1 && (
                <button
                  onClick={() => {
                    setApiKeys(apiKeys.filter((_, j) => j !== i));
                    setKeyVisible(keyVisible.filter((_, j) => j !== i));
                  }}
                  className="size-9 rounded-lg bg-red-500/10 hover:bg-red-500/20 text-red-500 flex items-center justify-center shrink-0 transition-colors"
                  title="ลบคีย์นี้"
                >
                  <LuTrash2 className="size-4" />
                </button>
              )}
            </div>
          ))}
          <button
            onClick={() => {
              setApiKeys([...apiKeys, '']);
              setKeyVisible([...keyVisible, false]);
            }}
            className="flex items-center gap-2 text-xs text-violet-500 hover:text-violet-600 font-medium px-2 py-1.5 rounded-lg hover:bg-violet-500/10 transition-colors"
          >
            <LuPlus className="size-3.5" /> เพิ่ม API Key
          </button>
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

        {/* AI Enable Toggle */}
        <div className="flex items-center justify-between p-3 rounded-xl bg-default-50 dark:bg-default-200/5">
          <div className="flex items-center gap-3">
            <div className="size-8 rounded-lg bg-violet-500/10 flex items-center justify-center text-violet-500"><LuBrain className="size-4" /></div>
            <div>
              <p className="text-sm font-semibold text-default-900">เปิดใช้งาน AI ช่วยตัดสินใจ</p>
              <p className="text-xs text-default-500">AI จะวิเคราะห์กราฟก่อนเปิดออเดอร์ (ต้องมี API Key)</p>
            </div>
          </div>
          <button
            onClick={() => setAiEnabled(!aiEnabled)}
            className={`relative w-11 h-6 rounded-full transition-colors ${aiEnabled ? 'bg-violet-600' : 'bg-default-300 dark:bg-default-200/30'}`}>
            <span className={`absolute top-0.5 left-0.5 size-5 rounded-full bg-white shadow transition-transform ${aiEnabled ? 'translate-x-5' : ''}`} />
          </button>
        </div>
      </div>

      {/* Auto-Pilot Configuration */}
      <div className="card !p-6 space-y-4 border-l-4 border-l-cyan-500">
        <div>
          <h5 className="text-sm font-semibold text-default-900 mb-2 flex items-center gap-2">
            <div className="size-8 rounded-lg bg-cyan-500/10 flex items-center justify-center"><LuBot className="size-4 text-cyan-500" /></div>
            🤖 AI Auto-Pilot (วิเคราะห์ & ออกออเดอร์อัตโนมัติ)
          </h5>
          <p className="text-xs text-default-500 mb-3">
            ให้ AI รัน Multi-Agent เฝ้ากราฟตลอดเวลาตามที่กำหนด
          </p>
        </div>

        <div className="flex items-center justify-between p-3 rounded-xl bg-default-50 dark:bg-default-200/5 mb-2">
          <div className="flex items-center gap-3">
            <div>
              <p className="text-sm font-semibold text-default-900">เปิดระบบ Auto-Pilot</p>
              <p className="text-xs text-default-500">ให้ระบบหลังบ้านวิเคราะห์ตลอด 24 ชั่วโมง</p>
            </div>
          </div>
          <button
            onClick={() => setAutoAnalyze(!autoAnalyze)}
            className={`relative w-11 h-6 rounded-full transition-colors ${autoAnalyze ? 'bg-cyan-500' : 'bg-default-300 dark:bg-default-200/30'}`}>
            <span className={`absolute top-0.5 left-0.5 size-5 rounded-full bg-white shadow transition-transform ${autoAnalyze ? 'translate-x-5' : ''}`} />
          </button>
        </div>

        {autoAnalyze && (
          <div className="space-y-4 animate-in fade-in slide-in-from-top-2">
            <div className="flex gap-2 items-center text-sm">
                <span>วิเคราะห์คู่เงิน:</span>
                <input type="text" value={autoTargetSymbol} onChange={e => setAutoTargetSymbol(e.target.value.toUpperCase())} className="input input-sm w-24 uppercase" />
                <span>TF:</span>
                <select value={autoAnalyzeTf} onChange={e => setAutoAnalyzeTf(e.target.value)} className="input input-sm w-20">
                  {['M1','M5','M15','M30','H1','H4','D1'].map(tf => <option key={tf} value={tf}>{tf}</option>)}
                </select>
                <span>ทุกๆ</span>
                <input type="number" value={autoAnalyzeInterval} onChange={e => setAutoAnalyzeInterval(e.target.value)} className="input input-sm w-20" />
                <span>นาที</span>
            </div>

            <div className="flex items-center justify-between p-3 rounded-xl border border-default-200 dark:border-default-200/10">
              <div className="flex items-center gap-3">
                <div className={`size-8 rounded-lg flex items-center justify-center ${autoTrade ? 'bg-green-500/10 text-green-500' : 'bg-orange-500/10 text-orange-500'}`}>
                   {autoTrade ? <LuZap className="size-4" /> : <LuShield className="size-4" />}
                </div>
                <div>
                  <p className="text-sm font-semibold text-default-900">โหมดการออกออเดอร์</p>
                  <p className="text-xs text-default-500">{autoTrade ? 'ยิง Signal เข้า MT5 อัตโนมัติทันทีที่ AI ตัดสินใจ (Auto-Trade)' : 'ส่งแจ้งเตือนมายังหน้าจอ & Telegram เพื่อรอคนกดยืนยัน (Manual Confirm)'}</p>
                </div>
              </div>
              <button
                onClick={() => setAutoTrade(!autoTrade)}
                className={`relative w-11 h-6 rounded-full transition-colors shrink-0 outline-none ${autoTrade ? 'bg-green-500' : 'bg-orange-500'}`}>
                <span className={`absolute top-0.5 left-0.5 size-5 rounded-full bg-white shadow transition-transform ${autoTrade ? 'translate-x-5' : ''}`} />
              </button>
            </div>
          </div>
        )}
      </div>

      {/* Save Button */}
      <button onClick={saveAll}
        className="btn w-full py-3 rounded-xl bg-violet-600 text-white hover:bg-violet-700 text-sm font-semibold flex items-center justify-center gap-2 border-none shadow-md shadow-violet-600/20">
        {saved ? <><LuCheck className="size-4" /> บันทึกแล้ว!</> : <><LuSave className="size-4" /> บันทึกการตั้งค่า</>}
      </button>

      {/* Market Analysis */}
      <div className="card !p-6 space-y-4">
        <h5 className="text-sm font-semibold text-default-900 flex items-center gap-2">
          <div className="size-8 rounded-lg bg-blue-500/10 flex items-center justify-center"><LuSparkles className="size-4 text-blue-500" /></div>
          วิเคราะห์ตลาดด้วย AI
        </h5>

        <div className="flex gap-2">
          <input
            type="text"
            value={analysisSymbol}
            onChange={(e) => setAnalysisSymbol(e.target.value.toUpperCase())}
            placeholder="Symbol"
            className="w-32 px-4 py-2.5 rounded-xl bg-default-100 dark:bg-default-200/10 text-sm text-default-900 border border-default-200 dark:border-default-300/10 focus:outline-none focus:ring-2 focus:ring-blue-500/30"
          />
          <select
            value={analysisTf}
            onChange={(e) => setAnalysisTf(e.target.value)}
            className="px-4 py-2.5 rounded-xl bg-default-100 dark:bg-default-200/10 text-sm text-default-900 border border-default-200 dark:border-default-300/10 focus:outline-none focus:ring-2 focus:ring-blue-500/30 appearance-none cursor-pointer"
          >
            {['M1','M5','M15','M30','H1','H4','D1'].map(tf => <option key={tf} value={tf}>{tf}</option>)}
          </select>
          <button onClick={analyzeMarket} disabled={analyzing || !apiKeys.some(k => k.trim())}
            className="btn flex-1 px-4 py-2.5 rounded-xl bg-blue-600 text-white hover:bg-blue-700 text-sm font-medium flex items-center justify-center gap-2 border-none disabled:opacity-50">
            {analyzing ? <><LuSparkles className="size-4 animate-spin" /> กำลังวิเคราะห์...</> : <><LuBrain className="size-4" /> วิเคราะห์</>}
          </button>
        </div>

        {analysis && (
          <div className="rounded-xl border border-default-200 dark:border-default-300/10 overflow-hidden">
            {analysis.success ? (
              <>
                <div className="flex items-center gap-3 p-4 bg-default-50 dark:bg-default-200/5">
                  <div className={`px-4 py-2 rounded-lg text-lg font-bold border ${recBg(analysis.recommendation)}`}>
                    {analysis.recommendation === 'BUY' ? '📈 BUY' : analysis.recommendation === 'SELL' ? '📉 SELL' : '⏸️ HOLD'}
                  </div>
                  <div>
                    <p className="text-sm font-semibold text-default-900">{analysis.symbol} {analysis.timeframe}</p>
                    <p className="text-xs text-default-500">ความมั่นใจ: {analysis.confidence?.toFixed(0)}% | โมเดล: {analysis.model}</p>
                  </div>
                </div>
                <div className="p-4 space-y-2">
                  <p className="text-sm text-default-700"><strong>เหตุผล:</strong> {analysis.reasoning}</p>
                  {analysis.full_analysis && (
                    <details className="mt-2">
                      <summary className="text-xs text-default-500 cursor-pointer hover:text-default-700">ดูผลวิเคราะห์ฉบับเต็ม</summary>
                      <pre className="mt-2 p-3 rounded-lg bg-default-100 dark:bg-default-200/10 text-xs text-default-600 whitespace-pre-wrap max-h-48 overflow-y-auto">{analysis.full_analysis}</pre>
                    </details>
                  )}
                </div>
              </>
            ) : (
              <div className="p-4 text-sm text-red-500">❌ {analysis.message}</div>
            )}
          </div>
        )}
      </div>

      {/* AI Chat */}
      <div className="card !p-6 space-y-4">
        <h5 className="text-sm font-semibold text-default-900 flex items-center gap-2">
          <div className="size-8 rounded-lg bg-emerald-500/10 flex items-center justify-center"><LuMessageCircle className="size-4 text-emerald-500" /></div>
          แชทกับ AI
        </h5>

        <div className="h-56 rounded-xl bg-default-50 dark:bg-default-200/5 border border-default-200 dark:border-default-300/10 overflow-y-auto p-3 space-y-2">
          {chatMessages.length === 0 && (
            <p className="text-xs text-default-400 text-center py-8">ถาม AI ได้เลย เช่น "ตลาดวันนี้เป็นยังไง?" หรือ "แนะนำคู่เงินที่น่าสนใจ"</p>
          )}
          {chatMessages.map((msg, i) => (
            <div key={i} className={`flex ${msg.role === 'user' ? 'justify-end' : 'justify-start'}`}>
              <div className={`max-w-[80%] px-3 py-2 rounded-xl text-sm ${
                msg.role === 'user'
                  ? 'bg-violet-600 text-white rounded-br-sm'
                  : 'bg-default-100 dark:bg-default-200/10 text-default-900 rounded-bl-sm'
              }`}>
                {msg.role === 'ai' && <span className="text-xs font-medium text-violet-500 block mb-1">🤖 AI</span>}
                <p className="whitespace-pre-wrap">{msg.text}</p>
              </div>
            </div>
          ))}
          {chatLoading && (
            <div className="flex justify-start">
              <div className="px-3 py-2 rounded-xl bg-default-100 dark:bg-default-200/10 text-default-500 text-sm rounded-bl-sm">
                <LuSparkles className="size-4 animate-spin inline mr-1" /> กำลังคิด...
              </div>
            </div>
          )}
          <div ref={chatEndRef} />
        </div>

        <div className="flex gap-2">
          <input
            type="text"
            value={chatInput}
            onChange={(e) => setChatInput(e.target.value)}
            onKeyDown={(e) => { if (e.key === 'Enter') sendChat(); }}
            placeholder="พิมพ์คำถามที่นี่..."
            className="flex-1 px-4 py-2.5 rounded-xl bg-default-100 dark:bg-default-200/10 text-sm text-default-900 border border-default-200 dark:border-default-300/10 focus:outline-none focus:ring-2 focus:ring-emerald-500/30"
            disabled={chatLoading || !apiKeys.some(k => k.trim())}
          />
          <button onClick={sendChat} disabled={chatLoading || !chatInput.trim() || !apiKeys.some(k => k.trim())}
            className="btn px-4 py-2.5 rounded-xl bg-emerald-600 text-white hover:bg-emerald-700 text-sm font-medium flex items-center gap-2 border-none disabled:opacity-50">
            <LuSend className="size-4" /> ส่ง
          </button>
        </div>
      </div>
    </main>
  );
};

export default AiSettings;
