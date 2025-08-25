

// Input parameters - General Settings
extern string EA_Name = "SuperProfitEA";
extern string EA_Version = "1.0";
extern string TimeFrames = "Works best on H1, M30, M15";

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

// Profit Target Settings
extern bool UseEquityStop = true;
extern double TotalEquityRisk = 20.0;
extern bool ProfitTargetInPips = false;
extern double ProfitTarget = 25.0;
extern bool CloseAllNow = false;
extern bool CloseProfitableTradesOnly = false;
extern double ProfitableTradeAmount = 1.0;

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
    Comment("SuperProfitEA v1.0 - Combined Strategy System\n",
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
