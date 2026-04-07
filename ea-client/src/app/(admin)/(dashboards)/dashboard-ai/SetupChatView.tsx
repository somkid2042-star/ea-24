import { useEffect, useRef, useState } from 'react';
import { LuBot, LuServer, LuSend, LuChevronDown, LuX, LuGlobe, LuActivity, LuCalendar, LuShield, LuBrainCircuit, LuCpu, LuCopy, LuCheck } from 'react-icons/lu';
import type { AiLog, AgentStatusMap } from './AgentPanel';
import { CountdownBadge } from './CountdownBadge';

interface SetupChatViewProps {
    job: any;
    closedMap: Record<string, boolean>;
    lastRunMap: Record<string, number>;
    setConfirmDialog: (dialog: any) => void;
    saveJobsToDb: (jobs: any[]) => void;
    autoPilotJobs: any[];
    jobIdx: number;
    handleEditJob: (job: any) => void;
    logsBySymbol: Record<string, AiLog[]>;
    logsM1BySymbol: Record<string, AiLog[]>;
    agentStatusBySymbol: Record<string, AgentStatusMap>;
    agentStatusM1Map: Record<string, AgentStatusMap>;
    finalResultBySymbol: Record<string, any>;
    verboseLogs: {timestamp: number, agent: string, prompt: string, response: string}[];
}

const AGENT_META: Record<string, { label: string; icon: any; color: string }> = {
    news_hunter:    { label: 'News Hunter',     icon: LuGlobe,        color: 'text-cyan-500' },
    chart_analyst:  { label: 'Chart Analyst',    icon: LuActivity,     color: 'text-blue-500' },
    calendar:       { label: 'Calendar',         icon: LuCalendar,     color: 'text-amber-500' },
    calendar_macro: { label: 'Macro Calendar',   icon: LuCalendar,     color: 'text-amber-600' },
    risk_manager:   { label: 'Risk Manager',     icon: LuShield,       color: 'text-emerald-500' },
    decision_maker: { label: 'Decision Maker',   icon: LuBrainCircuit, color: 'text-purple-500' },
    orchestrator:   { label: 'Orchestrator',     icon: LuBot,          color: 'text-indigo-500' },
};

type UnifiedEntry = {
    id: string;
    timestamp: number;
    source: 'server_m1' | 'ai_prompt' | 'ai_response' | 'system_log' | 'system_recovery';
    agent: string;
    status?: string;
    message?: string;
    prompt?: string;
    response?: string;
    raw_calculation_data?: string;
};

const TruncatedBlock = ({ text, maxLines = 6 }: { text: string; maxLines?: number }) => {
    const [expanded, setExpanded] = useState(false);
    const [copied, setCopied] = useState(false);
    const lines = (text || '').split('\n');
    const isTruncated = lines.length > maxLines;

    const handleCopy = (e: React.MouseEvent) => {
        e.stopPropagation();
        navigator.clipboard.writeText(text || '');
        setCopied(true);
        setTimeout(() => setCopied(false), 2000);
    };

    return (
        <div className="relative group">
            <pre className={`text-[12px] font-mono whitespace-pre-wrap leading-relaxed break-words ${!expanded && isTruncated ? `line-clamp-[${maxLines}]` : ''}`}
                 style={!expanded && isTruncated ? { display: '-webkit-box', WebkitLineClamp: maxLines, WebkitBoxOrient: 'vertical', overflow: 'hidden' } : {}}
            >
                {text}
            </pre>
            <div className="flex items-center gap-2 mt-2">
                {isTruncated && (
                    <button
                        onClick={(e) => { e.stopPropagation(); setExpanded(!expanded); }}
                        className="text-[10px] font-bold text-blue-500 hover:text-blue-400 flex items-center gap-1 uppercase tracking-wider"
                    >
                        <LuChevronDown className={`transition-transform ${expanded ? 'rotate-180' : ''}`} size={12} />
                        {expanded ? 'ย่อ' : `แสดงทั้งหมด (${lines.length} บรรทัด)`}
                    </button>
                )}
                <button 
                    onClick={handleCopy}
                    className="text-[10px] font-bold text-gray-400 hover:text-white flex items-center gap-1 ml-auto opacity-0 group-hover:opacity-100 transition-opacity"
                >
                    {copied ? <LuCheck size={10} /> : <LuCopy size={10} />}
                    {copied ? 'คัดลอกแล้ว' : 'คัดลอก'}
                </button>
            </div>
        </div>
    );
};

