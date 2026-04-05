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
  { key: 'news_hunter', name: 'News Hunter', icon: <LuGlobe size={14} /> },
  { key: 'chart_analyst', name: 'Chart Analyst', icon: <LuActivity size={14} /> },
  { key: 'calendar', name: 'Calendar Watcher', icon: <LuCalendar size={14} /> },
  { key: 'risk_manager', name: 'Risk Manager', icon: <LuShield size={14} /> },
  { key: 'decision_maker', name: 'Decision Maker', icon: <LuBrainCircuit size={14} /> },
];

const extendedAgentConfig = [
  ...agentConfig,
  { key: 'order_executor', name: 'Order Execution', icon: <LuZap size={14} /> },
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
        // No lastRun yet — use modulo sync
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
    <div className={`w-full h-full relative flex flex-col transition-all duration-300 bg-white dark:bg-[#0A0D14] ${!jobEnabled ? 'opacity-70 grayscale-[0.5]' : ''}`}>
      {isClosed && (
        <div className="absolute inset-0 z-50 bg-black/50 backdrop-blur-[1px] flex items-center justify-center p-4 text-center">
           <div className="bg-white/90 dark:bg-zinc-950/90 w-[180px] border border-red-500/20 rounded-xl p-3 shadow-md">
             <LuMonitorOff className="size-6 text-red-500 mx-auto mb-1 opacity-80" />
             <h3 className="text-[11px] font-bold text-default-900 dark:text-white uppercase tracking-wider">Market Closed</h3>
           </div>
        </div>
      )}

      {/* Header Section (Compact) */}
      <div className="card-header border-b border-default-200 dark:border-white/5 p-3 flex flex-col sm:flex-row sm:items-center justify-between gap-3 bg-white dark:bg-[#080B10] relative z-[60]">
        <div className="flex items-center gap-3">
          <div className={`size-8 rounded-lg flex items-center justify-center border shrink-0 ${jobEnabled ? 'bg-primary/5 border-primary/20 text-primary' : 'bg-default-100 dark:bg-white/5 border-default-200 dark:border-white/10 text-default-400'}`}>
            {jobEnabled ? <LuZap className="size-4" /> : <LuMonitorOff className="size-4" />}
          </div>
          <div className="flex flex-col">
            <h2 className="text-[13px] font-black text-default-900 dark:text-gray-100 uppercase tracking-tight flex items-center gap-1.5">
              {symbol}
              {jobEnabled && agentStatus.orchestrator === 'running' && <span className="size-1.5 rounded-full bg-amber-500 animate-pulse"></span>}
              {!jobEnabled && <span className="text-[9px] bg-default-200 dark:bg-white/10 px-1 py-0.5 rounded text-default-500 font-bold ml-1">PAUSED</span>}
              {jobEnabled && timeLeft && agentStatus.orchestrator !== 'running' && (
                 <span className="inline-flex items-center gap-1 rounded-full bg-sky-100 dark:bg-sky-500/20 px-1.5 py-0.5 text-[9px] font-mono font-bold text-sky-700 dark:text-sky-400 ml-1">
                   {String(timeLeft.m).padStart(2, '0')}:{String(timeLeft.s).padStart(2, '0')}
                 </span>
              )}
            </h2>
          </div>
        </div>

        <div className="flex flex-wrap items-center gap-2">
          {onEditJob && (
             <button
               onClick={() => onEditJob()}
               className="p-1 text-default-400 hover:text-default-900 dark:hover:text-white transition-colors"
               title="Edit Setup"
             >
               <LuSettings className="size-3.5" />
             </button>
          )}
          {onToggleJob && (
             <button
               onClick={() => onToggleJob()}
               className={`relative inline-flex h-4 w-7 items-center rounded-full transition-colors ml-1 ${jobEnabled ? 'bg-primary' : 'bg-default-300 dark:bg-default-700'}`}
             >
               <span className={`inline-block size-2.5 transform rounded-full bg-white transition-transform ${jobEnabled ? 'translate-x-4' : 'translate-x-1'}`} />
             </button>
          )}
        </div>
      </div>

      {/* Body Area (Ultra Minimal List) */}
      <div className={`card-body p-2 bg-default-50/50 dark:bg-[#0A0D14] flex-1 overflow-y-auto transition-opacity duration-300 ${!jobEnabled ? 'opacity-50 pointer-events-none' : ''}`}>
        
        <div className="flex flex-col mx-auto w-full relative">
            <div className="absolute left-6 top-6 bottom-4 w-px bg-default-200 dark:bg-white/10 z-0"></div>
            <div className="space-y-1 relative z-10">
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
                    let msg = 'รอการประมวลผล';
                    if (status === 'done' && finalResult && autoTrade) {
                        if (finalResult.final_decision === 'HOLD') {
                            msg = 'ไม่มีการออกออเดอร์ (HOLD)';
                        } else {
                            msg = `ส่งคำสั่งเรียบร้อย (${finalResult.final_decision})`;
                        }
                    } else if (status === 'done' && finalResult && !autoTrade) {
                        msg = `ไม่ได้ส่งคำสั่งเนืองจากปิดการทำงานไว้`;
                    }
                    latestAgentLog = { timestamp: Date.now(), symbol: '', type: 'log', agent: 'order_executor', message: msg };
                }

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
                     className={`flex flex-col py-1.5 px-2 rounded-lg cursor-pointer transition-colors ${
                       isActive ? 'bg-white dark:bg-white/5 border border-primary/20 shadow-sm' : 'hover:bg-default-100/50 dark:hover:bg-white/5 border border-transparent'
                     }`}
                  >
                    <div className="flex items-center gap-2">
                      <div className="size-8 rounded-lg relative flex items-center justify-center shrink-0 bg-default-50 dark:bg-[#0A0D14]">
                        <div className={`absolute inset-0 rounded-lg border transition-all ${
                          isDisabled ? 'bg-default-100 dark:bg-white/5 border-default-200 dark:border-white/10 opacity-50' :
                          isActive ? 'bg-primary/5 border-primary/20' :
                          isDone ? 'bg-emerald-500/5 border-emerald-500/20' :
                          isError ? 'bg-red-500/5 border-red-500/20' :
                          'bg-default-100 dark:bg-white/5 border-default-200 dark:border-white/10'
                        }`} />
                        <div className={`relative z-10 transition-all ${
                          isDisabled ? 'text-default-400' :
                          isActive ? 'text-primary' :
                          isDone ? 'text-emerald-500' :
                          isError ? 'text-red-500' :
                          'text-default-400'
                        }`}>
                           {isActive ? <LuLoader className="animate-spin size-4" /> : agent.icon}
                        </div>
                      </div>

                      <div className="flex-1 flex justify-between items-center min-w-0 ml-1">
                         <div className="flex items-center gap-1.5">
                           <span className={`font-semibold text-[11px] ${isDisabled ? 'text-default-400 line-through' : 'text-default-700 dark:text-gray-200'}`}>
                              {agent.name}
                           </span>
                         </div>
                         {!isDisabled && isActive && <span className="text-[9px] text-primary animate-pulse font-medium">Running...</span>}
                      </div>
                    </div>

                    {!isDisabled && latestAgentLog && (
                       <div className="ml-10 mt-0.5 relative group/log z-20">
                          <p className={`text-[10px] font-mono leading-tight truncate ${
                            isError ? 'text-red-500' : isDone ? 'text-emerald-600 dark:text-emerald-400/80' : 'text-default-500 dark:text-gray-400'
                          }`}>
                            <span className="opacity-40 mr-1.5">[{new Date(latestAgentLog.timestamp).toLocaleTimeString('en-US', { hour12: false })}]</span>
                            {stripEmojis(latestAgentLog.message)}
                          </p>
                          <div className="absolute top-full left-0 mt-1 shadow-xl bg-white dark:bg-zinc-900 border border-default-200 dark:border-white/10 text-default-800 dark:text-white p-2 rounded-lg text-[10px] whitespace-pre-wrap max-w-[250px] sm:max-w-[280px] z-[60] hidden group-hover/log:block pointer-events-none">
                              {stripEmojis(latestAgentLog.message)}
                          </div>
                       </div>
                    )}
                  </div>
                );
              })}
            </div>
        </div>
        
        {/* Separator */}
        <div className="h-px bg-default-200 dark:bg-white/5 mx-2 my-2"></div>

        {/* Final Operation Result */}
        <div className={`mx-2 p-2 rounded-lg border transition-all ${
            agentStatus.orchestrator === 'running' ? 'bg-blue-500/10 border-blue-500/30 shadow-sm' : 'bg-blue-50 dark:bg-blue-900/10 border-blue-200 dark:border-blue-800/30'
        }`}>
           <div className="flex items-center gap-2 mb-1">
             <LuBot className={`size-4 ${agentStatus.orchestrator === 'running' ? 'text-blue-500 animate-pulse' : 'text-blue-400'}`} />
             <span className="text-[11px] font-bold text-blue-800 dark:text-blue-300 uppercase tracking-wide">Operation Result</span>
           </div>
           <div className="ml-6 text-[10px] font-mono text-blue-700 dark:text-blue-200/80">
              {logs.length > 0 ? (
                 <div className="flex gap-2">
                   <span className="opacity-40 shrink-0">[{new Date(logs[logs.length-1].timestamp).toLocaleTimeString('en-US', { hour12: false })}]</span>
                   <span className={`break-words ${agentStatus.orchestrator === 'running' ? 'text-blue-500' : ''}`}>
                     {stripEmojis(logs[logs.length - 1].message)}
                   </span>
                 </div>
              ) : 'Standby...'}
           </div>
        </div>
      </div>
    </div>
  );
};
