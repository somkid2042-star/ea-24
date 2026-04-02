const WebSocket = require('ws');

const ws = new WebSocket('ws://localhost:8080');
let eaConnected = false;
let checkInterval;

ws.on('open', function open() {
  console.log('✅ Connected to ea-server. Requesting MT5 scan...');
  ws.send(JSON.stringify({ action: 'scan_mt5' }));
});

ws.on('message', function incoming(data) {
  try {
    const msg = JSON.parse(data.toString());

    if (msg.type === 'mt5_instances') {
      const instances = msg.instances;
      console.log('🔍 Found MT5 Instances:', instances.length);
      
      if (instances.length > 0) {
        // Find one that is configured/deployed
        const target = instances.find(i => i.ea_deployed) || instances[0];
        console.log(`🚀 Sending launch command for: ${target.broker_name} (${target.id})`);
        
        ws.send(JSON.stringify({
          action: 'launch_mt5',
          instance_id: target.id
        }));
        
        // Polling to see if EA connects
        checkInterval = setInterval(() => {
          if (!eaConnected) {
             console.log('⏳ Waiting for EA to connect...');
          }
        }, 2000);
      } else {
         console.log('⚠️ No MT5 instances found.');
         process.exit(1);
      }
    }
    
    if (msg.type === 'ea_info') {
      console.log(`\n🎉 EA CONNECTED! Version: ${msg.version}`);
      eaConnected = true;
      if (checkInterval) clearInterval(checkInterval);
      
      const order = {
        action: 'open_trade',
        symbol: msg.symbol || 'XAUUSD',
        direction: 'BUY',
        lot_size: 0.01,
        sl: 0,
        tp: 0,
        comment: 'EA-Test'
      };
      
      console.log(`\n🚀 Sending trade order: BUY 0.01 on ${order.symbol}`);
      ws.send(JSON.stringify(order));
    }
    
    if (msg.type === 'trade_result' || (msg.type && msg.action === 'open')) {
      console.log(`\n📊 TRADE RESULT:`);
      console.log(JSON.stringify(msg, null, 2));
      console.log('\n✅ Trade process completed successfully. Exiting in 3s...');
      setTimeout(() => process.exit(0), 3000);
    }
    
    if (msg.type === 'account_data' && eaConnected) {
      console.log(`\n💰 Account: Balance=$${msg.balance}, Equity=$${msg.equity}, Positions=${msg.positions_count}`);
      if (msg.positions && msg.positions.length > 0) {
        msg.positions.forEach(p => {
          console.log(`   📌 ${p.type} ${p.symbol} ${p.volume} lot @ ${p.open_price} PnL=$${p.pnl}`);
        });
      }
    }

  } catch (e) {
  }
});
