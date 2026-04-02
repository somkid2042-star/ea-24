const WebSocket = require('ws');

const ws = new WebSocket('ws://localhost:8080');
let resultReceived = false;

ws.on('open', function open() {
  console.log('✅ Connected to ea-server WebSocket');
  
  // First check if EA is connected
  console.log('📡 Checking EA status...');
});

ws.on('message', function incoming(data) {
  try {
    const msg = JSON.parse(data.toString());
    
    if (msg.type === 'welcome') {
      console.log(`\n📋 Server Info:`);
      console.log(`   Server version: ${msg.server_version}`);
      console.log(`   EA Connected: ${msg.ea_connected}`);
      console.log(`   EA Version: ${msg.ea_version}`);
      console.log(`   EA Symbol: ${msg.ea_symbol}`);
      
      if (!msg.ea_connected) {
        console.log('\n⚠️  EA is NOT connected! Launch MT5 with EA first.');
        console.log('   Sending open_trade anyway (it will be broadcast when EA connects)...');
      }
      
      // Send open trade command
      const order = {
        action: 'open_trade',
        symbol: 'XAUUSD',
        direction: 'BUY',
        lot_size: 0.01,
        sl: 0,
        tp: 0,
        comment: 'EA-Test'
      };
      
      console.log(`\n🚀 Sending order: ${JSON.stringify(order, null, 2)}`);
      ws.send(JSON.stringify(order));
      
      // Wait for result
      setTimeout(() => {
        if (!resultReceived) {
          console.log('\n⏳ No trade result received yet. EA might not be connected.');
          console.log('   The order command has been sent. If EA connects, it will execute.');
          ws.close();
        }
      }, 10000);
    }
    
    if (msg.type === 'trade_result' || (msg.type && msg.action === 'open')) {
      resultReceived = true;
      console.log(`\n📊 TRADE RESULT:`);
      console.log(JSON.stringify(msg, null, 2));
      ws.close();
    }
    
    if (msg.type === 'account_data') {
      console.log(`\n💰 Account: Balance=$${msg.balance}, Equity=$${msg.equity}, Positions=${msg.positions_count}`);
      if (msg.positions && msg.positions.length > 0) {
        msg.positions.forEach(p => {
          console.log(`   📌 ${p.type} ${p.symbol} ${p.volume} lot @ ${p.open_price} PnL=$${p.pnl}`);
        });
      }
    }
    
  } catch (e) {
    // non-JSON message
  }
});

ws.on('error', function error(err) {
  console.error('❌ WebSocket error:', err.message);
});

ws.on('close', function close() {
  console.log('\n👋 Disconnected from ea-server');
  process.exit(0);
});
