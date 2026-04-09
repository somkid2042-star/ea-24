import { useState, useRef, useEffect } from 'react';
import { LuChevronDown, LuX, LuServer, LuBrainCircuit, LuCheck, LuSparkles, LuLoader, LuSettings, LuTerminal, LuBot, LuEye, LuActivity } from 'react-icons/lu';
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

const stripEmojis = (msg: string) => {
    if (!msg) return '';
    return msg.replace(/[\p{Extended_Pictographic}\u{FE0F}\u{200D}]/gu, '').replace(/[\[\]]/g, '').replace(/\s{2,}/g, ' ').trim();
};

// Parse logs to extract stage results
const parseStageData = (logs: AiLog[]) => {
    const stages = {
        server: { lines: [] as string[], result: '', strategy: '', score: '', tf: '', status: 'idle' as string },
        gemma:  { lines: [] as string[], result: '', verdict: '', reason: '', status: 'idle' as string },
        gemini: { lines: [] as string[], result: '', decision: '', confidence: '', reason: '', status: 'idle' as string },
    };

    logs.forEach(log => {
        const msg = stripEmojis(log.message || '');
        const agent = log.agent || '';
        const status = log.status || '';

        if (agent === 'pipeline_v8' || agent.includes('pipeline')) {
            stages.server.lines.push(msg);
            stages.server.status = status;
            
            // Parse strategy selection
            const stratMatch = msg.match(/Best Signal:\s*(\w+)/i) || msg.match(/เลือก.*?:\s*(\w+)/i);
            if (stratMatch) stages.server.strategy = stratMatch[1];
            
            const scoreMatch = msg.match(/Score[:\s]+(\d+\.?\d*)/i) || msg.match(/WScore[:\s]+\w+:(\d+\.?\d*)/i);
            if (scoreMatch) stages.server.score = scoreMatch[1];
            
            const tfMatch = msg.match(/(M5|M15|M30|H1|H4)/);
            if (tfMatch) stages.server.tf = tfMatch[1];

            // Parse signal details
            if (msg.includes('BUY') || msg.includes('SELL')) {
                const dirMatch = msg.match(/(BUY|SELL)/);
                if (dirMatch) stages.server.result = dirMatch[1];
            }
            if (msg.includes('ไม่มีสัญญาณ') || msg.includes('No signal') || (msg.includes('BUY:0') && msg.includes('SELL:0'))) {
                stages.server.result = 'NO_SIGNAL';
            }
        }

        if (agent === 'gemma_filter' || agent === 'gemma_filter_v8' || agent.includes('gemma')) {
            stages.gemma.lines.push(msg);
            stages.gemma.status = status;
            
            if (msg.toLowerCase().includes('approve') || msg.includes('เห็นด้วย') || msg.includes('ผ่าน')) {
                stages.gemma.verdict = 'APPROVED';
            }
            if (msg.toLowerCase().includes('reject') || msg.includes('ไม่เห็นด้วย') || msg.includes('ไม่ผ่าน')) {
                stages.gemma.verdict = 'REJECTED';
            }
            stages.gemma.reason = msg;
        }

        if (agent === 'gemini_confirm' || agent === 'gemini_confirm_v8' || agent.includes('gemini') || agent === 'decision_maker') {
            stages.gemini.lines.push(msg);
            stages.gemini.status = status;
            
            const decMatch = msg.match(/(BUY|SELL|HOLD)/);
            if (decMatch) stages.gemini.decision = decMatch[1];
            
            const confMatch = msg.match(/(\d+)%/) || msg.match(/confidence[:\s]+(\d+)/i);
            if (confMatch) stages.gemini.confidence = confMatch[1];
            
            stages.gemini.reason = msg;
        }
    });

    return stages;
};

