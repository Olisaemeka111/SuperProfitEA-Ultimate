//+------------------------------------------------------------------+
//|                                    SuperProfitEA_MultiSymbol_Scanner.mq4|
//|                        Copyright 2024, Multi-Symbol Scanner System  |
//|                                                                  |
//+------------------------------------------------------------------+
#property strict

// Input parameters - General Settings
extern string EA_Name = "SuperProfitEA_MultiSymbol_Scanner";
extern string EA_Version = "3.0";
extern string TimeFrames = "Works best on H1, M30, M15, M5";

// Scanner Settings
extern bool EnableScanner = true;
extern int MaxSymbolsToTrade = 50;
extern int ScanInterval = 60; // Scan every 60 seconds
extern bool TradeOnlyMajors = true;
extern string CustomSymbols = ""; // Comma-separated symbols to include/exclude

// Money Management
extern double InitialLots = 0.01;
extern double LotExponent = 1.18;
extern int lotdecimal = 2;
extern double MaxLots = 10.0;
extern bool UseMoneyManagement = true;
extern double RiskPercent = 2.0;
extern double TakeProfit = 100.0;
extern double StopLoss = 0.0; // 0 = No Stop Loss (Let trades breathe)
extern bool UseNoStopLossMode = true; // Enable when StopLoss = 0

// Trade Management
extern int MaxTradesPerSymbol = 5;
extern int MaxTotalTrades = 100;
extern bool UseTrailingStop = true;
extern double TrailStart = 15.0;
extern double TrailStop = 5.0;
extern int slip = 3;

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

// CCI Settings
extern int CCI_Period = 13;
extern double CCI_BuyLevel = -100.0;
extern double CCI_SellLevel = 100.0;

// Stochastic Settings
extern int Stoch_K_Period = 5;
extern int Stoch_D_Period = 3;
extern int Stoch_Slowing = 3;
extern double Stoch_BuyLevel = 20.0;
extern double Stoch_SellLevel = 80.0;

// Bollinger Bands Settings
extern int BB_Period = 20;
extern double BB_Deviation = 2.0;
extern double BB_BuyLevel = 0.2;
extern double BB_SellLevel = 0.8;

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

// No Stop Loss Strategy Settings
extern bool UseBreakEvenMode = true; // Move to break-even after certain profit
extern double BreakEvenTrigger = 20.0; // Move to break-even after 20 pips profit
extern bool UseTrailingProfit = true; // Trail profit instead of using stop loss
extern double TrailingProfitStart = 30.0; // Start trailing after 30 pips profit

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
datetime lastScanTime = 0;
datetime lastBarTime = 0;

// Trade opportunity structure
struct TradeOpportunity
{
    string symbol;
    int signalType; // 1 = Buy, -1 = Sell
    int signalStrength;
    double signalScore;
    double spread;
    double volatility;
    datetime timestamp;
};

TradeOpportunity opportunities[];
int opportunityCount = 0;

// Major currency pairs
string majorPairs[] = {"EURUSD", "GBPUSD", "USDJPY", "USDCHF", "AUDUSD", "NZDUSD", "USDCAD", "EURGBP", "EURJPY", "GBPJPY", "CHFJPY", "AUDJPY", "NZDJPY", "CADJPY", "EURAUD", "GBPAUD", "AUDCAD", "AUDNZD", "GBPNZD", "EURNZD", "GBPCAD", "EURCAD", "GBPCHF", "EURCHF", "AUDCHF", "NZDCHF", "CADCHF", "NZDUSD", "USDSGD", "USDHKD", "USDSEK", "USDNOK", "USDDKK", "USDPLN", "USDCZK", "USDHUF", "USDRON", "USDBGN", "USDRUB", "USDTRY", "USDZAR", "USDBRL", "USDMXN", "USDINR", "USDCNY", "USDKRW", "USDTWD", "USDSGD", "USDTHB", "USDMYR", "USDPHP", "USDIDR"};

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    // Initialize variables
    BrokerDigitAdjust(Symbol());
    
    // Initialize opportunities array
    ArrayResize(opportunities, MaxSymbolsToTrade);
    opportunityCount = 0;
    
    // Display EA information
    Comment("SuperProfitEA Multi-Symbol Scanner v3.0\n",
            "Scanning all symbols for best trade opportunities\n",
            "Max Symbols to Trade: ", MaxSymbolsToTrade, "\n",
            "Scan Interval: ", ScanInterval, " seconds");
    
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
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
    // Check if it's time to scan
    if(EnableScanner && TimeCurrent() - lastScanTime >= ScanInterval)
    {
        ScanAllSymbols();
        lastScanTime = TimeCurrent();
    }
    
    // Update dashboard
    UpdateDashboard();
    
    // Check if we need to close all trades
    if(CloseAllNow)
    {
        CloseAllTrades();
        return;
    }
    
    // Check if we need to close profitable trades only
    if(CloseProfitableTradesOnly)
    {
        CloseAllProfitableTrades();
        return;
    }
    
    // Check profit target
    CheckProfitTarget();
    
    // Apply trailing stop to open positions
    if(UseTrailingStop)
    {
        ApplyTrailingStopAllSymbols();
    }
    
    // Check for close signals on all symbols
    CheckCloseSignalsAllSymbols();
    
    // Execute trades based on opportunities
    ExecuteTradeOpportunities();
}

