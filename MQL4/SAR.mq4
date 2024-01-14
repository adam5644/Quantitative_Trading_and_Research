//diff between audusd_sar3 and audusd_sar is that the third version has all the warnings removed

// (1) parabolic stop and reverse (parabolic sar):
//(1a) used to confirm the current trend: when parabola line is above price, this is dwntrend,
//...above price during a uptrend. you long durig uptrend, and short during downtrend
//...(1b)another interpretation: when price crosses the parabola line, this signals a price reversal, hence a potential entance/exit in opposite
//... direction as the current trend.
//...(1c)another way to use it is to set stop loss and limit levels at SAR levels
//...
//audusd
// (2) to optimise,default = 1 trade at any time
// close exisiting positions at the next reversal
// (4)to optimise,default = 15 min timeframe (just enough for chart to show 1 day of data)
// (5)backtest on the last 5 years
//upcoming: use average directional index momentum indicator to confirm the strength of the existing trend. other complements of SAR include moving averages and candlestick patterns. For example, when the asset price falls below a long-term moving average, it confirms the sell signal that is produced by the Parabolic SAR. If the price is above the moving average, focus on taking the buy signals.


//control panel
extern string symbol1="AUDUSD.s";
extern ENUM_TIMEFRAMES timeframe1=PERIOD_M15;
/*"extern int" usage comes from https://www.mql5.com/en/forum/356003
"int" means default input
"extern int" means a default input that can be changed in the code
*/
extern double lot1= 0.01; 
//ig gui minimum lot size of audusd and audusd mini is 0.5, but ig mt4 audusd.s accept 0.01 lot size.
extern int parameter1 = 0; 
//nearest n bars. if these n bars is long, then ill open a long trade. e,g, if parameter1=2, i want it be: 0,1,2 (note: start with zero)
extern int parameter2 = 0; 
//next n bars after the nearest n bars, rule of thumb: parameter2 > parameter1. e.g. if parameter2=9, i want it be to: 1,2,3,...,8,9 (note: no zero)
double slippage1 = MathAbs(int( 2.0 * (Ask - Bid) / _Point));
//https://www.mql5.com/en/forum/158834

//+------------------------------------------------------------------+
//| start of void ontick()                                                                 |
//+------------------------------------------------------------------+
void OnTick()
{
// close exisitng position at next reversal
   if (OrdersTotal()!=0)
   {
      OrderSelect(0, SELECT_BY_POS);
      int type   = OrderType();
      if(test_short(parameter1, parameter2)==TRUE)
        {
         switch(type)
           {
            //Close opened long positions
            case OP_BUY       :
               OrderClose(OrderTicket(), OrderLots(), OrderClosePrice(), slippage1, Green);
               break;
            //Close opened short positions
            case OP_SELL      :
               break;
           }
        }
      if(test_long(parameter1, parameter2)==TRUE)
        {
         switch(type)
           {
            //Close opened long positions
            case OP_BUY       :
               break;
            //Close opened short positions
            case OP_SELL      :
               OrderClose(OrderTicket(), OrderLots(), OrderClosePrice(), slippage1, Red);
               break;
           }
        }
   }
//if no existing positions, trade; else, no trade
//(1b) trade reversal when sar line crosses price line. if 5 dots is uptrend, then current trend is uptrend

   if(OrdersTotal()==0)
     {
      //if sar strategy suggests long, i long; if suggests short, i short
      if(
         test_long(parameter1, parameter2)==TRUE
      )
        {long1();}
        
      if(
         test_short(parameter1, parameter2)==TRUE
      )
        {short1();}
     }
}

//+------------------------------------------------------------------+
//| end of void ontick()                                                                   |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| custom function                                                                 |
//+------------------------------------------------------------------+

//custom functions after void OnTick()
//(1a) custom function to long
//(1b) custom function to short
//(1) sar value
double sar(int x) //x is shift. x=0 means current sar, current tick's sar. x=1 means previous tick's sar. 1 tick is about 0.2s-0.5s
  {
   double sar1 = iSAR(symbol1,timeframe1,0.02,0.2,x);
   return(sar1);
  }

