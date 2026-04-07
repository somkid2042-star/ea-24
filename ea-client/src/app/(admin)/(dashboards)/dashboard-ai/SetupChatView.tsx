import { useEffect, useRef, useState } from 'react';
import { LuImagePlus, LuActivity, LuServer } from 'react-icons/lu';
import { IoSend } from 'react-icons/io5';
import type { AiLog, AgentStatusMap } from './AgentPanel';

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
    job, verboseLogs, logsM1BySymbol
}: SetupChatViewProps) => {
    const [activeView, setActiveView] = useState<'server' | 'ai'>('ai');
    const [isHovering, setIsHovering] = useState(false);
    const logsM1 = logsM1BySymbol[job.symbol] || [];
    
    const logsEndRef = useRef<HTMLDivElement>(null);

    useEffect(() => {
        if (!isHovering) {
            logsEndRef.current?.scrollIntoView({ behavior: 'smooth' });
        }
    }, [verboseLogs, logsM1, activeView, isHovering]);

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
                         className={`px-3 py-1.5 text-[12px] font-semibold rounded-md transition-all ${activeView === 'server' ? 'bg-white dark:bg-[#2d313e] shadow-sm text-gray-800 dark:text-blue-400' : 'text-gray-500 hover:text-gray-700 dark:text-gray-400 dark:hover:text-gray-200'}`}
                     >
                         Server คำนวณ
                     </button>
                     <button 
                         onClick={() => setActiveView('ai')}
                         className={`px-3 py-1.5 text-[12px] font-semibold rounded-md transition-all ${activeView === 'ai' ? 'bg-white dark:bg-[#2d313e] shadow-sm text-gray-800 dark:text-blue-400' : 'text-gray-500 hover:text-gray-700 dark:text-gray-400 dark:hover:text-gray-200'}`}
                     >
                         ส่งข้อมูล AI คำนวณ
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
                    {verboseLogs && verboseLogs.length > 0 ? (
                        verboseLogs.map((log: any, i) => (
                            <div key={`verbose-${i}`} className="flex flex-col gap-6 w-full">
                                {/* Server Message (Prompt / ข้อมูลที่ส่งให้) - LEFT */}
                                <div className="flex items-start gap-4 w-full pr-16 md:pr-24">
                                    <div className="w-10 h-10 rounded-full bg-blue-100 dark:bg-blue-900/30 flex items-center justify-center shrink-0 border border-blue-200 dark:border-blue-800 shadow-sm">
                                        <LuImagePlus className="text-blue-600 dark:text-blue-400" size={18} />
                                    </div>
                                    <div className="bg-white dark:bg-[#1a1d27] border border-gray-100 dark:border-white/5 text-gray-800 dark:text-gray-300 rounded-2xl p-5 shadow-sm relative">
                                        <div className="text-[11px] font-bold text-gray-400 mb-2 uppercase tracking-wide">
                                            ข้อมูลที่ส่งให้ทำการวิเคราะห์
                                        </div>
                                        <pre className="text-[13px] font-sans whitespace-pre-wrap leading-relaxed">
                                            {log?.prompt || ''}
                                        </pre>
                                    </div>
                                </div>

                                {/* AI Agent Message (Response / ข้อมูลที่ตอบกลับ) - RIGHT */}
                                <div className="flex items-start justify-end gap-4 w-full pl-16 md:pl-24">
                                    <div className="bg-white dark:bg-[#1a1d27] border border-gray-100 dark:border-white/5 text-gray-800 dark:text-gray-200 rounded-2xl p-5 shadow-sm relative text-right">
                                        <div className="text-[11px] font-bold text-indigo-400 mb-2 uppercase tracking-wide">
                                            AI ตอบกลับ ({log?.agent || 'Unknown'}) • {new Date(log?.timestamp || Date.now()).toLocaleTimeString()}
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
                                    <div className={`bg-white dark:bg-[#1a1d27] border border-gray-100 dark:border-white/5 rounded-[20px] p-4 shadow-sm relative w-fit max-w-full ${isRunning ? 'rounded-bl-[4px] text-left' : 'rounded-br-[4px] text-right'}`}>
                                        <div className={`text-[10px] font-bold mb-1 uppercase tracking-wider ${isRunning ? 'text-gray-400' : (log?.status === 'error' ? 'text-red-400' : 'text-emerald-500')}`}>
                                            {isRunning ? 'SYSTEM (M1)' : 'SERVER RESPONSE'} • {new Date(log?.timestamp || Date.now()).toLocaleTimeString()}
                                        </div>
                                        <div className={`text-[13px] font-sans leading-relaxed break-words ${isRunning ? 'text-gray-600 dark:text-gray-300' : 'text-gray-800 dark:text-gray-100 font-medium'}`}>
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

            {/* Input Box Area (Fake, just to look like UI) */}
            {activeView === 'ai' && (
            <div className="absolute bottom-0 left-0 w-full bg-[#f8f9fa] dark:bg-[#090b14] p-4 md:px-6 pt-2">
                <div className="flex items-center gap-2 w-full max-w-4xl mx-auto">
                    <div className="flex-1 bg-white dark:bg-[#1a1d27] border border-gray-200 dark:border-white/10 rounded-lg flex items-center px-4 py-3 shadow-sm focus-within:border-blue-400 transition-colors">
                        <input 
                            type="text" 
                            disabled
                            placeholder="Data stream from EA server..." 
                            className="bg-transparent border-none outline-none w-full text-sm text-gray-700 dark:text-gray-300 cursor-not-allowed" 
                        />
                    </div>

                    <button className="w-11 h-11 flex items-center justify-center bg-blue-50 dark:bg-white/5 hover:bg-blue-100 dark:hover:bg-white/10 text-blue-500 rounded-lg transition-colors shrink-0">
                        <LuImagePlus size={20} />
                    </button>
                    <button className="h-11 px-6 flex items-center justify-center gap-2 bg-blue-500 hover:bg-blue-600 text-white font-semibold text-sm rounded-lg shadow-sm shadow-blue-500/20 transition-all shrink-0 cursor-not-allowed">
                        <IoSend size={16} /> Send
                    </button>
                </div>
            </div>
            )}
        </div>
    );
};
