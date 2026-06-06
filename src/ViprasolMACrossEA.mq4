//+------------------------------------------------------------------+
//|                                         ViprasolMACrossEA.mq4     |
//|              Part of MT4 Expert Advisor by Viprasol Tech Pvt Ltd  |
//|                                          https://viprasol.com     |
//+------------------------------------------------------------------+
#property copyright "2025 Viprasol Tech Private Limited"
#property link      "https://viprasol.com"
#property version   "1.00"
#property description "Moving-average crossover EA with risk-based lot sizing and ATR stops (MQL4)."
#property strict

//--- Inputs
input int    FastPeriod  = 12;        // Fast EMA period
input int    SlowPeriod  = 26;        // Slow EMA period
input double RiskPercent = 1.0;       // Risk per trade (% of equity)
input int    ATRPeriod   = 14;        // ATR period for stops
input double SL_ATR      = 2.0;       // Stop-loss = SL_ATR * ATR
input double TP_ATR      = 3.0;       // Take-profit = TP_ATR * ATR
input int    MagicNumber = 20250101;  // EA magic number
input int    Slippage    = 30;        // Max slippage (points)

//+------------------------------------------------------------------+
int OnInit()
  {
   if(FastPeriod >= SlowPeriod)
     {
      Print("FastPeriod must be smaller than SlowPeriod");
      return(INIT_PARAMETERS_INCORRECT);
     }
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Risk-based lot sizing over the stop distance (in price)          |
//+------------------------------------------------------------------+
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
   double lots = riskMoney / moneyPerLot;

   double minLot  = MarketInfo(Symbol(), MODE_MINLOT);
   double maxLot  = MarketInfo(Symbol(), MODE_MAXLOT);
   double lotStep = MarketInfo(Symbol(), MODE_LOTSTEP);
   if(lotStep > 0.0) lots = MathFloor(lots / lotStep) * lotStep;
   lots = MathMax(minLot, MathMin(maxLot, lots));
   return(lots);
  }

//+------------------------------------------------------------------+
//| True if this EA already holds a position on this symbol          |
//+------------------------------------------------------------------+
bool HasOpenPosition(int &ticketType)
  {
   for(int i = OrdersTotal() - 1; i >= 0; i--)
     {
      if(!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;
      if(OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumber)
        {
         ticketType = OrderType();
         return(true);
        }
     }
   return(false);
  }

//+------------------------------------------------------------------+
void ClosePositions()
  {
   for(int i = OrdersTotal() - 1; i >= 0; i--)
     {
      if(!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;
      if(OrderSymbol() != Symbol() || OrderMagicNumber() != MagicNumber) continue;
      if(OrderType() == OP_BUY)
         OrderClose(OrderTicket(), OrderLots(), Bid, Slippage, clrRed);
      else if(OrderType() == OP_SELL)
         OrderClose(OrderTicket(), OrderLots(), Ask, Slippage, clrRed);
     }
  }

//+------------------------------------------------------------------+
void OnTick()
  {
   static datetime lastBar = 0;
   if(Time[0] == lastBar) return;
   lastBar = Time[0];

   // Closed-bar EMA values: shift 1 (last closed) and shift 2 (previous)
   double fastCur  = iMA(Symbol(), 0, FastPeriod, 0, MODE_EMA, PRICE_CLOSE, 1);
   double fastPrev = iMA(Symbol(), 0, FastPeriod, 0, MODE_EMA, PRICE_CLOSE, 2);
   double slowCur  = iMA(Symbol(), 0, SlowPeriod, 0, MODE_EMA, PRICE_CLOSE, 1);
   double slowPrev = iMA(Symbol(), 0, SlowPeriod, 0, MODE_EMA, PRICE_CLOSE, 2);
   double atr      = iATR(Symbol(), 0, ATRPeriod, 1);

   bool crossUp   = (fastPrev <= slowPrev) && (fastCur > slowCur);
   bool crossDown = (fastPrev >= slowPrev) && (fastCur < slowCur);

   int posType = -1;
   if(HasOpenPosition(posType))
     {
      if((posType == OP_BUY && crossDown) || (posType == OP_SELL && crossUp))
         ClosePositions();
      return;
     }

   if(!crossUp && !crossDown) return;

   double slDist = SL_ATR * atr;
   double tpDist = TP_ATR * atr;
   double lots   = LotForRisk(slDist);
   if(lots <= 0.0) return;

   if(crossUp)
     {
      double sl = NormalizeDouble(Bid - slDist, Digits);
      double tp = NormalizeDouble(Bid + tpDist, Digits);
      OrderSend(Symbol(), OP_BUY, lots, Ask, Slippage, sl, tp,
                "Viprasol MA cross long", MagicNumber, 0, clrGreen);
     }
   else
     {
      double sl = NormalizeDouble(Ask + slDist, Digits);
      double tp = NormalizeDouble(Ask - tpDist, Digits);
      OrderSend(Symbol(), OP_SELL, lots, Bid, Slippage, sl, tp,
                "Viprasol MA cross short", MagicNumber, 0, clrRed);
     }
  }
//+------------------------------------------------------------------+
