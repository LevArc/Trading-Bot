#property copyright "Copyright 2025, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"


#include <MovingAverages.mqh>  
#include <trade/trade.mqh>


input ENUM_TIMEFRAMES Timeframe = PERIOD_H1;
input double lot = 0; //initial ammount of lot to buy
input int FollowTrend = 0; //0 means its turned off, 1 is turned on
input int CounterTrend = 0; //0 means its turned off, 1 is turned on
input int addLot = 0;
input double FollowTP = 5;
input double CounterTP = 3;

long totalBar;
int EMA200Handler; 
int EMA50Handler;
int trend;
double FiboLevels[] = {0.27, 0.618,1.618,3.236}; //setting percantage for fibo levels
double Layers[] = {0,5,8,13,21,34,55, 89};
double buyPrice[]; //saves buy price
double buyLot[]; //saves amount of lot bought
int buyLayer = 0;
double sellPrice[]; //saves sell price
double sellLot[]; //saves ammount of lot sold
CTrade trade;

double lowestBuy();

int OnInit()
  {
   Print("Expert Succesfully added");
   EMA200Handler = iMA(NULL,Timeframe,200,0,MODE_EMA,PRICE_CLOSE);
   EMA50Handler = iMA(NULL,Timeframe,50,0,MODE_EMA,PRICE_CLOSE);
   setTrend();
   totalBar = iBars(NULL, Timeframe);
   if (trend == 1){
      Print("Uptrend");
   }else if (trend == -1){
      Print("Downtrend");
   }
   
   return(INIT_SUCCEEDED);
  }
  

void OnDeinit(const int reason)
  {
//---
   
  }


void OnTick()
  {
      long currentBar = iBars(NULL,Timeframe);
      if (currentBar != totalBar){
         totalBar = currentBar;
         closeAllPending();
         openOrderBuy();
      }
  }   
//+------------------------------------------------------------------+

void setTrend(){ //1 is uptrend and -1 is downtrend (WORKS)
   double ema200[];
   double ema50[];
   CopyBuffer(EMA200Handler,0,1,1,ema200);
   CopyBuffer(EMA50Handler,0,1,1,ema50);
   if (ema50[0] > ema200[0]){
      trend = 1;
   }else{
      trend = -1;
   }
}

bool checkInsideCandle(){ //returns TRUE if inside candle and FALSE if NOT inside candle (WORKS)
   double highNew = iHigh(NULL, Timeframe,1);
   double lowNew = iLow(NULL, Timeframe,1);
   double highOld = iHigh(NULL, Timeframe,2);
   double lowOld = iLow(NULL, Timeframe,2);
   Print(highNew, lowNew, highOld, lowOld);
   if (highNew <= highOld && lowNew >= lowOld){
      return true;
   }else{
      return false;
   }
}


void openOrderBuy(){
   setTrend();
   double prevBuy = lowestBuy();
   double high = iHigh(NULL, Timeframe,1);
   double low = iLow(NULL, Timeframe,1);
   double diff = high - low;
   double fiboVal[];
   ArrayResize(fiboVal, ArraySize(FiboLevels));
   for(int i = 0; i < ArraySize(FiboLevels);i++){
      double temp = low - (FiboLevels[i]*diff);
      fiboVal[i] = temp;
   }
   if (trend == 1){
      for(int i = 0; i < ArraySize(fiboVal);i++){
         double vol = lot+(addLot*buyLayer);
         double price = fiboVal[i];
         if (buyLayer == 0){
            Print("buy order pending at : ", price);
            trade.BuyLimit(vol,fiboVal[0],NULL,0,price + FollowTP);
            buyLayer++;
            prevBuy = price;
            continue;
         }
         
         if (int(prevBuy) - int(price) < Layers[buyLayer]){
            continue;
         }else{
            Print("buy order pending at : ", price);
            trade.BuyLimit(vol,price,NULL);
            buyLayer++;
            prevBuy = price;
         }
      }
   }
}

void closeAllPending(){
   for(int i = 0; i < OrdersTotal();i++){
      ulong posTicket = OrderGetTicket(i);
      trade.OrderDelete(posTicket);    
   }
}



double lowestBuy(){
   double lowBuy = 0;
   for(int i = 0; i < PositionsTotal();i++){
      ulong posTicket = PositionGetTicket(i);
      
      if (PositionSelectByTicket(posTicket) && PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY){
         if (lowBuy == 0){
            lowBuy = PositionGetDouble(POSITION_PRICE_OPEN);
         }else{
            if (PositionGetDouble(POSITION_PRICE_OPEN) < lowBuy){
               lowBuy = PositionGetDouble(POSITION_PRICE_OPEN);
            }
         }
      }
    }
   return lowBuy;
}