// Animated border CSS
const glowKeyframes = `
@keyframes borderGlow {
    0% { border-color: rgba(34,197,94,0.2); box-shadow: 0 0 5px rgba(34,197,94,0.1); }
    50% { border-color: rgba(34,197,94,0.8); box-shadow: 0 0 20px rgba(34,197,94,0.3); }
    100% { border-color: rgba(34,197,94,0.2); box-shadow: 0 0 5px rgba(34,197,94,0.1); }
}
@keyframes flowDash {
    0% { stroke-dashoffset: 20; }
    100% { stroke-dashoffset: 0; }
}
`;


export const SetupChatView = ({
    job, verboseLogs, logsM1BySymbol, logsBySymbol, lastRunMap, agentStatusBySymbol, agentStatusM1Map, closedMap, finalResultBySymbol, handleEditJob
}: SetupChatViewProps) => {
    const [selectedLog, setSelectedLog] = useState<any>(null);
    const [expandedCard, setExpandedCard] = useState<string | null>(null);
    const [activeTab, setActiveTab] = useState<'timeline' | 'verbose'>('timeline');
    const logsEndRef = useRef<HTMLDivElement>(null);
    const [autoScroll, setAutoScroll] = useState(true);

    const logsAI = logsBySymbol[job.symbol] || [];
    const lastRunTime = lastRunMap?.[job.symbol] || null;
    const isRunning = Object.values(agentStatusBySymbol?.[job.symbol] || {}).some(s => s === 'running');
    const finalResult = finalResultBySymbol?.[job.symbol];

    // Auto-scroll logs
    useEffect(() => {
        if (autoScroll && logsEndRef.current) {
            logsEndRef.current.scrollIntoView({ behavior: 'smooth' });
        }
    }, [logsAI, autoScroll]);

    // Parse stage data from logs
    const stages = parseStageData(logsAI);
    const agentStatuses = agentStatusBySymbol?.[job.symbol] || {} as any;

    // Override with real-time agent statuses
    if (agentStatuses.pipeline_v8) stages.server.status = agentStatuses.pipeline_v8;
    if (agentStatuses.gemma_filter) stages.gemma.status = agentStatuses.gemma_filter;
    if (agentStatuses.gemini_confirm) stages.gemini.status = agentStatuses.gemini_confirm;

    // Determine agent info for log rendering
    const getAgentInfo = (agent: string) => {
        if (agent === 'pipeline_v8' || agent?.includes('pipeline')) return { icon: LuServer, color: 'blue', label: 'Server Scan' };
        if (agent === 'gemma_filter' || agent === 'gemma_filter_v8' || agent?.includes('gemma')) return { icon: LuSparkles, color: 'purple', label: 'Gemma 4' };
        if (agent === 'gemini_confirm' || agent === 'gemini_confirm_v8' || agent?.includes('gemini') || agent === 'decision_maker') return { icon: LuBrainCircuit, color: 'amber', label: 'Gemini' };
        return { icon: LuTerminal, color: 'gray', label: agent?.replace(/_/g, ' ') || 'System' };
    };

    const agentColorClasses: Record<string, { bg: string; text: string }> = {
        blue:   { bg: 'bg-blue-500/10',   text: 'text-blue-500' },
        purple: { bg: 'bg-purple-500/10', text: 'text-purple-500' },
        amber:  { bg: 'bg-amber-500/10',  text: 'text-amber-500' },
        gray:   { bg: 'bg-gray-100 dark:bg-white/5', text: 'text-gray-400' },
    };

    const cardConfigs = [
        {
            key: 'server',
            label: 'Server Scan',
            desc: '10 กลยุทธ์ × 5 TF',
            icon: LuServer,
            color: 'blue',
            status: stages.server.status,
            lines: stages.server.lines,
            summary: () => {
                if (stages.server.result === 'NO_SIGNAL') return { text: 'ไม่พบสัญญาณ', color: 'text-gray-500' };
                if (stages.server.result === 'BUY') return { text: `BUY ${stages.server.strategy || ''} ${stages.server.tf || ''}`.trim(), color: 'text-emerald-500' };
                if (stages.server.result === 'SELL') return { text: `SELL ${stages.server.strategy || ''} ${stages.server.tf || ''}`.trim(), color: 'text-red-500' };
                if (stages.server.status === 'running') return { text: 'กำลังสแกน...', color: 'text-blue-500' };
                return { text: 'รอสแกน', color: 'text-gray-500' };
            }
        },
        {
            key: 'gemma',
            label: 'Gemma 4',
            desc: 'ตรวจสอบ + ประวัติ',
            icon: LuSparkles,
            color: 'purple',
            status: stages.gemma.status,
            lines: stages.gemma.lines,
            summary: () => {
                if (stages.gemma.verdict === 'APPROVED') return { text: 'ผ่าน -- เห็นด้วย', color: 'text-emerald-500' };
                if (stages.gemma.verdict === 'REJECTED') return { text: 'ไม่ผ่าน -- ปฏิเสธ', color: 'text-red-500' };
                if (stages.gemma.status === 'running') return { text: 'กำลังตรวจสอบ...', color: 'text-purple-500' };
                return { text: 'รอข้อมูล', color: 'text-gray-500' };
            }
        },
        {
            key: 'gemini',
            label: 'Gemini',
            desc: 'ยืนยันขั้นสุดท้าย',
            icon: LuBrainCircuit,
            color: 'amber',
            status: stages.gemini.status,
            lines: stages.gemini.lines,
            summary: () => {
                if (stages.gemini.decision === 'BUY') return { text: `BUY ${stages.gemini.confidence ? stages.gemini.confidence + '%' : ''}`.trim(), color: 'text-emerald-500' };
                if (stages.gemini.decision === 'SELL') return { text: `SELL ${stages.gemini.confidence ? stages.gemini.confidence + '%' : ''}`.trim(), color: 'text-red-500' };
                if (stages.gemini.decision === 'HOLD') return { text: 'HOLD -- ไม่เทรด', color: 'text-amber-500' };
                if (stages.gemini.status === 'running') return { text: 'กำลังวิเคราะห์...', color: 'text-amber-500' };
                return { text: 'รอ Gemma ส่งต่อ', color: 'text-gray-500' };
            }
        },
    ];

    const colorMap: Record<string, { bg: string; border: string; text: string; iconBg: string }> = {
        blue:   { bg: 'bg-blue-500/5',   border: 'border-blue-500/20',   text: 'text-blue-500',   iconBg: 'bg-blue-500/10' },
        purple: { bg: 'bg-purple-500/5', border: 'border-purple-500/20', text: 'text-purple-500', iconBg: 'bg-purple-500/10' },
        amber:  { bg: 'bg-amber-500/5',  border: 'border-amber-500/20',  text: 'text-amber-500',  iconBg: 'bg-amber-500/10' },
    };

    return (
        <div className="flex flex-col h-full bg-[#fafafa] dark:bg-[#090b14] relative">
            <style>{glowKeyframes}</style>

            {/* Header */}
            <div className="flex items-center justify-between px-5 py-3 bg-white dark:bg-[#0b0e17] border-b border-gray-100 dark:border-white/5 z-10 shrink-0">
                <div className="flex items-center gap-3">
                    <div className="px-2.5 h-7 rounded-lg flex items-center justify-center font-bold text-[12px] shrink-0 bg-gradient-to-br from-blue-500 to-indigo-600 text-white">
                        {job.symbol}
                    </div>
                    <div>
                        <div className="flex items-center gap-2">
                            <h2 className="text-[13px] font-bold text-gray-900 dark:text-white">Pipeline v8</h2>
                            {isRunning && <LuLoader size={11} className="animate-spin text-blue-500" />}
                        </div>
                        <p className="text-[10px] text-gray-500">
                            {job.interval}m | {job.auto_trade ? 'Auto' : 'Manual'} | Lot {job.lot_size}
                        </p>
                    </div>
                </div>
                <div className="flex items-center gap-2">
                    <CountdownBadge interval={job.interval} lastRunTime={lastRunTime} isRunning={isRunning} enabled={job.enabled !== false} marketClosed={closedMap[job.symbol]} />
                    {(finalResult?.final_decision || finalResult?.decision) && (() => {
                        const dec = finalResult.final_decision || finalResult.decision;
                        return (
                        <span className={`px-2.5 py-1 rounded-lg text-[11px] font-black uppercase ${
                            dec === 'BUY' ? 'bg-emerald-500/10 text-emerald-500' :
                            dec === 'SELL' ? 'bg-red-500/10 text-red-500' :
                            'bg-amber-500/10 text-amber-500'
                        }`}>
                            {dec} {finalResult.confidence ? `${Math.round(finalResult.confidence)}%` : ''}
                        </span>
                        );
                    })()}
                    <button onClick={() => handleEditJob(job)} className="p-1.5 text-gray-400 hover:text-gray-600 dark:hover:text-white rounded-lg hover:bg-gray-100 dark:hover:bg-white/5 transition-colors">
                        <LuSettings size={14} />
                    </button>
                </div>
            </div>

            {/* Pipeline Cards */}
            <div className="shrink-0 px-5 py-5">
                <div className="flex items-stretch gap-0 relative">
                    {cardConfigs.map((card, idx) => {
                        const Icon = card.icon;
                        const colors = colorMap[card.color];
                        const isActive = card.status === 'running';
                        const isDone = card.status === 'done';
                        const isError = card.status === 'error';
                        const summary = card.summary();
                        const isExpanded = expandedCard === card.key;

                        return (
                            <div key={card.key} className="flex items-stretch flex-1 min-w-0">
                                {/* Card */}
                                <div
                                    className={`flex-1 rounded-xl border-2 p-4 transition-all duration-500 cursor-pointer hover:scale-[1.02] ${
                                        isActive
                                            ? 'border-emerald-500 bg-emerald-500/5 dark:bg-emerald-500/5'
                                            : isDone
                                            ? `${colors.bg} border-emerald-500/30`
                                            : isError
                                            ? 'border-red-500/30 bg-red-500/5'
                                            : `${colors.bg} ${colors.border}`
                                    }`}
                                    style={isActive ? {
                                        animation: 'borderGlow 1.5s ease-in-out infinite',
                                    } : {}}
                                    onClick={() => setExpandedCard(isExpanded ? null : card.key)}
                                >
                                    {/* Card Header */}
                                    <div className="flex items-center gap-2.5 mb-3">
                                        <div className={`size-9 rounded-lg flex items-center justify-center ${
                                            isActive ? 'bg-emerald-500/20 text-emerald-500' :
                                            isDone ? 'bg-emerald-500/10 text-emerald-500' :
                                            isError ? 'bg-red-500/10 text-red-500' :
                                            `${colors.iconBg} ${colors.text}`
                                        }`}>
                                            {isActive ? <LuLoader size={16} className="animate-spin" /> :
                                             isDone ? <LuCheck size={16} /> :
                                             <Icon size={16} />}
                                        </div>
                                        <div>
                                            <h3 className={`text-[12px] font-bold ${
                                                isActive ? 'text-emerald-500' :
                                                isDone ? 'text-emerald-600 dark:text-emerald-400' :
                                                isError ? 'text-red-500' :
                                                'text-gray-900 dark:text-white'
                                            }`}>
                                                {card.label}
                                            </h3>
                                            <p className="text-[9px] text-gray-500">{card.desc}</p>
                                        </div>
                                        {isActive && (
                                            <div className="ml-auto">
                                                <span className="flex items-center gap-1 text-[9px] font-bold text-emerald-500 animate-pulse">
                                                    <span className="size-1.5 rounded-full bg-emerald-500" />
                                                    ACTIVE
                                                </span>
                                            </div>
                                        )}
                                    </div>

                                    {/* Result Summary */}
                                    <div className={`text-[13px] font-bold ${summary.color} mb-1`}>
                                        {summary.text}
                                    </div>

                                    {/* Latest log line */}
                                    {card.lines.length > 0 && (
                                        <p className="text-[10px] text-gray-500 dark:text-gray-400 truncate leading-relaxed">
                                            {card.lines[card.lines.length - 1]}
                                        </p>
                                    )}

                                    {/* Expanded Detail */}
                                    {isExpanded && card.lines.length > 0 && (
                                        <div className="mt-3 pt-3 border-t border-gray-200 dark:border-white/10 space-y-1 animate-in fade-in slide-in-from-top-1 duration-200 max-h-[200px] overflow-y-auto custom-scrollbar">
                                            {card.lines.map((line, i) => (
                                                <p key={i} className="text-[10px] text-gray-600 dark:text-gray-400 leading-relaxed">
                                                    {line}
                                                </p>
                                            ))}
                                        </div>
                                    )}

                                    {card.lines.length > 1 && (
                                        <button className="flex items-center gap-0.5 text-[9px] text-gray-400 hover:text-gray-600 dark:hover:text-gray-300 mt-2 transition-colors">
                                            <LuChevronDown size={10} className={`transition-transform ${isExpanded ? 'rotate-180' : ''}`} />
                                            {isExpanded ? 'ย่อ' : `${card.lines.length} รายการ`}
                                        </button>
                                    )}
                                </div>

                                {/* Connector Line */}
                                {idx < cardConfigs.length - 1 && (
                                    <div className="flex items-center px-2 shrink-0">
                                        <svg width="32" height="40" viewBox="0 0 32 40" className="overflow-visible">
                                            <defs>
                                                <linearGradient id={`grad-${idx}`} x1="0" y1="0" x2="1" y2="0">
                                                    <stop offset="0%" stopColor={isDone ? '#22c55e' : '#6b7280'} stopOpacity="0.6" />
                                                    <stop offset="100%" stopColor={
                                                        cardConfigs[idx + 1].status === 'running' ? '#22c55e' :
                                                        cardConfigs[idx + 1].status === 'done' ? '#22c55e' : '#6b7280'
                                                    } stopOpacity="0.6" />
                                                </linearGradient>
                                            </defs>
                                            <line x1="0" y1="20" x2="32" y2="20"
                                                stroke={`url(#grad-${idx})`}
                                                strokeWidth="2"
                                                strokeDasharray={isDone ? 'none' : '4 3'}
                                                style={isActive || cardConfigs[idx + 1].status === 'running' 
                                                    ? { animation: 'flowDash 0.5s linear infinite', strokeDasharray: '6 4' } 
                                                    : {}}
                                            />
                                            <polygon
                                                points="26,15 32,20 26,25"
                                                fill={isDone || cardConfigs[idx + 1].status === 'running' ? '#22c55e' : '#6b7280'}
                                                opacity="0.6"
                                            />
                                        </svg>
                                    </div>
                                )}
                            </div>
                        );
                    })}
                </div>
            </div>

            {/* Tab Switcher */}
            <div className="shrink-0 px-5 flex items-center gap-1 border-b border-gray-100 dark:border-white/5">
                <button
                    onClick={() => setActiveTab('timeline')}
                    className={`flex items-center gap-1.5 px-3 py-2 text-[11px] font-bold transition-all border-b-2 -mb-px ${
                        activeTab === 'timeline'
                            ? 'text-blue-500 border-blue-500'
                            : 'text-gray-400 border-transparent hover:text-gray-600 dark:hover:text-gray-300'
                    }`}
                >
                    <LuActivity size={12} />
                    Activity Log
                    {logsAI.length > 0 && <span className="text-[9px] opacity-60">({logsAI.length})</span>}
                </button>
                <button
                    onClick={() => setActiveTab('verbose')}
                    className={`flex items-center gap-1.5 px-3 py-2 text-[11px] font-bold transition-all border-b-2 -mb-px ${
                        activeTab === 'verbose'
                            ? 'text-purple-500 border-purple-500'
                            : 'text-gray-400 border-transparent hover:text-gray-600 dark:hover:text-gray-300'
                    }`}
                >
                    <LuEye size={12} />
                    AI Prompts
                    {verboseLogs.length > 0 && <span className="text-[9px] opacity-60">({verboseLogs.length})</span>}
                </button>
            </div>

            {/* Log Content Area */}
            <div className="flex-1 overflow-hidden">
                {activeTab === 'timeline' ? (
                    /* Timeline Log Feed */
                    <div
                        className="h-full overflow-y-auto px-5 py-3 [&::-webkit-scrollbar]:hidden"
                        onScroll={(e) => {
                            const target = e.currentTarget;
                            setAutoScroll(target.scrollHeight - target.scrollTop - target.clientHeight < 40);
                        }}
                        onMouseLeave={() => setAutoScroll(true)}
                    >
                        <div className="space-y-2 relative">
                            {logsAI.length > 0 ? logsAI.map((log, i) => {
                                const info = getAgentInfo(log.agent);
                                const Icon = info.icon;
                                const colors = agentColorClasses[info.color];
                                const isLogRunning = log.status === 'running';

                                return (
                                    <div key={i} className="flex gap-3 items-start animate-in fade-in slide-in-from-bottom-1 duration-200">
                                        <div className={`size-7 rounded-lg flex items-center justify-center shrink-0 mt-0.5 ${colors.bg} ${colors.text}`}>
                                            {isLogRunning ? <LuLoader size={13} className="animate-spin" /> : <Icon size={13} />}
                                        </div>
                                        <div className="flex-1 min-w-0">
                                            <div className="flex items-baseline justify-between gap-2">
                                                <span className={`text-[11px] font-bold capitalize ${colors.text}`}>
                                                    {info.label}
                                                </span>
                                                <div className="flex items-center gap-1.5 shrink-0">
                                                    {isLogRunning && <span className="size-1.5 rounded-full bg-blue-500 animate-pulse" />}
                                                    <span className="text-[9px] text-gray-400 font-mono">
                                                        {new Date(log.timestamp).toLocaleTimeString([], {hour:'2-digit', minute:'2-digit', second:'2-digit'})}
                                                    </span>
                                                </div>
                                            </div>
                                            <p className="text-[11px] text-gray-600 dark:text-gray-400 leading-relaxed mt-0.5 break-words">
                                                {stripEmojis(log.message)}
                                            </p>
                                        </div>
                                    </div>
                                );
                            }) : (
                                <div className="flex flex-col items-center justify-center py-16 text-center opacity-50">
                                    <LuBot size={28} className="text-gray-400 mb-2" />
                                    <p className="text-[11px] text-gray-500">รอรับข้อมูลจาก Pipeline v8...</p>
                                    <p className="text-[9px] text-gray-400 mt-1">ระบบจะเริ่มสแกนตามรอบเวลาที่ตั้งไว้</p>
                                </div>
                            )}
                            <div ref={logsEndRef} />
                        </div>
                    </div>
                ) : (
                    /* Verbose AI Prompts/Responses */
                    <div className="h-full overflow-y-auto px-5 py-3 [&::-webkit-scrollbar]:hidden">
                        <div className="space-y-2">
                            {verboseLogs.length > 0 ? verboseLogs.map((vlog, i) => {
                                const info = getAgentInfo(vlog.agent);
                                const Icon = info.icon;
                                const colors = agentColorClasses[info.color];

                                return (
                                    <div
                                        key={i}
                                        className="flex gap-3 items-start cursor-pointer group hover:bg-gray-50 dark:hover:bg-white/[0.02] rounded-lg p-2 -mx-2 transition-colors"
                                        onClick={() => setSelectedLog(vlog)}
                                    >
                                        <div className={`size-7 rounded-lg flex items-center justify-center shrink-0 mt-0.5 ${colors.bg} ${colors.text}`}>
                                            <Icon size={13} />
                                        </div>
                                        <div className="flex-1 min-w-0">
                                            <div className="flex items-baseline justify-between gap-2">
                                                <span className={`text-[11px] font-bold capitalize ${colors.text}`}>
                                                    {info.label}
                                                </span>
                                                <div className="flex items-center gap-1.5 shrink-0">
                                                    <span className="text-[9px] text-blue-400 font-medium opacity-0 group-hover:opacity-100 transition-opacity">
                                                        ดู Prompt/Response
                                                    </span>
                                                    <span className="text-[9px] text-gray-400 font-mono">
                                                        {new Date(vlog.timestamp).toLocaleTimeString([], {hour:'2-digit', minute:'2-digit', second:'2-digit'})}
                                                    </span>
                                                </div>
                                            </div>
                                            <p className="text-[10px] text-gray-500 dark:text-gray-500 leading-relaxed mt-0.5 truncate">
                                                {stripEmojis(vlog.response || vlog.prompt || '').substring(0, 120)}...
                                            </p>
                                        </div>
                                    </div>
                                );
                            }) : (
                                <div className="flex flex-col items-center justify-center py-16 text-center opacity-50">
                                    <LuEye size={28} className="text-gray-400 mb-2" />
                                    <p className="text-[11px] text-gray-500">ยังไม่มีข้อมูล Prompt/Response</p>
                                    <p className="text-[9px] text-gray-400 mt-1">ข้อมูลจะแสดงเมื่อ AI models ทำงาน</p>
                                </div>
                            )}
                        </div>
                    </div>
                )}
            </div>

            {/* Prompt Detail Modal */}
            {selectedLog && (
                <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/70 backdrop-blur-sm p-4">
                    <div className="bg-white dark:bg-[#0B101E] border border-gray-200 dark:border-white/10 rounded-2xl shadow-2xl w-full max-w-3xl max-h-[85vh] flex flex-col animate-in fade-in zoom-in-95 duration-200">
                        <div className="flex items-center justify-between p-4 border-b border-gray-100 dark:border-white/5 shrink-0">
                            <div className="flex items-center gap-2">
                                <h3 className="text-sm font-bold text-gray-800 dark:text-gray-100">AI Detail</h3>
                                <span className="text-[10px] text-gray-400 font-mono">
                                    {selectedLog.agent?.replace(/_/g, ' ')} | {new Date(selectedLog.timestamp).toLocaleString()}
                                </span>
                            </div>
                            <button onClick={() => setSelectedLog(null)}
                                className="size-8 flex items-center justify-center bg-gray-100 hover:bg-gray-200 dark:bg-white/5 dark:hover:bg-white/10 text-gray-500 rounded-lg transition-colors">
                                <LuX size={16} />
                            </button>
                        </div>
                        <div className="flex-1 overflow-y-auto custom-scrollbar">
                            {selectedLog.prompt && (
                                <div className="p-5 border-b border-gray-100 dark:border-white/5">
                                    <h4 className="text-[10px] font-bold text-blue-500 uppercase tracking-wider mb-2">Prompt</h4>
                                    <pre className="text-[11px] font-mono text-gray-600 dark:text-gray-400 whitespace-pre-wrap leading-relaxed break-words bg-gray-50 dark:bg-[#06080F] rounded-lg p-4">
                                        {selectedLog.prompt}
                                    </pre>
                                </div>
                            )}
                            {selectedLog.response && (
                                <div className="p-5">
                                    <h4 className="text-[10px] font-bold text-emerald-500 uppercase tracking-wider mb-2">Response</h4>
                                    <pre className="text-[11px] font-mono text-gray-700 dark:text-emerald-400 whitespace-pre-wrap leading-relaxed break-words bg-gray-50 dark:bg-[#06080F] rounded-lg p-4">
                                        {selectedLog.response}
                                    </pre>
                                </div>
                            )}
                            {!selectedLog.prompt && !selectedLog.response && selectedLog.message && (
                                <div className="p-5">
                                    <pre className="text-[12px] font-mono text-gray-700 dark:text-emerald-400 whitespace-pre-wrap leading-relaxed break-words">
                                        {selectedLog.message}
                                    </pre>
                                </div>
                            )}
                        </div>
                    </div>
                </div>
            )}
        </div>
    );
};
