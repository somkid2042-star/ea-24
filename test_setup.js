const WebSocket = require('ws');

// ============================================================
// test_setup.js — Debug ทดสอบ Trade Setup → Order Flow
// ============================================================
// Script นี้จะ:
// 1. Connect WS → ดู EA status
// 2. ดึง Trade Setups ที่มีอยู่
// 3. สร้าง Setup ใหม่ถ้ายังไม่มี
// 4. Toggle เป็น active ถ้ายังเป็น paused
// 5. Monitor engine_status เพื่อดูว่า Engine ทำงานอย่างไร
// 6. Monitor strategy_signal / trade result
// ============================================================

const ws = new WebSocket('ws://localhost:8080');
let eaConnected = false;
let eaSymbol = '';
let setupExists = false;
let testSetupId = null;

function send(data) {
  if (ws.readyState === WebSocket.OPEN) {
    ws.send(JSON.stringify(data));
  }
}

ws.on('open', () => {
  console.log('✅ Connected to ea-server');
  console.log('📡 Requesting current setups...');
  send({ action: 'get_trade_setups' });
});

ws.on('message', (raw) => {
  try {
    const data = JSON.parse(raw.toString());

    // ─── Welcome ───
    if (data.type === 'welcome') {
      console.log('\n📋 Server Info:');
      console.log(`   Version: ${data.server_version}`);
      console.log(`   EA Connected: ${data.ea_connected}`);
      console.log(`   EA Version: ${data.ea_version}`);
      console.log(`   EA Symbol: ${data.ea_symbol}`);
      console.log(`   Uptime: ${data.server_uptime_secs}s`);
      eaConnected = data.ea_connected;
      eaSymbol = data.ea_symbol || 'XAUUSD';
      
      if (!eaConnected) {
        console.log('\n⚠️  EA ไม่ได้เชื่อมต่อ! Engine จะไม่ออกออเดอร์จนกว่า EA จะเชื่อมต่อ');
        console.log('   → ต้อง: เปิด MT5 + Attach EA (EATradingClient) ลงบน chart');
      }
    }

    // ─── Trade Setups ───
    if (data.type === 'trade_setups') {
      const setups = data.setups || [];
      console.log(`\n📦 Trade Setups Found: ${setups.length}`);
      
      if (setups.length === 0) {
        console.log('   ❌ ไม่มี Trade Setup เลย — กำลังสร้างใหม่...');
        send({
          action: 'add_trade_setup',
          symbol: eaSymbol || 'XAUUSD',
          strategy: 'Scalper Pro',
          timeframe: 'M5',
          lot_size: 0.01,
          risk_percent: 2.0,
          mt5_instance: '',
          tp_enabled: false,
          tp_mode: 'pips',
          tp_value: 50,
          sl_enabled: false,
          sl_mode: 'pips',
          sl_value: 30,
          trailing_stop_enabled: false,
          trailing_stop_points: 50,
        });
        console.log('   📝 ส่งคำสั่งสร้าง setup แล้ว...');
        return;
      }

      setups.forEach(s => {
        const statusEmoji = s.status === 'active' ? '🟢' : '🟡';
        console.log(`   ${statusEmoji} [ID ${s.id}] ${s.symbol} | ${s.strategy} | ${s.timeframe} | Lot ${s.lotSize} | Status: ${s.status}`);
        console.log(`      TP: ${s.tpEnabled ? `ON (${s.tpMode} ${s.tpValue})` : 'OFF'}`);
        console.log(`      SL: ${s.slEnabled ? `ON (${s.slMode} ${s.slValue})` : 'OFF'}`);
        console.log(`      Trailing: ${s.trailingStopEnabled ? `ON (${s.trailingStopPoints} pts)` : 'OFF'}`);
      });

      // ตรวจสอบว่ามี setup ที่ active อยู่หรือไม่
      const activeSetups = setups.filter(s => s.status === 'active');
      const pausedSetups = setups.filter(s => s.status === 'paused');
      
      console.log(`\n📊 สรุป: Active=${activeSetups.length}, Paused=${pausedSetups.length}`);
      
      if (activeSetups.length === 0 && pausedSetups.length > 0) {
        // มี setup แต่ยัง paused อยู่ — toggle ตัวแรก
        const first = pausedSetups[0];
        testSetupId = first.id;
        console.log(`\n⚡ ไม่มี setup ที่ active — กำลัง Activate setup ID ${first.id} (${first.symbol})...`);
        send({ action: 'toggle_trade_setup', setup_id: first.id });
      } else if (activeSetups.length > 0) {
        testSetupId = activeSetups[0].id;
        console.log(`\n✅ มี setup ที่ active อยู่แล้ว (ID ${testSetupId}) — กำลัง monitor engine...`);
      }

      if (data.added_id) {
        testSetupId = data.added_id;
        console.log(`\n✅ สร้าง setup ใหม่สำเร็จ! ID=${data.added_id}`);
        console.log(`   กำลัง Activate...`);
        send({ action: 'toggle_trade_setup', setup_id: data.added_id });
      }

      setupExists = true;
    }

    // ─── Engine Status ───
    if (data.type === 'engine_status') {
      const ts = new Date().toLocaleTimeString();
      console.log(`\n🧠 [${ts}] Engine Status: ${data.status}`);
      console.log(`   Message: ${data.message}`);
      
      if (data.setups && data.setups.length > 0) {
        data.setups.forEach(s => {
          const emoji = {
            scanning: '🔍',
            loading_candles: '📊',
            cooldown: '⏱',
            has_position: '📌',
            signal_sent: '🚀',
          }[s.status] || '❓';
          console.log(`   ${emoji} Setup ${s.setup_id}: ${s.status} — ${s.message}`);
        });
      }

      // สาเหตุที่ไม่ออกออเดอร์
      if (data.status === 'waiting_ea') {
        console.log('   ❌ สาเหตุ: EA ยังไม่เชื่อมต่อ → เปิด MT5 + Attach EA');
      } else if (data.status === 'waiting_account') {
        console.log('   ❌ สาเหตุ: ยังไม่ได้รับข้อมูลบัญชี → รอ EA ส่ง account_data');
      } else if (data.status === 'no_setups') {
        console.log('   ❌ สาเหตุ: ไม่มี Active Setup → สร้างและ Activate setup ในหน้า Trade Setup');
      } else if (data.status === 'drawdown_limit') {
        console.log('   ❌ สาเหตุ: Drawdown สูงเกิน 10% → รอให้ positions ปิด');
      } else if (data.status === 'max_positions') {
        console.log('   ❌ สาเหตุ: เปิด positions เต็มแล้ว (max 5)');
      }
    }

    // ─── Strategy Signal ───
    if (data.type === 'strategy_signal') {
      console.log('\n🎯 ═════════════════════════════════════════');
      console.log(`   SIGNAL: ${data.signal} ${data.symbol}`);
      console.log(`   Strategy: ${data.strategy}`);
      console.log(`   Reason: ${data.reason}`);
      console.log('   ═════════════════════════════════════════');
    }

    // ─── Trade Result (from EA) ───
    if (data.type === 'trade_result') {
      console.log('\n💰 ═════════════════════════════════════════');
      console.log('   TRADE RESULT:');
      console.log(JSON.stringify(data, null, 2));
      console.log('   ═════════════════════════════════════════');
    }

    // ─── EA Info ───
    if (data.type === 'ea_info') {
      console.log(`\n🔗 EA Info: v${data.version}, Symbol: ${data.symbol}`);
      eaConnected = true;
      eaSymbol = data.symbol;
    }

    // ─── Account Data (latest) ───
    if (data.type === 'account_data') {
      console.log(`\n💰 Account: Balance=$${data.balance}, Equity=$${data.equity}, Margin=$${data.margin}`);
      const positions = data.positions || [];
      if (positions.length > 0) {
        positions.forEach(p => {
          console.log(`   📌 ${p.type} ${p.symbol} ${p.volume} @ ${p.open_price} PnL=$${p.pnl}`);
        });
      } else {
        console.log('   (ไม่มี positions เปิดอยู่)');
      }
    }

    // ─── Alert ───
    if (data.type === 'alert') {
      const icon = data.level === 'warning' ? '⚠️' : data.level === 'info' ? 'ℹ️' : '🔔';
      console.log(`\n${icon} Alert: ${data.title} — ${data.message}`);
    }

  } catch (e) {
    // non-JSON
  }
});

ws.on('error', (err) => {
  console.error('❌ WebSocket error:', err.message);
});

ws.on('close', () => {
  console.log('\n👋 Disconnected');
  process.exit(0);
});

// Auto-exit after 120s
setTimeout(() => {
  console.log('\n⏰ Timeout 120s — กำลังปิด...');
  console.log('\n📋 สรุปการ Debug:');
  console.log('   ถ้าไม่ออกออเดอร์ ให้ตรวจสอบ:');
  console.log('   1. EA Connected? (ต้องเปิด MT5 + Attach EA)');
  console.log('   2. Trade Setup Active? (ต้อง toggle เป็น active)');
  console.log('   3. Candle Data เพียงพอ? (ต้อง >= 50 candles)');
  console.log('   4. Strategy conditions ตรง? (ดู engine_status scanning)');
  console.log('   5. Cooldown? (60s ระหว่าง trade)');
  console.log('   6. Max Positions? (max 5)');
  console.log('   7. Drawdown? (max 10%)');
  ws.close();
}, 120000);

console.log('🔍 กำลัง Monitor... (จะหยุดอัตโนมัติใน 120s)');
console.log('   Press Ctrl+C to stop manually\n');
