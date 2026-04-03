const fs = require('fs');
const file = 'ea-client/src/app/(admin)/(dashboards)/trading/index.tsx';
let content = fs.readFileSync(file, 'utf8');

const isWeekendFunc = `
  const isWeekend = (sym: string) => {
    if (sym.includes('BTC') || sym.includes('ETH') || sym.includes('CRYPTO')) return false;
    const now = new Date();
    const day = now.getUTCDay();
    const hour = now.getUTCHours();
    if (day === 5 && hour >= 21) return true;
    if (day === 6) return true;
    if (day === 0 && hour < 21) return true;
    return false;
  };
`;

content = content.replace('const [chartTf, setChartTf] = useState(\'M5\');', 'const [chartTf, setChartTf] = useState(\'M5\');\n' + isWeekendFunc);

const chartReplace = `
                  {isWeekend(activeSymbol) ? (
                    <div className="absolute inset-0 z-40 flex flex-col items-center justify-center bg-card backdrop-blur-md rounded-lg border-2 border-dashed border-default-200">
                       <LuMoon className="size-12 text-default-400 mb-3" />
                       <h2 className="text-xl font-bold text-default-900">ตลาดปิด (Market Closed)</h2>
                       <p className="text-default-500 mt-2">ไม่มีการแสดงกราฟและการซื้อขายในระบบสำหรับคู่เงินนี้ในช่วงวันหยุด (ส-อา)</p>
                    </div>
                  ) : (
                    <CandleChart symbol={activeSymbol} candles={candles} bid={bid} darkMode={darkMode} chartTf={chartTf}
                      markers={chartMarkers} priceLines={chartPriceLines} serverTime={sym?.serverTime}
                    />
                  )}
`;

content = content.replace(/<CandleChart symbol=\{activeSymbol\}[^>]*\/>/s, chartReplace);

fs.writeFileSync(file, content);
