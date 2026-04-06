import React, { useEffect, useState } from 'react';
import { LuBrainCircuit, LuGlobe, LuActivity, LuCalendar, LuShield, LuMonitorOff, LuZap, LuLoader, LuBot, LuSettings } from "react-icons/lu";

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
  finalResult: any;
  autoTrade?: boolean;
  onToggleAutoTrade?: () => void;
  disabledAgents?: string[];
  interval?: number;
  lastRunTime?: number | null;
  onEditJob?: () => void;
  onToggleAgent?: (agentKey: string) => void;
}

const stripEmojis = (msg: string) => {
  if (!msg) return '';
  return msg.replace(/[\p{Extended_Pictographic}⚠️]/gu, '').replace(/[✅❌⚠️📊🏁💡🔴🟢]/g, '').trim();
};

const agentConfig = [
  { key: 'news_hunter', name: 'News Hunter', icon: <LuGlobe size={16} /> },
  { key: 'chart_analyst', name: 'Chart Analyst', icon: <LuActivity size={16} /> },
  { key: 'calendar', name: 'Calendar Watcher', icon: <LuCalendar size={16} /> },
  { key: 'risk_manager', name: 'Risk Manager', icon: <LuShield size={16} /> },
  { key: 'decision_maker', name: 'Decision Maker', icon: <LuBrainCircuit size={16} /> },
];

const extendedAgentConfig = [
  ...agentConfig,
  { key: 'order_executor', name: 'Order Execution', icon: <LuZap size={16} /> },
];

