//+------------------------------------------------------------------+
//|                                         ViprasolMACrossEA.mq4     |
//|              Part of MT4 Expert Advisor by Viprasol Tech Pvt Ltd  |
//|                                          https://viprasol.com     |
//+------------------------------------------------------------------+
#property copyright "2025 Viprasol Tech Private Limited"
#property link      "https://viprasol.com"
#property version   "2.00"
#property description "EMA crossover EA for MQL4 with RSI/ADX filters, time & spread filters,"
#property description "fixed-or-risk money management, break-even, ATR/points trailing stop,"
#property description "max-trades-per-day cap, magic-number trade management and an on-chart dashboard."
#property strict

//==================================================================//
//  ENUMS                                                            //
//==================================================================//
enum ENUM_LOT_MODE
  {
   LOT_FIXED = 0,   // Fixed lot size
   LOT_RISK  = 1    // Risk percent of equity
  };

enum ENUM_TRAIL_MODE
  {
   TRAIL_OFF    = 0, // Off
   TRAIL_POINTS = 1, // Fixed points
   TRAIL_ATR    = 2  // ATR multiple
  };

//==================================================================//
//  INPUTS                                                           //
//==================================================================//
//--- Signal -------------------------------------------------------//
input string  sep_signal     = "===== Signal (EMA cross) =====";
input int     FastPeriod     = 12;        // Fast EMA period
input int     SlowPeriod     = 26;        // Slow EMA period
input ENUM_MA_METHOD MAMethod = MODE_EMA; // MA method
input ENUM_APPLIED_PRICE MAPrice = PRICE_CLOSE; // MA applied price

//--- Entry filters ------------------------------------------------//
input string  sep_filters    = "===== Entry filters =====";
input bool    UseRSIFilter   = true;      // Confirm entries with RSI
input int     RSIPeriod      = 14;        // RSI period
input double  RSIBuyMax      = 70.0;      // Skip longs if RSI above this
input double  RSISellMin     = 30.0;      // Skip shorts if RSI below this
input bool    UseADXFilter   = true;      // Require trend strength (ADX)
input int     ADXPeriod      = 14;        // ADX period
input double  ADXMin         = 20.0;      // Minimum ADX to trade
input bool    UseTimeFilter  = false;     // Restrict trading hours (server time)
input int     StartHour      = 7;         // Trading start hour (0-23)
input int     EndHour        = 20;        // Trading end hour (0-23)
input bool    UseSpreadFilter = true;     // Skip when spread is too wide
input double  MaxSpreadPoints = 30.0;     // Max allowed spread (points)

//--- Stops & targets ----------------------------------------------//
input string  sep_stops      = "===== Stops & targets =====";
input int     ATRPeriod      = 14;        // ATR period for stops
input double  SL_ATR         = 2.0;       // Stop-loss = SL_ATR * ATR
input double  TP_ATR         = 3.0;       // Take-profit = TP_ATR * ATR

//--- Money management ---------------------------------------------//
input string  sep_money      = "===== Money management =====";
input ENUM_LOT_MODE LotMode  = LOT_RISK;  // Lot sizing mode
input double  FixedLots      = 0.10;      // Lots when LotMode = Fixed
input double  RiskPercent    = 1.0;       // Risk per trade (% of equity)

//--- Trade management ---------------------------------------------//
input string  sep_manage     = "===== Trade management =====";
input bool    UseBreakEven   = true;      // Move SL to break-even
input double  BE_TriggerATR  = 1.0;       // Profit (in ATR) to arm break-even
input double  BE_LockPoints  = 20.0;      // Points locked beyond entry at BE
input ENUM_TRAIL_MODE TrailMode = TRAIL_ATR; // Trailing-stop mode
input double  TrailPoints    = 300.0;     // Trail distance (points) if TRAIL_POINTS
input double  TrailATR       = 2.0;       // Trail distance (ATR) if TRAIL_ATR
input double  TrailStepPoints = 10.0;     // Min improvement to modify SL (points)
input bool    CloseOnOpposite = true;     // Exit on opposite EMA cross

//--- Risk limits --------------------------------------------------//
input string  sep_limits     = "===== Risk limits =====";
input int     MaxTradesPerDay = 5;        // Max new trades per server day (0 = off)

