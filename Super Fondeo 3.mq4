//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2018, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+
#property copyright "Tony Programa"
#property link      "https://www.instagram.com/tony_programa/"
#property version   "3.00"
#property strict

int Permiso = 0;
ulong Ticket_Compra = 0;
ulong Ticket_Venta = 0;

int Number_Buy=0;
int Number_Sell=0;
double Meta = 0;
bool Funcion = false;


input double Lotaje = 1; //Lotaje
input int Distancia_Stop_Loss = 0; //Stop Loss en Points
input int Point_Anclaje = 1; //Punto de anclaje en Puntos
input double Porcentaje_Win = 54050; //Meta a alcanzar
input int Magic = 152454;
input int Tiempo = 1;


datetime TimeClose = 0;

enum Operation
  {
   Only_Buy=0,
   Only_Sell=1,
  };

input Operation Operation_Type_Operation = 1;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {

   datetime Expiry=D'2025.03.27 00:00';
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

   if(AccountBalance()>Porcentaje_Win)
     {
      Alert("Ya se ha fondeado la cuenta numero: " + IntegerToString(AccountInfoInteger(ACCOUNT_LOGIN)));
     }
//---
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {

   if(OrdersTotal()>0 && Ticket_Compra>0) //Trilling Stop Compra
     {
      Trilling_Stop_Buy();
     }

   if(OrdersTotal()>0 && Ticket_Venta>0) //Trilling Stop Venta
     {
      Trilling_Stop_Sell();
     }

   if(OrdersTotal()==0)
     {
      Ticket_Venta=0;
      Ticket_Compra=0;
     }
   else
      Close_Operation();

   if(AccountBalance()<Porcentaje_Win && TimeCurrent() > TimeClose)
     {
      //--- Operation Finish
      if(OrdersTotal()>0 && Sell_Previous()==0 && Buy_Previous()==0)
        {
         for(int i=0; i<OrdersTotal(); i++)
           {
            bool A = OrderDelete(OrderTicket(),0);
           }
        }


      if(Operation_Type_Operation==0) //Only Buy
        {
         if(Ticket_Compra==0 && Buy_Previous()==0) //Compra
           {
            if(OrderSend(Symbol(),OP_BUYSTOP,Lotaje,Ask+(Point_Anclaje*_Point),0,Ask+(Point_Anclaje*_Point)-(Distancia_Stop_Loss*_Point),0,"",Magic,0,clrBlue)>0)
              {
               TimeClose=TimeCurrent()+Tiempo;
               Ticket_Compra = OrderTicket();
              }
           }
        }


      if(Operation_Type_Operation==1) //Only Sel
        {
         if(Ticket_Venta==0 && Sell_Previous()==0) //Venta
           {
            if(OrderSend(Symbol(),OP_SELLSTOP,Lotaje,Bid-(Point_Anclaje*_Point),0,Bid-(Point_Anclaje*_Point)+(Distancia_Stop_Loss*_Point),0,"",Magic,0,clrRed)>0)
              {
               TimeClose=TimeCurrent()+Tiempo;
               Ticket_Venta = OrderTicket();
              }
           }
        }
     }

   if(OrdersTotal()>0 && Ticket_Compra>0) //Trilling Stop Compra
     {
      Trilling_Stop_Buy();
     }

   if(OrdersTotal()>0 && Ticket_Venta>0) //Trilling Stop Venta
     {
      Trilling_Stop_Sell();
     }

   if(OrdersTotal()==0)
     {
      Ticket_Venta=0;
      Ticket_Compra=0;
     }
   else
      Close_Operation();

   if(AccountBalance()>Porcentaje_Win && !Funcion)
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
   for(int i=0; i<OrdersTotal(); i++)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==true && OrderSymbol()==Symbol() && OrderMagicNumber()==Magic && OrderType()==OP_BUY)
        {
         Buy_Prev++;
         break;
        }
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
   for(int i=0; i<OrdersTotal(); i++)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==true && OrderSymbol()==Symbol() && OrderMagicNumber()==Magic && OrderType()==OP_SELL)
        {
         Sell_Prev++;
         break;
        }
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
   if(OrderSelect(0,SELECT_BY_POS,MODE_TRADES)==true && OrderSymbol()==Symbol() && OrderMagicNumber()==Magic && OrderType()==OP_SELL && Current_Price < OrderStopLoss() && Current_Price < OrderOpenPrice())
     {
      // New Stop Loss
      double New_Stop_Loss=SymbolInfoDouble(Symbol(),SYMBOL_ASK)+(NormalizeDouble(1*_Point,Digits()));
      bool res = OrderModify(OrderTicket(),OrderOpenPrice(),New_Stop_Loss,OrderTakeProfit(),0,Red);
     }
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|  Trilling Stop Buy                                               |
//+------------------------------------------------------------------+
void Trilling_Stop_Buy()
  {
//Extract current
   double Current_Price = SymbolInfoDouble(Symbol(),SYMBOL_BID);
   if(OrderSelect(0,SELECT_BY_POS,MODE_TRADES)==true && OrderSymbol()==Symbol() && OrderMagicNumber()==Magic && OrderType()==OP_BUY && Current_Price > OrderStopLoss() && Current_Price > OrderOpenPrice())
     {
      // New Stop Loss
      double New_Stop_Loss=SymbolInfoDouble(Symbol(),SYMBOL_BID)-(NormalizeDouble(1*_Point,Digits()));
      bool res = OrderModify(OrderTicket(),OrderOpenPrice(),New_Stop_Loss,OrderTakeProfit(),0,Blue);
     }
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|  Close Operation                                                 |
//+------------------------------------------------------------------+
void Close_Operation()
  {

   if(OrdersTotal()>0 && (Sell_Previous()==1 || Buy_Previous()==1))
     {
      for(int i=0; i<OrdersTotal(); i++)
        {
         if(OrderSelect(0,SELECT_BY_POS,MODE_TRADES) && (OrderType()==OP_SELLSTOP || OrderType()==OP_BUYSTOP))
            bool A = OrderDelete(OrderTicket(),0);
        }
     }

  }
//+------------------------------------------------------------------+