export const SetupChatView = ({
    job, verboseLogs, logsM1BySymbol, logsBySymbol, lastRunMap, agentStatusBySymbol, agentStatusM1Map, closedMap, finalResultBySymbol
}: SetupChatViewProps) => {
    const [isHovering, setIsHovering] = useState(false);
    const [selectedLog, setSelectedLog] = useState<any>(null);
    const [filter, setFilter] = useState<'all' | 'ai' | 'server'>('all');

    const logsM1 = logsM1BySymbol[job.symbol] || [];
    const logsAI = logsBySymbol[job.symbol] || [];

    const lastRunTime = lastRunMap?.[job.symbol] || null;
    const isAiRunning = Object.values(agentStatusBySymbol?.[job.symbol] || {}).some(s => s === 'running');
    const isM1Running = Object.values(agentStatusM1Map?.[job.symbol] || {}).some(s => s === 'running');
    const finalResult = finalResultBySymbol?.[job.symbol];

    // Build unified timeline
    const entries: UnifiedEntry[] = [];

    // Add AI verbose logs (prompt + response pairs)
    const filteredVerbose = (verboseLogs || []).filter((log: any) => !(job.disabled_agents || []).includes(log.agent));
    filteredVerbose.forEach((log: any, i: number) => {
        const ts = log.timestamp || Date.now();
        entries.push({
            id: `prompt-${i}`,
            timestamp: ts - 1, // prompt comes slightly before response
            source: log.prompt?.includes('[SYSTEM RECOVERY]') ? 'system_recovery' : 'ai_prompt',
            agent: log.agent,
            prompt: log.prompt,
            message: log.prompt,
        });
        entries.push({
            id: `response-${i}`,
            timestamp: ts,
            source: 'ai_response',
            agent: log.agent,
            response: log.response,
            message: log.response,
        });
    });

    // Add M1 Server logs
    logsM1.forEach((log: any, i: number) => {
        entries.push({
            id: `m1-${i}`,
            timestamp: log.timestamp || Date.now(),
            source: 'server_m1',
            agent: log.agent || 'system',
            status: log.status,
            message: log.message || log.raw_calculation_data || '',
            raw_calculation_data: log.raw_calculation_data,
        });
    });

    // Add AI agent_log messages (status updates like "running", "done")
    logsAI.forEach((log: any, i: number) => {
        entries.push({
            id: `ai-log-${i}`,
            timestamp: log.timestamp || Date.now(),
            source: 'system_log',
            agent: log.agent || 'system',
            status: log.status,
            message: log.message || '',
        });
    });

    // Sort chronologically
    entries.sort((a, b) => a.timestamp - b.timestamp);

    // Apply filter
    const filtered = entries.filter(e => {
        if (filter === 'ai') return e.source === 'ai_prompt' || e.source === 'ai_response' || e.source === 'system_log' || e.source === 'system_recovery';
        if (filter === 'server') return e.source === 'server_m1';
        return true;
    });

    const logsEndRef = useRef<HTMLDivElement>(null);

    useEffect(() => {
        if (!isHovering) {
            logsEndRef.current?.scrollIntoView({ behavior: 'smooth' });
        }
    }, [filtered.length, isHovering]);

    const agentMeta = (agent: string) => AGENT_META[agent] || { label: agent, icon: LuCpu, color: 'text-gray-500' };

    const renderEntry = (entry: UnifiedEntry) => {
        const meta = agentMeta(entry.agent);
        const Icon = meta.icon;
        const timeStr = new Date(entry.timestamp).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit', second: '2-digit' });

        // Prompt sent TO AI — left aligned, send-style bubble
        if (entry.source === 'ai_prompt') {
            return (
                <div key={entry.id} className="flex items-start gap-3 w-full animate-in fade-in slide-in-from-left-3 duration-300">
                    <div className={`w-9 h-9 rounded-xl flex items-center justify-center shrink-0 border bg-gradient-to-br from-blue-50 to-blue-100 dark:from-blue-900/30 dark:to-blue-800/20 border-blue-200 dark:border-blue-700/50 shadow-sm mt-0.5`}>
                        <LuSend className="text-blue-500" size={14} />
                    </div>
                    <div className="flex-1 min-w-0 mr-12 md:mr-20">
                        <div className="flex items-center gap-2 mb-1.5">
                            <span className="text-[10px] font-bold text-blue-500 uppercase tracking-wider">PROMPT → {meta.label}</span>
                            <span className="text-[9px] text-gray-500 font-mono">{timeStr}</span>
                        </div>
                        <div 
                            className="bg-white dark:bg-[#12151f] border border-gray-100 dark:border-white/5 rounded-2xl rounded-tl-sm p-4 shadow-sm cursor-pointer hover:border-blue-300 dark:hover:border-blue-700/50 transition-all"
                            onClick={() => setSelectedLog(entry)}
                        >
                            <TruncatedBlock text={entry.prompt || ''} maxLines={8} />
                        </div>
                    </div>
                </div>
            );
        }

        // Response FROM AI — right aligned, receive-style bubble
        if (entry.source === 'ai_response') {
            return (
                <div key={entry.id} className="flex items-start justify-end gap-3 w-full animate-in fade-in slide-in-from-right-3 duration-300">
                    <div className="flex-1 min-w-0 ml-12 md:ml-20">
                        <div className="flex items-center justify-end gap-2 mb-1.5">
                            <span className="text-[9px] text-gray-500 font-mono">{timeStr}</span>
                            <span className={`text-[10px] font-bold uppercase tracking-wider ${meta.color}`}>{meta.label} → ตอบกลับ</span>
                        </div>
                        <div 
                            className="bg-gradient-to-br from-indigo-50/80 to-purple-50/50 dark:from-indigo-900/20 dark:to-purple-900/10 border border-indigo-100 dark:border-indigo-700/30 rounded-2xl rounded-tr-sm p-4 shadow-sm cursor-pointer hover:border-indigo-300 dark:hover:border-indigo-600/50 transition-all"
                            onClick={() => setSelectedLog(entry)}
                        >
                            <TruncatedBlock text={entry.response || ''} maxLines={8} />
                        </div>
                    </div>
                    <div className={`w-9 h-9 rounded-xl flex items-center justify-center shrink-0 bg-gradient-to-br from-indigo-500 to-purple-600 text-white shadow-md mt-0.5`}>
                        <Icon size={16} />
                    </div>
                </div>
            );
        }

        // System Recovery (loaded from DB) — centered info bubble
        if (entry.source === 'system_recovery') {
            return (
                <div key={entry.id} className="flex items-start gap-3 w-full animate-in fade-in duration-200">
                    <div className="w-9 h-9 rounded-xl flex items-center justify-center shrink-0 border bg-amber-50 dark:bg-amber-900/20 border-amber-200 dark:border-amber-700/40 shadow-sm mt-0.5">
                        <LuServer className="text-amber-500" size={14} />
                    </div>
                    <div className="flex-1 min-w-0 mr-12">
                        <div className="flex items-center gap-2 mb-1.5">
                            <span className="text-[10px] font-bold text-amber-500 uppercase tracking-wider">ข้อมูลโหลดจาก DB</span>
                            <span className="text-[9px] text-gray-500 font-mono">{timeStr}</span>
                        </div>
                        <div 
                            className="bg-amber-50/50 dark:bg-amber-900/10 border border-amber-100 dark:border-amber-800/30 rounded-2xl rounded-tl-sm p-3 shadow-sm cursor-pointer hover:border-amber-300 transition-all"
                            onClick={() => setSelectedLog(entry)}
                        >
                            <p className="text-[12px] text-amber-700 dark:text-amber-400 font-medium leading-relaxed line-clamp-2">{entry.prompt || ''}</p>
                        </div>
                    </div>
                </div>
            );
        }

        // Server M1 log
        if (entry.source === 'server_m1') {
            const isRunning = entry.status === 'running';
            const isDone = entry.status === 'done';
            const isError = entry.status === 'error';

            return (
                <div key={entry.id} className={`flex items-start gap-3 w-full animate-in fade-in duration-200 ${isRunning ? '' : 'justify-end'}`}>
                    {isRunning && (
                        <div className="w-9 h-9 rounded-xl flex items-center justify-center shrink-0 border bg-gray-50 dark:bg-white/5 border-gray-200 dark:border-white/10 shadow-sm mt-0.5">
                            <LuCpu className="text-gray-400 animate-pulse" size={14} />
                        </div>
                    )}
                    <div className={`flex-1 min-w-0 ${isRunning ? 'mr-12 md:mr-20' : 'ml-12 md:ml-20'}`}>
                        <div className={`flex items-center gap-2 mb-1.5 ${!isRunning ? 'justify-end' : ''}`}>
                            {isRunning && <span className="text-[10px] font-bold text-gray-400 uppercase tracking-wider">M1 → {meta.label}</span>}
                            <span className="text-[9px] text-gray-500 font-mono">{timeStr}</span>
                            {!isRunning && <span className={`text-[10px] font-bold uppercase tracking-wider ${isError ? 'text-red-400' : 'text-emerald-500'}`}>{meta.label} → ผลลัพธ์</span>}
                        </div>
                        <div 
                            className={`rounded-2xl p-3 shadow-sm cursor-pointer transition-all border ${
                                isRunning 
                                    ? 'bg-white dark:bg-[#12151f] border-gray-100 dark:border-white/5 rounded-tl-sm hover:border-gray-300' 
                                    : isDone 
                                        ? 'bg-emerald-50/50 dark:bg-emerald-900/10 border-emerald-100 dark:border-emerald-800/30 rounded-tr-sm hover:border-emerald-300'
                                        : 'bg-red-50/50 dark:bg-red-900/10 border-red-100 dark:border-red-800/30 rounded-tr-sm hover:border-red-300'
                            }`}
                            onClick={() => setSelectedLog(entry)}
                        >
                            <p className={`text-[12px] font-medium leading-relaxed break-words whitespace-pre-wrap ${
                                isRunning ? 'text-gray-600 dark:text-gray-400' : isDone ? 'text-emerald-700 dark:text-emerald-400' : 'text-red-600 dark:text-red-400'
                            }`}>
                                {entry.message || ''}
                            </p>
                        </div>
                    </div>
                    {!isRunning && (
                        <div className={`w-9 h-9 rounded-xl flex items-center justify-center shrink-0 shadow-sm mt-0.5 ${
                            isError ? 'bg-red-100 dark:bg-red-900/30 text-red-500 border border-red-200 dark:border-red-700/40' 
                                    : 'bg-emerald-100 dark:bg-emerald-900/30 text-emerald-500 border border-emerald-200 dark:border-emerald-700/40'
                        }`}>
                            <LuServer size={14} />
                        </div>
                    )}
                </div>
            );
        }

        // System log (agent_log status updates)
        if (entry.source === 'system_log') {
            const isRunning = entry.status === 'running';
            const isError = entry.status === 'error';
            
            return (
                <div key={entry.id} className="flex items-center gap-3 w-full animate-in fade-in duration-200">
                    <div className={`w-7 h-7 rounded-lg flex items-center justify-center shrink-0 ${
                        isRunning ? 'bg-blue-50 dark:bg-blue-900/20 text-blue-500' 
                        : isError ? 'bg-red-50 dark:bg-red-900/20 text-red-500'
                        : 'bg-emerald-50 dark:bg-emerald-900/20 text-emerald-500'
                    }`}>
                        <Icon size={12} />
                    </div>
                    <div className="flex-1 flex items-center gap-2 min-w-0 py-1">
                        <span className={`text-[10px] font-bold uppercase tracking-wider ${meta.color}`}>
                            {meta.label}
                        </span>
                        <span className={`text-[11px] font-medium truncate ${
                            isRunning ? 'text-blue-600 dark:text-blue-400' : isError ? 'text-red-500' : 'text-gray-600 dark:text-gray-400'
                        }`}>
                            {(entry.message || '').replace(/[✅❌⚠️📊🏁💡🔴🟢🚨📅🔍🛡️]/g, '').trim()}
                        </span>
                        <span className="text-[9px] text-gray-400 font-mono ml-auto shrink-0">{timeStr}</span>
                    </div>
                    {isRunning && <div className="w-1.5 h-1.5 rounded-full bg-blue-500 animate-pulse shrink-0" />}
                </div>
            );
        }

        return null;
    };

    return (
        <div className="flex flex-col h-full bg-[#fafafa] dark:bg-[#090b14] relative">
            {/* Top Header */}
            <div className="flex items-center justify-between px-5 py-3.5 bg-white dark:bg-[#0b0e17] border-b border-gray-100 dark:border-white/5 z-10">
                <div className="flex items-center gap-3">
                    <div className="px-3 h-9 rounded-xl flex items-center justify-center font-bold text-sm shrink-0 bg-gradient-to-br from-blue-500 to-blue-600 text-white shadow-sm">
                        {job.symbol}
                    </div>
                    <div>
                        <h2 className="text-[14px] font-bold text-default-900 dark:text-white leading-tight">
                            {job.symbol}
                        </h2>
                        <p className="text-[11px] text-gray-500 font-medium">
                            Analysis Interval: {job.interval} min • Real-Time Activity
                        </p>
                    </div>
                </div>
                <div className="flex items-center gap-2">
                    {/* Status badges */}
                    <div className="flex items-center gap-1.5">
                        <CountdownBadge interval={1} lastRunTime={null} isRunning={isM1Running} enabled={job.enabled !== false} marketClosed={closedMap[job.symbol]} />
                        <CountdownBadge interval={job.interval} lastRunTime={lastRunTime} isRunning={isAiRunning} enabled={job.enabled !== false} marketClosed={closedMap[job.symbol]} />
                    </div>
                    {/* Final decision badge */}
                    {finalResult?.final_decision && (
                        <span className={`px-2.5 py-1 rounded-lg text-[10px] font-black uppercase tracking-wider border ${
                            finalResult.final_decision === 'BUY' ? 'bg-emerald-50 dark:bg-emerald-900/20 text-emerald-600 dark:text-emerald-400 border-emerald-200 dark:border-emerald-700/40' :
                            finalResult.final_decision === 'SELL' ? 'bg-red-50 dark:bg-red-900/20 text-red-600 dark:text-red-400 border-red-200 dark:border-red-700/40' :
                            'bg-amber-50 dark:bg-amber-900/20 text-amber-600 dark:text-amber-400 border-amber-200 dark:border-amber-700/40'
                        }`}>
                            AI: {finalResult.final_decision} {finalResult.confidence ? `${finalResult.confidence}%` : ''}
                        </span>
                    )}
                </div>
            </div>

            {/* Filter tabs */}
            <div className="flex items-center gap-1 px-4 py-2 border-b border-gray-100 dark:border-white/5 bg-white/50 dark:bg-[#0b0e17]/50">
                {[
                    { key: 'all' as const, label: 'ทั้งหมด', count: entries.length },
                    { key: 'ai' as const, label: 'AI Gemini', count: entries.filter(e => e.source === 'ai_prompt' || e.source === 'ai_response' || e.source === 'system_log').length },
                    { key: 'server' as const, label: 'Server M1', count: entries.filter(e => e.source === 'server_m1').length },
                ].map(tab => (
                    <button 
                        key={tab.key}
                        onClick={() => setFilter(tab.key)}
                        className={`px-3 py-1.5 rounded-lg text-[11px] font-semibold transition-all ${
                            filter === tab.key 
                                ? 'bg-blue-50 dark:bg-blue-900/30 text-blue-600 dark:text-blue-400 shadow-sm' 
                                : 'text-gray-500 hover:text-gray-700 dark:hover:text-gray-300 hover:bg-gray-100 dark:hover:bg-white/5'
                        }`}
                    >
                        {tab.label}
                        <span className="text-[9px] ml-1.5 font-mono opacity-60">{tab.count}</span>
                    </button>
                ))}
                <div className="ml-auto flex items-center gap-2">
                    {(isAiRunning || isM1Running) && (
                        <span className="flex items-center gap-1.5 text-[10px] font-bold text-blue-500 animate-pulse">
                            <span className="w-1.5 h-1.5 rounded-full bg-blue-500" />
                            LIVE
                        </span>
                    )}
                </div>
            </div>
            
            {/* Main Timeline */}
            <div 
                className="flex-1 overflow-y-auto px-4 md:px-5 py-4 space-y-4 custom-scrollbar"
                onMouseEnter={() => setIsHovering(true)}
                onMouseLeave={() => setIsHovering(false)}
            >
                {filtered.length > 0 ? (
                    filtered.map(entry => renderEntry(entry))
                ) : (
                    <div className="flex flex-col items-center justify-center h-full text-center gap-3 opacity-60">
                        <div className="w-14 h-14 rounded-2xl bg-gray-100 dark:bg-white/5 flex items-center justify-center">
                            <LuBot size={24} className="text-gray-400" />
                        </div>
                        <div>
                            <p className="text-sm font-semibold text-gray-500">ยังไม่มีข้อมูลกิจกรรม</p>
                            <p className="text-xs text-gray-400 mt-1">รอจนกว่า AI หรือ Server จะเริ่มวิเคราะห์รอบถัดไป</p>
                        </div>
                    </div>
                )}
                <div ref={logsEndRef} />
            </div>

            {/* Full View Modal */}
            {selectedLog && (
                <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/70 backdrop-blur-sm p-4 md:p-8">
                    <div className="bg-white dark:bg-[#0B101E] border border-gray-200 dark:border-white/10 rounded-2xl shadow-2xl w-full max-w-4xl max-h-[90vh] flex flex-col animate-in fade-in zoom-in-95 duration-200">
                        <div className="flex items-center justify-between p-4 border-b border-gray-100 dark:border-white/5 shrink-0">
                            <div className="flex items-center gap-3">
                                <div className={`w-8 h-8 rounded-lg flex items-center justify-center ${
                                    selectedLog.source === 'ai_prompt' ? 'bg-blue-100 dark:bg-blue-900/30 text-blue-500' :
                                    selectedLog.source === 'ai_response' ? 'bg-indigo-100 dark:bg-indigo-900/30 text-indigo-500' :
                                    'bg-emerald-100 dark:bg-emerald-900/30 text-emerald-500'
                                }`}>
                                    {selectedLog.source === 'ai_prompt' ? <LuSend size={14} /> : 
                                     selectedLog.source === 'ai_response' ? <LuBot size={14} /> : 
                                     <LuServer size={14} />}
                                </div>
                                <div>
                                    <h3 className="text-sm font-bold text-gray-800 dark:text-gray-100">
                                        {selectedLog.source === 'ai_prompt' ? 'Prompt ที่ส่งให้ AI' : 
                                         selectedLog.source === 'ai_response' ? 'AI ตอบกลับ' : 
                                         'ข้อมูลดิบ'}
                                    </h3>
                                    <p className="text-[10px] text-gray-500">
                                        {agentMeta(selectedLog.agent).label} • {new Date(selectedLog.timestamp).toLocaleString()}
                                    </p>
                                </div>
                            </div>
                            <button 
                                onClick={() => setSelectedLog(null)}
                                className="w-8 h-8 flex items-center justify-center bg-gray-100 hover:bg-gray-200 dark:bg-white/5 dark:hover:bg-white/10 text-gray-500 rounded-lg transition-colors"
                            >
                                <LuX size={16} />
                            </button>
                        </div>
                        <div className="flex-1 overflow-y-auto p-5 custom-scrollbar bg-gray-50/50 dark:bg-[#06080F]">
                            <pre className="text-[12px] font-mono text-gray-700 dark:text-emerald-400 whitespace-pre-wrap leading-relaxed break-words">
                                {selectedLog.source === 'ai_prompt' ? selectedLog.prompt :
                                 selectedLog.source === 'ai_response' ? selectedLog.response :
                                 selectedLog.message || JSON.stringify(selectedLog, null, 2)}
                            </pre>
                        </div>
                    </div>
                </div>
            )}
        </div>
    );
};
