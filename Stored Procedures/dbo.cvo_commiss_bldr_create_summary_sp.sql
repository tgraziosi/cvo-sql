SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE  PROCEDURE [dbo].[cvo_commiss_bldr_create_summary_sp] (@fiscalPeriod VARCHAR(10) =  NULL, @slp VARCHAR(10) = null )
AS 

SET NOCOUNT ON;

-- exec cvo_commiss_bldr_create_summary_sp '08/2016', '50531'
-- exec dbo.cvo_commission_bldr_sp '12/01/2015', '12/31/2015'
-- SELECT * FROM cvo_commission_summary_work_tbl AS ccswt where salesperson = '50531'
-- update v set v.rep_code = slp.salesperson_code
	-- From cvo_commission_promo_values v
	--LEFT OUTER JOIN arsalesp slp ON slp.salesperson_name = v.rep_code
-- select * From cvo_commission_promo_values 

DECLARE @start_date DATETIME, @end_date DATETIME, @fp VARCHAR(10), @drawweeks INT, @pfp VARCHAR(10)

select @fp = @fiscalperiod

-- SELECT @fp = '12/2015'

SELECT @start_date = CAST(left(@fp,2) AS VARCHAR(2))+'/1/'+CAST(right(@fp,4) AS VARCHAR(4))

SELECT @end_date = DATEADD(d,-1,DATEADD(m,1,@start_date))

SELECT @drawweeks = dbo.cvo_draw_weeks(@start_date, @end_date)

SELECT @pfp = RIGHT('00'+CAST(MONTH(DATEADD(d,-1,@start_date)) AS VARCHAR(2)),2) + '/' + RIGHT('0000'+CAST(YEAR(DATEADD(d,-1,@start_date)) AS VARCHAR(4)),4)

-- SELECT @start_date, @end_date, @drawweeks


-- drop table dbo.cvo_commission_summary_work_tbl

