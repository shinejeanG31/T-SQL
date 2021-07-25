Use WideWorldImporters;

select * from application.people;
select * from Purchasing.Suppliers;
select * from Sales.Customers;
select * from Sales.Orders;

/*1.	List of Persons’ full name, all their fax and phone numbers, as well as the phone number and fax of the company they are working for (if any). 
select FullName, FaxNumber, PhoneNumber from application.people;*/
select P.PersonID, FullName, S.ComName as CompanyName, P.PhoneNumber as PersonPhoneNumber, P.FaxNumber as PersonFaxNumber,
S.PhoneNumber as CompanyPhoneNumber, S.FaxNumber as CompanyFaxNumber
from Application.People as P left join 
(
(select SupplierName as ComName, PrimaryContactPersonID as PersonID, PhoneNumber, FaxNumber from Purchasing.Suppliers)
union
(select SupplierName as ComName, AlternateContactPersonID as PersonID, PhoneNumber, FaxNumber from Purchasing.Suppliers)
union
(select CustomerName as ComName, PrimaryContactPersonID as PersonID, PhoneNumber, FaxNumber from Sales.Customers where CustomerCategoryID != 1)
union
(select CustomerName as ComName, AlternateContactPersonID as PersonID, PhoneNumber, FaxNumber from Sales.Customers  where CustomerCategoryID != 1)
) as S
on P.PersonID = S.PersonID
order by P.personID;

/*2.	If the customer's primary contact person has the same phone number as the customer’s phone number, list the customer companies;*/

select CustomerID, CustomerName as Company, S.PhoneNumber as CusPhone, A.PhoneNumber as ConPhone,
case when S.PrimaryContactPersonID = A.PersonID 
then 'Yes' else 'No' 
end 
as Is_the_same
from Sales.Customers as S join Application.People as A
on S.PrimaryContactPersonID = A.PersonID;

/*3.	List of customers to whom we made a sale prior to 2016 but no sale since 2016-01-01.*/

select FullName CustomerName from 
(select CustomerID, (case when datediff(day,'2016-01-01',OrderDate)<0 then 'true' 
              when datediff(day,'2016-01-01',OrderDate) is null then 'False'
			  when datediff(day,'2016-01-01',OrderDate)>=0 then 'False' end) IsCustomer
from Sales.Orders) O
join Application.People as P
on P.PersonID = O.CustomerID
where O.IsCustomer = 'true';

/*4.	List of Stock Items and total quantity for each stock item in Purchase Orders in Year 2013.*/
select StockItemId, sum(OrderedOuters) TotalQuantity  from Purchasing.PurchaseOrderLines PL 
join Purchasing.PurchaseOrders PO on PL.PurchaseOrderID = PO.PurchaseOrderID
where PO.OrderDate like '2013%'
group by StockItemId
order by StockItemId;

/*5.	List of stock items that have at least 10 characters in description.*/
select StockItemID, StockItemName
from warehouse.stockitems
where len(SearchDetails) >= 10;

/*6.	List of stock items that are not sold to the state of Alabama and Georgia in 2014.
select top 10 * from application.StateProvinces; 
select top 10 * from application.Cities; --CityID, StateProvinceID
select top 10 * from sales.Customers; --CustomerID, deliveryCityID
select top 10 * from sales.OrderLines;--OrderID, StockItemID
select top 10 * from sales.Orders;--OrderID, CustomerID， OrderDate */

select SL.StockItemID from sales.Orders SO join sales.OrderLines SL
on SO.OrderID = SL.OrderID 
where SO.CustomerID not in
(select S.CustomerID from sales.Customers S join application.Cities C 
on S.DeliveryCityID = C.CityID join application.StateProvinces Sta
on C.StateProvinceID = Sta.StateProvinceID
where Sta.StateProvinceName = 'Alabama' or Sta.StateProvinceName = 'Georgia')
and SO.OrderID like '2014';

/*7.	List of States and Avg dates for processing (confirmed delivery date – order date).*/

--select top 10 * from Sales.Invoices; --ConfirmedDeliveryTime, OrderID
--select top 10 * from Sales.InvoiceLines; --Invoiced ID
--select top 10 * from sales.Orders;--OrderID, OrderDate 