//+------------------------------------------------------------------+
//| custom function                                                                 |
//+------------------------------------------------------------------+
void short1()
  {
   OrderSend(symbol1, OP_SELL, lot1, Bid,slippage1,NULL,NULL,NULL,NULL,NULL, Red);      //5 is 0.5 pip of splippage
//30pip is average volatility during 9pm-10pm sgt for gbpusd
//take profit = (30pip + spread (0.7pip) )*1.01=31.007pip  //1% is my profit
//stop loss = 15 pip
  }

//+------------------------------------------------------------------+
//| custom function                                                                 |
//+------------------------------------------------------------------+
void long1()
  {
   OrderSend(symbol1, OP_BUY, lot1, Ask,slippage1,NULL,NULL, NULL,NULL,NULL, Green);        //5 is 0.5 pip of splippage
//take profit = (15pip + spread (1.2pip) )*1.01=16.362pip  //1% is my profit
//stop loss = 15 pip
  }

//+------------------------------------------------------------------+
//| custom function                                                                 |
//+------------------------------------------------------------------+
bool test_long(int x, int y) //if x = 9, it means last 10 sar values, because start counting from 0
{
   int a = 0;
   //test nearest x bars (i.e. new sar) 
   for(int z=0; z<=x; z++) //if x = 2. z=0,1,2 (3 number). max a = 3
     {
      if((sar(z)< Close[z]))
        {a+= 1;}
     }
    
   //2 paths for the next nearest y bars
      if (((x=0)&&(y=0))||((x=1)&&(y=0)))
         {
         for(int z=x; z<=x+y; z++)//if x=2, y = 9. z=3,4,5,...,8,9 (9 number)
           {
            //test next y bars (i.e. old sar)
            if((sar(z)> Close[z])) //max a = 3 + 9 = 12
              {a+= 1;}
           }
            if(a==x+y+2) //if x = 2, y =9. a=0,1,2,..,
              {return TRUE;}
            else
              {return FALSE;}
         }
   //2 paths for the next nearest y bars     
      else
         {
         for(int z=x+1; z<=x+y; z++) //if x=2, y = 9. z=3,4,5,...,8,9 (9 number)
           {
            //test if next nearest y bars is increasing. sar is support and breaking which signals a short
            if((sar(z)> Close[z])) //max a = 3 + 9 = 12
              {a+= 1;}
           }
            if(a==x+y+1) //if x = 2, y =9. a=0,1,2,..,
              {return TRUE;}
            else
              {return FALSE;}
         }
}   
//+------------------------------------------------------------------+
//| custom function                                                                 |
//+------------------------------------------------------------------+
bool test_short(int x, int y) //if x = 9, it means last 10 sar values, because start counting from 0
{
   int a = 0;
   //test nearest x bars (i.e. new sar) 
   for(int z=0; z<=x; z++) //if x = 2. z=0,1,2 (3 number). max a = 3
     {
      if((sar(z)> Close[z]))
        {a+= 1;}
     }
    
   //2 paths for the next nearest y bars
      if (((x=0)&&(y=0))||((x=1)&&(y=0)))
         {
         for(int z=x; z<=x+y; z++)//if x=2, y = 9. z=3,4,5,...,8,9 (9 number)
           {
            //test next y bars (i.e. old sar)
            if((sar(z)< Close[z])) //max a = 3 + 9 = 12
              {a+= 1;}
           }
            if(a==x+y+2) //if x = 2, y =9. a=0,1,2,..,
              {return TRUE;}
            else
              {return FALSE;}
         }
   //2 paths for the next nearest y bars     
      else
         {
         for(int z=x+1; z<=x+y; z++) //if x=2, y = 9. z=3,4,5,...,8,9 (9 number)
           {
            //test if next nearest y bars is increasing. sar is support and breaking which signals a short
            if((sar(z)< Close[z])) //max a = 3 + 9 = 12
              {a+= 1;}
           }
            if(a==x+y+1) //if x = 2, y =9. a=0,1,2,..,
              {return TRUE;}
            else
              {return FALSE;}
         }
}   
      