//--- Order routing ------------------------------------------------//
input string  sep_order      = "===== Order routing =====";
input int     MagicNumber    = 20250101;  // EA magic number
input int     Slippage       = 30;        // Max slippage (points)
input bool    ShowDashboard  = true;      // Draw on-chart dashboard

//==================================================================//
//  GLOBALS                                                          //
//==================================================================//
double   g_point;            // adjusted point (handles 3/5-digit quotes)
int      g_pipFactor;        // 10 on 3/5-digit, else 1
datetime g_lastBarTime = 0;  // last processed bar open time
datetime g_dayStart    = 0;  // server-day boundary for the trade counter
int      g_tradesToday = 0;  // new trades opened on the current server day
string   g_lastSignal  = "none"; // last evaluated signal for dashboard

//==================================================================//
//  INIT                                                            //
//==================================================================//
int OnInit()
  {
   if(FastPeriod >= SlowPeriod)
     {
      Print("FastPeriod must be smaller than SlowPeriod.");
      return(INIT_PARAMETERS_INCORRECT);
     }
   if(FastPeriod < 1 || SlowPeriod < 1 || ATRPeriod < 1)
     {
      Print("Indicator periods must be positive.");
      return(INIT_PARAMETERS_INCORRECT);
     }
   if(LotMode == LOT_FIXED && FixedLots <= 0.0)
     {
      Print("FixedLots must be > 0 when LotMode = Fixed.");
      return(INIT_PARAMETERS_INCORRECT);
     }
   if(LotMode == LOT_RISK && RiskPercent <= 0.0)
     {
      Print("RiskPercent must be > 0 when LotMode = Risk.");
      return(INIT_PARAMETERS_INCORRECT);
     }
   if(UseTimeFilter && (StartHour < 0 || StartHour > 23 || EndHour < 0 || EndHour > 23))
     {
      Print("StartHour/EndHour must be in the range 0-23.");
      return(INIT_PARAMETERS_INCORRECT);
     }

   // Normalise point/pip handling for 3- and 5-digit brokers.
   g_point     = Point;
   g_pipFactor = 1;
   if(Digits == 3 || Digits == 5)
      g_pipFactor = 10;

   g_dayStart     = DayStart(TimeCurrent());
   g_tradesToday  = CountTradesOpenedToday();

   if(ShowDashboard)
      UpdateDashboard("init");

   return(INIT_SUCCEEDED);
  }

//==================================================================//
//  DEINIT                                                          //
//==================================================================//
void OnDeinit(const int reason)
  {
   ObjectDelete(0, "Viprasol_DB");
   Comment("");
  }

//==================================================================//
//  HELPERS                                                         //
//==================================================================//
//--- Beginning of the server day that contains the given time -----//
datetime DayStart(const datetime t)
  {
   return(t - (t % 86400));
  }

//--- Convert a point distance into a price distance ---------------//
double PointsToPrice(const double points)
  {
   return(points * g_point);
  }

//--- Current spread in points -------------------------------------//
double SpreadPoints()
  {
   return((Ask - Bid) / g_point);
  }

//--- Roll the per-day trade counter at the server-day boundary -----//
void RollDayCounter()
  {
   datetime today = DayStart(TimeCurrent());
   if(today != g_dayStart)
     {
      g_dayStart    = today;
      g_tradesToday = 0;
     }
  }