select sp.StateProvinceCode, round(avg(cast(datediff(dayofyear,OrderDate,ConfirmedDeliveryTime) as float)),2) avg_processing_date
from Sales.Invoices i join Sales.Orders o on o.OrderID = i.OrderID
join Sales.Customers c on c.CustomerID = o.CustomerID
join Application.Cities ct on DeliveryCityID = ct.CityID
join Application.StateProvinces sp on ct.StateProvinceID = sp.StateProvinceID
group by sp.StateProvinceCode

/*8.	List of States and Avg dates for processing (confirmed delivery date – order date) by month.*/

select sp.StateProvinceCode, month(orderdate) month, round(avg(cast(datediff(dayofyear,OrderDate,ConfirmedDeliveryTime) as float)),2) avg_processing_month
from Sales.Invoices i join Sales.Orders o on o.OrderID = i.OrderID
join Sales.Customers c on c.CustomerID = o.CustomerID
join Application.Cities ct on DeliveryCityID = ct.CityID
join Application.StateProvinces sp on ct.StateProvinceID = sp.StateProvinceID
group by sp.StateProvinceCode, month(orderdate)
order by sp.StateProvinceCode, month(orderdate)

/*9.	List of StockItems that the company purchased more than sold in the year of 2015.*/

select p.StockItemID from
(select si.StockItemID, sum(pol.OrderedOuters) total_purchased
from Purchasing.PurchaseOrderLines pol join Purchasing.PurchaseOrders po on pol.PurchaseOrderID = po.PurchaseOrderID
join Warehouse.StockItems si on si.StockItemID = pol.StockItemID
where year(po.OrderDate) = 2015
group by si.StockItemID) p
left join
(select si.StockItemID, sum(sol.Quantity) total_sold
from Sales.Orders so inner join Sales.OrderLines sol on so.OrderID = sol.OrderID
join Warehouse.StockItems si on si.StockItemID = sol.StockItemID
where year(so.OrderDate) = 2015
group by si.StockItemID) s
on p.StockItemID = s.StockItemID
where p.total_purchased > s.total_sold or p.total_purchased is null

/*10.	List of Customers and their phone number, together with the primary contact person’s name, 
to whom we did not sell more than 10  mugs (search by name) in the year 2016.*/
select CustomerName, c.PhoneNumber, FullName PrimaryContactPerson
from Sales.Customers c join Application.People p on PersonID = PrimaryContactPersonID
where CustomerID in 
(select CustomerID
from Warehouse.StockItems s join Sales.OrderLines ol on s.StockItemID = ol.StockItemID
join Sales.Orders o on o.OrderID = ol.OrderID
where StockItemName like '%mug%' and year(OrderDate) = 2016
group by CustomerID
having sum(Quantity) <= 10)

/*11.	List all the cities that were updated after 2015-01-01.*/

select distinct CityName from Application.Cities
where ValidFrom >= '2015-01-01'

/*12.	List all the Order Detail (Stock Item name, delivery address, delivery state, city, country, 
customer name, customer contact person name, customer phone, quantity) for the date of 2014-07-01. 
Info should be relevant to that date.*/

select StockItemName, DeliveryAddressLine1, DeliveryAddressLine2, 
StateProvinceName, CityName, CountryName, c.CustomerName, 
FullName customer_contact_person_name, c.PhoneNumber customer_phone, Quantity
from Warehouse.StockItems s inner join Sales.OrderLines ol on s.StockItemID = ol.StockItemID
join Sales.Orders o on o.OrderID = ol.OrderID
join Sales.Customers c on c.CustomerID = o.CustomerID
join Application.People p on p.PersonID = c.PrimaryContactPersonID
join Application.Cities ci on c.DeliveryCityID = ci.CityID
join Application.StateProvinces sp on sp.StateProvinceID = ci.StateProvinceID
join Application.Countries co on co.CountryID = sp.CountryID
where OrderDate = '2014-07-01'

/*13.	List of stock item groups and total quantity purchased, total quantity sold, and 
the remaining stock quantity (quantity purchased – quantity sold)*/

