//+------------------------------------------------------------------+
//|                                             EATradingClient.mq5 |
//|                                     Copyright 2026, EA Trading  |
//|                                        https://ea-trading.local |
//+------------------------------------------------------------------+
#property copyright "EA Trading"
#property link      "https://ea-trading.local"
#property version   "2.00"

#include <Trade\Trade.mqh>

input string   ServerIP   = "127.0.0.1";
input ushort   ServerPort = 8081;

int socket = INVALID_HANDLE;
CTrade trade;
bool isConnected = false;
datetime lastReconnectAttempt = 0;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   Print("====================================");
   Print("EATradingClient v2.00 Starting...");
   Print("Server: ", ServerIP, ":", ServerPort);
   Print("====================================");
   Print("");
   Print("IMPORTANT: You MUST allow socket connections!");
   Print("Go to: Tools > Options > Expert Advisors");
   Print("Check: 'Allow WebRequest for listed URL'");
   Print("Add:   ", ServerIP);
   Print("");
   
   // Try to connect
   TryConnect();
   
   // Set timer for reconnection and reading commands (every 500ms)
   EventSetMillisecondTimer(500);

   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Try to connect to server                                         |
//+------------------------------------------------------------------+
void TryConnect()
  {
   // Close old socket if exists
   if(socket != INVALID_HANDLE)
     {
      SocketClose(socket);
      socket = INVALID_HANDLE;
     }
   
   isConnected = false;
   lastReconnectAttempt = TimeCurrent();
   
   socket = SocketCreate();
   if(socket == INVALID_HANDLE)
     {
      int err = GetLastError();
      Print("Socket create failed, error ", err);
      if(err == 4014)
        {
         Print("ERROR 4014: Socket functions not allowed!");
         Print("FIX: Go to Tools > Options > Expert Advisors");
         Print("     Check 'Allow WebRequest for listed URL'");
         Print("     Add: ", ServerIP);
        }
      return;
     }

   if(!SocketConnect(socket, ServerIP, ServerPort, 2000))
     {
      int err = GetLastError();
      Print("Connect failed to ", ServerIP, ":", ServerPort, ", error ", err);
      if(err == 4014)
        {
         Print("ERROR 4014: Socket connections not allowed!");
         Print("FIX: Go to Tools > Options > Expert Advisors");
         Print("     Check 'Allow WebRequest for listed URL'");
         Print("     Add: ", ServerIP);
        }
      SocketClose(socket);
      socket = INVALID_HANDLE;
      return;
     }
     
   isConnected = true;
   Print("Connected to ea-server at ", ServerIP, ":", ServerPort);
  }

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   EventKillTimer();
   if(socket != INVALID_HANDLE)
     {
      SocketClose(socket);
      socket = INVALID_HANDLE;
     }
   isConnected = false;
   Print("Disconnected from ea-server.");
  }

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   if(!isConnected || socket == INVALID_HANDLE) return;
   
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double spread = (ask - bid) * MathPow(10, _Digits);
   
   string json = "{\"type\":\"tick\",\"symbol\":\"" + _Symbol + "\",\"bid\":" + DoubleToString(bid, _Digits) + ",\"ask\":" + DoubleToString(ask, _Digits) + ",\"spread\":" + DoubleToString(spread, 0) + "}\n";
   
   uchar data[];
   StringToCharArray(json, data);
   
   int sent = SocketSend(socket, data, (uint)(ArraySize(data) - 1));
   if(sent < 0) {
      Print("Send failed, reconnecting...");
      isConnected = false;
   }
  }

//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
  {
   // Reconnect if disconnected (try every 5 seconds)
   if(!isConnected)
     {
      if(TimeCurrent() - lastReconnectAttempt >= 5)
        {
         Print("Attempting to reconnect...");
         TryConnect();
        }
      return;
     }
   
   if(socket == INVALID_HANDLE) return;
   
   uint len = SocketIsReadable(socket);
   if(len > 0)
     {
      uchar buffer[];
      int received = SocketRead(socket, buffer, len, 100);
      if(received > 0)
        {
         string msg = CharArrayToString(buffer, 0, received);
         Print("Received from server: ", msg);
         
         if(StringFind(msg, "\"panic\"") >= 0)
           {
            Print("PANIC COMMAND RECEIVED! Closing all positions.");
            CloseAllPositions();
           }
        }
      else
        {
         Print("Connection lost, reconnecting...");
         isConnected = false;
        }
     }
  }

//+------------------------------------------------------------------+
//| Close all positions                                              |
//+------------------------------------------------------------------+
void CloseAllPositions()
  {
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      if(ticket > 0)
        {
         trade.PositionClose(ticket);
        }
     }
  }
//+------------------------------------------------------------------+
