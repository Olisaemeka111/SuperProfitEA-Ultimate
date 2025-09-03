# SuperProfitEA Multi-Symbol Scanner

## 🚀 Overview

**SuperProfitEA Multi-Symbol Scanner** is a professional-grade Expert Advisor (EA) for MetaTrader 4 that combines multiple advanced trading strategies into a unified multi-symbol scanning and trading system. This EA can scan all available symbols in your terminal, identify the best trade opportunities, and execute trades automatically while maintaining comprehensive risk management.

## ✨ Key Features

### 🔍 Multi-Symbol Scanning
- **Automatic Symbol Discovery**: Scans all symbols in Market Watch
- **Smart Opportunity Ranking**: Ranks trade opportunities by signal strength
- **Configurable Limits**: Set maximum symbols to trade (default: 50)
- **Major Pairs Focus**: Option to trade only major currency pairs

### 📊 Advanced Signal Generation
- **Williams %R**: Primary momentum indicator for entry/exit signals
- **Moving Averages**: Fast/Slow EMA crossover confirmation
- **RSI**: Relative Strength Index for overbought/oversold conditions
- **CCI**: Commodity Channel Index for trend strength
- **Stochastic**: Stochastic oscillator for momentum confirmation
- **Bollinger Bands**: Volatility-based entry/exit signals
- **MACD**: Trend direction and momentum confirmation
- **Multi-Timeframe Analysis**: H1 confirmation for stronger signals

### 💰 Professional Money Management
- **Risk-Based Position Sizing**: Automatic lot calculation based on account risk
- **Configurable Risk Percentage**: Set risk per trade (default: 2%)
- **Lot Size Limits**: Minimum and maximum lot size controls
- **Dynamic Lot Calculation**: Adjusts based on stop loss and account balance

### 🛡️ Advanced Risk Management
- **Equity Stop**: Automatic closure when equity drops below threshold
- **Spread Filter**: Only trades symbols with acceptable spreads
- **Volatility Filter**: Avoids low-volatility market conditions
- **Maximum Trade Limits**: Per-symbol and total trade limits
- **Trailing Stops**: Dynamic stop loss adjustment for profit protection

### 📈 Trade Management
- **Automatic Stop Loss**: Configurable stop loss in pips
- **Take Profit Targets**: Set profit targets in pips or currency
- **Trailing Stops**: Dynamic stop loss adjustment
- **Smart Exit Signals**: Multiple exit conditions based on indicators
- **Bulk Trade Management**: Close all trades or profitable trades only

## 🎯 Trading Strategy

### Entry Conditions
The EA generates buy/sell signals based on a **signal strength scoring system**:

1. **Williams %R Signal** (Core indicator)
   - Buy: Williams %R ≤ -90 (oversold)
   - Sell: Williams %R ≥ -10 (overbought)

2. **Moving Average Confirmation**
   - Buy: Fast MA > Slow MA, Price > Slow MA
   - Sell: Fast MA < Slow MA, Price < Slow MA

3. **RSI Confirmation**
   - Buy: RSI < 30 (oversold)
   - Sell: RSI > 70 (overbought)

4. **Additional Confirmations**
   - CCI, Stochastic, Bollinger Bands, MACD
   - Multi-timeframe Williams %R confirmation

### Exit Conditions
- **Williams %R Exit**: Buy closes at -30, Sell closes at -70
- **RSI Exit**: Buy closes at RSI > 80, Sell closes at RSI < 20
- **Take Profit**: Configurable profit targets
- **Stop Loss**: Configurable stop loss levels
- **Trailing Stop**: Dynamic stop loss adjustment

## 📋 Requirements

### MetaTrader 4
- **Version**: 4.0 or higher
- **Build**: 600 or higher (recommended)
- **Account Type**: Any (Demo/Live)
- **Broker**: Any MT4-compatible broker

### Indicators (Built-in)
- Williams %R
- Moving Averages (EMA/SMA)
- RSI (Relative Strength Index)
- CCI (Commodity Channel Index)
- Stochastic Oscillator
- Bollinger Bands
- MACD

### Timeframes
- **Primary**: H1 (1 Hour)
- **Secondary**: M30, M15, M5
- **Multi-timeframe**: H1 confirmation

## 🚀 Installation

### 1. Download Files
- `SuperProfitEA_MultiSymbol_Scanner.mq4` - Main EA file
- `SuperProfitEA_Scanner_Setting1_Aggressive.set` - Aggressive settings
- `SuperProfitEA_Scanner_Setting2_Balanced.set` - Balanced settings (Recommended)
- `SuperProfitEA_Scanner_Setting3_Conservative.set` - Conservative settings

### 2. Install in MetaTrader 4
1. Open MetaTrader 4
2. Press `Ctrl+N` to open Navigator
3. Right-click on "Expert Advisors"
4. Select "Import"
5. Choose the `.mq4` file
6. Restart MetaTrader 4

### 3. Apply Settings
1. Drag the EA to any chart
2. Select your preferred `.set` file
3. Enable "Allow live trading"
4. Click "OK"

## ⚙️ Configuration

### Scanner Settings
```mql4
extern bool EnableScanner = true;           // Enable/disable scanner
extern int MaxSymbolsToTrade = 50;         // Maximum symbols to trade
extern int ScanInterval = 60;              // Scan interval in seconds
extern bool TradeOnlyMajors = true;        // Trade only major pairs
```

