const WebSocket = require('ws');
const ws = new WebSocket('ws://localhost:8080');
ws.on('open', () => {
  console.log('Connected, requesting history...');
  ws.send(JSON.stringify({ action: 'get_history', symbol: 'XAUUSD', timeframe: 'M5', limit: 10 }));
});
ws.on('message', (d) => {
  const m = JSON.parse(d.toString());
  if (m.type === 'history') {
    console.log('History response:');
    console.log('  Symbol:', m.symbol, 'TF:', m.timeframe);
    console.log('  Candles count:', (m.candles || []).length);
    if (m.candles && m.candles.length > 0) {
      m.candles.forEach((c, i) => console.log(`  [${i}]`, JSON.stringify(c)));
    } else {
      console.log('  NO CANDLES!');
    }
    ws.close();
  }
});
setTimeout(() => { console.log('Timeout'); ws.close(); }, 5000);
