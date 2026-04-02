//+------------------------------------------------------------------+
//|                                             EATradingClient.mq5 |
//|                                     Copyright 2026, EA Trading  |
//|                                        https://ea-trading.local |
//+------------------------------------------------------------------+
#property copyright "EA Trading"
#property link      "https://ea-trading.local"
#property version   "2.05"

#include <Trade\Trade.mqh>

#define EA_VERSION "2.05"

input string   ServerIP   = "127.0.0.1";
input ushort   ServerPort = 8081;

int socket = INVALID_HANDLE;
CTrade trade;
bool isConnected = false;
bool tradingEnabled = true;
datetime lastReconnectAttempt = 0;
datetime lastAccountSend = 0;
datetime lastMarketWatchSend = 0;
datetime lastHistorySend = 0;

//+------------------------------------------------------------------+
//| Simple JSON value extractor                                      |
//+------------------------------------------------------------------+
string JsonGetString(const string &json, const string key)
  {
   string search = "\"" + key + "\":\"";
   int start = StringFind(json, search);
   if(start < 0) return "";
   start += StringLen(search);
   int end = StringFind(json, "\"", start);
   if(end < 0) return "";
   return StringSubstr(json, start, end - start);
  }

double JsonGetDouble(const string &json, const string key)
  {
   string search = "\"" + key + "\":";
   int start = StringFind(json, search);
   if(start < 0) return 0;
   start += StringLen(search);
   // Find end: comma, brace, or bracket
   string rest = StringSubstr(json, start, 30);
   string val = "";
   for(int i = 0; i < StringLen(rest); i++)
     {
      ushort ch = StringGetCharacter(rest, i);
      if(ch == ',' || ch == '}' || ch == ']' || ch == ' ') break;
      val += CharToString((uchar)ch);
     }
   return StringToDouble(val);
  }

long JsonGetLong(const string &json, const string key)
  {
   string search = "\"" + key + "\":";
   int start = StringFind(json, search);
   if(start < 0) return 0;
   start += StringLen(search);
   string rest = StringSubstr(json, start, 30);
   string val = "";
   for(int i = 0; i < StringLen(rest); i++)
     {
      ushort ch = StringGetCharacter(rest, i);
      if(ch == ',' || ch == '}' || ch == ']' || ch == ' ') break;
      val += CharToString((uchar)ch);
     }
   return StringToInteger(val);
  }

