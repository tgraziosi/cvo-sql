SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Elizabeth LaBarbera
-- Create date: 11/7/2013
-- Description:	Sales Data for Driver
-- EXEC cvo_salesdriver_sp '20201','2013',11
-- =============================================
CREATE PROCEDURE [dbo].[cvo_salesdriver_sp] 
	-- Add the parameters for the stored procedure here
	@Territory nvarchar(5), 
	@Year nvarchar(4),
	@Month nvarchar(2)
AS
BEGIN
	SET NOCOUNT ON;

--DECLARE @Territory varchar(5)
--DECLARE @Year varchar(4)
--DECLARE @Month varchar(2)
--SET @Territory = '20201'
--SET @Year = '2013'
--SET @Month = 11

IF(OBJECT_ID('tempdb.dbo.#DATA') is not null)  drop table #DATA
Select * into #DATA FROM (
Select territory,otype,year,X_MONTH,asales,anet,areturns,Region,yyyymmdd,Salesperson_name,0 as goal_amt
,CASE WHEN X_MONTH IN(1,2,3) THEN 1
WHEN X_MONTH IN(4,5,6) THEN 2
WHEN X_MONTH IN(7,8,9) THEN 3
ELSE 4 END AS Quarter
,Row_Number() over(partition by territory,year,X_MONTH order by territory,year,X_MONTH ) AS Rank,
(select date_of_hire from arsalesp AR where AR.territory_code=@Territory and status_type='1') AS date_of_hire
From
(
SELECT  cs.territory,cs.otype,DatePart(yy,yyyymmdd) As year,DatePart(mm,yyyymmdd) As X_MONTH, cs.asales,cs.anet,cs.areturns,dbo.calculate_region_fn(cs.territory) AS Region
,cs.yyyymmdd,(Select Salesperson_name From arsalesp Where territory_code =cs.territory AND status_type = 1)AS Salesperson_name
FROM  cvo_tsbm_daily AS cs
)A
left join cvo_territory_goal AS tg ON A.territory = tg.territory_code AND A.year = tg.yyear AND A.X_MONTH = tg.mmonth 
where  territory IN (@Territory)
AND year IN (@Year,@Year-1) 
--AND  X_MONTH IN (@Month) 
	UNION ALL
SELECT territory_code AS Territory, 'GOAL' AS otype, yyear AS year, mmonth AS X_MONTH, 0 AS asales, 0 AS anet, 0 AS areturns, dbo.calculate_region_fn(territory_code) AS Region, CAST(mmonth AS varchar(2)) + '/1/' + CAST(yyear AS varchar(4)) AS yyyymmdd, 
(Select Salesperson_name From arsalesp Where territory_code =@Territory AND status_type = 1)AS Salesperson_name, goal_amt, 
CASE WHEN mmonth IN (1, 2, 3) THEN 1 
	WHEN mmonth IN (4, 5, 6) THEN 2 
	WHEN mmonth IN (7, 8, 9) THEN 3 ELSE 4 END AS Quarter, 999 AS rank,
(SELECT date_of_hire FROM arsalesp AS AR  WHERE (territory_code = @Territory) AND (status_type = '1')) AS date_of_hire
FROM cvo_territory_goal
WHERE yyear IN (@Year, @Year - 1)
--AND  mmonth IN (@Month) 
) tmp
order by territory,year,X_MONTH,rank 

select * from #DATA

END
GO
