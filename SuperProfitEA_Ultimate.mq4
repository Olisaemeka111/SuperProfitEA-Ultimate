//+------------------------------------------------------------------+
//|                                           SuperProfitEA_Ultimate.mq4|
//|                        Copyright 2024, Ultimate Combined Strategy  |
//|                                                                  |
//+------------------------------------------------------------------+
#property strict

// Input parameters - General Settings
extern string EA_Name = "SuperProfitEA_Ultimate";
extern string EA_Version = "2.0";
extern string TimeFrames = "Works best on H1, M30, M15, M5";

// Money Management
extern double InitialLots = 0.01;
extern double LotExponent = 1.18;
extern int lotdecimal = 2;
extern double MaxLots = 10.0;
extern bool UseMoneyManagement = true;
extern double RiskPercent = 2.0;
extern double TakeProfit = 100.0;
extern double StopLoss = 50.0;

// Trade Management
extern int MaxTrades = 20;
extern bool UseTrailingStop = true;
extern double TrailStart = 15.0;
extern double TrailStop = 5.0;
extern double slip = 3.0;

// Williams %R Settings
extern int WilliamsR_Period = 14;
extern double WilliamsR_BuyLevel = -90.0;
extern double WilliamsR_SellLevel = -10.0;
extern double WilliamsR_CloseBuyLevel = -30.0;
extern double WilliamsR_CloseSellLevel = -70.0;

// Moving Average Settings
extern int FastMA_Period = 20;
extern int SlowMA_Period = 50;
extern int SignalMA_Period = 9;
extern ENUM_MA_METHOD MA_Method = MODE_EMA;
extern ENUM_APPLIED_PRICE MA_Price = PRICE_CLOSE;

// RSI Settings
extern int RSI_Period = 14;
extern int RSI_BuyLevel = 30;
extern int RSI_SellLevel = 70;

// CCI Settings (from EA 2)
extern int CCI_Period = 13;
extern double CCI_BuyLevel = -100.0;
extern double CCI_SellLevel = 100.0;

// Stochastic Settings (from EA 2)
extern int Stoch_K_Period = 5;
extern int Stoch_D_Period = 3;
extern int Stoch_Slowing = 3;
extern double Stoch_BuyLevel = 20.0;
extern double Stoch_SellLevel = 80.0;

// Bollinger Bands Settings
extern int BB_Period = 20;
extern double BB_Deviation = 2.0;
extern double BB_BuyLevel = 0.2;  // Price near lower band
extern double BB_SellLevel = 0.8; // Price near upper band

// MACD Settings
extern int MACD_Fast = 12;
extern int MACD_Slow = 26;
extern int MACD_Signal = 9;

// Profit Target Settings
extern bool UseEquityStop = true;
extern double TotalEquityRisk = 20.0;
extern bool ProfitTargetInPips = false;
extern double ProfitTarget = 25.0;
extern bool CloseAllNow = false;
extern bool CloseProfitableTradesOnly = false;
extern double ProfitableTradeAmount = 1.0;

// Advanced Settings
extern bool UseMultiTimeframe = true;
extern bool UseNewsFilter = false;
extern bool UseVolatilityFilter = true;
extern double MinSpread = 3.0;
extern double MaxSpread = 50.0;

// Global Variables
int totalBuyTrades = 0;
int totalSellTrades = 0;
int Multiplier;
double pips2dbl;
double lastBuyPrice = 0;
double lastSellPrice = 0;
datetime lastTradeTime = 0;
bool isNewBar = false;
datetime lastBarTime = 0;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    // Initialize variables
    BrokerDigitAdjust(Symbol());
    
    // Display EA information
    Comment("SuperProfitEA Ultimate v2.0 - Combined Strategy System\n",
            "Timeframe: ", TimeframeToString(Period()), "\n",
            "Symbol: ", Symbol(), "\n",
            "Spread: ", MarketInfo(Symbol(), MODE_SPREAD), " points");
    
    return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    Comment("");
    ObjectsDeleteAll(0, OBJ_LABEL);
}

//+------------------------------------------------------------------+
//| Check for new bar                                                |
//+------------------------------------------------------------------+
bool IsNewBar()
{
    datetime currentBarTime = iTime(Symbol(), Period(), 0);
    if(currentBarTime != lastBarTime)
    {
        lastBarTime = currentBarTime;
        return true;
    }
    return false;
}

