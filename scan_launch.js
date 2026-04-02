const WebSocket = require('ws');
const ws = new WebSocket('ws://localhost:8080');

ws.on('open', () => {
  console.log('Connected, scanning MT5...');
  ws.send(JSON.stringify({ action: 'scan_mt5' }));
});

ws.on('message', (d) => {
  const m = JSON.parse(d.toString());
  if (m.type === 'welcome') {
    console.log('EA Connected:', m.ea_connected, '| Symbol:', m.ea_symbol);
  }
  if (m.type === 'mt5_instances') {
    console.log('MT5 Instances:', m.instances.length);
    m.instances.forEach(i => {
      console.log('  ', i.id.substring(0, 12) + '...', i.broker_name, 'running:', i.mt5_running, 'ea:', i.ea_deployed);
    });
    const target = m.instances.find(i => i.ea_deployed) || m.instances[0];
    if (target && !target.mt5_running) {
      console.log('\n🚀 Launching:', target.broker_name, '(' + target.id + ')');
      ws.send(JSON.stringify({ action: 'launch_mt5', instance_id: target.id }));
    } else if (target && target.mt5_running) {
      console.log('\n✅ MT5 already running:', target.broker_name);
    } else {
      console.log('\n⚠️ No MT5 instances found');
    }
    setTimeout(() => ws.close(), 3000);
  }
  if (m.type === 'launch_status') {
    console.log('Launch result:', m.status);
  }
});

ws.on('close', () => process.exit(0));
ws.on('error', (e) => { console.error('Error:', e.message); process.exit(1); });
