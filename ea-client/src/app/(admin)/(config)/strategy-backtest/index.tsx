import { useState } from 'react';
import { LuPlay, LuTrendingUp, LuTrendingDown } from 'react-icons/lu';

const strategies = ['Scalper Pro', 'Trend Rider', 'Grid Master', 'Breakout Hunter', 'Mean Revert'];
const symbols = ['EURUSD', 'GBPUSD', 'USDJPY', 'AUDUSD', 'XAUUSD', 'BTCUSD'];

const StrategyBacktest = () => {
  const [strategy, setStrategy] = useState(strategies[0]);
  const [symbol, setSymbol] = useState(symbols[0]);
  const [showResults, setShowResults] = useState(false);

  const runBacktest = () => setShowResults(true);

  return (
    <main className="space-y-5">
      <div>
        <h4 className="text-lg font-semibold text-default-900">Backtest</h4>
        <p className="text-sm text-default-500">Test your strategy against historical data</p>
      </div>

      {/* Parameters */}
      <div className="card !p-5">
        <h5 className="mb-4 text-sm font-semibold text-default-900">Backtest Parameters</h5>
        <div className="grid grid-cols-2 gap-4 md:grid-cols-4">
          <div>
            <label className="mb-1.5 block text-xs text-default-500">Strategy</label>
            <select value={strategy} onChange={e => setStrategy(e.target.value)} className="form-select">
              {strategies.map(s => <option key={s} value={s}>{s}</option>)}
            </select>
          </div>
          <div>
            <label className="mb-1.5 block text-xs text-default-500">Symbol</label>
            <select value={symbol} onChange={e => setSymbol(e.target.value)} className="form-select">
              {symbols.map(s => <option key={s} value={s}>{s}</option>)}
            </select>
          </div>
          <div>
            <label className="mb-1.5 block text-xs text-default-500">Start Date</label>
            <input type="date" defaultValue="2025-01-01" className="form-input" />
          </div>
          <div>
            <label className="mb-1.5 block text-xs text-default-500">End Date</label>
            <input type="date" defaultValue="2025-12-31" className="form-input" />
          </div>
        </div>
        <button onClick={runBacktest} className="mt-4 btn bg-primary/10 text-primary hover:bg-primary hover:text-white">
          <LuPlay className="size-4" /> Run Backtest
        </button>
      </div>

      {/* Results */}
      {showResults && (
        <>
          <div className="grid grid-cols-2 gap-4 md:grid-cols-4">
            {[
              { label: 'Total Trades', value: '342', sub: '12 months' },
              { label: 'Win Rate', value: '68.4%', sub: '234 wins / 108 losses', positive: true },
              { label: 'Net Profit', value: '+$4,280', sub: '+42.8% return', positive: true },
              { label: 'Max Drawdown', value: '-6.3%', sub: '-$630 peak to valley', positive: false },
            ].map(stat => (
              <div key={stat.label} className="card !p-4 text-center">
                <p className="text-xs text-default-400">{stat.label}</p>
                <p className={`mt-1 text-xl font-bold ${stat.positive === true ? 'text-green-600 dark:text-green-400' : stat.positive === false ? 'text-red-600 dark:text-red-400' : 'text-default-900'}`}>{stat.value}</p>
                <p className="mt-0.5 text-[10px] text-default-500">{stat.sub}</p>
              </div>
            ))}
          </div>

          {/* Equity Curve */}
          <div className="card !p-5">
            <h5 className="mb-4 text-sm font-semibold text-default-900">Equity Curve — {strategy} on {symbol}</h5>
            <div className="flex items-end gap-0.5" style={{ height: 200 }}>
              {Array.from({ length: 40 }, (_, i) => {
                const val = 10000 + Math.sin(i * 0.3) * 500 + i * 100 + (Math.random() * 300 - 150);
                const min = 9500;
                const max = 15000;
                const h = ((val - min) / (max - min)) * 100;
                return (
                  <div key={i} className="flex-1 flex flex-col justify-end">
                    <div className="w-full rounded-t bg-gradient-to-t from-primary/80 to-primary/30 hover:from-primary hover:to-primary/50 transition-all" style={{ height: `${Math.max(h, 2)}%` }} />
                  </div>
                );
              })}
            </div>
            <div className="mt-2 flex justify-between text-[10px] text-default-400">
              <span>Jan 2025</span><span>Apr</span><span>Jul</span><span>Oct</span><span>Dec 2025</span>
            </div>
          </div>

          {/* Monthly breakdown */}
          <div className="card !p-5">
            <h5 className="mb-4 text-sm font-semibold text-default-900">Monthly Performance</h5>
            <div className="grid grid-cols-4 gap-2 md:grid-cols-6">
              {['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'].map(month => {
                const val = Math.round(Math.random() * 800 - 200);
                return (
                  <div key={month} className={`rounded-lg p-3 text-center ${val >= 0 ? 'bg-green-50 dark:bg-green-500/20' : 'bg-red-50 dark:bg-red-500/20'}`}>
                    <p className="text-xs font-medium text-default-600">{month}</p>
                    <p className={`text-sm font-bold ${val >= 0 ? 'text-green-600 dark:text-green-400' : 'text-red-600 dark:text-red-400'}`}>
                      {val >= 0 ? <LuTrendingUp className="inline size-3 mr-0.5" /> : <LuTrendingDown className="inline size-3 mr-0.5" />}
                      ${Math.abs(val)}
                    </p>
                  </div>
                );
              })}
            </div>
          </div>
        </>
      )}
    </main>
  );
};

export default StrategyBacktest;
