//RSI levels are from 0-100, select levels for overbought and oversold
// and the input to RSI

input int InpRSIPeriods = 14; //RSI periods
input ENUM_APPLIED_PRICE InpRSIPrice = PRICE_CLOSE; // RSI applied price

// the levels
input double inpOverSoldLevel = 30; //Oversold level
input double inpOverBoughtLevel = 70; //overbought level

//take profit and stop loss as exit criteria for each trade
//a simple way to exit
input double inpTakeProfit = 0.01; //take profit in currency value (e.g. 0.01 100 pips for currency other than jpy/usd)
input double inpStopLoss = 0.01; //stop loss in currency value (e.g. 0.01 100 pips for currency other than jpy/usd)

//standard inputs - you should have something like this is every EA
input double inpOrderSize = 0.01; //order size - start small. 0.01 normal contract = 10,000 units of first currency, e.g. 0.01 contract of GBP/USD is 10,000 pound
input string inpTradeComment = "beginner rsi"; //trade comment 
input int inpMagicNumber = 212121; //magic number - unique to different EA to identify the actions of different EA
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() 
//"int OnInit" is called once at beginning of EA and everytime it is reinitialised, e.g. when you change global input variable. while EA is running, you can decide to change the global input variable halfway
//    for this strategy, these trades are "set and forget" type of trade, once opened, the stop loss and take profit will close the out
//    this EA does not keep track of it, thats why the magic number is NOT important in this case
  {
   ENUM_INIT_RETCODE result = INIT_SUCCEEDED; //define a variable called"result", and it is a enum_init_retcode
   
   result = CheckInput(); //create a function called "checkinput" where im going to validate that the inputs are sensible in this case. checkinput returns a value of type enum_init_retcode which is assigned back to "result"
   if (result!=INIT_SUCCEEDED) return (result); //exit if inputs were bad (or, exit if CheckInput fails). the EA will stop here, and there will be an error message in the log
   
   //there may be other things to do here, but not in this example
   
   return(INIT_SUCCEEDED); //the return value must be a variable within enum_init_retcode 
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
//there may be other things to do here, but not in this example
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick(){
 
//---
// must work in EA happens under "void ontick()"
//event handler called for any price event, price change, new trade, many things

   static bool oversold = false; 
//static - variable exist and have a lifetime within the code block, 
//    and static is the limit you assign to them in this case. without static, for every tick event, all variables in "void OnTick()" get initialised again
//    at the start, oversold = false. each time function is called after that, they will still have the value the last time they were called 
//    in this case, i want oversold to have the lifetime of more than just one function, because i need to know if the previous tick is oversold or overbought
//    alternatively, you can put this is global scope, as global scope also exist outside the lifetime of this one function, but i prefer to keep things as tightly scoped as possible
   static bool overbought = false; 
   
   //perform any calculations and analysis here
   
   if (!NewBar()) return; //only trade on a new bar. if it is not a new bar, then it must an existing bar, which is bar 0

   //if rsi is 70, i will sell if bar 1 is downward candle.
   //if rsi is 30, i will buy if bar 1 is upward candle
   
   //v bar 0 is currently open, bar 1 is the most recent closed bar and 2 is the bar before that 
   double rsi = iRSI(Symbol(), Period(), InpRSIPeriods, InpRSIPrice, 1); //"1" means this ris is for bar 1
  

   double direction  = iClose(Symbol(), Period(),1)-iOpen(Symbol(),Period(),1);
   //get the direction of the last bar, this will just give a positive number
   //    for up and a negative number for down   
   
   //if rsi has crossed the midpoint then clear any old flags
   if (rsi>50){
      oversold = false; //if rsi is above 50, it has moved out of the oversold territory of <50
   }else
   if (rsi< 50){
      overbought = false;
  }
  
   //next check if the flags should be set
   //note not just assigning the comparison to the value
   //    this keeps any flags (e.g. overbought flag) already set intact
   //this code is wrong: overbought = (rsi > inpOverBoughtLevel); -this code will change to false once RSI move down to 79
   //this code is correct:  if (rsi>inpOverBoughtLevel) overbought = true; - this code will stay true even if RSI move down to 79
   if (rsi>inpOverBoughtLevel) overbought = true;
   if (rsi<inpOverSoldLevel) oversold = true;
   
   //actual trading logic
   //if there is a flag set (e.g. overbought flag set) and the bar moved in the right direction, make a trade
   //trading rules are: 
   //buy if: 
   //    oversold is true
   //    rsi is greater than oversold (has come out of oversold, which is set as 30 in the global input variable)
   // last bar was an up bar
   //sell if:
   //    overbought is true
   //    rsi is lower than overbought (has come out of overbought range, which is set at 70 in the global input variable)
   //    last bar was a down bar
   int ticket = 0; 
   //create a "ticket" variable to hold the ticket nu,ber that im going to get back from a trade
   //    when open an order you get a ticket number back, if opening of order fails the ticket number is going to be 0
   //    in this example, there is no checks in this EA for that, but it is a good idea to test the ticket number that come back to make sure 
   //    your trades have worked 
   if (oversold && (rsi>inpOverSoldLevel) && (direction>0)){ 
      ticket = OrderOpen(ORDER_TYPE_BUY, inpStopLoss, inpTakeProfit);
      oversold = false; //reset
   }else
   if (overbought && (rsi < inpOverBoughtLevel) && (direction <0)){
      ticket = OrderOpen(ORDER_TYPE_SELL, inpStopLoss, inpTakeProfit);
      overbought = false;
   }
   return;
}
   
 
//+----------custom functions after void OnTick()--------------------------------------------------------+

ENUM_INIT_RETCODE CheckInput() //enum_init_retcode is a datatype, similar as "int x" 
{
   //put some code here to check any input rules
   //im just going to say periods must be positive
   if (InpRSIPeriods <= 0) return (INIT_PARAMETERS_INCORRECT);
   return (INIT_SUCCEEDED); //else, return INIT_SUCCEEDED
   
 
   }

//+------------------------------------------------------------------+

bool NewBar(){
   datetime currentTime = iTime(Symbol(), Period(), 0); 
   //gets the opening time of bar 0. symbol() return the symbol of current chart where EA is running. period() is the current time frame on current chart. 0 - is the bar number to get its opening time
   static datetime priorTime = currentTime; //this initisalisation only happens the first time. if at 12noon, bar 0's currentTime is 12noon. when a new bar is created at 12:01pm, it is different from the "=currentTime that was only initiated once at initiation, which is 12noon"
   //use static if you want system to remeber the last value. the variable need to have a value when initialised, thats why =currentTime
   bool result = (currentTime!=priorTime);
   //time has changed. when a new bar is opened, priorTime = currentTime.
   //at initlisation, set currentTime as the open time of bar 0. at initilisation, priorTime = currentTime, hence "result" will come back as false, which means i dont have a new bar.  
   //    when a new bar is opened (bar 1), currentTime != iTime of bar 0, "datetime currentTime = bar 1's open time". hence "bool result" will return true as "datetime currentTime of bar 1 != static curentTime of bar 0"
   priorTime = currentTime; //reset for next time. this currentTime is "the latest and in-progress datetime currentTime", not the "once-off static curentTime"
   return(result);
}

//+------------------------------------------------------------------+
//simple function to open a new order
int OrderOpen(ENUM_ORDER_TYPE orderType, double stopLoss, double takeProfit) {   //order is executed at market price
   int ticket; //to capture the ticket number that comes back from the function
   double openPrice;
   double stopLossPrice;
   double takeProfitPrice;
   
   //calculate the open price, take profit and stop lsos prices based on the order type
   if (orderType == ORDER_TYPE_BUY){
      openPrice = NormalizeDouble(SymbolInfoDouble(Symbol(),SYMBOL_ASK), Digits()); //normaliseDouble(x,digits) rounds off symbol_ask to the digits of gbp/usd. in case some broker's symbol_asm != Digits()
      //v ternary operator (format: a,b? c: d), because it makes things look neat
      //same as saying
      //    if (stopLoss==0.0)
      //    {stopLossPrice = 0.0}
      //    else {stopLossPrice = NormalizeDouble(openPrice - stopLoss, Digits()); }
      stopLossPrice = (stopLoss==0.0)? 0.0 : NormalizeDouble(openPrice - stopLoss, Digits());
      // ^if stoploss = 0, then stoplossprice = 0, mt4 will ignore this stoplossprice. if stoploss !=0, then normaliseDouble(,)
      takeProfitPrice = (takeProfit == 0.0) ? 0.0 : NormalizeDouble(openPrice + takeProfit, Digits());
   } else if (orderType == ORDER_TYPE_SELL) {
      openPrice = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_BID), Digits());
      stopLossPrice = (stopLoss == 0.0) ? 0.0: NormalizeDouble(openPrice + stopLoss, Digits());
      takeProfitPrice = (takeProfit == 0.0)? 0.0: NormalizeDouble(openPrice - takeProfit, Digits());
   } else {
      // this function only works with type buy or sell, in case user do something
      return (-1); //this ia a "guard clause". this is an error ticket number, will lead to error, this trade fail
   }
   
   ticket = OrderSend(Symbol(), orderType, inpOrderSize, openPrice,0 , stopLossPrice, takeProfitPrice, inpTradeComment, inpMagicNumber);
   //^ this line of code executes the trade. symbol() is the chart symbol
   // orderType = ORDER_TYPE_BUY or ORDER_TYPE_SELL
   // inpOrderSize = 0.01 (see input global variable)
   // openPrice = if ORDER_TYPE_BUY, open price = SYMBOL_ASK. 
   //             if ORDER_TYPE_SELL, open price = SYMBOL_BID
   // slippage = 0, which means ANY slippage is ok. if there is fast market movement/ high volatility, slippage will be high. 
   // inpTradeComment = see input global variable
   // inpMagicNumber = see input global variable
   
   
   // check return codes here if needed
   
   return (ticket); //if OrderSend succeed, return valid ticket number > 0, 
                    // if fails, return value of <= 0
   
   
} 
  
   