//+------------------------------------------------------------------+
//| Send response back to server                                     |
//+------------------------------------------------------------------+
void SendResponse(const string json)
  {
   if(!isConnected || socket == INVALID_HANDLE) return;
   string msg = json + "\n";
   uchar data[];
   StringToCharArray(msg, data);
   SocketSend(socket, data, (uint)(ArraySize(data) - 1));
  }

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   Print("====================================");
   Print("EATradingClient v", EA_VERSION, " Starting...");
   Print("Server: ", ServerIP, ":", ServerPort);
   Print("====================================");
   
   // --- Close duplicate charts with the same symbol ---
   long thisChart = ChartID();
   string thisSymbol = ChartSymbol(thisChart);
   long chart = ChartFirst();
   while(chart >= 0)
     {
      long nextChart = ChartNext(chart);
      if(chart != thisChart && ChartSymbol(chart) == thisSymbol)
        {
         Print("Closing duplicate chart: ", chart, " (", ChartSymbol(chart), ")");
         ChartClose(chart);
        }
      chart = nextChart;
     }
   
   // --- Set chart background to black with clean look ---
   ChartSetInteger(0, CHART_COLOR_BACKGROUND, clrBlack);
   ChartSetInteger(0, CHART_COLOR_FOREGROUND, clrWhite);
   ChartSetInteger(0, CHART_COLOR_GRID, 0x1A1A1A);
   ChartSetInteger(0, CHART_COLOR_CHART_UP, clrLime);
   ChartSetInteger(0, CHART_COLOR_CHART_DOWN, clrRed);
   ChartSetInteger(0, CHART_COLOR_CANDLE_BULL, clrLime);
   ChartSetInteger(0, CHART_COLOR_CANDLE_BEAR, clrRed);
   ChartSetInteger(0, CHART_COLOR_CHART_LINE, clrWhite);
   ChartSetInteger(0, CHART_COLOR_BID, clrDodgerBlue);
   ChartSetInteger(0, CHART_COLOR_ASK, clrOrangeRed);
   ChartSetInteger(0, CHART_COLOR_LAST, clrYellow);
   ChartSetInteger(0, CHART_COLOR_STOP_LEVEL, clrRed);
   ChartSetInteger(0, CHART_SHOW_GRID, false);
   ChartRedraw(0);
   
   // --- Display EA version large on chart ---
   string versionText = "\n\n\n\n\n"
                       + "        EA Trading Client\n"
                       + "        v" + EA_VERSION + "\n"
                       + "        " + thisSymbol + "\n";
   Comment(versionText);
   
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
      return;
     }

   if(!SocketConnect(socket, ServerIP, ServerPort, 2000))
     {
      Print("Connect failed to ", ServerIP, ":", ServerPort, ", error ", GetLastError());
      SocketClose(socket);
      socket = INVALID_HANDLE;
      return;
     }
     
   isConnected = true;
   Print("Connected to ea-server at ", ServerIP, ":", ServerPort);
   
   // Send version info
   string versionMsg = "{\"type\":\"ea_info\",\"version\":\"" + EA_VERSION + "\",\"symbol\":\"" + _Symbol + "\"}\n";
   uchar vData[];
   StringToCharArray(versionMsg, vData);
   SocketSend(socket, vData, (uint)(ArraySize(vData) - 1));
   
   SendAccountData();
   SendMarketWatch();
   SendTradeHistory();
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
         TryConnect();
        }
      return;
     }
   
   if(socket == INVALID_HANDLE) return;
   
   // Send account data every 2 seconds
   if(TimeCurrent() - lastAccountSend >= 2)
     {
      SendAccountData();
      lastAccountSend = TimeCurrent();
     }
   
   // Send market watch every 10 seconds
   if(TimeCurrent() - lastMarketWatchSend >= 10)
     {
      SendMarketWatch();
      lastMarketWatchSend = TimeCurrent();
     }
   
   // Send trade history every 30 seconds
   if(TimeCurrent() - lastHistorySend >= 30)
     {
      SendTradeHistory();
      lastHistorySend = TimeCurrent();
     }
   
   // Read commands from server
   uint len = SocketIsReadable(socket);
   if(len > 0)
     {
      uchar buffer[];
      int received = SocketRead(socket, buffer, len, 100);
      if(received > 0)
        {
         string msg = CharArrayToString(buffer, 0, received);
         ProcessCommand(msg);
        }
      else
        {
         Print("Connection lost, reconnecting...");
         isConnected = false;
        }
     }
  }

//+------------------------------------------------------------------+
//| Process command from server                                       |
//+------------------------------------------------------------------+
void ProcessCommand(const string msg)
  {
   Print("CMD: ", msg);
   
   // PANIC - close all
   if(StringFind(msg, "\"panic\"") >= 0)
     {
      Print("PANIC! Closing all positions.");
      CloseAllPositions();
      return;
     }
   
   // Stop/Start trading
   if(StringFind(msg, "\"stop_trading\"") >= 0)
     { tradingEnabled = false; Print("Trading DISABLED."); return; }
   if(StringFind(msg, "\"start_trading\"") >= 0)
     { tradingEnabled = true; Print("Trading ENABLED."); return; }
   
   // Open trade
   if(StringFind(msg, "\"open_trade\"") >= 0)
     {
      HandleOpenTrade(msg);
      return;
     }
   
   // Close trade
   if(StringFind(msg, "\"close_trade\"") >= 0)
     {
      HandleCloseTrade(msg);
      return;
     }
   
   // Modify SL
   if(StringFind(msg, "\"modify_sl\"") >= 0)
     {
      HandleModifySL(msg);
      return;
     }
   
   // Request candles (historical OHLC)
   if(StringFind(msg, "\"request_candles\"") >= 0)
     {
      HandleRequestCandles(msg);
      return;
     }
  }

