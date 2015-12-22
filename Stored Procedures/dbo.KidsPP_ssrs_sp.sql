SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


-- =============================================
-- Author:		elabarbera
-- Create date: 3/26/2013
-- Description:	Kids Program Planner
-- EXEC KidsPP_ssrs_sp
-- =============================================
CREATE PROCEDURE [dbo].[KidsPP_ssrs_sp] 
	
AS
BEGIN
	SET NOCOUNT ON;

-- Kids 5 Year Program Planner

DECLARE @P1From datetime
	DECLARE @P1To datetime
DECLARE @P2From datetime
	DECLARE @P2To datetime
DECLARE @P3From datetime
	DECLARE @P3To datetime
DECLARE @P4From datetime
	DECLARE @P4To datetime
DECLARE @P5From datetime
	DECLARE @P5To datetime
DECLARE @P6From datetime
	DECLARE @P6To datetime
DECLARE @JDateFrom int                                    
	DECLARE @JDateTo int

SET @P1From = DATEADD(YEAR, DATEDIFF(YEAR, 0,DATEADD(YEAR, 0, GETDATE())), 0)
	SET @P1To = DATEADD(MILLISECOND, -3, DATEADD(YEAR, DATEDIFF(YEAR, 0, DATEADD(YEAR, 0, GETDATE())) + 1, 0))
SET @P2From = DATEADD(YEAR,-1,@P1From)
	SET @P2To = DATEADD(YEAR,-1,@P1To)
SET @P3From = DATEADD(YEAR,-1,@P2From)
	SET @P3To = DATEADD(YEAR,-1,@P2To)
SET @P4From = DATEADD(YEAR,-2,@P2From)
	SET @P4To = DATEADD(YEAR,-2,@P2To)
SET @P5From = DATEADD(YEAR,-3,@P2From)
	SET @P5To = DATEADD(YEAR,-3,@P2To)
SET @P6From = DATEADD(YEAR,-4,@P2From)
	SET @P6To = DATEADD(YEAR,-4,@P2To)
	
set @JDATEFROM = datediff(day,'1/1/1950',convert(datetime,convert(varchar( 8), (year(@P6From) * 10000) + (month(@P6From) * 100) + day(@P6From)))  ) + 711858
set @JDATETO = datediff(day,'1/1/1950',convert(datetime,convert(varchar( 8), (year(@P1To) * 10000) + (month(@P1To) * 100) + day(@P1To)))  ) + 711858

--  select @P1From AS '1', @P1To AS '2', @P2From AS '3', @P2To AS '4', @P3From AS '5', @P3To AS '6', @P4From AS '7', @P4To AS '8', @P5From AS '9', @P5To AS '10',  @P6From AS '11', @P6To AS '12', @JDATEFROM AS '13', @JDATETO AS '14'

-- Lookup 0 & 9 affiliated Accounts
IF(OBJECT_ID('tempdb.dbo.#Aff') is not null)  
drop table #Aff 
select a.customer_code as from_cust, a.ship_to_code as shipto, a.affiliated_cust_code as to_cust
into #Aff
from armaster a (nolock) inner join
armaster b (nolock) on a.affiliated_cust_code = b.customer_code and a.ship_to_code = b.ship_to_code
where a.status_type <> 1 and a.address_type <> 9 
and a.affiliated_cust_code<> '' and a.affiliated_cust_code is not null
and b.status_type = 1 and b.address_type <> 9
--select @@rowcount
--select * from #Aff

-- Pull Customer#, Shipto#, Name, Addr, City, State, Zip, Phone, Fax, Contact
IF(OBJECT_ID('tempdb.dbo.#Cust1') is not null)
drop table dbo.#Cust1
SELECT customer_code, ship_to_code, territory_code, Address_name, addr2, addr3, addr4, City, State, Postal_code, country_code, contact_phone, tlx_twx, 
case when contact_email ='REFUSED' then '' when contact_email like '@cvoptical.com' then '' when contact_email is null then '' else contact_email end as contact_email, 
contact_name  
INTO #Cust1
FROM armaster t1 (nolock)
WHERE ADDRESS_TYPE <>9
and status_type='1'
--select * from #RankCusts_S1

