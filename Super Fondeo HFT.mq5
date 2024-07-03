//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2018, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+
#property copyright "Tony Programa"
#property link      "https://www.instagram.com/tony_programa/"
#property version   "1.00"
#property description "\nExpert Advisor made by @Tony_Programa"
#property description "Asesor Experto realizado por @Tony_Programa"
#property strict

ulong Ticket_Compra = 0;
ulong Ticket_Venta = 0;

int Number_Buy=0;
int Number_Sell=0;
bool Funcion = false;
int Error;
datetime TimeClose = 0;

enum Operation
  {
   Only_Buy=0,
   Only_Sell=1
  };


input double Lotaje = 1; //Lotaje
input int Distancia_Stop_Loss = 0; //Stop Loss en Points
input int Point_Anclaje = 1; //Punto de anclaje en Puntos
input double Porcentaje_Win = 54050; //Meta a alcanzar
input int Magic = 123;
input int Tiempo = 1;
input Operation Operation_Type_Operation = 0;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {

   datetime Expiry=D'2025.04.20 00:00';
   if(TimeCurrent()>Expiry)
     {
      Alert("El Bot ha expirado");
      return(INIT_FAILED);
     }


   /*
      const long allowed_accounts[] = {20170371, 20169539};
      int password_status = -1;
      long account = AccountInfoInteger(ACCOUNT_LOGIN);

      for(int i=0; i<ArraySize(allowed_accounts); i++)
        {
         if(account == allowed_accounts[i])
           {
            password_status = 1;
            break;
           }
        }

      if(password_status == -1)
        {
         Alert("La licencia no puede verificarse, no puede operar por ID incorrecto");
         Alert("https://www.mafapower.com/");
         return(INIT_FAILED);
        }
   */

   TimeClose=TimeCurrent();

   if(AccountInfoDouble(ACCOUNT_BALANCE)>Porcentaje_Win)
      Alert("Ya se ha fondeado la cuenta numero: " + IntegerToString(AccountInfoInteger(ACCOUNT_LOGIN)));
//---
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {

   if(PositionsTotal()>0 && Ticket_Compra>0) //Trilling Stop Compra
      Trilling_Stop_Buy();

   if(PositionsTotal()>0 && Ticket_Venta>0) //Trilling Stop Venta
      Trilling_Stop_Sell();

   if(OrdersTotal() == 0 && PositionsTotal() == 0)
     {
      Ticket_Venta=0;
      Ticket_Compra=0;
     }
   else
      Close_Order();

   if(AccountInfoDouble(ACCOUNT_BALANCE)<Porcentaje_Win && TimeCurrent() > TimeClose)
     {

      if(OrdersTotal()>0 && Sell_Previous()==0 && Buy_Previous()==0)
         for(int i=0; i<OrdersTotal(); i++)
            Remove_Order(OrderGetTicket(i), Magic, Symbol(), Error);

      double Ask = SymbolInfoDouble(Symbol(),SYMBOL_ASK);
      double Bid = SymbolInfoDouble(Symbol(),SYMBOL_BID);

      if(Operation_Type_Operation==0) //Only Buy
         if(Ticket_Compra==0 && Buy_Previous()==0) //Compra
           {
            Ticket_Compra = Apply_Order(ORDER_TYPE_BUY_STOP, Magic, Symbol(), 0, Ask+(Point_Anclaje*_Point)-(Distancia_Stop_Loss*_Point), Lotaje, Ask+(Point_Anclaje*_Point), Error);

            if(Ticket_Compra>0)
               TimeClose=TimeCurrent()+Tiempo;

           }

      if(Operation_Type_Operation==1) //Only Sel
         if(Ticket_Venta==0 && Sell_Previous()==0) //Venta
           {
            Ticket_Venta = Apply_Order(ORDER_TYPE_SELL_STOP, Magic, Symbol(), 0, Bid-(Point_Anclaje*_Point)+(Distancia_Stop_Loss*_Point), Lotaje, Bid-(Point_Anclaje*_Point), Error);

            if(Ticket_Venta>0)
               TimeClose=TimeCurrent()+Tiempo;
           }

     }


   if(PositionsTotal()>0 && Ticket_Compra>0) //Trilling Stop Compra
      Trilling_Stop_Buy();

   if(PositionsTotal()>0 && Ticket_Venta>0) //Trilling Stop Venta
      Trilling_Stop_Sell();

   if(OrdersTotal() == 0 && PositionsTotal() == 0)
     {
      Ticket_Venta=0;
      Ticket_Compra=0;
     }
   else
      Close_Order();

   if(AccountInfoDouble(ACCOUNT_BALANCE)>Porcentaje_Win && !Funcion)
     {
      Alert("Ya se ha fondeado la cuenta numero: " + IntegerToString(AccountInfoInteger(ACCOUNT_LOGIN)));
      Funcion=true;
     }
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|  Buy Previous                                                  |
//+------------------------------------------------------------------+
int Buy_Previous()
  {
   int Buy_Prev=0;

   for(int i=0; i<PositionsTotal(); i++)
      if(PositionGetTicket(i) && PositionGetString(POSITION_SYMBOL) == Symbol() && PositionGetInteger(POSITION_MAGIC)==Magic && PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
        {
         Buy_Prev++;
         break;
        }

   return Buy_Prev;
  }
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//|Sell Previous                                                     |
//+------------------------------------------------------------------+
int Sell_Previous()
  {
   int Sell_Prev=0;

   for(int i=0; i<PositionsTotal(); i++)
      if(PositionGetTicket(i) && PositionGetString(POSITION_SYMBOL) == Symbol() && PositionGetInteger(POSITION_MAGIC)==Magic && PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL)
        {
         Sell_Prev++;
         break;
        }

   return Sell_Prev;
  }
//+------------------------------------------------------------------+


///+-----------------------------------------------------------------+
//|Trilling Stop Sell                                                   |
//+------------------------------------------------------------------+
void Trilling_Stop_Sell()
  {
//Extract current Price
   double Current_Price = SymbolInfoDouble(Symbol(),SYMBOL_ASK);
   for(int i=0; i<PositionsTotal(); i++)
      if(PositionGetTicket(i) && PositionGetString(POSITION_SYMBOL) == Symbol() && PositionGetInteger(POSITION_MAGIC)==Magic && PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL && Current_Price < PositionGetDouble(POSITION_SL) && Current_Price < PositionGetDouble(POSITION_PRICE_OPEN))
        {
         double New_Stop_Loss=SymbolInfoDouble(Symbol(),SYMBOL_ASK)+(NormalizeDouble(1*_Point,Digits()));
         Modify_Operation_SL_TP(PositionGetTicket(i), Magic, Symbol(), 0, New_Stop_Loss, Error);
        }
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|  Trilling Stop Buy                                               |
//+------------------------------------------------------------------+
void Trilling_Stop_Buy()
  {
//Extract current Price
   double Current_Price = SymbolInfoDouble(Symbol(),SYMBOL_BID);
   for(int i=0; i<PositionsTotal(); i++)
      if(PositionGetTicket(i) && PositionGetString(POSITION_SYMBOL) == Symbol() && PositionGetInteger(POSITION_MAGIC)==Magic && PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY && Current_Price > PositionGetDouble(POSITION_SL) && Current_Price > PositionGetDouble(POSITION_PRICE_OPEN))
        {
         double New_Stop_Loss=SymbolInfoDouble(Symbol(),SYMBOL_BID)-(NormalizeDouble(1*_Point,Digits()));
         Modify_Operation_SL_TP(PositionGetTicket(i), Magic, Symbol(), 0, New_Stop_Loss, Error);
        }
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|  Close Operation                                                 |
//+------------------------------------------------------------------+
void Close_Order()
  {
   if(OrdersTotal()>0 && (Sell_Previous()==1 || Buy_Previous()==1))
      for(int i=0; i<OrdersTotal(); i++)
         if(OrderGetTicket(i) && OrderGetString(ORDER_SYMBOL) == Symbol() && OrderGetInteger(ORDER_MAGIC)==Magic && (OrderGetInteger(ORDER_TYPE)))
            Remove_Order(OrderGetTicket(i), Magic, Symbol(), Error);
  }
//+------------------------------------------------------------------+



//+------------------------------------------------------------------+
//|Apply Order                                                       |
//+------------------------------------------------------------------+
ulong Apply_Order(ENUM_ORDER_TYPE type_operation, int magic_number, string symbol_, double tp, double sl, double lotaje_, double price_order, int &error)
  {

   error = 0;
   bool Apply = false;
   ulong ticket = 0;

   MqlTradeRequest request= {};
   MqlTradeResult  result= {};

   ZeroMemory(request);
   ZeroMemory(result);

   request.action    =     TRADE_ACTION_PENDING;
   request.symbol    =     symbol_;
   request.volume    =     lotaje_;
   request.type      =     type_operation;
   request.price     =     price_order;
   request.deviation =     500;
   request.magic     =     magic_number;

   if(tp>0)
      request.tp    =  tp;

   if(sl>0)
      request.sl   =  sl;

   if(!OrderSend(request,result))
     {
      Print("Error in Order Number: ",GetLastError());
      error = GetLastError();
     }
   else
     {
      Apply = true;
      ticket = result.order;
     }

   return ticket;
  }
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//|Remove Order                                                      |
//+------------------------------------------------------------------+
bool Remove_Order(ulong ticket, int magic_number, string symbol_, int &error)
  {

   error = 0;
   bool Apply = false;

   MqlTradeRequest request= {};
   MqlTradeResult  result= {};

   ZeroMemory(request);
   ZeroMemory(result);

   request.action    =     TRADE_ACTION_REMOVE;
   request.order     =     ticket;
   request.symbol    =     symbol_;
   request.deviation =     500;
   request.magic     =     magic_number;


   if(!OrderSend(request,result))
     {
      error = GetLastError();
      Print("Error in Modify Order Number: ",error);
     }
   else
      Apply = true;

   return Apply;
  }
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//|Modify Operation SL_TP                                             |
//+------------------------------------------------------------------+
bool Modify_Operation_SL_TP(ulong ticket, int magic_number, string symbol_, double tp, double sl, int &error)
  {

   error = 0;
   bool Apply = false;

   MqlTradeRequest request= {};
   MqlTradeResult  result= {};

   ZeroMemory(request);
   ZeroMemory(result);

   request.action    =  TRADE_ACTION_SLTP;
   request.position  =  ticket;
   request.symbol    =  symbol_;
   request.tp        =  tp;
   request.sl        =  sl;
   request.magic     =  magic_number;

   if(!OrderSend(request,result))
     {
      Print("Error in Modify Operation number: ",GetLastError());
      error = GetLastError();
     }
   else
      Apply = true;

   return Apply;
  }
//+------------------------------------------------------------------+