//+------------------------------------------------------------------+
//| Handle open_trade command                                         |
//+------------------------------------------------------------------+
void HandleOpenTrade(const string msg)
  {
   string sym = JsonGetString(msg, "symbol");
   string dir = JsonGetString(msg, "direction");
   double lot = JsonGetDouble(msg, "lot_size");
   double sl  = JsonGetDouble(msg, "sl");
   double tp  = JsonGetDouble(msg, "tp");
   string cmt = JsonGetString(msg, "comment");
   
   if(StringLen(sym) == 0) sym = _Symbol;
   if(lot <= 0) lot = 0.01;
   if(StringLen(cmt) == 0) cmt = "EA-Web";
   
   // Make sure symbol is selected
   SymbolSelect(sym, true);
   
   int digits = (int)SymbolInfoInteger(sym, SYMBOL_DIGITS);
   double ask = SymbolInfoDouble(sym, SYMBOL_ASK);
   double bid = SymbolInfoDouble(sym, SYMBOL_BID);
   
   bool result = false;
   
   if(dir == "BUY")
     {
      result = trade.Buy(lot, sym, ask, sl, tp, cmt);
     }
   else if(dir == "SELL")
     {
      result = trade.Sell(lot, sym, bid, sl, tp, cmt);
     }
   
   // Send result back
   string resp = "{\"type\":\"trade_result\"";
   resp += ",\"action\":\"open\"";
   resp += ",\"success\":" + (result ? "true" : "false");
   resp += ",\"symbol\":\"" + sym + "\"";
   resp += ",\"direction\":\"" + dir + "\"";
   resp += ",\"lot\":" + DoubleToString(lot, 2);
   if(!result)
     resp += ",\"error\":\"" + IntegerToString(GetLastError()) + " " + trade.ResultComment() + "\"";
   else
     resp += ",\"ticket\":" + IntegerToString((long)trade.ResultOrder());
   resp += "}";
   
   SendResponse(resp);
   Print(result ? "Trade opened: " : "Trade FAILED: ", sym, " ", dir, " ", lot);
   
   // Immediately send updated account data
   Sleep(500);
   SendAccountData();
  }

//+------------------------------------------------------------------+
//| Handle close_trade command                                        |
//+------------------------------------------------------------------+
void HandleCloseTrade(const string msg)
  {
   long ticket = JsonGetLong(msg, "ticket");
   
   if(ticket <= 0)
     {
      SendResponse("{\"type\":\"trade_result\",\"action\":\"close\",\"success\":false,\"error\":\"Invalid ticket\"}");
      return;
     }
   
   bool result = trade.PositionClose((ulong)ticket);
   
   string resp = "{\"type\":\"trade_result\"";
   resp += ",\"action\":\"close\"";
   resp += ",\"success\":" + (result ? "true" : "false");
   resp += ",\"ticket\":" + IntegerToString(ticket);
   if(!result)
     resp += ",\"error\":\"" + IntegerToString(GetLastError()) + " " + trade.ResultComment() + "\"";
   resp += "}";
   
   SendResponse(resp);
   Print(result ? "Position closed: #" : "Close FAILED: #", ticket);
   
   Sleep(500);
   SendAccountData();
   SendTradeHistory();
  }

//+------------------------------------------------------------------+
//| Handle modify_sl command                                          |
//+------------------------------------------------------------------+
void HandleModifySL(const string msg)
  {
   long ticket = JsonGetLong(msg, "ticket");
   double newSL = JsonGetDouble(msg, "new_sl");
   
   if(ticket <= 0) return;
   
   // Select the position to get current TP
   if(!PositionSelectByTicket((ulong)ticket)) return;
   
   double currentTP = PositionGetDouble(POSITION_TP);
   
   bool result = trade.PositionModify((ulong)ticket, newSL, currentTP);
   
   if(result)
     Print("SL modified: #", ticket, " -> ", newSL);
   else
     Print("SL modify FAILED: #", ticket, " error ", GetLastError());
  }

