import { useState, useEffect, useRef } from 'react';
import { LuBot, LuCheck, LuX, LuBrainCircuit, LuChevronDown, LuPlus, LuClock, LuBell } from 'react-icons/lu';
import { getWsUrl } from '@/utils/config';
import { AgentPanel } from './AgentPanel';
import type { AiLog, AgentStatusMap } from './AgentPanel';

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
        className={className || `flex items-center gap-2 px-4 py-2.5 rounded-xl bg-white dark:bg-[#090C15] border ${isOpen ? 'border-[#3B82F6]' : 'border-default-200 dark:border-white/10'} hover:border-[#3B82F6]/50 transition-colors text-sm font-bold justify-between shadow-sm text-default-800 dark:text-white/90 focus:outline-none`}
        style={{ minWidth }}
      >
        <div className="flex items-center gap-2">
           {icon !== undefined ? icon : <div className="size-2 rounded-full bg-[#1E3A8A]" />}
           <span>{selectedOption.label}</span>
        </div>
        <LuChevronDown className="text-default-400 dark:text-white/40" />
      </button>

      {isOpen && (
        <div className="absolute top-full mt-2 left-0 w-full min-w-max bg-white dark:bg-[#090C15] border border-default-200 dark:border-white/10 rounded-xl shadow-[0_10px_40px_rgba(0,0,0,0.8)] z-50 overflow-hidden py-1">
          <div className="max-h-[300px] overflow-y-auto custom-scrollbar">
            {options.map(opt => {
              const isSelected = String(value) === String(opt.value);
              return (
                <button
                  key={String(opt.value)}
                  onClick={() => { onChange(opt.value); setIsOpen(false); }}
                  className={`w-full flex items-center px-3 py-2 text-xs font-bold transition-colors ${isSelected ? 'bg-[#1E3A8A]/20' : 'hover:bg-default-100 dark:hover:bg-white/5'}`}
                >
                  <span className={`flex-1 text-left ${isSelected ? 'text-[#3B82F6]' : 'text-default-600 dark:text-white/80'}`}>
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

// Countdown timer for scan interval (removed due to unused variable error)

const DashboardAi = () => {
  const [logsBySymbol, setLogsBySymbol] = useState<Record<string, AiLog[]>>({});
  const [agentStatusBySymbol, setAgentStatusBySymbol] = useState<Record<string, AgentStatusMap>>({});
  const [finalResultBySymbol, setFinalResultBySymbol] = useState<Record<string, any>>({});
  const [lastRunMap, setLastRunMap] = useState<Record<string, number>>({});
  const [tradeProposal, setTradeProposal] = useState<any>(null);
  const [confirmDialog, setConfirmDialog] = useState<{ message: string; onConfirm: () => void } | null>(null);

  const [trackedSymbols, setTrackedSymbols] = useState<string[]>([]);
  // We keep globalSymbol as a fallback default for parsing websocket logs 
  const [globalSymbol, setGlobalSymbol] = useState("XAUUSD");
  // Auto-Pilot States
  // Auto-Pilot States
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
          // auto_analyze is now per-job
          
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
          setLastRunMap(prev => ({...prev, [sym]: Date.now()}));
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
     // Only save jobs that have finalized their setup (not drafts)
     const cleanJobs = newJobs.filter(j => !j.is_draft).map(j => {
        const { is_draft, ...rest } = j;
        return rest;
     });
     updateConfig('ai_autopilot_jobs', JSON.stringify(cleanJobs));
  };

  const handleToggleAgent = (jobIndex: number, agentKey: string) => {
    const newJobs = [...autoPilotJobs];
    const job = { ...newJobs[jobIndex] };
    const disabled = job.disabled_agents || [];
    
    if (disabled.includes(agentKey)) {
      job.disabled_agents = disabled.filter(a => a !== agentKey);
    } else {
      job.disabled_agents = [...disabled, agentKey];
    }
    
    newJobs[jobIndex] = job;
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

      {/* Manual Global Run Panel */}


      {/* Array of Auto-Pilot Panels! */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4 items-stretch w-full">
        {autoPilotJobs.map((job, idx) => (
           <div key={`job-${idx}-${job.symbol}`} className="bg-white dark:bg-[#0B101E] border border-default-200 dark:border-white/5 rounded-2xl flex flex-col shadow-xl relative overflow-hidden group">
               {/* Tiny delete button */}
               {job.is_draft && (
                   <button onClick={() => {
                       setConfirmDialog({
                           message: `คุณแน่ใจหรือไม่ว่าต้องการลบการตั้งค่าบอท ${job.symbol}?`,
                           onConfirm: () => {
                               const newJobs = autoPilotJobs.filter((_, i) => i !== idx);
                               saveJobsToDb(newJobs);
                           }
                       });
                   }} className="absolute top-3 right-3 text-gray-500 hover:text-red-500 transition-colors z-20">
                       <LuX className="size-4" />
                   </button>
               )}

               {/* Setup Settings Block embedded at the top */}
               {job.is_draft && (
                   <div className="p-5 border-b border-default-200 dark:border-white/5 bg-gradient-to-b from-default-50 to-white dark:from-[#131826]/80 dark:to-[#0B101E]">
                      <h3 className="text-xs font-black text-default-700 dark:text-gray-300 flex items-center gap-2 mb-4 uppercase tracking-widest border-b border-default-200/50 dark:border-white/5 pb-3">
                         <LuBot className="size-4 text-blue-500" />
                         Trade Parameters
                      </h3>
                      <div className="grid grid-cols-2 gap-3 mb-5">
                          <div className="flex flex-col gap-1.5">
                              <label className="text-[10px] font-bold text-gray-500 uppercase tracking-widest">Symbol</label>
                              <CustomSelect
                                  value={job.symbol}
                                  options={trackedSymbolOptions}
                                  onChange={(val) => {
                                  const newJobs = [...autoPilotJobs];
                                  newJobs[idx].symbol = val;
                                  saveJobsToDb(newJobs);
                                  }}
                                  className="w-full flex items-center justify-between gap-1 px-3 py-2 rounded-xl bg-white dark:bg-[#131826] border border-default-200 dark:border-white/5 hover:border-blue-500/50 text-[11px] font-bold text-default-800 dark:text-gray-200 focus:outline-none shadow-sm transition-colors"
                                  minWidth="100%"
                              />
                          </div>

                          <div className="flex flex-col gap-1.5">
                              <label className="text-[10px] font-bold text-gray-500 uppercase tracking-widest">Lot Size</label>
                              <input
                                  type="number"
                                  min="0.01" step="0.01"
                                  value={job.lot_size}
                                  onChange={(e) => {
                                  const newJobs = [...autoPilotJobs];
                                  newJobs[idx].lot_size = parseFloat(e.target.value) || 0.01;
                                  saveJobsToDb(newJobs);
                                  }}
                                  className="w-full px-3 py-2 text-[11px] font-bold rounded-xl bg-white dark:bg-[#131826] border border-default-200 dark:border-white/5 hover:border-blue-500/50 focus:border-blue-500 outline-none transition-all shadow-sm"
                              />
                          </div>
                      </div>

                      <div className="grid grid-cols-2 gap-3 mb-5 pb-5 border-b border-default-200 dark:border-white/5">
                          <div className="flex items-center justify-between col-span-2 p-3 rounded-xl bg-default-100/50 dark:bg-white/5 border border-default-200 dark:border-white/5">
                              <div className="flex items-center gap-2">
                                  <LuBell className="size-4 text-blue-500" />
                                  <div>
                                      <p className="text-[11px] font-bold text-default-700 dark:text-gray-200">Telegram Alerts</p>
                                      <p className="text-[9px] text-gray-500">Notify when order opens/closes</p>
                                  </div>
                              </div>
                              <button onClick={() => {
                                  const newJobs = [...autoPilotJobs];
                                  newJobs[idx].telegram_alert = !newJobs[idx].telegram_alert;
                                  saveJobsToDb(newJobs);
                              }} className={`relative inline-flex h-5 w-9 shrink-0 cursor-pointer items-center justify-center rounded-full focus:outline-none transition-colors ${job.telegram_alert ? 'bg-blue-500 shadow-[0_0_10px_rgba(59,130,246,0.3)]' : 'bg-gray-300 dark:bg-gray-700'}`}>
                                  <span className={`pointer-events-none inline-block h-3.5 w-3.5 transform rounded-full shadow-sm ring-0 transition duration-200 ease-in-out ${job.telegram_alert ? 'translate-x-2 bg-white' : '-translate-x-2 bg-gray-100 dark:bg-gray-400'}`} />
                              </button>
                          </div>

                          <div className="flex flex-col gap-1.5 col-span-2">
                              <label className="text-[10px] font-bold text-gray-500 uppercase tracking-widest mb-1">Target Mode (TP/SL)</label>
                              <div className="flex rounded-xl overflow-hidden border border-default-200 dark:border-white/5 p-1 bg-default-100/50 dark:bg-[#131826]">
                                  {['usd', 'pips', 'none'].map((mode) => (
                                      <button key={mode} onClick={() => {
                                          const newJobs = [...autoPilotJobs];
                                          newJobs[idx].tp_sl_mode = mode as any;
                                          saveJobsToDb(newJobs);
                                      }} className={`flex-1 text-[10px] font-bold uppercase py-1.5 rounded-lg transition-all ${job.tp_sl_mode === mode || (!job.tp_sl_mode && mode==='none') ? 'bg-primary text-white shadow-sm' : 'text-gray-500 hover:text-default-700 dark:hover:text-gray-300'}`}>
                                          {mode}
                                      </button>
                                  ))}
                              </div>
                          </div>

                          {(job.tp_sl_mode && job.tp_sl_mode !== 'none') && (
                              <>
                                  <div className="flex flex-col gap-1.5">
                                      <label className="text-[10px] font-bold text-gray-500 uppercase tracking-widest">{job.tp_sl_mode === 'usd' ? 'TP ($)' : 'TP (Pips)'}</label>
                                      <input
                                          type="number"
                                          min="0" step="1"
                                          value={job.tp_value || 0}
                                          onChange={(e) => {
                                          const newJobs = [...autoPilotJobs];
                                          newJobs[idx].tp_value = parseFloat(e.target.value) || 0;
                                          saveJobsToDb(newJobs);
                                          }}
                                          className="w-full px-3 py-2 text-[11px] font-bold rounded-xl bg-white dark:bg-[#131826] border border-default-200 dark:border-white/5 hover:border-emerald-500/50 focus:border-emerald-500 outline-none transition-all text-emerald-600 dark:text-emerald-400"
                                      />
                                  </div>
                                  <div className="flex flex-col gap-1.5">
                                      <label className="text-[10px] font-bold text-gray-500 uppercase tracking-widest">Trailing Step (Pips)</label>
                                      <input
                                          type="number"
                                          min="0" step="1"
                                          value={job.ts_value || 0}
                                          onChange={(e) => {
                                          const newJobs = [...autoPilotJobs];
                                          newJobs[idx].ts_value = parseFloat(e.target.value) || 0;
                                          saveJobsToDb(newJobs);
                                          }}
                                          className="w-full px-3 py-2 text-[11px] font-bold rounded-xl bg-white dark:bg-[#131826] border border-default-200 dark:border-white/5 hover:border-blue-500/50 focus:border-blue-500 outline-none transition-all text-blue-600 dark:text-blue-400"
                                      />
                                  </div>
                              </>
                          )}

                          <div className="flex flex-col gap-1.5 justify-center mt-2">
                              <label className="text-[10px] font-bold text-gray-500 uppercase tracking-widest mb-1">Auto-Execute</label>
                              <button onClick={() => {
                                  const newJobs = [...autoPilotJobs];
                                  newJobs[idx].auto_trade = !newJobs[idx].auto_trade;
                                  saveJobsToDb(newJobs);
                              }} className={`relative inline-flex h-6 w-11 shrink-0 cursor-pointer items-center justify-center rounded-full focus:outline-none transition-colors ${job.auto_trade ? 'bg-emerald-500 shadow-[0_0_15px_rgba(16,185,129,0.3)]' : 'bg-gray-200 dark:bg-gray-800'}`}>
                                  <span className={`pointer-events-none inline-block h-4 w-4 transform rounded-full shadow-md ring-0 transition duration-200 ease-in-out ${job.auto_trade ? 'translate-x-2.5 bg-white' : '-translate-x-2.5 bg-gray-400 dark:bg-gray-500'}`} />
                              </button>
                          </div>
                          <div className="flex flex-col gap-1.5 justify-center mt-2">
                              <label className="text-[10px] font-bold text-gray-500 uppercase tracking-widest"><LuClock className="inline size-3 mr-1" />Scan Every (min)</label>
                              <input
                                  type="number"
                                  min="1" max="1440" step="1"
                                  value={job.interval}
                                  onChange={(e) => {
                                  const newJobs = [...autoPilotJobs];
                                  newJobs[idx].interval = parseInt(e.target.value) || 5;
                                  saveJobsToDb(newJobs);
                                  }}
                                  className="w-full px-3 py-2 text-[11px] font-bold rounded-xl bg-white dark:bg-[#131826] border border-default-200 dark:border-white/5 hover:border-blue-500/50 focus:border-blue-500 outline-none transition-all shadow-sm"
                              />
                          </div>
                      </div>

                      {/* AI Context Feeds Checkboxes/Badges */}
                      <div className="mt-6 pt-4 border-t border-default-200 dark:border-white/5">
                          <h4 className="text-[10px] font-bold text-gray-500 uppercase tracking-widest mb-3 flex items-center gap-1.5">
                              <LuBrainCircuit className="size-3 text-purple-500" /> AI Context Feeds 
                              <span className="text-[8px] px-1.5 py-0.5 rounded bg-blue-500/10 text-blue-600 dark:text-blue-400 font-bold ml-auto">LIVE</span>
                          </h4>
                          <div className="flex flex-col gap-2.5">
                              <div className="flex items-center gap-2.5 p-2.5 rounded-xl bg-gradient-to-r from-emerald-500/10 to-transparent border border-emerald-500/20 text-emerald-600 dark:text-emerald-400">
                                  <div className="size-5 rounded-full bg-emerald-500/20 flex items-center justify-center shrink-0">
                                      <LuCheck className="size-3" />
                                  </div>
                                  <div className="flex-1">
                                      <p className="text-[11px] font-black tracking-wide">Algorithmic Extractor</p>
                                      <p className="text-[9px] font-semibold opacity-80 mt-0.5">RSI, EMA (9/21/50), Bollinger Bands</p>
                                  </div>
                              </div>
                              <div className="flex items-center gap-2.5 p-2.5 rounded-xl bg-gradient-to-r from-blue-500/10 to-transparent border border-blue-500/20 text-blue-600 dark:text-blue-400">
                                  <div className="size-5 rounded-full bg-blue-500/20 flex items-center justify-center shrink-0">
                                      <LuCheck className="size-3" />
                                  </div>
                                  <div className="flex-1">
                                      <p className="text-[11px] font-black tracking-wide">SMC / ICT Data</p>
                                      <p className="text-[9px] font-semibold opacity-80 mt-0.5">Order Blocks, FVG (Fair Value Gaps)</p>
                                  </div>
                              </div>
                              <div className="flex items-center gap-2.5 p-2.5 rounded-xl bg-gradient-to-r from-purple-500/10 to-transparent border border-purple-500/20 text-purple-600 dark:text-purple-400">
                                  <div className="size-5 rounded-full bg-purple-500/20 flex items-center justify-center shrink-0">
                                      <LuCheck className="size-3" />
                                  </div>
                                  <div className="flex-1">
                                      <p className="text-[11px] font-black tracking-wide">Volume Profile Proxy</p>
                                      <p className="text-[9px] font-semibold opacity-80 mt-0.5">High Volume Nodes (HVN), POC tracking</p>
                                  </div>
                              </div>
                          </div>
                      </div>
                   </div>
               )}

               {/* Agent Panel (Monitoring) */}
               {job.is_draft ? (
                  <div className="p-5 bg-default-50/50 dark:bg-[#0A0D14] flex-1 flex flex-col justify-center items-center">
                      <button 
                         onClick={() => {
                            const newJobs = [...autoPilotJobs];
                            newJobs[idx].is_draft = false;
                            saveJobsToDb(newJobs);
                         }}
                         className="w-full max-w-[220px] flex items-center justify-center gap-2 bg-gradient-to-r from-blue-600 to-indigo-600 hover:from-blue-500 hover:to-indigo-500 text-white text-[11px] font-black py-3.5 rounded-xl transition-all shadow-[0_10px_20px_rgba(37,99,235,0.2)] hover:shadow-[0_10px_25px_rgba(37,99,235,0.4)] hover:-translate-y-0.5 uppercase tracking-widest relative overflow-hidden group"
                      >
                         <div className="absolute inset-0 bg-white/20 translate-y-full group-hover:translate-y-0 transition-transform duration-300" />
                         <LuCheck className="size-4 shrink-0 transition-transform group-hover:scale-110" /> Deploy AI Agent
                      </button>
                      <span className="text-[9px] text-gray-500 mt-4 font-semibold text-center leading-relaxed">
                         Configure your parameters above<br/>and click Deploy to activate the Agent.
                      </span>
                  </div>
               ) : (
                 <AgentPanel
                    title={`Auto-Pilot Job: ${job.symbol}`}
                    symbol={job.symbol}
                    isClosed={closedMap[job.symbol] || false}
                    jobEnabled={job.enabled !== false}
                    interval={job.interval}
                    lastRunTime={lastRunMap[job.symbol] || null}
                    onToggleJob={() => {
                      const isCurrentlyEnabled = job.enabled !== false;
                      if (isCurrentlyEnabled) {
                        setConfirmDialog({
                           message: `คุณแน่ใจหรือไม่ว่าต้องการระงับการทำงานของบอท ${job.symbol}?`,
                           onConfirm: () => {
                               const newJobs = [...autoPilotJobs];
                               newJobs[idx].enabled = false;
                               saveJobsToDb(newJobs);
                           }
                        });
                        return;
                      }
                      // If it's turning ON, just do it directly without confirm
                      const newJobs = [...autoPilotJobs];
                      newJobs[idx].enabled = true;
                      saveJobsToDb(newJobs);
                    }}
                    onEditJob={() => {
                      const newJobs = [...autoPilotJobs];
                      newJobs[idx].is_draft = true;
                      saveJobsToDb(newJobs);
                    }}
                    logs={logsBySymbol[job.symbol] || []}
                    agentStatus={agentStatusBySymbol[job.symbol] || {
                      news_hunter: 'idle', chart_analyst: 'idle', calendar: 'idle',
                      risk_manager: 'idle', decision_maker: 'idle', orchestrator: 'idle',
                    }}
                    finalResult={finalResultBySymbol[job.symbol]}
                    autoTrade={job.auto_trade}
                    onToggleAutoTrade={() => {
                      const newJobs = [...autoPilotJobs];
                      newJobs[idx].auto_trade = !newJobs[idx].auto_trade;
                      saveJobsToDb(newJobs);
                    }}
                    disabledAgents={job.disabled_agents || []}
                    onToggleAgent={(agentKey) => handleToggleAgent(idx, agentKey)}
                 />
               )}
           </div>
        ))}

        {/* Add Setup Button / Placeholder */}
        <button 
             onClick={() => saveJobsToDb([...autoPilotJobs, { symbol: trackedSymbols.includes('ETHUSD') ? 'ETHUSD' : (trackedSymbols[0] || 'ETHUSD'), interval: 15, auto_trade: false, lot_size: 0.01, ai_mode: 'eval_10_strategies', is_draft: true }])}
             className="w-full min-h-[300px] border-[2px] border-dashed border-default-300 dark:border-white/10 rounded-3xl flex flex-col items-center justify-center gap-4 text-default-400 dark:text-gray-500 hover:text-blue-500 dark:hover:text-blue-400 hover:border-blue-500 hover:bg-blue-50 dark:hover:bg-blue-900/10 transition-all group shadow-sm hover:shadow-xl hover:shadow-blue-500/10"
        >
             <div className="size-16 rounded-2xl bg-white dark:bg-[#0B101E] border-[2px] border-default-300 dark:border-white/10 flex items-center justify-center group-hover:bg-blue-500 group-hover:border-blue-500 group-hover:text-white transition-all shadow-sm">
                 <LuPlus className="size-7 transition-transform group-hover:scale-125" />
             </div>
             <div className="flex flex-col items-center">
                 <span className="text-[12px] font-black tracking-widest uppercase mb-1">New AI Agent Setup</span>
                 <span className="text-[10px] opacity-70">Initialize a new algorithmic trading bot</span>
             </div>
        </button>
      </div>

      {/* Trade Proposal Modal */}
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
               {confirmDialog.message}
            </p>
            <div className="flex gap-3 justify-end items-center">
              <button 
                onClick={() => setConfirmDialog(null)} 
                className="px-5 py-2.5 rounded-xl text-xs font-bold text-default-500 dark:text-gray-400 hover:text-default-900 dark:hover:text-white hover:bg-default-100 dark:hover:bg-white/5 transition-all"
              >
                ยกเลิก
              </button>
              <button 
                onClick={() => { confirmDialog.onConfirm(); setConfirmDialog(null); }} 
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
