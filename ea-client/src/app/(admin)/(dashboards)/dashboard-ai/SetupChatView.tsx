import { LuServer, LuBrainCircuit, LuCheck, LuSparkles, LuLoader, LuSettings, LuPower, LuTrophy } from 'react-icons/lu';
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
    topSignals: any[];
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
            if (msg.includes('เริ่ม scan') || msg.includes('Pipeline v8:')) {
                stages.server.result = ''; stages.server.strategy = ''; stages.server.score = ''; stages.server.tf = '';
                stages.gemma.verdict = ''; stages.gemma.reason = '';
                stages.gemini.decision = ''; stages.gemini.confidence = ''; stages.gemini.reason = '';
            }
            stages.server.lines.push(msg); stages.server.status = status;
            const stageMatch = msg.match(/Stage 1:\s*(BUY|SELL)\s+\S+.*Score\s+(\d+)/i);
            if (stageMatch) { stages.server.result = stageMatch[1]; stages.server.score = stageMatch[2]; }
            const stratFromStage = msg.match(/\|\s*([\w\s]+?)\s*\(/);
            if (stratFromStage) stages.server.strategy = stratFromStage[1].trim();
            const tfMatch = msg.match(/(M5|M15|M30|H1|H4)/);
            if (tfMatch) stages.server.tf = tfMatch[1];
            const finalMatch = msg.match(/^.*?(BUY|SELL)\s+\S+\s+(\d+)%\s+lot:/i);
            if (finalMatch) { stages.server.result = finalMatch[1]; stages.server.score = finalMatch[2]; }
            if (msg.includes('ไม่มีสัญญาณผ่าน') || msg.includes('No signal') || (msg.includes('BUY:0') && msg.includes('SELL:0'))) {
                stages.server.result = 'NO_SIGNAL';
            }
        }
        if (agent === 'gemma_filter' || agent === 'gemma_filter_v8' || agent.includes('gemma')) {
            stages.gemma.lines.push(msg); stages.gemma.status = status;
            if (msg.toLowerCase().includes('approve') || msg.includes('ผ่าน')) stages.gemma.verdict = 'APPROVED';
            if (msg.toLowerCase().includes('reject') || msg.includes('ไม่ผ่าน')) stages.gemma.verdict = 'REJECTED';
            if (msg.includes('ปิดใช้งาน') || msg.includes('SKIP')) stages.gemma.verdict = 'SKIPPED';
            stages.gemma.reason = msg;
        }
        if (agent === 'gemini_confirm' || agent === 'gemini_confirm_v8' || agent.includes('gemini') || agent === 'decision_maker') {
            stages.gemini.lines.push(msg); stages.gemini.status = status;
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

// ─── Radial Score ───
const RadialScore = ({ score, size = 52, color = '#3b82f6' }: { score: number; size?: number; color?: string }) => {
    const r = (size - 6) / 2;
    const circ = 2 * Math.PI * r;
    const offset = circ - (score / 100) * circ;
    return (
        <svg width={size} height={size} className="transform -rotate-90">
            <circle cx={size/2} cy={size/2} r={r} fill="none" stroke="currentColor" strokeWidth="3" className="text-gray-100 dark:text-white/5" />
            <circle cx={size/2} cy={size/2} r={r} fill="none" stroke={color} strokeWidth="3"
                strokeDasharray={circ} strokeDashoffset={offset} strokeLinecap="round"
                className="transition-all duration-1000 ease-out" />
            <text x={size/2} y={size/2} textAnchor="middle" dominantBaseline="central"
                className="fill-gray-800 dark:fill-white text-[11px] font-black"
                transform={`rotate(90 ${size/2} ${size/2})`}>
                {Math.round(score)}
            </text>
        </svg>
    );
};

export const SetupChatView = ({
    job, logsBySymbol, lastRunMap, agentStatusBySymbol, closedMap, finalResultBySymbol, handleEditJob,
    saveJobsToDb, autoPilotJobs, jobIdx, topSignals,
}: SetupChatViewProps) => {

    const logsAI = logsBySymbol[job.symbol] || [];
    const lastRunTime = lastRunMap?.[job.symbol] || null;
    const isRunning = Object.values(agentStatusBySymbol?.[job.symbol] || {}).some(s => s === 'running');
    const finalResult = finalResultBySymbol?.[job.symbol];

    const top2 = (() => {
        if (topSignals && topSignals.length > 0) return topSignals.slice(0, 2);
        const stageLines = logsAI.filter(l => l.message && l.message.includes('Stage 1:')).map(l => l.message || '');
        return stageLines.slice(-2).map((line, i) => {
            const clean = stripEmojis(line);
            const m = clean.match(/Stage 1:\s*(BUY|SELL)\s+\S+.*Score\s+(\d+)%?.*?\|\s*([\w\s]+?)\s*\(([^)]+)\)/i);
            if (!m) return null;
            return { rank: i + 1, direction: m[1], score: parseFloat(m[2]), strategy_name: m[3].trim(), timeframe: m[4] };
        }).filter(Boolean);
    })();

    const disabledStages: string[] = job.disabled_stages || [];
    const toggleStage = (stageKey: string) => {
        const current: string[] = job.disabled_stages || [];
        const next = current.includes(stageKey) ? current.filter((s: string) => s !== stageKey) : [...current, stageKey];
        const updated = autoPilotJobs.map((j: any, i: number) => i === jobIdx ? { ...j, disabled_stages: next } : j);
        saveJobsToDb(updated);
    };

    const stages = parseStageData(logsAI);
    const agentStatuses = agentStatusBySymbol?.[job.symbol] || {} as any;
    if (agentStatuses.pipeline_v8) stages.server.status = agentStatuses.pipeline_v8;
    if (agentStatuses.gemma_filter) stages.gemma.status = agentStatuses.gemma_filter;
    if (agentStatuses.gemini_confirm) stages.gemini.status = agentStatuses.gemini_confirm;

    const finalDec = finalResult?.final_decision || finalResult?.decision;
    const gemmaDisabled = disabledStages.includes('gemma');
    const geminiDisabled = disabledStages.includes('gemini');

    const gemmaResult = (() => {
        if (gemmaDisabled) return { text: 'ปิดใช้งาน', color: 'text-gray-400' };
        if (stages.gemma.verdict === 'APPROVED') return { text: 'จัดเรียงข้อมูลแล้ว', color: 'text-emerald-500' };
        if (stages.gemma.verdict === 'REJECTED') return { text: 'ข้อมูลไม่เพียงพอ', color: 'text-red-500' };
        if (stages.gemma.status === 'running') return { text: 'กำลังจัดเรียงข้อมูล...', color: 'text-purple-500' };
        return { text: 'รอข้อมูลจาก Server', color: 'text-gray-400' };
    })();

    const geminiResult = (() => {
        if (geminiDisabled) return { text: 'ปิดใช้งาน', color: 'text-gray-400' };
        if (stages.gemini.decision === 'SKIPPED') return { text: 'ปิดใช้งาน', color: 'text-gray-400' };
        if (stages.gemini.decision === 'BUY') return { text: `BUY ${stages.gemini.confidence ? stages.gemini.confidence + '%' : ''}`.trim(), color: 'text-emerald-500' };
        if (stages.gemini.decision === 'SELL') return { text: `SELL ${stages.gemini.confidence ? stages.gemini.confidence + '%' : ''}`.trim(), color: 'text-red-500' };
        if (stages.gemini.decision === 'HOLD') return { text: 'HOLD', color: 'text-amber-500' };
        if (stages.gemini.status === 'running') return { text: 'กำลังตัดสินใจ...', color: 'text-amber-500' };
        return { text: 'รอข้อมูลจาก Gemma', color: 'text-gray-400' };
    })();

    // Card style: white, thin border, no shadow
    const card = 'rounded-xl border border-gray-100 dark:border-white/5 bg-white dark:bg-[#0d1020]';

    return (
        <div className="flex flex-col h-full bg-[#fafbfc] dark:bg-[#090b14]">

            {/* ═══ HEADER ═══ */}
            <div className="flex items-center justify-between px-5 py-3 bg-white dark:bg-[#0b0e17] border-b border-gray-100 dark:border-white/5 shrink-0">
                <div className="flex items-center gap-3">
                    <div className="px-2.5 h-7 rounded-lg flex items-center justify-center font-bold text-[12px] shrink-0 bg-gradient-to-br from-blue-500 to-indigo-600 text-white">
                        {job.symbol}
                    </div>
                    <div>
                        <div className="flex items-center gap-2">
                            <h2 className="text-[13px] font-bold text-gray-900 dark:text-white">Pipeline v9</h2>
                            {isRunning && <LuLoader size={11} className="animate-spin text-blue-500" />}
                        </div>
                        <p className="text-[10px] text-gray-500">{job.interval}m | {job.auto_trade ? 'Auto' : 'Manual'} | Lot {job.lot_size}</p>
                    </div>
                </div>
                <div className="flex items-center gap-2">
                    <CountdownBadge interval={job.interval} lastRunTime={lastRunTime} isRunning={isRunning} enabled={job.enabled !== false} marketClosed={closedMap[job.symbol]} />
                    {finalDec && (
                        <span className={`px-2.5 py-1 rounded-lg text-[11px] font-black uppercase ${
                            finalDec === 'BUY' ? 'bg-emerald-500/10 text-emerald-500' :
                            finalDec === 'SELL' ? 'bg-red-500/10 text-red-500' : 'bg-amber-500/10 text-amber-500'
                        }`}>
                            {finalDec} {finalResult.confidence ? `${Math.round(finalResult.confidence)}%` : ''}
                        </span>
                    )}
                    <button onClick={() => handleEditJob(job)} className="p-1.5 text-gray-400 hover:text-gray-600 dark:hover:text-white rounded-lg hover:bg-gray-100 dark:hover:bg-white/5 transition-colors">
                        <LuSettings size={14} />
                    </button>
                </div>
            </div>

            {/* ═══ CONTENT ═══ */}
            <div className="flex-1 overflow-y-auto px-5 py-5 [&::-webkit-scrollbar]:hidden space-y-4">

                {/* ── STAGE 1: Server Scan → Top 2 กลยุทธ์ ── */}
                <div className="space-y-2">
                    <div className="flex items-center gap-2 px-1">
                        <div className={`size-5 rounded flex items-center justify-center shrink-0 ${
                            stages.server.status === 'running' ? 'bg-blue-500' :
                            stages.server.status === 'done' ? 'bg-emerald-500' : 'bg-gray-300 dark:bg-gray-700'
                        }`}>
                            {stages.server.status === 'running' ? <LuLoader size={10} className="animate-spin text-white" /> :
                             stages.server.status === 'done' ? <LuCheck size={10} className="text-white" /> :
                             <LuServer size={10} className="text-white" />}
                        </div>
                        <span className="text-[11px] font-bold text-gray-800 dark:text-gray-200">Server Scan</span>
                        <span className="text-[9px] text-gray-400">10 กลยุทธ์ x 5 TF</span>
                    </div>

                    {top2.length > 0 ? (
                        <div className="grid grid-cols-2 gap-3">
                            {top2.map((sig: any, i: number) => {
                                const scoreColor = sig.score >= 70 ? '#22c55e' : sig.score >= 50 ? '#3b82f6' : '#9ca3af';
                                const dirBg = sig.direction === 'BUY' ? 'bg-emerald-500' : 'bg-red-500';

                                return (
                                    <div key={i} className={`${card} p-4`}>
                                        <div className="flex items-start justify-between">
                                            <div>
                                                <div className="flex items-center gap-1.5 mb-1">
                                                    <LuTrophy size={10} className={i === 0 ? 'text-amber-500' : 'text-gray-400'} />
                                                    <span className={`text-[9px] font-bold ${i === 0 ? 'text-amber-500' : 'text-gray-400'}`}>#{i + 1}</span>
                                                </div>
                                                <h4 className="text-[13px] font-bold text-gray-900 dark:text-white leading-tight">{sig.strategy_name}</h4>
                                                <span className="text-[10px] text-gray-400 font-mono">{sig.timeframe}</span>
                                            </div>
                                            <RadialScore score={sig.score} size={48} color={scoreColor} />
                                        </div>
                                        <div className="mt-3">
                                            <span className={`text-[10px] font-bold text-white px-2 py-0.5 rounded ${dirBg}`}>
                                                {sig.direction}
                                            </span>
                                        </div>
                                    </div>
                                );
                            })}
                        </div>
                    ) : (
                        <div className={`${card} p-6 flex items-center justify-center`}>
                            {isRunning ? (
                                <div className="flex items-center gap-2 text-gray-400">
                                    <LuLoader size={13} className="animate-spin" />
                                    <span className="text-[11px]">กำลังสแกน...</span>
                                </div>
                            ) : (
                                <span className="text-[11px] text-gray-400">รอผลสแกนรอบถัดไป</span>
                            )}
                        </div>
                    )}
                </div>

                {/* ── Flow Arrow ── */}
                <div className="flex justify-center">
                    <svg width="16" height="20" viewBox="0 0 16 20"><line x1="8" y1="0" x2="8" y2="16" stroke="#e5e7eb" strokeWidth="1.5" strokeDasharray="4 3" className="dark:stroke-gray-700" /><polygon points="5,14 8,20 11,14" fill="#e5e7eb" className="dark:fill-gray-700" /></svg>
                </div>

                {/* ── STAGE 2: Gemma 4 ── */}
                <div className={`${card} p-4 transition-all ${
                    gemmaDisabled ? 'opacity-50' :
                    stages.gemma.status === 'running' ? 'border-purple-200 dark:border-purple-500/20' :
                    stages.gemma.status === 'done' ? 'border-emerald-200 dark:border-emerald-500/20' : ''
                }`}>
                    <div className="flex items-center gap-2">
                        <div className={`size-7 rounded-lg flex items-center justify-center shrink-0 ${
                            gemmaDisabled ? 'bg-gray-100 dark:bg-white/5' :
                            stages.gemma.status === 'running' ? 'bg-gradient-to-br from-purple-500 to-pink-500' :
                            stages.gemma.status === 'done' ? 'bg-emerald-500' : 'bg-gradient-to-br from-purple-500 to-pink-500'
                        }`}>
                            {gemmaDisabled ? <LuPower size={12} className="text-gray-400" /> :
                             stages.gemma.status === 'running' ? <LuLoader size={12} className="animate-spin text-white" /> :
                             stages.gemma.status === 'done' ? <LuCheck size={12} className="text-white" /> :
                             <LuSparkles size={12} className="text-white" />}
                        </div>
                        <div className="flex-1 min-w-0">
                            <h4 className="text-[11px] font-bold text-gray-900 dark:text-white">Gemma 4</h4>
                            <p className="text-[9px] text-gray-400">จัดเรียงข้อมูล 2 กลยุทธ์</p>
                        </div>
                        <span className={`text-[11px] font-bold ${gemmaResult.color}`}>{gemmaResult.text}</span>
                        <button onClick={(e) => { e.stopPropagation(); toggleStage('gemma'); }}
                            className={`relative inline-flex h-4 w-7 shrink-0 cursor-pointer items-center rounded-full transition-colors ${
                                !gemmaDisabled ? 'bg-purple-500' : 'bg-gray-300 dark:bg-gray-700'
                            }`}>
                            <span className={`inline-block h-3 w-3 transform rounded-full bg-white shadow-sm transition duration-200 ${
                                !gemmaDisabled ? 'translate-x-[13px]' : 'translate-x-[2px]'
                            }`} />
                        </button>
                    </div>
                </div>

                {/* ── Flow Arrow ── */}
                <div className="flex justify-center">
                    <svg width="16" height="20" viewBox="0 0 16 20"><line x1="8" y1="0" x2="8" y2="16" stroke="#e5e7eb" strokeWidth="1.5" strokeDasharray="4 3" className="dark:stroke-gray-700" /><polygon points="5,14 8,20 11,14" fill="#e5e7eb" className="dark:fill-gray-700" /></svg>
                </div>

                {/* ── STAGE 3: Gemini ── */}
                <div className={`${card} p-4 transition-all ${
                    geminiDisabled ? 'opacity-50' :
                    stages.gemini.status === 'running' ? 'border-amber-200 dark:border-amber-500/20' :
                    stages.gemini.status === 'done' ? 'border-emerald-200 dark:border-emerald-500/20' : ''
                }`}>
                    <div className="flex items-center gap-2">
                        <div className={`size-7 rounded-lg flex items-center justify-center shrink-0 ${
                            geminiDisabled ? 'bg-gray-100 dark:bg-white/5' :
                            stages.gemini.status === 'running' ? 'bg-gradient-to-br from-amber-500 to-orange-500' :
                            stages.gemini.status === 'done' ? 'bg-emerald-500' : 'bg-gradient-to-br from-amber-500 to-orange-500'
                        }`}>
                            {geminiDisabled ? <LuPower size={12} className="text-gray-400" /> :
                             stages.gemini.status === 'running' ? <LuLoader size={12} className="animate-spin text-white" /> :
                             stages.gemini.status === 'done' ? <LuCheck size={12} className="text-white" /> :
                             <LuBrainCircuit size={12} className="text-white" />}
                        </div>
                        <div className="flex-1 min-w-0">
                            <h4 className="text-[11px] font-bold text-gray-900 dark:text-white">Gemini</h4>
                            <p className="text-[9px] text-gray-400">ตัดสินใจสุดท้าย</p>
                        </div>
                        <span className={`text-[11px] font-bold ${geminiResult.color}`}>{geminiResult.text}</span>
                        <button onClick={(e) => { e.stopPropagation(); toggleStage('gemini'); }}
                            className={`relative inline-flex h-4 w-7 shrink-0 cursor-pointer items-center rounded-full transition-colors ${
                                !geminiDisabled ? 'bg-amber-500' : 'bg-gray-300 dark:bg-gray-700'
                            }`}>
                            <span className={`inline-block h-3 w-3 transform rounded-full bg-white shadow-sm transition duration-200 ${
                                !geminiDisabled ? 'translate-x-[13px]' : 'translate-x-[2px]'
                            }`} />
                        </button>
                    </div>
                </div>

            </div>
        </div>
    );
};