//+------------------------------------------------------------------+
//| Send account data to server                                       |
//+------------------------------------------------------------------+
void SendAccountData()
  {
   if(!isConnected || socket == INVALID_HANDLE) return;
   
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double equity  = AccountInfoDouble(ACCOUNT_EQUITY);
   double profit  = AccountInfoDouble(ACCOUNT_PROFIT);
   double margin  = AccountInfoDouble(ACCOUNT_MARGIN);
   double freeMargin = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
   string currency = AccountInfoString(ACCOUNT_CURRENCY);
   
   string posJson = "[";
   int total = PositionsTotal();
   for(int i = 0; i < total; i++)
     {
      ulong ticket = PositionGetTicket(i);
      if(ticket > 0)
        {
         string sym = PositionGetString(POSITION_SYMBOL);
         long posType = PositionGetInteger(POSITION_TYPE);
         string dir = (posType == POSITION_TYPE_BUY) ? "BUY" : "SELL";
         double vol = PositionGetDouble(POSITION_VOLUME);
         double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
         double curPrice = PositionGetDouble(POSITION_PRICE_CURRENT);
         double posPnl = PositionGetDouble(POSITION_PROFIT);
         double posSwap = PositionGetDouble(POSITION_SWAP);
         double posSL = PositionGetDouble(POSITION_SL);
         double posTP = PositionGetDouble(POSITION_TP);
         long magic = PositionGetInteger(POSITION_MAGIC);
         datetime openTime = (datetime)PositionGetInteger(POSITION_TIME);
         string comment = PositionGetString(POSITION_COMMENT);
         int symDigits = (int)SymbolInfoInteger(sym, SYMBOL_DIGITS);
         
         if(i > 0) posJson += ",";
         posJson += "{";
         posJson += "\"ticket\":" + IntegerToString((long)ticket);
         posJson += ",\"symbol\":\"" + sym + "\"";
         posJson += ",\"type\":\"" + dir + "\"";
         posJson += ",\"volume\":" + DoubleToString(vol, 2);
         posJson += ",\"open_price\":" + DoubleToString(openPrice, symDigits);
         posJson += ",\"current_price\":" + DoubleToString(curPrice, symDigits);
         posJson += ",\"pnl\":" + DoubleToString(posPnl, 2);
         posJson += ",\"swap\":" + DoubleToString(posSwap, 2);
         posJson += ",\"sl\":" + DoubleToString(posSL, symDigits);
         posJson += ",\"tp\":" + DoubleToString(posTP, symDigits);
         posJson += ",\"magic\":" + IntegerToString(magic);
         posJson += ",\"open_time\":\"" + TimeToString(openTime, TIME_DATE|TIME_MINUTES) + "\"";
         posJson += ",\"comment\":\"" + comment + "\"";
         posJson += "}";
        }
     }
   posJson += "]";
   
   string json = "{\"type\":\"account_data\"";
   json += ",\"balance\":" + DoubleToString(balance, 2);
   json += ",\"equity\":" + DoubleToString(equity, 2);
   json += ",\"profit\":" + DoubleToString(profit, 2);
   json += ",\"margin\":" + DoubleToString(margin, 2);
   json += ",\"free_margin\":" + DoubleToString(freeMargin, 2);
   json += ",\"currency\":\"" + currency + "\"";
   json += ",\"positions\":" + posJson;
   json += ",\"positions_count\":" + IntegerToString(total);
   json += ",\"trading_enabled\":" + (tradingEnabled ? "true" : "false");
   json += "}\n";
   
   uchar data[];
   StringToCharArray(json, data);
   int sent = SocketSend(socket, data, (uint)(ArraySize(data) - 1));
   if(sent < 0)
     { isConnected = false; }
  }

//+------------------------------------------------------------------+
//| Close all positions                                              |
//+------------------------------------------------------------------+
void CloseAllPositions()
  {
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      if(ticket > 0) trade.PositionClose(ticket);
     }
  }

