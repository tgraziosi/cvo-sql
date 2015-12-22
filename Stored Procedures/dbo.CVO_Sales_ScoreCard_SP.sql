SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


-- =============================================
-- Author:		Elizabeth LaBarbera
-- Create date: 12/4/2013
-- Description:	Sales Territory/Salesperson ScoreCard (also for NSM  AWARDS)
-- EXEC CVO_Sales_ScoreCard_SP '1/1/2014', '12/30/2014'
-- 101314 -- tag --  add and remove two territories for 2014
-- =============================================
CREATE PROCEDURE [dbo].[CVO_Sales_ScoreCard_SP]

@DateFrom datetime,
@DateTo datetime

AS
BEGIN
	SET NOCOUNT ON;

--Declare @DateFrom datetime
--Declare @DateTo datetime
--Set @DateFrom = '11/1/2013'
--Set @DateTo = '10/31/2014'
	Set @DateTo = DateAdd(Second, -1, DateAdd(D,1,@DateTo))
--  select @DateFrom, @DateTo, (dateadd(day,-1,dateadd(year,1,@DateFrom))), dateadd(year,-1,@DateFrom) , dateadd(day,-1,@DateFrom)

declare @minBrandSales decimal(20,8)
select @minBrandSales = 750

-- PULL ALL Territories
IF(OBJECT_ID('tempdb.dbo.#Terrs') is not null)  drop table dbo.#Terrs
select distinct 
Case when Territory_code like '906%' then '600' 
	when Territory_code like '909%' then '900'
	when Territory_code like '80%' then '800'
	else left(Territory_code,1) * 100 end as Region
,Territory_code as Terr
INTO #TERRS from ARmaster (NOLOCK) WHERE Territory_code not like '%00' order by Territory_code
-- select * from #Terrs

-- BUILD REP DATA
IF(OBJECT_ID('tempdb.dbo.#Slp') is not null)  drop table dbo.#Slp
SELECT dbo.calculate_Region_fn(Territory_code)Region,Territory_code as Terr, Salesperson_name as Salesperson, ISNULL(date_of_hire,'1/1/1950')date_of_hire, 
CASE WHEN date_of_hire between @DateFrom and dateadd(day,-1,dateadd(year,1,@DateFrom)) 	THEN datepart(year,dateadd(day,-1,dateadd(year,1,@DateFrom)))
	WHEN date_of_hire between dateadd(year,-1,@DateFrom) and dateadd(day,-1,@DateFrom) 	THEN datepart(year,dateadd(day,-1,@DateFrom))
	ELSE ISNULL(DATEPART(YEAR,DATE_OF_HIRE),datepart(year,dateadd(day,-1,@DateFrom))) END AS ClassOf, 
CASE WHEN date_of_hire between @DateFrom and (dateadd(day,-1,dateadd(year,1,@DateFrom))) THEN 'Newbie'
	WHEN date_of_hire between dateadd(year,-1,@DateFrom) and dateadd(day,-1,@DateFrom) THEN 'Rookie'
	WHEN Salesperson_name like '%DEFAULT%' or Salesperson_name like '%COMPANY%' THEN 'Empty' 
	WHEN date_of_hire > @DateFrom  THEN 'Newbie'
	ELSE 'VETERAN' end as Status
INTO #Slp
FROM arsalesp Where Status_type = 1 and Territory_code not like '%00' and Salesperson_name <> 'Marcella Smith' and  salesperson_name <> 'Alanna Martin' order by Territory_code
--  select * from #Slp

