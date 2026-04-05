import { useState, useEffect, useRef } from 'react';
import { LuBot, LuTerminal, LuPlay, LuCheck, LuX, LuLoader, LuShield, LuCalendar, LuGlobe, LuActivity, LuBrainCircuit } from 'react-icons/lu';
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
  const [timeframe, setTimeframe] = useState("M15");
  const [isAnalyzing, setIsAnalyzing] = useState(false);
  const [agentStatus, setAgentStatus] = useState<AgentStatusMap>({
    news_hunter: 'idle',
    chart_analyst: 'idle',
    calendar: 'idle',
    risk_manager: 'idle',
    decision_maker: 'idle',
    orchestrator: 'idle',
  });
  const [agentLatestLog, setAgentLatestLog] = useState<Record<string, string>>({});
  const [finalResult, setFinalResult] = useState<any>(null);
  const [tradeProposal, setTradeProposal] = useState<any>(null);
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
      setLogs([{ timestamp: Date.now(), agent: 'System', status: 'done', message: 'เชื่อมต่อกับ Trading Server สำเร็จ' }]);
    };
    
    ws.onclose = () => setConnected(false);

    ws.onmessage = (evt) => {
      try {
        const data = JSON.parse(evt.data);
        
        if (data.type === 'agent_log') {
          setLogs(prev => [...prev, { 
            timestamp: Date.now(), 
            agent: data.agent, 
            status: data.status, 
            message: data.message 
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
             news_hunter: 'idle',
             chart_analyst: 'idle',
             calendar: 'idle',
             risk_manager: 'idle',
             decision_maker: 'idle',
             orchestrator: 'running',
           });
           setAgentLatestLog({});
           setFinalResult(null);
           setTradeProposal(null);
        }

        if (data.type === 'ai_trade_proposal') {
           setTradeProposal(data);
        }

      } catch (e) {}
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
      timeframe: timeframe,
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

  const getAgentColor = (_key: string, status: AgentStatus) => {
     if (status === 'running') return 'text-primary animate-pulse';
     if (status === 'error') return 'text-danger';
     if (status === 'done') return 'text-success';
     return 'text-default-400';
  };

  const getAgentIcon = (key: string) => {
      switch (key) {
         case 'news_hunter': return <LuGlobe size={24} />;
         case 'chart_analyst': return <LuActivity size={24} />;
         case 'calendar': return <LuCalendar size={24} />;
         case 'risk_manager': return <LuShield size={24} />;
         case 'decision_maker': return <LuBrainCircuit size={24} />;
         default: return <LuBot size={24} />;
      }
  };

  const agentNames: Record<string, string> = {
      news_hunter: "News Hunter",
      chart_analyst: "Chart Analyst",
      calendar: "Calendar Watcher",
      risk_manager: "Risk Manager",
      decision_maker: "Decision Maker"
  };

  const getDecisionColor = (decision: string) => {
      if (decision.includes('BUY')) return 'text-success';
      if (decision.includes('SELL')) return 'text-danger';
      if (decision.includes('HOLD')) return 'text-warning';
      return 'text-default-500';
  };

  return (
    <div className="flex flex-col gap-6 h-full p-4 md:p-6 w-full relative z-10 font-sans">
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
        <div>
          <h1 className="text-2xl font-bold tracking-tight text-default-900 flex items-center gap-3">
            <LuBot className="size-7 text-primary" />
            🤖 Multi-Agent Trading Hub
          </h1>
          <p className="text-default-500 mt-1">
            ระดมสมอง 5 AI Agents เพื่อค้นข่าว ดูกราฟ ตรวจปฏิทิน และจัดการความเสี่ยงก่อนเทรด
          </p>
        </div>
        <div className="flex items-center gap-4 bg-card px-4 py-2 rounded-xl border border-default-100 shadow-sm">
          <div className="flex flex-col">
            <span className="text-xs text-default-500 font-semibold uppercase tracking-wider">ws://server</span>
            <span className={`text-sm font-bold flex items-center gap-2 ${connected ? 'text-success' : 'text-warning'}`}>
              <span className={`inline-block size-2 rounded-full ${connected ? 'bg-success animate-pulse' : 'bg-warning'}`} />
              {connected ? 'เชื่อมต่อแล้ว' : 'กำลังรอ...'}
            </span>
          </div>
        </div>
      </div>

      {/* Control Panel */}
      <div className="card p-4 flex flex-wrap gap-4 items-center bg-default-50 dark:bg-default-100/50">
         <div className="flex items-center gap-2">
            <label className="text-sm font-semibold">Symbol:</label>
            <input type="text" value={symbol} onChange={e => setSymbol(e.target.value.toUpperCase())} className="input input-sm w-24 uppercase" />
         </div>
         <div className="flex items-center gap-2">
            <label className="text-sm font-semibold">Timeframe:</label>
            <select value={timeframe} onChange={e => setTimeframe(e.target.value)} className="input input-sm w-24">
               <option value="M5">M5</option>
               <option value="M15">M15</option>
               <option value="H1">H1</option>
               <option value="H4">H4</option>
               <option value="D1">D1</option>
            </select>
         </div>
         <button 
           onClick={runAnalysis} 
           disabled={isAnalyzing || !connected}
           className="btn btn-primary ml-auto flex items-center gap-2 font-bold"
         >
           {isAnalyzing ? <LuLoader className="animate-spin" /> : <LuPlay />}
           เริ่มรัน 5 Agents ทันที
         </button>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6 flex-1 min-h-[600px]">
        
        {/* Left Col: Agents Status & Final Result */}
        <div className="lg:col-span-1 flex flex-col gap-6">
           {/* Agents Grid */}
           <div className="card !rounded-2xl p-5 border-none shadow-xl bg-gradient-to-br from-card to-default-100">
              <h3 className="text-lg font-bold mb-4 flex items-center gap-2"><LuBot className="text-primary" /> Active Agents</h3>
              <div className="flex flex-col gap-3">
                 {Object.keys(agentNames).map(key => {
                    const status = agentStatus[key as keyof AgentStatusMap];
                    const isRunning = status === 'running';
                    const isError = status === 'error';
                    const isDone = status === 'done';
                    return (
                    <div key={key} className={`flex items-center gap-4 p-4 rounded-xl transition-all duration-500 bg-background border shadow-sm ${isRunning ? 'border-primary/50 shadow-primary/10 shadow-lg scale-[1.02] translate-x-1' : isDone ? 'border-success/30' : 'border-default-200/50'}`}>
                       <div className={`p-3 rounded-xl bg-default-100 transition-colors duration-300 ${getAgentColor(key, status)} ${isRunning ? 'bg-primary/10' : ''}`}>
                          {getAgentIcon(key)}
                       </div>
                       <div className="flex-1 min-w-0">
                          <h4 className="font-bold text-sm tracking-wide">{agentNames[key]}</h4>
                          {isRunning ? (
                             <div className="mt-1">
                                <p className="text-xs text-primary font-mono truncate pr-2 animate-pulse">
                                   &gt; {agentLatestLog[key] || "กำลังทำงาน..."}
                                </p>
                                <div className="h-1 w-full bg-primary/20 rounded-full overflow-hidden mt-2 relative">
                                   <div className="absolute top-0 left-0 h-full bg-primary w-full animate-[pulse_1s_ease-in-out_infinite]" style={{ transformOrigin: "left" }}></div>
                                </div>
                             </div>
                          ) : isDone ? (
                             <p className="text-xs text-success font-medium mt-1 truncate">
                                ✅ {agentLatestLog[key] || "เสร็จสมบูรณ์"}
                             </p>
                          ) : isError ? (
                             <p className="text-xs text-danger font-medium mt-1 truncate">
                                ❌ {agentLatestLog[key] || "เกิดข้อผิดพลาด"}
                             </p>
                          ) : (
                             <p className="text-xs text-default-400 mt-1 capitalize tracking-wide">{status}</p>
                          )}
                       </div>
                       <div>
                          {isRunning && <LuLoader className="animate-spin text-primary size-5" />}
                          {isDone && <LuCheck className="text-success size-5" />}
                          {isError && <LuX className="text-danger size-5" />}
                       </div>
                    </div>
                 )})}
              </div>
           </div>

           {/* Final Decision */}
           {finalResult && (
              <div className="card !rounded-2xl p-6 border border-primary/20 bg-primary/5 shadow-xl relative overflow-hidden">
                 <div className="absolute top-0 left-0 w-1 h-full bg-primary" />
                 <h3 className="text-sm font-bold text-default-500 uppercase tracking-wider mb-2">Final Decision</h3>
                 <div className="flex items-baseline gap-3 mb-4">
                    <span className={`text-4xl font-extrabold ${getDecisionColor(finalResult.final_decision)}`}>
                       {finalResult.final_decision}
                    </span>
                    <span className="text-lg font-bold opacity-80">
                       ({finalResult.confidence}%)
                    </span>
                 </div>
                 <p className="text-sm leading-relaxed mb-4">{finalResult.reasoning}</p>
                 
                 <div className="space-y-2 text-xs text-default-600 bg-background/50 p-3 rounded-lg">
                    <div className="flex justify-between">
                       <span>News Sentiment:</span>
                       <span className={`font-bold ${getDecisionColor(finalResult.news.sentiment)}`}>{finalResult.news.sentiment}</span>
                    </div>
                    <div className="flex justify-between">
                       <span>Chart Recommendation:</span>
                       <span className={`font-bold ${getDecisionColor(finalResult.chart.recommendation)}`}>{finalResult.chart.recommendation}</span>
                    </div>
                    <div className="flex justify-between">
                       <span>Risk Status:</span>
                       <span className={finalResult.risk.approved ? 'text-success' : 'text-danger'}>{finalResult.risk.approved ? 'Approved' : 'Blocked'}</span>
                    </div>
                 </div>
              </div>
           )}
        </div>

        {/* Right Col: Terminal Logs */}
        <div className="lg:col-span-2 card bg-[#0f111a] text-gray-300 !rounded-2xl border-none shadow-xl flex flex-col overflow-hidden">
          <div className="bg-[#1a1d27] px-4 py-3 flex items-center gap-3 border-b border-gray-800">
            <LuTerminal className="text-gray-400" />
            <span className="font-mono text-xs text-gray-400 uppercase font-semibold">System Logs</span>
          </div>
          <div className="p-4 overflow-y-auto flex-1 font-mono text-sm leading-relaxed space-y-2 max-h-[700px]">
            {logs.map((log, i) => (
              <div key={i} className="flex gap-3">
                <span className="text-gray-500 shrink-0">[{new Date(log.timestamp).toLocaleTimeString()}]</span>
                <span className="text-primary/70 shrink-0 capitalize w-24">[{log.agent.replace('_', ' ')}]</span>
                <span className={`${log.status === 'done' ? 'text-green-400 font-semibold' : log.status === 'error' ? 'text-red-400' : 'text-gray-300'}`}>
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
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-background/80 backdrop-blur-sm animate-in fade-in">
          <div className="card w-full max-w-md p-6 bg-card border border-warning/30 shadow-2xl shadow-warning/10 animate-in slide-in-from-bottom-4">
            <div className="flex items-center gap-3 mb-4 text-warning">
              <LuBrainCircuit className="size-8" />
              <h3 className="text-xl font-bold">รอการยืนยันออเดอร์ (AI)</h3>
            </div>
            
            <p className="text-sm text-default-500 mb-6">
              AI Agent แบบ Auto-Pilot ได้วิเคราะห์และพบสัญญาณการเข้าประเมินผลสูง ควรรีบตัดสินใจ:
            </p>

            <div className="bg-default-100 dark:bg-default-200/10 rounded-xl p-4 mb-6 space-y-3">
              <div className="flex justify-between items-center text-sm font-bold">
                <span>Symbol:</span>
                <span className="text-primary">{tradeProposal.symbol}</span>
              </div>
              <div className="flex justify-between items-center text-sm font-bold">
                <span>Direction:</span>
                <span className={tradeProposal.direction === 'BUY' ? 'text-success' : 'text-danger'}>{tradeProposal.direction}</span>
              </div>
              <div className="flex justify-between items-center text-sm font-bold">
                <span>Confidence:</span>
                <span>{tradeProposal.confidence}%</span>
              </div>
              <div className="flex justify-between items-center text-sm font-bold">
                <span>Lot Size:</span>
                <span>{tradeProposal.lot_size || 0.01}</span>
              </div>
              <div className="pt-2 mt-2 border-t border-default-200 dark:border-default-200/10 text-xs text-default-600">
                <strong>Reasoning:</strong> {tradeProposal.reasoning}
              </div>
            </div>

            <div className="flex gap-3">
              <button 
                onClick={rejectProposal}
                className="btn flex-1 bg-default-200 dark:bg-default-300 text-default-900 border-none font-bold outline-none"
              >
                <LuX className="size-4" /> ยกเลิก
              </button>
              <button 
                onClick={acceptProposal}
                className={`btn flex-1 text-white border-none font-bold outline-none shadow-md ${tradeProposal.direction === 'BUY' ? 'bg-success hover:bg-success/80 shadow-success/30' : 'bg-danger hover:bg-danger/80 shadow-danger/30'}`}
              >
                <LuCheck className="size-4" /> อนุมัติการเปิดออเดอร์
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default OpenClawDashboard;
