--(1)
--select top 10 * from sales.Customers;--CustomerID, CustomerName
--select top 10 * from sales.OrderLines;--OrderID, StockItemID, Quantity
--select top 10 * from sales.Orders;--OrderID, CustomerID, OrderDate
--select top 10 * from Warehouse.StockItemStockGroups;--StockItemID, StockGroupID
--select top 10 * from Warehouse.StockGroups;--StockGroupID, StockGroupName

select CustomerName, PostalCityID from sales.Customers
where CustomerID in
(select CustomerID from
(select CustomerID, sum(Quantity) Amount from 
(select S1.CustomerID, S2.Quantity, S1.OrderDate,S2.StockItemID from sales.Orders S1
join sales.OrderLines S2 on S1.OrderID = S2.OrderID 
where S1.OrderDate like '2016%' and S2.StockItemID in 
(select W1.StockItemID from Warehouse.StockItemStockGroups W1 left join Warehouse.StockGroups W2 
on W1.StockGroupID = W2.StockGroupID where W2.StockGroupName='toys')) A
group by CustomerID) B
where Amount > 50);

--(2)
--select top 10 * from Purchasing.PurchaseOrderLines;--PurchaseOrderID, StockItemID, OrderedOuters
--select top 10 * from Purchasing.PurchaseOrders;--PurchaseOrderID, OrderDate

--select top 10 * from sales.OrderLines;--OrderID, StockItemID, Quantity
--select top 10 * from sales.Orders;--OrderID, CustomerID, OrderDate

--stockItemID --- > orderDate

--1th version (left join + right join + unio)
select StockItemID, isnull(ImportsAmount, 0)ImportsAmount, isnull(SalesAmount,0)SalesAmount from

(select * from 
(select P.StockItemID, P.ImportsAmount, S.SalesAmount from 
(select P1.StockItemID, sum(P1.OrderedOuters) ImportsAmount from Purchasing.PurchaseOrderLines P1 
join Purchasing.PurchaseOrders P2 on P1.PurchaseOrderID = P2. PurchaseOrderID 
where P2.OrderDate like '2016%'
group by P1.StockItemID) P full join
(select S1.StockItemID, sum(S1.Quantity) SalesAmount from sales.OrderLines S1
join sales.Orders S2 on S1.OrderID = S2.OrderID 
where S2.OrderDate like '2016%'
group by S1.StockItemID) S
on P.StockItemID = S.StockItemID) PMT
Union 
(select SS.StockItemID, PP.ImportsAmount, SS.SalesAmount from 
(select Ss1.StockItemID, sum(Ss1.Quantity) SalesAmount from sales.OrderLines Ss1
join sales.Orders Ss2 on Ss1.OrderID = Ss2.OrderID 
where Ss2.OrderDate like '2016%'
group by Ss1.StockItemID) SS
left join
(select Pp1.StockItemID, sum(Pp1.OrderedOuters) ImportsAmount from Purchasing.PurchaseOrderLines Pp1 
join Purchasing.PurchaseOrders Pp2 on Pp1.PurchaseOrderID = Pp2. PurchaseOrderID 
where Pp2.OrderDate like '2016%'
group by Pp1.StockItemID) PP
on PP.StockItemID = SS.StockItemID)) A

where isnull(ImportsAmount, 0) > isnull(SalesAmount,0)
order by StockItemID;

--2th version £¨full join)
select P_StockItemID StockItemID, isnull(ImportsAmount, 0)ImportsAmount, isnull(SalesAmount,0)SalesAmount from

(select P.StockItemID P_StockItemID, P.ImportsAmount, S.StockItemID S_StockItemID,SalesAmount from 
(select P1.StockItemID, sum(P1.OrderedOuters) ImportsAmount from Purchasing.PurchaseOrderLines P1 
join Purchasing.PurchaseOrders P2 on P1.PurchaseOrderID = P2. PurchaseOrderID 
where P2.OrderDate like '2016%'
group by P1.StockItemID) P full join
(select S1.StockItemID, sum(S1.Quantity) SalesAmount from sales.OrderLines S1
join sales.Orders S2 on S1.OrderID = S2.OrderID 
where S2.OrderDate like '2016%'
group by S1.StockItemID) S
on P.StockItemID = S.StockItemID) PMT

where isnull(ImportsAmount, 0) > isnull(SalesAmount,0)
order by StockItemID;



--£¨3£©
--select * from sales.SpecialDeals;--CustomerID, StockItemID, DiscountAmout, DiscountPercentage, UnitPrice,DiscountPercentage
--select top 10 * from sales.OrderLines;--OrderID, StockItemID, Quantity,StockItemID, UnitPrice



select  sum(SP.DiscountPercentage*SL.Quantity*SL.UnitPrice) Loss
from sales.SpecialDeals SP left join sales.OrderLines SL
on SP.StockItemID = SL.StockItemID;


