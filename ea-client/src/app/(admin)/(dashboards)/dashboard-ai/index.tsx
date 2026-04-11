'use client';
import { useState, useEffect, useRef } from 'react';
import { getWsUrl } from '@/utils/config';
import { LuBot, LuCheck, LuX, LuBrainCircuit, LuPlus, LuSparkles, LuServer, LuZap } from 'react-icons/lu';
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
  lot_scale?: boolean;
};

const DashboardAi = () => {
  const [logsBySymbol, setLogsBySymbol] = useState<Record<string, AiLog[]>>({});
  const [agentStatusBySymbol, setAgentStatusBySymbol] = useState<Record<string, AgentStatusMap>>({});
  const [finalResultBySymbol, setFinalResultBySymbol] = useState<Record<string, any>>({});
  const [lastRunMap, setLastRunMap] = useState<Record<string, number>>({});
  const [tradeProposal, setTradeProposal] = useState<any>(null);
  const [confirmDialog, setConfirmDialog] = useState<{ message: string; onConfirm: () => void } | null>(null);

  const [trackedSymbols, setTrackedSymbols] = useState<string[]>([]);
  const [globalSymbol, setGlobalSymbol] = useState("XAUUSD");
  
  // Auto-Pilot States
  const [autoPilotJobs, setAutoPilotJobs] = useState<AutoPilotJob[]>([]);
  const [closedMap, setClosedMap] = useState<Record<string, boolean>>({});
  const [topSignalsBySymbol, setTopSignalsBySymbol] = useState<Record<string, any[]>>({});
  
  // UI States
  const [activeSetupId, setActiveSetupId] = useState<string | null>(null);
  const [verboseLogsBySymbol, setVerboseLogsBySymbol] = useState<Record<string, {timestamp: number, agent: string, prompt: string, response: string}[]>>({});
  
  // Modal states — separate from main view
  const [showAddModal, setShowAddModal] = useState(false);
  const [editingJob, setEditingJob] = useState<AutoPilotJob | null>(null);
  
  const wsRef = useRef<WebSocket | null>(null);

  // Fetch initial history logs
  useEffect(() => {
     if (autoPilotJobs.length === 0) return;
     const baseWs = getWsUrl();
     const httpUrl = baseWs.replace('ws://', 'http://').replace('wss://', 'https://').replace(':8080', ':4173') + (baseWs.endsWith('/') ? '' : '/');

     autoPilotJobs.forEach(job => {
         if (!job.symbol) return;
         fetch(`${httpUrl}api/ai_logs?symbol=${job.symbol}&limit=100`)
           .then(res => res.json())
           .then(data => {
               if (!Array.isArray(data)) return;
               const newLogs: any[] = [];
               const newVerboseLogs: any[] = [];
               data.forEach(d => {
                   const logRow = { ...d, timestamp: d.timestamp || Date.now() };
                   if (d.type === 'agent_log') {
                       newLogs.push(logRow);
                       newVerboseLogs.push({
                           timestamp: logRow.timestamp,
                           agent: logRow.agent,
                           prompt: '[SYSTEM RECOVERY] ข้อมูลโหลดจากประวัติเดิม',
                           response: logRow.message
                       });
                   }
               });
               
               if (newLogs.length > 0) {
                  setLogsBySymbol(prev => {
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
          // Filter: if both BTCUSD and BTCUSD.iux exist, keep only the broker variant (.suffix)
          const raw: string[] = data.symbols || [];
          const filtered = raw.filter((s: string) => {
            if (s.includes('.')) return true; // always keep broker variants
            // keep plain only if no broker variant exists
            return !raw.some((other: string) => other.startsWith(s) && other.includes('.'));
          });
          setTrackedSymbols(filtered);
          if (data.closed_map) setClosedMap(data.closed_map);
          if (filtered.length > 0 && !filtered.includes(globalSymbol)) {
            setGlobalSymbol(filtered[0]);
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
        }

        if (data.type === 'pipeline_v8_scan') {
          const sym = data.symbol || globalSymbol;
          if (data.scan?.top_signals) {
            setTopSignalsBySymbol(prev => ({ ...prev, [sym]: data.scan.top_signals }));
          }
        }

        if (data.type === 'multi_agent_result' || data.type === 'pipeline_result') {
          const sym = data.symbol || globalSymbol;
          setFinalResultBySymbol(prev => ({ ...prev, [sym]: data.result }));
          setAgentStatusBySymbol(prev => {
             const currentStatuses = prev[sym] || {} as AgentStatusMap;
             return { ...prev, [sym]: { 
               ...currentStatuses, 
               orchestrator: 'done',
               pipeline_v8: 'done',
               gemma_filter: currentStatuses.gemma_filter === 'running' ? 'done' : currentStatuses.gemma_filter,
               gemini_confirm: currentStatuses.gemini_confirm === 'running' ? 'done' : currentStatuses.gemini_confirm,
             } };
          });
        }

        if (data.type === 'agents_started') {
          const sym = data.symbol || globalSymbol;
          setLastRunMap(prev => ({...prev, [sym]: Date.now()}));
          setAgentStatusBySymbol(prev => {
             const newMap = {...prev};
             newMap[sym] = {
                news_hunter: 'idle', chart_analyst: 'idle', calendar: 'idle',
                risk_manager: 'idle', decision_maker: 'idle', orchestrator: 'running',
                pipeline_v8: 'idle', gemma_filter: 'idle', gemini_confirm: 'idle',
             };
             return newMap;
          });
          setFinalResultBySymbol(prev => {
             const newObj = {...prev};
             delete newObj[sym];
             return newObj;
          });
          setTradeProposal(null);
          setTopSignalsBySymbol(prev => {
             const newObj = {...prev};
             delete newObj[sym];
             return newObj;
          });
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
             [sym]: [...(prev[sym] || []), newLog].slice(-500)
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
      setEditingJob({ ...job });
  };

  const handleAddNew = () => {
     const defaultSymbol = trackedSymbols[0] || 'XAUUSD';
     setEditingJob({
       symbol: defaultSymbol,
       interval: 15,
       auto_trade: false,
       lot_size: 0.01,
       ai_mode: 'eval_10_strategies',
       is_draft: true,
     });
     setShowAddModal(true);
  };

  const handleSaveModal = (updatedJob: AutoPilotJob) => {
     if (showAddModal) {
       // Adding new
       saveJobsToDb([...autoPilotJobs, { ...updatedJob, is_draft: false }]);
       setActiveSetupId(updatedJob.symbol);
     } else {
       // Editing existing
       const newJobs = autoPilotJobs.map(j => j.symbol === editingJob?.symbol ? { ...updatedJob, is_draft: false } : j);
       saveJobsToDb(newJobs);
     }
     setEditingJob(null);
     setShowAddModal(false);
  };

  const handleDeleteModal = () => {
     if (!editingJob) return;
     setConfirmDialog({
       message: `ลบ Setup "${editingJob.symbol}" ?`,
       onConfirm: () => {
         const newJobs = autoPilotJobs.filter(j => j.symbol !== editingJob.symbol);
         saveJobsToDb(newJobs);
         if (activeSetupId === editingJob.symbol) setActiveSetupId(null);
         setEditingJob(null);
         setShowAddModal(false);
       }
     });
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
    <div className="p-3 md:p-5 lg:p-6 max-w-7xl mx-auto h-[calc(100vh-80px)] min-h-[600px] flex flex-col items-center w-full">
      <div className="flex w-full h-full bg-white dark:bg-[#090C15] border border-gray-200 dark:border-white/[0.06] rounded-2xl shadow-sm overflow-hidden">
      
      {/* SIDEBAR */}
      <div className="w-[180px] lg:w-[200px] flex-shrink-0 border-r border-gray-200 dark:border-white/[0.06] flex flex-col bg-[#fafafa] dark:bg-[#0b0e17]">
        <div className="p-4 flex items-center justify-between border-b border-gray-100 dark:border-white/5">
          <div className="flex items-center gap-2">
            <LuZap className="size-4 text-blue-500" />
            <h1 className="text-sm font-bold text-gray-900 dark:text-white">AI Setups</h1>
          </div>
          <button 
              onClick={handleAddNew}
              className="size-7 flex items-center justify-center rounded-lg text-gray-400 hover:bg-blue-500 hover:text-white transition-all"
              title="เพิ่ม Setup ใหม่"
          >
              <LuPlus size={14} />
          </button>
        </div>

        <div className="flex-1 overflow-y-auto custom-scrollbar">
                 {autoPilotJobs.map((job, idx) => (
                      <JobSidebarCard 
                          key={`job-card-${job.symbol}-${idx}`}
                          job={job}
                          isSelected={activeSetupId === job.symbol}
                          onClick={() => setActiveSetupId(job.symbol)}
                          onEdit={() => handleEditJob(job)}
                          result={finalResultBySymbol[job.symbol]}
                          lastRunTime={lastRunMap[job.symbol] || null}
                          agentStatusM1Map={agentStatusBySymbol[job.symbol]}
                          isClosed={!!closedMap[job.symbol]}
                      />
                 ))}
                 {autoPilotJobs.length === 0 && (
                     <div className="flex flex-col items-center justify-center flex-1 p-8 text-center h-full min-h-[300px]">
                       <div className="size-12 rounded-xl bg-gray-100 dark:bg-white/5 flex items-center justify-center mb-3">
                         <LuBot size={20} className="text-gray-400" />
                       </div>
                       <p className="text-[12px] text-gray-500 font-medium mb-1">ยังไม่มี Setup</p>
                       <button onClick={handleAddNew} className="text-[11px] text-blue-500 font-medium hover:underline">
                         + เพิ่ม Setup ใหม่
                       </button>
                     </div>
                 )}
             </div>
         </div>

         {/* MAIN AREA */}
         <div className="flex-1 min-w-0 bg-white dark:bg-[#090C15] flex flex-col relative">
             {activeSetupId ? (() => {
                 const jobIdx = autoPilotJobs.findIndex(j => j.symbol === activeSetupId);
                 if (jobIdx === -1) return <div className="m-auto text-gray-400 text-sm">Select a setup</div>;
                 const job = autoPilotJobs[jobIdx];

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
                        logsM1BySymbol={{}}
                        agentStatusBySymbol={agentStatusBySymbol}
                        agentStatusM1Map={{}}
                        finalResultBySymbol={finalResultBySymbol}
                        verboseLogs={verboseLogsBySymbol[activeSetupId] || []}
                        topSignals={topSignalsBySymbol[activeSetupId] || []}
                     />
                 );
             })() : (
                 <div className="m-auto flex flex-col items-center justify-center gap-5 text-center max-w-md px-6">
                     <div className="flex items-center gap-3">
                       <div className="size-12 rounded-xl bg-blue-500/10 flex items-center justify-center text-blue-500">
                         <LuServer size={22} />
                       </div>
                       <div className="text-gray-300 dark:text-gray-600">→</div>
                       <div className="size-12 rounded-xl bg-purple-500/10 flex items-center justify-center text-purple-500">
                         <LuSparkles size={22} />
                       </div>
                       <div className="text-gray-300 dark:text-gray-600">→</div>
                       <div className="size-12 rounded-xl bg-amber-500/10 flex items-center justify-center text-amber-500">
                         <LuBrainCircuit size={22} />
                       </div>
                     </div>
                     <div>
                         <h3 className="text-base font-bold text-gray-900 dark:text-white mb-1">Pipeline v8</h3>
                         <p className="text-[12px] text-gray-500 leading-relaxed">
                           Server Scan → Gemma 4 → Gemini<br/>
                           <span className="text-gray-400">เลือก Setup จากด้านซ้ายเพื่อดูผลวิเคราะห์</span>
                         </p>
                     </div>
                 </div>
             )}
          </div>
        </div>

      {/* SETUP FORM MODAL — always a real modal overlay */}
      {editingJob && (
        <SetupFormModal 
          job={editingJob}
          trackedSymbols={trackedSymbols}
          onClose={() => { setEditingJob(null); setShowAddModal(false); }}
          onSave={handleSaveModal}
          onDelete={showAddModal ? () => { setEditingJob(null); setShowAddModal(false); } : handleDeleteModal}
        />
      )}

      {/* Trade Proposal Modal */}
      {tradeProposal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/80 backdrop-blur-md px-4">
          <div className="w-full max-w-md rounded-2xl bg-white dark:bg-[#090C15] border border-gray-200 dark:border-white/10 shadow-2xl p-6">
            <div className="flex items-center gap-4 mb-5">
              <div className="size-11 rounded-xl bg-gradient-to-br from-amber-400 to-orange-600 flex items-center justify-center text-white shadow-lg">
                <LuBrainCircuit className="size-5" />
              </div>
              <div>
                <h3 className="text-lg font-bold text-gray-900 dark:text-white">รอยืนยันออเดอร์</h3>
                <p className="text-[11px] text-gray-500">Pipeline v8 แนะนำการเข้าเทรด</p>
              </div>
            </div>

            <div className="rounded-xl border border-gray-100 dark:border-white/5 bg-gray-50 dark:bg-white/5 p-4 mb-5 space-y-2.5">
              {[
                ['Symbol', tradeProposal.symbol, 'text-blue-500 font-mono'],
                ['Direction', tradeProposal.direction, tradeProposal.direction === 'BUY' ? 'text-emerald-500' : 'text-red-500'],
                ['Confidence', `${tradeProposal.confidence || 0}%`, 'text-gray-700 dark:text-white'],
                ['Lot Size', tradeProposal.lot_size || 0.01, 'text-amber-500 font-mono'],
              ].map(([label, value, color]) => (
                <div key={label as string} className="flex justify-between items-center text-sm">
                  <span className="text-gray-500 font-medium">{label}</span>
                  <span className={`font-bold ${color}`}>{value}</span>
                </div>
              ))}
              {tradeProposal.reasoning && (
                <div className="pt-2.5 mt-2.5 border-t border-gray-200 dark:border-white/10 text-[11px] text-gray-600 dark:text-gray-400 leading-relaxed">
                  <strong className="text-gray-700 dark:text-gray-300">เหตุผล:</strong> {tradeProposal.reasoning}
                </div>
              )}
            </div>

            <div className="flex gap-3">
              <button 
                onClick={rejectProposal}
                className="flex-1 flex items-center justify-center gap-2 px-4 py-3 rounded-xl bg-gray-100 dark:bg-white/5 hover:bg-gray-200 dark:hover:bg-white/10 font-bold text-sm text-gray-600 dark:text-gray-400 transition-all"
              >
                <LuX size={16} /> ยกเลิก
              </button>
              <button 
                onClick={acceptProposal}
                className={`flex-1 flex items-center justify-center gap-2 px-4 py-3 rounded-xl text-white font-bold text-sm transition-all shadow-lg hover:brightness-110 ${
                  tradeProposal.direction === 'BUY' ? 'bg-emerald-500 shadow-emerald-500/25' : 'bg-red-500 shadow-red-500/25'
                }`}
              >
                <LuCheck size={16} /> อนุมัติ
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Confirm Dialog */}
      {confirmDialog && (
        <div className="fixed inset-0 z-[60] flex items-center justify-center bg-black/80 backdrop-blur-sm px-4">
          <div className="w-full max-w-sm rounded-2xl bg-white dark:bg-[#0B101E] border border-gray-200 dark:border-white/10 shadow-2xl p-6">
            <h3 className="text-base font-bold text-gray-900 dark:text-white mb-2 flex items-center gap-2">
               <LuBot className="size-4 text-amber-500" />
               ยืนยัน
            </h3>
            <p className="text-sm text-gray-600 dark:text-gray-400 mb-6">
               {confirmDialog?.message}
            </p>
            <div className="flex gap-3 justify-end">
              <button 
                onClick={() => setConfirmDialog(null)} 
                className="px-5 py-2 rounded-xl text-sm text-gray-500 hover:text-gray-900 dark:hover:text-white hover:bg-gray-100 dark:hover:bg-white/5 transition-all"
              >
                ยกเลิก
              </button>
              <button 
                onClick={() => { confirmDialog?.onConfirm(); setConfirmDialog(null); }} 
                className="px-5 py-2 rounded-xl text-sm font-bold text-white bg-blue-500 hover:bg-blue-600 shadow-lg shadow-blue-500/25 transition-all"
              >
                ตกลง
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default DashboardAi;