select StockGroupName, quantity_purchased, quantity_sold, quantity_purchased - quantity_sold remaining_quantity
from Warehouse.StockGroups sgt join 
(select ssg.StockGroupID , sum(cast(pol.OrderedOuters as numeric(12, 0))) quantity_purchased, 
sum(cast(ol.Quantity as numeric(12, 0))) quantity_sold
from Warehouse.StockItemStockGroups ssg join Warehouse.StockItems s on ssg.StockItemID = s.StockItemID
join Purchasing.PurchaseOrderLines pol on s.StockItemID=pol.StockItemID
join Purchasing.PurchaseOrders po on po.PurchaseOrderID = pol.PurchaseOrderID
left join sales.OrderLines ol on s.StockItemID=ol.StockItemID
join sales.orders o on o.OrderID = ol.OrderID
group by ssg.StockGroupID) q on sgt.StockGroupID = q.StockGroupID


/*14.	List of Cities in the US and the stock item that the city got the most deliveries in 2016. 
If the city did not purchase any stock items in 2016, print “No Sales”.*/

with UScity as
(select CityID, CityName, StateProvinceName from Application.Cities ci 
join Application.StateProvinces sp on sp.StateProvinceID = ci.StateProvinceID
join Application.Countries co on co.CountryID = sp.CountryID
where CountryName = 'United States')
select UScity.CityName, UScity.StateProvinceName, 
ISNULL(cast(StockItemID as varchar), 'No Sales') most_delivered_stockitem
from UScity left join
(select CityID, cityname, StateProvinceName, StockItemID, count(InvoiceID) deliveries,
rank() over (partition by cityname, StateProvinceName order by count(InvoiceID) desc) rank_d
from Sales.Invoices i join Sales.OrderLines ol on i.OrderID = ol.OrderID
join Sales.Orders o on o.OrderID = ol.OrderID
join Sales.Customers c on c.CustomerID = o.CustomerID
right join UScity ci on DeliveryCityID = ci.cityid
where year(OrderDate) = 2016
group by CityID, cityname, StateProvinceName, StockItemID) temp
on temp.CityID = UScity.CityID
order by StateProvinceName, CityName


/*15.	List any orders that had more than one delivery attempt (located in invoice table).*/
select OrderID from Sales.Invoices
where JSON_QUERY(ReturnedDeliveryData,'$.Events[2]') is not null


/*16.	List all stock items that are manufactured in China. (Country of Manufacture)*/

select StockItemID,StockItemName
from Warehouse.StockItems
where JSON_VALUE(CustomFields,'$.CountryOfManufacture') = 'China'

/*17.	Total quantity of stock items sold in 2015, group by country of manufacturing.*/

select sum(quantity), JSON_VALUE(CustomFields,'$.CountryOfManufacture') CountryOfManufacture
from Warehouse.StockItems s inner join Sales.OrderLines ol on ol.StockItemID = s.StockItemID
inner join Sales.Orders o on o.OrderID = ol.OrderID
where year(OrderDate) = 2015
group by JSON_VALUE(CustomFields,'$.CountryOfManufacture')

/*18.	Create a view that shows the total quantity of stock items of each stock group sold (in orders) 
by year 2013-2017. [Stock Group Name, 2013, 2014, 2015, 2016, 2017]*/

go
create or alter view sales.quantity_sold_by_group_2013_2017
as
(select StockGroupName, [2013], [2014], [2015], [2016], [2017]
from 
(select StockGroupName, year(orderdate) yr, Quantity
from Warehouse.StockGroups sg join Warehouse.StockItemStockGroups ssg on sg.StockGroupID = ssg.StockGroupID
join Warehouse.StockItems s on ssg.StockItemID = s.StockItemID
join Sales.OrderLines ol on ol.StockItemID = s.StockItemID
join Sales.Orders o on o.OrderID = ol.OrderID) p
pivot(
    sum(quantity) for yr in ([2013], [2014], [2015], [2016], [2017])
) pvt);
go

/*19.	Create a view that shows the total quantity of stock items of each stock group sold (in orders) 
by year 2013-2017. [Year, Stock Group Name1, Stock Group Name2, Stock Group Name3, … , Stock Group Name10] */

