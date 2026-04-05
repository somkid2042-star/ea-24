import React, { useRef, useEffect } from 'react';
import { LuBot, LuTerminal, LuCheck, LuX, LuLoader, LuShield, LuCalendar, LuGlobe, LuActivity, LuBrainCircuit, LuZap, LuMonitorOff } from 'react-icons/lu';

export type AiLog = { timestamp: number; agent: string; status: string; message: string; };
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
  logs: AiLog[];
  agentStatus: AgentStatusMap;
  finalResult: any;
}

const agentConfig = [
  { key: 'news_hunter', name: 'News Hunter', desc: 'ค้นหาข่าวสารทั่วโลก', icon: <LuGlobe size={20} />, gradient: 'from-cyan-500 to-blue-600', shadow: 'shadow-cyan-500/30' },
  { key: 'chart_analyst', name: 'Chart Analyst', desc: 'วิเคราะห์โครงสร้างกราฟรูปตัวแปร Multi-TF', icon: <LuActivity size={20} />, gradient: 'from-purple-500 to-pink-600', shadow: 'shadow-purple-500/30' },
  { key: 'calendar', name: 'Calendar Watcher', desc: 'เฝ้าระวังวันประกาศเวลาสำคัญ', icon: <LuCalendar size={20} />, gradient: 'from-amber-500 to-orange-600', shadow: 'shadow-amber-500/30' },
  { key: 'risk_manager', name: 'Risk Manager', desc: 'ประเมินความเสี่ยงและ Margin', icon: <LuShield size={20} />, gradient: 'from-emerald-400 to-teal-500', shadow: 'shadow-emerald-500/30' },
  { key: 'decision_maker', name: 'Decision Maker', desc: 'เปรียบเทียบน้ำหนักตรรกะหาข้อสรุป', icon: <LuBrainCircuit size={20} />, gradient: 'from-rose-500 to-red-600', shadow: 'shadow-rose-500/30' },
];

const parseTfData = (reasoning: string) => {
  if (!reasoning) return null;
  const match = reasoning.match(/Best TF:\s*([A-Z0-9]+).+?M5:([A-Z]+)\s+M15:([A-Z]+)\s+H1:([A-Z]+)\s+H4:([A-Z]+)/);
  if (!match) return null;
  return [
    { tf: 'M5', signal: match[2], isBest: match[1] === 'M5' },
    { tf: 'M15', signal: match[3], isBest: match[1] === 'M15' },
    { tf: 'H1', signal: match[4], isBest: match[1] === 'H1' },
    { tf: 'H4', signal: match[5], isBest: match[1] === 'H4' },
  ];
};