//+------------------------------------------------------------------+
//| Send Market Watch symbols to server                              |
//+------------------------------------------------------------------+
void SendMarketWatch()
  {
   if(!isConnected || socket == INVALID_HANDLE) return;
   
   string symbolsJson = "[";
   int total = SymbolsTotal(true);
   int count = 0;
   for(int i = 0; i < total; i++)
     {
      string sym = SymbolName(i, true);
      if(StringLen(sym) > 0)
        {
         double bid = SymbolInfoDouble(sym, SYMBOL_BID);
         double ask = SymbolInfoDouble(sym, SYMBOL_ASK);
         int digits = (int)SymbolInfoInteger(sym, SYMBOL_DIGITS);
         double spread = (ask - bid) * MathPow(10, digits);
         string desc = SymbolInfoString(sym, SYMBOL_DESCRIPTION);
         
         if(count > 0) symbolsJson += ",";
         symbolsJson += "{";
         symbolsJson += "\"symbol\":\"" + sym + "\"";
         symbolsJson += ",\"bid\":" + DoubleToString(bid, digits);
         symbolsJson += ",\"ask\":" + DoubleToString(ask, digits);
         symbolsJson += ",\"spread\":" + DoubleToString(spread, 1);
         symbolsJson += ",\"digits\":" + IntegerToString(digits);
         symbolsJson += ",\"desc\":\"" + desc + "\"";
         symbolsJson += "}";
         count++;
        }
     }
   symbolsJson += "]";
   
   string json = "{\"type\":\"market_watch\"";
   json += ",\"symbols\":" + symbolsJson;
   json += ",\"count\":" + IntegerToString(count);
   json += "}\n";
   
   uchar data[];
   StringToCharArray(json, data);
   int sent = SocketSend(socket, data, (uint)(ArraySize(data) - 1));
   if(sent < 0)
     { isConnected = false; }
  }

//+------------------------------------------------------------------+
//| Send trade history (closed deals) to server                       |
//+------------------------------------------------------------------+
void SendTradeHistory()
  {
   if(!isConnected || socket == INVALID_HANDLE) return;
   
   // Select history for last 30 days
   datetime fromDate = TimeCurrent() - 30 * 24 * 60 * 60;
   datetime toDate = TimeCurrent();
   
   if(!HistorySelect(fromDate, toDate)) return;
   
   string dealsJson = "[";
   int total = HistoryDealsTotal();
   int count = 0;
   
   for(int i = 0; i < total; i++)
     {
      ulong dealTicket = HistoryDealGetTicket(i);
      if(dealTicket <= 0) continue;
      
      long entry = HistoryDealGetInteger(dealTicket, DEAL_ENTRY);
      // Only include closed deals (DEAL_ENTRY_OUT)
      if(entry != DEAL_ENTRY_OUT) continue;
      
      string sym = HistoryDealGetString(dealTicket, DEAL_SYMBOL);
      long dealType = HistoryDealGetInteger(dealTicket, DEAL_TYPE);
      string dir = (dealType == DEAL_TYPE_BUY) ? "BUY" : "SELL";
      double vol = HistoryDealGetDouble(dealTicket, DEAL_VOLUME);
      double price = HistoryDealGetDouble(dealTicket, DEAL_PRICE);
      double dealProfit = HistoryDealGetDouble(dealTicket, DEAL_PROFIT);
      double dealSwap = HistoryDealGetDouble(dealTicket, DEAL_SWAP);
      double dealComm = HistoryDealGetDouble(dealTicket, DEAL_COMMISSION);
      long dealMagic = HistoryDealGetInteger(dealTicket, DEAL_MAGIC);
      datetime dealTime = (datetime)HistoryDealGetInteger(dealTicket, DEAL_TIME);
      string dealComment = HistoryDealGetString(dealTicket, DEAL_COMMENT);
      long orderTicket = HistoryDealGetInteger(dealTicket, DEAL_ORDER);
      long posId = HistoryDealGetInteger(dealTicket, DEAL_POSITION_ID);
      
      if(count > 0) dealsJson += ",";
      dealsJson += "{";
      dealsJson += "\"ticket\":" + IntegerToString((long)dealTicket);
      dealsJson += ",\"order\":" + IntegerToString(orderTicket);
      dealsJson += ",\"pos_id\":" + IntegerToString(posId);
      dealsJson += ",\"symbol\":\"" + sym + "\"";
      dealsJson += ",\"type\":\"" + dir + "\"";
      dealsJson += ",\"volume\":" + DoubleToString(vol, 2);
      dealsJson += ",\"price\":" + DoubleToString(price, (int)SymbolInfoInteger(sym, SYMBOL_DIGITS));
      dealsJson += ",\"profit\":" + DoubleToString(dealProfit, 2);
      dealsJson += ",\"swap\":" + DoubleToString(dealSwap, 2);
      dealsJson += ",\"commission\":" + DoubleToString(dealComm, 2);
      dealsJson += ",\"magic\":" + IntegerToString(dealMagic);
      dealsJson += ",\"time\":\"" + TimeToString(dealTime, TIME_DATE|TIME_MINUTES) + "\"";
      dealsJson += ",\"comment\":\"" + dealComment + "\"";
      dealsJson += "}";
      count++;
     }
   dealsJson += "]";
   
   string json = "{\"type\":\"trade_history\"";
   json += ",\"deals\":" + dealsJson;
   json += ",\"count\":" + IntegerToString(count);
   json += "}\n";
   
   uchar data[];
   StringToCharArray(json, data);
   int sent = SocketSend(socket, data, (uint)(ArraySize(data) - 1));
   if(sent < 0)
     { isConnected = false; }
  }