go
declare @cols nvarchar(max);
declare @query nvarchar(max);
select @cols = COALESCE(@cols + ', ','') + QUOTENAME(StockGroupName)
FROM
(select distinct StockGroupName
from Warehouse.StockGroups) sg
order by sg.StockGroupName
set @query = 
'create or alter view sales.stock_quantity_by_group_year
as 
(select year, ' + @cols + '
from 
(select StockGroupName, year(orderdate) as year, Quantity
from Warehouse.StockGroups sg join Warehouse.StockItemStockGroups ssg on sg.StockGroupID = ssg.StockGroupID
join Warehouse.StockItems s on ssg.StockItemID = s.StockItemID
join Sales.OrderLines ol on ol.StockItemID = s.StockItemID
join Sales.Orders o on o.OrderID = ol.OrderID
where year(orderdate) in (2013, 2014, 2015, 2016, 2017)) p
pivot(
    sum(quantity) for StockGroupName in (' + @cols + ')
) pvt)'
exec(@query)
go

/*20.	Create a function, input: order id; return: total of that order. 
List invoices and use that function to attach the order total to the other fields of invoices. */

create or alter function sales.invoice_order_total (@orderid int)
returns decimal(18,2)
as
begin
    declare @OrderTotal decimal(18,2);
    select @OrderTotal = sum(Quantity * UnitPrice)
    from Sales.OrderLines
    where OrderID = @orderid;
    return @OrderTotal;
end
go

select *, Sales.invoice_order_total(OrderID) as OrderTotal from Sales.Invoices



/*21.	Create a new table called ods.Orders. Create a stored procedure, with proper error handling and transactions,
that input is a date; when executed, it would find orders of that day, calculate order total, and save the information 
(order id, order date, order total, customer id) into the new table. If a given date is already existing in the new table, 
throw an error and roll back. Execute the stored procedure 5 times using different dates. */

drop table ods.Orders;
go
drop schema ods;
go

Create schema ods;
go

Create table ods.Orders
(order_id int,
order_date datetime,
order_total int,
customer_id int
);


if Exists(select name from sysobjects where NAME = 'finddate' and type='P') 
    drop procedure finddate


Create Procedure finddate
@inputdate datetime

as
Begin

Set NOCOUNT ON;
Set XACT_ABORT ON;

Begin  Tran
save tran aaa
if not Exists (select * from ods.Orders where order_date = @inputdate)
insert into ods.Orders
(order_id,order_date,order_total,customer_id)
select SO.OrderID, SO.OrderDate, T.OrderTotal, SO.CustomerID from sales.Orders SO
  join (
  select OrderDate, count(OrderID) OrderTotal from sales.Orders
  where OrderDate = @inputdate
  group by OrderDate) T
  on SO.OrderDate = T.OrderDate
  where SO.OrderDate = @inputdate
  order by SO.OrderID;
select * from ods.Orders;

if @@error<>0 
begin 

rollback tran aaa 

commit tran ok

end

else 

commit tran ok 

End


Exec finddate @inputdate='2013-01-01'
Exec finddate @inputdate='2017-01-01'
Exec finddate @inputdate='2016-01-01'
Exec finddate @inputdate='2014-01-01'
Exec finddate @inputdate='2015-01-01'


/*22.	Create a new table called ods.StockItem. It has following columns: [StockItemID], [StockItemName], 
[SupplierID] ,[ColorID] ,[UnitPackageID] ,[OuterPackageID] ,[Brand] ,[Size] ,[LeadTimeDays] ,
[QuantityPerOuter] ,[IsChillerStock] ,[Barcode] ,[TaxRate]  ,[UnitPrice],[RecommendedRetailPrice] ,
[TypicalWeightPerUnit] ,[MarketingComments]  ,[InternalComments], [CountryOfManufacture], [Range], 
[Shelflife]. Migrate all the data in the original stock item table.*/
IF OBJECT_ID('ods.StockItem', 'U') IS NOT NULL 
    DROP TABLE ods.StockItem; 
