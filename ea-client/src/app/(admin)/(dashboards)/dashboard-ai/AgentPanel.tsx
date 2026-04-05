import React, { useRef, useEffect } from 'react';
import { LuBot, LuCheck, LuX, LuLoader, LuShield, LuCalendar, LuGlobe, LuActivity, LuBrainCircuit, LuZap, LuMonitorOff } from 'react-icons/lu';

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
  disabledAgents?: string[];
  onToggleAgent?: (agentKey: string) => void;
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

export const AgentPanel: React.FC<AgentPanelProps> = ({ title, symbol, isClosed, logs, agentStatus, finalResult, disabledAgents = [], onToggleAgent }) => {
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
      <div className="card-body p-0 grid grid-cols-1 lg:grid-cols-12 relative z-10 bg-white dark:bg-[#0A0A0A]">
        
        {/* Left Column: AI Pipeline Visualizer (Clean Style) */}
        <div className="lg:col-span-4 flex flex-col bg-default-50/50 dark:bg-[#0A0A0A] p-4 h-full">
            <h3 className="text-xs font-bold flex items-center gap-2 mb-4 text-default-500 px-2 lg:px-4">
              <LuBrainCircuit className="text-primary size-4" />
              AI PIPELINE
            </h3>

            <div className="px-2 lg:px-4 pb-4 relative flex-1 space-y-4 h-full">
              {/* Connecting line behind items */}
              <div className="absolute left-[28px] lg:left-[36px] top-4 bottom-4 w-px bg-default-200 dark:bg-default-800 z-0"></div>

              {agentConfig.map((agent) => {
                const isDisabled = disabledAgents.includes(agent.key);
                const status = agentStatus[agent.key as keyof AgentStatusMap] || 'idle';
                const isActive = !isDisabled && status === 'running';
                const isDone = !isDisabled && status === 'done';
                const isError = !isDisabled && status === 'error';

                return (
                  <div 
                     key={agent.key} 
                     onClick={() => onToggleAgent && onToggleAgent(agent.key)}
                     className={`relative z-10 flex gap-4 group items-center cursor-pointer transition-all duration-300 ${!isDisabled ? 'hover:opacity-80' : ''}`}
                  >
                    {/* Status Node */}
                    <div className="relative flex flex-col items-center">
                       <div className={`size-10 rounded-full flex items-center justify-center shadow-sm transition-all duration-300 z-10 border ${
                         isDisabled ? 'border-dashed border-default-300 dark:border-white text-default-400 dark:text-white bg-white dark:bg-[#0A0A0A]' :
                         isActive ? `bg-white dark:bg-black border-primary text-primary transform scale-105 shadow-primary/20` : 
                         isDone ? 'bg-white dark:bg-black border-emerald-500 text-emerald-500' : 
                         isError ? 'bg-white dark:bg-black border-red-500/50 text-red-500' : 
                         'bg-white dark:bg-black border-emerald-500 text-emerald-500' // Default Active (Green)
                       }`}>
                          {isDisabled ? <div className="scale-75">{agent.icon}</div> :
                           isActive ? <LuLoader className="animate-spin size-5" /> : 
                           isDone ? <LuCheck className="size-5" /> :
                           isError ? <LuX className="size-5" /> :
                           <div className="scale-75">{agent.icon}</div>}
                       </div>
                    </div>

                    {/* Agent Details */}
                    <div className="flex-1 overflow-hidden relative">
                       <div className="flex justify-between items-center mb-0.5">
                         <span className={`font-bold text-sm ${isDisabled ? 'text-default-500 dark:text-default-500' : isActive ? 'text-primary' : isError ? 'text-red-500' : 'text-default-700'}`}>
                            {agent.name} {isDisabled && <span className="text-[9px] uppercase ml-2 px-1.5 py-0.5 rounded shadow-sm bg-default-100 dark:bg-white/5 border border-default-200 dark:border-white/10 text-default-500 dark:text-default-500 font-semibold tracking-wider">OFF</span>}
                         </span>
                       </div>
                       <p className={`text-[10px] leading-tight ${isDisabled ? 'text-default-400 dark:text-default-600' : 'text-default-500'}`}>{agent.desc}</p>
                    </div>
                  </div>
                );
              })}
            </div>
        </div>

        {/* Right Column: Minimalist Reasoning UI */}
        <div className="lg:col-span-8 p-6 flex flex-col space-y-4 relative z-10 h-full">
          {logs.length === 0 && (
              <div className="flex items-center justify-center py-10 h-full text-default-400 flex-col">
                <LuBot className="size-10 opacity-20 mb-4" />
                <p className="font-semibold text-sm">System Standing By</p>
                <p className="text-xs mt-1 max-w-xs text-center opacity-70">Waiting for triggers to begin the AI analytical sequence.</p>
              </div>
          )}

          {/* Render Contiguous Groups of Logs */}
          {(() => {
            const groups: { id: string; agent: string; logs: AiLog[] }[] = [];
            let currentGroup: any = null;
            logs.forEach(log => {
              if (log.agent === 'system' || !log.agent) {
                if (currentGroup) groups.push(currentGroup);
                currentGroup = null;
                groups.push({ id: Math.random().toString(), agent: 'system', logs: [log] });
              } else {
                if (!currentGroup || currentGroup.agent !== log.agent) {
                  if (currentGroup) groups.push(currentGroup);
                  currentGroup = { id: Math.random().toString(), agent: log.agent, logs: [log] };
                } else {
                  currentGroup.logs.push(log);
                }
              }
            });
            if (currentGroup) groups.push(currentGroup);

            return groups.map((group, idx) => {
              const isLast = idx === groups.length - 1;
              const isRunning = isLast && agentStatus[group.agent as keyof AgentStatusMap] === 'running';

              if (group.agent === 'system') {
                return (
                  <div key={group.id} className="text-sm font-medium text-default-600 px-2 flex items-center gap-2">
                     <span className="size-1.5 rounded-full bg-default-300"></span>
                     {group.logs[0].message}
                  </div>
                );
              }

              const agentInfo = agentConfig.find(a => a.key === group.agent) || { name: group.agent?.toUpperCase() || 'AGENT' };

              return (
                <div key={group.id} className="flex flex-col space-y-2">
                  <details className="group/accordion" open={isLast}>
                    <summary className="inline-flex items-center gap-2 px-3 py-1.5 bg-default-100/80 dark:bg-default-50 hover:bg-default-200/80 dark:hover:bg-default-100 rounded-full cursor-pointer transition-colors select-none text-xs font-bold text-default-700 list-none [&::-webkit-details-marker]:hidden">
                       <span className="group-open/accordion:rotate-90 transition-transform duration-200">
                         <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"><path d="m9 18 6-6-6-6"/></svg>
                       </span>
                       {isRunning ? (
                         <span className="flex items-center gap-2">
                           <LuLoader className="animate-spin text-primary size-3.5" />
                           Thinking as {agentInfo.name}...
                         </span>
                       ) : (
                         <span className="flex items-center gap-1.5">
                           Thought process of {agentInfo.name}
                         </span>
                       )}
                    </summary>
                    <div className="pl-[22px] pt-3 pb-1 border-l-2 border-default-100 dark:border-default-800 ml-[11px] mt-1 space-y-2">
                       {group.logs.map((log, i) => {
                          const isError = log.status === 'error' || log.message.includes('❌');
                          const isSuccess = log.status === 'done' || log.message.includes('✅');
                          return (
                            <div key={i} className={`text-[13px] leading-relaxed font-mono ${
                              isError ? 'text-red-500' : isSuccess ? 'text-emerald-500 dark:text-emerald-400' : 'text-default-600 dark:text-default-400'
                            }`}>
                               {log.message}
                            </div>
                          );
                       })}
                    </div>
                  </details>
                </div>
              );
            });
          })()}
          <div ref={logsEndRef} className="h-4" />
        </div>
      </div>
    </div>
  );
};