IF(OBJECT_ID('tempdb.dbo.#SlpInfo') is not null)  drop table dbo.#SlpInfo
select t1.Region, t1.Terr, 
ISNULL((select Top 1 Salesperson from #SLP t2 where t1.terr=t2.terr),(Terr+' DEFAULT')) as Salesperson,
ISNULL((select Top 1 date_of_hire from #SLP t2 where t1.terr=t2.terr),'1/1/1950') as date_of_hire,
ISNULL((select Top 1 ClassOf from #SLP t2 where t1.terr=t2.terr),'1950') as ClassOf,
ISNULL((select Top 1 Status from #SLP t2 where t1.terr=t2.terr),'Empty') as Status
INTO #SlpInfo from #Terrs t1
Where T1.Region is not null
-- select * from #SLPInfo

-- BUILD BRANDS SUB REPORT
IF(OBJECT_ID('tempdb.dbo.#BrandsData') is not null)  drop table dbo.#BrandsData
CREATE TABLE dbo.#BrandsData (
[Status] [varchar](1) NULL
,[Customer] [varchar](5) NULL
,[ShipTo] [varchar](8) NULL
,[Terr] [varchar](8) NULL
,[Door] [varchar](1) NULL
,[Address_name] [varchar](40) NULL
,[addr2] [varchar](40) NULL
,[addr3] [varchar](40) NULL
,[addr4] [varchar](40) NULL
,[City] [varchar](40) NULL
,[State] [varchar](40) NULL
,[Postal_code] [varchar](15) NULL
,[Country] [varchar](3) NULL
,[contact_name] [varchar](40) NULL
,[contact_phone] [varchar](30) NULL
,[tlx_twx] [varchar](30) NULL
,[contact_email] [varchar](255) NULL
,[NetSTY] [float] NULL
,[SoldSTY] [float] NULL
,[RetSTY] [float] NULL
,[NetS_FS] [float] NULL
,[SoldS_FS] [float] NULL
,[RetS_FS] [float] NULL
,[BCBG_NET_S] [float] NULL
,[BCBG_FRAME_S] [float] NULL
,[BCBG_SUN_S] [float] NULL
,[BCBG_FS_SOLD_S] [float] NULL
,[BCBG_FS_RET_S] [float] NULL
,[ET_NET_S] [float] NULL
,[ET_FRAME_S] [float] NULL
,[ET_SUN_S] [float] NULL
,[ET_FS_SOLD_S] [float] NULL
,[ET_FS_RET_S] [float] NULL
,[CH_NET_S] [float] NULL
,[CH_FRAME_S] [float] NULL
,[CH_SUN_S] [float] NULL
,[CH_FS_SOLD_S] [float] NULL
,[CH_FS_RET_S] [float] NULL
,[ME_NET_S] [float] NULL
,[ME_FRAME_S] [float] NULL
,[ME_SUN_S] [float] NULL
,[ME_FS_SOLD_S] [float] NULL
,[ME_FS_RET_S] [float] NULL
,[PFX_NET_S] [float] NULL
,[PFX_FRAME_S] [float] NULL
,[PFX_SUN_S] [float] NULL
,[IZX_FS_SOLD_S] [float] NULL
,[IZX_FS_RET_S] [float] NULL
,[IZOD_NET_S] [float] NULL
,[IZOD_FRAME_S] [float] NULL
,[IZOD_SUN_S] [float] NULL
,[IZOD_FS_SOLD_S] [float] NULL
,[IZOD_FS_RET_S] [float] NULL
,[OP_NET_S] [float] NULL
,[OP_FRAME_S] [float] NULL
,[OP_SUN_S] [float] NULL
,[OP_FS_SOLD_S] [float] NULL
,[OP_FS_RET_S] [float] NULL
,[JMC_NET_S] [float] NULL
,[JMC_FRAME_S] [float] NULL
,[JMC_SUN_S] [float] NULL
,[JMC_FS_SOLD_S] [float] NULL
,[JMC_FS_RET_S] [float] NULL
,[CVO_NET_S] [float] NULL
,[CVO_FS_SOLD_S] [float] NULL
,[CVO_FS_RET_S] [float] NULL
,[JC_NET_S] [float] NULL
,[JC_FS_SOLD_S] [float] NULL
,[JC_FS_RET_S] [float] NULL
,[PT_NET_S] [float] NULL
,[PT_FS_SOLD_S] [float] NULL
,[PT_FS_RET_S] [float] NULL
,[UN_NET_S] [float] NULL
,[UN_FS_SOLD_S] [float] NULL
,[UN_FS_RET_S] [float] NULL
,[FP_NET_S] [float] NULL
,[FP_FS_SOLD_S] [float] NULL
,[FP_FS_RET_S] [float] NULL
,[KO_NET_S] [float] NULL
,[KO_FS_SOLD_S] [float] NULL
,[KO_FS_RET_S] [float] NULL
,[DI_NET_S] [float] NULL
,[DI_FS_SOLD_S] [float] NULL
,[DI_FS_RET_S] [float] NULL
,[DD_NET_S] [float] NULL
,[DD_FS_SOLD_S] [float] NULL
,[DD_FS_RET_S] [float] NULL
,[CORP_NET_S] [float] NULL
,[KIDS_NET_S] [float] NULL
,[PEDI_NET_S] [float] NULL
,[SUNS_NET_S] [float] NULL
,[NetUTY] [float] NULL
,[SoldUTY] [float] NULL
,[RetUTY] [float] NULL
,[NetU_FS] [float] NULL
,[SoldU_FS] [float] NULL
,[RetU_FS] [float] NULL
,[BCBG_NET_U] [float] NULL
,[BCBG_FRAME_U] [float] NULL
,[BCBG_SUN_U] [float] NULL
,[BCBG_FS_SOLD_U] [float] NULL
,[BCBG_FS_RET_U] [float] NULL
,[ET_NET_U] [float] NULL
,[ET_FRAME_U] [float] NULL
,[ET_SUN_U] [float] NULL
,[ET_FS_SOLD_U] [float] NULL
,[ET_FS_RET_U] [float] NULL
,[CH_NET_U] [float] NULL
,[CH_FRAME_U] [float] NULL
,[CH_SUN_U] [float] NULL
,[CH_FS_SOLD_U] [float] NULL
,[CH_FS_RET_U] [float] NULL
,[ME_NET_U] [float] NULL
,[ME_FRAME_U] [float] NULL
,[ME_SUN_U] [float] NULL
,[ME_FS_SOLD_U] [float] NULL
,[ME_FS_RET_U] [float] NULL
,[PFX_NET_U] [float] NULL
,[PFX_FRAME_U] [float] NULL
,[PFX_SUN_U] [float] NULL
,[IZX_FS_SOLD_U] [float] NULL
,[IZX_FS_RET_U] [float] NULL
,[IZOD_NET_U] [float] NULL
,[IZOD_FRAME_U] [float] NULL
,[IZOD_SUN_U] [float] NULL
,[IZOD_FS_SOLD_U] [float] NULL
,[IZOD_FS_RET_U] [float] NULL
,[OP_NET_U] [float] NULL
,[OP_FRAME_U] [float] NULL
,[OP_SUN_U] [float] NULL
,[op_FS_SOLD_U] [float] NULL
,[op_FS_RET_U] [float] NULL
,[JMC_NET_U] [float] NULL
,[JMC_FRAME_U] [float] NULL
,[JMC_SUN_U] [float] NULL
,[jmc_FS_SOLD_U] [float] NULL
,[jmc_FS_RET_U] [float] NULL
,[CVO_NET_U] [float] NULL
,[CVO_FS_SOLD_U] [float] NULL
,[CVO_FS_RET_U] [float] NULL
,[JC_NET_U] [float] NULL
,[JC_FS_SOLD_U] [float] NULL
,[JC_FS_RET_U] [float] NULL
,[PT_NET_U] [float] NULL
,[pt_FS_SOLD_U] [float] NULL
,[pt_FS_RET_U] [float] NULL
,[UN_NET_U] [float] NULL
,[UN_FS_SOLD_U] [float] NULL
,[UN_FS_RET_U] [float] NULL
,[FP_NET_U] [float] NULL
,[FP_FS_SOLD_U] [float] NULL
,[FP_FS_RET_U] [float] NULL
,[KO_NET_U] [float] NULL
,[KO_FS_SOLD_U] [float] NULL
,[KO_FS_RET_U] [float] NULL
,[DI_NET_U] [float] NULL
,[DI_FS_SOLD_U] [float] NULL
,[DI_FS_RET_U] [float] NULL
,[DD_NET_U] [float] NULL
,[DD_FS_SOLD_U] [float] NULL
,[DD_FS_RET_U] [float] NULL
,[CORP_NET_U] [float] NULL
,[KIDS_NET_U] [float] NULL
,[PEDI_NET_U] [float] NULL
,[SUNS_NET_U] [float] NULL
,[ActiveDesignation] [nvarchar](max) NOT NULL
,[CurrentPrimary] [varchar](10) NOT NULL
,[Parent] [varchar](8) NOT NULL
,[CustType] [varchar](40) NOT NULL
)
INSERT INTO #BrandsData  EXEC RankCustShipToBrands_sp @DateFrom,@DateTo
--  Select * from #BrandsData
/*
 Select Status, Customer, ShipTo, Door, Address_name, 
BCBG_NET_S, ET_NET_S, CH_NET_S, ME_NET_S, PFX_NET_S, IZOD_NET_S, OP_NET_S, JMC_NET_S, CVO_NET_S, JC_NET_S, PT_NET_S, UN_NET_S, FP_NET_S, KO_NET_S, DI_NET_S, DD_NET_S
from #BrandsData where Customer in (select distinct customer from #BrandsData where Door = 'Y' and shipTo <>'')
order by Customer, Shipto
*/

IF(OBJECT_ID('tempdb.dbo.#BrandsData2') is not null)  drop table dbo.#BrandsData2
select Status, Terr, Customer, ShipTo, Door, Address_name, 
	CASE WHEN (CASE WHEN door='y' and ShipTo<>''	THEN ISNULL(sum(BCBG_NET_S),0)  
	WHEN door<>'y' and ShipTo<>''	THEN 0	
ELSE ( (select ISNULL(sum(BCBG_NET_S),0) 
	from #BrandsData T11 where t1.Customer=t11.Customer and t11.door='y' and t11.ShipTo='') 
	+ (select ISNULL(sum(BCBG_NET_S),0) from #BrandsData T11 
	where t1.Customer=t11.Customer and t11.door<>'y' and t11.ShipTo<>'')) END) >= @minBrandSales THEN 1 else 0 END AS 'BCBG_NET_S', 
	CASE WHEN (CASE WHEN door='y' and ShipTo<>''	THEN ISNULL(sum(ET_NET_S),0)    	WHEN door<>'y' and ShipTo<>''	THEN 0	
ELSE ( (select ISNULL(sum(ET_NET_S),0) from #BrandsData T11 where t1.Customer=t11.Customer and t11.door='y' and t11.ShipTo='') + (select ISNULL(sum(ET_NET_S),0) from #BrandsData T11 where t1.Customer=t11.Customer and t11.door<>'y' and t11.ShipTo<>'')) END) >= @minBrandSales THEN 1 else 0 END  AS 'ET_NET_S', 
	CASE WHEN (CASE WHEN door='y' and ShipTo<>''	THEN ISNULL(sum(CH_NET_S),0)    	WHEN door<>'y' and ShipTo<>''	THEN 0	
ELSE ( (select ISNULL(sum(CH_NET_S),0) from #BrandsData T11 where t1.Customer=t11.Customer and t11.door='y' and t11.ShipTo='') + (select ISNULL(sum(CH_NET_S),0) from #BrandsData T11 where t1.Customer=t11.Customer and t11.door<>'y' and t11.ShipTo<>'')) END) >= @minBrandSales THEN 1 else 0 END  AS 'CH_NET_S', 
	CASE WHEN (CASE WHEN door='y' and ShipTo<>''	THEN ISNULL(sum(ME_NET_S),0)    	WHEN door<>'y' and ShipTo<>''	THEN 0	
ELSE ( (select ISNULL(sum(ME_NET_S),0) from #BrandsData T11 where t1.Customer=t11.Customer and t11.door='y' and t11.ShipTo='') + (select ISNULL(sum(ME_NET_S),0) from #BrandsData T11 where t1.Customer=t11.Customer and t11.door<>'y' and t11.ShipTo<>'')) END) >= @minBrandSales THEN 1 else 0 END  AS 'ME_NET_S', 
	CASE WHEN (CASE WHEN door='y' and ShipTo<>''	THEN ISNULL(sum(PFX_NET_S),0)    	WHEN door<>'y' and ShipTo<>''	THEN 0	
ELSE ( (select ISNULL(sum(PFX_NET_S),0) from #BrandsData T11 where t1.Customer=t11.Customer and t11.door='y' and t11.ShipTo='') + (select ISNULL(sum(PFX_NET_S),0) from #BrandsData T11 where t1.Customer=t11.Customer and t11.door<>'y' and t11.ShipTo<>'')) END) >= @minBrandSales THEN 1 else 0 END  AS 'PFX_NET_S', 
	CASE WHEN (CASE WHEN door='y' and ShipTo<>''	THEN ISNULL(sum(IZOD_NET_S),0)    	WHEN door<>'y' and ShipTo<>''	THEN 0	
ELSE ( (select ISNULL(sum(IZOD_NET_S),0) from #BrandsData T11 where t1.Customer=t11.Customer and t11.door='y' and t11.ShipTo='') + (select ISNULL(sum(IZOD_NET_S),0) from #BrandsData T11 where t1.Customer=t11.Customer and t11.door<>'y' and t11.ShipTo<>'')) END) >= @minBrandSales THEN 1 else 0 END  AS 'IZOD_NET_S', 
	CASE WHEN (CASE WHEN door='y' and ShipTo<>''	THEN ISNULL(sum(OP_NET_S),0)    	WHEN door<>'y' and ShipTo<>''	THEN 0	
ELSE ( (select ISNULL(sum(OP_NET_S),0) from #BrandsData T11 where t1.Customer=t11.Customer and t11.door='y' and t11.ShipTo='') + (select ISNULL(sum(OP_NET_S),0) from #BrandsData T11 where t1.Customer=t11.Customer and t11.door<>'y' and t11.ShipTo<>'')) END) >= @minBrandSales THEN 1 else 0 END  AS 'OP_NET_S', 
	CASE WHEN (CASE WHEN door='y' and ShipTo<>''	THEN ISNULL(sum(JMC_NET_S),0)    	WHEN door<>'y' and ShipTo<>''	THEN 0	
ELSE ( (select ISNULL(sum(JMC_NET_S),0) from #BrandsData T11 where t1.Customer=t11.Customer and t11.door='y' and t11.ShipTo='') + (select ISNULL(sum(JMC_NET_S),0) from #BrandsData T11 where t1.Customer=t11.Customer and t11.door<>'y' and t11.ShipTo<>'')) END) >= @minBrandSales THEN 1 else 0 END  AS 'JMC_NET_S', 
	CASE WHEN (CASE WHEN door='y' and ShipTo<>''	THEN ISNULL(sum(CVO_NET_S),0)    	WHEN door<>'y' and ShipTo<>''	THEN 0	
ELSE ( (select ISNULL(sum(CVO_NET_S),0) from #BrandsData T11 where t1.Customer=t11.Customer and t11.door='y' and t11.ShipTo='') + (select ISNULL(sum(CVO_NET_S),0) from #BrandsData T11 where t1.Customer=t11.Customer and t11.door<>'y' and t11.ShipTo<>'')) END) >= @minBrandSales THEN 1 else 0 END  AS 'CVO_NET_S', 
	CASE WHEN (CASE WHEN door='y' and ShipTo<>''	THEN ISNULL(sum(JC_NET_S),0)    	WHEN door<>'y' and ShipTo<>''	THEN 0	
ELSE ( (select ISNULL(sum(JC_NET_S),0) from #BrandsData T11 where t1.Customer=t11.Customer and t11.door='y' and t11.ShipTo='') + (select ISNULL(sum(JC_NET_S),0) from #BrandsData T11 where t1.Customer=t11.Customer and t11.door<>'y' and t11.ShipTo<>'')) END) >= @minBrandSales THEN 1 else 0 END  AS 'JC_NET_S', 
	CASE WHEN (CASE WHEN door='y' and ShipTo<>''	THEN ISNULL(sum(PT_NET_S),0)    	WHEN door<>'y' and ShipTo<>''	THEN 0	
ELSE ( (select ISNULL(sum(PT_NET_S),0) from #BrandsData T11 where t1.Customer=t11.Customer and t11.door='y' and t11.ShipTo='') + (select ISNULL(sum(PT_NET_S),0) from #BrandsData T11 where t1.Customer=t11.Customer and t11.door<>'y' and t11.ShipTo<>'')) END) >= @minBrandSales THEN 1 else 0 END  AS 'PT_NET_S', 
	CASE WHEN (CASE WHEN door='y' and ShipTo<>''	THEN ISNULL(sum(UN_NET_S),0)    	WHEN door<>'y' and ShipTo<>''	THEN 0	
ELSE ( (select ISNULL(sum(UN_NET_S),0) from #BrandsData T11 where t1.Customer=t11.Customer and t11.door='y' and t11.ShipTo='') + (select ISNULL(sum(UN_NET_S),0) from #BrandsData T11 where t1.Customer=t11.Customer and t11.door<>'y' and t11.ShipTo<>'')) END) >= @minBrandSales THEN 1 else 0 END  AS 'UN_NET_S', 
	CASE WHEN (CASE WHEN door='y' and ShipTo<>''	THEN ISNULL(sum(FP_NET_S),0)    	WHEN door<>'y' and ShipTo<>''	THEN 0	
ELSE ( (select ISNULL(sum(FP_NET_S),0) from #BrandsData T11 where t1.Customer=t11.Customer and t11.door='y' and t11.ShipTo='') + (select ISNULL(sum(FP_NET_S),0) from #BrandsData T11 where t1.Customer=t11.Customer and t11.door<>'y' and t11.ShipTo<>'')) END) >= @minBrandSales THEN 1 else 0 END  AS 'FP_NET_S', 
	CASE WHEN (CASE WHEN door='y' and ShipTo<>''	THEN ISNULL(sum(KO_NET_S),0)    	WHEN door<>'y' and ShipTo<>''	THEN 0	
ELSE ( (select ISNULL(sum(KO_NET_S),0) from #BrandsData T11 where t1.Customer=t11.Customer and t11.door='y' and t11.ShipTo='') + (select ISNULL(sum(KO_NET_S),0) from #BrandsData T11 where t1.Customer=t11.Customer and t11.door<>'y' and t11.ShipTo<>'')) END) >= @minBrandSales THEN 1 else 0 END  AS 'KO_NET_S', 
	CASE WHEN (CASE WHEN door='y' and ShipTo<>''	THEN ISNULL(sum(DI_NET_S),0)    	WHEN door<>'y' and ShipTo<>''	THEN 0	
ELSE ( (select ISNULL(sum(DI_NET_S),0) from #BrandsData T11 where t1.Customer=t11.Customer and t11.door='y' and t11.ShipTo='') + (select ISNULL(sum(DI_NET_S),0) from #BrandsData T11 where t1.Customer=t11.Customer and t11.door<>'y' and t11.ShipTo<>'')) END) >= @minBrandSales THEN 1 else 0 END  AS 'DI_NET_S', 
	CASE WHEN (CASE WHEN door='y' and ShipTo<>''	THEN ISNULL(sum(DD_NET_S),0)    	WHEN door<>'y' and ShipTo<>''	THEN 0	
ELSE ( (select ISNULL(sum(DD_NET_S),0) from #BrandsData T11 where t1.Customer=t11.Customer and t11.door='y' and t11.ShipTo='') + (select ISNULL(sum(DD_NET_S),0) from #BrandsData T11 where t1.Customer=t11.Customer and t11.door<>'y' and t11.ShipTo<>'')) END) >= @minBrandSales THEN 1 else 0 END  AS 'DD_NET_S'
INTO #BrandsData2
from #BrandsData T1
where Door = 'Y'
group by Status, Terr, Customer, ShipTo, Door, Address_name--, BCBG_NET_S, ET_NET_S, CH_NET_S, ME_NET_S, PFX_NET_S, IZOD_NET_S, OP_NET_S, JMC_NET_S, CVO_NET_S, JC_NET_S, PT_NET_S, UN_NET_S, FP_NET_S, KO_NET_S, DI_NET_S, DD_NET_S
order by Terr, Customer, ShipTo
-- -- FINAL BRANDS COUNT
-- select * from #BrandsData2
IF(OBJECT_ID('tempdb.dbo.#Brands') is not null)  drop table dbo.#Brands
select Status, Terr, Customer, ShipTo, Door, Address_name, 
sum(BCBG_NET_S + ET_NET_S + CH_NET_S + ME_NET_S + PFX_NET_S + 
IZOD_NET_S + OP_NET_S + JMC_NET_S + CVO_NET_S + JC_NET_S + PT_NET_S + 
UN_NET_S + FP_NET_S + KO_NET_S + DI_NET_S + DD_NET_S) NUM
INTO #Brands from  #BrandsData2 group by Status, Terr, Customer, ShipTo, Door, Address_name  order by Terr, Customer, ShipTo
-- select * from #Brands

-- BUILD SALES SUB REPORT
IF(OBJECT_ID('tempdb.dbo.#SalesData') is not null)  drop table dbo.#SalesData
CREATE TABLE dbo.#SalesData (
[Status] [varchar](1) NULL
,[Customer] [varchar](5) NULL
,[ShipTo] [varchar](8) NULL
,[Terr] [varchar](8) NULL
,[Door] [varchar](1) NULL
,[Address_name] [varchar](40) NULL
,[addr2] [varchar](40) NULL
,[addr3] [varchar](40) NULL
,[addr4] [varchar](40) NULL
,[City] [varchar](40) NULL
,[State] [varchar](40) NULL
,[Postal_code] [varchar](15) NULL
,[Country] [varchar](3) NULL
,[contact_name] [varchar](40) NULL
,[contact_phone] [varchar](30) NULL
,[tlx_twx] [varchar](30) NULL
,[contact_email] [varchar](255) NULL
,[NetSTY] [float] NULL
,[NetSLY] [float] NULL
,[NetSRXTY] [float] NULL
,[NetSRXLY] [float] NULL
,[NetSSTTY] [float] NULL
,[NetSSTLY] [float] NULL
,[RetSTY] [float] NULL
,[RetSLY] [float] NULL
,[RetSRaTY] [float] NULL
,[RetSRaLY] [float] NULL
,[RetSRXTY] [float] NULL
,[RetSRXLY] [float] NULL
,[RetSSTTY] [float] NULL
,[RetSSTLY] [float] NULL
,[GrossSTY] [float] NULL
,[GrossSLY] [float] NULL
,[GrossNoBepSTY] [float] NULL
,[GrossNoBepSLY] [float] NULL
,[NetUTY] [float] NULL
,[NetULY] [float] NULL
,[NetURXTY] [float] NULL
,[NetURXLY] [float] NULL
,[NetUSTTY] [float] NULL
,[NetUSTLY] [float] NULL
,[RetUTY] [float] NULL
,[RetULY] [float] NULL
,[RetURaTY] [float] NULL
,[RetURaLY] [float] NULL
,[RetURXTY] [float] NULL
,[RetURXLY] [float] NULL
,[RetUSTTY] [float] NULL
,[RetUSTLY] [float] NULL
,[GrossUTY] [float] NULL
,[GrossULY] [float] NULL
,[GrossNoBepUTY] [float] NULL
,[GrossNoBepULY] [float] NULL
,[ActiveDesignation] [nvarchar](max) NOT NULL
,[CurrentPrimary] [varchar](10) NOT NULL
,[Parent] [varchar](8) NULL
,[CustType] [varchar](40) NOT NULL
) ON [PRIMARY]
INSERT INTO #SalesData  EXEC RankCustDoor_sp @DateFrom,@DateTo,'TRUE' 
--  select * from #SalesData

-- BUILD PROGRAMS SUB REPORT
IF(OBJECT_ID('tempdb.dbo.#ProgramData') is not null)  drop table #ProgramData
CREATE TABLE dbo.#ProgramData (
[order_no] [varchar](10) NULL
,[ext] [varchar](3) NULL
,[cust_code] [varchar](10) NOT NULL
,[ship_to] [varchar](10) NULL
,[ship_to_name] [varchar](40) NULL
,[location] [varchar](10) NULL
,[cust_po] [varchar](20) NULL
,[routing] [varchar](20) NULL
,[fob] [varchar](10) NULL
,[attention] [varchar](40) NULL
,[tax_id] [varchar](10) NOT NULL
,[terms] [varchar](10) NULL
,[curr_key] [varchar](10) NULL
,[salesperson] [varchar](10) NULL
,[Territory] [varchar](10) NULL
,[region] [varchar](3) NULL
,[total_amt_order] [decimal](20, 8) NULL
,[total_discount] [decimal](20, 8) NULL
,[total_tax] [decimal](20, 8) NULL
,[freight] [decimal](20, 8) NULL
,[qty_ordered] [decimal](38, 8) NULL
,[qty_shipped] [decimal](38, 8) NULL
,[total_invoice] [decimal](23, 8) NOT NULL
,[invoice_no] [varchar](10) NULL
,[doc_ctrl_num] [varchar](16) NULL
,[date_invoice] [datetime] NULL
,[date_entered] [datetime] NOT NULL
,[date_sch_ship] [datetime] NULL
,[date_shipped] [datetime] NULL
,[status] [char](1) NOT NULL
,[status_desc] [varchar](20) NOT NULL
,[who_entered] [varchar](20) NULL
,[shipped_flag] [varchar](4) NOT NULL
,[hold_reason] [varchar](10) NULL
,[orig_no] [int] NULL
,[orig_ext] [int] NULL
,[promo_id] [varchar](255) NULL
,[promo_level] [varchar](255) NULL
,[order_type] [varchar](10) NULL
,[FramesOrdered] [decimal](38, 8) NOT NULL
,[FramesShipped] [decimal](38, 8) NOT NULL
,[back_ord_flag] [char](1) NULL
,[Cust_type] [varchar](40) NOT NULL
,[return_date] [datetime] NULL
,[reason] [varchar](40) NULL
,[return_amt] [decimal](20, 8) NULL
,[return_qty] [int] NOT NULL
,[source] [varchar](1) NOT NULL
,[Qual_order] [int] NOT NULL
,[override_reason] [varchar](2000) NULL
) ON [PRIMARY]
INSERT INTO #ProgramData  EXEC cvo_promotions_tracker_r2_sp @DateFrom,@DateTo
DELETE FROM #ProgramData WHERE ORDER_NO IS NULL
DELETE FROM #ProgramData WHERE QUAL_ORDER = 0

-- select * from #ProgramData where territory = '20204'

-- BUILD STOCK ORDERS SUB REPORT


-- -- # STOCK ORDERS PER MONTH  
-- PULL DATA FOR ST SHIPPED ORDERS / CREDITS OVER 5PCS
IF(OBJECT_ID('tempdb.dbo.#Invoices') is not null)  
drop table #Invoices

--LIVE
SELECT T1.TYPE, t1.status, DOOR, t3.territory_code, CUST_CODE, T1.SHIP_TO, Promo_ID, user_category, t1.ORDER_NO, t1.ext, 
CASE WHEN T1.TYPE = 'I' THEN sum(ordered) ELSE sum(cr_shipped)*-1 END AS 'QTY',
CASE WHEN T1.TYPE = 'I' THEN 1 ELSE -1 END AS 'COUNT',
ADDED_BY_DATE,
dateadd(day, datediff(day,0, t1.date_shipped), 0) date_shipped,
dateadd(mm, datediff(month, 0 , t1.date_shipped), 0) period, 
month(date_shipped) as X_MONTH

into #invoices

FROM ORDERS_ALL (NOLOCK) T1
JOIN ORD_LIST (NOLOCK) T2 ON T1.ORDER_NO = T2.ORDER_NO AND T1.EXT=T2.ORDER_EXT
join inv_master (nolock) IV on t2.part_no=IV.part_no
JOIN ARMASTER (NOLOCK) T3 ON T1.CUST_CODE=T3.CUSTOMER_CODE AND T1.SHIP_TO=T3.SHIP_TO_CODE
JOIN CVO_ARMASTER_ALL (NOLOCK) T4 ON T1.CUST_CODE=T4.CUSTOMER_CODE AND T1.SHIP_TO=T4.SHIP_TO
JOIN cvo_orders_all (NOLOCK) T5 ON T1.ORDER_NO = T5.ORDER_NO AND T1.EXT=T5.EXT
where t1.status = 't'
and date_shipped <= @dateto
-- date_shipped BETWEEN Dateadd(year,-2,@DateFrom) AND @DateTo
AND TYPE='I'
--and (order_ext=0 OR t1.who_entered = 'outofstock')
and t1.who_entered <> 'backordr'
and type_code in('sun','frame')
and user_category not like '%rx%'
and user_category not in ( 'ST-RB', 'DO')
GROUP BY t3.territory_code, DOOR, CUST_CODE, T1.SHIP_TO, T5.PROMO_ID, user_category, 
t1.ORDER_NO, t1.ext, T1.STATUS, T1.TYPE, ADDED_BY_DATE, date_shipped


-- select * from #Invoices where CUST_CODE = '047859'

-- Pull Unique Custs Orders by Month >=5pcs
IF(OBJECT_ID('tempdb.dbo.#InvStCount') is not null)  
drop table #InvStCount
select distinct territory_code, cust_code, sum(count) STOrds, X_MONTH
INTO #InvStCount
from #Invoices 
where qty>=5
and date_shipped BETWEEN @DateFrom and @DateTo
group by territory_code, cust_code, X_MONTH
having sum(count) >0
--order by territory_code, X_Month, cust_code
-- select * from #InvStCount order by territory_code, cust_code

-- REACTIVATED -- -- PULL Last & 2nd Last ST Order
IF(OBJECT_ID('tempdb.dbo.#DATA') is not null)  drop table #DATA
Select  t1.territory_code as Territory, t1.Customer_code, ship_to_code, 
T2.DOOR, added_by_date,
SUM(NETSALES)YTDNET,
-- FirstSTNew
LastST = (SELECT min(date_shipped) FROM #INVOICES inv 
	WHERE Type='i' and QTY >=5 
	and date_shipped >= @datefrom
	AND inv.CUST_CODE=T1.customer_code AND inv.SHIP_TO=T1.SHIP_TO_CODE) ,
-- PrevstNew
[2ndLastST]	= (select MAX(date_shipped) from #INVOICES t11 WHERE Type='i' 
	 and t11.date_shipped <
	  (SELECT min(inv.date_shipped) FROM #INVOICES inv 
		WHERE Type='i' and QTY >=5 
		and date_shipped >= @datefrom 
		AND inv.CUST_CODE=T1.customer_code AND inv.SHIP_TO=T1.SHIP_TO_CODE)
	  and QTY >=5 AND T11.CUST_CODE=T1.customer_code AND T11.SHIP_TO=T1.SHIP_TO_CODE)
INTO #DATA
from armaster t1 (NOLOCK)
join cvo_armaster_all t2 (nolock) on t1.customer_code=t2.customer_code and t1.ship_to_code=t2.ship_to
join cvo_rad_shipto t3 on right(t3.customer,5)=right(t1.customer_code,5) and t3.ship_to=t1.ship_to_code
 WHERE t1.address_type <> 9 and T2.door=1
AND yyyymmdd BETWEEN @DateFrom AND @DateTo
group by t1.territory_code, t1.customer_code, ship_to_code, t2.door, added_by_date
-- select * from #Data WHERE CUSTOMER_CODE = '047859'
-- select * from #INVOICES WHERE CUST_CODE = '047859' ORDER BY DATE_SHIPPED DESC

IF(OBJECT_ID('tempdb.dbo.#DATA2') is not null)  drop table #DATA2
SELECT T1.*, 
CASE WHEN DATEDIFF(D,isnull([2ndLastST],lastst),LastST) > 365 AND LastST > @DateFrom 
	AND added_by_date < @DateFrom    
	THEN 'REA' ELSE '' 
	END AS STAT,
CASE WHEN DATEDIFF(D,isnull([2ndLastST],lastst),LastST) > 365 AND LastST > @DateFrom 
	AND added_by_date < @DateFrom  
	THEN ISNULL(Month(LastST),1) else '' 
	end as X_MONTH
INTO #DATA2 FROM #DATA T1 
-- select * from #Data2 where STAT='REA'

-- FINAL FOR ST COUNT & REA COUNT
IF(OBJECT_ID('tempdb.dbo.#STREAD') is not null)  drop table #STREAD
SELECT * INTO #STREAD FROM (
 select Territory_code as Territory, COUNT(STOrds)NumStOrds, 0 as NumRea from 
 #InvStCount where stOrds <>  0 group by Territory_code, X_MONTH
 UNION ALL
 select Territory, 0 as NumStOrds, count(Door)NumRea from #Data2 where 
 STAT='REA' Group by Territory  ) tmp
 Order by Territory
 
IF(OBJECT_ID('tempdb.dbo.#STREA') is not null)  drop table #STREA
Select Territory, SUM(NumStOrds)NumStOrds, SUM(NumRea)NumRea INTO #STREA 
from #STREAD group by Territory
-- Select * from #STREA

-- BUILD TERRITORY SALES

IF(OBJECT_ID('tempdb.dbo.#t1') is not null)  drop table #t1
select T.Terr, return_code, user_category, 
sum(anet) NETTY, 
sum(asales) Gross, sum(areturns) Ret,
case when return_code = '' then sum(areturns) end as RetSA,
case when user_category= 'RX' then sum(anet) end as RX
into #t1
 from #Terrs T
 left outer join armaster T2 on t.Terr=t2.territory_code
 join cvo_sbm_details t1 on t1.customer=t2.customer_code and t1.ship_to=t2.ship_to_code
  where yyyymmdd between @DateFrom and @DateTo
group by T.Terr, return_code, user_category
order by T.Terr, user_category, return_code

-- SELECT * FROM #T1 where Terr = '90910'
IF(OBJECT_ID('tempdb.dbo.#TerrSales') is not null)  drop table #TerrSales
select T.Terr, ISNULL(sum(netty),0)NetSTY, 
ISNULL((select SUM(ANET) from cvo_sbm_details t11 join armaster t12 on t11.customer=t12.customer_code and t11.ship_to=t12.ship_to_code and T.Terr=T12.Territory_code AND yyyymmdd between DateAdd(year,-1,@DateFrom) and DateAdd(year,-1,@DateTo)),0)NetSLY,
ISNULL(sum(gross),0)Gross, ISNULL(sum(ret),0)Ret, ISNULL(sum(retSA),0)RetSa, ISNULL(sum(rx),0)RX 
INTO #TerrSales 
from #Terrs T
left outer join #t1 t1 on T.Terr=T1.Terr
group by T.Terr, T1.Terr
--select * from #TerrSales where Terr = '90910' Order by Terr

-- FINAL SELECT
IF(OBJECT_ID('tempdb.dbo.#FINAL') is not null)  drop table #FINAL
SELECT T1.*,
  ISNULL((SELECT Count(Customer) FROM #SalesData T3 
		WHERE T1.TERR=T3.TERR AND NETSTY>=2400),0)Active,

  ISNULL((SELECT sum(NumRea) FROM #STREA T5 WHERE T1.TERR=T5.Territory),0)ReActive,
  
  ISNULL((SELECT Count(Customer_code) 
	FROM #Data2 t6 WHERE  t1.Terr=t6.territory 
	and ( (added_by_date >= @DateFrom and isnull(LastST,0) >= @DateFrom)
	     or (lastst    >= @datefrom and isnull([2ndlastst],0)=0)) ), 0) New,

  ISNULL((SELECT sum(NumSTOrds) FROM #STREA T5 WHERE T1.TERR=T5.Territory),0) STOrds,
  ISNULL((SELECT COUNT(Order_no) from #ProgramData T4 where t1.terr=t4.territory 	and promo_id in ('AAP','APR','BEP','RCP','ROT64','FOD','SS') ),0)AnnualProg,
  ISNULL((SELECT COUNT(Order_no) from #ProgramData T4 where t1.terr=t4.territory 	and promo_id in ('BOGO','DOR','ME','PURITI','IZOD','KIDS','SUN','sunps','T3','CH','CVO','BCBG', 'ET', 'SUN SPRING', 'IZOD CLEAR'  ) ),0)SeasonalProg,  
  ISNULL((SELECT COUNT(Order_no) from #ProgramData T4 where t1.terr=t4.territory 	and promo_id in ('RXE') ),0)RXEProg,  
  ISNULL((SELECT count(Customer) FROM #Brands T2 WHERE T1.TERR=T2.TERR and NUM >=4),0)[4Brands],

  ISNULL((SELECT SUM(NETSTY)-SUM(NETSLY) FROM #TerrSales T3 WHERE T1.TERR=T3.TERR ),0)IncreaseDol,
    ISNULL((SELECT CASE WHEN SUM(NETSLY) = 0 THEN 1 WHEN SUM(NETSLY) < 0 THEN ((SUM(NETSTY)-SUM(NETSLY))/-SUM(NETSLY)) ELSE ((SUM(NETSTY)-SUM(NETSLY))/SUM(NETSLY)) END from #TerrSales T3 WHERE T1.TERR=T3.TERR),0)IncreasePct,
  ISNULL((SELECT CASE WHEN sum(NETSTY) = 0 THEN 0 ELSE sum(RX)/sum(NETSTY) END from #TerrSales T3 WHERE T1.TERR=T3.TERR),0)RXPct,
  
  ISNULL((SELECT sum(Gross) from #TerrSales T3 WHERE T1.TERR=T3.TERR),0)GrossSTY,
  ISNULL((SELECT sum(RetSa) from #TerrSales T3 WHERE T1.TERR=T3.TERR),0)RetSRATY,
  
  ISNULL((SELECT CASE WHEN sum(Gross) = 0 AND sum(RetSa) = 0 THEN 0 ELSE sum(RetSa)/sum(Gross) END from #TerrSales T3 WHERE T1.TERR=T3.TERR),0)RetPct,
  
  ISNULL((SELECT Count(Customer) FROM #SalesData T3 WHERE T1.TERR=T3.TERR AND NETSTY>='500'),0)Door500,
  
  ISNULL((SELECT SUM(NETSTY) FROM #TerrSales T3 WHERE T1.TERR=T3.TERR ),0)NetsTY,
  ISNULL((SELECT SUM(RX) FROM #TerrSales T3 WHERE T1.TERR=T3.TERR ),0)RXs,
  ISNULL((SELECT SUM(NETSLY) FROM #TerrSales T3 WHERE T1.TERR=T3.TERR ),0)NetsLY
  
INTO #FINAL
FROM #SlpInfo T1
-- select * from #final

-- IF(OBJECT_ID('CVO_SalesScoreCard_SSRS') is not null)  drop table dbo.CVO_SalesScoreCard_SSRS
select *,
Case when Active in (select TOP 3 active from #FINAL where Region NOT IN ('800','900') and Status <> 'Empty' order by active desc) then 'WIN' else '' end as WINActive,
Case when ReActive in (select TOP 3 ReActive from #FINAL where Region NOT IN ('800','900') and Status <> 'Empty' order by ReActive desc) then 'WIN' else '' end as WINReActive,
Case when New in (select TOP 3 New from #FINAL where Region NOT IN ('800','900') and Status <> 'Empty' order by New  desc) then 'WIN' else '' end as WINNew,
Case when STOrds in  (select TOP 3 STOrds from #FINAL where Region NOT IN ('800','900') and Status <> 'Empty' order by STOrds desc) then 'WIN' else '' end as WINSTOrds,
Case when AnnualProg in (select TOP 3 AnnualProg from #FINAL where Region NOT IN ('800','900') and Status <> 'Empty' order by AnnualProg desc) then 'WIN' else '' end as WINAnnualProg,
Case when SeasonalProg in (select TOP 3 SeasonalProg from #FINAL where Region NOT IN ('800','900') and Status <> 'Empty' order by SeasonalProg desc) then 'WIN' else '' end as WINSeasonalProg,
Case when RXEProg in (select TOP 3 RXEProg from #FINAL where Region NOT IN ('800','900') and Status <> 'Empty' order by RXEProg desc) then 'WIN' else '' end as WINRXEProg,
Case when [4Brands] in (select TOP 3 [4Brands] from #FINAL where Region NOT IN ('800','900') and Status <> 'Empty' order by [4Brands] desc) then 'WIN' else '' end as WIN4Brands,
Case when IncreaseDol in (select TOP 3 IncreaseDol from #FINAL where Region NOT IN ('800','900') and Status <> 'Empty' order by IncreaseDol desc) then 'WIN' else '' end as WINIncreaseDol,
Case when IncreasePct in (select TOP 3 IncreasePct from #FINAL where Region NOT IN ('800','900') and Status <> 'Empty' order by IncreasePct desc) then 'WIN' else '' end as WINIncreasePct,
Case when RXPct in (select TOP 3 RXPct from #FINAL where Region NOT IN ('800','900') and Status <> 'Empty' order by RXPct desc) then 'WIN' else '' end as WINRXPct,
Case when GrossSTY in (select TOP 3 GrossSTY from #FINAL where Region NOT IN ('800','900') and Status <> 'Empty' order by GrossSTY desc) then 'WIN' else '' end as WINGrossSTY,
Case when RetSRATY in (select TOP 3 RetSRATY from #FINAL where Region NOT IN ('800','900') and Status <> 'Empty' order by RetSRATY desc) then 'WIN' else '' end as WINRetSRATY,
ISNULL(case when  Region NOT IN ('800','900') and Status <> 'Empty' THEN (Case when RetPct in (select TOP 3 RetPct from #FINAL where Region NOT IN ('800','900') and Status <> 'Empty' Order by RetPct asc) then 'WIN' else '' end) END,'') as WINRetPct,
Case when Door500 in (select TOP 3 Door500 from #FINAL where Region NOT IN ('800','900') and Status <> 'Empty' order by Door500 desc) then 'WIN' else '' end as WINDoor500,
Case when NetsTY in (select TOP 3 NetsTY from #FINAL where Region NOT IN ('800','900') and Status <> 'Empty' order by NetsTY desc) then 'WIN' else '' end as WINNetsTY,
Case when RXs in (select TOP 3 RXs from #FINAL where Region NOT IN ('800','900') and Status <> 'Empty' order by RXs desc) then 'WIN' else '' end as WINRXs,
Case when NetsLY in (select TOP 3 NetsLY from #FINAL where Region NOT IN ('800','900') and Status <> 'Empty' order by NetsLY desc) then 'WIN' else '' end as WINNetsLY,
Case when Terr in ('20201', '20206', '20224', '20225', '30304', '30335', '40424', '40454', '40456', '50503', 
-- remove 101314 - '50508', '50520', 
-- add 101314
'50512','40452',
'70720', '70721', '70728', '70785') THEN 'PC' else '' end as PresCncl 
-- INTO CVO_SalesScoreCard_SSRS
from #FINAL
Order by Terr

-- select * from CVO_SalesScoreCard_SSRS

-- EXEC CVO_Sales_ScoreCard_SP '1/1/2014', '6/30/2014'

-- select * From #brands

END
GO
