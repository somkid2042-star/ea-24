import { LuActivity, LuPencil } from 'react-icons/lu';

const translateObj = { "BUY": "ซื้อ (BUY)", "SELL": "ขาย (SELL)", "HOLD": "รอดูท่าที (HOLD)" };

export const JobSidebarCard = ({ job, isSelected, onClick, onEdit, result, lastRunTime, agentStatusM1Map }: any) => {

    const decisionObj = result?.final_decision;
    const finalDecision = decisionObj && (translateObj as any)[decisionObj.toUpperCase()] 
                          ? (translateObj as any)[decisionObj.toUpperCase()] 
                          : decisionObj || 'AWAITING PROCESSING';

    const isRunning = agentStatusM1Map?.orchestrator === 'running';

    return (
        <div 
           className={`relative flex items-center gap-3 px-4 py-3 cursor-pointer transition-colors ${isSelected ? 'bg-gray-200 dark:bg-white/10' : 'hover:bg-gray-100 dark:hover:bg-white/5'}`}
           onClick={onClick}
        >
           {/* Avatar */}
           <div className="relative">
               <div className={`w-12 h-12 rounded-full flex items-center justify-center font-bold text-lg shrink-0 ${job.enabled !== false ? 'bg-gradient-to-br from-blue-400 to-blue-600 text-white' : 'bg-gray-200 text-gray-500'}`}>
                   {job.symbol.substring(0, 1)}
               </div>
               <div className={`absolute bottom-0 right-0 w-3 h-3 rounded-full border-2 border-white dark:border-[#090C15] ${job.enabled !== false ? 'bg-emerald-500' : 'bg-red-500'}`} />
           </div>

           {/* Content */}
           <div className="flex-1 min-w-0">
               <div className="flex justify-between items-baseline mb-0.5">
                   <h3 className="text-[15px] font-bold text-default-900 dark:text-gray-100 truncate pr-2">
                       {job.symbol}
                   </h3>
                   <div className="flex items-center gap-2">
                     <button onClick={(e) => { e.stopPropagation(); onEdit(); }} className="text-gray-400 hover:text-blue-500 transition-colors">
                        <LuPencil size={12} />
                     </button>
                     <div className="text-[11px] text-gray-500 font-medium">
                         M{job.interval}
                     </div>
                   </div>
               </div>
               
               <p className="text-[13px] text-gray-500 dark:text-gray-400 truncate w-full pr-4 flex items-center gap-1.5">
                   <LuActivity size={12} className={
                       finalDecision.includes('BUY') ? 'text-emerald-500' :
                       finalDecision.includes('SELL') ? 'text-red-500' : 'text-amber-500'
                   } />
                   {finalDecision === 'AWAITING PROCESSING' ? 'Waiting to analyze...' : finalDecision}
               </p>
           </div>
        </div>
    );
};