select StockItemID, StockItemName, SupplierID, ColorID, UnitPackageID, OuterPackageID, Brand, 
Size, LeadTimeDays, QuantityPerOuter, IsChillerStock, Barcode, TaxRate, UnitPrice, 
RecommendedRetailPrice, TypicalWeightPerUnit, MarketingComments, InternalComments, 
JSON_VALUE(CustomFields,'$.CountryOfManufacture') CountryOfManufacture,
JSON_VALUE(CustomFields,'$.Range') 'Range',
datediff(DAYOFYEAR, ValidFrom, ValidTo) Shelflife
into ods.StockItem
from Warehouse.StockItems
select * from ods.StockItem

/*23.	Rewrite your stored procedure in (21). Now with a given date, it should wipe out all the order 
data prior to the input date and load the order that was placed in the next 7 days following 
the input date.*/

if Exists(select name from sysobjects where NAME = 'finddate2' and type='P') 
    drop procedure finddate2;


Create Procedure finddate2
@inputdate2 datetime

as
Begin

Set NOCOUNT ON;
Set XACT_ABORT ON;

TRUNCATE TABLE ods.Orders
insert into ods.Orders
(order_id,order_date,order_total,customer_id)
select SO.OrderID, SO.OrderDate, T.OrderTotal, SO.CustomerID from sales.Orders SO
  join (
  select OrderDate, count(OrderID) OrderTotal from sales.Orders
  where OrderDate >= @inputdate2 and OrderDate <= @inputdate2 + 7
  group by OrderDate) T
  on SO.OrderDate = T.OrderDate
  where SO.OrderDate >= @inputdate2 and SO.OrderDate <= @inputdate2 + 7
  order by SO.OrderID;
select * from ods.Orders;

End


Exec finddate2 @inputdate2='2013-01-01'
Exec finddate2 @inputdate2='2017-01-01'
Exec finddate2 @inputdate2='2016-01-05'
Exec finddate2 @inputdate2='2014-01-01'
Exec finddate2 @inputdate2='2015-01-01'



/*24.	Consider the JSON file:
Looks like that it is our missed purchase orders. Migrate these data into Stock Item, Purchase Order 
and Purchase Order Lines tables. Of course, save the script.*/
declare @json NVARCHAR(max) = 
N'{"PurchaseOrders":
    [
        {
         "StockItemName":"Panzer Video Game",
         "Supplier":"7",
         "UnitPackageId":"1",
         "OuterPackageId":[
            6,
            7
         ],
         "Brand":"EA Sports",
         "LeadTimeDays":"5",
         "QuantityPerOuter":"1",
         "TaxRate":"6",
         "UnitPrice":"59.99",
         "RecommendedRetailPrice":"69.99",
         "TypicalWeightPerUnit":"0.5",
         "CountryOfManufacture":"Canada",
         "Range":"Adult",
         "OrderDate":"2018-01-01",
         "DeliveryMethod":"Post",
         "ExpectedDeliveryDate":"2018-02-02",
         "SupplierReference":"WWI2308"
         },
         {
         "StockItemName":"Panzer Video Game",
         "Supplier":"5",
         "UnitPackageId":"1",
         "OuterPackageId":"7",
         "Brand":"EA Sports",
         "LeadTimeDays":"5",
         "QuantityPerOuter":"1",
         "TaxRate":"6",
         "UnitPrice":"59.99",
         "RecommendedRetailPrice":"69.99",
         "TypicalWeightPerUnit":"0.5",
         "CountryOfManufacture":"Canada",
         "Range":"Adult",
         "OrderDate":"2018-01-02",
         "DeliveryMethod":"Post",
         "ExpectedDeliveryDate":"2018-02-02",
         "SupplierReference":"269622390"
         }
    ]
}'
-- insert into Purchasing.PurchaseOrders
insert into Purchasing.PurchaseOrders
    select (select max(PurchaseOrderID) + 1 from Purchasing.PurchaseOrders nolock),
    JSON_VALUE(oj.value, '$.Supplier'),
    JSON_VALUE(oj.value, '$.OrderDate'),
    (select DeliveryMethodID from Application.DeliveryMethods where DeliveryMethodName = JSON_VALUE(oj.value, '$.DeliveryMethod')),
    (select PrimaryContactPersonID from Purchasing.Suppliers where SupplierID = JSON_VALUE(oj.value, '$.Supplier')),
    JSON_VALUE(oj.value,'$.ExpectedDeliveryDate'),
    JSON_VALUE(oj.value,'$.SupplierReference'),
    0,
    null,
    null,
    (select min(LastEditedBy) from Purchasing.PurchaseOrders where SupplierID = JSON_VALUE(oj.value, '$.Supplier')),
    getdate()
    from openjson(@json,'$.PurchaseOrders') oj

