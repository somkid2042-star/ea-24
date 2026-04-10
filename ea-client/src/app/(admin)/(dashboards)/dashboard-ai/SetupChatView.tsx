import { useState } from 'react';
import { LuChevronDown, LuServer, LuBrainCircuit, LuCheck, LuSparkles, LuLoader, LuSettings, LuPower } from 'react-icons/lu';
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
            // Reset all stage data when a new scan starts (new pipeline run)
            if (msg.includes('เริ่ม scan') || msg.includes('Pipeline v8:')) {
                stages.server.result = '';
                stages.server.strategy = '';
                stages.server.score = '';
                stages.server.tf = '';
                stages.gemma.verdict = '';
                stages.gemma.reason = '';
                stages.gemini.decision = '';
                stages.gemini.confidence = '';
                stages.gemini.reason = '';
            }
            stages.server.lines.push(msg);
            stages.server.status = status;

            // Detect Stage 1 result: "Stage 1: BUY/SELL SYMBOL — Score X%"
            const stageMatch = msg.match(/Stage 1:\s*(BUY|SELL)\s+\S+.*Score\s+(\d+)/i);
            if (stageMatch) {
                stages.server.result = stageMatch[1];
                stages.server.score = stageMatch[2];
            }

            const stratMatch = msg.match(/Best Signal:\s*(\w+)/i) || msg.match(/เลือก.*?:\s*(\w+)/i);
            if (stratMatch) stages.server.strategy = stratMatch[1];

            // Extract strategy name from Stage 1 line
            const stratFromStage = msg.match(/\|\s*(\w[\w\s]*?)\s*\(/);
            if (stratFromStage) stages.server.strategy = stratFromStage[1].trim();

            const tfMatch = msg.match(/(M5|M15|M30|H1|H4)/);
            if (tfMatch) stages.server.tf = tfMatch[1];

            // Final pipeline result: "🔥 BUY/SELL SYMBOL — XX% lot:X.XX"
            const finalMatch = msg.match(/^.*?(BUY|SELL)\s+\S+\s+(\d+)%\s+lot:/i);
            if (finalMatch) {
                stages.server.result = finalMatch[1];
                stages.server.score = finalMatch[2];
            }

            // NO_SIGNAL: only match the specific "ไม่มีสัญญาณผ่าน" message (with ผ่าน suffix)
            // Also match "BUY:0 SELL:0" but NOT "BUY:1" etc.
            if (msg.includes('ไม่มีสัญญาณผ่าน') || msg.includes('No signal') || (msg.includes('BUY:0') && msg.includes('SELL:0'))) {
                stages.server.result = 'NO_SIGNAL';
            }
        }
        if (agent === 'gemma_filter' || agent === 'gemma_filter_v8' || agent.includes('gemma')) {
            stages.gemma.lines.push(msg);
            stages.gemma.status = status;
            if (msg.toLowerCase().includes('approve') || msg.includes('เห็นด้วย') || msg.includes('ผ่าน')) stages.gemma.verdict = 'APPROVED';
            if (msg.toLowerCase().includes('reject') || msg.includes('ไม่เห็นด้วย') || msg.includes('ไม่ผ่าน')) stages.gemma.verdict = 'REJECTED';
            if (msg.includes('ปิดใช้งาน') || msg.includes('SKIP')) stages.gemma.verdict = 'SKIPPED';
            stages.gemma.reason = msg;
        }
        if (agent === 'gemini_confirm' || agent === 'gemini_confirm_v8' || agent.includes('gemini') || agent === 'decision_maker') {
            stages.gemini.lines.push(msg);
            stages.gemini.status = status;
            const decMatch = msg.match(/(BUY|SELL|HOLD)/);
            if (decMatch) stages.gemini.decision = decMatch[1];
            const confMatch = msg.match(/(\d+)%/) || msg.match(/confidence[:\s]+(\d+)/i);
            if (confMatch) stages.gemini.confidence = confMatch[1];
            if (msg.includes('ปิดใช้งาน') || msg.includes('SKIP')) stages.gemini.decision = 'SKIPPED';
            stages.gemini.reason = msg;
        }
    });
    return stages;
};

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
    job, logsBySymbol, lastRunMap, agentStatusBySymbol, closedMap, finalResultBySymbol, handleEditJob,
    saveJobsToDb, autoPilotJobs, jobIdx,
}: SetupChatViewProps) => {
    const [expandedCard, setExpandedCard] = useState<string | null>(null);

    const logsAI = logsBySymbol[job.symbol] || [];
    const lastRunTime = lastRunMap?.[job.symbol] || null;
    const isRunning = Object.values(agentStatusBySymbol?.[job.symbol] || {}).some(s => s === 'running');
    const finalResult = finalResultBySymbol?.[job.symbol];

    // Disabled stages from job config
    const disabledStages: string[] = job.disabled_stages || [];

    const toggleStage = (stageKey: string) => {
        const current: string[] = job.disabled_stages || [];
        let next: string[];
        if (current.includes(stageKey)) {
            next = current.filter((s: string) => s !== stageKey);
        } else {
            next = [...current, stageKey];
        }
        const updated = autoPilotJobs.map((j: any, i: number) =>
            i === jobIdx ? { ...j, disabled_stages: next } : j
        );
        saveJobsToDb(updated);
    };

    const stages = parseStageData(logsAI);
    const agentStatuses = agentStatusBySymbol?.[job.symbol] || {} as any;
    if (agentStatuses.pipeline_v8) stages.server.status = agentStatuses.pipeline_v8;
    if (agentStatuses.gemma_filter) stages.gemma.status = agentStatuses.gemma_filter;
    if (agentStatuses.gemini_confirm) stages.gemini.status = agentStatuses.gemini_confirm;

    const cardConfigs = [
        {
            key: 'server', label: 'Server Scan', desc: '10 กลยุทธ์ x 5 TF',
            icon: LuServer, color: 'blue', status: stages.server.status, lines: stages.server.lines, alwaysOn: true,
            summary: () => {
                if (stages.server.result === 'NO_SIGNAL') return { text: 'ไม่พบสัญญาณ', color: 'text-gray-500' };
                if (stages.server.result === 'BUY') return { text: `BUY ${stages.server.strategy || ''} ${stages.server.tf || ''}`.trim(), color: 'text-emerald-500' };
                if (stages.server.result === 'SELL') return { text: `SELL ${stages.server.strategy || ''} ${stages.server.tf || ''}`.trim(), color: 'text-red-500' };
                if (stages.server.status === 'running') return { text: 'กำลังสแกน...', color: 'text-blue-500' };
                return { text: 'รอสแกน', color: 'text-gray-500' };
            }
        },
        {
            key: 'gemma', label: 'Gemma 4', desc: 'ตรวจสอบ + ประวัติ',
            icon: LuSparkles, color: 'purple', status: stages.gemma.status, lines: stages.gemma.lines, alwaysOn: false,
            summary: () => {
                if (disabledStages.includes('gemma')) return { text: 'ปิดใช้งาน', color: 'text-gray-400' };
                if (stages.gemma.verdict === 'APPROVED') return { text: 'ผ่าน -- เห็นด้วย', color: 'text-emerald-500' };
                if (stages.gemma.verdict === 'REJECTED') return { text: 'ไม่ผ่าน -- ปฏิเสธ', color: 'text-red-500' };
                if (stages.gemma.status === 'running') return { text: 'กำลังตรวจสอบ...', color: 'text-purple-500' };
                return { text: 'รอข้อมูล', color: 'text-gray-500' };
            }
        },
        {
            key: 'gemini', label: 'Gemini', desc: 'ยืนยันขั้นสุดท้าย',
            icon: LuBrainCircuit, color: 'amber', status: stages.gemini.status, lines: stages.gemini.lines, alwaysOn: false,
            summary: () => {
                if (disabledStages.includes('gemini')) return { text: 'ปิดใช้งาน', color: 'text-gray-400' };
                if (stages.gemini.decision === 'SKIPPED') return { text: 'ปิดใช้งาน', color: 'text-gray-400' };
                if (stages.gemini.decision === 'BUY') return { text: `BUY ${stages.gemini.confidence ? stages.gemini.confidence + '%' : ''}`.trim(), color: 'text-emerald-500' };
                if (stages.gemini.decision === 'SELL') return { text: `SELL ${stages.gemini.confidence ? stages.gemini.confidence + '%' : ''}`.trim(), color: 'text-red-500' };
                if (stages.gemini.decision === 'HOLD') return { text: 'HOLD -- ไม่เทรด', color: 'text-amber-500' };
                if (stages.gemini.status === 'running') return { text: 'กำลังวิเคราะห์...', color: 'text-amber-500' };
                return { text: disabledStages.includes('gemma') ? 'รอ Server Scan ส่งต่อ' : 'รอ Gemma ส่งต่อ', color: 'text-gray-500' };
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

            {/* Pipeline Cards — Vertical */}
            <div className="flex-1 overflow-y-auto px-5 py-4 [&::-webkit-scrollbar]:hidden">
                <div className="flex flex-col gap-0">
                    {cardConfigs.map((card, idx) => {
                        const Icon = card.icon;
                        const colors = colorMap[card.color];
                        const isDisabled = disabledStages.includes(card.key);
                        const isActive = !isDisabled && card.status === 'running';
                        const isDone = !isDisabled && card.status === 'done';
                        const isError = !isDisabled && card.status === 'error';
                        const summary = card.summary();
                        const isExpanded = expandedCard === card.key;

                        return (
                            <div key={card.key} className="flex flex-col items-stretch">
                                <div
                                    className={`rounded-xl border-2 p-4 transition-all duration-500 ${
                                        isDisabled
                                            ? 'border-gray-200 dark:border-white/5 bg-gray-50 dark:bg-white/[0.02] opacity-50'
                                            : isActive
                                            ? 'border-emerald-500 bg-emerald-500/5 dark:bg-emerald-500/5'
                                            : isDone
                                            ? `${colors.bg} border-emerald-500/30`
                                            : isError
                                            ? 'border-red-500/30 bg-red-500/5'
                                            : `${colors.bg} ${colors.border}`
                                    }`}
                                    style={isActive ? { animation: 'borderGlow 1.5s ease-in-out infinite' } : {}}
                                >
                                    <div className="flex items-center gap-3">
                                        <div
                                            className={`size-9 rounded-lg flex items-center justify-center shrink-0 cursor-pointer ${
                                                isDisabled ? 'bg-gray-200 dark:bg-white/5 text-gray-400' :
                                                isActive ? 'bg-emerald-500/20 text-emerald-500' :
                                                isDone ? 'bg-emerald-500/10 text-emerald-500' :
                                                isError ? 'bg-red-500/10 text-red-500' :
                                                `${colors.iconBg} ${colors.text}`
                                            }`}
                                            onClick={() => !isDisabled && setExpandedCard(isExpanded ? null : card.key)}
                                        >
                                            {isDisabled ? <LuPower size={16} className="text-gray-400" /> :
                                             isActive ? <LuLoader size={16} className="animate-spin" /> :
                                             isDone ? <LuCheck size={16} /> :
                                             <Icon size={16} />}
                                        </div>
                                        <div className="flex-1 min-w-0 cursor-pointer" onClick={() => !isDisabled && setExpandedCard(isExpanded ? null : card.key)}>
                                            <div className="flex items-center gap-2">
                                                <h3 className={`text-[12px] font-bold ${
                                                    isDisabled ? 'text-gray-400 line-through' :
                                                    isActive ? 'text-emerald-500' :
                                                    isDone ? 'text-emerald-600 dark:text-emerald-400' :
                                                    isError ? 'text-red-500' :
                                                    'text-gray-900 dark:text-white'
                                                }`}>
                                                    {card.label}
                                                </h3>
                                                <span className="text-[9px] text-gray-500">{card.desc}</span>
                                            </div>
                                            <div className={`text-[13px] font-bold ${summary.color} mt-0.5`}>
                                                {summary.text}
                                            </div>
                                        </div>

                                        {isActive && (
                                            <span className="flex items-center gap-1 text-[9px] font-bold text-emerald-500 animate-pulse shrink-0">
                                                <span className="size-1.5 rounded-full bg-emerald-500" />
                                                ACTIVE
                                            </span>
                                        )}

                                        {/* Toggle Switch — Gemma/Gemini only */}
                                        {!card.alwaysOn && (
                                            <button
                                                onClick={(e) => { e.stopPropagation(); toggleStage(card.key); }}
                                                className={`relative inline-flex h-5 w-9 shrink-0 cursor-pointer items-center justify-center rounded-full transition-colors ${
                                                    !isDisabled
                                                        ? card.color === 'purple' ? 'bg-purple-500' : 'bg-amber-500'
                                                        : 'bg-gray-300 dark:bg-gray-700'
                                                }`}
                                                title={isDisabled ? `เปิด ${card.label}` : `ปิด ${card.label}`}
                                            >
                                                <span className={`inline-block h-3.5 w-3.5 transform rounded-full bg-white shadow-sm transition duration-200 ${
                                                    !isDisabled ? 'translate-x-[7px]' : '-translate-x-[7px]'
                                                }`} />
                                            </button>
                                        )}

                                        {!isDisabled && card.lines.length > 1 && (
                                            <LuChevronDown
                                                size={12}
                                                className={`text-gray-400 shrink-0 transition-transform cursor-pointer ${isExpanded ? 'rotate-180' : ''}`}
                                                onClick={() => setExpandedCard(isExpanded ? null : card.key)}
                                            />
                                        )}
                                    </div>

                                    {!isDisabled && card.lines.length > 0 && !isExpanded && (
                                        <p className="text-[10px] text-gray-500 dark:text-gray-400 truncate leading-relaxed mt-2 ml-12">
                                            {card.lines[card.lines.length - 1]}
                                        </p>
                                    )}

                                    {!isDisabled && isExpanded && card.lines.length > 0 && (
                                        <div className="mt-3 ml-12 pt-3 border-t border-gray-200 dark:border-white/10 space-y-1.5 animate-in fade-in slide-in-from-top-1 duration-200 max-h-[300px] overflow-y-auto custom-scrollbar">
                                            {card.lines.map((line, i) => (
                                                <p key={i} className="text-[10px] text-gray-600 dark:text-gray-400 leading-relaxed">
                                                    {line}
                                                </p>
                                            ))}
                                        </div>
                                    )}
                                </div>

                                {/* Vertical Connector */}
                                {idx < cardConfigs.length - 1 && (
                                    <div className="flex justify-center py-1">
                                        <svg width="20" height="24" viewBox="0 0 20 24" className="overflow-visible">
                                            <defs>
                                                <linearGradient id={`vgrad-${idx}`} x1="0" y1="0" x2="0" y2="1">
                                                    <stop offset="0%" stopColor={isDone ? '#22c55e' : '#6b7280'} stopOpacity="0.6" />
                                                    <stop offset="100%" stopColor={
                                                        disabledStages.includes(cardConfigs[idx + 1].key) ? '#9ca3af' :
                                                        cardConfigs[idx + 1].status === 'running' ? '#22c55e' :
                                                        cardConfigs[idx + 1].status === 'done' ? '#22c55e' : '#6b7280'
                                                    } stopOpacity="0.6" />
                                                </linearGradient>
                                            </defs>
                                            <line x1="10" y1="0" x2="10" y2="24"
                                                stroke={isDisabled ? '#d1d5db' : `url(#vgrad-${idx})`}
                                                strokeWidth="2"
                                                strokeDasharray={isDone && !disabledStages.includes(cardConfigs[idx + 1].key) ? 'none' : '4 3'}
                                                style={!isDisabled && (isActive || cardConfigs[idx + 1].status === 'running')
                                                    ? { animation: 'flowDash 0.5s linear infinite', strokeDasharray: '6 4' } 
                                                    : {}}
                                            />
                                            <polygon
                                                points="6,18 10,24 14,18"
                                                fill={
                                                    disabledStages.includes(cardConfigs[idx + 1].key) ? '#d1d5db' :
                                                    isDone || cardConfigs[idx + 1].status === 'running' ? '#22c55e' : '#6b7280'
                                                }
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
        </div>
    );
};
