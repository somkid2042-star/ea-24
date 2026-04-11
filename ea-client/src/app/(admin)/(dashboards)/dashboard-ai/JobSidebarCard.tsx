import { LuActivity, LuLoader, LuShield, LuMoonStar } from 'react-icons/lu';

export const JobSidebarCard = ({ job, isSelected, onClick, result, agentStatusM1Map, isClosed }: any) => {

    const decision = result?.final_decision || result?.decision;
    const confidence = result?.confidence;
    
    // Check if any stage is running
    const agentStatuses = agentStatusM1Map || {};
    const isRunning = Object.values(agentStatuses).some((s: any) => s === 'running');
    
    // Check if Position Manager is active (has status entry)
    const isManaging = agentStatuses.position_manager === 'running' || agentStatuses.position_manager === 'done';

    // Market closed takes priority — no calculations should run
    const statusLabel = isClosed ? 'ตลาดปิด' :
        isManaging ? (
            agentStatuses.position_manager === 'running' ? 'กำลังดูแลออเดอร์...' : 'ดูแลออเดอร์เสร็จสิ้น'
        ) : decision ? (
            decision === 'BUY' ? 'BUY Signal' :
            decision === 'SELL' ? 'SELL Signal' :
            decision === 'HOLD' ? 'HOLD' : decision
        ) : isRunning ? 'กำลังวิเคราะห์...' : 'รอวิเคราะห์...';

    const statusColor = isClosed ? 'text-gray-400 dark:text-gray-500' :
                        isManaging ? 'text-cyan-500' :
                        decision === 'BUY' ? 'text-emerald-500' :
                        decision === 'SELL' ? 'text-red-500' :
                        decision === 'HOLD' ? 'text-amber-500' :
                        isRunning ? 'text-blue-500' : 'text-gray-400';

    const StatusIcon = isClosed ? LuMoonStar : isManaging ? LuShield : isRunning ? LuLoader : LuActivity;

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
                 isClosed
                   ? 'bg-gray-200 dark:bg-gray-800 text-gray-500'
                   : job.enabled !== false 
                     ? isManaging
                       ? 'bg-gradient-to-br from-cyan-500 to-teal-600 text-white shadow-sm'
                       : 'bg-gradient-to-br from-blue-500 to-indigo-600 text-white shadow-sm' 
                     : 'bg-gray-200 dark:bg-gray-800 text-gray-500'
               }`}>
                   {job.symbol.substring(0, 2)}
               </div>
               <div className={`absolute -bottom-0.5 -right-0.5 size-3 rounded-full border-2 border-white dark:border-[#0b0e17] ${
                 isClosed
                   ? 'bg-gray-400'
                   : job.enabled !== false 
                     ? isManaging ? 'bg-cyan-500 animate-pulse' : isRunning ? 'bg-blue-500 animate-pulse' : 'bg-emerald-500' 
                     : 'bg-gray-400'
               }`} />
           </div>

           {/* Content */}
           <div className="flex-1 min-w-0">
               <h3 className={`text-[13px] font-bold truncate font-mono mb-0.5 ${isClosed ? 'text-gray-400 dark:text-gray-500' : 'text-gray-900 dark:text-white'}`}>
                   {job.symbol}
               </h3>
               
               <div className={`text-[12px] font-medium truncate flex items-center gap-1.5 ${statusColor}`}>
                   <StatusIcon size={11} className={`shrink-0 ${!isClosed && (isRunning || (isManaging && agentStatuses.position_manager === 'running')) ? 'animate-spin' : ''}`} />
                   {statusLabel}
                   {!isClosed && confidence && <span className="opacity-70 text-[10px]">({confidence}%)</span>}
               </div>
           </div>
        </div>
    );
};
