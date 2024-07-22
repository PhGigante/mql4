
//+------------------------------------------------------------------+
//|                                             Didi Index EA.mq4    |
//|                   Copyright 2023, WebSim Creation Engine         |
//|                                   https://websim.cengine.ai      |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, WebSim Creation Engine"
#property link      "https://websim.cengine.ai"
#property version   "1.00"
#property strict

// Input parameters
extern int ShortMAPeriod = 9;
extern int MediumMAPeriod = 21;
extern int LongMAPeriod = 55;
extern int RSIPeriod = 14;
extern int StochPeriod = 14;
extern int StochKPeriod = 3;
extern int StochDPeriod = 3;
extern double TrailingStop = 50; // In points
extern double LotSize = 0.1;

// Global variables
int ticket = 0;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
    // Check if we have an open position
    if(ticket > 0)
    {
        // If yes, manage the position (apply trailing stop)
        ManagePosition();
    }
    else
    {
        // If not, check for new entry signals
        CheckForEntry();
    }
}

//+------------------------------------------------------------------+
//| Check for entry signals                                          |
//+------------------------------------------------------------------+
void CheckForEntry()
{
    double shortMA = iMA(NULL, 0, ShortMAPeriod, 0, MODE_EMA, PRICE_CLOSE, 0);
    double mediumMA = iMA(NULL, 0, MediumMAPeriod, 0, MODE_EMA, PRICE_CLOSE, 0);
    double longMA = iMA(NULL, 0, LongMAPeriod, 0, MODE_EMA, PRICE_CLOSE, 0);
    
    double rsi = iRSI(NULL, 0, RSIPeriod, PRICE_CLOSE, 0);
    double stochK, stochD;
    stochK = iStochastic(NULL, 0, StochPeriod, StochKPeriod, StochDPeriod, MODE_SMA, 0, MODE_MAIN, 0);
    stochD = iStochastic(NULL, 0, StochPeriod, StochKPeriod, StochDPeriod, MODE_SMA, 0, MODE_SIGNAL, 0);
    
    // Check for buy signal
    if(shortMA > mediumMA && shortMA > longMA && rsi > 30 && rsi < 70 && stochK > stochD && stochK < 30)
    {
        ticket = OrderSend(Symbol(), OP_BUY, LotSize, Ask, 3, 0, 0, "Didi Index EA Buy", 0, 0, Green);
    }
    
    // Check for sell signal
    if(shortMA < mediumMA && shortMA < longMA && rsi > 30 && rsi < 70 && stochK < stochD && stochK > 70)
    {
        ticket = OrderSend(Symbol(), OP_SELL, LotSize, Bid, 3, 0, 0, "Didi Index EA Sell", 0, 0, Red);
    }
}

//+------------------------------------------------------------------+
//| Manage open position                                             |
//+------------------------------------------------------------------+
void ManagePosition()
{
    if(OrderSelect(ticket, SELECT_BY_TICKET))
    {
        if(OrderType() == OP_BUY)
        {
            double newStopLoss = Bid - TrailingStop * Point;
            if(newStopLoss > OrderStopLoss())
            {
                OrderModify(ticket, OrderOpenPrice(), newStopLoss, OrderTakeProfit(), 0, Green);
            }
        }
        else if(OrderType() == OP_SELL)
        {
            double newStopLoss = Ask + TrailingStop * Point;
            if(newStopLoss < OrderStopLoss() || OrderStopLoss() == 0)
            {
                OrderModify(ticket, OrderOpenPrice(), newStopLoss, OrderTakeProfit(), 0, Red);
            }
        }
        
        // Check if the order has been closed
        if(OrderCloseTime() > 0)
        {
            ticket = 0;
        }
    }
    else
    {
        // If we can't select the order, assume it's closed
        ticket = 0;
    }
}