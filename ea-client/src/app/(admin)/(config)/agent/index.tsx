import { useState, useRef, useCallback, useEffect } from 'react';
import { LuSave, LuNetwork, LuBot, LuNewspaper } from 'react-icons/lu';
import { getWsUrl } from '@/utils/config';

const WS_URL = getWsUrl();

const AgentSettings = () => {
  const [wsConnected, setWsConnected] = useState(false);
  const [centralizedInfo, setCentralizedInfo] = useState<boolean>(true);
  const [newsKeyword, setNewsKeyword] = useState<string>('Global Forex Market');
  const [successMsg, setSuccessMsg] = useState('');
  
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
          setCentralizedInfo(c.agent_centralized !== 'false'); // default true
          setNewsKeyword(c.agent_news_keyword || 'Global Forex Market');
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
  };

  return (
    <div className="p-6 max-w-4xl mx-auto space-y-6">
      <div className="flex items-center gap-3 mb-8">
        <div className="w-12 h-12 bg-blue-500/20 text-blue-400 rounded-xl flex items-center justify-center">
          <LuNetwork size={24} />
        </div>
        <div>
          <h1 className="text-2xl font-bold text-gray-100">Agent Configuration</h1>
          <p className="text-gray-400">จัดการ Agent ส่วนกลาง (ค้นหาข่าว และอื่นๆ)</p>
        </div>
      </div>

      <div className="bg-gray-800/50 border border-gray-700/50 rounded-2xl p-6 relative overflow-hidden group">
        <div className="absolute top-0 right-0 p-8 opacity-5 group-hover:opacity-10 transition-opacity pointer-events-none">
          <LuBot size={120} />
        </div>
        
        <h2 className="text-lg font-semibold text-white flex items-center gap-2 mb-4">
          <LuNewspaper className="text-blue-400" /> Global News Agent
        </h2>
        <p className="text-sm text-gray-400 mb-6">
          ระบบจะทำการค้นหาข่าวสารให้ 1 ครั้งต่อชั่วโมง เพื่อลดการใช้ API Credit และส่งข่าวเดียวกันให้ทุกคู่เงินใช้วางแผนการเทรด
        </p>

        <div className="space-y-6 max-w-xl">
          <div className="flex items-center justify-between p-4 bg-gray-900/50 rounded-xl border border-gray-700/50">
            <div>
              <div className="text-gray-200 font-medium">เปิดใช้งาน Centralized News</div>
              <div className="text-xs text-gray-400 mt-1">ใช้ข่าวส่วนกลางร่วมกันทุกคู่เงิน (แนะนำให้เปิด)</div>
            </div>
            <label className="relative inline-flex items-center cursor-pointer">
              <input type="checkbox" className="sr-only peer" checked={centralizedInfo} onChange={(e) => setCentralizedInfo(e.target.checked)} />
              <div className={`w-11 h-6 rounded-full peer-focus:outline-none transition-colors ${centralizedInfo ? 'bg-blue-500' : 'bg-gray-600'} peer-checked:after:translate-x-full after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:rounded-full after:h-5 after:w-5 after:transition-all`}></div>
            </label>
          </div>

          <div className="space-y-2">
            <label className="text-sm font-medium text-gray-300">คำค้นหาข่าวศูนย์กลาง (Global Search Keyword)</label>
            <input
              type="text"
              value={newsKeyword}
              onChange={(e) => setNewsKeyword(e.target.value)}
              disabled={!centralizedInfo}
              className="w-full bg-gray-900 border border-gray-700 text-white rounded-lg px-4 py-2.5 focus:outline-none focus:border-blue-500 disabled:opacity-50"
              placeholder="ตัวอย่าง: Global Forex Market News"
            />
            <p className="text-xs text-gray-500">
              Agent จะนำคำนี้ไปค้นหาใน Tavily เพื่อสรุปผลกระทบตลาดโดยรวม
            </p>
          </div>

          <div className="pt-4 flex items-center justify-between">
            <button
              onClick={handleSave}
              className="px-6 py-2.5 bg-blue-600 hover:bg-blue-500 text-white rounded-lg transition-colors flex items-center gap-2 font-medium"
            >
              <LuSave size={18} />
              บันทึกการตั้งค่า Agent
            </button>
            {successMsg && <span className="text-green-400 text-sm">{successMsg}</span>}
            {!wsConnected && <span className="text-red-400 text-sm">การเชื่อมต่อขาดหาย</span>}
          </div>
        </div>
      </div>
    </div>
  );
};

export default AgentSettings;
