use AdventureWorks2019
go
select pp.Name as stockitemID, pp.Color as color,ppv.LastReceiptCost as UnitPrice, pp.ListPrice as recommendedRetailprice, 
pp.Size as size,pp.ModifiedDate as Vaildform,pps.ProductSubcategoryID as StockitemgroupID, ppv.BusinessEntityID as suplierID
from Production.Product pp
join Production.ProductSubcategory pps
on pp.ProductSubcategoryID= pps.ProductSubcategoryID
join Purchasing.ProductVendor ppv	
on pp.ProductID=ppv.ProductID