export const AgentPanel: React.FC<AgentPanelProps> = ({ symbol, isClosed, jobEnabled = true, interval, lastRunTime, onToggleJob, onEditJob, logs, agentStatus, finalResult, autoTrade, onToggleAutoTrade, disabledAgents = [], onToggleAgent }) => {
  const [timeLeft, setTimeLeft] = useState<{ m: number, s: number } | null>(null);
  
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
          <div className="size-10 rounded-2xl bg-blue-50/80 dark:bg-blue-500/10 border-2 border-blue-100/50 dark:border-blue-500/20 text-blue-500 flex items-center justify-center shrink-0 shadow-sm">
            {jobEnabled ? <LuZap className="size-5" /> : <LuMonitorOff className="size-5" />}
          </div>
          <div className="flex items-center gap-2">
            <h2 className="text-base font-bold text-gray-800 dark:text-gray-100 font-mono tracking-tight">
              {symbol}
            </h2>
            {jobEnabled && agentStatus.orchestrator === 'running' && (
              <span className="flex items-center gap-1.5 px-2 py-0.5 rounded-full bg-blue-50 dark:bg-blue-500/10 text-[10px] font-bold text-blue-600 dark:text-blue-400 uppercase">
                <span className="size-1.5 rounded-full bg-blue-500 animate-pulse"></span>
                Running
              </span>
            )}
            {!jobEnabled && (
              <span className="px-2 py-0.5 rounded-full bg-gray-100 dark:bg-gray-800 text-[10px] font-bold text-gray-500 dark:text-gray-400 uppercase border border-gray-200 dark:border-gray-700">PAUSED</span>
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
               <span className={`inline-block size-5 transform rounded-full bg-white transition-transform ${jobEnabled ? 'translate-x-[22px] shadow-sm' : 'translate-x-[2px] shadow-sm'}`} />
             </button>
          )}
        </div>
      </div>

      {/* Timeline Body Area */}
      <div className={`px-6 py-6 flex-1 overflow-y-auto ${!jobEnabled ? 'opacity-50 pointer-events-none' : ''}`}>
        <div className="relative">
            {/* The Vertical Line Connecting Icons */}
            <div className="absolute left-[20px] top-[10px] bottom-[20px] w-px bg-gray-200 dark:bg-white/10 z-0" />

            <div className="space-y-6 relative z-10 w-full">
              {extendedAgentConfig.map((agent) => {
                let isDisabled = disabledAgents.includes(agent.key);
                let status = agentStatus[agent.key as keyof AgentStatusMap] || 'idle';
                
                if (agent.key === 'order_executor') {
                   isDisabled = !autoTrade;
                   if (agentStatus.orchestrator === 'running' || agentStatus.orchestrator === 'idle') {
                       status = 'idle';
                   } else if (agentStatus.orchestrator === 'done' || agentStatus.orchestrator === 'error') {
                       status = 'done';
                   }
                }
                
                const isActive = !isDisabled && status === 'running';
                const isDone = !isDisabled && status === 'done';
                const isError = !isDisabled && status === 'error';
                
                const agentLogs = logs.filter(l => l.agent === agent.key && l.message);
                let latestAgentLog = agentLogs.length > 0 ? agentLogs[agentLogs.length - 1] : null;

                if (agent.key === 'order_executor' && (!latestAgentLog || !latestAgentLog.timestamp)) {
                    let msg = 'รอการประมวลผล (Standby)';
                    if (status === 'done' && finalResult && autoTrade) {
                        if (finalResult.final_decision === 'HOLD') {
                            msg = 'ไม่มีการออกออเดอร์ (HOLD)';
                        } else {
                            msg = `ส่งคำสั่งเรียบร้อย (${finalResult.final_decision})`;
                        }
                    } else if (status === 'done' && finalResult && !autoTrade) {
                        msg = `ไม่ได้ส่งคำสั่งเนื่องจากปิดการทำงานไว้`;
                    }
                    latestAgentLog = { timestamp: Date.now(), symbol: '', type: 'log', agent: 'order_executor', message: msg };
                }

                // Color Themes Based on Status
                const boxTheme = isDisabled ? 'bg-gray-50 dark:bg-[#131826] border-gray-100 dark:border-white/5 text-gray-400' 
                               : isError ? 'bg-red-50 dark:bg-red-500/10 border-red-200 dark:border-red-500/20 text-red-500'
                               : isActive ? 'bg-blue-50 dark:bg-blue-500/10 border-blue-200 dark:border-blue-500/30 text-blue-600 shadow-[0_0_15px_rgba(59,130,246,0.2)]'
                               : isDone ? 'bg-emerald-50/30 dark:bg-emerald-500/10 border-emerald-200/60 dark:border-emerald-500/20 text-emerald-600'
                               : 'bg-white dark:bg-[#0A0D14] border-gray-200 dark:border-white/10 text-gray-400';
                               
                const logTextColor = isError ? 'text-red-500' 
                                   : isDone ? 'text-emerald-500/90 dark:text-emerald-400' 
                                   : 'text-gray-400 dark:text-gray-500';

                return (
                  <div 
                     key={agent.key} 
                     onClick={() => {
                         if (agent.key === 'order_executor') {
                             if (onToggleAutoTrade) onToggleAutoTrade();
                         } else {
                             if (onToggleAgent) onToggleAgent(agent.key);
                         }
                     }}
                     className="flex items-start gap-5 cursor-pointer group"
                  >
                    {/* Icon Bubble */}
                    <div className={`size-10 rounded-2xl flex items-center justify-center shrink-0 border-[1.5px] transition-all duration-300 relative z-20 ${boxTheme}`}>
                        {isActive ? <LuLoader className="animate-spin size-4" /> : agent.icon}
                    </div>

                    {/* Text Area */}
                    <div className="flex flex-col pt-0.5 flex-1 min-w-0">
                       <div className="flex items-center gap-2">
                         <span className={`font-bold text-[14px] font-mono tracking-tight ${isDisabled ? 'text-gray-400 line-through' : 'text-slate-700 dark:text-gray-200 group-hover:text-blue-600 transition-colors'}`}>
                            {agent.name}
                         </span>
                         {!isDisabled && isActive && <span className="text-[10px] text-blue-500 animate-pulse font-bold bg-blue-50 px-2 py-0.5 rounded-md border border-blue-100">Running...</span>}
                       </div>

                       {!isDisabled && latestAgentLog && (
                          <div className="mt-[2px]">
                             <p className={`text-[13px] font-mono leading-relaxed line-clamp-2 pr-2 ${logTextColor}`}>
                               <span className="opacity-50 mr-1.5 font-bold">[{new Date(latestAgentLog.timestamp).toLocaleTimeString('en-US', { hour12: false })}]</span>
                               {stripEmojis(latestAgentLog.message)}
                             </p>
                          </div>
                       )}
                    </div>
                  </div>
                );
              })}
            </div>
        </div>
      </div>
      
      {/* Final Operation Result */}
      <div className="p-5 pb-6">
        <div className={`p-4 rounded-[16px] border-[1.5px] transition-all ${
            agentStatus.orchestrator === 'running' ? 'bg-blue-50/80 dark:bg-blue-500/5 border-blue-200 dark:border-blue-500/20 shadow-sm' : 'bg-blue-50/40 dark:bg-blue-900/10 border-blue-100 dark:border-blue-800/30'
        }`}>
           <div className="flex items-center gap-2.5 mb-2">
             <LuBot className={`size-5 ${agentStatus.orchestrator === 'running' ? 'text-blue-500 animate-pulse' : 'text-blue-500'}`} />
             <span className="text-[13px] font-extrabold text-blue-700 dark:text-blue-300 uppercase tracking-widest leading-none mt-0.5">Operation Result</span>
           </div>
           <div className="ml-8 text-[13px] font-mono text-blue-600 dark:text-blue-300">
              {logs.length > 0 ? (
                 <div className="flex flex-col gap-0.5">
                   <div className="flex gap-2">
                     <span className="opacity-40 shrink-0 font-bold">[{new Date(logs[logs.length-1].timestamp).toLocaleTimeString('en-US', { hour12: false })}]</span>
                     <span className={`break-words font-medium ${agentStatus.orchestrator === 'running' ? 'text-blue-600' : ''}`}>
                       {stripEmojis(logs[logs.length - 1].message)}
                     </span>
                   </div>
                 </div>
              ) : 'Standby...'}
           </div>
        </div>
      </div>
    </div>
  );
};
