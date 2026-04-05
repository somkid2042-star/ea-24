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
    <div className="card w-full relative mt-6 mb-6 overflow-hidden">
      {isClosed && (
        <div className="absolute inset-0 z-50 bg-black/60 backdrop-blur-[2px] flex items-center justify-center p-6 text-center">
           <div className="bg-zinc-950 max-w-sm w-full relative overflow-hidden group border border-red-500/30 shadow-[0_0_40px_rgba(239,68,68,0.2)] rounded-lg">
               <div className="p-6">
                 <div className="absolute inset-0 bg-gradient-to-br from-red-500/10 flex-transparent opacity-0 group-hover:opacity-100 transition-opacity"></div>
                 <LuMonitorOff className="size-10 text-red-500 mx-auto mb-4 drop-shadow-[0_0_10px_rgba(239,68,68,0.5)]" />
                 <h3 className="text-xl font-black text-white tracking-tight mb-2 uppercase">Market Closed</h3>
                 <p className="text-red-400 text-sm font-bold opacity-90">ตลาดปิดหยุดการคำนวณจาก AI</p>
               </div>
           </div>
        </div>
      )}

      {/* Header Section */}
      <div className="card-header border-b border-default-200 dark:border-default-300/10 p-4 flex flex-col md:flex-row md:items-center justify-between gap-4 relative z-10">
        <div className="flex items-center gap-3 relative z-10">
          <div className="size-10 rounded-xl bg-primary/10 flex items-center justify-center border border-primary/20 shrink-0">
            <LuBot className="size-5 text-primary drop-shadow-sm" />
          </div>
          <div>
            <h2 className="text-sm font-bold text-default-900 tracking-tight flex items-center gap-2">
              {title}
            </h2>
            <div className="flex items-center gap-2 mt-1">
              <span className="flex items-center gap-1.5 px-2 py-0.5 rounded-md bg-default-100 dark:bg-default-50 border border-default-200 dark:border-default-200/50 text-[9px] font-bold uppercase shadow-sm">
                 <LuActivity size={10} className="text-primary" /> {symbol}
              </span>
              <span className={`text-[9px] font-bold px-2 py-0.5 rounded-md flex items-center gap-1.5 ${
                 agentStatus.orchestrator === 'running' ? 'bg-amber-500/10 text-amber-600' : 
                 agentStatus.orchestrator === 'done' ? 'bg-emerald-500/10 text-emerald-600' : 'bg-default-100 dark:bg-default-50 text-default-500'
              }`}>
                 {agentStatus.orchestrator === 'running' && <span className="size-1 bg-amber-500 rounded-full animate-ping"></span>}
                 {agentStatus.orchestrator === 'done' && <LuCheck size={10} />}
                 {agentStatus.orchestrator === 'running' ? 'PROCESS ONGOING' : agentStatus.orchestrator === 'done' ? 'ANALYSIS COMPLETE' : 'STANDBY'}
              </span>
            </div>
          </div>
        </div>

        {/* Multi-TF Badge Group */}
        <div className="flex items-center gap-1.5 bg-default-50 dark:bg-black/20 p-1.5 rounded-lg border border-default-200/50 dark:border-default-300/10 relative z-10">
          <span className="text-[9px] font-bold text-default-400 uppercase tracking-widest pl-1 pr-1 hidden sm:inline-block">Timeframes</span>
          {['M5', 'M15', 'H1', 'H4'].map(tf => {
            const tfData = finalResult ? parseTfData(finalResult.chart?.reasoning)?.find(t => t.tf === tf) : null;
            return (
              <div key={tf} className={`flex items-center gap-1 px-2 py-1 rounded-md text-[10px] font-bold transition-all duration-300 ${
                tfData?.isBest ? 'bg-white dark:bg-default-50 text-primary border border-primary/30 shadow-sm shadow-primary/10' :
                tfData ? 'bg-white dark:bg-default-50 text-default-700 border border-default-200 dark:border-default-200/50 shadow-sm' : 'bg-transparent text-default-400'
              }`}>
                <span>{tf}</span>
                {tfData && (
                  <span className={`text-[9px] font-bold ${
                    tfData.signal === 'BUY' ? 'text-emerald-500' : 
                    tfData.signal === 'SELL' ? 'text-red-500' : 'text-amber-500'
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

      {/* Body Area */}
      <div className="card-body p-0 grid grid-cols-1 lg:grid-cols-12 relative z-10">
        
        {/* Left Column: AI Pipeline Visualizer */}
        <div className="lg:col-span-4 lg:border-r border-default-200 dark:border-default-300/10 flex flex-col h-[400px] bg-default-50/30 dark:bg-default-50/5 p-4">
            <h3 className="text-xs font-bold flex items-center gap-2 mb-4 text-default-600 px-2 lg:px-4">
              <LuBrainCircuit className="text-primary size-4" />
              AI PIPELINE
            </h3>

            <div className="overflow-y-auto px-2 lg:px-4 pb-4 custom-scrollbar relative flex-1 space-y-3">
              {/* Connecting line behind items */}
              <div className="absolute left-[28px] lg:left-[36px] top-4 bottom-4 w-px bg-default-200 dark:bg-default-300/20 z-0"></div>

              {agentConfig.map((agent) => {
                const status = agentStatus[agent.key as keyof AgentStatusMap] || 'idle';
                const latestLog = [...logs].reverse().find(l => l.agent === agent.key)?.message || '';
                
                const isActive = status === 'running';
                const isDone = status === 'done';
                const isError = status === 'error';

                return (
                  <div key={agent.key} className="relative z-10 flex gap-3 group">
                    {/* Status Node */}
                    <div className="relative flex flex-col items-center">
                       <div className={`size-10 rounded-xl flex items-center justify-center shadow-sm transition-all duration-300 z-10 ${
                         isActive ? `bg-primary/10 border border-primary/30 text-primary transform scale-105` : 
                         isDone ? 'bg-default-100 dark:bg-default-50 border border-default-200 dark:border-default-300/10' : 
                         isError ? 'bg-red-500/10 border border-red-500/30 text-red-500' : 
                         'bg-default-50 dark:bg-default-50/50 border border-default-200 dark:border-default-300/10 border-dashed text-default-400'
                       }`}>
                          {isActive ? <LuLoader className="animate-spin size-5" /> : 
                           isDone ? <LuCheck className="text-primary size-5 opacity-80" /> :
                           isError ? <LuX className="size-5" /> :
                           <div className="scale-75">{agent.icon}</div>}
                       </div>
                    </div>

                    {/* Agent Details Card */}
                    <div className={`flex-1 rounded-lg p-2.5 border transition-all duration-300 overflow-hidden relative ${
                      isActive ? 'bg-primary/5 border-primary/20 shadow-sm shadow-primary/5' :
                      isDone ? 'bg-default-50/50 dark:bg-transparent border-default-200/50 dark:border-default-300/10' :
                      isError ? 'bg-red-50 dark:bg-red-500/5 border-red-200 dark:border-red-500/20' :
                      'bg-transparent border-transparent'
                    }`}>
                      <div className="relative z-10">
                         <div className="flex justify-between items-start mb-0.5">
                           <span className={`font-semibold text-xs ${isActive ? 'text-primary' : isError ? 'text-red-500' : 'text-default-800'}`}>{agent.name}</span>
                           <span className={`text-[9px] font-bold uppercase px-1.5 py-0.5 rounded ${
                              isActive ? 'bg-primary/10 text-primary' :
                              isDone ? 'bg-emerald-500/10 text-emerald-600' :
                              isError ? 'bg-red-500/10 text-red-600' : 'hidden'
                           }`}>{status}</span>
                         </div>
                         <p className="text-[10px] text-default-500 leading-tight mb-1">{agent.desc}</p>
                         
                         {/* Output Snippet */}
                         {latestLog && (
                           <div className={`mt-1 text-[9px] font-mono p-1.5 rounded border ${
                             isActive ? 'bg-default-100 dark:bg-default-50 border-default-200 dark:border-default-300/20 text-primary' : 'bg-default-100/50 dark:bg-default-50/50 border-default-200/50 dark:border-default-300/10 text-default-500'
                           } whitespace-nowrap overflow-hidden text-ellipsis`}>
                             <span className="opacity-50 mr-1">&gt;</span>{latestLog}
                           </div>
                         )}
                      </div>
                    </div>
                  </div>
                );
              })}
            </div>
        </div>

        {/* Right Column: Premium Hacker Console */}
        <div className="lg:col-span-8 bg-zinc-950 dark:bg-[#070707] flex flex-col h-[400px] relative overflow-hidden">
          {/* Subtle glow behind console */}
          <div className="absolute inset-0 bg-primary/5 pointer-events-none"></div>

          {/* Terminal Header */}
          <div className="bg-zinc-900/80 border-b border-zinc-800 px-4 py-2 relative z-10 flex items-center justify-between">
            <div className="flex items-center gap-3">
              <div className="flex gap-1.5 group">
                <div className="size-2.5 rounded-full bg-red-500/80 hover:bg-red-400 transition-colors cursor-pointer" />
                <div className="size-2.5 rounded-full bg-amber-500/80 hover:bg-amber-400 transition-colors cursor-pointer" />
                <div className="size-2.5 rounded-full bg-emerald-500/80 hover:bg-emerald-400 transition-colors cursor-pointer" />
              </div>
              <div className="h-3 w-px bg-zinc-700"></div>
              <div className="flex items-center gap-1.5">
                <LuTerminal className="text-zinc-500 size-3" />
                <span className="font-mono text-[10px] text-zinc-400 font-bold tracking-widest">AGENT_CONSOLE v3.1</span>
              </div>
            </div>
            <span className="flex items-center gap-1.5 text-[9px] font-mono text-zinc-400 bg-zinc-950 px-1.5 py-0.5 rounded border border-zinc-800">
              <span className={`size-1.5 rounded-full ${agentStatus.orchestrator === 'running' ? 'bg-emerald-500 animate-pulse outline outline-1 outline-emerald-500/50' : 'bg-zinc-600'}`}></span>
              {agentStatus.orchestrator === 'running' ? 'LIVE SYNC' : 'DISCONNECTED'}
            </span>
          </div>
          
          <div className="overflow-y-auto px-4 py-3 font-mono text-[10px] leading-relaxed space-y-0.5 custom-scrollbar relative z-10 flex-1">
            {logs.length === 0 && (
              <div className="flex items-center justify-center h-full text-zinc-500 text-center flex-col">
                <div className="size-12 rounded-xl bg-zinc-900 flex items-center justify-center mb-3">
                  <LuTerminal className="size-5 opacity-30" />
                </div>
                <p className="font-bold text-zinc-400">System Standing By</p>
                <p className="text-zinc-600 mt-1 max-w-xs">Waiting for triggers to begin the AI multi-agent analytical sequence.</p>
              </div>
            )}

            {logs.map((log, i) => {
              const isError = log.status === 'error' || log.message.includes('❌');
              const isSuccess = log.status === 'done' || log.message.includes('✅');
              const isWarning = log.message.includes('⚠️');
              
              return (
                <div key={i} className="flex gap-4 hover:bg-zinc-900/50 px-3 py-1 rounded-lg transition-colors group">
                  <span className="text-zinc-600 shrink-0 select-none font-semibold">
                    {new Date(log.timestamp).toLocaleTimeString('en-US', { hour12: false, hour: '2-digit', minute: '2-digit', second: '2-digit' })}
                  </span>
                  <span className={`shrink-0 w-[120px] whitespace-nowrap text-right font-bold tracking-tight ${
                    log.agent === 'orchestrator' ? 'text-blue-400' :
                    log.agent === 'chart_analyst' ? 'text-purple-400' :
                    log.agent === 'news_hunter' ? 'text-cyan-400' :
                    log.agent === 'decision_maker' ? 'text-rose-400' :
                    log.agent === 'risk_manager' ? 'text-emerald-400' :
                    log.agent === 'calendar' ? 'text-amber-400' : 'text-zinc-400'
                  }`}>
                    [{log.agent?.toUpperCase() || 'SYSTEM'}]
                  </span>
                  <span className={`flex-1 break-words font-medium ${
                    isSuccess ? 'text-emerald-400' : 
                    isError ? 'text-red-400' : 
                    isWarning ? 'text-amber-300' : 'text-zinc-300'
                  }`}>
                    {log.message}
                  </span>
                </div>
              );
            })}
            
            {agentStatus.orchestrator === 'running' && (
              <div className="flex gap-4 px-3 py-1">
                <span className="text-zinc-700 shrink-0 font-medium">... ... ..</span>
                <span className="shrink-0 w-[120px]"></span>
                <span className="flex-1 flex gap-2 items-center">
                   <div className="size-1 bg-white rounded-full animate-bounce" style={{ animationDelay: '0ms' }}></div>
                   <div className="size-1 bg-white rounded-full animate-bounce" style={{ animationDelay: '150ms' }}></div>
                   <div className="size-1 bg-white rounded-full animate-bounce" style={{ animationDelay: '300ms' }}></div>
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
