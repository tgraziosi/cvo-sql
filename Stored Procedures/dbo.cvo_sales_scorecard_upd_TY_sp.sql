SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Tine Graziosi
-- Create date: 01/14/2016
-- Description:	Sales Territory/Salesperson ScoreCard update for portal scorecard
-- EXEC CVO_Sales_ScoreCard_upd_ty_Sp
-- select * from cvo_terr_scorecard where rsm_territory_code is null
-- delete from cvo_terr_scorecard where territory_code is null
-- update cvo_terr_scorecard set stat_year = '2015' where stat_year = '2015a'
-- select * into cvo_terr_scorecard_bkup from cvo_terr_scorecard
-- 051315 - add  qual st ord_value
-- =============================================


CREATE PROCEDURE [dbo].[cvo_sales_scorecard_upd_TY_sp] 
AS

SET NOCOUNT ON;
SET ANSI_WARNINGS OFF;

BEGIN

declare @datefrom datetime, @dateto DATETIME, @datetoty DATETIME, @datefromly DATETIME, @datetoly DATETIME
		, @datefrompy DATETIME, @datetopy datetime
declare @territory varchar(1024), @statyear VARCHAR(4), @statyearly VARCHAR(4), @statyearty VARCHAR(4)
select @Territory = NULL

SELECT @datefrom = cdrv.BeginDate, @dateto = cdrv.EndDate
FROM dbo.cvo_date_range_vw AS cdrv WHERE cdrv.Period = 'Year To Date'
SELECT @datetoty = @dateto

SELECT @datefromly = cdrv.BeginDate, @datetoly = cdrv.EndDate
FROM dbo.cvo_date_range_vw AS cdrv WHERE cdrv.Period = 'Last Year to Date'

SELECT @datefrompy = cdrv.BeginDate, @datetopy = cdrv.EndDate
FROM dbo.cvo_date_range_vw AS cdrv WHERE cdrv.Period = 'Two Years Ago to Date'

-- select * from cvo_date_Range_vw

--SELECT @datefrom = '1/1/2015', @dateto = '12/31/2015'
--SELECT @datefromly = '1/1/2014', @datetoly = '12/31/2014'

SELECT @statyear = CAST(DATEPART(YEAR,@dateto) AS varchar(4))
SELECT @statyearty = CAST(DATEPART(YEAR,@dateto) AS varchar(4))
SELECT @statyearly = CAST(DATEPART(YEAR,@datetoly) AS varchar(4))

IF(OBJECT_ID('tempdb.dbo.#report_ty') is not null)  drop table #report_ty


create table #report_ty
(region VARCHAR(5),
 Terr varchar(10)
, Salesperson varchar(40)
, date_of_hire datetime
, ClassOf varchar(5)
, Status varchar(20)
, PC int
, Top9 int
, Active int
, ReActive int
, New int
, STOrds int
, ord_value decimal(20,8)
,AnnualProg int
,SeasonalProg int
,RXEProg INT
,AspireProg int
,id4Brands int
,IncreaseDol float
,IncreasePct float
,RXPct float
,GrossSTY decimal(20,8)
,RetSRATY decimal(20,8)
,RetPct float
,Door500 int
,NetsTY decimal(20,8)
,NetsTY_Goal decimal(20,8)
,RXs decimal(20,8)
,NetsLY decimal(20,8)
,TerrGoal DECIMAL(20,8)
,TerrGoalPCT DECIMAL(20,8)
,activeretaincnt INTEGER
,door500retaincnt INTEGER
,activeretainvalue DECIMAL(20,8)
,door500retainvallue DECIMAL(20,8)
,Veteran_status varchar(10)
)

IF(OBJECT_ID('tempdb.dbo.#report_ly') is not null)  drop table #report_ly
create table #report_ly
(region VARCHAR(5),
Terr varchar(10)
, Salesperson varchar(40)
, date_of_hire datetime
, ClassOf varchar(5)
, Status varchar(20)
, PC int
, Top9 int
, Active int
, ReActive int
, New int
, STOrds int
, ord_value decimal(20,8)
,AnnualProg int
,SeasonalProg int
,RXEProg INT
,AspireProg int
,id4Brands int
,IncreaseDol float
,IncreasePct float
,RXPct float
,GrossSTY decimal(20,8)
,RetSRATY decimal(20,8)
,RetPct float
,Door500 int
,NetsTY decimal(20,8)
,NetsTY_Goal decimal(20,8)
,RXs decimal(20,8)
,NetsLY decimal(20,8)
,TerrGoal DECIMAL(20,8)
,TerrGoalPCT DECIMAL(20,8)
,activeretaincnt INTEGER
,door500retaincnt INTEGER
,activeretainvalue DECIMAL(20,8)
,door500retainvallue DECIMAL(20,8)
,Veteran_status varchar(10)
)