//+------------------------------------------------------------------+
//| Scan all symbols for trade opportunities                         |
//+------------------------------------------------------------------+
void ScanAllSymbols()
{
    opportunityCount = 0;
    
    // Get all symbols from Market Watch
    for(int i = 0; i < SymbolsTotal(true); i++)
    {
        string symbol = SymbolName(i, true);
        
        // Skip if not a major pair (if enabled)
        if(TradeOnlyMajors && !IsMajorPair(symbol))
            continue;
            
        // Skip if symbol is in custom exclusion list
        if(IsSymbolExcluded(symbol))
            continue;
        
        // Check if symbol is tradeable
        if(!IsSymbolTradeable(symbol))
            continue;
        
        // Get trading signals for this symbol
        int buySignal = GetBuySignal(symbol);
        int sellSignal = GetSellSignal(symbol);
        
        // Check market conditions
        if(!CheckMarketConditions(symbol))
            continue;
        
        // Add buy opportunity if signal is strong enough
        if(buySignal >= 3 && opportunityCount < MaxSymbolsToTrade)
        {
            opportunities[opportunityCount].symbol = symbol;
            opportunities[opportunityCount].signalType = 1; // Buy
            opportunities[opportunityCount].signalStrength = buySignal;
            opportunities[opportunityCount].signalScore = CalculateSignalScore(symbol, buySignal, 1);
            opportunities[opportunityCount].spread = (double)MarketInfo(symbol, MODE_SPREAD);
            opportunities[opportunityCount].volatility = GetVolatility(symbol);
            opportunities[opportunityCount].timestamp = TimeCurrent();
            opportunityCount++;
        }
        
        // Add sell opportunity if signal is strong enough
        if(sellSignal >= 3 && opportunityCount < MaxSymbolsToTrade)
        {
            opportunities[opportunityCount].symbol = symbol;
            opportunities[opportunityCount].signalType = -1; // Sell
            opportunities[opportunityCount].signalStrength = sellSignal;
            opportunities[opportunityCount].signalScore = CalculateSignalScore(symbol, sellSignal, -1);
            opportunities[opportunityCount].spread = (double)MarketInfo(symbol, MODE_SPREAD);
            opportunities[opportunityCount].volatility = GetVolatility(symbol);
            opportunities[opportunityCount].timestamp = TimeCurrent();
            opportunityCount++;
        }
    }
    
    // Sort opportunities by signal score (best first)
    SortOpportunities();
    
    // Limit to MaxSymbolsToTrade
    if(opportunityCount > MaxSymbolsToTrade)
        opportunityCount = MaxSymbolsToTrade;
    
    Print("Scan completed. Found ", opportunityCount, " trade opportunities");
}

//+------------------------------------------------------------------+
//| Check if symbol is a major pair                                 |
//+------------------------------------------------------------------+
bool IsMajorPair(string symbol)
{
    for(int i = 0; i < ArraySize(majorPairs); i++)
    {
        if(StringFind(symbol, majorPairs[i]) == 0)
            return true;
    }
    return false;
}

//+------------------------------------------------------------------+
//| Check if symbol is excluded                                     |
//+------------------------------------------------------------------+
bool IsSymbolExcluded(string symbol)
{
    if(CustomSymbols == "")
        return false;
    
    // Add logic to check custom symbol list
    // This can be expanded based on your needs
    return false;
}

//+------------------------------------------------------------------+
//| Check if symbol is tradeable                                    |
//+------------------------------------------------------------------+
bool IsSymbolTradeable(string symbol)
{
    return ((bool)MarketInfo(symbol, MODE_TRADEALLOWED) && 
            (double)MarketInfo(symbol, MODE_LOTSIZE) > 0 &&
            (double)MarketInfo(symbol, MODE_MINLOT) > 0);
}

//+------------------------------------------------------------------+
//| Calculate signal score for ranking                              |
//+------------------------------------------------------------------+
double CalculateSignalScore(string symbol, int signalStrength, int signalType)
{
    double score = (double)signalStrength * 10.0; // Base score from signal strength
    
    // Add bonus for low spread
    double spread = (double)MarketInfo(symbol, MODE_SPREAD);
    if(spread < 5.0) score += 5.0;
    else if(spread < 10.0) score += 3.0;
    else if(spread < 20.0) score += 1.0;
    
    // Add bonus for good volatility
    double volatility = GetVolatility(symbol);
    if(volatility > 0.8) score += 3.0;
    else if(volatility > 0.5) score += 2.0;
    else if(volatility > 0.3) score += 1.0;
    
    // Add bonus for trend strength
    double trendStrength = GetTrendStrength(symbol, signalType);
    score += trendStrength * 2.0;
    
    return score;
}

