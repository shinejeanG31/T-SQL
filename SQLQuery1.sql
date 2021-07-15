select * from application.people;
select * from Purchasing.Suppliers;
select * from Sales.Customers;
select * from Sales.Orders;

/*1.	List of Persons¡¯ full name, all their fax and phone numbers, as well as the phone number and fax of the company they are working for (if any). 
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

/*2.	If the customer's primary contact person has the same phone number as the customer¡¯s phone number, list the customer companies;*/

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