insert #report_ty
exec CVO_Sales_ScoreCard_terr_SP @datefrom, @dateto --, @Territory

insert #report_ly
exec CVO_Sales_ScoreCard_terr_SP @datefromly, @datetoly --, @Territory

-- lets replace all the actuals records
DELETE FROM cvo_terr_scorecard WHERE Stat_Year = @statyearty+'A' OR stat_year = @statyearly+'A'

DECLARE @cntr int
SELECT @cntr =  0

WHILE @cntr < 2
BEGIN

INSERT dbo.cvo_terr_scorecard
        ( scdate,
		  Territory_Code ,
          Salesperson_name ,
          Stat_Year ,
          ActiveDoors_2400 ,
          Active_Retn_Pct ,
          Active_Retn_Amt ,
          ReAct_Doors ,
          New_Doors ,
          Valid_ST_Orders ,
          Valid_ST_Orders_Amt ,
          Qual_Annual_Progs ,
          Qual_Seasonal_Progs ,
          Qual_RXE_Progs ,
          Doors_4Brands ,
          Net_Sales_TY ,
          LY_TY_Sales_Increase_Amt ,
          LY_TY_Sales_Incr_Pct ,
          Pct_to_Goal ,
          TY_RX_Pct ,
          TY_Ret_Pct ,
          Doors_500 ,
          D500_Retn_Pct
        )

SELECT distinct
@dateto
, ty.Terr 
, ty.Salesperson 
, @statyear+'A'  -- actuals
, ty.Active 
, ActiveRetentionPct = CASE WHEN ISNULL(ly.active,0) = 0 THEN 0
	ELSE  
	CAST((CASE WHEN cast(ISNULL(ly.active,0) AS FLOAT) = 0.00 THEN 1.00 
			   ELSE CAST(ISNULL(ty.activeretaincnt,0) AS FLOAT) / CAST(ISNULL(ly.active,1) AS FLOAT) END) AS DECIMAL(20,8))
	END
, ty.activeretainvalue 
, ty.ReActive 
, ty.New 
, ty.STOrds 
, ty.ord_value 
, ty.AnnualProg 
, ty.SeasonalProg 
, ty.RXEProg 
, ty.id4Brands 
, ty.NetsTY 
, ty.IncreaseDol 
, ty.IncreasePct 
, TerrGoalPCT = CASE WHEN ISNULL(cts.Core_Goal_Amt,0) = 0 THEN 0
				ELSE ISNULL(ty.netsty,0) / ISNULL(cts.Core_Goal_Amt,0) end
, ty.RXPct
, ty.RetPct 
, ty.Door500 
, SlowRetentionPct = CASE WHEN ISNULL(ly.Door500,0) = 0 THEN 0
	else
	CAST( (CASE WHEN CAST(ISNULL(ty.door500,0) AS FLOAT) = 0.00 THEN 1.00
				ELSE CAST(ISNULL(ty.door500retaincnt,0) AS FLOAT) / CAST(ISNULL(ly.door500,0) AS FLOAT) END) AS DECIMAL(20,8))
	END

From #report_ty ty
LEFT OUTER JOIN #report_ly ly ON ty.terr = ly.terr
LEFT OUTER JOIN dbo.cvo_terr_scorecard AS cts ON cts.Territory_Code = ty.Terr AND cts.Stat_Year = @statyear