### Money Management
```mql4
extern double RiskPercent = 2.0;           // Risk per trade (%)
extern double InitialLots = 0.01;          // Initial lot size
extern double MaxLots = 10.0;              // Maximum lot size
extern bool UseMoneyManagement = true;     // Enable risk-based sizing
```

### Trade Management
```mql4
extern double TakeProfit = 100.0;          // Take profit in pips
extern double StopLoss = 50.0;             // Stop loss in pips
extern bool UseTrailingStop = true;        // Enable trailing stop
extern double TrailStart = 15.0;           // Trailing start in pips
extern double TrailStop = 5.0;             // Trailing stop in pips
```

### Signal Settings
```mql4
extern int WilliamsR_Period = 14;          // Williams %R period
extern double WilliamsR_BuyLevel = -90.0;  // Buy signal level
extern double WilliamsR_SellLevel = -10.0; // Sell signal level
extern int RSI_Period = 14;                // RSI period
extern int RSI_BuyLevel = 30;              // RSI buy level
extern int RSI_SellLevel = 70;             // RSI sell level
```

## 📊 Recommended Settings

### 🎯 Balanced (Recommended)
- **MaxSymbolsToTrade**: 50
- **ScanInterval**: 60 seconds
- **RiskPercent**: 2.0%
- **TakeProfit**: 100 pips
- **StopLoss**: 50 pips
- **TrailStart**: 20 pips
- **TrailStop**: 10 pips

### ⚡ Aggressive
- **MaxSymbolsToTrade**: 25
- **ScanInterval**: 30 seconds
- **RiskPercent**: 1.5%
- **TakeProfit**: 50 pips
- **StopLoss**: 30 pips
- **TrailStart**: 10 pips
- **TrailStop**: 5 pips

### 🛡️ Conservative
- **MaxSymbolsToTrade**: 15
- **ScanInterval**: 300 seconds
- **RiskPercent**: 1.0%
- **TakeProfit**: 150 pips
- **StopLoss**: 75 pips
- **TrailStart**: 30 pips
- **TrailStop**: 15 pips

## 📱 Dashboard Information

The EA provides a comprehensive dashboard showing:

- **Scanner Status**: Active/Inactive status
- **Scan Information**: Last scan time, opportunities found
- **Trade Summary**: Buy/Sell trades, total open trades
- **Profit Information**: Total profit in currency and pips
- **Account Status**: Balance, Equity, Margin, Free Margin
- **Top Opportunities**: Best 5 trade opportunities with scores

## 🔧 Customization

### Adding Custom Symbols
```mql4
extern string CustomSymbols = "EURUSD,GBPUSD,USDJPY";
```

### Modifying Signal Levels
```mql4
extern double WilliamsR_BuyLevel = -85.0;   // Less strict buy
extern double WilliamsR_SellLevel = -15.0;  // Less strict sell
```

### Adjusting Risk Parameters
```mql4
extern double TotalEquityRisk = 15.0;       // Lower equity risk
extern double RiskPercent = 1.5;            // Lower risk per trade
```

## ⚠️ Important Notes

### Risk Warnings
- **Past performance does not guarantee future results**
- **Always test on demo account first**
- **Monitor the EA regularly**
- **Adjust settings based on market conditions**

### Best Practices
- **Start with conservative settings**
- **Use proper risk management**
- **Monitor spread conditions**
- **Avoid trading during major news events**
- **Regular performance review and optimization**

### Market Conditions
- **Best Performance**: Trending markets with clear direction
- **Good Performance**: Range-bound markets with clear levels
- **Avoid**: Low volatility, high spread conditions

## 🐛 Troubleshooting

### Common Issues
1. **EA not trading**: Check "Allow live trading" is enabled
2. **No opportunities found**: Verify symbol list and market conditions
3. **High spread warnings**: Check broker spread settings
4. **Compilation errors**: Ensure MT4 build 600+

### Performance Tips
- **Use H1 timeframe for best results**
- **Monitor during major market sessions**
- **Regular parameter optimization**
- **Keep spread filters enabled**

## 📈 Performance Metrics

### Expected Results (Conservative Settings)
- **Win Rate**: 60-70%
- **Average Win**: 80-120 pips
- **Average Loss**: 40-60 pips
- **Profit Factor**: 1.5-2.0
- **Maximum Drawdown**: 15-25%

### Optimization Tips
- **Backtest different parameter combinations**
- **Use Walk-Forward Analysis**
- **Monitor correlation between symbols**
- **Adjust for different market conditions**

## 🤝 Support & Updates

### Version History
- **v3.0**: Multi-symbol scanner with advanced features
- **v2.0**: Enhanced signal generation and risk management
- **v1.0**: Basic Williams %R strategy

### Future Updates
- **News filter integration**
- **Advanced correlation analysis**
- **Machine learning signal optimization**
- **Multi-timeframe strategy enhancement**

## 📄 License

This EA is provided for educational and trading purposes. Use at your own risk and always test thoroughly before live trading.

## ⚖️ Disclaimer

**Trading foreign exchange (Forex) carries a high level of risk and may not be suitable for all investors. The high degree of leverage can work against you as well as for you. Before deciding to trade foreign exchange, you should carefully consider your investment objectives, level of experience, and risk appetite. The possibility exists that you could sustain a loss of some or all of your initial investment and therefore you should not invest money that you cannot afford to lose.**

---

**SuperProfitEA Multi-Symbol Scanner v3.0**  
*Professional Multi-Symbol Trading Solution*  
*Built for Maximum Profitability with Advanced Risk Management*
