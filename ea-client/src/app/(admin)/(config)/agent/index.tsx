import { useState, useRef, useCallback, useEffect } from 'react';
import { 
  LuSave, LuNetwork, LuNewspaper, LuCalendar, 
  LuActivity, LuShieldAlert, LuGitMerge, LuFileText,
  LuKey, LuCheck, LuX, LuSparkles, LuZap, LuChevronDown, LuChevronUp, LuPlus, LuTrash2, LuMail, LuSearch, LuOctagon, LuCircleCheck, LuCircleX, LuTrendingDown, LuLayers, LuGauge, LuDollarSign,
  LuChevronRight, LuEye, LuEyeOff, LuRefreshCw
} from 'react-icons/lu';
import { getWsUrl } from '@/utils/config';

const WS_URL = getWsUrl();

type TabKey = 'news' | 'calendar' | 'sentiment' | 'risk' | 'correlation' | 'report' | 'key';

interface AiModel {
  id: string;
  name: string;
}

const AgentSettings = () => {
  const [activeTab, setActiveTab] = useState<TabKey>('news');
  const [wsConnected, setWsConnected] = useState(false);
  const [successMsg, setSuccessMsg] = useState('');
  
  // States: News
  const [centralizedInfo, setCentralizedInfo] = useState<boolean>(true);
  const [newsKeyword, setNewsKeyword] = useState<string>('Global Forex Market');

  // States: Calendar
  const [calendarEnabled, setCalendarEnabled] = useState<boolean>(false);
  const [calendarImpact, setCalendarImpact] = useState<string>('High');

  // States: Sentiment
  const [sentimentEnabled, setSentimentEnabled] = useState<boolean>(false);
  const [sentimentIndexes, setSentimentIndexes] = useState<string>('VIX, FearGreed');

  // States: Risk
  const [maxDailyDrawdown, setMaxDailyDrawdown] = useState('100');
  const [maxTotalLot, setMaxTotalLot] = useState('1.0');
  const [maxPositions, setMaxPositions] = useState('5');
  const [riskStopEnabled, setRiskStopEnabled] = useState(true);
  const [emergencyStop, setEmergencyStop] = useState(false);
  const [currentDrawdown, setCurrentDrawdown] = useState(0);
  const [currentPositions, setCurrentPositions] = useState(0);
  const [currentLotTotal, setCurrentLotTotal] = useState(0);

  // States: Correlation
  const [correlationEnabled, setCorrelationEnabled] = useState<boolean>(false);
  const [correlationMax, setCorrelationMax] = useState<string>('0.85');

  // States: Report
  const [reportEnabled, setReportEnabled] = useState<boolean>(false);

  // States: API Keys
  const [selectedModel, setSelectedModel] = useState('');
  const [models, setModels] = useState<AiModel[]>([]);
  const [testResult, setTestResult] = useState<{ success: boolean; message: string } | null>(null);
  const [tavilyResult, setTavilyResult] = useState<{ success: boolean; message: string } | null>(null);
  const [testing, setTesting] = useState(false);
  const [testingTavily, setTestingTavily] = useState(false);
  const [emails, setEmails] = useState<{address: string, password: string, apiKey: string, tavilyKey: string}[]>([{address: '', password: '', apiKey: '', tavilyKey: ''}]);
  const [globalNews, setGlobalNews] = useState<any>(null);
  const [newsLastUpdated, setNewsLastUpdated] = useState<number>(0);
  const [nextFetchSeconds, setNextFetchSeconds] = useState<number>(0);
  const [expandedKeys, setExpandedKeys] = useState<number[]>([]);
  const [showApiCards, setShowApiCards] = useState<boolean>(false);

  const toggleExpand = (index: number) => {
    if (expandedKeys.includes(index)) {
      setExpandedKeys(expandedKeys.filter(i => i !== index));
    } else {
      setExpandedKeys([...expandedKeys, index]);
    }
  };



  const wsRef = useRef<WebSocket | null>(null);

  const connectWs = useCallback(() => {
    const ws = new WebSocket(WS_URL);
    ws.onopen = () => {
      setWsConnected(true);
      ws.send(JSON.stringify({ action: 'get_server_config' }));
      ws.send(JSON.stringify({ action: 'get_ai_models' }));
      ws.send(JSON.stringify({ action: 'get_global_ai_data' }));
    };
    ws.onclose = () => { setWsConnected(false); setTimeout(connectWs, 3000); };
    ws.onmessage = (evt) => {
      try {
        const data = JSON.parse(evt.data);
        if (data.type === 'server_config' && data.config) {
          const c = data.config;
          // News
          if (c.agent_centralized !== undefined) setCentralizedInfo(c.agent_centralized !== 'false');
          if (c.agent_news_keyword !== undefined) setNewsKeyword(c.agent_news_keyword);
          // Calendar
          if (c.agent_calendar_enabled !== undefined) setCalendarEnabled(c.agent_calendar_enabled === 'true');
          if (c.agent_calendar_impact !== undefined) setCalendarImpact(c.agent_calendar_impact);
          // Sentiment
          if (c.agent_sentiment_enabled !== undefined) setSentimentEnabled(c.agent_sentiment_enabled === 'true');
          if (c.agent_sentiment_indexes !== undefined) setSentimentIndexes(c.agent_sentiment_indexes);
          // Risk
          if (c.max_daily_drawdown) setMaxDailyDrawdown(c.max_daily_drawdown);
          if (c.max_total_lot) setMaxTotalLot(c.max_total_lot);
          if (c.max_positions) setMaxPositions(c.max_positions);
          if (c.risk_stop_enabled !== undefined) setRiskStopEnabled(c.risk_stop_enabled === 'true');
          if (c.emergency_stop !== undefined) setEmergencyStop(c.emergency_stop === 'true');
          // Correlation
          if (c.agent_correlation_enabled !== undefined) setCorrelationEnabled(c.agent_correlation_enabled === 'true');
          if (c.agent_correlation_max !== undefined) setCorrelationMax(c.agent_correlation_max);
          // Report
          if (c.agent_report_enabled !== undefined) setReportEnabled(c.agent_report_enabled === 'true');
          // API Keys
          if (c.gemini_model) setSelectedModel(c.gemini_model);
          if (c.gmail_address || c.gmail_app_password || c.gemini_api_key || c.tavily_api_key) {
            const addrs = (c.gmail_address || '').split(',').map((x: string) => x.trim());
            const passes = (c.gmail_app_password || '').split(',').map((x: string) => x.trim());
            const keys = (c.gemini_api_key || '').split(',').map((x: string) => x.trim());
            const tvlys = (c.tavily_api_key || '').split(',').map((x: string) => x.trim());
            const length = Math.max(addrs.length, passes.length, keys.length, tvlys.length, 1);
            const loaded = [];
            for (let i = 0; i < length; i++) {
              loaded.push({ 
                address: addrs[i] || '', 
                password: passes[i] || '',
                apiKey: keys[i] || '',
                tavilyKey: tvlys[i] || ''
              });
            }
            if (loaded.length > 0) setEmails(loaded);
            else setEmails([{address: '', password: '', apiKey: '', tavilyKey: ''}]);
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
        if (data.type === 'tavily_test_result') {
          if (tavilyTimeoutRef.current) { clearTimeout(tavilyTimeoutRef.current); tavilyTimeoutRef.current = null; }
          setTestingTavily(false);
          setTavilyResult({ success: data.success, message: data.message });
          setTimeout(() => setTavilyResult(null), 10000);
        }
        if (data.type === 'global_ai_data') {
          if (data.data && data.data.news) {
            setGlobalNews(data.data.news);
          }
          if (data.data && data.data.last_updated) {
            setNewsLastUpdated(data.data.last_updated);
          }
        }
        if (data.type === 'account_data') {
          const positions = data.positions || [];
          setCurrentPositions(positions.length);
          setCurrentLotTotal(positions.reduce((s: number, p: any) => s + (p.volume || 0), 0));
          const totalPnl = positions.reduce((s: number, p: any) => s + (p.pnl || 0), 0);
          if (totalPnl < 0) setCurrentDrawdown(Math.abs(totalPnl));
        }
        if (data.type === 'config_saved') {
          setSuccessMsg('✅ บันทึกการตั้งค่าแล้ว');
          setTimeout(() => setSuccessMsg(''), 3000);
        }
      } catch {}
    };
    wsRef.current = ws;
  }, []);

  useEffect(() => { connectWs(); return () => { wsRef.current?.close(); }; }, [connectWs]);

  useEffect(() => {
    const timer = setInterval(() => {
      if (newsLastUpdated > 0) {
        const now = Math.floor(Date.now() / 1000);
        let diff = 3600 - (now - newsLastUpdated);
        if (diff < 0) diff = 0;
        setNextFetchSeconds(diff);
      }
    }, 1000);
    return () => clearInterval(timer);
  }, [newsLastUpdated]);

  const send = (msg: object) => { if (wsRef.current?.readyState === 1) wsRef.current.send(JSON.stringify(msg)); };

  const saveConfig = (key: string, value: string) => {
    send({ action: 'set_server_config', config_key: key, config_value: value });
  };

  const handleSave = () => {
    saveConfig('agent_centralized', centralizedInfo ? 'true' : 'false');
    saveConfig('agent_news_keyword', newsKeyword);
    saveConfig('agent_calendar_enabled', calendarEnabled ? 'true' : 'false');
    saveConfig('agent_calendar_impact', calendarImpact);
    saveConfig('agent_sentiment_enabled', sentimentEnabled ? 'true' : 'false');
    saveConfig('agent_sentiment_indexes', sentimentIndexes);
    saveConfig('max_daily_drawdown', maxDailyDrawdown);
    saveConfig('max_total_lot', maxTotalLot);
    saveConfig('max_positions', maxPositions);
    saveConfig('risk_stop_enabled', riskStopEnabled.toString());
    saveConfig('agent_correlation_enabled', correlationEnabled ? 'true' : 'false');
    saveConfig('agent_correlation_max', correlationMax);
    saveConfig('agent_report_enabled', reportEnabled ? 'true' : 'false');
    
    // API Keys
    const validEmails = emails.filter(e => e.address.trim() || e.password.trim() || e.apiKey.trim() || e.tavilyKey.trim());
    const toSave = validEmails.length > 0 ? validEmails : [{address: '', password: '', apiKey: '', tavilyKey: ''}];
    saveConfig('gmail_address', toSave.map(e => e.address).join(','));
    saveConfig('gmail_app_password', toSave.map(e => e.password).join(','));
    saveConfig('gemini_api_key', toSave.map(e => e.apiKey).join(','));
    saveConfig('tavily_api_key', toSave.map(e => e.tavilyKey).join(','));
    saveConfig('gemini_model', selectedModel);
  };

  const toggleEmergencyStop = () => {
    const newVal = !emergencyStop;
    setEmergencyStop(newVal);
    saveConfig('emergency_stop', newVal.toString());
  };

  const testTimeoutRef = useRef<ReturnType<typeof setTimeout> | null>(null);
  const tavilyTimeoutRef = useRef<ReturnType<typeof setTimeout> | null>(null);

  const testTavily = () => {
    setTestingTavily(true); setTavilyResult(null);
    const orderedKeys = emails.map(e => e.tavilyKey).filter(k => k.trim());
    if (orderedKeys.length > 0) saveConfig('tavily_api_key', orderedKeys.join(','));
    setTimeout(() => send({ action: 'test_tavily' }), 300);
    if (tavilyTimeoutRef.current) clearTimeout(tavilyTimeoutRef.current);
    tavilyTimeoutRef.current = setTimeout(() => {
      setTestingTavily(prev => {
        if (prev) setTavilyResult({ success: false, message: 'หมดเวลา — Server ไม่ตอบกลับภายใน 15 วินาที' });
        return false;
      });
    }, 15000);
  };

  const testAi = () => {
    setTesting(true); setTestResult(null);
    const orderedKeys = emails.map(e => e.apiKey).filter(k => k.trim());
    if (orderedKeys.length > 0) saveConfig('gemini_api_key', orderedKeys.join(','));
    saveConfig('gemini_model', selectedModel);
    setTimeout(() => send({ action: 'test_ai' }), 300);
    if (testTimeoutRef.current) clearTimeout(testTimeoutRef.current);
    testTimeoutRef.current = setTimeout(() => {
      setTesting(prev => {
        if (prev) setTestResult({ success: false, message: 'หมดเวลา — Server ไม่ตอบกลับภายใน 15 วินาที' });
        return false;
      });
    }, 15000);
  };

  const ddPercent = parseFloat(maxDailyDrawdown) > 0 ? Math.min(100, (currentDrawdown / parseFloat(maxDailyDrawdown)) * 100) : 0;
  const lotPercent = parseFloat(maxTotalLot) > 0 ? Math.min(100, (currentLotTotal / parseFloat(maxTotalLot)) * 100) : 0;
  const posPercent = parseInt(maxPositions) > 0 ? Math.min(100, (currentPositions / parseInt(maxPositions)) * 100) : 0;
  const gaugeColor = (pct: number) => pct >= 80 ? 'bg-red-500' : pct >= 50 ? 'bg-yellow-500' : 'bg-green-500';

  const moveEmailUp = (index: number) => {
    if (index === 0) return;
    const next = [...emails];
    const temp = next[index - 1];
    next[index - 1] = next[index];
    next[index] = temp;
    setEmails(next);
  };

  const moveEmailDown = (index: number) => {
    if (index === emails.length - 1) return;
    const next = [...emails];
    const temp = next[index + 1];
    next[index + 1] = next[index];
    next[index] = temp;
    setEmails(next);
  };

  const TABS = [
    { key: 'news', icon: <LuNewspaper size={18} />, label: 'News AI' },
    { key: 'calendar', icon: <LuCalendar size={18} />, label: 'Calendar' },
    { key: 'sentiment', icon: <LuActivity size={18} />, label: 'Sentiment' },
    { key: 'risk', icon: <LuShieldAlert size={18} />, label: 'Risk Guard' },
    { key: 'correlation', icon: <LuGitMerge size={18} />, label: 'Correlation' },
    { key: 'report', icon: <LuFileText size={18} />, label: 'Daily Report' },
    { key: 'key', icon: <LuKey size={18} />, label: 'API Keys' },
  ] as const;

  const renderSaveAction = () => (
    <div className="flex items-center justify-between border-t border-default-100 dark:border-gray-700/50 pt-5 mt-6">
      <div>
        {successMsg && <span className="text-green-500 font-medium flex items-center gap-2"><span className="w-2 h-2 rounded-full bg-green-500 animate-pulse"></span> {successMsg}</span>}
        {!wsConnected && <span className="text-red-500 font-medium flex items-center gap-2"><span className="w-2 h-2 rounded-full bg-red-500 animate-pulse"></span> การเชื่อมต่อขาดหาย</span>}
      </div>
      <button
        onClick={handleSave}
        className="px-6 py-2.5 shadow-md shadow-blue-500/20 bg-blue-600 hover:bg-blue-500 active:scale-95 text-white rounded-xl transition-all flex items-center gap-2 font-medium"
      >
        <LuSave size={18} />
        บันทึกการตั้งค่า
      </button>
    </div>
  );

  return (
    <div className="p-4 lg:p-6 max-w-5xl mx-auto space-y-6">
      <div className="flex items-center gap-3 mb-6">
        <div className="w-12 h-12 bg-blue-100 text-blue-600 dark:bg-blue-500/20 dark:text-blue-400 rounded-xl flex items-center justify-center shadow-inner">
          <LuNetwork size={24} />
        </div>
        <div>
          <h1 className="text-2xl font-bold text-default-900 dark:text-gray-100">Global Agent Manager</h1>
          <p className="text-default-500 dark:text-gray-400">ระบบสั่งการส่วนหน้าสำหรับจัดการ Agent ศูนย์กลางทั้งหมด</p>
        </div>
      </div>

      <div className="flex flex-col lg:flex-row gap-6 lg:gap-8 items-start mb-24 relative">
        {/* Sidebar Tabs */}
        <div className="w-full lg:w-60 shrink-0 lg:sticky lg:top-24 bg-white/40 dark:bg-gray-800/20 backdrop-blur-xl p-2 rounded-2xl border border-default-200/50 dark:border-gray-700/30 flex lg:flex-col gap-1 overflow-x-auto hide-scrollbar z-10 shadow-sm">
          {TABS.map((tab) => (
            <button
              key={tab.key}
              onClick={() => {
                setActiveTab(tab.key);
                
              }}
              className={`flex flex-shrink-0 items-center justify-start gap-3 px-4 py-3 rounded-xl text-sm font-medium transition-all duration-300 ${
                activeTab === tab.key 
                  ? 'bg-blue-600 text-white shadow-md shadow-blue-500/20' 
                  : 'text-default-600 dark:text-gray-400 hover:text-blue-600 dark:hover:text-blue-400 hover:bg-blue-50 dark:hover:bg-blue-500/10 border-transparent'
              }`}
            >
              <div className={activeTab === tab.key ? 'text-white/90 scale-110 transition-transform' : 'opacity-70'}>{tab.icon}</div>
              {tab.label}
            </button>
          ))}
        </div>

        {/* Content Sections */}
        <div className="flex-1 space-y-8 w-full min-w-0 pb-32">
        {/* News  Tab */}
          {activeTab === 'news' && (<section id={`section-news`} className="bg-white dark:bg-gray-800/50 border border-default-200 dark:border-gray-700/50 rounded-2xl p-6 lg:p-8 shadow-sm scroll-mt-28 transition-all hover:shadow-md group">
            <h2 className="text-lg font-semibold text-default-900 dark:text-white flex items-center gap-2 mb-2">
              <LuNewspaper className="text-blue-500 dark:text-blue-400" /> Global News Agent
            </h2>
            <p className="text-sm text-default-500 dark:text-gray-400 mb-6">
              ระบบส่วนกลางสำหรับค้นหาข่าวสารให้ 1 ครั้งต่อชั่วโมง เพื่อลดการใช้ API Credit ของแต่ละคู่เงิน
            </p>

            <div className="space-y-6 max-w-xl">
              <div className="flex items-center justify-between p-4 bg-default-50 dark:bg-gray-900/50 rounded-xl border border-default-200 dark:border-gray-700/50">
                <div>
                  <div className="text-default-800 dark:text-gray-200 font-medium">เปิดใช้งาน Centralized News</div>
                  <div className="text-xs text-default-500 dark:text-gray-400 mt-1">แชร์ข่าวส่วนกลางร่วมกันทุกคู่เงิน (แนะนำให้เปิด)</div>
                </div>
                <label className="relative inline-flex items-center cursor-pointer">
                  <input type="checkbox" className="sr-only peer" checked={centralizedInfo} onChange={(e) => setCentralizedInfo(e.target.checked)} />
                  <div className={`w-11 h-6 rounded-full peer-focus:outline-none transition-colors ${centralizedInfo ? 'bg-blue-500' : 'bg-default-300 dark:bg-gray-600'} peer-checked:after:translate-x-full after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all`}></div>
                </label>
              </div>

              <div className="space-y-2">
                <label className="text-sm font-medium text-default-700 dark:text-gray-300">คำค้นหาข่าวศูนย์กลาง (Global Search Keyword)</label>
                <input
                  type="text"
                  value={newsKeyword}
                  onChange={(e) => setNewsKeyword(e.target.value)}
                  disabled={!centralizedInfo}
                  className="w-full bg-white dark:bg-gray-900 border border-default-300 dark:border-gray-700 text-default-900 dark:text-white rounded-lg px-4 py-2.5 focus:outline-none focus:border-blue-500 dark:focus:border-blue-500 disabled:opacity-50 disabled:bg-default-100"
                  placeholder="ตัวอย่าง: Global Forex Market News"
                />
              </div>

              {/* Fetched News Card */}
              <div className="mt-6 p-5 rounded-xl border border-default-200 dark:border-gray-700/50 bg-default-50/50 dark:bg-gray-900/30">
                <div className="flex items-center justify-between mb-4">
                  <h3 className="text-sm font-medium text-default-900 dark:text-gray-100 flex items-center gap-2">
                    <LuActivity className="text-blue-500" /> ข่าวสารล่าสุดที่ระบบหาได้
                  </h3>
                  <div className="flex items-center gap-3">
                    <button 
                      onClick={() => send({ action: 'force_fetch_news' })}
                      className="p-1 rounded-md bg-default-200 dark:bg-gray-700 hover:bg-default-300 dark:hover:bg-gray-600 transition-colors text-default-600 dark:text-gray-300 tooltip focus:outline-none"
                      title="เช็คข่าวสารด่วน (Refresh)"
                    >
                      <LuRefreshCw className="w-3.5 h-3.5" />
                    </button>
                    {newsLastUpdated > 0 && nextFetchSeconds > 0 && (
                      <span className="text-xs text-default-500 font-mono">
                        อัปเดตอัติโนมัติในอีก {Math.floor(nextFetchSeconds / 60)}:{(nextFetchSeconds % 60).toString().padStart(2, '0')}
                      </span>
                    )}
                    {newsLastUpdated > 0 && nextFetchSeconds === 0 && (
                      <span className="text-xs text-blue-500 font-mono animate-pulse">
                        กำลังดึงข้อมูลใหม่...
                      </span>
                    )}
                    {globalNews?.sentiment && (
                      <span className={`px-2.5 py-1 rounded-md text-xs font-semibold ${
                        globalNews.sentiment === 'BULLISH' ? 'bg-green-100 text-green-700 dark:bg-green-500/20 dark:text-green-400' :
                        globalNews.sentiment === 'BEARISH' ? 'bg-red-100 text-red-700 dark:bg-red-500/20 dark:text-red-400' :
                        'bg-gray-200 text-gray-700 dark:bg-gray-700 dark:text-gray-300'
                      }`}>
                        {globalNews.sentiment}
                      </span>
                    )}
                  </div>
                </div>
                
                {globalNews ? (
                  <div className="space-y-4">
                    <p className="text-sm text-default-600 dark:text-gray-300 leading-relaxed">
                      {globalNews.summary}
                    </p>
                    
                    {globalNews.headlines && globalNews.headlines.length > 0 && (
                      <div className="mt-4 border-t border-default-200 dark:border-gray-700 pt-4">
                        <h4 className="text-xs font-semibold text-default-500 dark:text-gray-400 mb-3 uppercase">Headlines</h4>
                        <div className="space-y-2">
                          {globalNews.headlines.slice(0, 5).map((h: string, idx: number) => {
                            const parts = h.split('||');
                            const title = parts[0]?.trim() || h;
                            const content = parts[1]?.trim() || '';
                            
                            return (
                              <details key={idx} className="group border border-default-200 dark:border-gray-700 rounded-xl bg-white dark:bg-gray-800/50 shadow-sm overflow-hidden mb-3">
                                <summary className="flex items-start justify-between cursor-pointer p-4 font-semibold text-default-800 dark:text-gray-200 list-none outline-none hover:bg-default-50 dark:hover:bg-gray-700/50 transition-colors">
                                  <div className="flex-1 pr-4">
                                    <span className="block text-left text-sm md:text-base leading-snug line-clamp-2 md:line-clamp-none text-balance">{title}</span>
                                  </div>
                                  <div className="bg-default-100 dark:bg-gray-700 rounded-full p-1 mt-0.5 flex-shrink-0">
                                    <LuChevronDown className="w-4 h-4 text-default-500 transition-transform group-open:rotate-180" />
                                  </div>
                                </summary>
                                {content && (
                                  <div className="px-4 pb-4 text-sm text-default-600 dark:text-gray-400 bg-default-50 dark:bg-gray-800 leading-relaxed border-t border-default-100 dark:border-gray-700 pt-3">
                                    <div className="pt-1 italic">{content}</div>
                                  </div>
                                )}
                              </details>
                            );
                          })}
                        </div>
                      </div>
                    )}
                  </div>
                ) : (
                  <div className="text-center py-6 text-sm text-default-500 dark:text-gray-500 flex flex-col items-center gap-2">
                    <LuNewspaper size={24} className="opacity-50" />
                    <span>ยังไม่มีข้อมูลข่าวสารในขณะนี้</span>
                    <span className="text-xs">ระบบจะดึงข้อมูลอัตโนมัติ 1 ครั้งต่อชั่วโมง เพื่อลดการใช้ API Credit</span>
                  </div>
                )}
              </div>

            </div>
            {renderSaveAction()}
          </section>)}

        {/* Calendar  Tab */}
          {activeTab === 'calendar' && (<section id={`section-calendar`} className="bg-white dark:bg-gray-800/50 border border-default-200 dark:border-gray-700/50 rounded-2xl p-6 lg:p-8 shadow-sm scroll-mt-28 transition-all hover:shadow-md group">
            <h2 className="text-lg font-semibold text-default-900 dark:text-white flex items-center gap-2 mb-2">
              <LuCalendar className="text-purple-500 dark:text-purple-400" /> Economic Calendar AI
            </h2>
            <p className="text-sm text-default-500 dark:text-gray-400 mb-6">
              ให้ Global Agent ตัวเดียวคอยดึงข้อมูลตัวเลขเศรษฐกิจสำคัญ เพื่อแจ้งเตือนคู่เงินทั้งหมด
            </p>

            <div className="space-y-6 max-w-xl">
              <div className="flex items-center justify-between p-4 bg-default-50 dark:bg-gray-900/50 rounded-xl border border-default-200 dark:border-gray-700/50">
                <div>
                  <div className="text-default-800 dark:text-gray-200 font-medium">เชื่อมต่อ API ปฏิทินเศรษฐกิจ</div>
                  <div className="text-xs text-default-500 dark:text-gray-400 mt-1">เปิดเพื่อโหลดดอกเบี้ย FED, NFP, CPI อัตโนมัติ</div>
                </div>
                <label className="relative inline-flex items-center cursor-pointer">
                  <input type="checkbox" className="sr-only peer" checked={calendarEnabled} onChange={(e) => setCalendarEnabled(e.target.checked)} />
                  <div className={`w-11 h-6 rounded-full peer-focus:outline-none transition-colors ${calendarEnabled ? 'bg-blue-500' : 'bg-default-300 dark:bg-gray-600'} peer-checked:after:translate-x-full after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all`}></div>
                </label>
              </div>

              <div className="space-y-2">
                <label className="text-sm font-medium text-default-700 dark:text-gray-300">ระดับความสำคัญที่ให้ส่งผลต่อการเทรด</label>
                <select
                  value={calendarImpact}
                  onChange={(e) => setCalendarImpact(e.target.value)}
                  disabled={!calendarEnabled}
                  className="w-full bg-white dark:bg-gray-900 border border-default-300 dark:border-gray-700 text-default-900 dark:text-white rounded-lg px-4 py-2.5 focus:outline-none focus:border-blue-500 dark:focus:border-blue-500 disabled:opacity-50 disabled:bg-default-100"
                >
                  <option value="High">ระวังเฉพาะข่าวแดง (High Impact)</option>
                  <option value="Medium">ระวังข่าวส้มและแดง (Medium & High Impact)</option>
                  <option value="All">ทุกข่าวสำคัญ (All Impact)</option>
                </select>
              </div>
            </div>
            {renderSaveAction()}
          </section>)}

        {/* Sentiment  Tab */}
          {activeTab === 'sentiment' && (<section id={`section-sentiment`} className="bg-white dark:bg-gray-800/50 border border-default-200 dark:border-gray-700/50 rounded-2xl p-6 lg:p-8 shadow-sm scroll-mt-28 transition-all hover:shadow-md group">
            <h2 className="text-lg font-semibold text-default-900 dark:text-white flex items-center gap-2 mb-2">
              <LuActivity className="text-orange-500 dark:text-orange-400" /> Market Sentiment Analyzer
            </h2>
            <p className="text-sm text-default-500 dark:text-gray-400 mb-6">
              วิเคราะห์ความกลัว ความโลภ และดัชนีสำคัญ (VIX, DXY) เพื่อหาดูว่าตลาดปัจจุบันเป็น Risk-On หรือ Risk-Off
            </p>

            <div className="space-y-6 max-w-xl">
              <div className="flex items-center justify-between p-4 bg-default-50 dark:bg-gray-900/50 rounded-xl border border-default-200 dark:border-gray-700/50">
                <div>
                  <div className="text-default-800 dark:text-gray-200 font-medium">วิเคราะห์ Sentiment รวม</div>
                  <div className="text-xs text-default-500 dark:text-gray-400 mt-1">ให้ Agent ตัดสินรอบตลาด ก่อนส่งให้แต่ละคู่เงินปรับ Lot</div>
                </div>
                <label className="relative inline-flex items-center cursor-pointer">
                  <input type="checkbox" className="sr-only peer" checked={sentimentEnabled} onChange={(e) => setSentimentEnabled(e.target.checked)} />
                  <div className={`w-11 h-6 rounded-full peer-focus:outline-none transition-colors ${sentimentEnabled ? 'bg-blue-500' : 'bg-default-300 dark:bg-gray-600'} peer-checked:after:translate-x-full after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all`}></div>
                </label>
              </div>

              <div className="space-y-2">
                <label className="text-sm font-medium text-default-700 dark:text-gray-300">ดัชนีชี้วัดที่ต้องการตรวจสอบ</label>
                <input
                  type="text"
                  value={sentimentIndexes}
                  onChange={(e) => setSentimentIndexes(e.target.value)}
                  disabled={!sentimentEnabled}
                  className="w-full bg-white dark:bg-gray-900 border border-default-300 dark:border-gray-700 text-default-900 dark:text-white rounded-lg px-4 py-2.5 focus:outline-none focus:border-blue-500 dark:focus:border-blue-500 disabled:opacity-50 disabled:bg-default-100"
                  placeholder="VIX, FearGreed, DXY"
                />
              </div>
            </div>
            {renderSaveAction()}
          </section>)}

        {/* Risk  Tab */}
          {activeTab === 'risk' && (<section id={`section-risk`} className="bg-white dark:bg-gray-800/50 border border-default-200 dark:border-gray-700/50 rounded-2xl p-6 lg:p-8 shadow-sm scroll-mt-28 transition-all hover:shadow-md group">
            <div className="flex items-center justify-between">
              <div>
                <h2 className="text-lg font-semibold text-default-900 dark:text-white flex items-center gap-2 mb-2">
                  <LuShieldAlert className="text-red-500 dark:text-red-400" /> Global Risk & Kill Switch
                </h2>
                <p className="text-sm text-default-500 dark:text-gray-400 mb-2">
                  ตั้งค่าขีดจำกัดรวมทั้งหมด ไม่ให้เกินพิกัดความเสี่ยงเพื่อปกป้องพอร์ตโฟลิโอของคุณ
                </p>
              </div>
            </div>

            <div className={`p-5 rounded-2xl border-2 transition-colors ${emergencyStop ? 'border-red-500 bg-red-50 dark:bg-red-900/10' : 'border-default-200 dark:border-gray-700/50 bg-white dark:bg-gray-800'}`}>
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-3">
                  <div className={`w-12 h-12 rounded-xl flex items-center justify-center ${emergencyStop ? 'bg-red-500' : 'bg-default-100 dark:bg-gray-700'}`}>
                    <LuOctagon className={`size-6 ${emergencyStop ? 'text-white' : 'text-default-500'}`} />
                  </div>
                  <div>
                    <p className={`text-base font-bold flex items-center gap-1.5 ${emergencyStop ? 'text-red-600 dark:text-red-400' : 'text-default-900 dark:text-white'}`}>
                      Emergency Stop (Kill Switch)
                    </p>
                    <p className="text-xs text-default-500">หยุดการเปิดออเดอร์จากทุก Agent ทันทีด้วยมือ</p>
                  </div>
                </div>
                <button
                  onClick={toggleEmergencyStop}
                  className={`px-5 py-2.5 rounded-xl text-sm font-bold border-none transition-all flex items-center gap-2 ${emergencyStop ? 'bg-green-500 text-white hover:bg-green-600' : 'bg-red-500 text-white hover:bg-red-600'}`}
                >
                  {emergencyStop ? <><LuCircleCheck className="size-4" /> ปลดล็อคระบบ</> : <><LuCircleX className="size-4" /> ปิดระบบฉุกเฉิน</>}
                </button>
              </div>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-3 gap-4 auto-rows-fr">
              {[
                { label: 'Drawdown วันนี้', val: `$${currentDrawdown.toFixed(2)}`, max: `$${maxDailyDrawdown}`, pct: ddPercent, icon: <LuTrendingDown className="size-4" /> },
                { label: 'Lot รวม', val: `${currentLotTotal.toFixed(2)} lot`, max: `${maxTotalLot} lot`, pct: lotPercent, icon: <LuLayers className="size-4" /> },
                { label: 'Positions พร้อมกัน', val: currentPositions, max: maxPositions, pct: posPercent, icon: <LuGauge className="size-4" /> },
              ].map((g, i) => (
                <div key={i} className="p-4 rounded-xl bg-default-50 dark:bg-gray-900/50 border border-default-200 dark:border-gray-700/50 flex flex-col justify-between h-full">
                  <div>
                    <div className="flex items-center justify-between mb-2">
                      <span className="text-xs font-semibold uppercase text-default-500 flex items-center gap-1.5">{g.icon} {g.label}</span>
                      <span className={`text-xs font-bold ${g.pct >= 80 ? 'text-red-500' : g.pct >= 50 ? 'text-yellow-500' : 'text-green-500'}`}>{g.pct.toFixed(0)}%</span>
                    </div>
                    <p className="text-xl font-bold text-default-900 dark:text-white mb-2">{g.val} <span className="text-sm font-normal text-default-400">/ {g.max}</span></p>
                  </div>
                  <div className="w-full h-1.5 rounded-full bg-default-200 dark:bg-gray-700 overflow-hidden mt-auto">
                    <div className={`h-full transition-all ${gaugeColor(g.pct)}`} style={{ width: `${g.pct}%` }} />
                  </div>
                </div>
              ))}
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <label className="text-sm font-medium text-default-700 dark:text-gray-300 mb-1.5 block">Max Drawdown ต่อวัน ($)</label>
                <div className="relative">
                  <LuDollarSign className="absolute left-3 top-1/2 -translate-y-1/2 text-default-400 size-4" />
                  <input type="number" value={maxDailyDrawdown} onChange={(e) => setMaxDailyDrawdown(e.target.value)}
                    className="w-full pl-9 pr-4 py-2.5 rounded-xl bg-white dark:bg-gray-900 border border-default-300 dark:border-gray-700 focus:ring-2 focus:ring-blue-500/50" />
                </div>
              </div>
              <div className="flex gap-4">
                <div className="flex-1">
                  <label className="text-sm font-medium text-default-700 dark:text-gray-300 mb-1.5 block">Max Lot รวม</label>
                  <input type="number" step="0.1" value={maxTotalLot} onChange={(e) => setMaxTotalLot(e.target.value)}
                    className="w-full px-4 py-2.5 rounded-xl bg-white dark:bg-gray-900 border border-default-300 dark:border-gray-700 focus:ring-2 focus:ring-blue-500/50" />
                </div>
                <div className="flex-1">
                  <label className="text-sm font-medium text-default-700 dark:text-gray-300 mb-1.5 block">Max Positions</label>
                  <input type="number" value={maxPositions} onChange={(e) => setMaxPositions(e.target.value)}
                    className="w-full px-4 py-2.5 rounded-xl bg-white dark:bg-gray-900 border border-default-300 dark:border-gray-700 focus:ring-2 focus:ring-blue-500/50" />
                </div>
              </div>
            </div>

            <div className="flex items-center justify-between p-4 bg-default-50 dark:bg-gray-900/50 rounded-xl border border-default-200 dark:border-gray-700/50">
              <div>
                <p className="text-sm font-semibold text-default-900 dark:text-white">บังคับใช้กฎ Risk Management</p>
                <p className="text-xs text-default-500">หยุดหุ่นยนต์อัตโนมัติหากยอดเข้าขีดจำกัดด้านบน</p>
              </div>
              <label className="relative inline-flex items-center cursor-pointer">
                <input type="checkbox" className="sr-only peer" checked={riskStopEnabled} onChange={(e) => setRiskStopEnabled(e.target.checked)} />
                <div className={`w-11 h-6 rounded-full transition-colors ${riskStopEnabled ? 'bg-blue-500' : 'bg-default-300 dark:bg-gray-600'} peer-checked:after:translate-x-full after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all`}></div>
              </label>
            </div>
            {renderSaveAction()}
          </section>)}

        {/* Correlation  Tab */}
          {activeTab === 'correlation' && (<section id={`section-correlation`} className="bg-white dark:bg-gray-800/50 border border-default-200 dark:border-gray-700/50 rounded-2xl p-6 lg:p-8 shadow-sm scroll-mt-28 transition-all hover:shadow-md group">
            <h2 className="text-lg font-semibold text-default-900 dark:text-white flex items-center gap-2 mb-2">
              <LuGitMerge className="text-cyan-500 dark:text-cyan-400" /> Correlation Analyzer
            </h2>
            <p className="text-sm text-default-500 dark:text-gray-400 mb-6">
              ป้องกันการเปิดออเดอร์ในคู่เงินที่วิ่งทิศทางเดียวกันในเวลาเดียวกันมากเกินไป (Over-exposure)
            </p>

            <div className="space-y-6 max-w-xl">
              <div className="flex items-center justify-between p-4 bg-default-50 dark:bg-gray-900/50 rounded-xl border border-default-200 dark:border-gray-700/50">
                <div>
                  <div className="text-default-800 dark:text-gray-200 font-medium">ใช้ระบบป้องกัน Correlation</div>
                  <div className="text-xs text-default-500 dark:text-gray-400 mt-1">กันคู่เงินที่มีความสัมพันธ์สูงเปิดเหมือนกัน</div>
                </div>
                <label className="relative inline-flex items-center cursor-pointer">
                  <input type="checkbox" className="sr-only peer" checked={correlationEnabled} onChange={(e) => setCorrelationEnabled(e.target.checked)} />
                  <div className={`w-11 h-6 rounded-full peer-focus:outline-none transition-colors ${correlationEnabled ? 'bg-blue-500' : 'bg-default-300 dark:bg-gray-600'} peer-checked:after:translate-x-full after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all`}></div>
                </label>
              </div>

              <div className="space-y-2">
                <label className="text-sm font-medium text-default-700 dark:text-gray-300">ระดับความสัมพันธ์สูงสุด (Max Correlation Co-eff 0.0-1.0)</label>
                <input
                  type="number"
                  step="0.05"
                  value={correlationMax}
                  onChange={(e) => setCorrelationMax(e.target.value)}
                  disabled={!correlationEnabled}
                  className="w-full bg-white dark:bg-gray-900 border border-default-300 dark:border-gray-700 text-default-900 dark:text-white rounded-lg px-4 py-2.5 focus:outline-none focus:border-blue-500 dark:focus:border-blue-500 disabled:opacity-50 disabled:bg-default-100"
                  placeholder="0.85"
                />
              </div>
            </div>
            {renderSaveAction()}
          </section>)}

        {/* Report  Tab */}
          {activeTab === 'report' && (<section id={`section-report`} className="bg-white dark:bg-gray-800/50 border border-default-200 dark:border-gray-700/50 rounded-2xl p-6 lg:p-8 shadow-sm scroll-mt-28 transition-all hover:shadow-md group">
            <h2 className="text-lg font-semibold text-default-900 dark:text-white flex items-center gap-2 mb-2">
              <LuFileText className="text-emerald-500 dark:text-emerald-400" /> Global Daily Reporter
            </h2>
            <p className="text-sm text-default-500 dark:text-gray-400 mb-6">
              ให้ตัวกลางคอยรวบรวมข้อมูล P&L และสรุปผลรายวัน
            </p>

            <div className="flex items-center justify-between p-4 bg-default-50 dark:bg-gray-900/50 rounded-xl border border-default-200 dark:border-gray-700/50 max-w-xl">
              <div>
                <div className="text-default-800 dark:text-gray-200 font-medium">ทำสรุปผลงานรวมรายวัน (Daily Recap)</div>
                <div className="text-xs text-default-500 dark:text-gray-400 mt-1">ส่งสรุป Performance รวมให้ในห้อง Notification</div>
              </div>
              <label className="relative inline-flex items-center cursor-pointer">
                <input type="checkbox" className="sr-only peer" checked={reportEnabled} onChange={(e) => setReportEnabled(e.target.checked)} />
                <div className={`w-11 h-6 rounded-full transition-colors ${reportEnabled ? 'bg-blue-500' : 'bg-default-300 dark:bg-gray-600'} peer-checked:after:translate-x-full after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all`}></div>
              </label>
            </div>
            {renderSaveAction()}
          </section>)}

        {/* API Keys  Tab */}
          {activeTab === 'key' && (<section id={`section-key`} className="bg-white dark:bg-gray-800/50 border border-default-200 dark:border-gray-700/50 rounded-2xl p-6 lg:p-8 shadow-sm scroll-mt-28 transition-all hover:shadow-md group">
            <div>
              <h2 className="text-lg font-semibold text-default-900 dark:text-white flex items-center gap-2 mb-2">
                <LuKey className="text-violet-500 dark:text-violet-400" /> API Keys & Models
              </h2>
              <p className="text-sm text-default-500 dark:text-gray-400 mb-6">
                จัดการรหัสผ่านและคีย์ที่ระบบ Agent จะนำไปใช้ในการวิเคราะห์
              </p>
            </div>

            <div className="space-y-4">
              <div className="flex items-center justify-between">
                <div>
                  <h5 className="text-sm font-semibold flex items-center gap-2 dark:text-gray-200">
                    <LuSparkles className="text-violet-500" /> Google Gemini API
                  </h5>
                  <p className="text-xs text-default-500 mt-1">โมเดล AI ที่ใช้สำหรับคิดแผนเทรด</p>
                </div>
              </div>
              <div className="flex gap-2 items-center max-w-xl">
                <div className="relative flex-1">
                  <select
                    value={selectedModel}
                    onChange={(e) => setSelectedModel(e.target.value)}
                    className="w-full px-4 py-2.5 rounded-xl bg-default-50 dark:bg-gray-900 border border-default-200 dark:border-gray-700 text-sm text-default-900 dark:text-gray-100 focus:outline-none appearance-none"
                  >
                    <option value="">เลือกโมเดล (ค่าเริ่มต้น: Gemini 2.5 Flash)</option>
                    {models.map(m => (
                      <option key={m.id} value={m.id}>{m.name}</option>
                    ))}
                  </select>
                  <LuChevronDown className="size-4 absolute right-3 top-1/2 -translate-y-1/2 text-default-400 pointer-events-none" />
                </div>
                <button onClick={testAi} disabled={testing || !emails.some(e => e.apiKey.trim())} className="btn px-4 py-2.5 rounded-xl bg-violet-600 hover:bg-violet-700 text-white text-sm font-medium flex items-center gap-2 disabled:opacity-50 border-none">
                  {testing ? <><LuSparkles className="size-4 animate-spin" /> เช็ค...</> : <><LuZap className="size-4" /> ทดสอบ</>}
                </button>
              </div>
              {testResult && (
                <div className={`p-3 rounded-xl text-sm max-w-xl ${testResult.success ? 'bg-green-50 text-green-600 dark:bg-green-500/10' : 'bg-red-50 text-red-600 dark:bg-red-500/10'}`}>
                  {testResult.success ? <><LuCheck className="inline mr-1" /> {testResult.message}</> : <><LuX className="inline mr-1" /> {testResult.message}</>}
                </div>
              )}
            </div>

            <div className="space-y-4">
              <div className="flex items-center justify-between">
                <div>
                  <h5 className="text-sm font-semibold flex items-center gap-2 dark:text-gray-200">
                    <LuSearch className="text-orange-500" /> Tavily API (News Fetcher)
                  </h5>
                  <p className="text-xs text-default-500 mt-1">โมเดลที่ใช้สำหรับค้นหาข่าวออนไลน์ (รับคีย์ได้ที่ tavily.com)</p>
                </div>
              </div>
              <div className="flex gap-2 items-center max-w-xl">
                <button onClick={testTavily} disabled={testingTavily || !emails.some(e => e.tavilyKey.trim())} className="btn px-4 py-2.5 rounded-xl bg-orange-600 hover:bg-orange-700 text-white text-sm font-medium flex items-center gap-2 disabled:opacity-50 border-none">
                  {testingTavily ? <><LuSparkles className="size-4 animate-spin" /> เช็คโควต้า...</> : <><LuZap className="size-4" /> ทดสอบ Tavily</>}
                </button>
              </div>
              {tavilyResult && (
                <div className={`p-3 rounded-xl text-sm max-w-xl ${tavilyResult.success ? 'bg-green-50 text-green-600 dark:bg-green-500/10' : 'bg-red-50 text-red-600 dark:bg-red-500/10'}`}>
                  {tavilyResult.success ? <><LuCheck className="inline mr-1" /> {tavilyResult.message}</> : <><LuX className="inline mr-1" /> {tavilyResult.message}</>}
                </div>
              )}
            </div>

            <div className="space-y-4">
              <div className="flex items-center justify-between">
                <div>
                  <h5 className="text-sm font-semibold flex items-center gap-2 dark:text-gray-200">
                    <LuMail className="text-blue-500" /> จัดการบัญชี API
                  </h5>
                  <p className="text-xs text-default-500 mt-1">จับคู่ Email กับ Key ทั้งหมดเพื่อให้สลับใช้งานได้ง่าย</p>
                </div>
                <div className="flex gap-2">
                   <button 
                     onClick={() => setShowApiCards(!showApiCards)} 
                     className={`px-3 py-1.5 text-xs font-medium rounded-lg flex items-center gap-1.5 transition-colors ${showApiCards ? 'bg-default-100 hover:bg-default-200 dark:bg-gray-800 dark:hover:bg-gray-700 text-default-700 dark:text-gray-300' : 'bg-blue-50 hover:bg-blue-100 dark:bg-blue-500/10 dark:hover:bg-blue-500/20 text-blue-600 dark:text-blue-400'}`}
                   >
                     {showApiCards ? <><LuEyeOff className="size-3.5" /> ซ่อนทั้งหมด</> : <><LuEye className="size-3.5" /> แสดงทั้งหมด</>}
                   </button>
                </div>
              </div>
              
              <div className="space-y-3">
                {showApiCards && (
                  <>
                    {emails.map((acc, i) => (
                      <div key={i} className={`border ${expandedKeys.includes(i) ? 'border-blue-500/50 shadow-sm dark:border-blue-500/30' : 'border-default-200 dark:border-gray-700/80'} rounded-xl bg-white dark:bg-gray-800/50 overflow-hidden transition-all duration-200`}>
                        <div 
                          className="flex items-center justify-between p-3 cursor-pointer hover:bg-default-50 dark:hover:bg-gray-800 transition-colors"
                          onClick={() => toggleExpand(i)}
                        >
                          <div className="flex items-center gap-3">
                            <div className={`text-default-400 transition-transform duration-200 ${expandedKeys.includes(i) ? 'rotate-90' : ''}`}>
                              <LuChevronRight className="size-4" />
                            </div>
                            <div className="flex flex-col">
                              <span className={`text-sm font-medium ${expandedKeys.includes(i) ? 'text-blue-600 dark:text-blue-400' : 'text-default-900 dark:text-gray-200'}`}>
                                {acc.address || `บัญชีใหม่ (ไม่มีอีเมล ${i + 1})`}
                              </span>
                            </div>
                          </div>
                          <div className="flex items-center gap-1">
                            <button onClick={(e) => { e.stopPropagation(); moveEmailUp(i); }} disabled={i === 0} className="p-1.5 text-default-400 hover:text-blue-500 disabled:opacity-20 rounded hover:bg-default-100 dark:hover:bg-gray-700 transition-colors"><LuChevronUp className="size-4" /></button>
                            <button onClick={(e) => { e.stopPropagation(); moveEmailDown(i); }} disabled={i === emails.length - 1} className="p-1.5 text-default-400 hover:text-blue-500 disabled:opacity-20 rounded hover:bg-default-100 dark:hover:bg-gray-700 transition-colors"><LuChevronDown className="size-4" /></button>
                            {emails.length > 1 && (
                              <button onClick={(e) => { e.stopPropagation(); setEmails(emails.filter((_, j) => j !== i)); }} className="p-1.5 text-red-500 hover:bg-red-500/10 rounded ml-1 transition-colors"><LuTrash2 className="size-4" /></button>
                            )}
                          </div>
                        </div>
                        
                        {expandedKeys.includes(i) && (
                          <div className="p-4 bg-default-50/50 dark:bg-gray-900/30 border-t border-default-100 dark:border-gray-700/50 space-y-3 animate-in fade-in slide-in-from-top-1">
                             <div>
                               <label className="text-xs font-medium text-default-600 dark:text-gray-400 mb-1 block">Google Email</label>
                               <input type="text" value={acc.address} onChange={(e) => { const n = [...emails]; n[i].address = e.target.value; setEmails(n); }} placeholder="example@gmail.com" className="w-full px-3 py-2 text-sm rounded-lg bg-white dark:bg-gray-900 border border-default-200 dark:border-gray-700 focus:ring-1 focus:ring-blue-500/50 hover:border-blue-400 transition-all outline-none" />
                             </div>
                             <div>
                               <label className="text-xs font-medium text-default-600 dark:text-gray-400 mb-1 block">Gemini API Key</label>
                               <input type="text" value={acc.apiKey} onChange={(e) => { const n = [...emails]; n[i].apiKey = e.target.value; setEmails(n); }} placeholder="AIzaSy..." className="w-full px-3 py-2 text-sm rounded-lg bg-white dark:bg-gray-900 border border-default-200 dark:border-gray-700 focus:ring-1 focus:ring-blue-500/50 hover:border-blue-400 transition-all outline-none font-mono" />
                             </div>
                             <div>
                               <label className="text-xs font-medium text-default-600 dark:text-gray-400 mb-1 block">Tavily API Key</label>
                               <input type="text" value={acc.tavilyKey} onChange={(e) => { const n = [...emails]; n[i].tavilyKey = e.target.value; setEmails(n); }} placeholder="tvly-dev-..." className="w-full px-3 py-2 text-sm rounded-lg bg-white dark:bg-gray-900 border border-default-200 dark:border-gray-700 focus:ring-1 focus:ring-blue-500/50 hover:border-blue-400 transition-all outline-none font-mono" />
                             </div>
                          </div>
                        )}
                      </div>
                ))}
                
                <button 
                  onClick={() => {
                    const newIndex = emails.length;
                    setEmails([...emails, {address: '', password: '', apiKey: '', tavilyKey: ''}]);
                    setExpandedKeys([...expandedKeys, newIndex]);
                  }} 
                  className="w-full mt-2 py-3 border-2 border-dashed border-default-200 hover:border-blue-500 dark:border-gray-700 dark:hover:border-blue-500 text-default-500 hover:text-blue-600 dark:text-gray-400 dark:hover:text-blue-400 rounded-xl flex items-center justify-center gap-2 text-sm font-medium transition-colors bg-default-50/50 hover:bg-blue-50 dark:bg-gray-800/20 dark:hover:bg-blue-500/10"
                >
                  <LuPlus className="size-4" /> เพิ่มบัญชี API ใหม่
                </button>
                  </>
                )}
              </div>
            </div>
            {renderSaveAction()}
          </section>)}

        </div>
      </div>
    </div>
  );
};

export default AgentSettings;
