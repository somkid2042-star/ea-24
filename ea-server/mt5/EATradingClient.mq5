//+------------------------------------------------------------------+
//|                                             EATradingClient.mq5 |
//|                                     Copyright 2026, EA Trading  |
//|                                        https://ea-trading.local |
//+------------------------------------------------------------------+
#property copyright "EA Trading"
#property link      "https://ea-trading.local"
#property version   "2.01"

#include <Trade\Trade.mqh>

#define EA_VERSION "2.01"

input string   ServerIP   = "127.0.0.1";
input ushort   ServerPort = 8081;

int socket = INVALID_HANDLE;
CTrade trade;
bool isConnected = false;
bool tradingEnabled = true;
datetime lastReconnectAttempt = 0;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   Print("====================================");
   Print("EATradingClient v", EA_VERSION, " Starting...");
   Print("Server: ", ServerIP, ":", ServerPort);
   Print("====================================");
   Print("");
   Print("IMPORTANT: You MUST allow socket connections!");
   Print("Go to: Tools > Options > Expert Advisors");
   Print("Check: 'Allow WebRequest for listed URL'");
   Print("Add:   ", ServerIP);
   Print("");
   
   TryConnect();
   EventSetMillisecondTimer(500);

   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Try to connect to server                                         |
//+------------------------------------------------------------------+
void TryConnect()
  {
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
   
   // Send version info to server on connect
   string versionMsg = "{\"type\":\"ea_info\",\"version\":\"" + EA_VERSION + "\",\"symbol\":\"" + _Symbol + "\"}\n";
   uchar vData[];
   StringToCharArray(versionMsg, vData);
   SocketSend(socket, vData, (uint)(ArraySize(vData) - 1));
   Print("Sent version info: v", EA_VERSION);
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
         else if(StringFind(msg, "\"stop_trading\"") >= 0)
           {
            tradingEnabled = false;
            Print("STOP TRADING command received. Trading disabled.");
           }
         else if(StringFind(msg, "\"start_trading\"") >= 0)
           {
            tradingEnabled = true;
            Print("START TRADING command received. Trading enabled.");
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
