import { useState, useEffect, useRef } from 'react';
import { LuBot, LuTerminal, LuPlay, LuCheck, LuX, LuLoader, LuShield, LuCalendar, LuGlobe, LuActivity, LuBrainCircuit, LuChevronDown, LuZap, LuTrendingUp, LuTrendingDown, LuMinus } from 'react-icons/lu';
import { getWsUrl } from '@/utils/config';

type AiLog = { timestamp: number; agent: string; status: string; message: string; };
type AgentStatus = 'idle' | 'running' | 'done' | 'error';
type AgentStatusMap = {
  news_hunter: AgentStatus;
  chart_analyst: AgentStatus;
  calendar: AgentStatus;
  risk_manager: AgentStatus;
  decision_maker: AgentStatus;
  orchestrator: AgentStatus;
};

const OpenClawDashboard = () => {
  const [logs, setLogs] = useState<AiLog[]>([]);
  const [connected, setConnected] = useState(false);
  const [symbol, setSymbol] = useState("XAUUSD");
  const [trackedSymbols, setTrackedSymbols] = useState<string[]>([]);
  const [isAnalyzing, setIsAnalyzing] = useState(false);
  const [agentStatus, setAgentStatus] = useState<AgentStatusMap>({
    news_hunter: 'idle', chart_analyst: 'idle', calendar: 'idle',
    risk_manager: 'idle', decision_maker: 'idle', orchestrator: 'idle',
  });
  const [agentLatestLog, setAgentLatestLog] = useState<Record<string, string>>({});
  const [finalResult, setFinalResult] = useState<any>(null);
  const [tradeProposal, setTradeProposal] = useState<any>(null);
  const [showSymbolDropdown, setShowSymbolDropdown] = useState(false);
  const wsRef = useRef<WebSocket | null>(null);
  const logsEndRef = useRef<HTMLDivElement>(null);
  
  useEffect(() => {
    logsEndRef.current?.scrollIntoView({ behavior: "smooth" });
  }, [logs]);

  useEffect(() => {
    const WS_URL = getWsUrl();
    const ws = new WebSocket(WS_URL);
    wsRef.current = ws;

    ws.onopen = () => {
      setConnected(true);
      setLogs([{ timestamp: Date.now(), agent: 'System', status: 'done', message: '✅ เชื่อมต่อกับ Trading Server สำเร็จ' }]);
      // Request tracked symbols
      ws.send(JSON.stringify({ action: "get_tracked_symbols" }));
    };
    
    ws.onclose = () => setConnected(false);

    ws.onmessage = (evt) => {
      try {
        const data = JSON.parse(evt.data);
        
        if (data.type === 'tracked_symbols') {
          setTrackedSymbols(data.symbols || []);
          if (data.symbols?.length > 0 && !data.symbols.includes(symbol)) {
            setSymbol(data.symbols[0]);
          }
        }

        if (data.type === 'agent_log') {
          setLogs(prev => [...prev, { 
            timestamp: Date.now(), agent: data.agent, status: data.status, message: data.message 
          }]);
          if (data.agent) {
            setAgentStatus(prev => ({ ...prev, [data.agent]: data.status }));
            setAgentLatestLog(prev => ({ ...prev, [data.agent]: data.message }));
          }
        }
        
        if (data.type === 'multi_agent_result') {
          setFinalResult(data.result);
          setIsAnalyzing(false);
          setAgentStatus(prev => ({ ...prev, orchestrator: 'done' }));
        }

        if (data.type === 'agents_started') {
          setAgentStatus({
            news_hunter: 'idle', chart_analyst: 'idle', calendar: 'idle',
            risk_manager: 'idle', decision_maker: 'idle', orchestrator: 'running',
          });
          setAgentLatestLog({});
          setFinalResult(null);
          setTradeProposal(null);
        }

        if (data.type === 'ai_trade_proposal') {
          setTradeProposal(data);
        }
      } catch (_e) {}
    };

    return () => ws.close();
  }, []);

  const runAnalysis = () => {
    if (!wsRef.current || wsRef.current.readyState !== WebSocket.OPEN) return;
    setIsAnalyzing(true);
    setLogs([]);
    wsRef.current.send(JSON.stringify({
      action: "run_agents",
      symbol: symbol,
    }));
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

  const agentConfig = [
    { key: 'news_hunter', name: 'News Hunter', desc: 'ค้นหาข่าวสาร', icon: <LuGlobe size={20} />, gradient: 'from-blue-500/20 to-cyan-500/10' },
    { key: 'chart_analyst', name: 'Chart Analyst', desc: 'วิเคราะห์ Multi-TF', icon: <LuActivity size={20} />, gradient: 'from-purple-500/20 to-pink-500/10' },
    { key: 'calendar', name: 'Calendar Watcher', desc: 'ตรวจปฏิทินเศรษฐกิจ', icon: <LuCalendar size={20} />, gradient: 'from-orange-500/20 to-amber-500/10' },
    { key: 'risk_manager', name: 'Risk Manager', desc: 'จัดการความเสี่ยง', icon: <LuShield size={20} />, gradient: 'from-emerald-500/20 to-green-500/10' },
    { key: 'decision_maker', name: 'Decision Maker', desc: 'ตัดสินใจสุดท้าย', icon: <LuBrainCircuit size={20} />, gradient: 'from-rose-500/20 to-red-500/10' },
  ];

  const getDecisionColor = (d: string) => d?.includes('BUY') ? '#10b981' : d?.includes('SELL') ? '#ef4444' : '#f59e0b';
  const getDecisionBg = (d: string) => d?.includes('BUY') ? 'from-emerald-500/20 to-emerald-500/5' : d?.includes('SELL') ? 'from-red-500/20 to-red-500/5' : 'from-amber-500/20 to-amber-500/5';
  const getDecisionIcon = (d: string) => d?.includes('BUY') ? <LuTrendingUp size={28} /> : d?.includes('SELL') ? <LuTrendingDown size={28} /> : <LuMinus size={28} />;

  // Parse multi-TF data from chart reasoning
  const parseTfData = (reasoning: string) => {
    if (!reasoning) return null;
    const match = reasoning.match(/\[Best: (\w+)\]/);
    const bestTf = match?.[1] || '';
    const tfs = ['M5', 'M15', 'H1', 'H4'];
    return tfs.map(tf => {
      const tfMatch = reasoning.match(new RegExp(`${tf}:(\\w+)`));
      return { tf, signal: tfMatch?.[1] || 'HOLD', isBest: tf === bestTf };
    });
  };

  return (
    <div className="flex flex-col gap-5 h-full p-4 md:p-6 w-full relative z-10 font-sans">
      
      {/* Header */}
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
        <div className="flex items-center gap-4">
          <div className="relative">
            <div className="size-12 rounded-2xl bg-gradient-to-br from-blue-500 to-purple-600 flex items-center justify-center shadow-lg shadow-blue-500/25">
              <LuBot className="size-6 text-white" />
            </div>
            <div className={`absolute -bottom-0.5 -right-0.5 size-3.5 rounded-full border-2 border-background ${connected ? 'bg-emerald-400 animate-pulse' : 'bg-amber-400'}`} />
          </div>
          <div>
            <h1 className="text-xl font-bold tracking-tight text-default-900">
              Multi-Agent Trading Hub
            </h1>
            <p className="text-xs text-default-500">
              5 AI Agents + Multi-Timeframe Analysis (M5 / M15 / H1 / H4)
            </p>
          </div>
        </div>

        <div className="flex items-center gap-3">
          {/* Symbol Selector */}
          <div className="relative">
            <button
              onClick={() => setShowSymbolDropdown(!showSymbolDropdown)}
              className="flex items-center gap-2 px-4 py-2.5 rounded-xl border border-default-200 bg-background hover:bg-default-100 transition-all font-bold text-sm min-w-[140px] justify-between"
            >
              <span className="text-primary">{symbol}</span>
              <LuChevronDown className={`size-4 text-default-400 transition-transform ${showSymbolDropdown ? 'rotate-180' : ''}`} />
            </button>
            
            {showSymbolDropdown && (
              <div className="absolute top-full mt-1 right-0 w-full min-w-[160px] bg-background border border-default-200 rounded-xl shadow-2xl z-50 overflow-hidden">
                {trackedSymbols.length > 0 ? trackedSymbols.map(s => (
                  <button
                    key={s}
                    onClick={() => { setSymbol(s); setShowSymbolDropdown(false); }}
                    className={`w-full text-left px-4 py-2.5 text-sm font-semibold hover:bg-primary/10 transition-colors ${s === symbol ? 'bg-primary/10 text-primary' : 'text-default-700'}`}
                  >
                    {s}
                  </button>
                )) : (
                  <div className="px-4 py-3 text-xs text-default-400 text-center">
                    ยังไม่มี Symbol<br />(รอ MT5 เชื่อมต่อ)
                  </div>
                )}
              </div>
            )}
          </div>

          {/* Run Button */}
          <button 
            onClick={runAnalysis} 
            disabled={isAnalyzing || !connected}
            className="flex items-center gap-2 px-5 py-2.5 rounded-xl font-bold text-sm text-white shadow-lg transition-all disabled:opacity-50 disabled:cursor-not-allowed"
            style={{
              background: isAnalyzing ? 'linear-gradient(135deg, #6366f1, #8b5cf6)' : 'linear-gradient(135deg, #3b82f6, #8b5cf6)',
              boxShadow: '0 4px 15px rgba(99, 102, 241, 0.3)'
            }}
          >
            {isAnalyzing ? <LuLoader className="animate-spin size-4" /> : <LuZap className="size-4" />}
            {isAnalyzing ? 'กำลังวิเคราะห์...' : 'วิเคราะห์ AI'}
          </button>
        </div>
      </div>

      {/* Multi-TF Badge Bar */}
      <div className="flex items-center gap-2 px-1">
        <span className="text-[10px] font-bold text-default-400 uppercase tracking-widest mr-1">Timeframe:</span>
        {['M5', 'M15', 'H1', 'H4'].map(tf => {
          const tfData = finalResult ? parseTfData(finalResult.chart?.reasoning)?. find(t => t.tf === tf) : null;
          return (
            <div key={tf} className={`flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-bold transition-all ${
              tfData?.isBest ? 'bg-primary/15 text-primary border border-primary/30 shadow-sm shadow-primary/10' :
              tfData ? 'bg-default-100 text-default-600' : 'bg-default-50 text-default-400 border border-default-100'
            }`}>
              <span>{tf}</span>
              {tfData && (
                <span className={`text-[10px] font-extrabold ${
                  tfData.signal === 'BUY' ? 'text-emerald-500' : tfData.signal === 'SELL' ? 'text-red-500' : 'text-amber-500'
                }`}>
                  {tfData.signal}
                </span>
              )}
              {tfData?.isBest && <LuZap className="size-3 text-primary" />}
            </div>
          );
        })}
        <span className="text-[10px] text-default-400 ml-auto">AI เลือก Timeframe ที่ดีที่สุดให้อัตโนมัติ</span>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-12 gap-5 flex-1 min-h-[550px]">
        
        {/* Left: Agents + Decision */}
        <div className="lg:col-span-4 flex flex-col gap-4">
          
          {/* Agent Cards */}
          <div className="flex flex-col gap-2.5">
            {agentConfig.map(({ key, name, desc, icon, gradient }) => {
              const status = agentStatus[key as keyof AgentStatusMap];
              const isRunning = status === 'running';
              const isDone = status === 'done';
              const isError = status === 'error';
              return (
                <div 
                  key={key} 
                  className={`relative overflow-hidden rounded-xl p-3.5 transition-all duration-500 border ${
                    isRunning ? 'border-primary/40 shadow-md shadow-primary/10 scale-[1.01]' : 
                    isDone ? 'border-emerald-500/20' : 
                    isError ? 'border-red-500/20' : 'border-default-200/60'
                  } bg-background`}
                >
                  <div className={`absolute inset-0 bg-gradient-to-r ${gradient} opacity-${isRunning || isDone ? '100' : '0'} transition-opacity duration-500`} />
                  <div className="relative flex items-center gap-3">
                    <div className={`size-9 rounded-lg flex items-center justify-center transition-all ${
                      isRunning ? 'bg-primary/15 text-primary' : isDone ? 'bg-emerald-500/15 text-emerald-500' : 
                      isError ? 'bg-red-500/15 text-red-500' : 'bg-default-100 text-default-400'
                    }`}>
                      {icon}
                    </div>
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center gap-2">
                        <h4 className="font-bold text-xs tracking-wide">{name}</h4>
                        {isDone && <LuCheck className="text-emerald-500 size-3.5" />}
                        {isError && <LuX className="text-red-500 size-3.5" />}
                        {isRunning && <LuLoader className="animate-spin text-primary size-3.5" />}
                      </div>
                      <p className={`text-[11px] truncate mt-0.5 ${
                        isRunning ? 'text-primary/80 animate-pulse font-mono' : 
                        isDone ? 'text-emerald-600 dark:text-emerald-400' : 
                        isError ? 'text-red-500' : 'text-default-400'
                      }`}>
                        {isRunning || isDone || isError ? (agentLatestLog[key] || desc) : desc}
                      </p>
                    </div>
                  </div>
                  {isRunning && (
                    <div className="absolute bottom-0 left-0 right-0 h-0.5 bg-primary/20 overflow-hidden">
                      <div className="h-full bg-primary animate-[shimmer_1.5s_ease-in-out_infinite]" style={{ width: '40%' }} />
                    </div>
                  )}
                </div>
              );
            })}
          </div>

          {/* Final Decision */}
          {finalResult && (
            <div className={`rounded-2xl p-5 bg-gradient-to-br ${getDecisionBg(finalResult.final_decision)} border border-default-200/50 shadow-lg relative overflow-hidden`}>
              <div className="absolute top-0 right-0 w-24 h-24 opacity-5" style={{ color: getDecisionColor(finalResult.final_decision) }}>
                {getDecisionIcon(finalResult.final_decision)}
              </div>
              <div className="relative">
                <div className="flex items-center gap-2 mb-3">
                  <div className="size-2 rounded-full" style={{ backgroundColor: getDecisionColor(finalResult.final_decision) }} />
                  <span className="text-[10px] font-bold uppercase tracking-widest text-default-500">Final Decision</span>
                </div>
                <div className="flex items-baseline gap-3 mb-3">
                  <span className="text-3xl font-extrabold" style={{ color: getDecisionColor(finalResult.final_decision) }}>
                    {finalResult.final_decision}
                  </span>
                  <span className="text-lg font-bold text-default-500">{finalResult.confidence?.toFixed(0)}%</span>
                </div>
                <p className="text-xs leading-relaxed text-default-600 mb-4">{finalResult.reasoning}</p>

                {/* Summary Grid */}
                <div className="grid grid-cols-3 gap-2">
                  <div className="bg-background/60 rounded-lg p-2 text-center">
                    <p className="text-[9px] text-default-400 font-bold uppercase">Sentiment</p>
                    <p className={`text-xs font-extrabold mt-0.5 ${
                      finalResult.news?.sentiment?.includes('BULL') ? 'text-emerald-500' : 
                      finalResult.news?.sentiment?.includes('BEAR') ? 'text-red-500' : 'text-amber-500'
                    }`}>{finalResult.news?.sentiment || '—'}</p>
                  </div>
                  <div className="bg-background/60 rounded-lg p-2 text-center">
                    <p className="text-[9px] text-default-400 font-bold uppercase">Chart</p>
                    <p className={`text-xs font-extrabold mt-0.5`} style={{ color: getDecisionColor(finalResult.chart?.recommendation) }}>
                      {finalResult.chart?.recommendation || '—'}
                    </p>
                  </div>
                  <div className="bg-background/60 rounded-lg p-2 text-center">
                    <p className="text-[9px] text-default-400 font-bold uppercase">Risk</p>
                    <p className={`text-xs font-extrabold mt-0.5 ${finalResult.risk?.approved ? 'text-emerald-500' : 'text-red-500'}`}>
                      {finalResult.risk?.approved ? '✅ PASS' : '❌ BLOCK'}
                    </p>
                  </div>
                </div>
              </div>
            </div>
          )}
        </div>

        {/* Right: Terminal Logs */}
        <div className="lg:col-span-8 rounded-2xl bg-[#0c0e16] text-gray-300 border border-[#1e2030] shadow-xl flex flex-col overflow-hidden">
          <div className="bg-[#141622] px-4 py-2.5 flex items-center gap-3 border-b border-[#1e2030]">
            <div className="flex gap-1.5">
              <div className="size-2.5 rounded-full bg-red-500/70" />
              <div className="size-2.5 rounded-full bg-amber-500/70" />
              <div className="size-2.5 rounded-full bg-emerald-500/70" />
            </div>
            <LuTerminal className="text-gray-500 size-3.5 ml-2" />
            <span className="font-mono text-[11px] text-gray-500 font-semibold">agent_logs — {symbol} — Multi-TF</span>
            <span className="text-[10px] text-gray-600 ml-auto font-mono">{logs.length} entries</span>
          </div>
          <div className="p-4 overflow-y-auto flex-1 font-mono text-[12px] leading-relaxed space-y-1 max-h-[700px]">
            {logs.length === 0 && (
              <div className="flex items-center justify-center h-full text-gray-600 text-center">
                <div>
                  <LuBot className="size-12 mx-auto mb-3 opacity-20" />
                  <p className="text-sm">กดปุ่ม "วิเคราะห์ AI" เพื่อเริ่มต้น</p>
                  <p className="text-xs text-gray-700 mt-1">AI จะวิเคราะห์ 4 Timeframe พร้อมกัน</p>
                </div>
              </div>
            )}
            {logs.map((log, i) => (
              <div key={i} className="flex gap-2 hover:bg-white/[0.02] px-2 py-0.5 rounded">
                <span className="text-gray-600 shrink-0 select-none">{new Date(log.timestamp).toLocaleTimeString()}</span>
                <span className={`shrink-0 w-[90px] text-right font-semibold ${
                  log.agent === 'orchestrator' ? 'text-blue-400' :
                  log.agent === 'chart_analyst' ? 'text-purple-400' :
                  log.agent === 'news_hunter' ? 'text-cyan-400' :
                  log.agent === 'decision_maker' ? 'text-rose-400' :
                  log.agent === 'risk_manager' ? 'text-emerald-400' :
                  log.agent === 'calendar' ? 'text-orange-400' : 'text-gray-400'
                }`}>
                  [{log.agent?.replace(/_/g, ' ').split(' ').map(w => w[0]?.toUpperCase() + w.slice(1)).join(' ') || 'System'}]
                </span>
                <span className={`flex-1 ${
                  log.status === 'done' ? 'text-emerald-400' : 
                  log.status === 'error' ? 'text-red-400' : 'text-gray-300'
                }`}>
                  {log.message}
                </span>
              </div>
            ))}
            <div ref={logsEndRef} />
          </div>
        </div>
      </div>

      {/* Trade Proposal Modal */}
      {tradeProposal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 backdrop-blur-sm">
          <div className="w-full max-w-md rounded-2xl bg-background border border-default-200 shadow-2xl p-6 animate-in slide-in-from-bottom-4">
            <div className="flex items-center gap-3 mb-5">
              <div className="size-10 rounded-xl bg-amber-500/15 flex items-center justify-center text-amber-500">
                <LuBrainCircuit className="size-5" />
              </div>
              <div>
                <h3 className="text-lg font-bold">รอการยืนยันออเดอร์</h3>
                <p className="text-xs text-default-500">AI Agent แนะนำการเข้าเทรด</p>
              </div>
            </div>

            <div className="rounded-xl bg-default-50 dark:bg-default-100/20 p-4 mb-5 space-y-3">
              {[
                ['Symbol', tradeProposal.symbol, 'text-primary'],
                ['Direction', tradeProposal.direction, tradeProposal.direction === 'BUY' ? 'text-emerald-500' : 'text-red-500'],
                ['Confidence', `${tradeProposal.confidence}%`, ''],
                ['Lot Size', tradeProposal.lot_size || 0.01, ''],
              ].map(([label, value, color]) => (
                <div key={label as string} className="flex justify-between items-center text-sm">
                  <span className="text-default-500">{label}</span>
                  <span className={`font-bold ${color}`}>{value}</span>
                </div>
              ))}
              <div className="pt-2 mt-2 border-t border-default-200/50 text-xs text-default-600">
                <strong>เหตุผล:</strong> {tradeProposal.reasoning}
              </div>
            </div>

            <div className="flex gap-3">
              <button 
                onClick={rejectProposal}
                className="flex-1 flex items-center justify-center gap-2 px-4 py-2.5 rounded-xl bg-default-100 hover:bg-default-200 font-bold text-sm transition-all"
              >
                <LuX size={16} /> ยกเลิก
              </button>
              <button 
                onClick={acceptProposal}
                className={`flex-1 flex items-center justify-center gap-2 px-4 py-2.5 rounded-xl text-white font-bold text-sm transition-all shadow-lg ${
                  tradeProposal.direction === 'BUY' ? 'bg-emerald-500 hover:bg-emerald-600 shadow-emerald-500/25' : 'bg-red-500 hover:bg-red-600 shadow-red-500/25'
                }`}
              >
                <LuCheck size={16} /> อนุมัติออเดอร์
              </button>
            </div>
          </div>
        </div>
      )}

      <style>{`
        @keyframes shimmer {
          0% { transform: translateX(-100%); }
          100% { transform: translateX(350%); }
        }
      `}</style>
    </div>
  );
};

export default OpenClawDashboard;
