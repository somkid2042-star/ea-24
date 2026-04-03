import { useState, useEffect, useRef } from 'react';
import { LuBot, LuTerminal, LuSettings } from 'react-icons/lu';

type AiLog = { timestamp: number; type: string; message: string; };

const OpenClawDashboard = () => {
  const [logs, setLogs] = useState<AiLog[]>([]);
  const [connected, setConnected] = useState(false);
  const logsEndRef = useRef<HTMLDivElement>(null);
  
  useEffect(() => {
    // Scroll to bottom when logs update
    logsEndRef.current?.scrollIntoView({ behavior: "smooth" });
  }, [logs]);

  useEffect(() => {
    // Initial dummy logs to demonstrate UI works
    setLogs([
      { timestamp: Date.now() - 60000, type: 'info', message: 'กำลังรอการเชื่อมต่อ OpenClaw ผ่าน MCP...' }
    ]);

    const WS_URL = `ws://${window.location.hostname}:8080/`;
    const ws = new WebSocket(WS_URL);
    
    ws.onmessage = (evt) => {
      try {
        const data = JSON.parse(evt.data);
        if (data.type === 'ai_log') {
          setLogs(prev => [...prev, { timestamp: Date.now(), type: data.log_type || 'info', message: data.message }]);
        }
        if (data.type === 'welcome') {
          // Check if server reports AI connected
          // For now, we mock true if ea_connected, or add real ai_connected field in the future
        }
      } catch (e) {}
    };

    return () => ws.close();
  }, []);

  return (
    <div className="flex flex-col gap-6 h-full p-4 md:p-6 w-full relative z-10 font-sans">
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
        <div>
          <h1 className="text-2xl font-bold tracking-tight text-default-900 flex items-center gap-3">
            <LuBot className="size-7 text-primary" />
            ระบบตรวจสอบ OpenClaw AI
          </h1>
          <p className="text-default-500 mt-1">
            แสดงสถานะและบันทึกการทำงานของ AI ผ่าน Model Context Protocol (MCP) แบบเรียลไทม์
          </p>
        </div>
        <div className="flex items-center gap-4 bg-card px-4 py-2 rounded-xl shadow-sm border border-default-100 dark:border-default-200/20">
          <div className="flex flex-col">
            <span className="text-xs text-default-500 font-semibold uppercase tracking-wider">สถานะการเชื่อมต่อ</span>
            <span className={`text-sm font-bold flex items-center gap-2 ${connected ? 'text-success' : 'text-warning'}`}>
              <span className={`inline-block size-2 rounded-full ${connected ? 'bg-success animate-pulse' : 'bg-warning'}`} />
              {connected ? 'เชื่อมต่อสำเร็จ' : 'รอการเชื่อมต่อ...'}
            </span>
          </div>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6 flex-1 min-h-[500px]">
        
        {/* Terminal / Logs View */}
        <div className="lg:col-span-2 card bg-[#0f111a] text-gray-300 !rounded-2xl border-none shadow-xl flex flex-col overflow-hidden">
          <div className="bg-[#1a1d27] px-4 py-3 flex items-center gap-3 border-b border-gray-800">
            <LuTerminal className="text-gray-400" />
            <span className="font-mono text-xs text-gray-400 uppercase font-semibold">บันทึกการทำงาน MCP (Logs)</span>
          </div>
          <div className="p-4 overflow-y-auto flex-1 font-mono text-sm leading-relaxed space-y-2">
            {logs.map((log, i) => (
              <div key={i} className="flex gap-3">
                <span className="text-gray-500 shrink-0">[{new Date(log.timestamp).toLocaleTimeString()}]</span>
                <span className={`${log.type === 'action' ? 'text-green-400 font-semibold' : log.type === 'error' ? 'text-red-400' : 'text-gray-300'}`}>
                  {log.message}
                </span>
              </div>
            ))}
            <div ref={logsEndRef} />
          </div>
        </div>

        {/* Configuration Guide */}
        <div className="card !rounded-2xl !p-6 flex flex-col gap-6">
          <div>
            <h3 className="text-lg font-bold text-default-900 flex items-center gap-2 mb-2">
              <LuSettings className="text-primary" /> คู่มือการเชื่อมต่อ
            </h3>
            <p className="text-sm text-default-600 leading-relaxed">
              หากต้องการเชื่อมต่อ OpenClaw หรือบอท AI เข้ากับระบบ EA-24 ให้นำที่อยู่ Endpoint ด้านล่างนี้ไปใส่ในไฟล์ตั้งค่าของ AI
            </p>
          </div>

          <div className="bg-default-100 dark:bg-default-200/20 p-4 rounded-xl border border-default-200 dark:border-default-200/10">
            <span className="block text-xs font-semibold text-default-500 uppercase mb-2">ที่อยู่ Endpoint สำหรับเชื่อมต่อ</span>
            <code className="block w-full text-sm font-mono text-primary bg-background dark:bg-black/20 p-2 rounded selectable">
              http://{window.location.hostname}:8080/mcp
            </code>
          </div>

          <div className="text-sm text-default-500">
            <p className="mb-2"><strong>ขั้นตอนการตั้งค่า:</strong></p>
            <ol className="list-decimal pl-4 space-y-2">
              <li>เปิดไฟล์การตั้งค่าของตัว <code>OpenClaw</code></li>
              <li>เพิ่มเซิร์ฟเวอร์ลงในหัวข้อ <code>mcpServers</code> โดยชี้เป้าหมายมาที่พอร์ต 8080</li>
              <li>รีสตาร์ท OpenClaw เพื่อให้ระบบโหลดเครื่องมือ (Tools) อย่างการดูกราฟและการออกออเดอร์เข้าไป</li>
            </ol>
          </div>
          
          <div className="mt-auto pt-4 border-t border-default-100 dark:border-default-200/10">
             <button
               onClick={() => {
                 setLogs(prev => [...prev, { timestamp: Date.now(), type: 'action', message: 'คุณกำลังทดสอบการทำงานจำลองของระบบบันทึก...' }]);
                 setConnected(true);
               }}
               className="w-full btn btn-primary flex items-center justify-center gap-2"
             >
               จำลองทดสอบการเชื่อมต่อ
             </button>
          </div>
        </div>

      </div>
    </div>
  );
};

export default OpenClawDashboard;
