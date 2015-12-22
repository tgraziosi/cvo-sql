SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- -- --Inactive Accounts no sales in 24Months for REACTIVATION
-- Author - E.L.
-- 071812 - tag - create SP for EV

/*
exec cvo_custinactive_sp 'terr=30304'
*/

CREATE procedure [dbo].[cvo_custinactive_sp] (@whereclause varchar(1024)='')

as 

DECLARE @terr INT
SET @terr=''

if (charindex('terr',@whereclause) <> 0 and charindex('%',@whereclause) <> 0)
	begin
		set @terr = substring(@whereclause,charindex('%',@whereclause)+1,5)
	end

--select  @terr

--history
IF(OBJECT_ID('tempdb.dbo.#CustInactive') is not null)                          
drop table #CustInactive 
SELECT T1.SALESPERSON_CODE as SLP, T1.TERRITORY_CODE as TERR, t1.CUSTomer_CODE as 'Cust#', t1.address_name, addr2,addr3,addr4, Contact_phone,  
		MAX(DATE_SHIPPED) 'LastInv',
		(SELECT DATEADD(dd, -DAY(DATEADD(m,1,GETDATE())), DATEADD(m,-24,GETDATE()))) as 'IncenDate'
	INTO #CustInactive
	FROM CVO_ORDERS_ALL_HIST T2
	LEFT OUTER JOIN armaster t1 ON t1.customer_code=t2.cust_code and t1.ship_to_code=t2.ship_to
WHERE t1.TERRITORY_CODE = @TERR
AND T1.STATUS_TYPE=1
GROUP BY T1.SALESPERSON_CODE, T1.TERRITORY_CODE, t1.CUSTomer_CODE, t1.address_name, addr2,addr3,addr4, Contact_phone
HAVING MAX(DATE_SHIPPED) <  (SELECT DATEADD(dd, -DAY(DATEADD(m,1,GETDATE())), DATEADD(m,-24,GETDATE())))

INSERT INTO #CustInactive 
--live
SELECT T1.SALESPERSON_CODE as SLP, T1.TERRITORY_CODE as TERR, t1.CUSTomer_CODE as 'Cust#', t1.address_name, addr2,addr3,addr4, Contact_phone,  
		MAX(DATE_SHIPPED) 'LastInv',
		(SELECT DATEADD(dd, -DAY(DATEADD(m,1,GETDATE())), DATEADD(m,-24,GETDATE()))) as 'IncenDate'
	FROM ORDERS_ALL T2
	LEFT OUTER JOIN armaster t1 ON t1.customer_code=t2.cust_code and t1.ship_to_code=t2.ship_to
WHERE t1.TERRITORY_CODE = @TERR
AND T1.STATUS_TYPE=1
GROUP BY T1.SALESPERSON_CODE, T1.TERRITORY_CODE, t1.CUSTomer_CODE, t1.address_name, addr2,addr3,addr4, Contact_phone
--HAVING MAX(DATE_SHIPPED) <  (SELECT DATEADD(dd, -DAY(DATEADD(m,1,GETDATE())), DATEADD(m,-24,GETDATE())))

SELECT SLP,TERR,Cust#,address_name,addr2,addr3,addr4,Contact_phone, MAX(LastInv) LastInv, IncenDate
FROM #CustInactive
GROUP BY SLP,TERR,Cust#,address_name,addr2,addr3,addr4,Contact_phone,IncenDate
HAVING MAX(LastInv) <  (SELECT DATEADD(dd, -DAY(DATEADD(m,1,GETDATE())), DATEADD(m,-24,GETDATE())))

GO
GRANT EXECUTE ON  [dbo].[cvo_custinactive_sp] TO [public]
GO