//+------------------------------------------------------------------+
//| Handle request_candles command - send historical OHLC data        |
//+------------------------------------------------------------------+
void HandleRequestCandles(const string msg)
  {
   string sym = JsonGetString(msg, "symbol");
   long tf_minutes = JsonGetLong(msg, "timeframe");
   long count = JsonGetLong(msg, "count");
   
   if(StringLen(sym) == 0) sym = _Symbol;
   if(count <= 0) count = 200;
   if(count > 500) count = 500;
   
   // Map minutes to ENUM_TIMEFRAMES
   ENUM_TIMEFRAMES tf = PERIOD_M5;
   if(tf_minutes == 1)   tf = PERIOD_M1;
   else if(tf_minutes == 5)   tf = PERIOD_M5;
   else if(tf_minutes == 15)  tf = PERIOD_M15;
   else if(tf_minutes == 30)  tf = PERIOD_M30;
   else if(tf_minutes == 60)  tf = PERIOD_H1;
   else if(tf_minutes == 240) tf = PERIOD_H4;
   else if(tf_minutes == 1440) tf = PERIOD_D1;
   
   // Make sure symbol is available
   SymbolSelect(sym, true);
   
   MqlRates rates[];
   ArraySetAsSeries(rates, false);
   int copied = CopyRates(sym, tf, 0, (int)count, rates);
   
   if(copied <= 0)
     {
      Print("CopyRates failed for ", sym, " TF=", tf_minutes, " err=", GetLastError());
      SendResponse("{\"type\":\"candle_data\",\"symbol\":\"" + sym + "\",\"candles\":[],\"count\":0}");
      return;
     }
   
   int digits = (int)SymbolInfoInteger(sym, SYMBOL_DIGITS);
   
   // Build JSON array of candles
   string json = "{\"type\":\"candle_data\"";
   json += ",\"symbol\":\"" + sym + "\"";
   json += ",\"timeframe\":" + IntegerToString(tf_minutes);
   json += ",\"count\":" + IntegerToString(copied);
   json += ",\"candles\":[";
   
   for(int i = 0; i < copied; i++)
     {
      if(i > 0) json += ",";
      json += "{\"t\":" + IntegerToString((long)rates[i].time);
      json += ",\"o\":" + DoubleToString(rates[i].open, digits);
      json += ",\"h\":" + DoubleToString(rates[i].high, digits);
      json += ",\"l\":" + DoubleToString(rates[i].low, digits);
      json += ",\"c\":" + DoubleToString(rates[i].close, digits);
      json += "}";
     }
   json += "]}";
   
   SendResponse(json);
   Print("Sent ", copied, " candles for ", sym, " TF=M", tf_minutes);
  }
//+------------------------------------------------------------------+