//+------------------------------------------------------------------+
//| Calculate lot size based on risk                                 |
//+------------------------------------------------------------------+
double CalculateLotSize()
{
    double lotSize = InitialLots;
    
    if(UseMoneyManagement)
    {
        double riskAmount = AccountBalance() * (RiskPercent / 100.0);
        double tickValue = MarketInfo(Symbol(), MODE_TICKVALUE);
        double tickSize = MarketInfo(Symbol(), MODE_TICKSIZE);
        
        if(StopLoss > 0 && tickValue > 0 && tickSize > 0)
        {
            lotSize = NormalizeDouble(riskAmount / (StopLoss * tickValue / tickSize), lotdecimal);
        }
        
        // Ensure lot size is within allowed range
        double minLot = MarketInfo(Symbol(), MODE_MINLOT);
        double maxLot = MarketInfo(Symbol(), MODE_MAXLOT);
        
        lotSize = MathMax(minLot, MathMin(lotSize, maxLot));
        lotSize = MathMin(lotSize, MaxLots);
    }
    
    return NormalizeDouble(lotSize, lotdecimal);
}

//+------------------------------------------------------------------+
//| Broker digit adjustment for pip calculation                      |
//+------------------------------------------------------------------+
void BrokerDigitAdjust(string symbol)
{
    Multiplier = 1;
    if(MarketInfo(symbol, MODE_DIGITS) == 3 || MarketInfo(symbol, MODE_DIGITS) == 5) Multiplier = 10;
    if(MarketInfo(symbol, MODE_DIGITS) == 6) Multiplier = 100;   
    if(MarketInfo(symbol, MODE_DIGITS) == 7) Multiplier = 1000;
    pips2dbl = Multiplier * MarketInfo(symbol, MODE_POINT); 
}

