import { useState, lazy, Suspense } from 'react';
import { LuHistory, LuChartNoAxesCombined, LuBookOpen } from 'react-icons/lu';

const TradeHistoryPage = lazy(() => import('@/app/(admin)/(config)/trade-history/index'));
const PnlReportPage = lazy(() => import('@/app/(admin)/(config)/pnl-report/index'));
const JournalPage = lazy(() => import('@/app/(admin)/(config)/journal/index'));

type TabKey = 'history' | 'pnl' | 'journal';

const TABS: { key: TabKey; label: string; icon: React.ReactNode }[] = [
  { key: 'history', label: 'Trade History', icon: <LuHistory size={16} strokeWidth={1.5} /> },
  { key: 'pnl', label: 'P&L Report', icon: <LuChartNoAxesCombined size={16} strokeWidth={1.5} /> },
  { key: 'journal', label: 'Journal', icon: <LuBookOpen size={16} strokeWidth={1.5} /> },
];

const ReportCombined = () => {
  const [activeTab, setActiveTab] = useState<TabKey>('history');

  return (
    <div className="flex flex-col h-full">
      {/* Tab Bar */}
      <div className="flex items-center gap-1 px-1 pb-3 border-b border-default-200/60 dark:border-default-100/10 mb-4">
        {TABS.map(tab => (
          <button
            key={tab.key}
            onClick={() => setActiveTab(tab.key)}
            className={`flex items-center gap-2 px-4 py-2 rounded-lg text-xs font-semibold transition-all border-none cursor-pointer ${
              activeTab === tab.key
                ? 'bg-primary/10 text-primary'
                : 'text-default-500 hover:text-default-800 dark:hover:text-default-200 hover:bg-default-100 dark:hover:bg-default-100/10'
            }`}
          >
            {tab.icon}
            {tab.label}
          </button>
        ))}
      </div>

      {/* Tab Content */}
      <div className="flex-1 min-h-0 overflow-auto">
        <Suspense fallback={<div className="flex items-center justify-center py-20 text-default-400 text-sm">Loading...</div>}>
          {activeTab === 'history' && <TradeHistoryPage />}
          {activeTab === 'pnl' && <PnlReportPage />}
          {activeTab === 'journal' && <JournalPage />}
        </Suspense>
      </div>
    </div>
  );
};

export default ReportCombined;
