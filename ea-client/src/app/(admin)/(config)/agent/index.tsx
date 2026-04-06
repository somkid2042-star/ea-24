import { useState, useRef, useCallback, useEffect } from 'react';
import { 
  LuSave, LuNetwork, LuNewspaper, LuCalendar, 
  LuActivity, LuShieldAlert, LuGitMerge, LuFileText 
} from 'react-icons/lu';
import { getWsUrl } from '@/utils/config';

const WS_URL = getWsUrl();

type TabKey = 'news' | 'calendar' | 'sentiment' | 'risk' | 'correlation' | 'report';

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
  const [riskEnabled, setRiskEnabled] = useState<boolean>(false);
  const [riskMaxDd, setRiskMaxDd] = useState<string>('15');

  // States: Correlation
  const [correlationEnabled, setCorrelationEnabled] = useState<boolean>(false);
  const [correlationMax, setCorrelationMax] = useState<string>('0.85');

  // States: Report
  const [reportEnabled, setReportEnabled] = useState<boolean>(false);

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
          if (c.agent_risk_enabled !== undefined) setRiskEnabled(c.agent_risk_enabled === 'true');
          if (c.agent_risk_max_dd !== undefined) setRiskMaxDd(c.agent_risk_max_dd);
          // Correlation
          if (c.agent_correlation_enabled !== undefined) setCorrelationEnabled(c.agent_correlation_enabled === 'true');
          if (c.agent_correlation_max !== undefined) setCorrelationMax(c.agent_correlation_max);
          // Report
          if (c.agent_report_enabled !== undefined) setReportEnabled(c.agent_report_enabled === 'true');
        }
        if (data.type === 'config_saved') {
          setSuccessMsg('✅ บันทึกการตั้งค่า Agent เรียบร้อยแล้ว');
          setTimeout(() => setSuccessMsg(''), 3000);
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

  const handleSave = () => {
    saveConfig('agent_centralized', centralizedInfo ? 'true' : 'false');
    saveConfig('agent_news_keyword', newsKeyword);
    saveConfig('agent_calendar_enabled', calendarEnabled ? 'true' : 'false');
    saveConfig('agent_calendar_impact', calendarImpact);
    saveConfig('agent_sentiment_enabled', sentimentEnabled ? 'true' : 'false');
    saveConfig('agent_sentiment_indexes', sentimentIndexes);
    saveConfig('agent_risk_enabled', riskEnabled ? 'true' : 'false');
    saveConfig('agent_risk_max_dd', riskMaxDd);
    saveConfig('agent_correlation_enabled', correlationEnabled ? 'true' : 'false');
    saveConfig('agent_correlation_max', correlationMax);
    saveConfig('agent_report_enabled', reportEnabled ? 'true' : 'false');
  };

  const TABS = [
    { key: 'news', icon: <LuNewspaper size={18} />, label: 'News AI' },
    { key: 'calendar', icon: <LuCalendar size={18} />, label: 'Calendar' },
    { key: 'sentiment', icon: <LuActivity size={18} />, label: 'Sentiment' },
    { key: 'risk', icon: <LuShieldAlert size={18} />, label: 'Risk Guard' },
    { key: 'correlation', icon: <LuGitMerge size={18} />, label: 'Correlation' },
    { key: 'report', icon: <LuFileText size={18} />, label: 'Daily Report' },
  ] as const;

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

      <div className="flex bg-default-100 dark:bg-gray-800/60 p-1 rounded-xl overflow-x-auto hide-scrollbar">
        {TABS.map((tab) => (
          <button
            key={tab.key}
            onClick={() => setActiveTab(tab.key)}
            className={`flex items-center gap-2 px-5 py-2.5 rounded-lg text-sm font-medium transition-all whitespace-nowrap ${
              activeTab === tab.key 
                ? 'bg-white dark:bg-gray-700 text-blue-600 dark:text-blue-400 shadow-sm border border-default-200 dark:border-gray-600/50' 
                : 'text-default-600 dark:text-gray-400 hover:text-default-900 dark:hover:text-gray-200 hover:bg-default-200 dark:hover:bg-gray-700/50 border border-transparent'
            }`}
          >
            {tab.icon}
            {tab.label}
          </button>
        ))}
      </div>

      <div className="bg-white dark:bg-gray-800/50 border border-default-200 dark:border-gray-700/50 rounded-2xl p-6 shadow-sm min-h-[350px]">
        {/* News Tab */}
        {activeTab === 'news' && (
          <div className="animate-in fade-in slide-in-from-bottom-2 duration-300">
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
                <p className="text-xs text-default-500 dark:text-gray-500">
                  Agent จะนำคำนี้ไปค้นหาใน Tavily เพื่อสรุปผลกระทบตลาดโดยรวม
                </p>
              </div>
            </div>
          </div>
        )}

        {/* Calendar Tab */}
        {activeTab === 'calendar' && (
          <div className="animate-in fade-in slide-in-from-bottom-2 duration-300">
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
                <label className="text-sm font-medium text-default-700 dark:text-gray-300">ระดับความสำคัญที่ให้ส่งผลต่อการเทรด (Impact Level)</label>
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
          </div>
        )}

        {/* Sentiment Tab */}
        {activeTab === 'sentiment' && (
          <div className="animate-in fade-in slide-in-from-bottom-2 duration-300">
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
                <label className="text-sm font-medium text-default-700 dark:text-gray-300">ดัชนีชี้วัดที่ต้องการให้ตรวจสอบล่วงหน้า (Monitoring Indexes)</label>
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
          </div>
        )}

        {/* Risk Tab */}
        {activeTab === 'risk' && (
          <div className="animate-in fade-in slide-in-from-bottom-2 duration-300">
            <h2 className="text-lg font-semibold text-default-900 dark:text-white flex items-center gap-2 mb-2">
              <LuShieldAlert className="text-red-500 dark:text-red-400" /> Global Risk & Kill Switch
            </h2>
            <p className="text-sm text-default-500 dark:text-gray-400 mb-6">
              ผู้พิทักษ์พอร์ตโฟลิโอ ตรวจจับความผันผวนพร้อมกันทุกคู่เงิน เพื่อสั่ง Standby หากตลาดมีอาการแครช (Flash Crash)
            </p>

            <div className="space-y-6 max-w-xl">
              <div className="flex items-center justify-between p-4 bg-red-50 dark:bg-red-900/10 rounded-xl border border-red-200 dark:border-red-900/30">
                <div>
                  <div className="text-red-900 dark:text-red-200 font-medium">เปิดใช้งาน Global Kill Switch</div>
                  <div className="text-xs text-red-700 dark:text-red-400/70 mt-1">ปิดระบบฉุกเฉินหากเข้าข่ายความเสี่ยงสูงจัด</div>
                </div>
                <label className="relative inline-flex items-center cursor-pointer">
                  <input type="checkbox" className="sr-only peer" checked={riskEnabled} onChange={(e) => setRiskEnabled(e.target.checked)} />
                  <div className={`w-11 h-6 rounded-full peer-focus:outline-none transition-colors ${riskEnabled ? 'bg-red-500' : 'bg-default-300 dark:bg-gray-600'} peer-checked:after:translate-x-full after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all`}></div>
                </label>
              </div>

              <div className="space-y-2">
                <label className="text-sm font-medium text-default-700 dark:text-gray-300">Global Max Drawdown (%)</label>
                <div className="relative">
                  <input
                    type="number"
                    value={riskMaxDd}
                    onChange={(e) => setRiskMaxDd(e.target.value)}
                    disabled={!riskEnabled}
                    className="w-full bg-white dark:bg-gray-900 border border-default-300 dark:border-gray-700 text-default-900 dark:text-white rounded-lg pl-4 pr-10 py-2.5 focus:outline-none focus:border-red-500 dark:focus:border-red-500 disabled:opacity-50 disabled:bg-default-100"
                    placeholder="15"
                  />
                  <span className="absolute right-4 top-2.5 text-default-500 font-medium">%</span>
                </div>
                <p className="text-xs text-default-500 dark:text-gray-500">
                  ถ้ายอดติดลบรวมทุกคู่เงินเกิน % นี้ Global Agent จะส่งคำสั่งให้หยุดเทรดทั้งหมดทันที
                </p>
              </div>
            </div>
          </div>
        )}

        {/* Correlation Tab */}
        {activeTab === 'correlation' && (
          <div className="animate-in fade-in slide-in-from-bottom-2 duration-300">
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
          </div>
        )}

        {/* Report Tab */}
        {activeTab === 'report' && (
          <div className="animate-in fade-in slide-in-from-bottom-2 duration-300">
            <h2 className="text-lg font-semibold text-default-900 dark:text-white flex items-center gap-2 mb-2">
              <LuFileText className="text-emerald-500 dark:text-emerald-400" /> Global Daily Reporter
            </h2>
            <p className="text-sm text-default-500 dark:text-gray-400 mb-6">
              ให้ตัวกลางคอยรวบรวมข้อมูล P&L และความเคลื่อนไหวจาก AI ของทุกๆ คู่เงิน เพื่อสรุปให้คุณฟังครั้งเดียวตอนเช้า
            </p>

            <div className="space-y-6 max-w-xl">
              <div className="flex items-center justify-between p-4 bg-default-50 dark:bg-gray-900/50 rounded-xl border border-default-200 dark:border-gray-700/50">
                <div>
                  <div className="text-default-800 dark:text-gray-200 font-medium">ทำสรุปผลงานรวมรายวัน (Daily Recap)</div>
                  <div className="text-xs text-default-500 dark:text-gray-400 mt-1">ส่งสรุป Performance รวมให้ในห้อง Notification</div>
                </div>
                <label className="relative inline-flex items-center cursor-pointer">
                  <input type="checkbox" className="sr-only peer" checked={reportEnabled} onChange={(e) => setReportEnabled(e.target.checked)} />
                  <div className={`w-11 h-6 rounded-full peer-focus:outline-none transition-colors ${reportEnabled ? 'bg-blue-500' : 'bg-default-300 dark:bg-gray-600'} peer-checked:after:translate-x-full after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all`}></div>
                </label>
              </div>
            </div>
          </div>
        )}
      </div>

      <div className="fixed bottom-0 left-0 right-0 bg-white/80 dark:bg-[#151821]/80 backdrop-blur-xl border-t border-default-200 dark:border-gray-700/50 p-4 z-10">
        <div className="max-w-5xl mx-auto flex items-center justify-between lg:pl-[240px]">
          <div>
            {successMsg && <span className="text-green-500 font-medium flex items-center gap-2"><span className="w-2 h-2 rounded-full bg-green-500 animate-pulse"></span> {successMsg}</span>}
            {!wsConnected && <span className="text-red-500 font-medium flex items-center gap-2"><span className="w-2 h-2 rounded-full bg-red-500 animate-pulse"></span> การเชื่อมต่อขาดหาย</span>}
          </div>
          <button
            onClick={handleSave}
            className="px-6 py-2.5 shadow-md shadow-blue-500/20 bg-blue-600 hover:bg-blue-500 active:scale-95 text-white rounded-xl transition-all flex items-center gap-2 font-medium"
          >
            <LuSave size={18} />
            บันทึกการตั้งค่า Global Agent
          </button>
        </div>
      </div>
    </div>
  );
};

export default AgentSettings;