-- insert into Warehouse.StockItems
insert into Warehouse.StockItems
select
    (select max(StockItemID) + 1 from Warehouse.StockItems),
    JSON_VALUE(@json,'$.PurchaseOrders[0].StockItemName'),
    cast(JSON_VALUE(@json,'$.PurchaseOrders[0].Supplier') as int), null,
    cast(JSON_VALUE(@json,'$.PurchaseOrders[0].UnitPackageId') as int),
    cast(JSON_VALUE(@json,'$.PurchaseOrders[0].OuterPackageId[0]') as int),
    JSON_VALUE(@json,'$.PurchaseOrders[0].Brand'), null,
    JSON_VALUE(@json,'$.PurchaseOrders[0].LeadTimeDays'),
    JSON_VALUE(@json,'$.PurchaseOrders[0].QuantityPerOuter'),
    cast(0 as bit), null,
    JSON_VALUE(@json,'$.PurchaseOrders[0].TaxRate'),
    JSON_VALUE(@json,'$.PurchaseOrders[0].UnitPrice'),
    JSON_VALUE(@json,'$.PurchaseOrders[0].RecommendedRetailPrice'),
    JSON_VALUE(@json,'$.PurchaseOrders[0].TypicalWeightPerUnit'),null,null,null,null,null,null,
    7, SYSDATETIME(),
    (select max(ValidTo) from Warehouse.StockItems)
/*
insert into Purchasing.PurchaseOrderLines
values(
    (select max(PurchaseOrderLineID) + 1 from Purchasing.PurchaseOrderLines)
)
*/

/*25.	Revisit your answer in (19). Convert the result in JSON string and save it to the server using TSQL FOR JSON PATH.*/

select year, isnull([Airline Novelties],0) as 'StockGroup.Airline Novelties',
isnull(Clothing,0) as 'StockGroup.Clothing',
isnull([Computing Novelties],0) as 'StockGroup.Computing Novelties',
isnull([Furry Footwear],0) as 'StockGroup.Furry Footwear',
isnull(Mugs,0) as 'StockGroup.Mugs',
isnull([Novelty Items],0) as 'StockGroup.Novelty Items',
isnull([Packaging Materials],0) as 'StockGroup.Packaging Materials',
isnull([T-Shirts],0) as 'StockGroup.T-Shirts',
isnull(Toys,0) as 'StockGroup.Toys',
isnull([USB Novelties],0) as 'StockGroup.USB Novelties'
from sales.stock_quantity_by_group_year
order by year
for json path

/*26.	Revisit your answer in (19). Convert the result into an XML string and save it to the server using TSQL FOR XML PATH.*/

select b.year as '@Year', 
isnull([Airline Novelties],0) as 'StockGroups/AirlineNovelties',
isnull(Clothing,0) as 'StockGroups/Clothing',
isnull([Computing Novelties],0) as 'StockGroups/ComputingNovelties',
isnull([Furry Footwear],0) as 'StockGroups/FurryFootwear',
isnull(Mugs,0) as 'StockGroups/Mugs',
isnull([Novelty Items],0) as 'StockGroups/NoveltyItems',
isnull([Packaging Materials],0) as 'StockGroups/PackagingMaterials',
isnull([T-Shirts],0) as 'StockGroups/T-Shirts',
isnull(Toys,0) as 'StockGroups/Toys',
isnull([USB Novelties],0) as 'StockGroups/USBNovelties'
from sales.stock_quantity_by_group_year b
order by year
for xml path('ReportYear'), root('StockGroupQuantity')

/*27.	Create a new table called ods.ConfirmedDeviveryJson with 3 columns (id, date, value) . 
Create a stored procedure, input is a date. The logic would load invoice information (all columns) as well as 
invoice line information (all columns) and forge them into a JSON string and then insert into the new table just created. 
Then write a query to run the stored procedure for each DATE that customer id 1 got something delivered to him.*/

