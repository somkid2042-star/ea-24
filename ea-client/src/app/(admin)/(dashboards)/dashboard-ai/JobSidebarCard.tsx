import { LuActivity, LuPencil, LuLoader } from 'react-icons/lu';

export const JobSidebarCard = ({ job, isSelected, onClick, onEdit, result, agentStatusM1Map }: any) => {

    const decision = result?.final_decision || result?.decision;
    const confidence = result?.confidence;
    
    // Check if any stage is running
    const agentStatuses = agentStatusM1Map || {};
    const isRunning = Object.values(agentStatuses).some((s: any) => s === 'running');

    const statusLabel = decision ? (
        decision === 'BUY' ? 'BUY Signal' :
        decision === 'SELL' ? 'SELL Signal' :
        decision === 'HOLD' ? 'HOLD' : decision
    ) : isRunning ? 'กำลังวิเคราะห์...' : 'รอวิเคราะห์...';

    const statusColor = decision === 'BUY' ? 'text-emerald-500' :
                        decision === 'SELL' ? 'text-red-500' :
                        decision === 'HOLD' ? 'text-amber-500' :
                        isRunning ? 'text-blue-500' : 'text-gray-400';

    return (
        <div 
           className={`flex items-center gap-3 px-4 py-3.5 cursor-pointer transition-all border-l-2 ${
             isSelected 
               ? 'bg-blue-50/80 dark:bg-blue-500/5 border-l-blue-500' 
               : 'hover:bg-gray-50 dark:hover:bg-white/[0.02] border-l-transparent'
           }`}
           onClick={onClick}
        >
           {/* Avatar */}
           <div className="relative">
               <div className={`size-10 rounded-xl flex items-center justify-center font-bold text-sm shrink-0 ${
                 job.enabled !== false 
                   ? 'bg-gradient-to-br from-blue-500 to-indigo-600 text-white shadow-sm' 
                   : 'bg-gray-200 dark:bg-gray-800 text-gray-500'
               }`}>
                   {job.symbol.substring(0, 2)}
               </div>
               <div className={`absolute -bottom-0.5 -right-0.5 size-3 rounded-full border-2 border-white dark:border-[#0b0e17] ${
                 job.enabled !== false 
                   ? isRunning ? 'bg-blue-500 animate-pulse' : 'bg-emerald-500' 
                   : 'bg-gray-400'
               }`} />
           </div>

           {/* Content */}
           <div className="flex-1 min-w-0">
               <div className="flex justify-between items-center mb-0.5">
                   <h3 className="text-[14px] font-bold text-gray-900 dark:text-white truncate font-mono">
                       {job.symbol}
                   </h3>
                   <div className="flex items-center gap-1.5">
                     <button onClick={(e) => { e.stopPropagation(); onEdit(); }} className="text-gray-300 hover:text-blue-500 transition-colors p-0.5">
                        <LuPencil size={11} />
                     </button>
                     <span className="text-[10px] text-gray-400 font-medium bg-gray-100 dark:bg-white/5 px-1.5 py-0.5 rounded font-mono">
                         {job.interval}m
                     </span>
                   </div>
               </div>
               
               <div className={`text-[12px] font-medium truncate flex items-center gap-1.5 ${statusColor}`}>
                   {isRunning ? (
                     <LuLoader size={11} className="animate-spin shrink-0" />
                   ) : (
                     <LuActivity size={11} className="shrink-0" />
                   )}
                   {statusLabel}
                   {confidence && <span className="opacity-70 text-[10px]">({confidence}%)</span>}
               </div>
           </div>
        </div>
    );
};
