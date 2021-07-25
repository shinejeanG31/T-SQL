
use AdventureWorks2019
go
drop table #personnew
create table #personnew( 
	PersonID int primary key not null, 
    Fullname nvarchar(50) not null, 
    PreferredName nvarchar(101) not null,
    IsPermittedToLogon bit not null,
	LogonName nvarchar(50),
	IsExternalLogonProvider bit not null,
	HashedPassword varbinary(max),
	IsSystemUser bit not null,
	IsEmployee   bit  not null,
	IsSalesperson  bit not null,
	UserPreferences nvarchar(max),
	PhoneNumber  nvarchar(20),
	FaxNumber    nvarchar(20),
	EmailAddress   nvarchar(256),
	Photo    varbinary(max),
	CustomFields  nvarchar(max),
	OtherLanguages nvarchar(max),
	LastEditedBy  int not null,
	ValidFrom datetime2(7) not null,
	ValidTo  datetime2(7) not null

)
go

insert into #personnew

select ROW_NUMBER() over(order by pp.BusinessEntityID) + 3261 AS personID,
COALESCE(pp.FirstName,'') + ' ' + COALESCE(pp.middlename,' ') + COALESCE(pp.lastname, '') as Fullname,
pp.FirstName as PreferredName,
1 as IsPermittedToLogon,
pe.EmailAddress as LogonName,
1 as IsExternalLogonProvider,
cast(ppw.PasswordSalt as varbinary )as HashedPassword,
1  as IsSystemUser,
0  as IsEmployee,
0  as IsSalesperson ,
null  as  UserPreferences,
ppp.PhoneNumber as PhoneNumber, 
null as FaxNumber,
pe.EmailAddress as EmailAddress ,
null as Photo ,
null as CustomFields,
null as OtherLanguages,
1 AS LastEditedBy,
GETDATE() as ValidFrom,
CAST('12/31/9999 23:59:59.9999' AS DATETIME2) AS ValidTo 
from Person.Person pp
join Person.EmailAddress pe
on pp.BusinessEntityID= pe.BusinessEntityID
join Person.PersonPhone ppp
on pp.BusinessEntityID = ppp.BusinessEntityID
join Person.Password ppw
on pp.BusinessEntityID =ppw.BusinessEntityID


select *
from #personnew 