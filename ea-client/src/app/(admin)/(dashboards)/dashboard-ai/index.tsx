'use client';
import { useState, useEffect, useRef } from 'react';
import { getWsUrl } from '@/utils/config';
import { LuBot, LuCheck, LuX, LuBrainCircuit, LuPlus } from 'react-icons/lu';
import type { AiLog, AgentStatusMap } from './AgentPanel';
import { SetupFormModal } from './SetupFormModal';
import { JobSidebarCard } from './JobSidebarCard';
import { SetupChatView } from './SetupChatView';

type AutoPilotJob = { 
  symbol: string; 
  interval: number; 
  auto_trade: boolean; 
  lot_size: number; 
  ai_mode?: string; 
  disabled_agents?: string[]; 
  enabled?: boolean; 
  is_draft?: boolean; 
  telegram_alert?: boolean;
  tp_sl_mode?: 'pips' | 'usd' | 'none';
  tp_value?: number;
  sl_value?: number;
  ts_value?: number;
};

// Countdown timer for scan interval (removed due to unused variable error)

const DashboardAi = () => {
  const [logsBySymbol, setLogsBySymbol] = useState<Record<string, AiLog[]>>({});
  const [agentStatusBySymbol, setAgentStatusBySymbol] = useState<Record<string, AgentStatusMap>>({});
  const [finalResultBySymbol, setFinalResultBySymbol] = useState<Record<string, any>>({});
  const [lastRunMap, setLastRunMap] = useState<Record<string, number>>({});
  const [tradeProposal, setTradeProposal] = useState<any>(null);
  const [confirmDialog, setConfirmDialog] = useState<{ message: string; onConfirm: () => void } | null>(null);

  const [trackedSymbols, setTrackedSymbols] = useState<string[]>([]);
  const [globalSymbol, setGlobalSymbol] = useState("XAUUSD");
  
  // M1 states per symbol
  const [agentStatusM1Map, setAgentStatusM1Map] = useState<Record<string, AgentStatusMap>>({});
  const [logsM1BySymbol, setLogsM1BySymbol] = useState<Record<string, AiLog[]>>({});
  
  // Auto-Pilot States
  const [autoPilotJobs, setAutoPilotJobs] = useState<AutoPilotJob[]>([]);
  const [closedMap, setClosedMap] = useState<Record<string, boolean>>({});
  
  // Chat UI States
  const [activeSetupId, setActiveSetupId] = useState<string | null>(null);
  const [verboseLogsBySymbol, setVerboseLogsBySymbol] = useState<Record<string, {timestamp: number, agent: string, prompt: string, response: string}[]>>({});
  
  const wsRef = useRef<WebSocket | null>(null);

  // Fetch initial history logs
  useEffect(() => {
     if (autoPilotJobs.length === 0) return;
     const baseWs = getWsUrl(); // e.g. ws://35.201.200.246:8080
     const httpUrl = baseWs.replace('ws://', 'http://').replace('wss://', 'https://').replace(':8080', ':4173') + (baseWs.endsWith('/') ? '' : '/');

     autoPilotJobs.forEach(job => {
         if (!job.symbol) return;
         fetch(`${httpUrl}api/ai_logs?symbol=${job.symbol}&limit=100`)
           .then(res => res.json())
           .then(data => {
               if (!Array.isArray(data)) return;
               const newLogs: any[] = [];
               const newM1Logs: any[] = [];
               const newVerboseLogs: any[] = [];
               data.forEach(d => {
                   const logRow = { ...d, timestamp: d.timestamp || Date.now() };
                   if (d.type === 'agent_log') {
                       newLogs.push(logRow);
                       newVerboseLogs.push({
                           timestamp: logRow.timestamp,
                           agent: logRow.agent,
                           prompt: '[SYSTEM RECOVERY] ข้อมูลการวิเคราะห์ล่าสุดถูกโหลดจากประวัติเดิม (ไม่สามารถกู้คืน Raw Prompt ของรอบก่อนหน้าได้)',
                           response: logRow.message
                       });
                   }
                   if (d.type === 'agent_log_m1') newM1Logs.push(logRow);
               });
               
               if (newLogs.length > 0) {
                  setLogsBySymbol(prev => {
                     // don't overwrite if we already received realtime
                     if (prev[job.symbol] && prev[job.symbol].length > 0) return prev;
                     return {...prev, [job.symbol]: newLogs};
                  });
                  setAgentStatusBySymbol(prev => {
                     if (prev[job.symbol]) return prev;
                     const currentStatuses: AgentStatusMap = {
                       news_hunter: 'idle', chart_analyst: 'idle', calendar: 'idle',
                       risk_manager: 'idle', decision_maker: 'idle', orchestrator: 'idle',
                     };
                     newLogs.forEach(log => {
                        if (log.agent && log.status) {
                           currentStatuses[log.agent as keyof AgentStatusMap] = log.status as any;
                        }
                     });
                     return {...prev, [job.symbol]: currentStatuses};
                  });
               }
               if (newVerboseLogs.length > 0) {
                  setVerboseLogsBySymbol(prev => {
                     if (prev[job.symbol] && prev[job.symbol].length > 0) return prev;
                     return {...prev, [job.symbol]: newVerboseLogs};
                  });
               }
               if (newM1Logs.length > 0) {
                  setLogsM1BySymbol(prev => {
                     if (prev[job.symbol] && prev[job.symbol].length > 0) return prev;
                     return {...prev, [job.symbol]: newM1Logs};
                  });
                  setAgentStatusM1Map(prev => {
                     if (prev[job.symbol]) return prev;
                     const currentStatuses: AgentStatusMap = {
                       news_hunter: 'idle', chart_analyst: 'idle', calendar: 'idle',
                       risk_manager: 'idle', decision_maker: 'idle', orchestrator: 'idle',
                     };
                     newM1Logs.forEach(log => {
                        if (log.agent && log.status) {
                           currentStatuses[log.agent as keyof AgentStatusMap] = log.status as any;
                        }
                     });
                     return {...prev, [job.symbol]: currentStatuses};
                  });
               }
           })
           .catch(() => {});
     });
  }, [autoPilotJobs]);

  useEffect(() => {
    const WS_URL = getWsUrl();
    const ws = new WebSocket(WS_URL);
    wsRef.current = ws;

    ws.onopen = () => {
      ws.send(JSON.stringify({ action: 'get_server_config' }));
      ws.send(JSON.stringify({ action: 'get_tracked_symbols' }));
    };
    ws.onclose = () => {};

    ws.onmessage = (evt) => {
      try {
        const data = JSON.parse(evt.data);
        
        if (data.type === 'server_config' && data.config) {
          const c = data.config;
          if (c.ai_autopilot_jobs) {
            try { setAutoPilotJobs(JSON.parse(c.ai_autopilot_jobs)); } catch(e){}
          } else if (c.ai_target_symbols) {
            const syms = c.ai_target_symbols.split(',').map((s: string) => s.trim()).filter(Boolean);
            const legacyInterval = parseInt(c.ai_analyze_interval || '15', 10);
            const legacyAutoTrade = c.ai_auto_trade === 'true';
            const legacyLot = parseFloat(c.ai_auto_lot_size || '0.01');
            setAutoPilotJobs(syms.map((s: string) => ({ symbol: s, interval: legacyInterval, auto_trade: legacyAutoTrade, lot_size: legacyLot })));
          }
        }

        if (data.type === 'tracked_symbols') {
          setTrackedSymbols(data.symbols || []);
          if (data.closed_map) setClosedMap(data.closed_map);
          if (data.symbols?.length > 0 && !data.symbols.includes(globalSymbol)) {
            setGlobalSymbol(data.symbols[0]);
          }
        }

        if (data.type === 'market_closed') {
          const sym = data.symbol || globalSymbol;
          setClosedMap(prev => ({ ...prev, [sym]: true }));
        }

        if (data.type === 'agent_log') {
          const sym = data.symbol || globalSymbol;
          const newLog = { timestamp: Date.now(), agent: data.agent, status: data.status, message: data.message };
          
          setLogsBySymbol(prev => ({
             ...prev,
             [sym]: [...(prev[sym] || []), newLog].slice(-50)
          }));
          
          if (data.agent) {
             setAgentStatusBySymbol(prev => {
                const currentStatuses = prev[sym] || {
                  news_hunter: 'idle', chart_analyst: 'idle', calendar: 'idle',
                  risk_manager: 'idle', decision_maker: 'idle', orchestrator: 'running',
                };
                return {
                  ...prev,
                  [sym]: { ...currentStatuses, [data.agent]: data.status }
                };
             });
          }
        } else if (data.type === 'agent_log_m1') {
          const symbol = data.symbol;
          const agentStr = data.agent as keyof AgentStatusMap;
          const newLog = { ...data, timestamp: Date.now() };
          
          setLogsM1BySymbol(prev => ({
             ...prev,
             [symbol]: [...(prev[symbol] || []), newLog].slice(-50)
          }));
          
          setAgentStatusM1Map(prev => {
              const newMap = { ...prev };
              if (!newMap[symbol]) {
                  newMap[symbol] = {
                      orchestrator: 'running',
                      news_hunter: 'idle', chart_analyst: 'idle',
                      calendar: 'idle', risk_manager: 'idle', decision_maker: 'idle'
                  };
              }
              if (agentStr) {
                 newMap[symbol][agentStr] = data.status as 'idle'|'running'|'done'|'error';
              }
              return newMap;
          });
        } else if (data.type === 'agents_started_m1') {
          const symbol = data.symbol;
          setAgentStatusM1Map(prev => {
              const newMap = { ...prev };
              newMap[symbol] = {
                  orchestrator: 'running',
                  news_hunter: 'idle', chart_analyst: 'idle',
                  calendar: 'idle', risk_manager: 'idle', decision_maker: 'idle'
              };
              return newMap;
          });
        } else if (data.type === 'agents_done_m1') {
          const symbol = data.symbol;
          setAgentStatusM1Map(prev => {
              const newMap = { ...prev };
              newMap[symbol] = {
                  orchestrator: 'idle',
                  news_hunter: 'idle', chart_analyst: 'idle',
                  calendar: 'idle', risk_manager: 'idle', decision_maker: 'idle'
              };
              return newMap;
          });
        }
        
        if (data.type === 'multi_agent_result') {
          const sym = data.symbol || globalSymbol;
          setFinalResultBySymbol(prev => ({ ...prev, [sym]: data.result }));
          
          setAgentStatusBySymbol(prev => {
             const currentStatuses = prev[sym] || {} as AgentStatusMap;
             return { ...prev, [sym]: { ...currentStatuses, orchestrator: 'done' } };
          });
        }

        if (data.type === 'agents_started') {
          const sym = data.symbol || globalSymbol;
          setLastRunMap(prev => ({...prev, [sym]: Date.now()}));
          setAgentStatusBySymbol(prev => {
             const newMap = {...prev};
             newMap[sym] = {
                news_hunter: 'idle', chart_analyst: 'idle', calendar: 'idle',
                risk_manager: 'idle', decision_maker: 'idle', orchestrator: 'running'
             };
             return newMap;
          });
          setFinalResultBySymbol(prev => {
             const newObj = {...prev};
             delete newObj[sym];
             return newObj;
          });

          setTradeProposal(null);
        }

        if (data.type === 'ai_trade_proposal') {
          setTradeProposal(data);
        }

        if (data.type === 'agent_log_verbose') {
          const sym = data.symbol;
          const newLog = {
             timestamp: Date.now(),
             agent: data.agent,
             prompt: data.prompt,
             response: data.response
          };
          setVerboseLogsBySymbol(prev => ({
             ...prev,
             [sym]: [...(prev[sym] || []), newLog].slice(-500) // keep last 500 verbose logs per symbol
          }));
        }
      } catch (_e) {}
    };

    return () => ws.close();
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const updateConfig = (key: string, val: string) => {
    if (!wsRef.current || wsRef.current.readyState !== WebSocket.OPEN) return;
    wsRef.current.send(JSON.stringify({ action: 'set_server_config', config_key: key, config_value: val }));
  };

  const saveJobsToDb = (newJobs: AutoPilotJob[]) => {
     setAutoPilotJobs(newJobs);
     const cleanJobs = newJobs.filter(j => !j.is_draft).map(j => {
        const { is_draft, ...rest } = j;
        return rest;
     });
     updateConfig('ai_autopilot_jobs', JSON.stringify(cleanJobs));
  };

  const handleEditJob = (job: AutoPilotJob) => {
      const newJobs = autoPilotJobs.map(j => j.symbol === job.symbol ? { ...j, is_draft: true } : j);
      saveJobsToDb(newJobs);
  };

  const acceptProposal = () => {
    if (!wsRef.current || wsRef.current.readyState !== WebSocket.OPEN || !tradeProposal) return;
    wsRef.current.send(JSON.stringify({
      action: "open_trade",
      symbol: tradeProposal.symbol,
      direction: tradeProposal.direction,
      lot_size: tradeProposal.lot_size || 0.01,
      comment: tradeProposal.comment || "EA24-AI"
    }));
    setTradeProposal(null);
  };

  const rejectProposal = () => setTradeProposal(null);
  
  return (
    <div className="p-4 md:p-6 lg:p-8 max-w-7xl mx-auto h-[calc(100vh-80px)] min-h-[600px] flex flex-col items-center w-full">
      <div className="flex w-full h-full bg-white dark:bg-[#090C15] border border-gray-200 dark:border-white/10 rounded-3xl shadow-sm overflow-hidden">
      {/* SIDEBAR: Setup List */}
      <div className="w-[300px] lg:w-[350px] flex-shrink-0 border-r border-default-200 dark:border-white/10 flex flex-col bg-[#fafafa] dark:bg-[#0b0e17]">
        <div className="p-4 flex items-center justify-between">
          <h1 className="text-xl font-bold text-default-900 dark:text-white">Setups</h1>
          <button 
              onClick={() => saveJobsToDb([...autoPilotJobs, { symbol: trackedSymbols.includes('BTCUSD') ? 'BTCUSD' : (trackedSymbols[0] || 'BTCUSD'), interval: 15, auto_trade: false, lot_size: 0.01, ai_mode: 'eval_10_strategies', is_draft: true }])}
              className="w-8 h-8 flex items-center justify-center bg-gray-200 dark:bg-white/10 rounded-md text-gray-600 dark:text-gray-300 hover:bg-gray-300 transition-colors"
          >
              <LuPlus size={18} />
          </button>
        </div>

        <div className="px-4 pb-2 text-xs font-semibold text-gray-500">
          All Setups
        </div>
        <div className="flex-1 overflow-y-auto custom-scrollbar flex flex-col">
         <div className="w-full md:w-80 lg:w-[320px] hidden" />
                 {autoPilotJobs.map((job, idx) => (
                      <JobSidebarCard 
                          key={`job-card-${job.symbol}-${idx}`}
                          job={job}
                          isSelected={activeSetupId === job.symbol}
                          onClick={() => setActiveSetupId(job.symbol)}
                          onEdit={() => handleEditJob(job)}
                          result={finalResultBySymbol[job.symbol]}
                          lastRunTime={lastRunMap[job.symbol] || null}
                          agentStatusM1Map={agentStatusM1Map[job.symbol]}
                      />
                 ))}
                 {autoPilotJobs.length === 0 && (
                     <div className="text-center p-6 border-2 border-dashed border-default-200 dark:border-white/10 rounded-xl my-auto">
                         <p className="text-xs text-gray-500">No Setups</p>
                     </div>
                 )}
             </div>
         </div>

         {/* MAIN UI: Chat View */}
         <div className="flex-1 min-w-0 bg-white dark:bg-[#090C15] flex flex-col relative">
             {activeSetupId ? (() => {
                 const jobIdx = autoPilotJobs.findIndex(j => j.symbol === activeSetupId);
                 if (jobIdx === -1) return <div className="m-auto text-gray-400 text-sm">Select a setup to view Activity</div>;
                 const job = autoPilotJobs[jobIdx];

                 if (job.is_draft) {
                     return (
                         <SetupFormModal 
                            job={job}
                            trackedSymbols={trackedSymbols}
                            onClose={() => {
                                const newJobs = [...autoPilotJobs];
                                newJobs[jobIdx].is_draft = false;
                                saveJobsToDb(newJobs);
                            }}
                            onSave={(updatedJob: any) => {
                                const newJobs = [...autoPilotJobs];
                                newJobs[jobIdx] = updatedJob;
                                saveJobsToDb(newJobs);
                            }}
                            onDelete={() => {
                                setConfirmDialog({
                                    message: `คุณแน่ใจหรือไม่ว่าต้องการลบการตั้งค่าบอท ${job.symbol}?`,
                                    onConfirm: () => {
                                        const newJobs = autoPilotJobs.filter((_, i) => i !== jobIdx);
                                        saveJobsToDb(newJobs);
                                        setActiveSetupId(null);
                                    }
                                });
                            }}
                         />
                     );
                 }

                 return (
                     <SetupChatView
                        job={job}
                        closedMap={closedMap}
                        lastRunMap={lastRunMap}
                        setConfirmDialog={setConfirmDialog}
                        saveJobsToDb={saveJobsToDb}
                        autoPilotJobs={autoPilotJobs}
                        jobIdx={jobIdx}
                        handleEditJob={handleEditJob}
                        logsBySymbol={logsBySymbol}
                        logsM1BySymbol={logsM1BySymbol}
                        agentStatusBySymbol={agentStatusBySymbol}
                        agentStatusM1Map={agentStatusM1Map}
                        finalResultBySymbol={finalResultBySymbol}
                        verboseLogs={verboseLogsBySymbol[activeSetupId] || []}
                     />
                 );
             })() : (
                 <div className="m-auto flex flex-col items-center justify-center gap-4 text-center">
                     <div className="size-16 bg-blue-50 dark:bg-white/5 rounded-2xl flex items-center justify-center text-blue-500">
                         <LuBot size={32} />
                     </div>
                     <div>
                         <h3 className="text-sm font-black text-default-900 dark:text-gray-100">AI Dashboard</h3>
                         <p className="text-xs text-gray-500 max-w-sm">Select an AI setup from the sidebar to view live processing logs and decision explanations.</p>
                     </div>
                 </div>
             )}
          </div>
        </div>
      {tradeProposal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/80 backdrop-blur-md px-4">
          <div className="w-full max-w-md rounded-3xl bg-white dark:bg-[#090C15] border border-default-200 dark:border-white/10 shadow-[0_20px_60px_rgba(0,0,0,0.1)] dark:shadow-[0_20px_60px_rgba(0,0,0,0.8)] p-6 animate-in slide-in-from-bottom-4">
            <div className="flex items-center gap-4 mb-6">
              <div className="size-12 rounded-2xl bg-gradient-to-br from-amber-400 to-orange-600 flex items-center justify-center text-white shadow-lg shadow-amber-500/20">
                <LuBrainCircuit className="size-6" />
              </div>
              <div>
                <h3 className="text-xl font-black text-default-900 dark:text-white/90">รอการยืนยันออเดอร์</h3>
                <p className="text-xs font-semibold text-default-500 dark:text-white/40">AI Agent แนะนำการเข้าเทรด</p>
              </div>
            </div>

            <div className="rounded-2xl border border-default-200 dark:border-white/5 bg-default-50 dark:bg-white/5 p-4 mb-6 space-y-3 shadow-inner">
              {[
                ['Symbol', tradeProposal.symbol, 'text-[#3B82F6]'],
                ['Direction', tradeProposal.direction, tradeProposal.direction === 'BUY' ? 'text-emerald-400' : 'text-red-400'],
                ['Confidence', `${tradeProposal.confidence || 0}%`, 'text-default-700 dark:text-white/80'],
                ['Lot Size', tradeProposal.lot_size || 0.01, 'text-amber-400 font-mono'],
              ].map(([label, value, color]) => (
                <div key={label as string} className="flex justify-between items-center text-sm">
                  <span className="text-white/50 font-medium tracking-wide">{label}</span>
                  <span className={`font-black ${color}`}>{value}</span>
                </div>
              ))}
              <div className="pt-3 mt-3 border-t border-white/10 text-xs text-white/60 leading-relaxed font-medium">
                <strong className="text-white/80">เหตุผล:</strong> {tradeProposal.reasoning}
              </div>
            </div>

            <div className="flex gap-3">
              <button 
                onClick={rejectProposal}
                className="flex-1 flex items-center justify-center gap-2 px-4 py-3.5 rounded-xl bg-white/5 hover:bg-white/10 font-bold text-sm text-white/80 transition-all border border-transparent hover:border-white/10"
              >
                <LuX size={16} /> ยกเลิก
              </button>
              <button 
                onClick={acceptProposal}
                className={`flex-1 flex items-center justify-center gap-2 px-4 py-3.5 rounded-xl text-white font-black text-sm transition-all shadow-lg hover:brightness-110 ${
                  tradeProposal.direction === 'BUY' ? 'bg-gradient-to-r from-emerald-500 to-emerald-600 shadow-emerald-500/25' : 'bg-gradient-to-r from-red-500 to-red-600 shadow-red-500/25'
                }`}
              >
                <LuCheck size={16} /> อนุมัติออเดอร์
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Confirm Dialog Modal */}
      {confirmDialog && (
        <div className="fixed inset-0 z-[60] flex items-center justify-center bg-black/80 backdrop-blur-sm px-4">
          <div className="w-full max-w-sm rounded-3xl bg-white dark:bg-[#0B101E] border border-default-200 dark:border-white/10 shadow-[0_20px_60px_rgba(0,0,0,0.1)] dark:shadow-[0_20px_60px_rgba(0,0,0,0.8)] p-6 relative animate-in slide-in-from-bottom-2">
            <h3 className="text-xl font-black text-default-900 dark:text-white/90 mb-3 flex items-center gap-2">
               <LuBot className="size-5 text-amber-500" />
               แจ้งเตือนยืนยัน
            </h3>
            <p className="text-sm font-semibold text-default-600 dark:text-white/60 mb-8 leading-relaxed">
               {confirmDialog?.message}
            </p>
            <div className="flex gap-3 justify-end items-center">
              <button 
                onClick={() => setConfirmDialog(null)} 
                className="px-5 py-2.5 rounded-xl text-xs font-bold text-default-500 dark:text-gray-400 hover:text-default-900 dark:hover:text-white hover:bg-default-100 dark:hover:bg-white/5 transition-all"
              >
                ยกเลิก
              </button>
              <button 
                onClick={() => { confirmDialog?.onConfirm(); setConfirmDialog(null); }} 
                className="px-5 py-2.5 rounded-xl text-xs font-black text-white bg-blue-600 hover:bg-blue-500 shadow-lg shadow-blue-500/25 transition-all uppercase tracking-wide"
              >
                ยืนยันตกลง
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default DashboardAi;
