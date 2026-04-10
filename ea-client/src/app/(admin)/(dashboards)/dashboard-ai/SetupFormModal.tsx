import { useState } from 'react';
import { LuBot, LuX, LuCheck, LuBrainCircuit, LuServer, LuSparkles, LuClock, LuMessageCircle, LuZap, LuScaling, LuChevronDown, LuPower, LuSettings2, LuBell, LuBellOff } from 'react-icons/lu';

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

// ── Available options ──
const ALL_STRATEGIES = [
    'SMC', 'ICT', 'Session Sniper', 'Fibonacci', 'Trend Rider',
    'Pullback Sniper', 'Bollinger Squeeze', 'Momentum Surge',
    'Reversal Catcher', 'Fractal Breakout',
];

const ALL_TIMEFRAMES = [
    { key: 'M5',  label: 'M5'  },
    { key: 'M15', label: 'M15' },
    { key: 'M30', label: 'M30' },
    { key: 'H1',  label: 'H1'  },
    { key: 'H4',  label: 'H4'  },
];

const GEMMA_MODELS = [
    { value: 'gemma-4-31b-it',   label: 'Gemma 4 31B' },
    { value: 'gemma-4-12b-it',   label: 'Gemma 4 12B' },
    { value: 'gemma-3-27b-it',   label: 'Gemma 3 27B' },
];

const GEMINI_MODELS = [
    { value: 'gemini-2.5-flash',           label: 'Gemini 2.5 Flash' },
    { value: 'gemini-2.5-pro',             label: 'Gemini 2.5 Pro' },
    { value: 'gemini-2.0-flash',           label: 'Gemini 2.0 Flash' },
    { value: 'gemini-2.0-flash-lite',      label: 'Gemini 2.0 Flash Lite' },
];

// ── Data sources for each AI stage ──
const GEMMA_DATA_SOURCES = [
    { key: 'indicators',     label: 'Indicators',      desc: 'RSI, EMA, BB, ATR, Momentum' },
    { key: 'trade_history',  label: 'Trade History',    desc: 'Win Rate, จำนวนเทรด 30 วัน' },
    { key: 'strategy_wr',    label: 'Strategy WR',      desc: 'Win Rate เฉพาะกลยุทธ์' },
    { key: 'session',        label: 'Session',          desc: 'Asia/London/NY WR' },
    { key: 'streak',         label: 'Streak',           desc: 'ชนะ/แพ้ติดต่อกัน' },
    { key: 'recent_orders',  label: 'Recent Orders',    desc: '5 ออเดอร์ล่าสุด' },
];

const GEMINI_DATA_SOURCES = [
    { key: 'trade_history',  label: 'Trade History',    desc: 'Win Rate, จำนวนเทรด' },
    { key: 'portfolio',      label: 'Portfolio',        desc: 'Balance, Equity, Drawdown' },
    { key: 'news',           label: 'News',             desc: 'วิเคราะห์ข่าวตลาด' },
    { key: 'calendar',       label: 'Calendar',         desc: 'ปฏิทินเศรษฐกิจ' },
    { key: 'chart_data',     label: 'Chart Data',       desc: 'OHLC Multi-Timeframe' },
    { key: 'gemma_result',   label: 'Gemma Result',     desc: 'ผลจาก Gemma Stage' },
];

// ── Toggle Chip ──
const ToggleChip = ({ label, active, onClick }: { label: string; active: boolean; onClick: () => void }) => (
    <button
        onClick={onClick}
        className={`px-2.5 py-1 rounded-lg text-[10px] font-bold transition-all duration-200 border ${
            active 
                ? 'bg-blue-500/10 border-blue-500/30 text-blue-600 dark:text-blue-400 shadow-sm' 
                : 'bg-transparent border-gray-200 dark:border-white/10 text-gray-400 hover:text-gray-600 dark:hover:text-gray-300 hover:border-gray-300 dark:hover:border-white/20'
        }`}
    >
        {label}
    </button>
);

