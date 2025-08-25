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
    
    comment += "SuperProfitEA v1.0 - Combined Strategy System\n";
    comment += "--------------------------------------------\n";
    comment += "Symbol: " + Symbol() + ", Timeframe: " + TimeframeToString(Period()) + "\n";
    comment += "Spread: " + DoubleToStr(MarketInfo(Symbol(), MODE_SPREAD), 1) + " points\n";
    comment += "--------------------------------------------\n";
    comment += "Williams %R: " + DoubleToStr(iWPR(NULL, 0, WilliamsR_Period, 0), 2) + "\n";
    comment += "RSI: " + DoubleToStr(iRSI(NULL, 0, RSI_Period, PRICE_CLOSE, 0), 2) + "\n";
    comment += "Fast MA: " + DoubleToStr(iMA(NULL, 0, FastMA_Period, 0, MA_Method, MA_Price, 0), Digits) + "\n";
    comment += "Slow MA: " + DoubleToStr(iMA(NULL, 0, SlowMA_Period, 0, MA_Method, MA_Price, 0), Digits) + "\n";
    comment += "--------------------------------------------\n";
    comment += "Buy Trades: " + IntegerToString(CountTrades(OP_BUY)) + "\n";
    comment += "Sell Trades: " + IntegerToString(CountTrades(OP_SELL)) + "\n";
    comment += "Total Profit: " + DoubleToStr(CalculateProfit(), 2) + " " + AccountCurrency() + "\n";
    comment += "Total Profit (Pips): " + DoubleToStr(CalculateProfitPips(), 1) + "\n";
    comment += "--------------------------------------------\n";
    comment += "Balance: " + DoubleToStr(AccountBalance(), 2) + " " + AccountCurrency() + "\n";
    comment += "Equity: " + DoubleToStr(AccountEquity(), 2) + " " + AccountCurrency() + "\n";
    comment += "Margin: " + DoubleToStr(AccountMargin(), 2) + " " + AccountCurrency() + "\n";
    comment += "Free Margin: " + DoubleToStr(AccountFreeMargin(), 2) + " " + AccountCurrency() + "\n";
    comment += "Margin Level: " + DoubleToStr(AccountEquity() / AccountMargin() * 100, 2) + "%\n";
    
    Comment(comment);
}