-- create table
if exists(select * from ods.ConfirmedDeviveryJson)
    drop table ods.ConfirmedDeviveryJson
create table ods.ConfirmedDeviveryJson (
    id int primary key not null,
    date date not null,
    value NVARCHAR(max) not null
)
go

-- delare a temptable to store events info
if exists(select * from #temptable)
    drop table #temptable
create table #temptable(InvoiceID int, Event nvarchar(100), EventTime datetime2(7), 
    ConNote nvarchar(50), DriverID int, Latitude decimal(10,7), Longitude decimal(10,7), 
    Status nvarchar(50), DeliveredWhen datetime2(7), ReceivedBy nvarchar(100))
-- insert records into temptable
INSERT INTO #temptable
    select sales.Invoices.InvoiceID,Events.Event,Events.EventTime,Events.ConNote,
    Events.DriverID,Events.Latitude,Events.Longitude,Events.Status,
    ReturnedDeliveryData.DeliveredWhen, ReturnedDeliveryData.ReceivedBy
    from Sales.Invoices
    cross apply 
    openjson(ReturnedDeliveryData) 
    with(
        Events nvarchar(max) AS JSON,
        DeliveredWhen datetime2(7),
        ReceivedBy nvarchar(100)
    )
    as ReturnedDeliveryData
    cross apply
    openjson(ReturnedDeliveryData.Events)
    with(
        Event nvarchar(100),
        EventTime datetime2(7),
        ConNote nvarchar(50),
        DriverID int,
        Latitude decimal(10,7),
        Longitude decimal(10,7),
        Status nvarchar(50)
    ) as Events
-- procedure start here
go
create or alter proc ods.load_invoice_info
    @date date,
    @custid int
as
begin
-- insert value into ods.ConfirmedDeviveryJson
    insert into ods.ConfirmedDeviveryJson
    select InvoiceID id, cast(ConfirmedDeliveryTime as date) date,
    (select i.InvoiceID,CustomerID,BillToCustomerID,OrderID,DeliveryMethodID,ContactPersonID,
    AccountsPersonID,SalespersonPersonID,PackedByPersonID,InvoiceDate,CustomerPurchaseOrderNumber,
    IsCreditNote,CreditNoteReason,Comments,DeliveryInstructions,InternalComments,TotalDryItems,
    TotalChillerItems,DeliveryRun,RunPosition,
    (select Event,EventTime,ConNote,DriverID,Latitude,Longitude,Status from #temptable
    where InvoiceID = i.InvoiceID for json path) as 'ReturnedDeliveryData.Events',
    (select distinct DeliveredWhen from #temptable where InvoiceID = i.InvoiceID) as 'ReturnedDeliveryData.DeliveredWhen',
    (select distinct ReceivedBy from #temptable where InvoiceID = i.InvoiceID) as 'ReturnedDeliveryData.DReceivedBy',
    ConfirmedDeliveryTime,ConfirmedReceivedBy,i.LastEditedBy 'InvoiceLastEditedBy',i.LastEditedWhen 'InvoiceLastEditedWhen',
    (select * from Sales.InvoiceLines where InvoiceID = i.InvoiceID for json path) 'InvoiceLines'
    from Sales.Invoices i
    where InvoiceID = main.InvoiceID
    for json path) value
    from Sales.Invoices main
    where cast(ConfirmedDeliveryTime as date) = @date and CustomerID = @custid
end

select * from ods.ConfirmedDeviveryJson
-- run the stored procedure for each DATE that customer id 1 got something delivered to him
DECLARE @deliverydate date
DECLARE myCursor CURSOR FORWARD_ONLY FOR
    SELECT distinct cast(ConfirmedDeliveryTime as date) deliverydate from Sales.Invoices
OPEN myCursor
FETCH NEXT FROM myCursor INTO @deliverydate
WHILE @@FETCH_STATUS = 0 BEGIN
    EXEC ods.load_invoice_info @date = @deliverydate,@custid = 1
    FETCH NEXT FROM myCursor INTO @deliverydate
END;
CLOSE myCursor;
DEALLOCATE myCursor;

select * from ods.ConfirmedDeviveryJson