SELECT @cntr = @cntr + 1
IF @cntr < 2
begin
	truncate TABLE #report_ty
	INSERT #report_ty
        ( region,
		  Terr ,
          Salesperson ,
          date_of_hire ,
          ClassOf ,
          Status ,
          PC ,
          Top9 ,
          Active ,
          ReActive ,
          New ,
          STOrds ,
          ord_value ,
          AnnualProg ,
          SeasonalProg ,
          RXEProg ,
          AspireProg ,
          id4Brands ,
          IncreaseDol ,
          IncreasePct ,
          RXPct ,
          GrossSTY ,
          RetSRATY ,
          RetPct ,
          Door500 ,
          NetsTY ,
          NetsTY_Goal ,
          RXs ,
          NetsLY ,
          TerrGoal ,
          TerrGoalPCT ,
          activeretaincnt ,
          door500retaincnt ,
          activeretainvalue ,
          door500retainvallue ,
          Veteran_status
        )
	SELECT * FROM #report_ly
	TRUNCATE TABLE #report_ly
	insert #report_ly
	exec CVO_Sales_ScoreCard_terr_SP @datefrompy, @datetopy --, @Territory 
	SELECT @statyear = @statyearly, @dateto = @datetoly
END
END

-- update the region codes in the scorecard

UPDATE t SET t.RSM_Territory_Code = ISNULL(csav.rsm_territory_code,'900')
-- SELECT *
FROM cvo_terr_scorecard t
LEFT OUTER JOIN dbo.cvo_sc_addr_vw AS csav ON csav.territory_code = t.Territory_Code
WHERE t.RSM_Territory_Code IS null

-- update target records for region summaries

DELETE FROM dbo.cvo_terr_scorecard WHERE salesperson_name =  'Region Summary' AND (Stat_Year LIKE '%A')

INSERT dbo.cvo_terr_scorecard
        ( scdate,
		  Territory_Code ,
          Salesperson_name ,
          Stat_Year ,
          ActiveDoors_2400 ,
          Active_Retn_Pct ,
          Active_Retn_Amt ,
          ReAct_Doors ,
          New_Doors ,
          Valid_ST_Orders ,
          Valid_ST_Orders_Amt ,
          Qual_Annual_Progs ,
          Qual_Seasonal_Progs ,
          Qual_RXE_Progs ,
          Doors_4Brands ,
          Net_Sales_TY ,
          LY_TY_Sales_Increase_Amt ,
          LY_TY_Sales_Incr_Pct ,
          Pct_to_Goal ,
          TY_RX_Pct ,
          TY_Ret_Pct ,
          Doors_500 ,
          D500_Retn_Pct,
		  RSM_Territory_Code
        )
SELECT 
@dateto
, cts.rsm_territory_code AS Territory_code
, 'Region Summary' AS Salesperson 
, cts.Stat_Year  -- targets for current year rollup
, SUM(cts.ActiveDoors_2400) ActiveDoors_2400
, ActiveRetentionPct = null
, SUM(cts.Active_Retn_Amt) active_retn_amt
, SUM(cts.ReAct_Doors) ReAct_Doors
, SUM(cts.New_Doors ) New_Doors
, SUM(cts.Valid_ST_Orders ) Valid_ST_Orders
, SUM(cts.Valid_ST_Orders_Amt) Valid_ST_Orders_Amt 
, SUM(cts.Qual_Annual_Progs) Qual_Annual_Progs
, SUM(cts.Qual_Seasonal_Progs ) Qual_Seasonal_Progs
, SUM(cts.Qual_RXE_Progs ) Qual_RXE_Progs
, SUM(cts.Doors_4Brands ) Doors_4Brands
, SUM(cts.Net_Sales_TY ) Net_Sales_TY 
, SUM(cts.LY_TY_Sales_Increase_Amt ) LY_TY_Sales_Increase_Amt
,  LY_TY_Sales_Incr_Pct = NULL -- can't calculate here

, TerrGoalPCT = CASE WHEN SUM(ISNULL(cts.Core_Goal_Amt,0)) = 0 THEN 0
				ELSE SUM(ISNULL(cts.LY_TY_Sales_Incr_Pct,0)) / SUM(ISNULL(cts.Core_Goal_Amt,0)) end
, RXPct = null
, RetPct = null
, SUM(ISNULL(cts.Doors_500,0) ) Doors_500
, SlowRetentionPct = NULL
, cts.rsm_territory_code

From dbo.cvo_terr_scorecard AS cts 
WHERE cts.Stat_Year LIKE '%A'
GROUP BY cts.rsm_territory_code, cts.Stat_Year

