import React, { useEffect, useState, useRef } from 'react';
import { LuBot, LuLoader, LuTerminal, LuSettings, LuZap, LuMonitorOff, LuServer, LuBrainCircuit, LuSparkles } from 'react-icons/lu';

export type AiLog = { timestamp: number; symbol: string; agent: string; message: string; type: string; status?: string };
export type AgentStatus = 'idle' | 'running' | 'done' | 'error';
export type AgentStatusMap = {
  news_hunter: AgentStatus;
  chart_analyst: AgentStatus;
  calendar: AgentStatus;
  risk_manager: AgentStatus;
  decision_maker: AgentStatus;
  orchestrator: AgentStatus;
  pipeline_v8?: AgentStatus;
  gemma_filter?: AgentStatus;
  gemini_confirm?: AgentStatus;
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
  interval?: number;
  lastRunTime?: number | null;
  onEditJob?: () => void;
  finalResult?: any;
}

const stripEmojis = (msg: string) => {
  if (!msg) return '';
  return msg.replace(/[\p{Extended_Pictographic}\u{FE0F}\u{200D}]/gu, '').replace(/[\[\]]/g, '').replace(/\s{2,}/g, ' ').trim();
};

// Pipeline v8 stages
const STAGES = [
  { key: 'pipeline_v8',    label: 'Server Scan',    icon: <LuServer size={14} />,        desc: '10 กลยุทธ์ × 5 TF' },
  { key: 'gemma_filter',   label: 'Gemma 4',        icon: <LuSparkles size={14} />,      desc: 'ตรวจสอบ + ประวัติ' },
  { key: 'gemini_confirm', label: 'Gemini',          icon: <LuBrainCircuit size={14} />,  desc: 'ยืนยันขั้นสุดท้าย' },
];