//+------------------------------------------------------------------+
//| Convert timeframe to string                                      |
//+------------------------------------------------------------------+
string TimeframeToString(int timeframe)
{
    switch(timeframe)
    {
        case PERIOD_M1:  return "M1";
        case PERIOD_M5:  return "M5";
        case PERIOD_M15: return "M15";
        case PERIOD_M30: return "M30";
        case PERIOD_H1:  return "H1";
        case PERIOD_H4:  return "H4";
        case PERIOD_D1:  return "D1";
        case PERIOD_W1:  return "W1";
        case PERIOD_MN1: return "MN1";
        default:         return "Unknown";
    }
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
    // Check if it's a new bar
    isNewBar = IsNewBar();
    
    // Update dashboard
    UpdateDashboard();
    
    // Check if we need to close all trades
    if(CloseAllNow)
    {
        CloseAll();
        return;
    }
    
    // Check if we need to close profitable trades only
    if(CloseProfitableTradesOnly)
    {
        CloseAllInProfit();
        return;
    }
    
    // Check profit target
    CheckProfitTarget();
    
    // Apply trailing stop to open positions
    if(UseTrailingStop)
    {
        ApplyTrailingStop();
    }
    
    // Only perform trade analysis on new bars for better performance
    if(isNewBar)
    {
        // Check market conditions
        if(!CheckMarketConditions()) return;
        
        // Get trading signals
        int buySignal = GetBuySignal();
        int sellSignal = GetSellSignal();
        
        // Check for close signals
        CheckCloseSignals();
        
        // Execute trades based on signals
        if(buySignal >= 3 && CountTrades(OP_BUY) < MaxTrades)
        {
            double lotSize = CalculateLotSize();
            double stopLossPrice = StopLoss > 0 ? Ask - StopLoss * pips2dbl : 0;
            double takeProfitPrice = TakeProfit > 0 ? Ask + TakeProfit * pips2dbl : 0;
            
            int ticket = OrderSend(Symbol(), OP_BUY, lotSize, Ask, slip, stopLossPrice, takeProfitPrice, 
                                  "SuperProfitEA Ultimate Buy", 12345, 0, Green);
            
            if(ticket > 0)
            {
                lastBuyPrice = Ask;
                lastTradeTime = TimeCurrent();
                totalBuyTrades++;
                Print("Buy order opened at price: ", Ask, " Signal strength: ", buySignal);
            }
            else
            {
                Print("Error opening buy order: ", GetLastError());
            }
        }
        
        if(sellSignal >= 3 && CountTrades(OP_SELL) < MaxTrades)
        {
            double lotSize = CalculateLotSize();
            double stopLossPrice = StopLoss > 0 ? Bid + StopLoss * pips2dbl : 0;
            double takeProfitPrice = TakeProfit > 0 ? Bid - TakeProfit * pips2dbl : 0;
            
            int ticket = OrderSend(Symbol(), OP_SELL, lotSize, Bid, slip, stopLossPrice, takeProfitPrice, 
                                  "SuperProfitEA Ultimate Sell", 12345, 0, Red);
            
            if(ticket > 0)
            {
                lastSellPrice = Bid;
                lastTradeTime = TimeCurrent();
                totalSellTrades++;
                Print("Sell order opened at price: ", Bid, " Signal strength: ", sellSignal);
            }
            else
            {
                Print("Error opening sell order: ", GetLastError());
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Check market conditions                                          |
//+------------------------------------------------------------------+
bool CheckMarketConditions()
{
    // Check spread
    double currentSpread = MarketInfo(Symbol(), MODE_SPREAD);
    if(currentSpread < MinSpread || currentSpread > MaxSpread)
    {
        return false;
    }
    
    // Check volatility
    if(UseVolatilityFilter)
    {
        double atr = iATR(NULL, 0, 14, 0);
        double avgATR = 0;
        for(int i = 1; i <= 10; i++)
        {
            avgATR += iATR(NULL, 0, 14, i);
        }
        avgATR /= 10;
        
        if(atr < avgATR * 0.5) // Too low volatility
        {
            return false;
        }
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Get buy signal strength (0-6)                                    |
//+------------------------------------------------------------------+
int GetBuySignal()
{
    int signalStrength = 0;
    
    // Williams %R signal
    double williamsR = iWPR(NULL, 0, WilliamsR_Period, 0);
    if(williamsR <= WilliamsR_BuyLevel && williamsR >= -100)
    {
        signalStrength++;
    }
    
    // Moving Average signal
    double fastMA = iMA(NULL, 0, FastMA_Period, 0, MA_Method, MA_Price, 0);
    double slowMA = iMA(NULL, 0, SlowMA_Period, 0, MA_Method, MA_Price, 0);
    
    if(fastMA > slowMA && Close[1] > slowMA)
    {
        signalStrength++;
    }
    
    // RSI signal
    double rsi = iRSI(NULL, 0, RSI_Period, PRICE_CLOSE, 0);
    if(rsi < RSI_BuyLevel)
    {
        signalStrength++;
    }
    
    // CCI signal
    double cci = iCCI(NULL, 0, CCI_Period, PRICE_TYPICAL, 0);
    if(cci < CCI_BuyLevel)
    {
        signalStrength++;
    }
    
    // Stochastic signal
    double stochK = iStochastic(NULL, 0, Stoch_K_Period, Stoch_D_Period, Stoch_Slowing, MODE_EMA, 0, MODE_MAIN, 0);
    double stochD = iStochastic(NULL, 0, Stoch_K_Period, Stoch_D_Period, Stoch_Slowing, MODE_EMA, 0, MODE_SIGNAL, 0);
    if(stochK < Stoch_BuyLevel && stochK > stochD)
    {
        signalStrength++;
    }
    
    // Bollinger Bands signal
    double bbUpper = iBands(NULL, 0, BB_Period, BB_Deviation, 0, PRICE_CLOSE, MODE_UPPER, 0);
    double bbLower = iBands(NULL, 0, BB_Period, BB_Deviation, 0, PRICE_CLOSE, MODE_LOWER, 0);
    double bbPosition = (Close[0] - bbLower) / (bbUpper - bbLower);
    if(bbPosition < BB_BuyLevel)
    {
        signalStrength++;
    }
    
    // MACD signal
    double macd = iMACD(NULL, 0, MACD_Fast, MACD_Slow, MACD_Signal, PRICE_CLOSE, MODE_MAIN, 0);
    double macdSignal = iMACD(NULL, 0, MACD_Fast, MACD_Slow, MACD_Signal, PRICE_CLOSE, MODE_SIGNAL, 0);
    if(macd > macdSignal && macd < 0)
    {
        signalStrength++;
    }
    
    // Multi-timeframe confirmation
    if(UseMultiTimeframe)
    {
        double williamsR_H1 = iWPR(NULL, PERIOD_H1, WilliamsR_Period, 0);
        if(williamsR_H1 <= -80)
        {
            signalStrength++;
        }
    }
    
    return signalStrength;
}

//+------------------------------------------------------------------+
//| Get sell signal strength (0-6)                                   |
//+------------------------------------------------------------------+
int GetSellSignal()
{
    int signalStrength = 0;
    
    // Williams %R signal
    double williamsR = iWPR(NULL, 0, WilliamsR_Period, 0);
    if(williamsR >= WilliamsR_SellLevel && williamsR <= 0)
    {
        signalStrength++;
    }
    
    // Moving Average signal
    double fastMA = iMA(NULL, 0, FastMA_Period, 0, MA_Method, MA_Price, 0);
    double slowMA = iMA(NULL, 0, SlowMA_Period, 0, MA_Method, MA_Price, 0);
    
    if(fastMA < slowMA && Close[1] < slowMA)
    {
        signalStrength++;
    }
    
    // RSI signal
    double rsi = iRSI(NULL, 0, RSI_Period, PRICE_CLOSE, 0);
    if(rsi > RSI_SellLevel)
    {
        signalStrength++;
    }
    
    // CCI signal
    double cci = iCCI(NULL, 0, CCI_Period, PRICE_TYPICAL, 0);
    if(cci > CCI_SellLevel)
    {
        signalStrength++;
    }
    
    // Stochastic signal
    double stochK = iStochastic(NULL, 0, Stoch_K_Period, Stoch_D_Period, Stoch_Slowing, MODE_EMA, 0, MODE_MAIN, 0);
    double stochD = iStochastic(NULL, 0, Stoch_K_Period, Stoch_D_Period, Stoch_Slowing, MODE_EMA, 0, MODE_SIGNAL, 0);
    if(stochK > Stoch_SellLevel && stochK < stochD)
    {
        signalStrength++;
    }
    
    // Bollinger Bands signal
    double bbUpper = iBands(NULL, 0, BB_Period, BB_Deviation, 0, PRICE_CLOSE, MODE_UPPER, 0);
    double bbLower = iBands(NULL, 0, BB_Period, BB_Deviation, 0, PRICE_CLOSE, MODE_LOWER, 0);
    double bbPosition = (Close[0] - bbLower) / (bbUpper - bbLower);
    if(bbPosition > BB_SellLevel)
    {
        signalStrength++;
    }
    
    // MACD signal
    double macd = iMACD(NULL, 0, MACD_Fast, MACD_Slow, MACD_Signal, PRICE_CLOSE, MODE_MAIN, 0);
    double macdSignal = iMACD(NULL, 0, MACD_Fast, MACD_Slow, MACD_Signal, PRICE_CLOSE, MODE_SIGNAL, 0);
    if(macd < macdSignal && macd > 0)
    {
        signalStrength++;
    }
    
    // Multi-timeframe confirmation
    if(UseMultiTimeframe)
    {
        double williamsR_H1 = iWPR(NULL, PERIOD_H1, WilliamsR_Period, 0);
        if(williamsR_H1 >= -20)
        {
            signalStrength++;
        }
    }
    
    return signalStrength;
}

//+------------------------------------------------------------------+
//| Check for close signals                                          |
//+------------------------------------------------------------------+
void CheckCloseSignals()
{
    double williamsR = iWPR(NULL, 0, WilliamsR_Period, 0);
    
    // Close buy positions when Williams %R is between -30 and 0
    if(williamsR >= WilliamsR_CloseBuyLevel && williamsR <= 0)
    {
        CloseTrades(OP_BUY);
    }
    
    // Close sell positions when Williams %R is between -100 and -70
    if(williamsR <= WilliamsR_CloseSellLevel && williamsR >= -100)
    {
        CloseTrades(OP_SELL);
    }
    
    // Additional close signals based on RSI
    double rsi = iRSI(NULL, 0, RSI_Period, PRICE_CLOSE, 0);
    if(rsi > 80)
    {
        CloseTrades(OP_BUY);
    }
    if(rsi < 20)
    {
        CloseTrades(OP_SELL);
    }
}

//+------------------------------------------------------------------+
//| Close trades of specified type                                   |
//+------------------------------------------------------------------+
void CloseTrades(int tradeType)
{
    for(int i = OrdersTotal() - 1; i >= 0; i--)
    {
        if(OrderSelect(i, SELECT_BY_POS) && OrderSymbol() == Symbol() && OrderMagicNumber() == 12345)
        {
            if(OrderType() == tradeType)
            {
                bool result = false;
                
                if(tradeType == OP_BUY)
                {
                    result = OrderClose(OrderTicket(), OrderLots(), Bid, slip, Green);
                    if(result) totalBuyTrades--;
                }
                else if(tradeType == OP_SELL)
                {
                    result = OrderClose(OrderTicket(), OrderLots(), Ask, slip, Red);
                    if(result) totalSellTrades--;
                }
                
                if(!result)
                {
                    Print("Error closing order: ", GetLastError());
                }
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Apply trailing stop to open positions                            |
//+------------------------------------------------------------------+
void ApplyTrailingStop()
{
    for(int i = 0; i < OrdersTotal(); i++)
    {
        if(OrderSelect(i, SELECT_BY_POS) && OrderSymbol() == Symbol() && OrderMagicNumber() == 12345)
        {
            if(OrderType() == OP_BUY)
            {
                if(Bid - OrderOpenPrice() > TrailStart * pips2dbl)
                {
                    if(OrderStopLoss() < Bid - TrailStop * pips2dbl)
                    {
                        bool result = OrderModify(OrderTicket(), OrderOpenPrice(), 
                                               Bid - TrailStop * pips2dbl, 
                                               OrderTakeProfit(), 0, Green);
                        if(!result)
                        {
                            Print("Error modifying buy order: ", GetLastError());
                        }
                    }
                }
            }
            else if(OrderType() == OP_SELL)
            {
                if(OrderOpenPrice() - Ask > TrailStart * pips2dbl)
                {
                    if(OrderStopLoss() > Ask + TrailStop * pips2dbl || OrderStopLoss() == 0)
                    {
                        bool result = OrderModify(OrderTicket(), OrderOpenPrice(), 
                                               Ask + TrailStop * pips2dbl, 
                                               OrderTakeProfit(), 0, Red);
                        if(!result)
                        {
                            Print("Error modifying sell order: ", GetLastError());
                        }
                    }
                }
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Count trades of specified type                                   |
//+------------------------------------------------------------------+
int CountTrades(int tradeType = -1)
{
    int count = 0;
    
    for(int i = 0; i < OrdersTotal(); i++)
    {
        if(OrderSelect(i, SELECT_BY_POS) && OrderSymbol() == Symbol() && OrderMagicNumber() == 12345)
        {
            if(tradeType == -1 || OrderType() == tradeType)
            {
                count++;
            }
        }
    }
    
    return count;
}

//+------------------------------------------------------------------+
//| Calculate total profit                                           |
//+------------------------------------------------------------------+
double CalculateProfit()
{
    double profit = 0;
    
    for(int i = 0; i < OrdersTotal(); i++)
    {
        if(OrderSelect(i, SELECT_BY_POS) && OrderSymbol() == Symbol() && OrderMagicNumber() == 12345)
        {
            profit += OrderProfit() + OrderSwap() + OrderCommission();
        }
    }
    
    return profit;
}

//+------------------------------------------------------------------+
//| Calculate total profit in pips                                   |
//+------------------------------------------------------------------+
double CalculateProfitPips()
{
    double profitPips = 0;
    
    for(int i = 0; i < OrdersTotal(); i++)
    {
        if(OrderSelect(i, SELECT_BY_POS) && OrderSymbol() == Symbol() && OrderMagicNumber() == 12345)
        {
            if(OrderType() == OP_BUY)
            {
                profitPips += (Bid - OrderOpenPrice()) / pips2dbl;
            }
            else if(OrderType() == OP_SELL)
            {
                profitPips += (OrderOpenPrice() - Ask) / pips2dbl;
            }
        }
    }
    
    return profitPips;
}

//+------------------------------------------------------------------+
//| Check if profit target is reached                                |
//+------------------------------------------------------------------+
void CheckProfitTarget()
{
    if(ProfitTargetInPips)
    {
        if(CalculateProfitPips() >= ProfitTarget)
        {
            CloseAll();
        }
    }
    else
    {
        if(CalculateProfit() >= ProfitTarget)
        {
            CloseAll();
        }
    }
    
    // Check equity stop
    if(UseEquityStop)
    {
        double currentEquity = AccountEquity();
        double maxEquity = AccountBalance() + CalculateProfit();
        
        if(maxEquity - currentEquity > TotalEquityRisk / 100.0 * AccountBalance())
        {
            CloseAll();
        }
    }
}

//+------------------------------------------------------------------+
//| Close all positions                                              |
//+------------------------------------------------------------------+
void CloseAll()
{
    for(int i = OrdersTotal() - 1; i >= 0; i--)
    {
        if(OrderSelect(i, SELECT_BY_POS) && OrderSymbol() == Symbol() && OrderMagicNumber() == 12345)
        {
            bool result = false;
            
            if(OrderType() == OP_BUY)
            {
                result = OrderClose(OrderTicket(), OrderLots(), Bid, slip, Green);
            }
            else if(OrderType() == OP_SELL)
            {
                result = OrderClose(OrderTicket(), OrderLots(), Ask, slip, Red);
            }
            
            if(!result)
            {
                Print("Error closing order: ", GetLastError());
            }
        }
    }
    
    totalBuyTrades = 0;
    totalSellTrades = 0;
}

//+------------------------------------------------------------------+
//| Close all profitable positions                                   |
//+------------------------------------------------------------------+
void CloseAllInProfit()
{
    for(int i = OrdersTotal() - 1; i >= 0; i--)
    {
        if(OrderSelect(i, SELECT_BY_POS) && OrderSymbol() == Symbol() && OrderMagicNumber() == 12345)
        {
            if(OrderProfit() + OrderSwap() + OrderCommission() > ProfitableTradeAmount)
            {
                bool result = false;
                
                if(OrderType() == OP_BUY)
                {
                    result = OrderClose(OrderTicket(), OrderLots(), Bid, slip, Green);
                    if(result) totalBuyTrades--;
                }
                else if(OrderType() == OP_SELL)
                {
                    result = OrderClose(OrderTicket(), OrderLots(), Ask, slip, Red);
                    if(result) totalSellTrades--;
                }
                
                if(!result)
                {
                    Print("Error closing profitable order: ", GetLastError());
                }
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Update dashboard with trading information                        |
//+------------------------------------------------------------------+
void UpdateDashboard()
{
    string comment = "";
    
    comment += "SuperProfitEA Ultimate v2.0 - Combined Strategy System\n";
    comment += "----------------------------------------------------\n";
    comment += "Symbol: " + Symbol() + ", Timeframe: " + TimeframeToString(Period()) + "\n";
    comment += "Spread: " + DoubleToStr(MarketInfo(Symbol(), MODE_SPREAD), 1) + " points\n";
    comment += "----------------------------------------------------\n";
    comment += "Williams %R: " + DoubleToStr(iWPR(NULL, 0, WilliamsR_Period, 0), 2) + "\n";
    comment += "RSI: " + DoubleToStr(iRSI(NULL, 0, RSI_Period, PRICE_CLOSE, 0), 2) + "\n";
    comment += "CCI: " + DoubleToStr(iCCI(NULL, 0, CCI_Period, PRICE_TYPICAL, 0), 2) + "\n";
    comment += "Stoch K: " + DoubleToStr(iStochastic(NULL, 0, Stoch_K_Period, Stoch_D_Period, Stoch_Slowing, MODE_EMA, 0, MODE_MAIN, 0), 2) + "\n";
    comment += "Fast MA: " + DoubleToStr(iMA(NULL, 0, FastMA_Period, 0, MA_Method, MA_Price, 0), Digits) + "\n";
    comment += "Slow MA: " + DoubleToStr(iMA(NULL, 0, SlowMA_Period, 0, MA_Method, MA_Price, 0), Digits) + "\n";
    comment += "----------------------------------------------------\n";
    comment += "Buy Trades: " + IntegerToString(CountTrades(OP_BUY)) + "\n";
    comment += "Sell Trades: " + IntegerToString(CountTrades(OP_SELL)) + "\n";
    comment += "Total Profit: " + DoubleToStr(CalculateProfit(), 2) + " " + AccountCurrency() + "\n";
    comment += "Total Profit (Pips): " + DoubleToStr(CalculateProfitPips(), 1) + "\n";
    comment += "----------------------------------------------------\n";
    comment += "Balance: " + DoubleToStr(AccountBalance(), 2) + " " + AccountCurrency() + "\n";
    comment += "Equity: " + DoubleToStr(AccountEquity(), 2) + " " + AccountCurrency() + "\n";
    comment += "Margin: " + DoubleToStr(AccountMargin(), 2) + " " + AccountCurrency() + "\n";
    comment += "Free Margin: " + DoubleToStr(AccountFreeMargin(), 2) + " " + AccountCurrency() + "\n";
    double marginLevel = 0;
    if (AccountMargin() > 0)
        marginLevel = AccountEquity() / AccountMargin() * 100;
    else
        marginLevel = 0; // or you can display N/A
    comment += "Margin Level: " + DoubleToStr(marginLevel, 2) + "%\n";
    
    Comment(comment);
} 