//+------------------------------------------------------------------+
//| Get volatility for symbol                                       |
//+------------------------------------------------------------------+
double GetVolatility(string symbol)
{
    double atr = iATR(symbol, 0, 14, 0);
    double avgATR = 0.0;
    
    for(int i = 1; i <= 10; i++)
    {
        avgATR += iATR(symbol, 0, 14, i);
    }
    avgATR /= 10.0;
    
    if(avgATR > 0.00001)
        return atr / avgATR;
    
    return 0.0;
}

//+------------------------------------------------------------------+
//| Get trend strength for symbol                                   |
//+------------------------------------------------------------------+
double GetTrendStrength(string symbol, int signalType)
{
    double fastMA = iMA(symbol, 0, FastMA_Period, 0, MA_Method, MA_Price, 0);
    double slowMA = iMA(symbol, 0, SlowMA_Period, 0, MA_Method, MA_Price, 0);
    
    if(signalType == 1) // Buy
    {
        if(slowMA > 0.00001)
            return (fastMA - slowMA) / slowMA * 100.0;
        else
            return 0.0;
    }
    else // Sell
    {
        if(slowMA > 0.00001)
            return (slowMA - fastMA) / slowMA * 100.0;
        else
            return 0.0;
    }
}

//+------------------------------------------------------------------+
//| Sort opportunities by signal score                              |
//+------------------------------------------------------------------+
void SortOpportunities()
{
    for(int i = 0; i < opportunityCount - 1; i++)
    {
        for(int j = i + 1; j < opportunityCount; j++)
        {
            if(opportunities[i].signalScore < opportunities[j].signalScore)
            {
                TradeOpportunity temp = opportunities[i];
                opportunities[i] = opportunities[j];
                opportunities[j] = temp;
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Execute trade opportunities                                     |
//+------------------------------------------------------------------+
void ExecuteTradeOpportunities()
{
    for(int i = 0; i < opportunityCount; i++)
    {
        if(CountTrades(opportunities[i].symbol) >= MaxTradesPerSymbol)
            continue;
            
        if(CountTotalTrades() >= MaxTotalTrades)
            break;
        
        if(opportunities[i].signalType == 1) // Buy
        {
            ExecuteBuyTrade(opportunities[i].symbol);
        }
        else if(opportunities[i].signalType == -1) // Sell
        {
            ExecuteSellTrade(opportunities[i].symbol);
        }
    }
}

//+------------------------------------------------------------------+
//| Execute buy trade                                               |
//+------------------------------------------------------------------+
void ExecuteBuyTrade(string symbol)
{
    double lotSize = CalculateLotSize(symbol);
    double askPrice = (double)MarketInfo(symbol, MODE_ASK);
    double stopLossPrice = StopLoss > 0 ? askPrice - StopLoss * GetPips2Dbl(symbol) : 0;
    double takeProfitPrice = TakeProfit > 0 ? askPrice + TakeProfit * GetPips2Dbl(symbol) : 0;
    
    int ticket = OrderSend(symbol, OP_BUY, lotSize, askPrice, slip, stopLossPrice, takeProfitPrice, 
                          "SuperProfitEA Scanner Buy", 12345, 0, Green);
    
    if(ticket > 0)
    {
        totalBuyTrades++;
        Print("Buy order opened on ", symbol, " at price: ", askPrice);
    }
    else
    {
        Print("Error opening buy order on ", symbol, ": ", GetLastError());
    }
}

//+------------------------------------------------------------------+
//| Execute sell trade                                              |
//+------------------------------------------------------------------+
void ExecuteSellTrade(string symbol)
{
    double lotSize = CalculateLotSize(symbol);
    double bidPrice = (double)MarketInfo(symbol, MODE_BID);
    double stopLossPrice = StopLoss > 0 ? bidPrice + StopLoss * GetPips2Dbl(symbol) : 0;
    double takeProfitPrice = TakeProfit > 0 ? bidPrice - TakeProfit * GetPips2Dbl(symbol) : 0;
    
    int ticket = OrderSend(symbol, OP_SELL, lotSize, bidPrice, slip, stopLossPrice, takeProfitPrice, 
                          "SuperProfitEA Scanner Sell", 12345, 0, Red);
    
    if(ticket > 0)
    {
        totalSellTrades++;
        Print("Sell order opened on ", symbol, " at price: ", bidPrice);
    }
    else
    {
        Print("Error opening sell order on ", symbol, ": ", GetLastError());
    }
}

//+------------------------------------------------------------------+
//| Get buy signal strength for symbol                              |
//+------------------------------------------------------------------+
int GetBuySignal(string symbol)
{
    int signalStrength = 0;
    
    // Williams %R signal
    double williamsR = iWPR(symbol, 0, WilliamsR_Period, 0);
    if(williamsR <= WilliamsR_BuyLevel && williamsR >= -100)
    {
        signalStrength++;
    }
    
    // Moving Average signal
    double fastMA = iMA(symbol, 0, FastMA_Period, 0, MA_Method, MA_Price, 0);
    double slowMA = iMA(symbol, 0, SlowMA_Period, 0, MA_Method, MA_Price, 0);
    
    if(fastMA > slowMA && iClose(symbol, 0, 1) > slowMA)
    {
        signalStrength++;
    }
    
    // RSI signal
    double rsi = iRSI(symbol, 0, RSI_Period, PRICE_CLOSE, 0);
    if(rsi < RSI_BuyLevel)
    {
        signalStrength++;
    }
    
    // CCI signal
    double cci = iCCI(symbol, 0, CCI_Period, PRICE_TYPICAL, 0);
    if(cci < CCI_BuyLevel)
    {
        signalStrength++;
    }
    
    // Stochastic signal
    double stochK = iStochastic(symbol, 0, Stoch_K_Period, Stoch_D_Period, Stoch_Slowing, MODE_EMA, 0, MODE_MAIN, 0);
    double stochD = iStochastic(symbol, 0, Stoch_K_Period, Stoch_D_Period, Stoch_Slowing, MODE_EMA, 0, MODE_SIGNAL, 0);
    if(stochK < Stoch_BuyLevel && stochK > stochD)
    {
        signalStrength++;
    }
    
    // Bollinger Bands signal
    double bbUpper = iBands(symbol, 0, BB_Period, BB_Deviation, 0, PRICE_CLOSE, MODE_UPPER, 0);
    double bbLower = iBands(symbol, 0, BB_Period, BB_Deviation, 0, PRICE_CLOSE, MODE_LOWER, 0);
    
    // Prevent division by zero
    if(bbUpper > bbLower && (bbUpper - bbLower) > 0.00001)
    {
        double bbPosition = (iClose(symbol, 0, 0) - bbLower) / (bbUpper - bbLower);
        if(bbPosition < BB_BuyLevel)
        {
            signalStrength++;
        }
    }
    
    // MACD signal
    double macd = iMACD(symbol, 0, MACD_Fast, MACD_Slow, MACD_Signal, PRICE_CLOSE, MODE_MAIN, 0);
    double macdSignal = iMACD(symbol, 0, MACD_Fast, MACD_Slow, MACD_Signal, PRICE_CLOSE, MODE_SIGNAL, 0);
    if(macd > macdSignal && macd < 0)
    {
        signalStrength++;
    }
    
    // Multi-timeframe confirmation
    if(UseMultiTimeframe)
    {
        double williamsR_H1 = iWPR(symbol, PERIOD_H1, WilliamsR_Period, 0);
        if(williamsR_H1 <= -80)
        {
            signalStrength++;
        }
    }
    
    return signalStrength;
}

//+------------------------------------------------------------------+
//| Get sell signal strength for symbol                             |
//+------------------------------------------------------------------+
int GetSellSignal(string symbol)
{
    int signalStrength = 0;
    
    // Williams %R signal
    double williamsR = iWPR(symbol, 0, WilliamsR_Period, 0);
    if(williamsR >= WilliamsR_SellLevel && williamsR <= 0)
    {
        signalStrength++;
    }
    
    // Moving Average signal
    double fastMA = iMA(symbol, 0, FastMA_Period, 0, MA_Method, MA_Price, 0);
    double slowMA = iMA(symbol, 0, SlowMA_Period, 0, MA_Method, MA_Price, 0);
    
    if(fastMA < slowMA && iClose(symbol, 0, 1) < slowMA)
    {
        signalStrength++;
    }
    
    // RSI signal
    double rsi = iRSI(symbol, 0, RSI_Period, PRICE_CLOSE, 0);
    if(rsi > RSI_SellLevel)
    {
        signalStrength++;
    }
    
    // CCI signal
    double cci = iCCI(symbol, 0, CCI_Period, PRICE_TYPICAL, 0);
    if(cci > CCI_SellLevel)
    {
        signalStrength++;
    }
    
    // Stochastic signal
    double stochK = iStochastic(symbol, 0, Stoch_K_Period, Stoch_D_Period, Stoch_Slowing, MODE_EMA, 0, MODE_MAIN, 0);
    double stochD = iStochastic(symbol, 0, Stoch_K_Period, Stoch_D_Period, Stoch_Slowing, MODE_EMA, 0, MODE_SIGNAL, 0);
    if(stochK > Stoch_SellLevel && stochK < stochD)
    {
        signalStrength++;
    }
    
    // Bollinger Bands signal
    double bbUpper = iBands(symbol, 0, BB_Period, BB_Deviation, 0, PRICE_CLOSE, MODE_UPPER, 0);
    double bbLower = iBands(symbol, 0, BB_Period, BB_Deviation, 0, PRICE_CLOSE, MODE_LOWER, 0);
    
    // Prevent division by zero
    if(bbUpper > bbLower && (bbUpper - bbLower) > 0.00001)
    {
        double bbPosition = (iClose(symbol, 0, 0) - bbLower) / (bbUpper - bbLower);
        if(bbPosition > BB_SellLevel)
        {
            signalStrength++;
        }
    }
    
    // MACD signal
    double macd = iMACD(symbol, 0, MACD_Fast, MACD_Slow, MACD_Signal, PRICE_CLOSE, MODE_MAIN, 0);
    double macdSignal = iMACD(symbol, 0, MACD_Fast, MACD_Slow, MACD_Signal, PRICE_CLOSE, MODE_SIGNAL, 0);
    if(macd < macdSignal && macd > 0)
    {
        signalStrength++;
    }
    
    // Multi-timeframe confirmation
    if(UseMultiTimeframe)
    {
        double williamsR_H1 = iWPR(symbol, PERIOD_H1, WilliamsR_Period, 0);
        if(williamsR_H1 >= -20)
        {
            signalStrength++;
        }
    }
    
    return signalStrength;
}

//+------------------------------------------------------------------+
//| Check market conditions for symbol                              |
//+------------------------------------------------------------------+
bool CheckMarketConditions(string symbol)
{
    // Check spread
    double currentSpread = (double)MarketInfo(symbol, MODE_SPREAD);
    if(currentSpread < MinSpread || currentSpread > MaxSpread)
    {
        return false;
    }
    
    // Check volatility
    if(UseVolatilityFilter)
    {
        double atr = iATR(symbol, 0, 14, 0);
        double avgATR = 0.0;
        for(int i = 1; i <= 10; i++)
        {
            avgATR += iATR(symbol, 0, 14, i);
        }
        avgATR /= 10.0;
        
        if(atr < avgATR * 0.5) // Too low volatility
        {
            return false;
        }
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Calculate lot size based on risk for symbol                     |
//+------------------------------------------------------------------+
double CalculateLotSize(string symbol)
{
    double lotSize = InitialLots;
    
    if(UseMoneyManagement)
    {
        if(StopLoss > 0) // Traditional risk-based sizing
        {
            double riskAmount = AccountBalance() * (RiskPercent / 100.0);
            double tickValue = (double)MarketInfo(symbol, MODE_TICKVALUE);
            double tickSize = (double)MarketInfo(symbol, MODE_TICKSIZE);
            
            if(tickValue > 0 && tickSize > 0)
            {
                double denominator = StopLoss * tickValue / tickSize;
                if(denominator > 0.00001)
                {
                    lotSize = NormalizeDouble(riskAmount / denominator, lotdecimal);
                }
            }
        }
        else if(UseNoStopLossMode) // No stop loss mode - use equity-based sizing
        {
            // Calculate lot size based on available equity and max risk
            double maxRiskAmount = AccountBalance() * (RiskPercent / 100.0);
            double tickValue = (double)MarketInfo(symbol, MODE_TICKVALUE);
            double tickSize = (double)MarketInfo(symbol, MODE_TICKSIZE);
            
            if(tickValue > 0 && tickSize > 0)
            {
                // Use a conservative approach - assume max 100 pip move against us
                double assumedMaxLoss = 100.0 * tickValue / tickSize;
                if(assumedMaxLoss > 0.00001)
                {
                    lotSize = NormalizeDouble(maxRiskAmount / assumedMaxLoss, lotdecimal);
                }
            }
        }
        
        // Ensure lot size is within allowed range
        double minLot = (double)MarketInfo(symbol, MODE_MINLOT);
        double maxLot = (double)MarketInfo(symbol, MODE_MAXLOT);
        
        lotSize = MathMax(minLot, MathMin(lotSize, maxLot));
        lotSize = MathMin(lotSize, MaxLots);
    }
    
    return NormalizeDouble(lotSize, lotdecimal);
}

//+------------------------------------------------------------------+
//| Get pips to double conversion for symbol                        |
//+------------------------------------------------------------------+
double GetPips2Dbl(string symbol)
{
    int multiplier = 1;
    if((int)MarketInfo(symbol, MODE_DIGITS) == 3 || (int)MarketInfo(symbol, MODE_DIGITS) == 5) multiplier = 10;
    if((int)MarketInfo(symbol, MODE_DIGITS) == 6) multiplier = 100;   
    if((int)MarketInfo(symbol, MODE_DIGITS) == 7) multiplier = 1000;
    return multiplier * (double)MarketInfo(symbol, MODE_POINT);
}

//+------------------------------------------------------------------+
//| Broker digit adjustment for pip calculation                     |
//+------------------------------------------------------------------+
void BrokerDigitAdjust(string symbol)
{
    Multiplier = 1;
    if((int)MarketInfo(symbol, MODE_DIGITS) == 3 || (int)MarketInfo(symbol, MODE_DIGITS) == 5) Multiplier = 10;
    if((int)MarketInfo(symbol, MODE_DIGITS) == 6) Multiplier = 100;   
    if((int)MarketInfo(symbol, MODE_DIGITS) == 7) Multiplier = 1000;
    pips2dbl = Multiplier * (double)MarketInfo(symbol, MODE_POINT); 
}

//+------------------------------------------------------------------+
//| Count trades for specific symbol                                |
//+------------------------------------------------------------------+
int CountTrades(string symbol)
{
    int count = 0;
    
    for(int i = 0; i < OrdersTotal(); i++)
    {
        if(OrderSelect(i, SELECT_BY_POS) && OrderSymbol() == symbol && OrderMagicNumber() == 12345)
        {
            count++;
        }
    }
    
    return count;
}

//+------------------------------------------------------------------+
//| Count total trades across all symbols                           |
//+------------------------------------------------------------------+
int CountTotalTrades()
{
    int count = 0;
    
    for(int i = 0; i < OrdersTotal(); i++)
    {
        if(OrderSelect(i, SELECT_BY_POS) && OrderMagicNumber() == 12345)
        {
            count++;
        }
    }
    
    return count;
}

//+------------------------------------------------------------------+
//| Check for close signals on all symbols                          |
//+------------------------------------------------------------------+
void CheckCloseSignalsAllSymbols()
{
    for(int i = 0; i < OrdersTotal(); i++)
    {
        if(OrderSelect(i, SELECT_BY_POS) && OrderMagicNumber() == 12345)
        {
            string symbol = OrderSymbol();
            double williamsR = iWPR(symbol, 0, WilliamsR_Period, 0);
            double rsi = iRSI(symbol, 0, RSI_Period, PRICE_CLOSE, 0);
            
            // Close buy positions
            if(OrderType() == OP_BUY)
            {
                if(williamsR >= WilliamsR_CloseBuyLevel && williamsR <= 0)
                {
                    double bidPrice = (double)MarketInfo(symbol, MODE_BID);
                    bool result = OrderClose(OrderTicket(), OrderLots(), bidPrice, slip, Green);
                    if(result) totalBuyTrades--;
                    else Print("Error closing buy order: ", GetLastError());
                }
                else if(rsi > 80)
                {
                    double bidPrice = (double)MarketInfo(symbol, MODE_BID);
                    bool result = OrderClose(OrderTicket(), OrderLots(), bidPrice, slip, Green);
                    if(result) totalBuyTrades--;
                    else Print("Error closing buy order: ", GetLastError());
                }
            }
            // Close sell positions
            else if(OrderType() == OP_SELL)
            {
                if(williamsR <= WilliamsR_CloseSellLevel && williamsR >= -100)
                {
                    double askPrice = (double)MarketInfo(symbol, MODE_ASK);
                    bool result = OrderClose(OrderTicket(), OrderLots(), askPrice, slip, Red);
                    if(result) totalSellTrades--;
                    else Print("Error closing sell order: ", GetLastError());
                }
                else if(rsi < 20)
                {
                    double askPrice = (double)MarketInfo(symbol, MODE_ASK);
                    bool result = OrderClose(OrderTicket(), OrderLots(), askPrice, slip, Red);
                    if(result) totalSellTrades--;
                    else Print("Error closing sell order: ", GetLastError());
                }
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Apply trailing stop and no-stop-loss strategy to all symbols    |
//+------------------------------------------------------------------+
void ApplyTrailingStopAllSymbols()
{
    for(int i = 0; i < OrdersTotal(); i++)
    {
        if(OrderSelect(i, SELECT_BY_POS) && OrderMagicNumber() == 12345)
        {
            string symbol = OrderSymbol();
            
            if(OrderType() == OP_BUY)
            {
                double bidPrice = (double)MarketInfo(symbol, MODE_BID);
                double profitPips = (bidPrice - OrderOpenPrice()) / GetPips2Dbl(symbol);
                
                // Traditional trailing stop
                if(UseTrailingStop && TrailStart > 0 && TrailStop > 0)
                {
                    if(profitPips > TrailStart)
                    {
                        if(OrderStopLoss() < bidPrice - TrailStop * GetPips2Dbl(symbol))
                        {
                            bool result = OrderModify(OrderTicket(), OrderOpenPrice(), 
                                       bidPrice - TrailStop * GetPips2Dbl(symbol), 
                                       OrderTakeProfit(), 0, Green);
                            if(!result) Print("Error modifying buy order: ", GetLastError());
                        }
                    }
                }
                
                // No Stop Loss Strategy: Break-even mode
                if(StopLoss == 0 && UseBreakEvenMode && OrderStopLoss() == 0)
                {
                    if(profitPips >= BreakEvenTrigger)
                    {
                        bool result = OrderModify(OrderTicket(), OrderOpenPrice(), 
                                   OrderOpenPrice(), // Move stop loss to break-even
                                   OrderTakeProfit(), 0, Green);
                        if(!result) Print("Error moving to break-even: ", GetLastError());
                    }
                }
                
                // No Stop Loss Strategy: Trailing profit
                if(StopLoss == 0 && UseTrailingProfit && profitPips >= TrailingProfitStart)
                {
                    double newStopLoss = bidPrice - (TrailingProfitStart * 0.5) * GetPips2Dbl(symbol);
                    if(OrderStopLoss() < newStopLoss)
                    {
                        bool result = OrderModify(OrderTicket(), OrderOpenPrice(), 
                                   newStopLoss, OrderTakeProfit(), 0, Green);
                        if(!result) Print("Error applying trailing profit: ", GetLastError());
                    }
                }
            }
            else if(OrderType() == OP_SELL)
            {
                double askPrice = (double)MarketInfo(symbol, MODE_ASK);
                double profitPips = (OrderOpenPrice() - askPrice) / GetPips2Dbl(symbol);
                
                // Traditional trailing stop
                if(UseTrailingStop && TrailStart > 0 && TrailStop > 0)
                {
                    if(profitPips > TrailStart)
                    {
                        if(OrderStopLoss() > askPrice + TrailStop * GetPips2Dbl(symbol) || OrderStopLoss() == 0)
                        {
                            bool result = OrderModify(OrderTicket(), OrderOpenPrice(), 
                                       askPrice + TrailStop * GetPips2Dbl(symbol), 
                                       OrderTakeProfit(), 0, Red);
                            if(!result) Print("Error modifying sell order: ", GetLastError());
                        }
                    }
                }
                
                // No Stop Loss Strategy: Break-even mode
                if(StopLoss == 0 && UseBreakEvenMode && OrderStopLoss() == 0)
                {
                    if(profitPips >= BreakEvenTrigger)
                    {
                        bool result = OrderModify(OrderTicket(), OrderOpenPrice(), 
                                   OrderOpenPrice(), // Move stop loss to break-even
                                   OrderTakeProfit(), 0, Red);
                        if(!result) Print("Error moving to break-even: ", GetLastError());
                    }
                }
                
                // No Stop Loss Strategy: Trailing profit
                if(StopLoss == 0 && UseTrailingProfit && profitPips >= TrailingProfitStart)
                {
                    double newStopLoss = askPrice + (TrailingProfitStart * 0.5) * GetPips2Dbl(symbol);
                    if(OrderStopLoss() > newStopLoss || OrderStopLoss() == 0)
                    {
                        bool result = OrderModify(OrderTicket(), OrderOpenPrice(), 
                                   newStopLoss, OrderTakeProfit(), 0, Red);
                        if(!result) Print("Error applying trailing profit: ", GetLastError());
                    }
                }
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Check if profit target is reached                               |
//+------------------------------------------------------------------+
void CheckProfitTarget()
{
    if(ProfitTargetInPips)
    {
        if(CalculateTotalProfitPips() >= ProfitTarget)
        {
            CloseAllTrades();
        }
    }
    else
    {
        if(CalculateTotalProfit() >= ProfitTarget)
        {
            CloseAllTrades();
        }
    }
    
    // Check equity stop
    if(UseEquityStop)
    {
        double currentEquity = AccountEquity();
        double maxEquity = AccountBalance() + CalculateTotalProfit();
        
        if(maxEquity - currentEquity > (TotalEquityRisk / 100.0) * AccountBalance())
        {
            CloseAllTrades();
        }
    }
}

//+------------------------------------------------------------------+
//| Calculate total profit across all symbols                       |
//+------------------------------------------------------------------+
double CalculateTotalProfit()
{
    double profit = 0;
    
    for(int i = 0; i < OrdersTotal(); i++)
    {
        if(OrderSelect(i, SELECT_BY_POS) && OrderMagicNumber() == 12345)
        {
            profit += OrderProfit() + OrderSwap() + OrderCommission();
        }
    }
    
    return profit;
}

//+------------------------------------------------------------------+
//| Calculate total profit in pips across all symbols               |
//+------------------------------------------------------------------+
double CalculateTotalProfitPips()
{
    double profitPips = 0;
    
    for(int i = 0; i < OrdersTotal(); i++)
    {
        if(OrderSelect(i, SELECT_BY_POS) && OrderMagicNumber() == 12345)
        {
            if(OrderType() == OP_BUY)
            {
                double bidPrice = (double)MarketInfo(OrderSymbol(), MODE_BID);
                profitPips += (bidPrice - OrderOpenPrice()) / GetPips2Dbl(OrderSymbol());
            }
            else if(OrderType() == OP_SELL)
            {
                double askPrice = (double)MarketInfo(OrderSymbol(), MODE_ASK);
                profitPips += (OrderOpenPrice() - askPrice) / GetPips2Dbl(OrderSymbol());
            }
        }
    }
    
    return profitPips;
}

//+------------------------------------------------------------------+
//| Close all trades across all symbols                             |
//+------------------------------------------------------------------+
void CloseAllTrades()
{
    for(int i = OrdersTotal() - 1; i >= 0; i--)
    {
                    if(OrderSelect(i, SELECT_BY_POS) && OrderMagicNumber() == 12345)
            {
                string symbol = OrderSymbol();
                bool result = false;
                
                if(OrderType() == OP_BUY)
                {
                    result = OrderClose(OrderTicket(), OrderLots(), (double)MarketInfo(symbol, MODE_BID), slip, Green);
                }
                else if(OrderType() == OP_SELL)
                {
                    result = OrderClose(OrderTicket(), OrderLots(), (double)MarketInfo(symbol, MODE_ASK), slip, Red);
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
//| Close all profitable trades across all symbols                  |
//+------------------------------------------------------------------+
void CloseAllProfitableTrades()
{
    for(int i = OrdersTotal() - 1; i >= 0; i--)
    {
        if(OrderSelect(i, SELECT_BY_POS) && OrderMagicNumber() == 12345)
        {
            if(OrderProfit() + OrderSwap() + OrderCommission() > ProfitableTradeAmount)
            {
                string symbol = OrderSymbol();
                bool result = false;
                
                if(OrderType() == OP_BUY)
                {
                    result = OrderClose(OrderTicket(), OrderLots(), (double)MarketInfo(symbol, MODE_BID), slip, Green);
                    if(result) totalBuyTrades--;
                }
                else if(OrderType() == OP_SELL)
                {
                    result = OrderClose(OrderTicket(), OrderLots(), (double)MarketInfo(symbol, MODE_ASK), slip, Red);
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
//| Update dashboard with scanning information                       |
//+------------------------------------------------------------------+
void UpdateDashboard()
{
    string comment = "";
    
    comment += "SuperProfitEA Multi-Symbol Scanner v3.0\n";
    comment += "----------------------------------------------------\n";
    comment += "Scanner Status: " + (EnableScanner ? "ACTIVE" : "INACTIVE") + "\n";
    comment += "Scan Interval: " + IntegerToString(ScanInterval) + " seconds\n";
    comment += "Last Scan: " + TimeToString(lastScanTime) + "\n";
    comment += "Opportunities Found: " + IntegerToString(opportunityCount) + "/" + IntegerToString(MaxSymbolsToTrade) + "\n";
    comment += "----------------------------------------------------\n";
    comment += "Total Buy Trades: " + IntegerToString(totalBuyTrades) + "\n";
    comment += "Total Sell Trades: " + IntegerToString(totalSellTrades) + "\n";
    comment += "Total Open Trades: " + IntegerToString(CountTotalTrades()) + "\n";
    comment += "Total Profit: " + DoubleToStr(CalculateTotalProfit(), 2) + " " + AccountCurrency() + "\n";
    comment += "Total Profit (Pips): " + DoubleToStr(CalculateTotalProfitPips(), 1) + "\n";
    comment += "----------------------------------------------------\n";
    comment += "Stop Loss Strategy: " + (StopLoss > 0 ? "Fixed SL (" + DoubleToStr(StopLoss, 1) + " pips)" : "NO STOP LOSS (Let trades breathe)") + "\n";
    if(StopLoss == 0)
    {
        comment += "Break-Even Mode: " + (UseBreakEvenMode ? "ON (at " + DoubleToStr(BreakEvenTrigger, 1) + " pips)" : "OFF") + "\n";
        comment += "Trailing Profit: " + (UseTrailingProfit ? "ON (start at " + DoubleToStr(TrailingProfitStart, 1) + " pips)" : "OFF") + "\n";
    }
    comment += "----------------------------------------------------\n";
    comment += "Balance: " + DoubleToStr(AccountBalance(), 2) + " " + AccountCurrency() + "\n";
    comment += "Equity: " + DoubleToStr(AccountEquity(), 2) + " " + AccountCurrency() + "\n";
    comment += "Margin: " + DoubleToStr(AccountMargin(), 2) + " " + AccountCurrency() + "\n";
    comment += "Free Margin: " + DoubleToStr(AccountFreeMargin(), 2) + " " + AccountCurrency() + "\n";
    
    double marginLevel = 0.0;
    if (AccountMargin() > 0.0)
        marginLevel = AccountEquity() / AccountMargin() * 100.0;
    else
        marginLevel = 0.0;
    comment += "Margin Level: " + DoubleToStr(marginLevel, 2) + "%\n";
    
    // Show top opportunities
    if(opportunityCount > 0)
    {
        comment += "----------------------------------------------------\n";
        comment += "TOP OPPORTUNITIES:\n";
        for(int i = 0; i < MathMin(5, opportunityCount); i++)
        {
            string signalType = (opportunities[i].signalType == 1) ? "BUY" : "SELL";
            comment += IntegerToString(i+1) + ". " + opportunities[i].symbol + " " + signalType + " (Score: " + DoubleToStr(opportunities[i].signalScore, 1) + ")\n";
        }
    }
    
    Comment(comment);
}
