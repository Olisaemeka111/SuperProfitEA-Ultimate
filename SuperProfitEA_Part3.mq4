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
                profitPips += (OrderClosePrice() - OrderOpenPrice()) / pips2dbl;
            }
            else if(OrderType() == OP_SELL)
            {
                profitPips += (OrderOpenPrice() - OrderClosePrice()) / pips2dbl;
            }
        }
    }
    
    return profitPips;
}
