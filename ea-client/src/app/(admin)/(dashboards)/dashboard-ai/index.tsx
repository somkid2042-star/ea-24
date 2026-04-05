import { useState, useEffect, useRef } from 'react';
import { LuBot, LuCheck, LuX, LuBrainCircuit, LuChevronDown, LuZap, LuPlus, LuTrash } from 'react-icons/lu';
import { getWsUrl } from '@/utils/config';
import { AgentPanel } from './AgentPanel';
import type { AiLog, AgentStatusMap } from './AgentPanel';

type AutoPilotJob = { symbol: string; interval: number; auto_trade: boolean; lot_size: number; ai_mode?: string; };

const CustomSelect = ({ value, options, onChange, icon, minWidth = '120px', className, containerClassName }: { value: string | number, options: {label: string, value: string | number}[], onChange: (val: any) => void, icon?: React.ReactNode, minWidth?: string, className?: string, containerClassName?: string }) => {
  const [isOpen, setIsOpen] = useState(false);
  const containerRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const handleClickOutside = (e: MouseEvent) => {
      if (containerRef.current && !containerRef.current.contains(e.target as Node)) setIsOpen(false);
    };
    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, []);

  const selectedOption = options.find(o => String(o.value) === String(value)) || { label: value, value };

  return (
    <div className={`relative ${containerClassName || ''}`} ref={containerRef}>
      <button 
        onClick={() => setIsOpen(!isOpen)}
        className={className || `flex items-center gap-2 px-4 py-2.5 rounded-xl bg-[#090C15] border ${isOpen ? 'border-[#3B82F6]' : 'border-white/10'} hover:border-[#3B82F6]/50 transition-colors text-sm font-bold justify-between shadow-sm text-white/90 focus:outline-none`}
        style={{ minWidth }}
      >
        <div className="flex items-center gap-2">
           {icon !== undefined ? icon : <div className="size-2 rounded-full bg-[#1E3A8A]" />}
           <span>{selectedOption.label}</span>
        </div>
        <LuChevronDown className="text-white/40" />
      </button>

      {isOpen && (
        <div className="absolute top-full mt-2 left-0 w-full min-w-max bg-[#090C15] border border-white/10 rounded-xl shadow-[0_10px_40px_rgba(0,0,0,0.8)] z-50 overflow-hidden py-1">
          <div className="max-h-[300px] overflow-y-auto custom-scrollbar">
            {options.map(opt => {
              const isSelected = String(value) === String(opt.value);
              return (
                <button
                  key={String(opt.value)}
                  onClick={() => { onChange(opt.value); setIsOpen(false); }}
                  className={`w-full flex items-center px-3 py-2 text-xs font-bold transition-colors ${isSelected ? 'bg-[#1E3A8A]/20' : 'hover:bg-white/5'}`}
                >
                  <span className={`flex-1 text-left ${isSelected ? 'text-[#3B82F6]' : 'text-white/80'}`}>
                    {opt.label}
                  </span>
                </button>
              );
            })}
          </div>
        </div>
      )}
    </div>
  );
};

