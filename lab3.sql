-- Customers that have ever have their invoices attempted delivery for more than once, sort by date when the latest incident happens
--json

--select top 10 * from Sales.Invoices
--select JSON_QUERY(ReturnedDeliveryData) Re from Sales.Invoices;

select SI.CustomerID, SC.CustomerName from (select CustomerID, JSON_value(ReturnedDeliveryData,'$.Events[1].Comment') Re, ConfirmedDeliveryTime Time_ from Sales.Invoices) SI 
join sales.Customers SC
on SI.CustomerID = SC.CustomerID

where Re is not null
order by Time_ Desc;


-- List of (Sales People) and (total numbers) of whose orders that (the delivery date is more than 7 days later than the order date).
--Group by

select top 10 * from sales.Orders;--OrderID, CustomerID, SalespersonPersonID, OrderDate
select top 10 * from Sales.Invoices;--OrderID, ConfirmedDeliveryTime
select top 10 * from Application.People;--personID, FullName


Select  P.personID, P.FullName , A.Order_Amount from

(select SO.SalespersonPersonID, count(distinct SO.OrderID) Order_Amount from Sales.Orders SO join
Sales.Invoices SI on SO.OrderID=SI.OrderID
where DATEDIFF(day, SO.OrderDate, SI.ConfirmedDeliveryTime) > 7
group by SO.SalespersonPersonID
) A 
join
Application.People P
on A.SalespersonPersonID = P.personID

order by A.Order_Amount desc;

-- Total Numbers of £¨stockitems£© on sales, of each £¨stockitem group£©, for each £¨year£© existing in the database. [total_number, 2013,2014,2015,2016,2017...]
--Dynamic pivot
--select top 10 * from Warehouse.StockGroups;--StockGroupID, StockGroupName
--select top 10 * from Warehouse.StockItemStockGroups;--StockItemID, StockGroupID,
--select * from Warehouse.StockItems; --StockItemID,ValidFrom

DECLARE @columns NVARCHAR(MAX), @sql NVARCHAR(MAX);
SET @columns = N'';
SELECT @columns += N',' + QUOTENAME(Year)
  FROM (select year(ValidFrom) Year
	  from Warehouse.StockItems_Archive
	  GROUP BY year(ValidFrom)) AS x;

print @columns;
SET @sql = N'
SELECT *
FROM
(
  SELECT S.StockGroupName, year(I.ValidFrom) Year, I.StockItemID
	  from Warehouse.StockItems_Archive I join Warehouse.StockItemStockGroups G
	  on I.StockItemID= G.StockItemID
	  join Warehouse.StockGroups S
	  on S.StockGroupID = G.StockGroupID
) AS j
PIVOT
(
  Count([StockItemID]) FOR Year IN ('
  + STUFF(@columns, 1, 1, '') +')
) AS p;';
--PRINT @sql;
EXEC sp_executesql @sql;

