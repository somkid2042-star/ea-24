import React, { useEffect, useState, useRef } from 'react';
import { LuGlobe, LuActivity, LuCalendar, LuShield, LuBrainCircuit, LuLoader, LuTerminal, LuBot, LuSettings, LuZap, LuMonitorOff } from 'react-icons/lu';

export type AiLog = { timestamp: number; symbol: string; agent: string; message: string; type: string };
export type AgentStatus = 'idle' | 'running' | 'done' | 'error';
export type AgentStatusMap = {
  news_hunter: AgentStatus;
  chart_analyst: AgentStatus;
  calendar: AgentStatus;
  risk_manager: AgentStatus;
  decision_maker: AgentStatus;
  orchestrator: AgentStatus;
};

interface AgentPanelProps {
  title: string;
  symbol: string;
  isClosed?: boolean;
  jobEnabled?: boolean;
  onToggleJob?: () => void;
  logs: AiLog[];
  agentStatus: AgentStatusMap;
  autoTrade?: boolean;
  disabledAgents?: string[];
  interval?: number;
  lastRunTime?: number | null;
  onEditJob?: () => void;
  agentStatusM1?: AgentStatusMap;
  logsM1?: AiLog[];
}

const stripEmojis = (msg: string) => {
  if (!msg) return '';
  return msg.replace(/[\p{Extended_Pictographic}⚠️]/gu, '').replace(/[✅❌⚠️📊🏁💡🔴🟢]/g, '').trim();
};

const agentConfig = [
  { key: 'news_hunter', name: 'วิเคราะห์ข่าวกรอง (News)', icon: <LuGlobe size={16} /> },
  { key: 'chart_analyst', name: 'วิเคราะห์เทคนิค (Chart)', icon: <LuActivity size={16} /> },
  { key: 'calendar', name: 'ติดตามปฏิทินศก. (Calendar)', icon: <LuCalendar size={16} /> },
  { key: 'risk_manager', name: 'บริหารความเสี่ยง (Risk)', icon: <LuShield size={16} /> },
  { key: 'decision_maker', name: 'ผู้ตัดสินใจขั้นสุดท้าย', icon: <LuBrainCircuit size={16} /> },
];