const DashboardAi = () => {
  const [logsBySymbol, setLogsBySymbol] = useState<Record<string, AiLog[]>>({});
  const [agentStatusBySymbol, setAgentStatusBySymbol] = useState<Record<string, AgentStatusMap>>({});
  const [finalResultBySymbol, setFinalResultBySymbol] = useState<Record<string, any>>({});
  const [tradeProposal, setTradeProposal] = useState<any>(null);

  const [trackedSymbols, setTrackedSymbols] = useState<string[]>([]);
  // We keep globalSymbol as a fallback default for parsing websocket logs 
  const [globalSymbol, setGlobalSymbol] = useState("XAUUSD");
  // Auto-Pilot States
  const [autoAnalyze, setAutoAnalyze] = useState(false);
  const [autoPilotJobs, setAutoPilotJobs] = useState<AutoPilotJob[]>([]);
  const [closedMap, setClosedMap] = useState<Record<string, boolean>>({});
  
  const wsRef = useRef<WebSocket | null>(null);

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
          if (c.ai_auto_analyze !== undefined) setAutoAnalyze(c.ai_auto_analyze === 'true');
          
          if (c.ai_autopilot_jobs) {
            try { setAutoPilotJobs(JSON.parse(c.ai_autopilot_jobs)); } catch(e){}
          } else if (c.ai_target_symbols) {
            // Legacy migration
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
          const sym = data.symbol || globalSymbol; // Fallback
          const newLog = { timestamp: Date.now(), agent: data.agent, status: data.status, message: data.message };
          
          setLogsBySymbol(prev => ({
             ...prev,
             [sym]: [...(prev[sym] || []), newLog]
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
          setAgentStatusBySymbol(prev => ({
             ...prev,
             [sym]: {
                news_hunter: 'idle', chart_analyst: 'idle', calendar: 'idle',
                risk_manager: 'idle', decision_maker: 'idle', orchestrator: 'running',
             }
          }));
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
     updateConfig('ai_autopilot_jobs', JSON.stringify(newJobs));
  };



  const acceptProposal = () => {
    if (!wsRef.current || wsRef.current.readyState !== WebSocket.OPEN || !tradeProposal) return;
    wsRef.current.send(JSON.stringify({
      action: "open_trade",
      symbol: tradeProposal.symbol,
      direction: tradeProposal.direction,
      lot_size: tradeProposal.lot_size || 0.01
    }));
    setTradeProposal(null);
  };

  const rejectProposal = () => setTradeProposal(null);

  // Symbol options for our CustomSelect
  const trackedSymbolOptions = trackedSymbols
    .filter(s => !closedMap[s])
    .map(s => ({ label: s, value: s }));
  
  return (
    <div className="p-4 md:p-6 lg:p-8 max-w-7xl mx-auto space-y-6">
      {/* Header Controls */}
      <div className="flex flex-col md:flex-row justify-between items-start md:items-end gap-4 border-b border-default-200 pb-4">
        <div>
          <h1 className="text-2xl font-black text-default-900 tracking-tight flex items-center gap-2">
            Multi-Currency Auto-Pilot
          </h1>
          <p className="text-sm font-medium text-default-500 mt-1">วิเคราะห์ตลาดและบริหารความเสี่ยงด้วย AI หลายสกุลเงินพร้อมกัน</p>
        </div>
      </div>

      {/* Auto-Pilot Task Configuration Box */}
      <div className="card">
         <div className="card-header">
            <h4 className="card-title flex items-center gap-2">
               <LuBot className="size-5 text-primary" />
               Auto-Pilot Background Tasks
            </h4>
            <div className="flex items-center gap-3">
               <span className="text-sm font-semibold text-default-700">Master Switch: </span>
               <button
                 onClick={() => {
                   const next = !autoAnalyze;
                   setAutoAnalyze(next);
                   updateConfig('ai_auto_analyze', next.toString());
                 }}
                 className={`relative inline-flex h-6 w-11 items-center rounded-full transition-colors ${autoAnalyze ? 'bg-primary' : 'bg-default-300 dark:bg-default-700'}`}
               >
                 <span className={`inline-block size-4 transform rounded-full bg-white transition-transform ${autoAnalyze ? 'translate-x-5' : 'translate-x-1'}`} />
               </button>
            </div>
         </div>
         
         <div className="card-body">
            <p className="text-sm text-default-500 mb-5">คิวการทำงานของ AI แยกรันแต่ละคู่เงินแบบอิสระ ไม่ดึงโควต้าตีกัน</p>
            <div className="space-y-4">
               {autoPilotJobs.map((job, idx) => (
                   <div key={idx} className="flex flex-wrap lg:flex-nowrap items-center gap-4 p-4 border border-default-200 dark:border-default-200/50 rounded-xl hover:bg-default-50/50 dark:hover:bg-default-300/5 transition-colors">
                       <CustomSelect
                           value={job.symbol}
                           options={trackedSymbolOptions}
                           onChange={(val) => {
                               const newJobs = [...autoPilotJobs];
                               newJobs[idx].symbol = val;
                               saveJobsToDb(newJobs);
                           }}
                           minWidth="110px"
                           className="flex items-center gap-2 px-3 py-2 rounded-lg bg-default-100 dark:bg-default-50 border border-default-200 dark:border-default-200/50 hover:border-primary/30 transition-colors text-sm font-semibold justify-between shadow-sm focus:outline-none focus:border-primary"
                       />

                       <div className="flex items-center gap-2">
                           <span className="text-[10px] font-bold text-default-400 uppercase tracking-widest">Interval</span>
                           <CustomSelect
                               value={job.interval}
                               options={[
                                 { label: '5 นาที', value: 5 },
                                 { label: '15 นาที', value: 15 },
                                 { label: '30 นาที', value: 30 },
                                 { label: '1 ชั่วโมง', value: 60 },
                                 { label: '4 ชั่วโมง', value: 240 },
                               ]}
                               onChange={(val) => {
                                   const newJobs = [...autoPilotJobs];
                                   newJobs[idx].interval = Number(val);
                                   saveJobsToDb(newJobs);
                               }}
                               icon={<LuZap className="text-default-400 size-3" />}
                               minWidth="100px"
                               className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-default-100 dark:bg-default-50 border border-default-200 dark:border-default-200/50 hover:bg-default-200 dark:hover:bg-default-100 transition-colors text-sm font-semibold justify-between shadow-sm focus:outline-none"
                           />
                       </div>

                       <div className="flex items-center gap-2">
                           <span className="text-[10px] font-bold text-default-400 uppercase tracking-widest">Mode</span>
                           <CustomSelect
                               value={job.ai_mode || 'auto'}
                               options={[
                                 { label: '💡 AI หาให้', value: 'auto' },
                                 { label: '⚙️ 10 กลยุทธ์', value: 'eval_10_strategies' },
                               ]}
                               onChange={(val) => {
                                   const newJobs = [...autoPilotJobs];
                                   newJobs[idx].ai_mode = val;
                                   saveJobsToDb(newJobs);
                               }}
                               icon={null}
                               minWidth="110px"
                               className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-default-100 dark:bg-default-50 border border-default-200 dark:border-default-200/50 hover:bg-default-200 dark:hover:bg-default-100 transition-colors text-sm font-semibold justify-between shadow-sm focus:outline-none"
                           />
                       </div>

                       <div className="flex items-center gap-2">
                           <span className="text-[10px] font-bold text-default-400 uppercase tracking-widest">Lot Target</span>
                           <input
                               type="number"
                               min="0.01" step="0.01"
                               value={job.lot_size}
                               onChange={(e) => {
                                   const newJobs = [...autoPilotJobs];
                                   newJobs[idx].lot_size = parseFloat(e.target.value) || 0.01;
                                   saveJobsToDb(newJobs);
                               }}
                               className="w-20 px-3 py-1.5 text-sm font-semibold rounded-lg bg-default-100 dark:bg-default-50 border border-default-200 dark:border-default-200/50 hover:border-primary/30 outline-none focus:border-primary transition-all font-mono"
                           />
                       </div>

                       <button
                           onClick={() => {
                               const newJobs = [...autoPilotJobs];
                               newJobs[idx].auto_trade = !newJobs[idx].auto_trade;
                               saveJobsToDb(newJobs);
                           }}
                           className={`ml-auto px-4 py-2 min-w-[170px] rounded-lg text-[11px] font-bold transition-all duration-300 ${job.auto_trade ? 'bg-amber-500 text-white shadow-md shadow-amber-500/20 hover:bg-amber-600' : 'bg-default-100 text-default-600 border border-default-200 hover:bg-default-200 dark:bg-default-50 dark:border-default-200/50 dark:text-default-400 dark:hover:text-default-300'}`}
                       >
                           {job.auto_trade ? '⚡ EXECUTE AUTO-TRADE' : '🔔 SIGNAL NOTIFY ONLY'}
                       </button>
                       
                       <button 
                           onClick={() => {
                               const newJobs = autoPilotJobs.filter((_, i) => i !== idx);
                               saveJobsToDb(newJobs);
                           }}
                           className="p-2 ml-1 text-red-500 hover:bg-red-500 hover:text-white rounded-lg transition-all border border-transparent hover:shadow-md bg-default-100 dark:bg-default-50 lg:bg-transparent"
                       >
                            <LuTrash className="size-4" />
                       </button>
                   </div>
               ))}

               <button 
                   onClick={() => saveJobsToDb([...autoPilotJobs, { symbol: trackedSymbols[0] || 'XAUUSD', interval: 15, auto_trade: false, lot_size: 0.01, ai_mode: 'auto' }])}
                   className="w-full py-4 mt-2 bg-primary/5 hover:bg-primary/10 border-2 border-dashed border-primary/30 rounded-xl text-primary font-bold text-sm transition-all flex items-center justify-center gap-2 group"
               >
                   <LuPlus className="size-4 group-hover:scale-110 transition-transform" />
                   ADD ANALYSIS ENGINE THREAD
               </button>
            </div>
         </div>
      </div>

      {/* Manual Global Run Panel */}


      {/* Array of Auto-Pilot Panels! */}
      {autoAnalyze && autoPilotJobs.map((job, idx) => (
         <AgentPanel
            key={`job-${idx}-${job.symbol}`}
            title={`Auto-Pilot Job: ${job.symbol}`}
            symbol={job.symbol}
            isClosed={closedMap[job.symbol] || false}
            logs={logsBySymbol[job.symbol] || []}
            agentStatus={agentStatusBySymbol[job.symbol] || {
              news_hunter: 'idle', chart_analyst: 'idle', calendar: 'idle',
              risk_manager: 'idle', decision_maker: 'idle', orchestrator: 'idle',
            }}
            finalResult={finalResultBySymbol[job.symbol]}
         />
      ))}

      {/* Trade Proposal Modal */}
      {tradeProposal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/80 backdrop-blur-md px-4">
          <div className="w-full max-w-md rounded-3xl bg-[#090C15] border border-white/10 shadow-[0_20px_60px_rgba(0,0,0,0.8)] p-6 animate-in slide-in-from-bottom-4">
            <div className="flex items-center gap-4 mb-6">
              <div className="size-12 rounded-2xl bg-gradient-to-br from-amber-400 to-orange-600 flex items-center justify-center text-white shadow-lg shadow-amber-500/20">
                <LuBrainCircuit className="size-6" />
              </div>
              <div>
                <h3 className="text-xl font-black text-white/90">รอการยืนยันออเดอร์</h3>
                <p className="text-xs font-semibold text-white/40">AI Agent แนะนำการเข้าเทรด</p>
              </div>
            </div>

            <div className="rounded-2xl border border-white/5 bg-white/5 p-4 mb-6 space-y-3 shadow-inner">
              {[
                ['Symbol', tradeProposal.symbol, 'text-[#3B82F6]'],
                ['Direction', tradeProposal.direction, tradeProposal.direction === 'BUY' ? 'text-emerald-400' : 'text-red-400'],
                ['Confidence', `${tradeProposal.confidence || 0}%`, 'text-white/80'],
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
    </div>
  );
};

export default DashboardAi;
