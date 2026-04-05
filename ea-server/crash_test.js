const WebSocket = require('ws');
const ws = new WebSocket('ws://localhost:8080/ws');
ws.on('open', function open() {
  console.log("Connected, sending run_agents");
  ws.send(JSON.stringify({
    action: 'run_agents',
    symbol: 'XAUUSD',
  }));
});
ws.on('message', function incoming(data) {
  console.log("Received: %s", data);
});
ws.on('close', function close() {
  console.log("Disconnected");
});
