SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



-- =============================================
-- Author:		Tine Graziosi
-- Create date: 12/23/2014
-- Description:	Sales Territory/Salesperson ScoreCard (also for NSM  AWARDS)
-- EXEC CVO_Sales_ScoreCard_ty_LY_SP '1/1/2016', '4/1/2016'
-- 051315 - add  qual st ord_value
-- =============================================
CREATE PROCEDURE [dbo].[cvo_sales_scorecard_TY_LY_sp] 

@DF datetime,
@DT datetime
--, @Terr varchar(1024) = null
--with recompile
AS
SET NOCOUNT ON;
BEGIN



declare @datefrom datetime, @dateto datetime
declare @territory varchar(1024)
select @datefrom = @df, @dateto = @dt
select @Territory = null

declare @datefromly datetime, @datetoly datetime
select @datefromly = dateadd(yy,-1,@datefrom), @datetoly = dateadd(yy,-1,@dateto)

create table #report_ty
(Region varchar(3)
,Terr varchar(10)
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

create table #report_LY
(Region varchar(3)
,Terr varchar(10)
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

TRUNCATE TABLE #report_ty
insert #report_ty
--exec CVO_Sales_ScoreCard_terr_SP '1/1/2016', '3/31/2016' --, @Territory
--SELECT * FROM #report_ty AS rt

exec CVO_Sales_ScoreCard_terr_SP @datefrom, @dateto --, @Territory

TRUNCATE TABLE #report_ly
insert #report_ly 
exec CVO_Sales_ScoreCard_terr_SP @Datefromly, @Datetoly -- , @Territory


select 
ty.Region 
, ty.Terr 
, ty.Salesperson 
, ty.date_of_hire 
, ty.ClassOf
, ty.Status
, ty.PC
, ty.Top9 
, ty.Active 
, ty.ReActive 
, ty.New 
, ty.STOrds 
, ty.ord_value 
, ty.AnnualProg 
, ty.SeasonalProg 
, ty.RXEProg 
, ty.AspireProg
, ty.id4Brands 
, ty.IncreaseDol 
, ty.IncreasePct 
, ty.RXPct
, ty.GrossSTY
, ty.RetSRATY 
, ty.RetPct 
, ty.Door500 
, ty.NetsTY 
, ty.netsty_goal
,ty.RXs 
,ty.NetsLY 
,ty.TerrGoal 
,ty.TerrGoalPCT 
,ty.activeretaincnt 
,ty.door500retaincnt 
,ty.activeretainvalue 
,ty.door500retainvallue
,ty.Veteran_status
, ActiveRetentionPct = CASE WHEN ly.active = 0 THEN 0
	ELSE  
	-CAST(1.00 - (CASE WHEN ISNULL(cast (ly.active AS FLOAT),0.00) = 0.00 THEN 1.00 
							ELSE ISNULL(CAST(ty.active AS FLOAT),0.00) / ISNULL(CAST(ly.active AS FLOAT),1.00) END) AS DECIMAL(20,8))
	END
, SlowRetentionPct = CASE WHEN ly.Door500 = 0 THEN 0
	else
	-CAST( 1.00 - (CASE WHEN ISNULL(CAST(ty.door500 AS FLOAT),0.00) = 0.00 THEN 1.00
					ELSE ISNULL(CAST(ty.door500 AS FLOAT),0.00) / ISNULL(CAST(ly.door500 AS FLOAT),1.00) END) AS DECIMAL(20,8))
	end
, ActiveTY = ty.Active
, ActiveLY = ly.Active
, Door500TY = ty.Door500
, Door500LY = ly.Door500
, 'TY' as tyly 
From #report_ty ty
LEFT OUTER JOIN #report_ly ly ON ty.terr = ly.terr
union all
select 
 Region 
,Terr 
, Salesperson 
, date_of_hire 
, ClassOf
, Status 
, PC
, Top9
, Active 
, ReActive 
, New 
, STOrds 
, ord_value
,AnnualProg 
,SeasonalProg 
,RXEProg 
,AspireProg
,id4Brands 
,IncreaseDol 
,IncreasePct 
,RXPct
,GrossSTY
,RetSRATY 
,RetPct 
,Door500 
,NetsTY 
,netsty_goal
,RXs 
,NetsLY
,TerrGoal 
,TerrGoalPCT
,activeretaincnt 
,door500retaincnt
,activeretainvalue =0
,door500retainvallue = 0
,Veteran_status
,ActiveRetentionPct = 0.00
,SlowRetentionPct = 0.00
,ActiveTY = 0
,ActiveLY = 0
,Door500TY = 0
,Door500LY = 0
,'LY' as tyly 
FROM #report_LY

end

GO
