import { useState } from 'react';
import { LuBot, LuX, LuCheck, LuBrainCircuit, LuServer, LuSparkles, LuClock, LuMessageCircle, LuZap, LuScaling } from 'react-icons/lu';

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
                    {/* Symbol + Lot */}
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

                    {/* Pipeline v8 Diagram */}
                    <div className="mb-6">
                        <label className="text-[10px] font-bold text-gray-500 uppercase tracking-widest border-b border-default-200 dark:border-white/5 pb-2 mb-3 flex items-center gap-2">
                            <LuBrainCircuit className="text-blue-500 size-4" />
                            Pipeline v8 — 3-Stage Engine
                        </label>
                        <div className="flex items-center gap-2 py-3">
                            <div className="flex-1 rounded-xl bg-blue-500/5 border border-blue-500/20 p-3 text-center">
                                <LuServer className="size-4 text-blue-500 mx-auto mb-1" />
                                <p className="text-[10px] font-bold text-gray-700 dark:text-gray-300">Server Scan</p>
                                <p className="text-[8px] text-gray-500">10 กลยุทธ์ x 5 TF</p>
                            </div>
                            <span className="text-gray-300 dark:text-gray-600 text-xs shrink-0">-&gt;</span>
                            <div className="flex-1 rounded-xl bg-purple-500/5 border border-purple-500/20 p-3 text-center">
                                <LuSparkles className="size-4 text-purple-500 mx-auto mb-1" />
                                <p className="text-[10px] font-bold text-gray-700 dark:text-gray-300">Gemma 4</p>
                                <p className="text-[8px] text-gray-500">ตรวจสอบ + ประวัติ</p>
                            </div>
                            <span className="text-gray-300 dark:text-gray-600 text-xs shrink-0">-&gt;</span>
                            <div className="flex-1 rounded-xl bg-amber-500/5 border border-amber-500/20 p-3 text-center">
                                <LuBrainCircuit className="size-4 text-amber-500 mx-auto mb-1" />
                                <p className="text-[10px] font-bold text-gray-700 dark:text-gray-300">Gemini</p>
                                <p className="text-[8px] text-gray-500">ยืนยันขั้นสุดท้าย</p>
                            </div>
                        </div>
                    </div>

                    {/* Discord Alert */}
                    <div className="flex items-center justify-between p-4 mb-6 rounded-xl bg-default-100/50 dark:bg-white/5 border border-default-200 dark:border-white/5">
                        <div className="flex items-center gap-3">
                            <LuMessageCircle className="size-5 text-indigo-500" />
                            <div>
                                <p className="text-xs font-bold text-default-700 dark:text-gray-200">Discord Alerts</p>
                                <p className="text-[10px] text-gray-500">แจ้งเตือนเมื่อเปิด/ปิดออเดอร์</p>
                            </div>
                        </div>
                        <button onClick={() => setLocalJob({ ...localJob, discord_alert: !localJob.discord_alert })} className={`relative inline-flex h-6 w-11 shrink-0 cursor-pointer items-center justify-center rounded-full transition-colors ${localJob.discord_alert ? 'bg-indigo-500' : 'bg-gray-300 dark:bg-gray-700'}`}>
                            <span className={`inline-block h-4 w-4 transform rounded-full bg-white transition duration-200 ease-in-out ${localJob.discord_alert ? 'translate-x-2.5' : '-translate-x-2.5'}`} />
                        </button>
                    </div>

                    {/* Lot Scale */}
                    <div className="flex items-center justify-between p-4 mb-6 rounded-xl bg-default-100/50 dark:bg-white/5 border border-default-200 dark:border-white/5">
                        <div className="flex items-center gap-3">
                            <LuScaling className="size-5 text-emerald-500" />
                            <div>
                                <p className="text-xs font-bold text-default-700 dark:text-gray-200">Lot Scaling</p>
                                <p className="text-[10px] text-gray-500">ปรับ Lot ตาม Confidence (x2, x3)</p>
                            </div>
                        </div>
                        <button onClick={() => setLocalJob({ ...localJob, lot_scale: !localJob.lot_scale })} className={`relative inline-flex h-6 w-11 shrink-0 cursor-pointer items-center justify-center rounded-full transition-colors ${localJob.lot_scale ? 'bg-emerald-500' : 'bg-gray-300 dark:bg-gray-700'}`}>
                            <span className={`inline-block h-4 w-4 transform rounded-full bg-white transition duration-200 ease-in-out ${localJob.lot_scale ? 'translate-x-2.5' : '-translate-x-2.5'}`} />
                        </button>
                    </div>

                    {/* TP/SL + Settings */}
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
                           <label className="text-[10px] font-bold text-gray-500 uppercase tracking-widest mb-1 flex items-center gap-1">
                              <LuZap className="size-3 text-emerald-500" />
                              Auto-Execute
                           </label>
                           <button onClick={() => setLocalJob({ ...localJob, auto_trade: !localJob.auto_trade })} className={`relative inline-flex h-6 w-11 shrink-0 cursor-pointer items-center justify-center rounded-full transition-colors ${localJob.auto_trade ? 'bg-emerald-500 shadow-[0_0_15px_rgba(16,185,129,0.3)]' : 'bg-gray-200 dark:bg-gray-800'}`}>
                               <span className={`inline-block h-4 w-4 transform rounded-full bg-white shadow-md transition ${localJob.auto_trade ? 'translate-x-2.5' : '-translate-x-2.5'}`} />
                           </button>
                        </div>
                        <div className="flex flex-col gap-1.5 justify-center mt-2">
                           <label className="text-[10px] font-bold text-gray-500 uppercase tracking-widest flex items-center gap-1">
                              <LuClock className="size-3" />
                              Scan Interval (min)
                           </label>
                           <input type="number" min="1" step="1" value={localJob.interval} onChange={(e) => setLocalJob({ ...localJob, interval: parseInt(e.target.value) || 5 })} className="w-full px-3 py-2.5 text-xs font-bold rounded-xl bg-white dark:bg-[#131826] border border-default-200 dark:border-white/10" />
                        </div>
                    </div>
                </div>

                <div className="p-5 border-t border-default-200 dark:border-white/5 bg-gray-50 dark:bg-[#0A0D14] flex justify-between items-center">
                    <button onClick={onDelete} className="text-xs font-bold text-red-500 hover:text-red-600 px-4 py-2 hover:bg-red-50 dark:hover:bg-red-500/10 rounded-xl transition-colors">
                        ลบ Setup นี้
                    </button>
                    <button onClick={() => onSave({ ...localJob, is_draft: false })} className="flex items-center gap-2 bg-blue-600 hover:bg-blue-500 text-white text-xs font-black px-6 py-3 rounded-xl transition-all shadow-lg hover:shadow-blue-500/50 tracking-wider">
                        <LuCheck size={16} /> SAVE
                    </button>
                </div>
            </div>
        </div>
    );
};
