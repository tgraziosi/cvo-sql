SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



-- =============================================
-- Author:		elabarbera
-- Create date: 7/1/2013
-- Description:	NEW Ranking Customer Ship To brand Sun/Frame/Net
-- EXEC RankCustShipToBrands_terr_sp '11/1/2014','11/30/2014'
-- =============================================

-- CUSTOMER RANKING CREATED BY *Elizabeth LaBarbera*  7/1/2013

CREATE Procedure [dbo].[RankCustShipToBrands_terr_sp]

@DateFrom datetime,
@DateTo datetime
, @territory varchar(1000) = null


AS
Begin
SET NOCOUNT ON

-- RUN LIVE FROM HERE
----  DECLARES
--DECLARE @DateFrom datetime                                    
--DECLARE @DateTo datetime		

------  SETS
--SET @DateFrom = '1/1/2013'
--SET @DateTo = '12/31/2013'
	SET @dateTo= dateadd(day,1,(dateadd(second,-1,@dateTo)))

create table #territory (territory varchar(10))
if @territory is null
begin
 insert into #territory (territory)
 select distinct territory_code from armaster
end
else
begin
 insert into #territory (territory)
 select listitem from dbo.f_comma_list_to_table(@territory)
end

-- Lookup 0 & 9 affiliated Accounts
IF(OBJECT_ID('tempdb.dbo.#Rank_Aff') is not null)  
drop table #Rank_Aff  
select a.customer_code as from_cust, a.ship_to_code as shipto, a.affiliated_cust_code as to_cust
into #Rank_Aff
from armaster a (nolock) inner join
armaster b (nolock) on a.affiliated_cust_code = b.customer_code and a.ship_to_code = b.ship_to_code
where a.status_type <> 1 and a.address_type <> 9 
and a.affiliated_cust_code<> '' and a.affiliated_cust_code is not null
and b.status_type = 1 and b.address_type <> 9
-- Select * from #Rank_Aff  

-- Pull Customer INFO
IF(OBJECT_ID('tempdb.dbo.#RankCusts_S1') is not null)
drop table dbo.#RankCusts_S1
SELECT CASE WHEN T2.DOOR = 1 THEN 'Y' else '' end as Door,
t1.customer_code, ship_to_code, territory_code as Terr, Address_name, addr2, case when addr3 like '%, __ %' then '' else addr3 end as addr3, case when addr4 like '%, __ %' then '' else addr4 end as addr4, City, State, Postal_code, country_code, contact_name, contact_phone, tlx_twx, case when contact_email is null then '' when contact_email like '%@cvoptical%' then '' else contact_email end as contact_email, addr_sort1 as CustType
INTO #RankCusts_S1
FROM armaster t1 (nolock)
inner join #territory t on t.territory = t1.territory_code
LEFT OUTER JOIN CVO_ARMASTER_ALL T2 ON T1.CUSTOMER_CODE = T2.CUSTOMER_CODE AND T1.SHIP_TO_CODE=T2.SHIP_TO
WHERE t1.ADDRESS_TYPE <>9
-- select * from #RankCusts_S1