//--- Count trades from this EA that were opened during today -------//
int CountTradesOpenedToday()
  {
   int count = 0;
   datetime today = DayStart(TimeCurrent());
   for(int i = OrdersTotal() - 1; i >= 0; i--)
     {
      if(!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;
      if(OrderSymbol() != Symbol() || OrderMagicNumber() != MagicNumber) continue;
      if(OrderType() != OP_BUY && OrderType() != OP_SELL) continue;
      if(DayStart(OrderOpenTime()) == today) count++;
     }
   return(count);
  }

//==================================================================//
//  MONEY MANAGEMENT                                                //
//==================================================================//
//--- Clamp a raw lot value to broker volume constraints -----------//
double NormalizeLots(double lots)
  {
   double minLot  = MarketInfo(Symbol(), MODE_MINLOT);
   double maxLot  = MarketInfo(Symbol(), MODE_MAXLOT);
   double lotStep = MarketInfo(Symbol(), MODE_LOTSTEP);
   if(lotStep > 0.0) lots = MathFloor(lots / lotStep + 1e-9) * lotStep;
   lots = MathMax(minLot, MathMin(maxLot, lots));
   return(NormalizeDouble(lots, 2));
  }

//--- Risk-based lot sizing over the stop distance (in price) -------//
double LotForRisk(const double stopDistancePrice)
  {
   if(stopDistancePrice <= 0.0) return(0.0);
   double equity    = AccountEquity();
   double riskMoney = equity * RiskPercent / 100.0;

   double tickValue = MarketInfo(Symbol(), MODE_TICKVALUE);
   double tickSize  = MarketInfo(Symbol(), MODE_TICKSIZE);
   if(tickValue <= 0.0 || tickSize <= 0.0) return(0.0);

   double moneyPerLot = (stopDistancePrice / tickSize) * tickValue;
   if(moneyPerLot <= 0.0) return(0.0);

   return(NormalizeLots(riskMoney / moneyPerLot));
  }

//--- Resolve the position size for the active money-management mode //
double ResolveLots(const double stopDistancePrice)
  {
   if(LotMode == LOT_FIXED)
      return(NormalizeLots(FixedLots));
   return(LotForRisk(stopDistancePrice));
  }

//==================================================================//
//  POSITION INSPECTION                                             //
//==================================================================//
//--- True if this EA already holds a position on this symbol -------//
bool HasOpenPosition(int &ticketType)
  {
   for(int i = OrdersTotal() - 1; i >= 0; i--)
     {
      if(!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;
      if(OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumber)
        {
         if(OrderType() == OP_BUY || OrderType() == OP_SELL)
           {
            ticketType = OrderType();
            return(true);
           }
        }
     }
   return(false);
  }

//==================================================================//
//  ENTRY / EXIT                                                    //
//==================================================================//
void ClosePositions()
  {
   for(int i = OrdersTotal() - 1; i >= 0; i--)
     {
      if(!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;
      if(OrderSymbol() != Symbol() || OrderMagicNumber() != MagicNumber) continue;
      if(OrderType() == OP_BUY)
        {
         if(!OrderClose(OrderTicket(), OrderLots(), Bid, Slippage, clrRed))
            Print("OrderClose (buy) failed: ", GetLastError());
        }
      else if(OrderType() == OP_SELL)
        {
         if(!OrderClose(OrderTicket(), OrderLots(), Ask, Slippage, clrRed))
            Print("OrderClose (sell) failed: ", GetLastError());
        }
     }
  }

//==================================================================//
//  BREAK-EVEN + TRAILING STOP                                      //
//==================================================================//
//--- Compute the desired trailing distance in price ---------------//
double TrailDistance(const double atr)
  {
   if(TrailMode == TRAIL_POINTS) return(PointsToPrice(TrailPoints));
   if(TrailMode == TRAIL_ATR)    return(TrailATR * atr);
   return(0.0);
  }

//--- Manage break-even and trailing for all of this EA's trades ----//
void ManageOpenTrades(const double atr)
  {
   double trailDist = TrailDistance(atr);
   double stepPrice = PointsToPrice(TrailStepPoints);
   double beTrigger = BE_TriggerATR * atr;
   double beLock    = PointsToPrice(BE_LockPoints);

   for(int i = OrdersTotal() - 1; i >= 0; i--)
     {
      if(!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;
      if(OrderSymbol() != Symbol() || OrderMagicNumber() != MagicNumber) continue;

      int    type    = OrderType();
      double entry   = OrderOpenPrice();
      double curSL   = OrderStopLoss();
      double curTP   = OrderTakeProfit();
      double newSL   = curSL;

      if(type == OP_BUY)
        {
         double profit = Bid - entry;

         // Break-even: lift SL to entry + lock once enough profit accrued.
         if(UseBreakEven && profit >= beTrigger)
           {
            double be = entry + beLock;
            if(be > newSL) newSL = be;
           }
         // Trailing: follow price by trailDist, only ever tightening.
         if(TrailMode != TRAIL_OFF && trailDist > 0.0)
           {
            double trail = Bid - trailDist;
            if(trail > newSL) newSL = trail;
           }

         newSL = NormalizeDouble(newSL, Digits);
         if(newSL > curSL + stepPrice && newSL < Bid)
           {
            if(!OrderModify(OrderTicket(), entry, newSL, curTP, 0, clrAqua))
               Print("OrderModify (buy trail) failed: ", GetLastError());
           }
        }
      else if(type == OP_SELL)
        {
         double profit = entry - Ask;

         if(UseBreakEven && profit >= beTrigger)
           {
            double be = entry - beLock;
            if(curSL == 0.0 || be < newSL) newSL = be;
           }
         if(TrailMode != TRAIL_OFF && trailDist > 0.0)
           {
            double trail = Ask + trailDist;
            if(curSL == 0.0 || trail < newSL) newSL = trail;
           }

         newSL = NormalizeDouble(newSL, Digits);
         bool improves = (curSL == 0.0) || (newSL < curSL - stepPrice);
         if(improves && newSL > Ask)
           {
            if(!OrderModify(OrderTicket(), entry, newSL, curTP, 0, clrAqua))
               Print("OrderModify (sell trail) failed: ", GetLastError());
           }
        }
     }
  }

//==================================================================//
//  FILTERS                                                         //
//==================================================================//
//--- True if all enabled entry filters allow a long ---------------//
bool FiltersAllowLong(const double rsi, const double adx)
  {
   if(UseRSIFilter && rsi > RSIBuyMax) return(false);
   if(UseADXFilter && adx < ADXMin)    return(false);
   return(true);
  }

//--- True if all enabled entry filters allow a short --------------//
bool FiltersAllowShort(const double rsi, const double adx)
  {
   if(UseRSIFilter && rsi < RSISellMin) return(false);
   if(UseADXFilter && adx < ADXMin)     return(false);
   return(true);
  }

//--- True if the current server hour is inside the trade window ----//
bool WithinTradingHours()
  {
   if(!UseTimeFilter) return(true);
   int h = TimeHour(TimeCurrent());
   if(StartHour <= EndHour)
      return(h >= StartHour && h < EndHour);
   // Overnight window that wraps past midnight (e.g. 22 -> 5).
   return(h >= StartHour || h < EndHour);
  }

//==================================================================//
//  MAIN LOOP                                                       //
//==================================================================//
void OnTick()
  {
   double atr = iATR(Symbol(), 0, ATRPeriod, 1);

   // Manage open trades on every tick for responsive trailing/BE.
   ManageOpenTrades(atr);

   // The remaining signal logic runs once per fully-closed bar.
   if(Time[0] == g_lastBarTime)
     {
      if(ShowDashboard) UpdateDashboard(g_lastSignal);
      return;
     }
   g_lastBarTime = Time[0];

   RollDayCounter();

   // Closed-bar EMA values: shift 1 (last closed) and shift 2 (previous).
   double fastCur  = iMA(Symbol(), 0, FastPeriod, 0, MAMethod, MAPrice, 1);
   double fastPrev = iMA(Symbol(), 0, FastPeriod, 0, MAMethod, MAPrice, 2);
   double slowCur  = iMA(Symbol(), 0, SlowPeriod, 0, MAMethod, MAPrice, 1);
   double slowPrev = iMA(Symbol(), 0, SlowPeriod, 0, MAMethod, MAPrice, 2);
   double rsi      = iRSI(Symbol(), 0, RSIPeriod, MAPrice, 1);
   double adx      = iADX(Symbol(), 0, ADXPeriod, PRICE_CLOSE, MODE_MAIN, 1);

   bool crossUp   = (fastPrev <= slowPrev) && (fastCur > slowCur);
   bool crossDown = (fastPrev >= slowPrev) && (fastCur < slowCur);

   g_lastSignal = crossUp ? "cross up" : (crossDown ? "cross down" : "flat");

   // Manage an existing position: opposite-cross exit only.
   int posType = -1;
   if(HasOpenPosition(posType))
     {
      if(CloseOnOpposite &&
         ((posType == OP_BUY && crossDown) || (posType == OP_SELL && crossUp)))
         ClosePositions();
      if(ShowDashboard) UpdateDashboard(g_lastSignal);
      return;
     }

   if(!crossUp && !crossDown)
     {
      if(ShowDashboard) UpdateDashboard(g_lastSignal);
      return;
     }

   // Global gates before any new entry.
   if(!WithinTradingHours())
     {
      g_lastSignal = "blocked: hours";
      if(ShowDashboard) UpdateDashboard(g_lastSignal);
      return;
     }
   if(UseSpreadFilter && SpreadPoints() > MaxSpreadPoints)
     {
      g_lastSignal = "blocked: spread";
      if(ShowDashboard) UpdateDashboard(g_lastSignal);
      return;
     }
   if(MaxTradesPerDay > 0 && g_tradesToday >= MaxTradesPerDay)
     {
      g_lastSignal = "blocked: daily cap";
      if(ShowDashboard) UpdateDashboard(g_lastSignal);
      return;
     }

   double slDist = SL_ATR * atr;
   double tpDist = TP_ATR * atr;
   if(slDist <= 0.0)
     {
      if(ShowDashboard) UpdateDashboard("blocked: ATR=0");
      return;
     }

   double lots = ResolveLots(slDist);
   if(lots <= 0.0)
     {
      g_lastSignal = "blocked: lots=0";
      if(ShowDashboard) UpdateDashboard(g_lastSignal);
      return;
     }

   if(crossUp && FiltersAllowLong(rsi, adx))
     {
      double sl = NormalizeDouble(Bid - slDist, Digits);
      double tp = NormalizeDouble(Bid + tpDist, Digits);
      int ticket = OrderSend(Symbol(), OP_BUY, lots, Ask, Slippage, sl, tp,
                             "Viprasol MA cross long", MagicNumber, 0, clrGreen);
      if(ticket >= 0) g_tradesToday++;
      else            Print("OrderSend (buy) failed: ", GetLastError());
     }
   else if(crossDown && FiltersAllowShort(rsi, adx))
     {
      double sl = NormalizeDouble(Ask + slDist, Digits);
      double tp = NormalizeDouble(Ask - tpDist, Digits);
      int ticket = OrderSend(Symbol(), OP_SELL, lots, Bid, Slippage, sl, tp,
                             "Viprasol MA cross short", MagicNumber, 0, clrRed);
      if(ticket >= 0) g_tradesToday++;
      else            Print("OrderSend (sell) failed: ", GetLastError());
     }
   else
     {
      g_lastSignal = "blocked: filter";
     }

   if(ShowDashboard) UpdateDashboard(g_lastSignal);
  }

//==================================================================//
//  ON-CHART DASHBOARD                                              //
//==================================================================//
void UpdateDashboard(const string signal)
  {
   int    posType = -1;
   bool   inTrade = HasOpenPosition(posType);
   string posTxt  = inTrade ? (posType == OP_BUY ? "LONG" : "SHORT") : "flat";

   string lotTxt  = (LotMode == LOT_RISK)
                    ? StringFormat("risk %.2f%%", RiskPercent)
                    : StringFormat("fixed %.2f", FixedLots);

   string trailTxt = (TrailMode == TRAIL_OFF) ? "off"
                     : (TrailMode == TRAIL_POINTS
                        ? StringFormat("%.0f pts", TrailPoints)
                        : StringFormat("%.1f ATR", TrailATR));

   string capTxt = (MaxTradesPerDay > 0)
                   ? StringFormat("%d / %d", g_tradesToday, MaxTradesPerDay)
                   : "unlimited";

   string txt =
      "Viprasol MA Cross EA v2.0\n"
      + "----------------------------\n"
      + "Symbol      : " + Symbol() + "  (" + IntegerToString(Period()) + "m)\n"
      + "Position    : " + posTxt + "\n"
      + "Last signal : " + signal + "\n"
      + "Spread      : " + DoubleToString(SpreadPoints(), 1) + " pts\n"
      + "Sizing      : " + lotTxt + "\n"
      + "Trailing    : " + trailTxt + "\n"
      + "Break-even  : " + (UseBreakEven ? "on" : "off") + "\n"
      + "Trades today: " + capTxt + "\n"
      + "Equity      : " + DoubleToString(AccountEquity(), 2) + " " + AccountCurrency() + "\n"
      + "Magic       : " + IntegerToString(MagicNumber);

   Comment(txt);
  }
//+------------------------------------------------------------------+
