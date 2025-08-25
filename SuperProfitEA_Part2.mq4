
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
        // Get trading signals
        int buySignal = GetBuySignal();
        int sellSignal = GetSellSignal();
        
        // Check for close signals
        CheckCloseSignals();
        
        // Execute trades based on signals
        if(buySignal > 0 && CountTrades(OP_BUY) < MaxTrades)
        {
            double lotSize = CalculateLotSize();
            double stopLossPrice = StopLoss > 0 ? Ask - StopLoss * pips2dbl : 0;
            double takeProfitPrice = TakeProfit > 0 ? Ask + TakeProfit * pips2dbl : 0;
            
            int ticket = OrderSend(Symbol(), OP_BUY, lotSize, Ask, slip, stopLossPrice, takeProfitPrice, 
                                  "SuperProfitEA Buy", 12345, 0, Green);
            
            if(ticket > 0)
            {
                lastBuyPrice = Ask;
                lastTradeTime = TimeCurrent();
                totalBuyTrades++;
                Print("Buy order opened at price: ", Ask);
            }
            else
            {
                Print("Error opening buy order: ", GetLastError());
            }
        }
        
        if(sellSignal > 0 && CountTrades(OP_SELL) < MaxTrades)
        {
            double lotSize = CalculateLotSize();
            double stopLossPrice = StopLoss > 0 ? Bid + StopLoss * pips2dbl : 0;
            double takeProfitPrice = TakeProfit > 0 ? Bid - TakeProfit * pips2dbl : 0;
            
            int ticket = OrderSend(Symbol(), OP_SELL, lotSize, Bid, slip, stopLossPrice, takeProfitPrice, 
                                  "SuperProfitEA Sell", 12345, 0, Red);
            
            if(ticket > 0)
            {
                lastSellPrice = Bid;
                lastTradeTime = TimeCurrent();
                totalSellTrades++;
                Print("Sell order opened at price: ", Bid);
            }
            else
            {
                Print("Error opening sell order: ", GetLastError());
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Get buy signal strength (0-3)                                    |
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
    
    // Check for trend confirmation
    if(iClose(NULL, 0, 1) > iOpen(NULL, 0, 1) && 
       iClose(NULL, 0, 2) > iOpen(NULL, 0, 2))
    {
        signalStrength++;
    }
    
    return signalStrength;
}

//+------------------------------------------------------------------+
//| Get sell signal strength (0-3)                                   |
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
    
    // Check for trend confirmation
    if(iClose(NULL, 0, 1) < iOpen(NULL, 0, 1) && 
       iClose(NULL, 0, 2) < iOpen(NULL, 0, 2))
    {
        signalStrength++;
    }
    
    return signalStrength;
}