-- Get Designation Codes, into one field  (Where Designations date range is in report date range
IF(OBJECT_ID('tempdb.dbo.#RankCusts_S2A') is not null)
drop table dbo.#RankCusts_S2A
      ;WITH C AS 
            ( SELECT customer_code, code FROM cvo_cust_designation_codes (nolock) )
            select Distinct customer_code,
                              STUFF ( ( SELECT '; ' + code
                              FROM cvo_cust_designation_codes (nolock)
                              WHERE customer_code = C.customer_code
                              AND (START_DATE IS NULL or START_DATE <= @DATETO)
                              AND (END_DATE IS NULL or END_DATE >=@DATETO)
                              FOR XML PATH ('') ), 1, 1, ''  ) AS NEW
      INTO #RankCusts_s2A
      FROM C

-- Get Primary for each Customer
IF(OBJECT_ID('tempdb.dbo.#Primary') is not null)
drop table dbo.#Primary
SELECT CUSTOMER_CODE, CODE, START_DATE, END_DATE INTO #Primary FROM cvo_cust_designation_codes (nolock)  WHERE PRIMARY_FLAG=1
-- select * from #Primary

-- Add Designation & Primary to Customer Data
IF(OBJECT_ID('tempdb.dbo.#RankCusts_S2B') is not null)
drop table dbo.#RankCusts_S2B
Select T1.*, ISNULL(T2.NEW, '' ) as Designations, ISNULL(t3.code, '' ) as PriDesig
INTO #RankCusts_S2B
from #RankCusts_S1 t1
left outer join #RankCusts_S2A t2 on t1.customer_code=t2.customer_code
left outer join #Primary t3 on t1.customer_code=t3.customer_code
--select * from #RankCusts_S2B

--Add ReClassify for Affiliation 
IF(OBJECT_ID('tempdb.dbo.#Rank_Aff_All') is not null)
drop table dbo.#Rank_Aff_All
select X.* INTO #Rank_Aff_All FROM
( select from_cust AS CUST,'I' as Code from #Rank_Aff     UNION
select to_cust AS CUST,'A' Code from #Rank_Aff ) X
--SELECT * FROM #Rank_Aff_All 

-- Add 0/9 Statu to Customer Data
IF(OBJECT_ID('tempdb.dbo.#RankCusts_S3a') is not null)
drop table dbo.#RankCusts_S3a
Select ISNULL(t2.code,(select case when status_type = 1 then 'A' else 'I' end from armaster (nolock) t11 where t1.customer_code=t11.customer_code and t1.ship_to_code=t11.ship_to_code) ) Status,
 Right(customer_code, 5) as MergeCust, T1.*
INTO #RankCusts_S3a
from #RankCusts_S2B t1
full outer join #Rank_Aff_All t2 on t1.customer_code=t2.cust
-- select * from #RankCusts_S3a

-- add in Parent &/or BG
IF(OBJECT_ID('tempdb.dbo.#RankCusts_S3c') is not null)
drop table dbo.#RankCusts_S3c
select t1.*, 
case when t1.customer_code=t2.parent then '' else t2.parent end as Parent 
INTO #RankCusts_S3c
from #RankCusts_S3a t1
right outer join artierrl (nolock) t2 on t1.customer_code=t2.rel_cust
where t1.customer_code is not null
-- select * from #RankCusts_S3c 

-- CLEAN OUT EXTRA DUPLICATE 0 & 9
IF(OBJECT_ID('tempdb.dbo.#RankCusts_S3') is not null)
drop table dbo.#RankCusts_S3
select MIN(ISNULL(Status,''))Status,			MergeCust, 
MIN(isnull(Door,''))Door,						MIN(isnull(customer_code,''))customer_code,		ship_to_code, 
MIN(isnull(terr,''))terr,						MIN(isnull(Address_name,''))Address_name,	MIN(isnull(addr2,''))addr2,
MIN(isnull(addr3,''))addr3,						MIN(isnull(addr4,''))addr4,	
MIN(isnull(City,''))City,						MIN(isnull(State,''))State,				MIN(isnull(Postal_code,''))Postal_code,
MIN(isnull(Country_code,''))Country,			MIN(isnull(contact_name,''))contact_name,
MIN(isnull(contact_phone,''))contact_phone,		MIN(isnull(tlx_twx,''))tlx_twx,			MIN(isnull(contact_email,''))contact_email,
MIN(isnull(Designations,''))Designations,		MIN(isnull(PriDesig,''))PriDesig,		MIN(isnull(Parent,''))Parent,	MIN(isnull(CustType,''))CustType
INTO #RankCusts_S3
FROM #RankCusts_S3c
group by MergeCust, Ship_to_code
order by MergeCust
-- select * from #RankCusts_S3

-- SOURCE SALES
IF(OBJECT_ID('tempdb.dbo.#SOURCE') is not null)
drop table dbo.#SOURCE
SELECT Right(customer,5)MergeCust, T2.*, CATEGORY, TYPE_CODE, 
CASE WHEN INV2.category_2 like '%child%' then 'Kids' else 'Adult' END as Demographic,
CASE WHEN yyyymmdd between @DateFrom and @Dateto THEN 'TY' ELSE 'LY' END AS 'TYLY'
INTO #SOURCE
FROM cvo_sbm_details (nolock) t2
JOIN INV_MASTER (NOLOCK) INV ON T2.PART_NO=INV.PART_NO
JOIN INV_MASTER_ADD (NOLOCK) INV2 ON INV.PART_NO=INV2.PART_NO
Where yyyymmdd between @DateFrom and @Dateto
-- SELECT * FROM #SOURCE where qreturns<>0

-- DATA
IF(OBJECT_ID('tempdb.dbo.#Data') is not null)
drop table dbo.#data
select  
Status, t1.MergeCust as Customer, ship_to_code as ShipTo, Terr, Door, Address_name, addr2, addr3, addr4, City, State, Postal_code, Country, contact_name, contact_phone, tlx_twx, contact_email, 
-- SALES
ISNULL(SUM(ANET),0)  NetSTY, ISNULL(SUM(ASALES),0)  SoldSTY, ISNULL(SUM(ARETURNS),0)  RetSTY,
CASE WHEN TYPE_CODE in ('FRAME','SUN') THEN ISNULL(SUM(ANET),0) ELSE 0 END AS NetS_FS,
CASE WHEN TYPE_CODE in ('FRAME','SUN') THEN ISNULL(SUM(asales),0) ELSE 0 END AS SoldS_FS,
CASE WHEN return_code ='' AND TYPE_CODE in ('FRAME','SUN') THEN ISNULL(SUM(areturns),0) ELSE 0 END AS RetS_FS,

CASE WHEN CATEGORY='BCBG' THEN ISNULL(SUM(ANET),0) ELSE 0 END AS BCBG_NET_S,
CASE WHEN CATEGORY='BCBG' AND TYPE_CODE='FRAME' THEN ISNULL(SUM(ANET),0) ELSE 0 END AS BCBG_FRAME_S,
CASE WHEN CATEGORY='BCBG' AND TYPE_CODE='SUN' THEN ISNULL(SUM(ANET),0) ELSE 0 END AS BCBG_SUN_S,
CASE WHEN CATEGORY='BCBG' AND TYPE_CODE in ('FRAME','SUN') THEN ISNULL(SUM(ASALES),0) ELSE 0 END AS BCBG_FS_SOLD_S,
CASE WHEN CATEGORY='BCBG' AND TYPE_CODE in ('FRAME','SUN') AND return_code ='' THEN ISNULL(SUM(areturns),0) ELSE 0 END AS BCBG_FS_RET_S,

CASE WHEN CATEGORY='ET' THEN ISNULL(SUM(ANET),0) ELSE 0 END AS ET_NET_S,
CASE WHEN CATEGORY='ET' AND TYPE_CODE='FRAME' THEN ISNULL(SUM(ANET),0) ELSE 0 END AS ET_FRAME_S,
CASE WHEN CATEGORY='ET' AND TYPE_CODE='SUN' THEN ISNULL(SUM(ANET),0) ELSE 0 END AS ET_SUN_S,
CASE WHEN CATEGORY='ET' AND TYPE_CODE in ('FRAME','SUN') THEN ISNULL(SUM(ASALES),0) ELSE 0 END AS ET_FS_SOLD_S,
CASE WHEN CATEGORY='ET' AND TYPE_CODE in ('FRAME','SUN') AND return_code ='' THEN ISNULL(SUM(areturns),0) ELSE 0 END AS ET_FS_RET_S,

CASE WHEN CATEGORY='CH' THEN ISNULL(SUM(ANET),0) ELSE 0 END AS CH_NET_S,
CASE WHEN CATEGORY='CH' AND TYPE_CODE='FRAME' THEN ISNULL(SUM(ANET),0) ELSE 0 END AS CH_FRAME_S,
CASE WHEN CATEGORY='CH' AND TYPE_CODE='SUN' THEN ISNULL(SUM(ANET),0) ELSE 0 END AS CH_SUN_S,
CASE WHEN CATEGORY='CH' AND TYPE_CODE in ('FRAME','SUN') THEN ISNULL(SUM(ASALES),0) ELSE 0 END AS CH_FS_SOLD_S,
CASE WHEN CATEGORY='CH' AND TYPE_CODE in ('FRAME','SUN') AND return_code ='' THEN ISNULL(SUM(areturns),0) ELSE 0 END AS CH_FS_RET_S,

CASE WHEN CATEGORY='ME' THEN ISNULL(SUM(ANET),0) ELSE 0 END AS ME_NET_S,
CASE WHEN CATEGORY='ME' AND TYPE_CODE='FRAME' THEN ISNULL(SUM(ANET),0) ELSE 0 END AS ME_FRAME_S,
CASE WHEN CATEGORY='ME' AND TYPE_CODE='SUN' THEN ISNULL(SUM(ANET),0) ELSE 0 END AS ME_SUN_S,
CASE WHEN CATEGORY='ME' AND TYPE_CODE in ('FRAME','SUN') THEN ISNULL(SUM(ASALES),0) ELSE 0 END AS ME_FS_SOLD_S,
CASE WHEN CATEGORY='ME' AND TYPE_CODE in ('FRAME','SUN') AND return_code ='' THEN ISNULL(SUM(areturns),0) ELSE 0 END AS ME_FS_RET_S,

CASE WHEN CATEGORY='IZX' THEN ISNULL(SUM(ANET),0) ELSE 0 END AS PFX_NET_S,
CASE WHEN CATEGORY='IZX' AND TYPE_CODE='FRAME' THEN ISNULL(SUM(ANET),0) ELSE 0 END AS PFX_FRAME_S,
CASE WHEN CATEGORY='IZX' AND TYPE_CODE='SUN' THEN ISNULL(SUM(ANET),0) ELSE 0 END AS PFX_SUN_S,
CASE WHEN CATEGORY='IZX' AND TYPE_CODE in ('FRAME','SUN') THEN ISNULL(SUM(ASALES),0) ELSE 0 END AS IZX_FS_SOLD_S,
CASE WHEN CATEGORY='IZX' AND TYPE_CODE in ('FRAME','SUN') AND return_code ='' THEN ISNULL(SUM(areturns),0) ELSE 0 END AS IZX_FS_RET_S,

CASE WHEN CATEGORY='IZOD' THEN ISNULL(SUM(ANET),0) ELSE 0 END AS IZOD_NET_S,
CASE WHEN CATEGORY='IZOD' AND TYPE_CODE='FRAME' THEN ISNULL(SUM(ANET),0) ELSE 0 END AS IZOD_FRAME_S,
CASE WHEN CATEGORY='IZOD' AND TYPE_CODE='SUN' THEN ISNULL(SUM(ANET),0) ELSE 0 END AS IZOD_SUN_S,
CASE WHEN CATEGORY='IZOD' AND TYPE_CODE in ('FRAME','SUN') THEN ISNULL(SUM(ASALES),0) ELSE 0 END AS IZOD_FS_SOLD_S,
CASE WHEN CATEGORY='IZOD' AND TYPE_CODE in ('FRAME','SUN') AND return_code ='' THEN ISNULL(SUM(areturns),0) ELSE 0 END AS IZOD_FS_RET_S,

CASE WHEN CATEGORY='OP' THEN ISNULL(SUM(ANET),0) ELSE 0 END AS OP_NET_S,
CASE WHEN CATEGORY='OP' AND TYPE_CODE='FRAME' THEN ISNULL(SUM(ANET),0) ELSE 0 END AS OP_FRAME_S,
CASE WHEN CATEGORY='OP' AND TYPE_CODE='SUN' THEN ISNULL(SUM(ANET),0) ELSE 0 END AS OP_SUN_S,
CASE WHEN CATEGORY='OP' AND TYPE_CODE in ('FRAME','SUN') THEN ISNULL(SUM(ASALES),0) ELSE 0 END AS OP_FS_SOLD_S,
CASE WHEN CATEGORY='OP' AND TYPE_CODE in ('FRAME','SUN') AND return_code ='' THEN ISNULL(SUM(areturns),0) ELSE 0 END AS OP_FS_RET_S,

CASE WHEN CATEGORY='JMC' THEN ISNULL(SUM(ANET),0) ELSE 0 END AS JMC_NET_S,
CASE WHEN CATEGORY='JMC' AND TYPE_CODE='FRAME' THEN ISNULL(SUM(ANET),0) ELSE 0 END AS JMC_FRAME_S,
CASE WHEN CATEGORY='JMC' AND TYPE_CODE='SUN' THEN ISNULL(SUM(ANET),0) ELSE 0 END AS JMC_SUN_S,
CASE WHEN CATEGORY='JMC' AND TYPE_CODE in ('FRAME','SUN') THEN ISNULL(SUM(ASALES),0) ELSE 0 END AS JMC_FS_SOLD_S,
CASE WHEN CATEGORY='JMC' AND TYPE_CODE in ('FRAME','SUN') AND return_code ='' THEN ISNULL(SUM(areturns),0) ELSE 0 END AS JMC_FS_RET_S,

CASE WHEN CATEGORY='CVO' THEN ISNULL(SUM(ANET),0) ELSE 0 END AS CVO_NET_S,
CASE WHEN CATEGORY='CVO' THEN ISNULL(SUM(ASALES),0) ELSE 0 END AS CVO_FS_SOLD_S,
CASE WHEN CATEGORY='CVO' AND return_code ='' THEN ISNULL(SUM(areturns),0) ELSE 0 END AS CVO_FS_RET_S,

CASE WHEN CATEGORY='JC' THEN ISNULL(SUM(ANET),0) ELSE 0 END AS JC_NET_S,
CASE WHEN CATEGORY='JC' THEN ISNULL(SUM(ASALES),0) ELSE 0 END AS JC_FS_SOLD_S,
CASE WHEN CATEGORY='JC' AND return_code ='' THEN ISNULL(SUM(areturns),0) ELSE 0 END AS JC_FS_RET_S,

CASE WHEN CATEGORY='PT' THEN ISNULL(SUM(ANET),0) ELSE 0 END AS PT_NET_S,
CASE WHEN CATEGORY='PT' THEN ISNULL(SUM(ASALES),0) ELSE 0 END AS PT_FS_SOLD_S,
CASE WHEN CATEGORY='PT' AND return_code ='' THEN ISNULL(SUM(areturns),0) ELSE 0 END AS PT_FS_RET_S,

CASE WHEN CATEGORY='UN' THEN ISNULL(SUM(ANET),0) ELSE 0 END AS UN_NET_S,
CASE WHEN CATEGORY='UN' THEN ISNULL(SUM(ASALES),0) ELSE 0 END AS UN_FS_SOLD_S,
CASE WHEN CATEGORY='UN' AND return_code ='' THEN ISNULL(SUM(areturns),0) ELSE 0 END AS UN_FS_RET_S,


CASE WHEN CATEGORY='FP' THEN ISNULL(SUM(ANET),0) ELSE 0 END AS FP_NET_S,
CASE WHEN CATEGORY='FP' THEN ISNULL(SUM(ASALES),0) ELSE 0 END AS FP_FS_SOLD_S,
CASE WHEN CATEGORY='FP' AND return_code ='' THEN ISNULL(SUM(areturns),0) ELSE 0 END AS FP_FS_RET_S,

CASE WHEN CATEGORY='KO' THEN ISNULL(SUM(ANET),0) ELSE 0 END AS KO_NET_S,
CASE WHEN CATEGORY='KO' THEN ISNULL(SUM(ASALES),0) ELSE 0 END AS KO_FS_SOLD_S,
CASE WHEN CATEGORY='KO' AND return_code ='' THEN ISNULL(SUM(areturns),0) ELSE 0 END AS KO_FS_RET_S,

CASE WHEN CATEGORY='DI' THEN ISNULL(SUM(ANET),0) ELSE 0 END AS DI_NET_S,
CASE WHEN CATEGORY='DI' THEN ISNULL(SUM(ASALES),0) ELSE 0 END AS DI_FS_SOLD_S,
CASE WHEN CATEGORY='DI' AND return_code ='' THEN ISNULL(SUM(areturns),0) ELSE 0 END AS DI_FS_RET_S,

CASE WHEN CATEGORY='DD' THEN ISNULL(SUM(ANET),0) ELSE 0 END AS DD_NET_S,
CASE WHEN CATEGORY='DD' THEN ISNULL(SUM(ASALES),0) ELSE 0 END AS DD_FS_SOLD_S,
CASE WHEN CATEGORY='DD' AND return_code ='' THEN ISNULL(SUM(areturns),0) ELSE 0 END AS DD_FS_RET_S,

CASE WHEN CATEGORY='CORP' THEN ISNULL(SUM(ANET),0) ELSE 0 END AS CORP_NET_S,

CASE WHEN demographic='Kids' and (Category='FP' OR Category='DD') THEN ISNULL(SUM(ANET),0) ELSE 0 END AS KIDS_NET_S,
CASE WHEN demographic='Kids' and (Category<>'FP' OR Category<>'DD') THEN ISNULL(SUM(ANET),0) ELSE 0 END AS PEDI_NET_S,
CASE WHEN TYPE_CODE='SUN' THEN ISNULL(SUM(ANET),0) ELSE 0 END AS SUNS_NET_S,

--Ty RX Percent
--TY Return Percent

-- UNITS
ISNULL(SUM(QNET),0) NetUTY, ISNULL(SUM(QSALES),0) SoldUTY, ISNULL(SUM(QRETURNS),0) RetUTY,
CASE WHEN TYPE_CODE in ('FRAME','SUN') THEN ISNULL(SUM(QNET),0) ELSE 0 END AS NetU_FS,
CASE WHEN TYPE_CODE in ('FRAME','SUN') THEN ISNULL(SUM(QSALES),0) ELSE 0 END AS SoldU_FS,
CASE WHEN return_code ='' AND TYPE_CODE in ('FRAME','SUN') THEN ISNULL(SUM(QRETURNS),0) ELSE 0 END AS RetU_FS,

CASE WHEN CATEGORY='BCBG' THEN ISNULL(SUM(qnet),0) ELSE 0 END AS BCBG_NET_U,
CASE WHEN CATEGORY='BCBG' AND TYPE_CODE='FRAME' THEN ISNULL(SUM(qnet),0) ELSE 0 END AS BCBG_FRAME_U,
CASE WHEN CATEGORY='BCBG' AND TYPE_CODE='SUN' THEN ISNULL(SUM(qnet),0) ELSE 0 END AS BCBG_SUN_U,
CASE WHEN CATEGORY='BCBG' AND TYPE_CODE in ('FRAME','SUN') THEN ISNULL(SUM(QSALES),0) ELSE 0 END AS BCBG_FS_SOLD_U,
CASE WHEN CATEGORY='BCBG' AND TYPE_CODE in ('FRAME','SUN') AND return_code ='' THEN ISNULL(SUM(qreturns),0) ELSE 0 END AS BCBG_FS_RET_U,

CASE WHEN CATEGORY='ET' THEN ISNULL(SUM(qnet),0) ELSE 0 END AS ET_NET_U,
CASE WHEN CATEGORY='ET' AND TYPE_CODE='FRAME' THEN ISNULL(SUM(qnet),0) ELSE 0 END AS ET_FRAME_U,
CASE WHEN CATEGORY='ET' AND TYPE_CODE='SUN' THEN ISNULL(SUM(qnet),0) ELSE 0 END AS ET_SUN_U,
CASE WHEN CATEGORY='ET' AND TYPE_CODE in ('FRAME','SUN') THEN ISNULL(SUM(QSALES),0) ELSE 0 END AS ET_FS_SOLD_U,
CASE WHEN CATEGORY='ET' AND TYPE_CODE in ('FRAME','SUN') AND return_code ='' THEN ISNULL(SUM(qreturns),0) ELSE 0 END AS ET_FS_RET_U,

CASE WHEN CATEGORY='CH' THEN ISNULL(SUM(qnet),0) ELSE 0 END AS CH_NET_U,
CASE WHEN CATEGORY='CH' AND TYPE_CODE='FRAME' THEN ISNULL(SUM(qnet),0) ELSE 0 END AS CH_FRAME_U,
CASE WHEN CATEGORY='CH' AND TYPE_CODE='SUN' THEN ISNULL(SUM(qnet),0) ELSE 0 END AS CH_SUN_U,
CASE WHEN CATEGORY='CH' AND TYPE_CODE in ('FRAME','SUN') THEN ISNULL(SUM(QSALES),0) ELSE 0 END AS CH_FS_SOLD_U,
CASE WHEN CATEGORY='CH' AND TYPE_CODE in ('FRAME','SUN') AND return_code ='' THEN ISNULL(SUM(qreturns),0) ELSE 0 END AS CH_FS_RET_U,

CASE WHEN CATEGORY='ME' THEN ISNULL(SUM(qnet),0) ELSE 0 END AS ME_NET_U,
CASE WHEN CATEGORY='ME' AND TYPE_CODE='FRAME' THEN ISNULL(SUM(qnet),0) ELSE 0 END AS ME_FRAME_U,
CASE WHEN CATEGORY='ME' AND TYPE_CODE='SUN' THEN ISNULL(SUM(qnet),0) ELSE 0 END AS ME_SUN_U,
CASE WHEN CATEGORY='ME' AND TYPE_CODE in ('FRAME','SUN') THEN ISNULL(SUM(QSALES),0) ELSE 0 END AS ME_FS_SOLD_U,
CASE WHEN CATEGORY='ME' AND TYPE_CODE in ('FRAME','SUN') AND return_code ='' THEN ISNULL(SUM(qreturns),0) ELSE 0 END AS ME_FS_RET_U,

CASE WHEN CATEGORY='IZX' THEN ISNULL(SUM(qnet),0) ELSE 0 END AS PFX_NET_U,
CASE WHEN CATEGORY='IZX' AND TYPE_CODE='FRAME' THEN ISNULL(SUM(qnet),0) ELSE 0 END AS PFX_FRAME_U,
CASE WHEN CATEGORY='IZX' AND TYPE_CODE='SUN' THEN ISNULL(SUM(qnet),0) ELSE 0 END AS PFX_SUN_U,
CASE WHEN CATEGORY='IZX' AND TYPE_CODE in ('FRAME','SUN') THEN ISNULL(SUM(QSALES),0) ELSE 0 END AS IZX_FS_SOLD_U,
CASE WHEN CATEGORY='IZX' AND TYPE_CODE in ('FRAME','SUN') AND return_code ='' THEN ISNULL(SUM(qreturns),0) ELSE 0 END AS IZX_FS_RET_U,

CASE WHEN CATEGORY='IZOD' THEN ISNULL(SUM(qnet),0) ELSE 0 END AS IZOD_NET_U,
CASE WHEN CATEGORY='IZOD' AND TYPE_CODE='FRAME' THEN ISNULL(SUM(qnet),0) ELSE 0 END AS IZOD_FRAME_U,
CASE WHEN CATEGORY='IZOD' AND TYPE_CODE='SUN' THEN ISNULL(SUM(qnet),0) ELSE 0 END AS IZOD_SUN_U,
CASE WHEN CATEGORY='IZOD' AND TYPE_CODE in ('FRAME','SUN') THEN ISNULL(SUM(QSALES),0) ELSE 0 END AS IZOD_FS_SOLD_U,
CASE WHEN CATEGORY='IZOD' AND TYPE_CODE in ('FRAME','SUN') AND return_code ='' THEN ISNULL(SUM(qreturns),0) ELSE 0 END AS IZOD_FS_RET_U,

CASE WHEN CATEGORY='OP' THEN ISNULL(SUM(qnet),0) ELSE 0 END AS OP_NET_U,
CASE WHEN CATEGORY='OP' AND TYPE_CODE='FRAME' THEN ISNULL(SUM(qnet),0) ELSE 0 END AS OP_FRAME_U,
CASE WHEN CATEGORY='OP' AND TYPE_CODE='SUN' THEN ISNULL(SUM(qnet),0) ELSE 0 END AS OP_SUN_U,
CASE WHEN CATEGORY='op' AND TYPE_CODE in ('FRAME','SUN') THEN ISNULL(SUM(QSALES),0) ELSE 0 END AS op_FS_SOLD_U,
CASE WHEN CATEGORY='op' AND TYPE_CODE in ('FRAME','SUN') AND return_code ='' THEN ISNULL(SUM(qreturns),0) ELSE 0 END AS op_FS_RET_U,

CASE WHEN CATEGORY='JMC' THEN ISNULL(SUM(qnet),0) ELSE 0 END AS JMC_NET_U,
CASE WHEN CATEGORY='JMC' AND TYPE_CODE='FRAME' THEN ISNULL(SUM(qnet),0) ELSE 0 END AS JMC_FRAME_U,
CASE WHEN CATEGORY='JMC' AND TYPE_CODE='SUN' THEN ISNULL(SUM(qnet),0) ELSE 0 END AS JMC_SUN_U,
CASE WHEN CATEGORY='jmc' AND TYPE_CODE in ('FRAME','SUN') THEN ISNULL(SUM(QSALES),0) ELSE 0 END AS jmc_FS_SOLD_U,
CASE WHEN CATEGORY='jmc' AND TYPE_CODE in ('FRAME','SUN') AND return_code ='' THEN ISNULL(SUM(qreturns),0) ELSE 0 END AS jmc_FS_RET_U,

CASE WHEN CATEGORY='CVO' THEN ISNULL(SUM(qnet),0) ELSE 0 END AS CVO_NET_U,
CASE WHEN CATEGORY='CVO' THEN ISNULL(SUM(qSALES),0) ELSE 0 END AS CVO_FS_SOLD_U,
CASE WHEN CATEGORY='CVO' AND return_code ='' THEN ISNULL(SUM(qreturns),0) ELSE 0 END AS CVO_FS_RET_U,

CASE WHEN CATEGORY='JC' THEN ISNULL(SUM(qnet),0) ELSE 0 END AS JC_NET_U,
CASE WHEN CATEGORY='JC' THEN ISNULL(SUM(qSALES),0) ELSE 0 END AS JC_FS_SOLD_U,
CASE WHEN CATEGORY='JC' AND return_code ='' THEN ISNULL(SUM(qreturns),0) ELSE 0 END AS JC_FS_RET_U,

CASE WHEN CATEGORY='PT' THEN ISNULL(SUM(qnet),0) ELSE 0 END AS PT_NET_U,
CASE WHEN CATEGORY='pt' THEN ISNULL(SUM(qSALES),0) ELSE 0 END AS pt_FS_SOLD_U,
CASE WHEN CATEGORY='pt' AND return_code ='' THEN ISNULL(SUM(qreturns),0) ELSE 0 END AS pt_FS_RET_U,

CASE WHEN CATEGORY='UN' THEN ISNULL(SUM(qnet),0) ELSE 0 END AS UN_NET_U,
CASE WHEN CATEGORY='UN' THEN ISNULL(SUM(qSALES),0) ELSE 0 END AS UN_FS_SOLD_U,
CASE WHEN CATEGORY='UN' AND return_code ='' THEN ISNULL(SUM(qreturns),0) ELSE 0 END AS UN_FS_RET_U,

CASE WHEN CATEGORY='FP' THEN ISNULL(SUM(qnet),0) ELSE 0 END AS FP_NET_U,
CASE WHEN CATEGORY='FP' THEN ISNULL(SUM(qSALES),0) ELSE 0 END AS FP_FS_SOLD_U,
CASE WHEN CATEGORY='FP' AND return_code ='' THEN ISNULL(SUM(qreturns),0) ELSE 0 END AS FP_FS_RET_U,

CASE WHEN CATEGORY='KO' THEN ISNULL(SUM(qnet),0) ELSE 0 END AS KO_NET_U,
CASE WHEN CATEGORY='KO' THEN ISNULL(SUM(qSALES),0) ELSE 0 END AS KO_FS_SOLD_U,
CASE WHEN CATEGORY='KO' AND return_code ='' THEN ISNULL(SUM(qreturns),0) ELSE 0 END AS KO_FS_RET_U,

CASE WHEN CATEGORY='DI' THEN ISNULL(SUM(qnet),0) ELSE 0 END AS DI_NET_U,
CASE WHEN CATEGORY='DI' THEN ISNULL(SUM(qSALES),0) ELSE 0 END AS DI_FS_SOLD_U,
CASE WHEN CATEGORY='DI' AND return_code ='' THEN ISNULL(SUM(qreturns),0) ELSE 0 END AS DI_FS_RET_U,

CASE WHEN CATEGORY='DD' THEN ISNULL(SUM(qnet),0) ELSE 0 END AS DD_NET_U,
CASE WHEN CATEGORY='DD' THEN ISNULL(SUM(qSALES),0) ELSE 0 END AS DD_FS_SOLD_U,
CASE WHEN CATEGORY='DD' AND return_code ='' THEN ISNULL(SUM(qreturns),0) ELSE 0 END AS DD_FS_RET_U,

CASE WHEN CATEGORY='CORP' THEN ISNULL(SUM(qnet),0) ELSE 0 END AS CORP_NET_U,

CASE WHEN demographic='Kids' and (Category='FP' OR Category='DD') THEN ISNULL(SUM(qnet),0) ELSE 0 END AS KIDS_NET_U,
CASE WHEN demographic='Kids' and (Category<>'FP' OR Category<>'DD') THEN ISNULL(SUM(qnet),0) ELSE 0 END AS PEDI_NET_U,
CASE WHEN TYPE_CODE='SUN' THEN ISNULL(SUM(qnet),0) ELSE 0 END AS SUNS_NET_U,
--
ISNULL(Designations, '' )ActiveDesignation, ISNULL(PriDesig, '' ) CurrentPrimary, ISNULL(Parent, '' )PARENT, ISNULL(CustType, '' )CustType
INTO #DATA
FROM #RankCusts_S3 t1
left outer join #Source t2 on t1.MergeCust=t2.MergeCust and t1.ship_to_code=t2.ship_to
GROUP BY Status, t1.MergeCust, ship_to_code, Terr, Door, Address_name, addr2, addr3, addr4, City, State, Postal_code, Country, contact_name, contact_phone, tlx_twx, contact_email, Designations, PriDesig, Parent, CustType, TYLY, user_category, promo_id, return_code, category, type_code, DEMOGRAPHIC

-- select * from #Data
-- FINAL SELECT
SELECT Status, Customer, ShipTo, Terr, Door, Address_name, addr2, addr3, addr4, City, State, Postal_code, Country, contact_name, contact_phone, tlx_twx, contact_email, 
-- SALES
SUM(NetSTY)NetSTY, 
SUM(SoldSTY)SoldSTY, 
SUM(RetSTY)RetSTY, 
SUM(NetS_FS)NetS_FS, 
SUM(SoldS_FS)SoldS_FS, 
SUM(RetS_FS)RetS_FS, 
SUM(BCBG_NET_S)BCBG_NET_S, 
SUM(BCBG_FRAME_S)BCBG_FRAME_S, 
SUM(BCBG_SUN_S)BCBG_SUN_S, 
SUM(BCBG_FS_SOLD_S)BCBG_FS_SOLD_S, 
SUM(BCBG_FS_RET_S)BCBG_FS_RET_S, 
SUM(ET_NET_S)ET_NET_S, 
SUM(ET_FRAME_S)ET_FRAME_S, 
SUM(ET_SUN_S)ET_SUN_S, 
SUM(ET_FS_SOLD_S)ET_FS_SOLD_S, 
SUM(ET_FS_RET_S)ET_FS_RET_S, 
SUM(CH_NET_S)CH_NET_S, 
SUM(CH_FRAME_S)CH_FRAME_S, 
SUM(CH_SUN_S)CH_SUN_S, 
SUM(CH_FS_SOLD_S)CH_FS_SOLD_S, 
SUM(CH_FS_RET_S)CH_FS_RET_S, 
SUM(ME_NET_S)ME_NET_S, 
SUM(ME_FRAME_S)ME_FRAME_S, 
SUM(ME_SUN_S)ME_SUN_S, 
SUM(ME_FS_SOLD_S)ME_FS_SOLD_S, 
SUM(ME_FS_RET_S)ME_FS_RET_S, 
SUM(PFX_NET_S)PFX_NET_S, 
SUM(PFX_FRAME_S)PFX_FRAME_S, 
SUM(PFX_SUN_S)PFX_SUN_S, 
SUM(IZX_FS_SOLD_S)IZX_FS_SOLD_S, 
SUM(IZX_FS_RET_S)IZX_FS_RET_S, 
SUM(IZOD_NET_S)IZOD_NET_S, 
SUM(IZOD_FRAME_S)IZOD_FRAME_S, 
SUM(IZOD_SUN_S)IZOD_SUN_S, 
SUM(IZOD_FS_SOLD_S)IZOD_FS_SOLD_S, 
SUM(IZOD_FS_RET_S)IZOD_FS_RET_S, 
SUM(OP_NET_S)OP_NET_S, 
SUM(OP_FRAME_S)OP_FRAME_S, 
SUM(OP_SUN_S)OP_SUN_S, 
SUM(OP_FS_SOLD_S)OP_FS_SOLD_S, 
SUM(OP_FS_RET_S)OP_FS_RET_S, 
SUM(JMC_NET_S)JMC_NET_S, 
SUM(JMC_FRAME_S)JMC_FRAME_S, 
SUM(JMC_SUN_S)JMC_SUN_S, 
SUM(JMC_FS_SOLD_S)JMC_FS_SOLD_S, 
SUM(JMC_FS_RET_S)JMC_FS_RET_S, 
SUM(CVO_NET_S)CVO_NET_S, 
SUM(CVO_FS_SOLD_S)CVO_FS_SOLD_S, 
SUM(CVO_FS_RET_S)CVO_FS_RET_S, 
SUM(JC_NET_S)JC_NET_S, 
SUM(JC_FS_SOLD_S)JC_FS_SOLD_S, 
SUM(JC_FS_RET_S)JC_FS_RET_S, 
SUM(PT_NET_S)PT_NET_S, 
SUM(PT_FS_SOLD_S)PT_FS_SOLD_S, 
SUM(PT_FS_RET_S)PT_FS_RET_S, 
SUM(UN_NET_S)UN_NET_S, 
SUM(UN_FS_SOLD_S)UN_FS_SOLD_S, 
SUM(UN_FS_RET_S)UN_FS_RET_S, 
SUM(FP_NET_S)FP_NET_S, 
SUM(FP_FS_SOLD_S)FP_FS_SOLD_S, 
SUM(FP_FS_RET_S)FP_FS_RET_S, 
SUM(KO_NET_S)KO_NET_S, 
SUM(KO_FS_SOLD_S)KO_FS_SOLD_S, 
SUM(KO_FS_RET_S)KO_FS_RET_S, 
SUM(DI_NET_S)DI_NET_S, 
SUM(DI_FS_SOLD_S)DI_FS_SOLD_S, 
SUM(DI_FS_RET_S)DI_FS_RET_S, 
SUM(DD_NET_S)DD_NET_S, 
SUM(DD_FS_SOLD_S)DD_FS_SOLD_S, 
SUM(DD_FS_RET_S)DD_FS_RET_S, 
SUM(CORP_NET_S)CORP_NET_S, 
SUM(KIDS_NET_S)KIDS_NET_S, 
SUM(PEDI_NET_S)PEDI_NET_S, 
SUM(SUNS_NET_S)SUNS_NET_S, 

-- UNITS
SUM(NetUTY)NetUTY, 
SUM(SoldUTY)SoldUTY, 
SUM(RetUTY)RetUTY, 
SUM(NetU_FS)NetU_FS, 
SUM(SoldU_FS)SoldU_FS, 
SUM(RetU_FS)RetU_FS, 
SUM(BCBG_NET_U)BCBG_NET_U, 
SUM(BCBG_FRAME_U)BCBG_FRAME_U, 
SUM(BCBG_SUN_U)BCBG_SUN_U, 
SUM(BCBG_FS_SOLD_U)BCBG_FS_SOLD_U, 
SUM(BCBG_FS_RET_U)BCBG_FS_RET_U, 
SUM(ET_NET_U)ET_NET_U, 
SUM(ET_FRAME_U)ET_FRAME_U, 
SUM(ET_SUN_U)ET_SUN_U, 
SUM(ET_FS_SOLD_U)ET_FS_SOLD_U, 
SUM(ET_FS_RET_U)ET_FS_RET_U, 
SUM(CH_NET_U)CH_NET_U, 
SUM(CH_FRAME_U)CH_FRAME_U, 
SUM(CH_SUN_U)CH_SUN_U, 
SUM(CH_FS_SOLD_U)CH_FS_SOLD_U, 
SUM(CH_FS_RET_U)CH_FS_RET_U, 
SUM(ME_NET_U)ME_NET_U, 
SUM(ME_FRAME_U)ME_FRAME_U, 
SUM(ME_SUN_U)ME_SUN_U, 
SUM(ME_FS_SOLD_U)ME_FS_SOLD_U, 
SUM(ME_FS_RET_U)ME_FS_RET_U, 
SUM(PFX_NET_U)PFX_NET_U, 
SUM(PFX_FRAME_U)PFX_FRAME_U, 
SUM(PFX_SUN_U)PFX_SUN_U, 
SUM(IZX_FS_SOLD_U)IZX_FS_SOLD_U, 
SUM(IZX_FS_RET_U)IZX_FS_RET_U, 
SUM(IZOD_NET_U)IZOD_NET_U, 
SUM(IZOD_FRAME_U)IZOD_FRAME_U, 
SUM(IZOD_SUN_U)IZOD_SUN_U, 
SUM(IZOD_FS_SOLD_U)IZOD_FS_SOLD_U, 
SUM(IZOD_FS_RET_U)IZOD_FS_RET_U, 
SUM(OP_NET_U)OP_NET_U, 
SUM(OP_FRAME_U)OP_FRAME_U, 
SUM(OP_SUN_U)OP_SUN_U, 
SUM(op_FS_SOLD_U)op_FS_SOLD_U, 
SUM(op_FS_RET_U)op_FS_RET_U, 
SUM(JMC_NET_U)JMC_NET_U, 
SUM(JMC_FRAME_U)JMC_FRAME_U, 
SUM(JMC_SUN_U)JMC_SUN_U, 
SUM(jmc_FS_SOLD_U)jmc_FS_SOLD_U, 
SUM(jmc_FS_RET_U)jmc_FS_RET_U, 
SUM(CVO_NET_U)CVO_NET_U, 
SUM(CVO_FS_SOLD_U)CVO_FS_SOLD_U, 
SUM(CVO_FS_RET_U)CVO_FS_RET_U, 
SUM(JC_NET_U)JC_NET_U, 
SUM(JC_FS_SOLD_U)JC_FS_SOLD_U, 
SUM(JC_FS_RET_U)JC_FS_RET_U, 
SUM(PT_NET_U)PT_NET_U, 
SUM(pt_FS_SOLD_U)pt_FS_SOLD_U, 
SUM(pt_FS_RET_U)pt_FS_RET_U, 
SUM(UN_NET_U)UN_NET_U, 
SUM(UN_FS_SOLD_U)UN_FS_SOLD_U, 
SUM(UN_FS_RET_U)UN_FS_RET_U, 
SUM(FP_NET_U)FP_NET_U, 
SUM(FP_FS_SOLD_U)FP_FS_SOLD_U, 
SUM(FP_FS_RET_U)FP_FS_RET_U, 
SUM(KO_NET_U)KO_NET_U, 
SUM(KO_FS_SOLD_U)KO_FS_SOLD_U, 
SUM(KO_FS_RET_U)KO_FS_RET_U, 
SUM(DI_NET_U)DI_NET_U, 
SUM(DI_FS_SOLD_U)DI_FS_SOLD_U, 
SUM(DI_FS_RET_U)DI_FS_RET_U, 
SUM(DD_NET_U)DD_NET_U, 
SUM(DD_FS_SOLD_U)DD_FS_SOLD_U, 
SUM(DD_FS_RET_U)DD_FS_RET_U, 
SUM(CORP_NET_U)CORP_NET_U, 
SUM(KIDS_NET_U)KIDS_NET_U, 
SUM(PEDI_NET_U)PEDI_NET_U, 
SUM(SUNS_NET_U)SUNS_NET_U,
--ISNULL((select sum(asales) from cvo_sbm_details t11 where t1.customer=right(t11.customer,5) and yyyymmdd between DATEADD(YEAR,-1,DATEADD(Day, 0, DATEDIFF(Day, 0, GetDate()))) and DATEADD(Day, -1, DATEDIFF(Day, 0, GetDate())) and promo_id <> 'BEP'),0) GrossSNoBep_R12,
--(-1*ISNULL((select sum(areturns) from cvo_sbm_details t11 where t1.customer=right(t11.customer,5) and yyyymmdd between DATEADD(YEAR,-1,DATEADD(Day, 0, DATEDIFF(Day, 0, GetDate()))) and DATEADD(Day, -1, DATEDIFF(Day, 0, GetDate())) and return_code <> 'EXC'),0)) RetSRa_R12,

--ISNULL((select sum(Qsales) from cvo_sbm_details t11 where t1.customer=right(t11.customer,5) and yyyymmdd between DATEADD(YEAR,-1,DATEADD(Day, 0, DATEDIFF(Day, 0, GetDate()))) and DATEADD(Day, -1, DATEDIFF(Day, 0, GetDate())) and promo_id <> 'BEP'),0) GrossUNoBep_R12,
--(-1*ISNULL((select sum(Qreturns) from cvo_sbm_details t11 where t1.customer=right(t11.customer,5) and yyyymmdd between DATEADD(YEAR,-1,DATEADD(Day, 0, DATEDIFF(Day, 0, GetDate()))) and DATEADD(Day, -1, DATEDIFF(Day, 0, GetDate())) and return_code <> 'EXC'),0)) RetURa_R12,

ActiveDesignation, CurrentPrimary, Parent, CustType
--INTO RankCustShipToBrands_EL
FROM #DATA T1
GROUP BY status, customer, SHIPTO, Terr, Door, address_name, addr2, addr3, addr4, city, state, postal_code, country, contact_name, contact_phone, tlx_twx, contact_email, ActiveDesignation, CurrentPrimary, Parent, CustType
ORDER BY Terr, SUM(NetSTY) DESC

-- EXEC RankCustShipToBrands_sp '6/1/2013','5/31/2014'

END

GO
GRANT EXECUTE ON  [dbo].[RankCustShipToBrands_terr_sp] TO [public]
GO
