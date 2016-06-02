SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[cvo_commission_statement_sp] @FiscalPeriod VARCHAR(10)
AS 

-- exec cvo_commission_statement_sp '01/2016'

SET NOCOUNT ON;

BEGIN

DECLARE @start_date DATETIME, @end_date DATETIME, @fp VARCHAR(10), @drawweeks INT, @year int, @prior_year INT, @month int

--DECLARE @fiscalperiod VARCHAR(10)
-- SELECT @fiscalperiod = '01/2016'
SELECT @fp = @fiscalperiod

SELECT @start_date = CAST(left(@fp,2) AS VARCHAR(2))+'/1/'+CAST(right(@fp,4) AS VARCHAR(4))

SELECT @end_date = DATEADD(d,-1,DATEADD(m,1,@start_date))

SELECT @year = CAST(RIGHT(@fp,4)  AS INT), @month = CAST(LEFT(@fp,2) AS int)

SELECT @prior_year = @year - 1

-- SELECT @fp, @start_date, @end_date, @year, @prior_year

IF(OBJECT_ID('tempdb.dbo.#mm') is not null)  drop table #mm

CREATE TABLE #mm 
	(salesperson VARCHAR(20),
	 salesperson_name VARCHAR(50),
	 territory VARCHAR(5) ,
	 region VARCHAR(5),
	 mm varchar(2)
	)

DECLARE @i INT
SELECT @i = 1

WHILE @i < 13
begin
	INSERT #mm
			( salesperson, salesperson_name, territory, region, mm )
	SELECT DISTINCT salesperson, salesperson_name, ccswt.territory, 
					dbo.calculate_region_fn(ccswt.territory) region, 
					RIGHT('00'+CAST(@i AS VARCHAR(2)),2) mm
	 from dbo.cvo_commission_summary_work_tbl AS ccswt
	 SELECT @i = @i + 1
end

SELECT ty.id ,
       #mm.salesperson,
	   #mm.salesperson_name,
       ty.hiredate ,
       ISNULL(ty.amount,0) amount ,
       ISNULL(ty.comm_amt,0) comm_amt ,
       ISNULL(ty.draw_amount,0) draw_amount ,
       ty.draw_weeks ,
       ISNULL(ty.commission,0) commission ,
       ISNULL(ty.incentivePC,0) incentivePC ,
       ISNULL(ty.incentive,0) incentive ,
       ISNULL(ty.other_additions,0) other_additions ,
       ISNULL(ty.reduction, 0) reduction ,
       ISNULL(ty.addition_rsn,'') addition_rsn ,
       ISNULL(ty.reduction_rsn,'') reduction_rsn ,
       ISNULL(ty.rep_type,0) rep_type ,
       ISNULL(ty.status_type,0) status_type ,
       #mm.territory territory ,
       #mm.region region ,
       CASE WHEN ISNULL(tyhist.total_earnings,0) <> 0 THEN tyhist.total_earnings 
			ELSE ISNULL(ty.total_earnings,0) END AS total_earnings ,
       ISNULL(ty.total_draw,0) total_draw ,
       ISNULL(ty.prior_month_bal,0) prior_month_bal ,
       ISNULL(ty.net_pay,0) net_pay ,
       ty.report_month ,
       ty.current_flag ,
       ISNULL(ty.promo_detail,'') promo_detail ,
       ISNULL(ty.promo_sum,0) promo_sum,
	   #mm.mm month_num,
	   @prior_year year_ly,
	   CASE WHEN ISNULL(lyhist.total_earnings,0) <>0 THEN lyhist.total_earnings
			ELSE ISNULL(ly.total_earnings,0) END AS total_earnings_ly
	   FROM
       #mm 
      
	   LEFT OUTER JOIN
(
SELECT       id, salesperson, hiredate, amount, comm_amt, draw_amount, draw_weeks, commission
			, incentivePC, incentive, other_additions, reduction, 
                  addition_rsn, reduction_rsn, rep_type, status_type, 
				  territory, region, 
				  total_earnings, total_draw, 
				  prior_month_bal, net_pay, report_month, current_flag, 
                  promo_detail, promo_sum
FROM         cvo_commission_summary_work_tbl
WHERE        @year = CAST(RIGHT(report_month, 4) AS INT)
			 AND @month > = CAST(LEFT(report_month,2) AS int)
) ty ON ty.salesperson = #mm.salesperson AND #mm.mm = LEFT(ty.report_month,2)

LEFT OUTER JOIN
(
 SELECT c.salesperson, LEFT(c.report_month,2) month_num, c.total_earnings
 FROM cvo_commission_history_tbl c
 WHERE CAST(RIGHT(c.report_month,4) AS int) = @year
 	   AND @month > = CAST(LEFT(report_month,2) AS int)
) tyhist ON #mm.salesperson = tyhist.salesperson AND #mm.mm = tyhist.month_num


LEFT OUTER JOIN

( SELECT c.salesperson, LEFT(c.report_month,2) month_num, ISNULL(total_earnings,0) total_earnings
 FROM cvo_commission_summary_work_tbl c
 WHERE CAST(right(c.report_month,4) AS INT) = @prior_year
) ly ON #mm.salesperson = ly.salesperson AND #mm.mm = ly.month_num

LEFT OUTER JOIN

(
SELECT c.salesperson, LEFT(c.report_month,2) month_num, c.total_earnings
 FROM cvo_commission_history_tbl c
 WHERE CAST(RIGHT(c.report_month,4) AS int) = @prior_year
) lyhist ON #mm.salesperson = lyhist.salesperson AND lyhist.month_num = #mm.mm



ORDER BY salesperson


END


GO
GRANT EXECUTE ON  [dbo].[cvo_commission_statement_sp] TO [public]
GO