// ── Stage Toggle Switch ──
const StageSwitch = ({ enabled, color, onToggle }: { enabled: boolean; color: string; onToggle: () => void }) => {
    const colorClass = color === 'purple' ? 'bg-purple-500' : color === 'amber' ? 'bg-amber-500' : 'bg-blue-500';
    return (
        <button
            onClick={(e) => { e.stopPropagation(); onToggle(); }}
            className={`relative inline-flex h-5 w-9 shrink-0 cursor-pointer items-center justify-center rounded-full transition-colors ${
                enabled ? colorClass : 'bg-gray-300 dark:bg-gray-700'
            }`}
        >
            <span className={`inline-block h-3.5 w-3.5 transform rounded-full bg-white shadow-sm transition duration-200 ${
                enabled ? 'translate-x-[7px]' : '-translate-x-[7px]'
            }`} />
        </button>
    );
};

export const SetupFormModal = ({ job, trackedSymbols, onClose, onSave, onDelete }: any) => {
    const [localJob, setLocalJob] = useState({ ...job });
    const [expandedStage, setExpandedStage] = useState<string | null>(null);
    
    const trackedSymbolOptions = trackedSymbols.map((s: string) => ({ label: s, value: s }));

    // ── Stage config helpers ──
    const stageConfig = localJob.stage_config || {};
    
    const getServerConfig = () => ({
        strategies: stageConfig.server_strategies || [...ALL_STRATEGIES],
        timeframes: stageConfig.server_timeframes || ALL_TIMEFRAMES.map(t => t.key),
        min_confidence: stageConfig.server_min_confidence ?? 65,
    });

    const getGemmaConfig = () => ({
        enabled: !(localJob.disabled_stages || []).includes('gemma'),
        model: stageConfig.gemma_model || 'gemma-4-31b-it',
        data_sources: stageConfig.gemma_data_sources || GEMMA_DATA_SOURCES.map(d => d.key),
    });

    const getGeminiConfig = () => ({
        enabled: !(localJob.disabled_stages || []).includes('gemini'),
        model: stageConfig.gemini_model || 'gemini-2.5-flash',
        data_sources: stageConfig.gemini_data_sources || GEMINI_DATA_SOURCES.map(d => d.key),
    });

    const updateStageConfig = (updates: Record<string, any>) => {
        setLocalJob({ ...localJob, stage_config: { ...stageConfig, ...updates } });
    };

    const toggleStrategy = (name: string) => {
        const current = getServerConfig().strategies;
        const next = current.includes(name) 
            ? current.filter((s: string) => s !== name) 
            : [...current, name];
        if (next.length === 0) return; // prevent empty
        updateStageConfig({ server_strategies: next });
    };

    const toggleTimeframe = (key: string) => {
        const current = getServerConfig().timeframes;
        const next = current.includes(key)
            ? current.filter((t: string) => t !== key)
            : [...current, key];
        if (next.length === 0) return;
        updateStageConfig({ server_timeframes: next });
    };

    const toggleDisabledStage = (stageKey: string) => {
        const current: string[] = localJob.disabled_stages || [];
        const next = current.includes(stageKey)
            ? current.filter((s: string) => s !== stageKey)
            : [...current, stageKey];
        setLocalJob({ ...localJob, disabled_stages: next });
    };

    const toggleDataSource = (stageKey: 'gemma' | 'gemini', sourceKey: string) => {
        const configKey = `${stageKey}_data_sources`;
        const allSources = stageKey === 'gemma' ? GEMMA_DATA_SOURCES : GEMINI_DATA_SOURCES;
        const current: string[] = stageConfig[configKey] || allSources.map(d => d.key);
        const next = current.includes(sourceKey)
            ? current.filter((s: string) => s !== sourceKey)
            : [...current, sourceKey];
        if (next.length === 0) return;
        updateStageConfig({ [configKey]: next });
    };

    const getAlertStages = (): string[] => stageConfig.alert_stages || ['server_scan', 'gemma_verdict', 'gemini_decision', 'order_execute'];
    const isAlertOn = (key: string) => localJob.discord_alert && getAlertStages().includes(key);
    const toggleAlertStage = (key: string) => {
        const current = getAlertStages();
        const next = current.includes(key)
            ? current.filter((s: string) => s !== key)
            : [...current, key];
        updateStageConfig({ alert_stages: next });
        if (!localJob.discord_alert && !current.includes(key)) {
            setLocalJob({ ...localJob, discord_alert: true, stage_config: { ...stageConfig, alert_stages: next } });
        }
    };

    const serverConf = getServerConfig();
    const gemmaConf = getGemmaConfig();
    const geminiConf = getGeminiConfig();

    // ── Stage Card Component ──
    const StageCard = ({ stageKey, label, desc, icon: Icon, color, alwaysOn, expanded, alertKey, children }: any) => {
        const isDisabled = !alwaysOn && (localJob.disabled_stages || []).includes(stageKey);
        const hasAlert = alertKey && isAlertOn(alertKey);
        const colorMap: Record<string, { bg: string; border: string; text: string; iconBg: string }> = {
            blue:   { bg: 'bg-blue-500/5',   border: 'border-blue-500/20',   text: 'text-blue-500',   iconBg: 'bg-blue-500/10' },
            purple: { bg: 'bg-purple-500/5', border: 'border-purple-500/20', text: 'text-purple-500', iconBg: 'bg-purple-500/10' },
            amber:  { bg: 'bg-amber-500/5',  border: 'border-amber-500/20',  text: 'text-amber-500',  iconBg: 'bg-amber-500/10' },
        };
        const c = colorMap[color];

        return (
            <div className={`rounded-xl border transition-all duration-300 overflow-hidden ${
                isDisabled 
                    ? 'border-gray-200 dark:border-white/5 bg-gray-50 dark:bg-white/[0.02] opacity-50' 
                    : `${c.bg} ${c.border}`
            }`}>
                {/* Header */}
                <div 
                    className="flex items-center gap-3 p-3.5 cursor-pointer select-none"
                    onClick={() => !isDisabled && setExpandedStage(expanded ? null : stageKey)}
                >
                    <div className={`size-8 rounded-lg flex items-center justify-center shrink-0 ${
                        isDisabled ? 'bg-gray-200 dark:bg-white/5 text-gray-400' : `${c.iconBg} ${c.text}`
                    }`}>
                        {isDisabled ? <LuPower size={15} /> : <Icon size={15} />}
                    </div>
                    <div className="flex-1 min-w-0">
                        <div className="flex items-center gap-2">
                            <h4 className={`text-[11px] font-bold ${isDisabled ? 'text-gray-400 line-through' : 'text-gray-900 dark:text-white'}`}>
                                {label}
                            </h4>
                            <span className="text-[9px] text-gray-500">{desc}</span>
                        </div>
                    </div>
                    <div className="flex items-center gap-2 shrink-0">
                        {/* Discord Alert Bell */}
                        {alertKey && !isDisabled && (
                            <button
                                onClick={(e) => { e.stopPropagation(); toggleAlertStage(alertKey); }}
                                className={`size-7 rounded-lg flex items-center justify-center transition-all duration-200 ${
                                    hasAlert 
                                        ? 'bg-indigo-500/10 text-indigo-500 hover:bg-indigo-500/20' 
                                        : 'text-gray-300 dark:text-gray-600 hover:text-gray-500 dark:hover:text-gray-400'
                                }`}
                                title={hasAlert ? 'Discord alert ON' : 'Discord alert OFF'}
                            >
                                {hasAlert ? <LuBell size={13} /> : <LuBellOff size={13} />}
                            </button>
                        )}
                        {!alwaysOn && (
                            <StageSwitch
                                enabled={!isDisabled}
                                color={color}
                                onToggle={() => toggleDisabledStage(stageKey)}
                            />
                        )}
                        {!isDisabled && (
                            <LuChevronDown size={13} className={`text-gray-400 transition-transform duration-200 ${expanded ? 'rotate-180' : ''}`} />
                        )}
                    </div>
                </div>

                {/* Expanded Config */}
                {!isDisabled && expanded && (
                    <div className="px-3.5 pb-3.5 pt-0 border-t border-gray-200/50 dark:border-white/5 animate-in fade-in slide-in-from-top-1 duration-200">
                        <div className="pt-3">
                            {children}
                        </div>
                    </div>
                )}
            </div>
        );
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

                <div className="p-5 overflow-y-auto max-h-[70vh] [&::-webkit-scrollbar]:hidden">
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

                    {/* ═══════════════════════════════════════════════ */}
                    {/* Pipeline v8 — 3-Stage Engine (Configurable)    */}
                    {/* ═══════════════════════════════════════════════ */}
                    <div className="mb-6">
                        <label className="text-[10px] font-bold text-gray-500 uppercase tracking-widest border-b border-default-200 dark:border-white/5 pb-2 mb-3 flex items-center gap-2">
                            <LuSettings2 className="text-blue-500 size-4" />
                            Pipeline v8 — 3-Stage Engine
                        </label>
                        <div className="flex flex-col gap-2 pt-3">
                            {/* ── Stage 1: Server Scan ── */}
                            <StageCard
                                stageKey="server"
                                label="Stage 1: Server Scan"
                                desc={`${serverConf.strategies.length} กลยุทธ์ x ${serverConf.timeframes.length} TF`}
                                icon={LuServer}
                                color="blue"
                                alwaysOn={true}
                                alertKey="server_scan"
                                expanded={expandedStage === 'server'}
                            >
                                {/* Strategies */}
                                <div className="mb-3">
                                    <div className="flex items-center justify-between mb-2">
                                        <span className="text-[9px] font-bold text-gray-500 uppercase tracking-wider">Strategies</span>
                                        <button
                                            onClick={() => {
                                                const allSelected = serverConf.strategies.length === ALL_STRATEGIES.length;
                                                updateStageConfig({ server_strategies: allSelected ? ['SMC'] : [...ALL_STRATEGIES] });
                                            }}
                                            className="text-[9px] text-blue-500 hover:text-blue-400 font-bold"
                                        >
                                            {serverConf.strategies.length === ALL_STRATEGIES.length ? 'Deselect All' : 'Select All'}
                                        </button>
                                    </div>
                                    <div className="flex flex-wrap gap-1.5">
                                        {ALL_STRATEGIES.map(s => (
                                            <ToggleChip
                                                key={s}
                                                label={s}
                                                active={serverConf.strategies.includes(s)}
                                                onClick={() => toggleStrategy(s)}
                                            />
                                        ))}
                                    </div>
                                </div>
                                {/* Timeframes */}
                                <div className="mb-3">
                                    <span className="text-[9px] font-bold text-gray-500 uppercase tracking-wider mb-2 block">Timeframes</span>
                                    <div className="flex gap-1.5">
                                        {ALL_TIMEFRAMES.map(tf => (
                                            <ToggleChip
                                                key={tf.key}
                                                label={tf.label}
                                                active={serverConf.timeframes.includes(tf.key)}
                                                onClick={() => toggleTimeframe(tf.key)}
                                            />
                                        ))}
                                    </div>
                                </div>
                                {/* Min Confidence */}
                                <div>
                                    <span className="text-[9px] font-bold text-gray-500 uppercase tracking-wider mb-1 block">Min Confidence</span>
                                    <div className="flex items-center gap-2">
                                        <input
                                            type="range" min="50" max="90" step="5"
                                            value={serverConf.min_confidence}
                                            onChange={(e) => updateStageConfig({ server_min_confidence: parseInt(e.target.value) })}
                                            className="flex-1 h-1.5 rounded-full appearance-none bg-gray-200 dark:bg-white/10 accent-blue-500"
                                        />
                                        <span className="text-[11px] font-bold text-blue-500 min-w-[36px] text-right">{serverConf.min_confidence}%</span>
                                    </div>
                                </div>
                            </StageCard>

                            {/* Connector */}
                            <div className="flex justify-center">
                                <svg width="16" height="16" viewBox="0 0 16 16">
                                    <line x1="8" y1="0" x2="8" y2="12" stroke={gemmaConf.enabled ? '#a855f7' : '#d1d5db'} strokeWidth="2" strokeDasharray="3 2" />
                                    <polygon points="5,10 8,16 11,10" fill={gemmaConf.enabled ? '#a855f7' : '#d1d5db'} opacity="0.7" />
                                </svg>
                            </div>

                            {/* ── Stage 2: Gemma 4 ── */}
                            <StageCard
                                stageKey="gemma"
                                label="Stage 2: Gemma 4"
                                desc={`ตรวจสอบ (${gemmaConf.data_sources.length}/${GEMMA_DATA_SOURCES.length} sources)`}
                                icon={LuSparkles}
                                color="purple"
                                alwaysOn={false}
                                alertKey="gemma_verdict"
                                expanded={expandedStage === 'gemma'}
                            >
                                <div className="space-y-3">
                                    {/* AI Model */}
                                    <div>
                                        <span className="text-[9px] font-bold text-gray-500 uppercase tracking-wider mb-1.5 block">AI Model</span>
                                        <select
                                            value={gemmaConf.model}
                                            onChange={(e) => updateStageConfig({ gemma_model: e.target.value })}
                                            className="w-full px-3 py-2 text-[11px] font-bold rounded-lg bg-white dark:bg-[#131826] border border-purple-500/20 text-gray-800 dark:text-gray-200 focus:outline-none focus:border-purple-500/50"
                                        >
                                            {GEMMA_MODELS.map(m => (
                                                <option key={m.value} value={m.value}>{m.label}</option>
                                            ))}
                                        </select>
                                    </div>
                                    {/* Data Sources */}
                                    <div>
                                        <div className="flex items-center justify-between mb-2">
                                            <span className="text-[9px] font-bold text-gray-500 uppercase tracking-wider">Data Sources</span>
                                            <button
                                                onClick={() => {
                                                    const allOn = gemmaConf.data_sources.length === GEMMA_DATA_SOURCES.length;
                                                    updateStageConfig({ gemma_data_sources: allOn ? ['indicators'] : GEMMA_DATA_SOURCES.map(d => d.key) });
                                                }}
                                                className="text-[9px] text-purple-500 hover:text-purple-400 font-bold"
                                            >
                                                {gemmaConf.data_sources.length === GEMMA_DATA_SOURCES.length ? 'Deselect All' : 'Select All'}
                                            </button>
                                        </div>
                                        <div className="space-y-1">
                                            {GEMMA_DATA_SOURCES.map(ds => {
                                                const active = gemmaConf.data_sources.includes(ds.key);
                                                return (
                                                    <button
                                                        key={ds.key}
                                                        onClick={() => toggleDataSource('gemma', ds.key)}
                                                        className={`w-full flex items-center gap-2.5 px-3 py-2 rounded-lg text-left transition-all duration-200 border ${
                                                            active
                                                                ? 'bg-purple-500/5 border-purple-500/20'
                                                                : 'bg-transparent border-gray-200/50 dark:border-white/5 opacity-50'
                                                        }`}
                                                    >
                                                        <div className={`size-4 rounded flex items-center justify-center shrink-0 transition-colors ${
                                                            active ? 'bg-purple-500 text-white' : 'bg-gray-200 dark:bg-white/10'
                                                        }`}>
                                                            {active && <LuCheck size={10} />}
                                                        </div>
                                                        <div className="flex-1 min-w-0">
                                                            <span className={`text-[10px] font-bold block ${active ? 'text-gray-800 dark:text-gray-200' : 'text-gray-400'}`}>
                                                                {ds.label}
                                                            </span>
                                                            <span className="text-[8px] text-gray-500 block">{ds.desc}</span>
                                                        </div>
                                                    </button>
                                                );
                                            })}
                                        </div>
                                    </div>
                                </div>
                            </StageCard>

                            {/* Connector */}
                            <div className="flex justify-center">
                                <svg width="16" height="16" viewBox="0 0 16 16">
                                    <line x1="8" y1="0" x2="8" y2="12" stroke={geminiConf.enabled ? '#f59e0b' : '#d1d5db'} strokeWidth="2" strokeDasharray="3 2" />
                                    <polygon points="5,10 8,16 11,10" fill={geminiConf.enabled ? '#f59e0b' : '#d1d5db'} opacity="0.7" />
                                </svg>
                            </div>

                            {/* ── Stage 3: Gemini ── */}
                            <StageCard
                                stageKey="gemini"
                                label="Stage 3: Gemini"
                                desc={`ยืนยัน (${geminiConf.data_sources.length}/${GEMINI_DATA_SOURCES.length} sources)`}
                                icon={LuBrainCircuit}
                                color="amber"
                                alwaysOn={false}
                                alertKey="gemini_decision"
                                expanded={expandedStage === 'gemini'}
                            >
                                <div className="space-y-3">
                                    {/* AI Model */}
                                    <div>
                                        <span className="text-[9px] font-bold text-gray-500 uppercase tracking-wider mb-1.5 block">AI Model</span>
                                        <select
                                            value={geminiConf.model}
                                            onChange={(e) => updateStageConfig({ gemini_model: e.target.value })}
                                            className="w-full px-3 py-2 text-[11px] font-bold rounded-lg bg-white dark:bg-[#131826] border border-amber-500/20 text-gray-800 dark:text-gray-200 focus:outline-none focus:border-amber-500/50"
                                        >
                                            {GEMINI_MODELS.map(m => (
                                                <option key={m.value} value={m.value}>{m.label}</option>
                                            ))}
                                        </select>
                                    </div>
                                    {/* Data Sources */}
                                    <div>
                                        <div className="flex items-center justify-between mb-2">
                                            <span className="text-[9px] font-bold text-gray-500 uppercase tracking-wider">Data Sources</span>
                                            <button
                                                onClick={() => {
                                                    const allOn = geminiConf.data_sources.length === GEMINI_DATA_SOURCES.length;
                                                    updateStageConfig({ gemini_data_sources: allOn ? ['trade_history'] : GEMINI_DATA_SOURCES.map(d => d.key) });
                                                }}
                                                className="text-[9px] text-amber-500 hover:text-amber-400 font-bold"
                                            >
                                                {geminiConf.data_sources.length === GEMINI_DATA_SOURCES.length ? 'Deselect All' : 'Select All'}
                                            </button>
                                        </div>
                                        <div className="space-y-1">
                                            {GEMINI_DATA_SOURCES.map(ds => {
                                                const active = geminiConf.data_sources.includes(ds.key);
                                                return (
                                                    <button
                                                        key={ds.key}
                                                        onClick={() => toggleDataSource('gemini', ds.key)}
                                                        className={`w-full flex items-center gap-2.5 px-3 py-2 rounded-lg text-left transition-all duration-200 border ${
                                                            active
                                                                ? 'bg-amber-500/5 border-amber-500/20'
                                                                : 'bg-transparent border-gray-200/50 dark:border-white/5 opacity-50'
                                                        }`}
                                                    >
                                                        <div className={`size-4 rounded flex items-center justify-center shrink-0 transition-colors ${
                                                            active ? 'bg-amber-500 text-white' : 'bg-gray-200 dark:bg-white/10'
                                                        }`}>
                                                            {active && <LuCheck size={10} />}
                                                        </div>
                                                        <div className="flex-1 min-w-0">
                                                            <span className={`text-[10px] font-bold block ${active ? 'text-gray-800 dark:text-gray-200' : 'text-gray-400'}`}>
                                                                {ds.label}
                                                            </span>
                                                            <span className="text-[8px] text-gray-500 block">{ds.desc}</span>
                                                        </div>
                                                    </button>
                                                );
                                            })}
                                        </div>
                                    </div>
                                </div>
                            </StageCard>
                        </div>
                    </div>

                    {/* Discord Alerts — Per Stage */}
                    <div className="mb-4 rounded-xl bg-default-100/50 dark:bg-white/5 border border-default-200 dark:border-white/5 overflow-hidden">
                        <div className="flex items-center justify-between p-4">
                            <div className="flex items-center gap-3">
                                <LuMessageCircle className="size-5 text-indigo-500" />
                                <div>
                                    <p className="text-xs font-bold text-default-700 dark:text-gray-200">Discord Alerts</p>
                                    <p className="text-[10px] text-gray-500">เลือก Stage ที่ต้องการแจ้งเตือน</p>
                                </div>
                            </div>
                            <button onClick={() => setLocalJob({ ...localJob, discord_alert: !localJob.discord_alert })} className={`relative inline-flex h-6 w-11 shrink-0 cursor-pointer items-center justify-center rounded-full transition-colors ${localJob.discord_alert ? 'bg-indigo-500' : 'bg-gray-300 dark:bg-gray-700'}`}>
                                <span className={`inline-block h-4 w-4 transform rounded-full bg-white transition duration-200 ease-in-out ${localJob.discord_alert ? 'translate-x-2.5' : '-translate-x-2.5'}`} />
                            </button>
                        </div>
                        {localJob.discord_alert && (
                            <div className="px-4 pb-4 pt-0 border-t border-gray-200/50 dark:border-white/5">
                                <div className="space-y-1.5 pt-3">
                                    {[
                                        { key: 'server_scan',    label: 'Server Scan',    desc: 'ผลสแกนสัญญาณ',              icon: LuServer,        color: 'blue' },
                                        { key: 'gemma_verdict',  label: 'Gemma Verdict',  desc: 'ผล Approve/Reject จาก Gemma', icon: LuSparkles,      color: 'purple' },
                                        { key: 'gemini_decision',label: 'Gemini Decision', desc: 'การตัดสินใจขั้นสุดท้าย',      icon: LuBrainCircuit,  color: 'amber' },
                                        { key: 'order_execute',  label: 'Order Execute',  desc: 'เปิด/ปิดออเดอร์',            icon: LuZap,           color: 'emerald' },
                                    ].map(item => {
                                        const alertStages: string[] = stageConfig.alert_stages || ['server_scan', 'gemma_verdict', 'gemini_decision', 'order_execute'];
                                        const active = alertStages.includes(item.key);
                                        const Icon = item.icon;
                                        const colorMap: Record<string, string> = {
                                            blue: 'bg-blue-500', purple: 'bg-purple-500', amber: 'bg-amber-500', emerald: 'bg-emerald-500',
                                        };
                                        return (
                                            <button
                                                key={item.key}
                                                onClick={() => {
                                                    const current: string[] = stageConfig.alert_stages || ['server_scan', 'gemma_verdict', 'gemini_decision', 'order_execute'];
                                                    const next = current.includes(item.key)
                                                        ? current.filter((s: string) => s !== item.key)
                                                        : [...current, item.key];
                                                    updateStageConfig({ alert_stages: next });
                                                }}
                                                className={`w-full flex items-center gap-2.5 px-3 py-2 rounded-lg text-left transition-all duration-200 border ${
                                                    active
                                                        ? 'bg-indigo-500/5 border-indigo-500/20'
                                                        : 'bg-transparent border-gray-200/50 dark:border-white/5 opacity-40'
                                                }`}
                                            >
                                                <div className={`size-6 rounded-md flex items-center justify-center shrink-0 ${
                                                    active ? `${colorMap[item.color]}/10 text-${item.color}-500` : 'bg-gray-200 dark:bg-white/5 text-gray-400'
                                                }`}>
                                                    <Icon size={12} />
                                                </div>
                                                <div className="flex-1 min-w-0">
                                                    <span className={`text-[10px] font-bold block ${active ? 'text-gray-800 dark:text-gray-200' : 'text-gray-400'}`}>
                                                        {item.label}
                                                    </span>
                                                    <span className="text-[8px] text-gray-500 block">{item.desc}</span>
                                                </div>
                                                <div className={`size-5 rounded-full flex items-center justify-center shrink-0 transition-colors ${
                                                    active ? 'text-indigo-500' : 'text-gray-300 dark:text-gray-600'
                                                }`}>
                                                    {active ? <LuBell size={12} /> : <LuBellOff size={12} />}
                                                </div>
                                            </button>
                                        );
                                    })}
                                </div>
                            </div>
                        )}
                    </div>

                    {/* Lot Scale */}
                    <div className="flex items-center justify-between p-4 mb-4 rounded-xl bg-default-100/50 dark:bg-white/5 border border-default-200 dark:border-white/5">
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