export const AgentPanel: React.FC<AgentPanelProps> = ({ title, symbol, isClosed, logs, agentStatus, finalResult }) => {
  const logsEndRef = useRef<HTMLDivElement>(null);
  
  useEffect(() => {
    logsEndRef.current?.scrollIntoView({ behavior: "smooth" });
  }, [logs]);

  return (
    <div className="flex flex-col gap-6 mt-8 relative rounded-2xl overflow-hidden">
      {isClosed && (
        <div className="absolute inset-0 z-50 bg-black/60 backdrop-blur-[2px] flex items-center justify-center p-6 text-center rounded-2xl">
           <div className="bg-[#090C15] border border-red-500/30 p-6 rounded-2xl shadow-[0_0_40px_rgba(239,68,68,0.2)] max-w-sm w-full relative overflow-hidden group">
               <div className="absolute inset-0 bg-gradient-to-br from-red-500/10 flex-transparent opacity-0 group-hover:opacity-100 transition-opacity"></div>
               <LuMonitorOff className="size-10 text-red-500 mx-auto mb-4 drop-shadow-[0_0_10px_rgba(239,68,68,0.5)]" />
               <h3 className="text-xl font-black text-white tracking-tight mb-2 uppercase">Market Closed</h3>
               <p className="text-red-400 text-sm font-bold opacity-90">ตลาดปิดหยุดการคำนวณจาก AI</p>
           </div>
        </div>
      )}
      {/* Decorative Blur */}
      <div className="absolute -top-10 -left-10 w-40 h-40 bg-primary/10 rounded-full blur-3xl pointer-events-none"></div>

      {/* Header Section */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 bg-background dark:bg-white/[0.02] border border-default-200 dark:border-white/5 p-4 rounded-2xl shadow-sm backdrop-blur-xl relative overflow-hidden z-10">
        <div className="absolute top-0 right-0 w-64 h-64 bg-gradient-to-br from-primary/10 to-purple-500/10 blur-2xl transform translate-x-1/2 -translate-y-1/2 pointer-events-none rounded-full"></div>
        
        <div className="flex items-center gap-4 relative z-10">
          <div className="size-14 rounded-2xl bg-gradient-to-br from-primary to-indigo-600 flex items-center justify-center shadow-lg shadow-primary/30 shrink-0">
            <LuBot size={28} className="text-white drop-shadow-md" />
          </div>
          <div>
            <h2 className="text-xl font-black text-default-900 tracking-tight flex items-center gap-2">
              {title}
            </h2>
            <div className="flex items-center gap-2 mt-1.5">
              <span className="flex items-center gap-1.5 px-2.5 py-0.5 rounded-lg bg-primary/10 border border-primary/20 text-[10px] font-extrabold text-primary uppercase shadow-sm">
                 <LuActivity size={12} /> {symbol}
              </span>
              <span className={`text-[10px] font-bold px-2 py-0.5 rounded-lg flex items-center gap-1.5 ${
                 agentStatus.orchestrator === 'running' ? 'bg-amber-500/10 text-amber-600 border border-amber-500/20' : 
                 agentStatus.orchestrator === 'done' ? 'bg-emerald-500/10 text-emerald-600 border border-emerald-500/20' : 'bg-default-100 text-default-500 border border-default-200'
              }`}>
                 {agentStatus.orchestrator === 'running' && <span className="size-1.5 bg-amber-500 rounded-full animate-ping"></span>}
                 {agentStatus.orchestrator === 'done' && <LuCheck size={12} />}
                 {agentStatus.orchestrator === 'running' ? 'PROCESS ONGOING' : agentStatus.orchestrator === 'done' ? 'ANALYSIS COMPLETE' : 'STANDBY'}
              </span>
            </div>
          </div>
        </div>

        {/* Multi-TF Badge Group */}
        <div className="flex items-center gap-2 bg-default-100/50 p-1.5 rounded-xl border border-default-200/50 relative z-10">
          <span className="text-[10px] font-black text-default-400 uppercase tracking-widest pl-2 pr-1 hidden sm:inline-block">Timeframes</span>
          {['M5', 'M15', 'H1', 'H4'].map(tf => {
            const tfData = finalResult ? parseTfData(finalResult.chart?.reasoning)?.find(t => t.tf === tf) : null;
            return (
              <div key={tf} className={`flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-bold transition-all duration-300 ${
                tfData?.isBest ? 'bg-white dark:bg-slate-800 text-primary border border-primary/30 shadow-md shadow-primary/20 scale-105' :
                tfData ? 'bg-white dark:bg-slate-800 text-default-600 border border-default-200 shadow-sm' : 'bg-transparent text-default-400'
              }`}>
                <span>{tf}</span>
                {tfData && (
                  <span className={`text-[10px] font-black ${
                    tfData.signal === 'BUY' ? 'text-emerald-500 dark:text-emerald-400 drop-shadow-sm' : 
                    tfData.signal === 'SELL' ? 'text-red-500 dark:text-red-400 drop-shadow-sm' : 'text-amber-500 dark:text-amber-400 drop-shadow-sm'
                  }`}>
                    {tfData.signal}
                  </span>
                )}
                {tfData?.isBest && <LuZap className="size-3 text-primary animate-pulse" />}
              </div>
            );
          })}
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-12 gap-6 relative z-10">
        
        {/* Left Column: AI Pipeline Visualizer */}
        <div className="lg:col-span-5 flex flex-col gap-4">
          <div className="bg-background dark:bg-slate-900 border border-default-200 dark:border-white/5 rounded-3xl p-5 shadow-xl shadow-black/5 flex flex-col h-[520px] relative overflow-hidden">
            <div className="absolute top-0 inset-x-0 h-1 bg-gradient-to-r from-transparent via-default-300 dark:via-white/10 to-transparent"></div>
            
            <div className="flex items-center justify-between mb-5">
              <h3 className="font-black text-default-800 text-sm flex items-center gap-2">
                <LuBrainCircuit className="text-primary size-5" />
                AI PIPELINE EXECUTION
              </h3>
            </div>

            <div className="flex-1 overflow-y-auto pr-2 space-y-4 custom-scrollbar relative">
              {/* Connecting line behind items */}
              <div className="absolute left-[27px] top-6 bottom-6 w-0.5 bg-gradient-to-b from-default-200 via-default-200 to-transparent z-0"></div>

              {agentConfig.map((agent) => {
                const status = agentStatus[agent.key as keyof AgentStatusMap] || 'idle';
                const latestLog = [...logs].reverse().find(l => l.agent === agent.key)?.message || '';
                
                const isActive = status === 'running';
                const isDone = status === 'done';
                const isError = status === 'error';

                return (
                  <div key={agent.key} className="relative z-10 flex gap-4 group">
                    {/* Status Node */}
                    <div className="relative flex flex-col items-center">
                       <div className={`w-14 h-14 rounded-2xl flex items-center justify-center shadow-lg transition-all duration-300 z-10 ${
                         isActive ? `bg-gradient-to-br ${agent.gradient} ${agent.shadow} transform scale-110` : 
                         isDone ? 'bg-default-100 dark:bg-white/5 border border-default-200 dark:border-white/10 shadow-none' : 
                         isError ? 'bg-red-500 shadow-red-500/30' : 
                         'bg-default-50 border border-default-200 border-dashed opacity-60 grayscale'
                       }`}>
                          {isActive ? <LuLoader className="animate-spin text-white size-6" /> : 
                           isDone ? <LuCheck className="text-primary size-6 opacity-70" /> :
                           isError ? <LuX className="text-white size-6" /> :
                           <div className="text-default-400">{agent.icon}</div>}
                       </div>
                    </div>

                    {/* Agent Details Card */}
                    <div className={`flex-1 rounded-2xl border p-3 transition-all duration-500 overflow-hidden relative ${
                      isActive ? 'bg-white dark:bg-white/[0.02] border-primary/30 shadow-xl shadow-primary/5' :
                      isDone ? 'bg-default-50/50 dark:bg-transparent border-default-200/50 dark:border-white/5 opacity-80' :
                      isError ? 'bg-red-50 dark:bg-red-950/20 border-red-200 dark:border-red-500/20' :
                      'bg-transparent border-transparent opacity-40'
                    }`}>
                      {isActive && <div className="absolute top-0 right-0 w-32 h-32 bg-primary/10 blur-2xl rounded-full transform translate-x-10 -translate-y-10"></div>}
                      
                      <div className="relative z-10">
                         <div className="flex justify-between items-start mb-1">
                           <span className={`font-black tracking-tight text-sm ${isActive ? 'text-primary' : 'text-default-800'}`}>{agent.name}</span>
                           <span className={`text-[9px] font-black uppercase px-2 py-0.5 rounded-md ${
                              isActive ? 'bg-primary/10 text-primary' :
                              isDone ? 'bg-emerald-500/10 text-emerald-600' :
                              isError ? 'bg-red-500/10 text-red-600' : 'hidden'
                           }`}>{status}</span>
                         </div>
                         <p className="text-[11px] text-default-500 leading-snug font-medium mb-1.5">{agent.desc}</p>
                         
                         {/* Output Terminal Snippet */}
                         {latestLog && (
                           <div className={`mt-2 text-[10px] font-mono p-2 rounded-xl backdrop-blur-md border border-white/10 ${
                             isActive ? 'bg-default-100 dark:bg-black/40 text-primary' : 'bg-default-100/50 dark:bg-black/20 text-default-500'
                           } whitespace-nowrap overflow-hidden text-ellipsis`}>
                             <span className="opacity-50 mr-2">&gt;</span>{latestLog}
                           </div>
                         )}
                      </div>
                    </div>
                  </div>
                );
              })}
            </div>
          </div>
        </div>

        {/* Right Column: Premium Hacker Console */}
        <div className="lg:col-span-7 rounded-3xl bg-[#09090b] border border-[#27272a] shadow-2xl shadow-black/80 flex flex-col overflow-hidden relative h-[520px]">
          {/* Subtle glow behind console */}
          <div className="absolute inset-0 bg-gradient-to-b from-primary/5 to-transparent opacity-50 pointer-events-none"></div>

          {/* Mac-like Traffic Lights Header */}
          <div className="flex items-center justify-between px-5 py-3.5 bg-[#18181b] border-b border-[#27272a] relative z-10">
            <div className="flex items-center gap-4">
              <div className="flex gap-2 group">
                <div className="size-3 rounded-full bg-red-500/80 border border-red-500/20 shadow-[0_0_10px_rgba(239,68,68,0.4)] group-hover:bg-red-400 transition-colors" />
                <div className="size-3 rounded-full bg-amber-500/80 border border-amber-500/20 shadow-[0_0_10px_rgba(245,158,11,0.4)] group-hover:bg-amber-400 transition-colors" />
                <div className="size-3 rounded-full bg-emerald-500/80 border border-emerald-500/20 shadow-[0_0_10px_rgba(16,185,129,0.4)] group-hover:bg-emerald-400 transition-colors" />
              </div>
              <div className="h-4 w-[1px] bg-[#27272a]"></div>
              <div className="flex items-center gap-2">
                <LuTerminal className="text-primary size-4 opacity-80" />
                <span className="font-mono text-xs text-zinc-400 font-semibold tracking-widest">AGENT_CONSOLE v3.1_PRO</span>
              </div>
            </div>
            <span className="flex items-center gap-2 text-[10px] font-mono text-zinc-500 bg-zinc-900/80 px-2 py-1 rounded border border-zinc-800">
              <span className={`size-1.5 rounded-full ${agentStatus.orchestrator === 'running' ? 'bg-primary animate-pulse shadow-[0_0_8px_var(--tw-colors-primary)]' : 'bg-zinc-600'}`}></span>
              {agentStatus.orchestrator === 'running' ? 'LIVE SYNC' : 'DISCONNECTED'}
            </span>
          </div>
          
          <div className="flex-1 overflow-y-auto px-5 py-6 font-mono text-[12px] leading-relaxed space-y-1 custom-scrollbar relative z-10">
            {logs.length === 0 && (
              <div className="flex items-center justify-center h-full text-zinc-600 text-center flex-col">
                <div className="size-16 rounded-2xl bg-zinc-800/50 flex items-center justify-center mb-4">
                  <LuTerminal className="size-8 opacity-40" />
                </div>
                <p className="text-sm font-semibold text-zinc-400">System Standing By</p>
                <p className="text-xs text-zinc-600 mt-1 max-w-xs">Waiting for triggers to begin the AI multi-agent analytical sequence.</p>
              </div>
            )}

            {logs.map((log, i) => {
              const isError = log.status === 'error' || log.message.includes('❌');
              const isSuccess = log.status === 'done' || log.message.includes('✅');
              const isWarning = log.message.includes('⚠️');
              
              return (
                <div key={i} className="flex gap-4 hover:bg-white/[0.03] px-3 py-1.5 rounded-lg transition-colors group">
                  <span className="text-zinc-600 shrink-0 select-none font-medium">
                    {new Date(log.timestamp).toLocaleTimeString('en-US', { hour12: false, hour: '2-digit', minute: '2-digit', second: '2-digit' })}
                  </span>
                  <span className={`shrink-0 w-[140px] whitespace-nowrap text-right font-bold tracking-tight ${
                    log.agent === 'orchestrator' ? 'text-blue-400' :
                    log.agent === 'chart_analyst' ? 'text-purple-400' :
                    log.agent === 'news_hunter' ? 'text-cyan-400' :
                    log.agent === 'decision_maker' ? 'text-rose-400' :
                    log.agent === 'risk_manager' ? 'text-emerald-400' :
                    log.agent === 'calendar' ? 'text-amber-400' : 'text-zinc-400'
                  }`}>
                    [{log.agent?.toUpperCase() || 'SYSTEM'}]
                  </span>
                  <span className={`flex-1 break-words ${
                    isSuccess ? 'text-emerald-400 drop-shadow-[0_0_5px_rgba(52,211,153,0.3)]' : 
                    isError ? 'text-red-400 drop-shadow-[0_0_5px_rgba(248,113,113,0.3)]' : 
                    isWarning ? 'text-amber-300' : 'text-zinc-300'
                  }`}>
                    {log.message}
                  </span>
                </div>
              );
            })}
            
            {agentStatus.orchestrator === 'running' && (
              <div className="flex gap-4 px-3 py-1.5 opacity-70">
                <span className="text-zinc-600 shrink-0 font-medium">... ... ..</span>
                <span className="shrink-0 w-[140px]"></span>
                <span className="flex-1 flex gap-2 items-center">
                   <div className="size-1.5 bg-primary rounded-full animate-bounce" style={{ animationDelay: '0ms' }}></div>
                   <div className="size-1.5 bg-primary rounded-full animate-bounce" style={{ animationDelay: '150ms' }}></div>
                   <div className="size-1.5 bg-primary rounded-full animate-bounce" style={{ animationDelay: '300ms' }}></div>
                </span>
              </div>
            )}
            <div ref={logsEndRef} className="h-4" />
          </div>
        </div>
      </div>
    </div>
  );
};