export const AgentPanel: React.FC<AgentPanelProps> = ({ symbol, isClosed, jobEnabled = true, interval, lastRunTime, onToggleJob, onEditJob, logs, agentStatus, finalResult }) => {
  const [timeLeft, setTimeLeft] = useState<{ m: number, s: number } | null>(null);
  const logsRef = useRef<HTMLDivElement>(null);
  const [autoScroll, setAutoScroll] = useState(true);

  useEffect(() => {
     if (autoScroll && logsRef.current) {
         logsRef.current.scrollTop = logsRef.current.scrollHeight;
     }
  }, [logs, autoScroll]);
  
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

  // Determine which stage is active
  const getStageStatus = (key: string) => {
    const status = (agentStatus as any)?.[key];
    if (status === 'running') return 'running';
    if (status === 'done') return 'done';
    if (status === 'error') return 'error';
    return 'idle';
  };

  return (
    <div className={`flex flex-col transition-all duration-300 overflow-hidden ${!jobEnabled ? 'opacity-60' : ''}`}>
      {isClosed && (
        <div className="absolute inset-0 z-50 bg-black/50 backdrop-blur-[2px] flex items-center justify-center">
           <div className="bg-white/90 dark:bg-zinc-950/90 border border-red-500/20 rounded-2xl px-6 py-4 shadow-xl text-center">
             <LuMonitorOff className="size-7 text-red-500 mx-auto mb-2" />
             <h3 className="text-xs font-black text-gray-900 dark:text-white uppercase tracking-widest">Market Closed</h3>
           </div>
        </div>
      )}

      {/* Header */}
      <div className="border-b border-gray-100 dark:border-white/5 px-5 py-3.5 flex items-center justify-between">
        <div className="flex items-center gap-3">
          <div className="size-9 rounded-xl bg-gradient-to-br from-blue-500 to-indigo-600 text-white flex items-center justify-center shadow-lg shadow-blue-500/20">
            {jobEnabled ? <LuZap className="size-4" /> : <LuMonitorOff className="size-4" />}
          </div>
          <div>
            <div className="flex items-center gap-2">
              <h2 className="text-sm font-bold text-gray-900 dark:text-white font-mono">{symbol}</h2>
              {jobEnabled && agentStatus.orchestrator === 'running' && (
                <span className="flex items-center gap-1.5 px-2 py-0.5 rounded-full bg-blue-500/10 text-[10px] font-bold text-blue-500 uppercase">
                  <span className="size-1.5 rounded-full bg-blue-500 animate-pulse" />
                  วิเคราะห์
                </span>
              )}
              {!jobEnabled && (
                <span className="px-2 py-0.5 rounded-full bg-gray-100 dark:bg-gray-800 text-[10px] font-bold text-gray-500 uppercase">ปิดอยู่</span>
              )}
              {jobEnabled && timeLeft && agentStatus.orchestrator !== 'running' && (
                 <span className="font-mono text-[11px] font-bold text-blue-500 bg-blue-500/10 px-2 py-0.5 rounded-full tabular-nums">
                   {String(timeLeft.m).padStart(2, '0')}:{String(timeLeft.s).padStart(2, '0')}
                 </span>
              )}
            </div>
            <p className="text-[10px] text-gray-500 mt-0.5">Pipeline v8 • every {interval}m</p>
          </div>
        </div>

        <div className="flex items-center gap-2">
          {onEditJob && (
             <button onClick={() => onEditJob()} className="p-1.5 text-gray-400 hover:text-gray-700 dark:hover:text-white transition-colors rounded-lg hover:bg-gray-100 dark:hover:bg-white/5" title="Settings">
               <LuSettings className="size-4" />
             </button>
          )}
          {onToggleJob && (
             <button
               onClick={() => onToggleJob()}
               className={`relative inline-flex h-6 w-11 items-center rounded-full transition-colors ${jobEnabled ? 'bg-blue-500' : 'bg-gray-300 dark:bg-gray-700'}`}
             >
               <span className={`size-4 rounded-full bg-white shadow transition-transform ${jobEnabled ? 'translate-x-[24px]' : 'translate-x-[3px]'}`} />
             </button>
          )}
        </div>
      </div>
      
      {/* Pipeline v8 — 3 Stages */}
      <div className="px-5 py-4 border-b border-gray-100 dark:border-white/5">
        <div className="flex items-center gap-1">
          {STAGES.map((stage, i) => {
            const status = getStageStatus(stage.key);
            return (
              <React.Fragment key={stage.key}>
                <div className={`flex-1 rounded-xl p-3 text-center transition-all duration-500 ${
                  status === 'running' ? 'bg-blue-500/10 border border-blue-500/30 ring-1 ring-blue-500/20' :
                  status === 'done' ? 'bg-emerald-500/10 border border-emerald-500/20' :
                  status === 'error' ? 'bg-red-500/10 border border-red-500/20' :
                  'bg-gray-50 dark:bg-white/5 border border-transparent'
                }`}>
                  <div className={`flex items-center justify-center gap-1.5 mb-1 ${
                    status === 'running' ? 'text-blue-500' :
                    status === 'done' ? 'text-emerald-500' :
                    status === 'error' ? 'text-red-500' :
                    'text-gray-400'
                  }`}>
                    {status === 'running' ? <LuLoader className="size-3.5 animate-spin" /> : stage.icon}
                    <span className="text-[11px] font-bold">{stage.label}</span>
                  </div>
                  <p className="text-[9px] text-gray-500">{stage.desc}</p>
                </div>
                {i < STAGES.length - 1 && (
                  <div className={`text-xs w-4 text-center ${status === 'done' ? 'text-emerald-400' : 'text-gray-300 dark:text-gray-600'}`}>→</div>
                )}
              </React.Fragment>
            );
          })}
        </div>
      </div>

      {/* Logs Timeline */}
      <div className="flex-1 overflow-hidden">
        <div 
            ref={logsRef}
            onScroll={(e) => {
                const target = e.currentTarget;
                setAutoScroll(target.scrollHeight - target.scrollTop - target.clientHeight < 40);
            }}
            onMouseLeave={() => setAutoScroll(true)}
            className="h-full overflow-y-auto px-5 py-3 [&::-webkit-scrollbar]:hidden"
        >
           <div className="space-y-2.5 relative">
               {logs.length > 0 ? logs.map((log, i) => {
                   const isGemma = log.agent === 'gemma_filter';
                   const isGemini = log.agent === 'gemini_confirm';
                   const isPipeline = log.agent === 'pipeline_v8';
                   const isDone = log.status === 'done';
                   const isRunning = log.status === 'running';

                   return (
                     <div key={i} className="flex gap-3 items-start animate-in fade-in slide-in-from-bottom-1 duration-200">
                       <div className={`size-7 rounded-lg flex items-center justify-center shrink-0 mt-0.5 ${
                         isPipeline ? 'bg-blue-500/10 text-blue-500' :
                         isGemma ? 'bg-purple-500/10 text-purple-500' :
                         isGemini ? 'bg-amber-500/10 text-amber-500' :
                         'bg-gray-100 dark:bg-white/5 text-gray-400'
                       }`}>
                         {isPipeline ? <LuServer size={13} /> :
                          isGemma ? <LuSparkles size={13} /> :
                          isGemini ? <LuBrainCircuit size={13} /> :
                          <LuTerminal size={13} />}
                       </div>
                       <div className="flex-1 min-w-0">
                         <div className="flex items-baseline justify-between gap-2">
                           <span className={`text-[11px] font-bold capitalize ${
                             isPipeline ? 'text-blue-500' :
                             isGemma ? 'text-purple-500' :
                             isGemini ? 'text-amber-500' : 'text-gray-500'
                           }`}>
                             {log.agent?.replace(/_/g, ' ')}
                           </span>
                           <div className="flex items-center gap-1.5 shrink-0">
                             {isRunning && <span className="size-1.5 rounded-full bg-blue-500 animate-pulse" />}
                             <span className="text-[9px] text-gray-400 font-mono">{new Date(log.timestamp).toLocaleTimeString([], {hour:'2-digit', minute:'2-digit', second:'2-digit'})}</span>
                           </div>
                         </div>
                         <p className="text-[11px] text-gray-600 dark:text-gray-400 leading-relaxed mt-0.5 break-words">
                           {stripEmojis(log.message)}
                         </p>
                       </div>
                     </div>
                   );
               }) : (
                   <div className="flex flex-col items-center justify-center py-10 text-center opacity-50">
                     <LuBot size={28} className="text-gray-400 mb-2" />
                     <p className="text-[11px] text-gray-500">รอรับข้อมูลจาก Pipeline v8...</p>
                   </div>
               )}
           </div>
        </div>
      </div>
    </div>
  );
};