IF(OBJECT_ID('dbo.cvo_commission_summary_work_tbl') is null)
BEGIN
	CREATE TABLE [dbo].[cvo_commission_summary_work_tbl](
		[id] [INT] IDENTITY(1,1) NOT NULL,
		[salesperson] [VARCHAR](50) NOT NULL,
		[salesperson_name] [VARCHAR](50) NOT NULL,
		[hiredate] [SMALLDATETIME] NULL,
		[amount] [NUMERIC](12, 2) NULL,
		[comm_amt] [NUMERIC](12, 2) NULL,
		[draw_amount] [INT] NULL,
		[draw_weeks] INT NULL,
		[commission] [NUMERIC](8, 2) NULL,
		[incentivePC] [TINYINT] NULL,
		[incentive] [NUMERIC](18, 2) NULL,
		[other_additions] [NUMERIC](18, 2) NULL,
		[reduction] [NUMERIC](18, 2) NULL,
		[addition_rsn] [VARCHAR](5000) NULL,
		[reduction_rsn] [VARCHAR](5000) NULL,
		[rep_type] [TINYINT] NULL,
		[status_type] [TINYINT] NULL,
		[territory] [CHAR](5) NULL,
		[region] VARCHAR(10) NULL,
		[total_earnings] [NUMERIC](12, 2) NULL,
		[total_draw] [NUMERIC](12, 2) NULL,
		[prior_month_bal] [NUMERIC](12, 2) NULL,
		[net_pay] [NUMERIC](12, 2) NULL,
		[report_month] [VARCHAR](50) NULL,
		[current_flag] [CHAR](1) NULL,
		[promo_detail] [VARCHAR](5000) NULL,
		[promo_sum] [NUMERIC](12, 2) NULL


	) ON [PRIMARY]
	CREATE CLUSTERED INDEX [pk_commis_summary_tbl] ON [dbo].[cvo_commission_summary_work_tbl]
	(
		[salesperson] ASC,
		[territory] ASC,
		[report_month] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF
	, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
end

IF EXISTS (SELECT 1 FROM cvo_commission_summary_work_tbl AS ccswt WHERE ccswt.report_month = @fp AND ccswt.salesperson = ISNULL(@slp,ccswt.salesperson))
		   DELETE FROM cvo_commission_summary_work_tbl WHERE report_month = @fp AND salesperson = ISNULL(@slp,salesperson)

insert into cvo_commission_summary_work_tbl
(salesperson, salesperson_name, territory, region, hiredate
, amount, comm_amt, draw_amount, draw_weeks, total_draw
, prior_month_bal
, commission, incentivePC, incentive,
other_additions, reduction, addition_rsn, reduction_rsn,
report_month,
rep_type, status_type, promo_detail, promo_sum)

select a.Salesperson ,
       r.salesperson_name ,
	   r.territory_code,
	   dbo.calculate_region_fn(r.territory_code) region,
       dbo.adm_format_pltdate_f(r.date_hired) hiredate ,
       a.amount ,
	   a.comm_amt
	   , ISNULL(draw_over.draw_amount, ISNULL( r.draw_amount,0 )) draw_amount
	   , ISNULL(draw_over.qty, @drawweeks) drawweeks
	   , total_draw = ISNULL(draw_over.draw_amount, ISNULL( r.draw_amount,0 )) * ISNULL(draw_over.qty, @drawweeks)
	   --, pfp.net_pay, pfphist.net_pay
	   , prior_month_bal = CASE WHEN pfphist.net_pay IS NULL OR pfphist.net_pay = 0 THEN ISNULL(pfp.net_pay,0)
							ELSE pfphist.net_pay
						   end
	   , commission = case WHEN ISNULL(r.commission,0) IN (0,12) THEN 12 ELSE r.commission end, 
	   -- 11/8/2016 - empty territories don't get incentives :)
	incentivePC = case when (ISNULL(r.commission,0) IN (0, 12) OR r.salesperson_code IN ('WitteBu','OhlhauTh')) AND r.salesperson_code <> r.territory_code
					then case when amount >= 60000 then 2
						 when amount >= 50000 then 1
						 else 0 end
					else 0 end,
	incentive = case when (ISNULL(r.commission,0) in (0, 12) OR r.salesperson_code IN ('WitteBu','OhlhauTh')) AND r.salesperson_code <> r.territory_code
					then case when amount >= 60000 then amount * .02
						 when amount >= 50000 then amount * .01
						 else 0 end
					else 0 END
    , addition_details.addition_sum
	, deduction_details.deduction_sum
	, addition_details.addition_details
	, deduction_details.deduction_details
	, a.fiscal_period
	, r.salesperson_type, r.status_type
	, promo_details.promo_details
	, promo_details.promo_sum
from 

	(select salesperson
		, fiscal_period
		-- , CONVERT(money,SUM(amount)) amount
		, CONVERT(money,SUM(net_sales)) amount -- 9/12/2016
		, convert(money,SUM(comm_amt)) comm_amt 
	from cvo_commission_bldr_work_tbl
	WHERE fiscal_period = @fp
	AND Salesperson = ISNULL(@slp, Salesperson)
	GROUP BY Salesperson
			,fiscal_period) a
	JOIN arsalesp r ON r.salesperson_code = a.Salesperson
	LEFT OUTER JOIN -- prior month balance to roll forward, if any
    (SELECT salesperson,
		ccswt.report_month,
		ccswt.net_pay
		FROM dbo.cvo_commission_summary_work_tbl AS ccswt
		WHERE ccswt.report_month = @pfp
		AND ccswt.salesperson = ISNULL(@slp,ccswt.salesperson)
		AND ccswt.net_pay <= 0
	) pfp ON pfp.salesperson = a.salesperson
	LEFT OUTER JOIN -- prior month balance to roll forward, if any
    (SELECT salesperson,
		ccswt.report_month,
		ccswt.net_pay
		FROM dbo.cvo_commission_history_tbl AS ccswt
		WHERE ccswt.report_month = @pfp
		AND ccswt.salesperson = ISNULL(@slp,ccswt.salesperson)
		AND ccswt.net_pay <= 0
	) pfphist ON pfphist.salesperson = a.salesperson
	LEFT OUTER JOIN -- promo/incentive information
    (SELECT ccpv.rep_code , 
		STUFF(( SELECT DISTINCT '; ' + ccpv2.comments 
				FROM dbo.cvo_commission_promo_values AS ccpv2
				WHERE ccpv2.rep_code = ccpv.rep_code AND ccpv2.recorded_month = @fp
					AND ISNULL(ccpv2.line_type,'') NOT LIKE '%adj 3%'
					AND ISNULL(ccpv2.line_type,'') <> 'special payment'
					AND ccpv2.incentive_amount > 0
				FOR XML PATH ('')
				), 1, 1, '') promo_details
				, SUM(ccpv.incentive_amount) promo_sum
        FROM dbo.cvo_commission_promo_values AS ccpv
		WHERE ccpv.recorded_month = @fp 
		AND ccpv.rep_code = ISNULL(@slp,ccpv.rep_code)
		AND ISNULL(ccpv.line_type,'')  NOT LIKE  '%adj 3%'
		AND ISNULL(ccpv.line_type,'') <> 'special payment'
		AND ccpv.incentive_amount > 0
		GROUP BY ccpv.rep_code
	) promo_details ON (promo_details.rep_code = a.salesperson OR promo_details.rep_code = r.salesperson_name)
		LEFT OUTER JOIN -- other additions nformation
    (SELECT ccpv.rep_code , 
		STUFF(( SELECT DISTINCT '; ' + ISNULL(ccpv2.comments ,'')
				FROM dbo.cvo_commission_promo_values AS ccpv2
				WHERE ccpv2.rep_code = ccpv.rep_code 
				AND ccpv2.recorded_month = @fp
				AND ccpv2.rep_code = ISNULL(@slp,ccpv2.rep_code)
				AND ISNULL(ccpv2.line_type,'') LIKE '%adj 3%'
				AND ISNULL(ccpv2.incentive_amount,0) > 0
				FOR XML PATH ('')
				), 1, 1, '') addition_details
				, SUM(ISNULL(ccpv.incentive_amount,0)) addition_sum
        FROM dbo.cvo_commission_promo_values AS ccpv
		WHERE ccpv.recorded_month = @fp 
		AND ccpv.rep_code = ISNULL(@slp, ccpv.rep_code)
		AND ISNULL(ccpv.incentive_amount,0) > 0 
		AND ISNULL(ccpv.line_type,'') LIKE '%adj 3%'
		GROUP BY ccpv.rep_code
	) addition_details ON addition_details.rep_code = a.salesperson OR addition_details.rep_code = r.salesperson_name
		LEFT OUTER JOIN -- other deductions information
    (SELECT ccpv.rep_code , 
		STUFF(( SELECT DISTINCT '; ' + ccpv2.comments 
				FROM dbo.cvo_commission_promo_values AS ccpv2
				WHERE ccpv2.rep_code = ccpv.rep_code 
				AND ccpv2.recorded_month = @fp
				AND ccpv2.territory = ISNULL(@slp, ccpv2.territory)
				AND ISNULL(ccpv2.line_type,'') LIKE '%reduction%'
				FOR XML PATH ('')
				), 1, 1, '') deduction_details
				, SUM(ccpv.incentive_amount) deduction_sum
        FROM dbo.cvo_commission_promo_values AS ccpv
		WHERE ccpv.recorded_month = @fp 
		AND ccpv.incentive_amount < 0 
		AND ISNULL(line_type,'') like '%manual reduction%'
		GROUP BY ccpv.rep_code
	) deduction_details ON deduction_details.rep_code = a.salesperson OR deduction_details.rep_code = r.salesperson_name
		LEFT OUTER JOIN -- draw overrides
    (SELECT ccpv.rep_code, SUM(ccpv.qty) qty, SUM(ccpv.incentive_amount) draw_amount
        FROM dbo.cvo_commission_promo_values AS ccpv
		WHERE ccpv.recorded_month = @fp 
		AND ISNULL(line_type,'') IN ('Draw_Over') 
		GROUP BY ccpv.rep_code
	) draw_over ON draw_over.rep_code = a.salesperson 



UPDATE d SET 
		total_earnings = comm_amt + incentive + ISNULL(other_additions,0) + ISNULL(d.promo_sum,0), -- remove 2/14 per MB -- + ISNULL(reduction,0),
		net_pay = comm_amt + incentive + ISNULL(other_additions,0) + ISNULL(d.promo_sum,0) + ISNULL(reduction,0) 
				  + total_draw + prior_month_bal
		FROM dbo.cvo_commission_summary_work_tbl d
		WHERE d.report_month = @fp
		AND d.salesperson = ISNULL(@slp, d.salesperson)

-- SELECT * FROM dbo.cvo_commission_summary_work_tbl AS ccswt where report_month = '09/2016'


















GO
GRANT EXECUTE ON  [dbo].[cvo_commiss_bldr_create_summary_sp] TO [public]
GO
