import { useState } from 'react';
import { LuBot, LuX, LuCheck, LuBell, LuBrainCircuit, LuGlobe, LuActivity, LuCalendar, LuShield, LuClock } from 'react-icons/lu';

const agentConfig = [
  { key: 'news_hunter', name: 'วิเคราะห์ข่าวกรอง (News)', icon: <LuGlobe size={14} /> },
  { key: 'chart_analyst', name: 'วิเคราะห์เทคนิค (Chart)', icon: <LuActivity size={14} /> },
  { key: 'calendar', name: 'ติดตามปฏิทินศก. (Calendar)', icon: <LuCalendar size={14} /> },
  { key: 'risk_manager', name: 'บริหารความเสี่ยง (Risk)', icon: <LuShield size={14} /> },
];

const CustomSelect = ({ value, options, onChange, minWidth = '120px', className }: any) => (
    <select 
       value={value} 
       onChange={(e) => onChange(e.target.value)}
       className={className}
       style={{ minWidth }}
    >
        {options.map((opt: any) => <option key={opt.value} value={opt.value}>{opt.label}</option>)}
    </select>
);

export const SetupFormModal = ({ job, trackedSymbols, onClose, onSave, onDelete }: any) => {
    const [localJob, setLocalJob] = useState({ ...job });
    
    const trackedSymbolOptions = trackedSymbols.map((s: string) => ({ label: s, value: s }));

    const handleToggleAgent = (agentKey: string) => {
        const disabled = localJob.disabled_agents || [];
        if (disabled.includes(agentKey)) {
            setLocalJob({ ...localJob, disabled_agents: disabled.filter((a: string) => a !== agentKey) });
        } else {
            setLocalJob({ ...localJob, disabled_agents: [...disabled, agentKey] });
        }
    };

    return (
        <div className="fixed inset-0 z-[60] flex items-center justify-center bg-black/80 backdrop-blur-md px-4">
            <div className="w-full max-w-lg rounded-3xl bg-white dark:bg-[#090C15] border border-default-200 dark:border-white/10 shadow-2xl overflow-hidden animate-in slide-in-from-bottom-4">
                {/* Header */}
                <div className="p-5 border-b border-default-200 dark:border-white/5 flex justify-between items-center bg-gradient-to-r from-blue-50 to-transparent dark:from-blue-900/20">
                    <h3 className="text-sm font-black text-default-900 dark:text-white flex items-center gap-2 uppercase tracking-widest">
                        <LuBot className="size-5 text-blue-500" />
                        AI Trade Setup
                    </h3>
                    <button onClick={onClose} className="text-gray-500 hover:text-red-500 transition-colors">
                        <LuX className="size-5" />
                    </button>
                </div>

                <div className="p-5 overflow-y-auto max-h-[70vh]">
                    {/* form fields (copied mostly from old code) */}
                    <div className="grid grid-cols-2 gap-4 mb-6">
                        <div className="flex flex-col gap-1.5">
                            <label className="text-[10px] font-bold text-gray-500 uppercase tracking-widest">Symbol</label>
                            <CustomSelect
                                value={localJob.symbol}
                                options={trackedSymbolOptions}
                                onChange={(val: string) => setLocalJob({ ...localJob, symbol: val })}
                                className="w-full px-3 py-2.5 rounded-xl bg-white dark:bg-[#131826] border border-default-200 dark:border-white/10 hover:border-blue-500/50 text-xs font-bold text-default-800 dark:text-gray-200 focus:outline-none shadow-sm"
                            />
                        </div>

                        <div className="flex flex-col gap-1.5">
                            <label className="text-[10px] font-bold text-gray-500 uppercase tracking-widest">Lot Size</label>
                            <input
                                type="number" min="0.01" step="0.01"
                                value={localJob.lot_size}
                                onChange={(e) => setLocalJob({ ...localJob, lot_size: parseFloat(e.target.value) || 0.01 })}
                                className="w-full px-3 py-2.5 text-xs font-bold rounded-xl bg-white dark:bg-[#131826] border border-default-200 dark:border-white/10"
                            />
                        </div>
                    </div>

                    <div className="flex items-center justify-between p-4 mb-6 rounded-xl bg-default-100/50 dark:bg-white/5 border border-default-200 dark:border-white/5">
                        <div className="flex items-center gap-3">
                            <LuBell className="size-5 text-blue-500" />
                            <div>
                                <p className="text-xs font-bold text-default-700 dark:text-gray-200">Telegram Alerts</p>
                                <p className="text-[10px] text-gray-500">Notify when order opens/closes</p>
                            </div>
                        </div>
                        <button onClick={() => setLocalJob({ ...localJob, telegram_alert: !localJob.telegram_alert })} className={`relative inline-flex h-6 w-11 shrink-0 cursor-pointer items-center justify-center rounded-full transition-colors ${localJob.telegram_alert ? 'bg-blue-500' : 'bg-gray-300 dark:bg-gray-700'}`}>
                            <span className={`inline-block h-4 w-4 transform rounded-full bg-white transition duration-200 ease-in-out ${localJob.telegram_alert ? 'translate-x-2.5' : '-translate-x-2.5'}`} />
                        </button>
                    </div>

                    <div className="mb-6">
                        <label className="text-[10px] font-bold text-gray-500 uppercase tracking-widest border-b border-default-200 dark:border-white/5 pb-2 mb-3 flex items-center gap-2">
                            <LuBrainCircuit className="text-blue-500 size-4" />
                            AI Agents (Pipeline)
                        </label>
                        <div className="flex flex-col gap-2">
                            {agentConfig.map((agent) => {
                                const disabled = localJob.disabled_agents || [];
                                const isEnabled = !disabled.includes(agent.key);
                                return (
                                    <div key={agent.key} className="flex items-center justify-between p-3 rounded-xl bg-white dark:bg-[#131826] border border-default-200 dark:border-white/5">
                                        <div className="flex items-center gap-2 text-xs font-bold text-default-700 dark:text-gray-300">
                                            <span className="text-blue-500">{agent.icon}</span>
                                            {agent.name}
                                        </div>
                                        <button onClick={() => handleToggleAgent(agent.key)} className={`relative inline-flex h-5 w-9 shrink-0 cursor-pointer items-center justify-center rounded-full transition-colors ${isEnabled ? 'bg-blue-500' : 'bg-gray-300 dark:bg-gray-700'}`}>
                                            <span className={`inline-block h-3.5 w-3.5 transform rounded-full bg-white transition ${isEnabled ? 'translate-x-[6px]' : '-translate-x-[6px]'}`} />
                                        </button>
                                    </div>
                                )
                            })}
                        </div>
                    </div>

                    <div className="grid grid-cols-2 gap-4 mb-4">
                        <div className="flex flex-col gap-1.5 col-span-2">
                            <label className="text-[10px] font-bold text-gray-500 uppercase tracking-widest">Target Mode</label>
                            <div className="flex rounded-xl overflow-hidden border border-default-200 dark:border-white/5 p-1 bg-default-100/50 dark:bg-[#131826]">
                                {['usd', 'pips', 'none'].map((mode) => (
                                    <button key={mode} onClick={() => setLocalJob({ ...localJob, tp_sl_mode: mode })} className={`flex-1 text-[10px] font-bold uppercase py-2 rounded-lg transition-all ${localJob.tp_sl_mode === mode || (!localJob.tp_sl_mode && mode==='none') ? 'bg-blue-500 text-white shadow-sm' : 'text-gray-500 hover:text-default-700 dark:hover:text-gray-300'}`}>
                                        {mode}
                                    </button>
                                ))}
                            </div>
                        </div>

                        {(localJob.tp_sl_mode && localJob.tp_sl_mode !== 'none') && (
                            <>
                                <div className="flex flex-col gap-1.5">
                                    <label className="text-[10px] font-bold text-gray-500 uppercase tracking-widest">{localJob.tp_sl_mode === 'usd' ? 'TP ($)' : 'TP (Pips)'}</label>
                                    <input type="number" min="0" value={localJob.tp_value || 0} onChange={(e) => setLocalJob({ ...localJob, tp_value: parseFloat(e.target.value) || 0 })} className="w-full px-3 py-2.5 text-xs font-bold rounded-xl bg-white dark:bg-[#131826] border border-default-200 dark:border-white/10 text-emerald-600" />
                                </div>
                                <div className="flex flex-col gap-1.5">
                                    <label className="text-[10px] font-bold text-gray-500 uppercase tracking-widest">SL (Pips)</label>
                                    <input type="number" min="0" value={localJob.sl_value || 0} onChange={(e) => setLocalJob({ ...localJob, sl_value: parseFloat(e.target.value) || 0 })} className="w-full px-3 py-2.5 text-xs font-bold rounded-xl bg-white dark:bg-[#131826] border border-default-200 dark:border-white/10 text-orange-600" />
                                </div>
                            </>
                        )}
                        
                        <div className="flex flex-col gap-1.5 justify-center mt-2">
                           <label className="text-[10px] font-bold text-gray-500 uppercase tracking-widest mb-1">Auto-Execute (AI Only)</label>
                           <button onClick={() => setLocalJob({ ...localJob, auto_trade: !localJob.auto_trade })} className={`relative inline-flex h-6 w-11 shrink-0 cursor-pointer items-center justify-center rounded-full transition-colors ${localJob.auto_trade ? 'bg-emerald-500 shadow-[0_0_15px_rgba(16,185,129,0.3)]' : 'bg-gray-200 dark:bg-gray-800'}`}>
                               <span className={`inline-block h-4 w-4 transform rounded-full bg-white shadow-md transition ${localJob.auto_trade ? 'translate-x-2.5' : '-translate-x-2.5'}`} />
                           </button>
                        </div>
                        <div className="flex flex-col gap-1.5 justify-center mt-2">
                           <label className="text-[10px] font-bold text-gray-500 uppercase tracking-widest"><LuClock className="inline size-3 mr-1" />Scan Every (min)</label>
                           <input type="number" min="1" step="1" value={localJob.interval} onChange={(e) => setLocalJob({ ...localJob, interval: parseInt(e.target.value) || 5 })} className="w-full px-3 py-2.5 text-xs font-bold rounded-xl bg-white dark:bg-[#131826] border border-default-200 dark:border-white/10" />
                        </div>
                    </div>
                </div>

                <div className="p-5 border-t border-default-200 dark:border-white/5 bg-gray-50 dark:bg-[#0A0D14] flex justify-between items-center">
                    <button onClick={onDelete} className="text-xs font-bold text-red-500 hover:text-red-600 px-4 py-2 hover:bg-red-50 dark:hover:bg-red-500/10 rounded-xl transition-colors">
                        ลบ Setup นี้
                    </button>
                    <button onClick={() => onSave({ ...localJob, is_draft: false })} className="flex items-center gap-2 bg-blue-600 hover:bg-blue-500 text-white text-xs font-black px-6 py-3 rounded-xl transition-all shadow-lg hover:shadow-blue-500/50 tracking-wider">
                        <LuCheck size={16} /> BIND AI AGENT
                    </button>
                </div>
            </div>
        </div>
    );
};