export const AgentPanel: React.FC<AgentPanelProps> = ({ symbol, isClosed, jobEnabled = true, interval, lastRunTime, onToggleJob, onEditJob, logs, logsM1 = [], agentStatus, agentStatusM1 }) => {
  const [timeLeft, setTimeLeft] = useState<{ m: number, s: number } | null>(null);
  const logsM1Ref = useRef<HTMLDivElement>(null);
  const logsAIRef = useRef<HTMLDivElement>(null);
  const [autoScrollM1, setAutoScrollM1] = useState(true);
  const [autoScrollAI, setAutoScrollAI] = useState(true);

  // Auto-scroll M1 Logs
  useEffect(() => {
     if (autoScrollM1 && logsM1Ref.current) {
         logsM1Ref.current.scrollTop = logsM1Ref.current.scrollHeight;
     }
  }, [logsM1, autoScrollM1]);

  // Auto-scroll AI Logs
  useEffect(() => {
     if (autoScrollAI && logsAIRef.current) {
         logsAIRef.current.scrollTop = logsAIRef.current.scrollHeight;
     }
  }, [logs, autoScrollAI]);
  
  useEffect(() => {
    if (!interval || !jobEnabled || agentStatus.orchestrator === 'running') {
      setTimeLeft(null);
      return;
    }
    
    const totalMs = interval * 60 * 1000;
    
    const updateCountdown = () => {
      if (lastRunTime) {
        const target = lastRunTime + totalMs;
        const remaining = Math.max(0, target - Date.now());
        const totalSecs = Math.floor(remaining / 1000);
        setTimeLeft({ m: Math.floor(totalSecs / 60), s: totalSecs % 60 });
      } else {
        const totalSec = interval * 60;
        const now = Math.floor(Date.now() / 1000);
        const rem = totalSec - (now % totalSec);
        setTimeLeft({ m: Math.floor(rem / 60), s: rem % 60 });
      }
    };
    
    updateCountdown();
    const id = setInterval(updateCountdown, 1000);
    return () => clearInterval(id);
  }, [lastRunTime, interval, jobEnabled, agentStatus.orchestrator]);

  return (
    <div className={`w-full h-full relative flex flex-col transition-all duration-300 bg-white dark:bg-[#0A0D14] rounded-[24px] border border-gray-100 dark:border-white/5 shadow-sm overflow-hidden min-h-[500px] ${!jobEnabled ? 'opacity-70 grayscale-[0.3]' : ''}`}>
      {isClosed && (
        <div className="absolute inset-0 z-50 bg-black/50 backdrop-blur-[1px] flex items-center justify-center p-4 text-center">
           <div className="bg-white/90 dark:bg-zinc-950/90 w-[180px] border border-red-500/20 rounded-2xl p-4 shadow-xl">
             <LuMonitorOff className="size-8 text-red-500 mx-auto mb-2 opacity-90" />
             <h3 className="text-xs font-black text-default-900 dark:text-white uppercase tracking-widest">Market Closed</h3>
           </div>
        </div>
      )}

      {/* Header Section */}
      <div className="border-b border-gray-100 dark:border-white/5 p-4 flex items-center justify-between bg-white dark:bg-[#0A0D14] z-40 relative">
        <div className="flex items-center gap-3">
          <div className="size-10 rounded-full bg-[#EFF6FF] text-[#3B82F6] flex items-center justify-center shrink-0">
            {jobEnabled ? <LuZap className="size-[22px] fill-[#3B82F6]/20" /> : <LuMonitorOff className="size-[22px]" />}
          </div>
          <div className="flex items-center gap-2">
            <h2 className="text-base font-bold text-gray-800 dark:text-gray-100 font-mono tracking-tight">
              {symbol}
            </h2>
            {jobEnabled && agentStatus.orchestrator === 'running' && (
              <span className="flex items-center gap-1.5 px-2 py-0.5 rounded-full bg-blue-50 dark:bg-blue-500/10 text-[10px] font-bold text-blue-600 dark:text-blue-400 uppercase">
                <span className="size-1.5 rounded-full bg-blue-500 animate-pulse"></span>
                กำลังทำงาน
              </span>
            )}
            {!jobEnabled && (
              <span className="px-2 py-0.5 rounded-full bg-gray-100 dark:bg-gray-800 text-[10px] font-bold text-gray-500 dark:text-gray-400 uppercase border border-gray-200 dark:border-gray-700">ระงับการใช้งาน</span>
            )}
            {jobEnabled && timeLeft && agentStatus.orchestrator !== 'running' && (
               <span className="inline-flex items-center rounded-full bg-blue-50/80 dark:bg-blue-900/30 px-2 py-0.5 text-[11px] font-mono font-bold text-blue-600 dark:text-blue-400">
                 {String(timeLeft.m).padStart(2, '0')}:{String(timeLeft.s).padStart(2, '0')}
               </span>
            )}
          </div>
        </div>

        <div className="flex items-center gap-2">
          {onEditJob && (
             <button
               onClick={() => onEditJob()}
               className="p-1 text-gray-400 hover:text-gray-700 dark:hover:text-gray-200 transition-colors mr-1"
               title="Settings"
             >
               <LuSettings className="size-5" />
             </button>
          )}
          {onToggleJob && (
             <button
               onClick={() => onToggleJob()}
               className={`relative inline-flex h-[26px] w-[46px] items-center rounded-full transition-colors ${jobEnabled ? 'bg-blue-500 shadow-[0_0_12px_rgba(59,130,246,0.3)]' : 'bg-gray-200 dark:bg-gray-700 border border-gray-300 dark:border-gray-600'}`}
             >
               <span className={`size-5 rounded-full bg-white transition-transform ${jobEnabled ? 'translate-x-[22px]' : 'translate-x-[2px]'}`} />
             </button>
          )}
        </div>
      </div>
      
      {/* Operation Logs Stack */}
      <div className="px-6 pb-6 pt-2 space-y-4">
        
        {/* Server / M1 Logs Timeline */}
        <div className="p-4 rounded-[16px] border-[1.5px] border-default-200 dark:border-white/5 bg-white dark:bg-[#0A0D14] flex flex-col flex-1 h-[250px]">
           <div className="flex items-center justify-between mb-4 shrink-0">
             <div className="flex items-center gap-2">
                 <LuLoader className={`size-3.5 text-indigo-500 ${agentStatusM1?.orchestrator === 'running' ? 'animate-spin' : ''}`} />
                 <span className="text-[11px] font-black text-indigo-500 tracking-widest uppercase leading-none mt-0.5">Server Logs (M1 Fast-Track)</span>
             </div>
             {!autoScrollM1 && (
                 <button onClick={() => setAutoScrollM1(true)} className="text-[10px] font-bold text-indigo-500 bg-indigo-50 dark:bg-indigo-500/10 px-2 py-0.5 rounded-full hover:bg-indigo-100 dark:hover:bg-indigo-500/20 transition-colors">
                    Scroll to Latest
                 </button>
             )}
           </div>
           
           <div 
               ref={logsM1Ref}
               onScroll={(e) => {
                   const target = e.currentTarget;
                   const isAtBottom = target.scrollHeight - target.scrollTop - target.clientHeight < 40;
                   setAutoScrollM1(isAtBottom);
               }}
               className="flex-1 overflow-y-auto [&::-webkit-scrollbar]:hidden relative pl-[10px]"
           >
              <div className="absolute left-[20px] top-[14px] bottom-0 w-px bg-default-200 dark:bg-white/10 z-0" />
              <div className="space-y-4 pb-4">
                  {logsM1.length > 0 ? logsM1.map((log, i) => (
                      <div key={i} className="flex gap-4 relative z-10 w-full animate-in fade-in slide-in-from-bottom-2 duration-300">
                          <div className={`size-[22px] rounded-full flex items-center justify-center shrink-0 border bg-white dark:bg-[#0B101E] border-indigo-200 text-indigo-500 mt-0.5 shadow-sm`}>
                             {agentConfig.find(a => a.key === log.agent)?.icon || <LuTerminal size={10} />}
                          </div>
                          <div className="flex flex-col pb-1 w-full min-w-0 pr-2">
                             <div className="flex justify-between items-baseline gap-2">
                                <span className="text-[12px] font-bold leading-none mb-1 text-indigo-600 dark:text-indigo-400 capitalize truncate">{log.agent.replace('_', ' ')}</span>
                                <span className="text-[9px] text-default-400 shrink-0">{new Date(log.timestamp).toLocaleTimeString([], {hour: '2-digit', minute:'2-digit', second:'2-digit'})}</span>
                             </div>
                             <span className="text-[11px] text-default-600 leading-relaxed dark:text-gray-400 line-clamp-2">
                                 {stripEmojis(log.message)}
                             </span>
                          </div>
                      </div>
                  )) : (
                      <div className="text-[11px] text-default-400 italic pl-10 pb-4">สแตนด์บาย M1...</div>
                  )}
              </div>
           </div>
        </div>

        {/* AI Logs Timeline */}
        <div className="p-4 rounded-[16px] border-[1.5px] border-default-200 dark:border-white/5 bg-white dark:bg-[#0A0D14] flex flex-col flex-1 h-[250px]">
           <div className="flex items-center justify-between mb-4 shrink-0">
             <div className="flex items-center gap-2">
                 <LuBot className={`size-4 text-[#3B82F6] ${agentStatus?.orchestrator === 'running' ? 'animate-pulse' : ''}`} />
                 <span className="text-[11px] font-black text-[#3B82F6] tracking-widest uppercase leading-none mt-0.5">AI Agents Logs (Interval)</span>
             </div>
             {!autoScrollAI && (
                 <button onClick={() => setAutoScrollAI(true)} className="text-[10px] font-bold text-blue-500 bg-blue-50 dark:bg-blue-500/10 px-2 py-0.5 rounded-full hover:bg-blue-100 dark:hover:bg-blue-500/20 transition-colors">
                    Scroll to Latest
                 </button>
             )}
           </div>
           
           <div 
               ref={logsAIRef}
               onScroll={(e) => {
                   const target = e.currentTarget;
                   const isAtBottom = target.scrollHeight - target.scrollTop - target.clientHeight < 40;
                   setAutoScrollAI(isAtBottom);
               }}
               className="flex-1 overflow-y-auto [&::-webkit-scrollbar]:hidden relative pl-[10px]"
           >
              <div className="absolute left-[20px] top-[14px] bottom-0 w-px bg-default-200 dark:bg-white/10 z-0" />
              <div className="space-y-4 pb-4">
                  {logs.length > 0 ? logs.map((log, i) => (
                      <div key={i} className="flex gap-4 relative z-10 w-full animate-in fade-in slide-in-from-bottom-2 duration-300">
                          <div className={`size-[22px] rounded-full flex items-center justify-center shrink-0 border bg-white dark:bg-[#0B101E] border-blue-200 text-blue-500 mt-0.5 shadow-sm`}>
                             {agentConfig.find(a => a.key === log.agent)?.icon || <LuBot size={10} />}
                          </div>
                          <div className="flex flex-col pb-1 w-full min-w-0 pr-2">
                             <div className="flex justify-between items-baseline gap-2">
                                <span className="text-[12px] font-bold leading-none mb-1 text-blue-600 dark:text-blue-400 capitalize truncate">{log.agent.replace('_', ' ')}</span>
                                <span className="text-[9px] text-default-400 shrink-0">{new Date(log.timestamp).toLocaleTimeString([], {hour: '2-digit', minute:'2-digit', second:'2-digit'})}</span>
                             </div>
                             <span className="text-[11px] text-default-600 leading-relaxed dark:text-gray-400 line-clamp-2">
                                 {stripEmojis(log.message)}
                             </span>
                          </div>
                      </div>
                  )) : (
                      <div className="text-[11px] text-default-400 italic pl-10 pb-4">รอรับคำสั่ง AI รอบถัดไป...</div>
                  )}
              </div>
           </div>
        </div>

      </div>
    </div>
  );
};