--Add ReClassify for Affiliation 
IF(OBJECT_ID('tempdb.dbo.#Aff_All') is not null)
drop table dbo.#Aff_All
select X.* INTO #Aff_All FROM
( select from_cust AS CUST,'I' as Code from #Aff    UNION
select to_cust AS CUST,'A' Code from #Aff ) X
--SELECT * FROM #Aff_All 

-- Add 0/9 Statu to Customer Data
IF(OBJECT_ID('tempdb.dbo.#Cust2') is not null)
drop table dbo.#Cust2
Select ISNULL(t2.code,'A') Status, Right(customer_code, 5) as MergeCust, T1.*
INTO #Cust2
from #Cust1 t1
full outer join #Aff_All t2 on t1.customer_code=t2.cust
-- select * from #Cust1
-- select * from #Cust2

-- Dedup out 0/9 Customers
IF(OBJECT_ID('tempdb.dbo.#Cust3') is not null)
drop table dbo.#Cust3
SELECT MergeCust, ship_to_code,
MIN(isnull(Status,'')) Status,
MIN(isnull(territory_code,'')) Terr, 
MIN(isnull(Address_name,'')) Name, 
MIN(isnull(addr2,'')) Addr2, 
case when MIN(isnull(addr3,''))  like '%, __ %' then '' else MIN(isnull(addr3,''))  end as Addr3,
MIN(isnull(City,'')) City, 
MIN(isnull(State,'')) State, 
MIN(isnull(Postal_code,'')) Zip,
MIN(isnull(country_code,'')) Cntry, 
MIN(isnull(contact_phone,'')) Phone, 
MIN(isnull(tlx_twx,'')) Fax, 
MIN(isnull(contact_email,'')) Email, 
MIN(isnull(contact_name,'')) Contact
into #Cust3 from #Cust2 GROUP BY MergeCust, ship_to_code


-- PULL SALES
IF(OBJECT_ID('tempdb.dbo.#invsales') is not null)
drop table dbo.#invsales
SELECT im.category AS Coll, case when ima.category_2 like '%child%' then 'Kids' else 'Adult' END as Demographic, right(t1.customer,5)MCust, t1.*
into #invsales
 from cvo_sbm_details t1
join inv_master (nolock) im on t1.part_no=im.part_no
join inv_master_add (nolock) ima on im.part_no=ima.part_no
WHERE YYYYMMDD BETWEEN  @P6From and @P1To 
-- SELECT * FROM #invsales



IF(OBJECT_ID('tempdb.dbo.#SUBFINAL') is not null)  
drop table #SUBFINAL
SELECT T2.Terr, T2.MergeCust as Cust, t2.Ship_to_code as ShipTo, t2.Name, t2.addr2, t2.addr3, t2.city, t2.state, t2.zip, t2.cntry, t2.phone,t2.fax, t2.email, t2.contact,

ISNULL((select sum(anet) from #invsales t11 where t2.MergeCust=t11.MCust and t2.ship_to_code=t11.ship_to and t11.demographic='Kids' and t11.Coll<>'FP' and t11.Coll<>'DD' and yyyymmdd between @P1From and @P1To),0) 'Kids_CY',
ISNULL((select sum(anet) from #invsales t11 where t2.MergeCust=t11.MCust and t2.ship_to_code=t11.ship_to and t11.demographic='Kids' and (t11.Coll='FP' OR t11.Coll='DD') and yyyymmdd between @P1From and @P1To),0) 'Pediatric_CY',
ISNULL((select sum(anet) from #invsales t11 where t2.MergeCust=t11.MCust and t2.ship_to_code=t11.ship_to and t11.Coll='OP' and yyyymmdd between @P1From and @P1To),0) 'OP_CY',
ISNULL((select sum(anet) from #invsales t11 where t2.MergeCust=t11.MCust and t2.ship_to_code=t11.ship_to and t11.Coll='JC' and yyyymmdd between @P1From and @P1To),0) 'JC_CY',

ISNULL((select sum(anet) from #invsales t11 where t2.MergeCust=t11.MCust and t2.ship_to_code=t11.ship_to and t11.demographic='Kids' and t11.Coll<>'FP' and t11.Coll<>'DD' and yyyymmdd between @P2From and @P2To),0) 'Kids_LY',
ISNULL((select sum(anet) from #invsales t11 where t2.MergeCust=t11.MCust and t2.ship_to_code=t11.ship_to and t11.demographic='Kids' and (t11.Coll='FP' OR t11.Coll='DD') and yyyymmdd between @P2From and @P2To),0) 'Pediatric_LY',
ISNULL((select sum(anet) from #invsales t11 where t2.MergeCust=t11.MCust and t2.ship_to_code=t11.ship_to and t11.Coll='OP' and yyyymmdd between @P2From and @P2To),0) 'OP_LY',
ISNULL((select sum(anet) from #invsales t11 where t2.MergeCust=t11.MCust and t2.ship_to_code=t11.ship_to and t11.Coll='JC' and yyyymmdd between @P2From and @P2To),0) 'JC_LY',

ISNULL((select sum(anet) from #invsales t11 where t2.MergeCust=t11.MCust and t2.ship_to_code=t11.ship_to and t11.demographic='Kids' and t11.Coll<>'FP' and t11.Coll<>'DD' and yyyymmdd between @P3From and @P3To),0) 'Kids_LY1',
ISNULL((select sum(anet) from #invsales t11 where t2.MergeCust=t11.MCust and t2.ship_to_code=t11.ship_to and t11.demographic='Kids' and (t11.Coll='FP' OR t11.Coll='DD') and yyyymmdd between @P3From and @P3To),0) 'Pediatric_LY1',
ISNULL((select sum(anet) from #invsales t11 where t2.MergeCust=t11.MCust and t2.ship_to_code=t11.ship_to and t11.Coll='OP' and yyyymmdd between @P3From and @P3To),0) 'OP_LY1',
ISNULL((select sum(anet) from #invsales t11 where t2.MergeCust=t11.MCust and t2.ship_to_code=t11.ship_to and t11.Coll='JC' and yyyymmdd between @P3From and @P3To),0) 'JC_LY1',

ISNULL((select sum(anet) from #invsales t11 where t2.MergeCust=t11.MCust and t2.ship_to_code=t11.ship_to and t11.demographic='Kids' and t11.Coll<>'FP' and t11.Coll<>'DD' and yyyymmdd between @P4From and @P4To),0) 'Kids_LY2',
ISNULL((select sum(anet) from #invsales t11 where t2.MergeCust=t11.MCust and t2.ship_to_code=t11.ship_to and t11.demographic='Kids' and (t11.Coll='FP' OR t11.Coll='DD') and yyyymmdd between @P4From and @P4To),0) 'Pediatric_LY2',
ISNULL((select sum(anet) from #invsales t11 where t2.MergeCust=t11.MCust and t2.ship_to_code=t11.ship_to and t11.Coll='OP' and yyyymmdd between @P4From and @P4To),0) 'OP_LY2',
ISNULL((select sum(anet) from #invsales t11 where t2.MergeCust=t11.MCust and t2.ship_to_code=t11.ship_to and t11.Coll='JC' and yyyymmdd between @P4From and @P4To),0) 'JC_LY2',

ISNULL((select sum(anet) from #invsales t11 where t2.MergeCust=t11.MCust and t2.ship_to_code=t11.ship_to and t11.demographic='Kids' and t11.Coll<>'FP' and t11.Coll<>'DD' and yyyymmdd between @P5From and @P5To),0) 'Kids_LY3',
ISNULL((select sum(anet) from #invsales t11 where t2.MergeCust=t11.MCust and t2.ship_to_code=t11.ship_to and t11.demographic='Kids' and (t11.Coll='FP' OR t11.Coll='DD') and yyyymmdd between @P5From and @P5To),0) 'Pediatric_LY3',
ISNULL((select sum(anet) from #invsales t11 where t2.MergeCust=t11.MCust and t2.ship_to_code=t11.ship_to and t11.Coll='OP' and yyyymmdd between @P5From and @P5To),0) 'OP_LY3',
ISNULL((select sum(anet) from #invsales t11 where t2.MergeCust=t11.MCust and t2.ship_to_code=t11.ship_to and t11.Coll='JC' and yyyymmdd between @P5From and @P5To),0) 'JC_LY3',

ISNULL((select sum(anet) from #invsales t11 where t2.MergeCust=t11.MCust and t2.ship_to_code=t11.ship_to and t11.demographic='Kids' and t11.Coll<>'FP' and t11.Coll<>'DD' and yyyymmdd between @P6From and @P6To),0) 'Kids_LY4',
ISNULL((select sum(anet) from #invsales t11 where t2.MergeCust=t11.MCust and t2.ship_to_code=t11.ship_to and t11.demographic='Kids' and (t11.Coll='FP' OR t11.Coll='DD') and yyyymmdd between @P6From and @P6To),0) 'Pediatric_LY4',
ISNULL((select sum(anet) from #invsales t11 where t2.MergeCust=t11.MCust and t2.ship_to_code=t11.ship_to and t11.Coll='OP' and yyyymmdd between @P6From and @P6To),0) 'OP_LY4',
ISNULL((select sum(anet) from #invsales t11 where t2.MergeCust=t11.MCust and t2.ship_to_code=t11.ship_to and t11.Coll='JC' and yyyymmdd between @P6From and @P6To),0) 'JC_LY4'

INTO #SUBFINAL
FROM #invsales T1
JOIN #Cust3 T2 (nolock) ON T1.Mcust=t2.MergeCust and t1.ship_to=t2.ship_to_code
group by T2.Terr, T2.MergeCust, t2.Ship_to_code, t2.Name, t2.addr2, t2.addr3, t2.city, t2.state, t2.zip, t2.cntry, t2.phone,t2.fax, t2.email, t2.contact

--select *,
--KidsMaxYr,
--PediatricMaxYr,
--OPMaxYr,
--JCMaxYr,
--datepart(year, @P1From ) as CY,
--datepart(year, @P2From ) as LY,
--datepart(year, @P3From ) as LY1,
--datepart(year, @P4From ) as LY2,
--9999 as ALL_LY
-- from #SubFinal

SELECT Terr, Cust, ShipTo, Name, addr2, addr3, city, state, zip, cntry, phone, fax, lower(email)email, Contact, 
sum(Kids_CY)Kids_CY, sum(Pediatric_CY)Pediatric_CY, sum(OP_CY)OP_CY, sum(JC_CY)JC_CY,
sum(Kids_LY)Kids_LY, sum(Pediatric_LY)Pediatric_LY, sum(OP_LY)OP_LY, sum(JC_LY)JC_LY,
sum(Kids_LY1)Kids_LY1, sum(Pediatric_LY1)Pediatric_LY1, sum(OP_LY1)OP_LY1, sum(JC_LY1)JC_LY1,
sum(Kids_LY2)Kids_LY2, sum(Pediatric_LY2)Pediatric_LY2, sum(OP_LY2)OP_LY2, sum(JC_LY2)JC_LY2,
sum(Kids_LY3)Kids_LY3, sum(Pediatric_LY3)Pediatric_LY3, sum(OP_LY3)OP_LY3, sum(JC_LY3)JC_LY3,
sum(Kids_LY4)Kids_LY4, sum(Pediatric_LY4)Pediatric_LY4, sum(OP_LY4)OP_LY4, sum(JC_LY4)JC_LY4,

CASE 	WHEN SUM(Kids_LY4) > SUM(Kids_LY3) AND  SUM(Kids_LY4) > SUM(Kids_LY2) AND  SUM(Kids_LY4) > SUM(Kids_LY1) AND SUM(Kids_LY4) > SUM(Kids_LY) AND SUM(Kids_LY4) > SUM(Kids_CY) THEN SUM(Kids_LY4)
	WHEN SUM(Kids_LY3) > SUM(Kids_LY2) AND  SUM(Kids_LY3) > SUM(Kids_LY1) AND SUM(Kids_LY3) > SUM(Kids_LY) AND SUM(Kids_LY3) > SUM(Kids_CY) THEN SUM(Kids_LY3)
	WHEN SUM(Kids_LY2) > SUM(Kids_LY1) AND SUM(Kids_LY2) > SUM(Kids_LY) AND SUM(Kids_LY2) > SUM(Kids_CY) THEN SUM(Kids_LY2)
	WHEN SUM(Kids_LY1) > SUM(Kids_LY)  AND SUM(Kids_LY1) > SUM(Kids_CY) THEN SUM(Kids_LY1)
	WHEN SUM(Kids_LY) > SUM(Kids_CY) THEN SUM(Kids_LY)  ELSE SUM(Kids_CY) END AS 'KidsMaxYr',
	
CASE 	WHEN  SUM(Pediatric_LY4) > SUM(Pediatric_LY3) AND SUM(Pediatric_LY4) > SUM(Pediatric_LY2) AND SUM(Pediatric_LY4) > SUM(Pediatric_LY1) AND SUM(Pediatric_LY4) > SUM(Pediatric_LY) AND SUM(Pediatric_LY4) > SUM(Pediatric_CY) THEN SUM(Pediatric_LY4)
	WHEN  SUM(Pediatric_LY3) > SUM(Pediatric_LY2) AND SUM(Pediatric_LY3) > SUM(Pediatric_LY1) AND SUM(Pediatric_LY3) > SUM(Pediatric_LY) AND SUM(Pediatric_LY3) > SUM(Pediatric_CY) THEN SUM(Pediatric_LY3)
	WHEN SUM(Pediatric_LY2) > SUM(Pediatric_LY1) AND SUM(Pediatric_LY2) > SUM(Pediatric_LY) AND SUM(Pediatric_LY2) > SUM(Pediatric_CY) THEN SUM(Pediatric_LY2)
	WHEN SUM(Pediatric_LY1) > SUM(Pediatric_LY)  AND SUM(Pediatric_LY1) > SUM(Pediatric_CY) THEN SUM(Pediatric_LY1)
	WHEN SUM(Pediatric_LY) > SUM(Pediatric_CY) THEN SUM(Pediatric_LY)  ELSE SUM(Pediatric_CY) END AS 'PediatricMaxYr',
	
CASE 	WHEN SUM(OP_LY4) > SUM(OP_LY3) AND SUM(OP_LY4) > SUM(OP_LY2) AND SUM(OP_LY4) > SUM(OP_LY1) AND SUM(OP_LY4) > SUM(OP_LY) AND SUM(OP_LY4) > SUM(OP_CY) THEN SUM(OP_LY4)
	WHEN SUM(OP_LY3) > SUM(OP_LY2) AND SUM(OP_LY3) > SUM(OP_LY1) AND SUM(OP_LY3) > SUM(OP_LY) AND SUM(OP_LY3) > SUM(OP_CY) THEN SUM(OP_LY3)
	WHEN SUM(OP_LY2) > SUM(OP_LY1) AND SUM(OP_LY2) > SUM(OP_LY) AND SUM(OP_LY2) > SUM(OP_CY) THEN SUM(OP_LY2)
	WHEN SUM(OP_LY1) > SUM(OP_LY)  AND SUM(OP_LY1) > SUM(OP_CY) THEN SUM(OP_LY1)
	WHEN SUM(OP_LY) > SUM(OP_CY) THEN SUM(OP_LY)  ELSE SUM(OP_CY) END AS 'OPMaxYr',

CASE 	WHEN SUM(JC_LY4) > SUM(JC_LY3) AND SUM(JC_LY4) > SUM(JC_LY2) AND SUM(JC_LY4) > SUM(JC_LY1) AND SUM(JC_LY4) > SUM(JC_LY) AND SUM(JC_LY4) > SUM(JC_CY) THEN SUM(JC_LY4)
	WHEN SUM(JC_LY3) > SUM(JC_LY2) AND SUM(JC_LY3) > SUM(JC_LY1) AND SUM(JC_LY3) > SUM(JC_LY) AND SUM(JC_LY3) > SUM(JC_CY) THEN SUM(JC_LY3)
	WHEN SUM(JC_LY2) > SUM(JC_LY1) AND SUM(JC_LY2) > SUM(JC_LY) AND SUM(JC_LY2) > SUM(JC_CY) THEN SUM(JC_LY2)
	WHEN SUM(JC_LY1) > SUM(JC_LY)  AND SUM(JC_LY1) > SUM(JC_CY) THEN SUM(JC_LY1)
	WHEN SUM(JC_LY) > SUM(JC_CY) THEN SUM(JC_LY)  ELSE SUM(JC_CY) END AS 'JCMaxYr',

DATEPART(YEAR,@P1FROM) AS CY,
DATEPART(YEAR,@P2FROM) AS LY,
DATEPART(YEAR,@P3FROM) AS 'LY1',
DATEPART(YEAR,@P4FROM) AS 'LY2',
DATEPART(YEAR,@P5FROM) AS 'LY3',
DATEPART(YEAR,@P6FROM) AS 'LY4',
(sum(Kids_LY)+sum(Pediatric_LY)+sum(OP_LY)+sum(JC_LY))ALL_LY
-- INTO cvo_kids_report_el
FROM #SUBFINAL
GROUP BY Terr, Cust, ShipTo, Name, addr2, addr3, city, state, zip, cntry, phone, fax, email, Contact

END
GO
