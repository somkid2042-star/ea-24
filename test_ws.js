const WebSocket = require('ws');

const ws = new WebSocket('ws://localhost:8080');

ws.on('open', function open() {
  console.log('Connected to server');
  ws.send(JSON.stringify({
    action: 'get_history',
    symbol: 'XAUUSD',
    limit: 10
  }));
});

ws.on('message', function incoming(data) {
  console.log('Received: %s', data);
  ws.close();
});

ws.on('error', function error(err) {
  console.error('WebSocket error:', err);
});