-- update the PC Avg and Veterans Average entries
INSERT dbo.cvo_terr_scorecard
        ( SCDate ,
          Territory_Code ,
          Salesperson_name ,
          Stat_Year)
SELECT @datetoty,
		'PC_AVG',
		'PC Average',
		@statyearty+'X'
WHERE NOT EXISTS (SELECT 1 FROM dbo.cvo_terr_scorecard AS cts 
				  WHERE stat_year = @statyearty+'X' AND cts.Territory_Code = 'PC_AVG')

INSERT dbo.cvo_terr_scorecard
        ( SCDate ,
          Territory_Code ,
          Salesperson_name ,
          Stat_Year)
SELECT @datetoty,
		'Vet_AVG',
		'Vet Average',
		@statyearty+'X'
WHERE NOT EXISTS (SELECT 1 FROM dbo.cvo_terr_scorecard AS cts 
				  WHERE stat_year = @statyearty+'X' AND cts.Territory_Code = 'Vet_AVG')

UPDATE dbo.cvo_terr_scorecard
SET 
       scdate = @datetoty, 
       ActiveDoors_2400 = ty.Active,
 	   react_doors = ty.ReActive ,
	   new_doors = ty.new ,
	   valid_st_orders = ty.STOrds ,
		qual_annual_progs = ty.AnnualProg ,
		qual_seasonal_progs = ty.SeasonalProg,
		qual_rxe_progs = ty.RXEProg ,
		doors_4brands = ty.id4Brands ,
		doors_500 = ISNULL(ty.Door500,0)  

 --- president council members
From 
(SELECT terr,
		AVG(active) active,
		AVG(reactive) reactive,
		avg(new) new,
		AVG(stords) stords,
		AVG(annualprog) annualprog,
		AVG(seasonalprog) seasonalprog,
		AVG(rxeprog) rxeprog,
		AVG(id4brands) id4brands,
		AVG(door500) door500
		FROM #report_ty
		WHERE pc = 1
		GROUP BY terr)	AS ty 
WHERE Stat_Year LIKE @statyearty+'X' AND territory_code = 'PC_AVG'

update dbo.cvo_terr_scorecard 
SET 
       scdate = @datetoty, 
       ActiveDoors_2400 =  ty.Active,
 	   react_doors = ty.ReActive ,
	   new_doors = ty.new ,
	   valid_st_orders = ty.STOrds ,
		qual_annual_progs = ty.AnnualProg ,
		qual_seasonal_progs = ty.SeasonalProg,
		qual_rxe_progs = ty.RXEProg ,
		doors_4brands = ty.id4Brands ,
		doors_500 = ISNULL(ty.Door500,0)  

 --- Veterans

From 
(SELECT terr,
		AVG(ISNULL(active,0)) active,
		AVG(reactive) reactive,
		avg(new) new,
		AVG(stords) stords,
		AVG(annualprog) annualprog,
		AVG(seasonalprog) seasonalprog,
		AVG(rxeprog) rxeprog,
		AVG(id4brands) id4brands,
		AVG(door500) door500
		FROM #report_ty
		WHERE status = 'Veteran'
		GROUP BY terr
		) AS ty 
		WHERE Stat_Year = @statyearty+'X' AND territory_code = 'Vet_AVG'

-- DELETE FROM dbo.cvo_terr_scorecard WHERE salesperson_name =  'Region Summary' AND (Stat_Year LIKE '%A')

END

--UPDATE t SET t.RSM_Territory_Code = csav.rsm_territory_code
--FROM 
--cvo_terr_scorecard t
--JOIN dbo.cvo_sc_addr_vw AS csav ON csav.territory_code = t.Territory_Code
--WHERE t.RSM_Territory_Code IS null

--SELECT csav.territory_code, csav.rsm_territory_code, cts.Territory_Code, cts.RSM_Territory_Code, cts.Stat_Year
--From dbo.cvo_terr_scorecard AS cts 
--LEFT OUTER JOIN dbo.cvo_sc_addr_vw AS csav ON csav.territory_code = cts.Territory_Code

-- UPDATE dbo.cvo_terr_scorecard SET scdate = '12/31/2014' WHERE scdate IS NULL AND stat_year = '2014'
-- update cvo_terr_scorecard set territory_code = 'Vet_avgs' where territory_code = 'Vet_avg'
GO
