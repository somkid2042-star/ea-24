import { useEffect, useRef, useState } from 'react';
import { LuImagePlus, LuActivity, LuServer, LuX } from 'react-icons/lu';
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

export const SetupChatView = ({
    job, verboseLogs, logsM1BySymbol, lastRunMap, agentStatusBySymbol, agentStatusM1Map, closedMap
}: SetupChatViewProps) => {
    const [activeView, setActiveView] = useState<'server' | 'ai'>('ai');
    const [isHovering, setIsHovering] = useState(false);
    const [selectedLog, setSelectedLog] = useState<any>(null);
    const logsM1 = logsM1BySymbol[job.symbol] || [];
    
    const lastRunTime = lastRunMap?.[job.symbol] || null;
    const isAiRunning = Object.values(agentStatusBySymbol?.[job.symbol] || {}).some(s => s === 'running');
    
    const isM1Running = Object.values(agentStatusM1Map?.[job.symbol] || {}).some(s => s === 'running');
    
    const disabledAgents = job.disabled_agents || [];
    const filteredVerboseLogs = (verboseLogs || []).filter((log: any) => !disabledAgents.includes(log.agent));

    const logsEndRef = useRef<HTMLDivElement>(null);

    useEffect(() => {
        if (!isHovering) {
            logsEndRef.current?.scrollIntoView({ behavior: 'smooth' });
        }
    }, [filteredVerboseLogs, logsM1, activeView, isHovering]);

    return (
        <div className="flex flex-col h-full bg-[#fafafa] dark:bg-[#090b14] relative">
            {/* Top Config & Countdown Section */}
            <div className="flex items-center justify-between px-6 py-4 bg-white dark:bg-[#0b0e17] border-b border-gray-100 dark:border-white/5 z-10">
                 <div className="flex items-center gap-3">
                     <div className="px-3 h-10 rounded-full flex items-center justify-center font-bold text-sm shrink-0 bg-gradient-to-br from-blue-400 to-blue-600 text-white shadow-sm">
                         {job.symbol}
                     </div>
                     <div>
                         <h2 className="text-[15px] font-bold text-default-900 dark:text-white leading-tight">
                             {job.symbol}
                         </h2>
                         <p className="text-xs text-gray-500 font-medium">
                             Analysis Interval: {job.interval} min
                         </p>
                     </div>
                 </div>
                 <div className="flex bg-gray-100 dark:bg-[#1a1d27] p-1 rounded-lg">
                     <button 
                         onClick={() => setActiveView('server')}
                         className={`px-3 py-1.5 flex items-center justify-center gap-2 text-[12px] font-semibold rounded-md transition-all ${activeView === 'server' ? 'bg-white dark:bg-[#2d313e] shadow-sm text-gray-800 dark:text-blue-400' : 'text-gray-500 hover:text-gray-700 dark:text-gray-400 dark:hover:text-gray-200'}`}
                     >
                         <span>Server คำนวณ</span>
                         <CountdownBadge interval={1} lastRunTime={null} isRunning={isM1Running} enabled={job.enabled !== false} marketClosed={closedMap[job.symbol]} />
                     </button>
                     <button 
                         onClick={() => setActiveView('ai')}
                         className={`px-3 py-1.5 flex items-center justify-center gap-2 text-[12px] font-semibold rounded-md transition-all ${activeView === 'ai' ? 'bg-white dark:bg-[#2d313e] shadow-sm text-gray-800 dark:text-blue-400' : 'text-gray-500 hover:text-gray-700 dark:text-gray-400 dark:hover:text-gray-200'}`}
                     >
                         <span>ส่งข้อมูล AI คำนวณ</span>
                         <CountdownBadge interval={job.interval} lastRunTime={lastRunTime} isRunning={isAiRunning} enabled={job.enabled !== false} marketClosed={closedMap[job.symbol]} />
                     </button>
                 </div>
            </div>
            
            
            {/* Main Content Area */}
            {activeView === 'ai' ? (
                <div 
                    className="flex-1 overflow-y-auto p-4 md:p-6 space-y-8 custom-scrollbar pb-24"
                    onMouseEnter={() => setIsHovering(true)}
                    onMouseLeave={() => setIsHovering(false)}
                >
                    {filteredVerboseLogs.length > 0 ? (
                        filteredVerboseLogs.map((log: any, i: number) => (
                            <div key={`verbose-${i}`} className="flex flex-col gap-6 w-full">
                                {/* Server Message (Prompt / ข้อมูลที่ส่งให้) - LEFT */}
                                <div className="flex items-start gap-4 w-full pr-16 md:pr-24">
                                    <div className="w-10 h-10 rounded-full bg-blue-100 dark:bg-blue-900/30 flex items-center justify-center shrink-0 border border-blue-200 dark:border-blue-800 shadow-sm">
                                        <LuImagePlus className="text-blue-600 dark:text-blue-400" size={18} />
                                    </div>
                                    <div 
                                        className="bg-white dark:bg-[#1a1d27] border border-gray-100 dark:border-white/5 text-gray-800 dark:text-gray-300 rounded-2xl p-5 shadow-sm relative cursor-pointer hover:ring-2 hover:ring-blue-500/20 transition-all"
                                        onClick={() => setSelectedLog(log)}
                                    >
                                        <div className="text-[11px] font-bold text-gray-400 mb-2 uppercase tracking-wide">
                                            ข้อมูลที่ส่งให้ทำการวิเคราะห์ (คลิกเพื่อดูฉบับเต็ม)
                                        </div>
                                        <pre className="text-[13px] font-sans whitespace-pre-wrap leading-relaxed">
                                            {log?.prompt || ''}
                                        </pre>
                                    </div>
                                </div>

                                {/* AI Agent Message (Response / ข้อมูลที่ตอบกลับ) - RIGHT */}
                                <div className="flex items-start justify-end gap-4 w-full pl-16 md:pl-24">
                                    <div 
                                        className="bg-white dark:bg-[#1a1d27] border border-gray-100 dark:border-white/5 text-gray-800 dark:text-gray-200 rounded-2xl p-5 shadow-sm relative text-right cursor-pointer hover:ring-2 hover:ring-indigo-500/20 transition-all"
                                        onClick={() => setSelectedLog(log)}
                                    >
                                        <div className="text-[11px] font-bold text-indigo-400 mb-2 uppercase tracking-wide">
                                            AI ตอบกลับ ({log?.agent || 'Unknown'}) • {new Date(log?.timestamp || Date.now()).toLocaleTimeString()} (คลิกเพื่อดูฉบับเต็ม)
                                        </div>
                                        <pre className="text-[13px] font-sans whitespace-pre-wrap leading-relaxed overflow-x-auto text-left">
                                            {log?.response || ''}
                                        </pre>
                                    </div>
                                    <div className="w-10 h-10 rounded-full bg-indigo-500 flex items-center justify-center shrink-0 text-white font-bold tracking-tight shadow-md">
                                        AI
                                    </div>
                                </div>
                            </div>
                        ))
                    ) : (
                        <div className="flex flex-col items-center justify-center h-full text-gray-400">
                            <span className="text-sm font-semibold">No active AI logs yet.</span>
                            <span className="text-xs mt-1 text-gray-500">Wait for the next analyze interval to see live communication.</span>
                        </div>
                    )}
                    <div ref={logsEndRef} />
                </div>
            ) : (
                <div 
                    className="flex-1 overflow-y-auto p-4 md:p-6 space-y-6 custom-scrollbar pb-6"
                    onMouseEnter={() => setIsHovering(true)}
                    onMouseLeave={() => setIsHovering(false)}
                >
                    {logsM1.length > 0 ? (
                        logsM1.map((log: any, i) => {
                            const isRunning = log?.status === 'running';
                            
                            return (
                                <div key={`m1-${i}`} className={`flex items-end gap-3 w-full ${isRunning ? 'pr-16 md:pr-24' : 'justify-end pl-16 md:pl-24'}`}>
                                    {/* Left Side: System Trigger / Data Sent */}
                                    {isRunning && (
                                        <div className="w-9 h-9 rounded-full bg-gray-100 dark:bg-white/10 flex items-center justify-center shrink-0 border border-gray-200 dark:border-white/5 shadow-sm">
                                            <LuActivity className="text-gray-500 dark:text-gray-400" size={16} />
                                        </div>
                                    )}
                                    
                                    {/* Chat Bubble */}
                                    <div 
                                        className={`bg-white dark:bg-[#1a1d27] border border-gray-100 dark:border-white/5 rounded-[20px] p-4 shadow-sm relative w-fit max-w-full cursor-pointer hover:ring-2 transition-all ${isRunning ? 'rounded-bl-[4px] text-left hover:ring-gray-300/50 dark:hover:ring-gray-600/50' : 'rounded-br-[4px] text-right hover:ring-emerald-500/20 dark:hover:ring-emerald-500/20'}`}
                                        onClick={() => setSelectedLog(log)}
                                    >
                                        <div className={`text-[10px] font-bold mb-1 uppercase tracking-wider ${isRunning ? 'text-gray-400' : (log?.status === 'error' ? 'text-red-400' : 'text-emerald-500')}`}>
                                            {isRunning ? 'SYSTEM (M1)' : 'SERVER RESPONSE'} • {new Date(log?.timestamp || Date.now()).toLocaleTimeString()} (คลิกเพื่ออ่านตัวเต็ม)
                                        </div>
                                        <div className={`text-[13px] font-sans leading-relaxed break-words whitespace-pre-wrap ${isRunning ? 'text-gray-600 dark:text-gray-300' : 'text-gray-800 dark:text-gray-100 font-medium'}`}>
                                            {log?.message || ''}
                                        </div>
                                    </div>

                                    {/* Right Side: Server Response / Data Replied */}
                                    {!isRunning && (
                                        <div className={`w-9 h-9 rounded-full flex items-center justify-center shrink-0 text-white shadow-sm border ${log?.status === 'error' ? 'bg-red-50 text-red-500 border-red-200 dark:bg-red-500/10 dark:border-red-500/20' : 'bg-emerald-50 text-emerald-500 border-emerald-200 dark:bg-emerald-500/10 dark:border-emerald-500/20'}`}>
                                            <LuServer size={16} />
                                        </div>
                                    )}
                                </div>
                            );
                        })
                    ) : (
                        <div className="text-center text-gray-500 py-10 font-sans">กำลังรอข้อมูล Server M1 FAST-TRACK...</div>
                    )}
                    <div ref={logsEndRef} />
                </div>
            )}



            {/* Selected Log Full View Modal */}
            {selectedLog && (
                <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 backdrop-blur-sm p-4 md:p-8">
                    <div className="bg-white dark:bg-[#0B101E] border border-gray-200 dark:border-white/10 rounded-2xl shadow-2xl w-full max-w-4xl max-h-[90vh] flex flex-col animate-in fade-in zoom-in-95 duration-200 relative">
                        <div className="flex items-center justify-between p-4 border-b border-gray-100 dark:border-white/5">
                            <h3 className="text-lg font-bold text-gray-800 dark:text-gray-100 flex items-center gap-2">
                                ข้อมูลดิบแบบเต็ม (Raw Data)
                            </h3>
                            <button 
                                onClick={() => setSelectedLog(null)}
                                className="w-8 h-8 flex items-center justify-center bg-gray-100 hover:bg-gray-200 dark:bg-white/5 dark:hover:bg-white/10 text-gray-500 rounded-full transition-colors"
                            >
                                <LuX size={18} />
                            </button>
                        </div>
                        <div className="flex-1 overflow-y-auto p-4 custom-scrollbar bg-gray-50 dark:bg-[#06080F]">
                            <pre className="text-[13px] font-mono text-gray-700 dark:text-emerald-400 whitespace-pre-wrap leading-relaxed break-words">
                                {JSON.stringify(selectedLog, null, 2)}
                            </pre>
                        </div>
                    </div>
                </div>
            )}
        </div>
    );
};
