SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[cvo_commiss_bldr_create_summary_sp] (@fiscalPeriod VARCHAR(10) =  NULL )
AS 

DECLARE @start_date DATETIME, @end_date DATETIME, @fp VARCHAR(10), @drawweeks int

-- select @fp = @fiscalperiod

SELECT @fp = '12/2015'

SELECT @start_date = CAST(LEFT(@fp,2) AS VARCHAR(2))+'/1/'+CAST(RIGHT(@fp,4) AS VARCHAR(4))
SELECT @end_date = DATEADD(d,-1,DATEADD(m,1,@start_date))

SELECT @drawweeks = dbo.cvo_draw_weeks(@start_date, @end_date)

SELECT @start_date, @end_date, @drawweeks


-- drop table #cvo_commission_summary_work_tbl

IF(OBJECT_ID('#cvo_commission_summary_work_tbl') is null)
BEGIN
CREATE TABLE #cvo_commission_summary_work_tbl
	(
	[id] [int] IDENTITY(1,1) PRIMARY key,
	[salesperson] [varchar](50) NOT NULL,
	[salesperson_name] [varchar](50) NOT NULL,
	[territory_code] VARCHAR(12) NOT NULL,
	[hiredate] [smalldatetime] NULL,
	[amount] [numeric](12, 2) NULL,
	[comm_amt] [numeric](12, 2) NULL,
	[draw_amount] [int] NULL,
	[commission] [numeric](8, 2) NULL,
	-- from other table that I don't have
	[incentivePC] [tinyint] NULL,
	[incentive] [numeric](18, 2) NULL,
	[other_additions] [numeric](18, 2) NULL,
	[reduction] [numeric](18, 2) NULL,
	[addition_rsn] [varchar](max) NULL,
	[reduction_rsn] [varchar](max) NULL,
	[fiscal_period] VARCHAR(10) NULL,
	[draw_weeks] INT null

) 

TRUNCATE TABLE #cvo_commission_summary_work_tbl


insert into #cvo_commission_summary_work_tbl
(salesperson, salesperson_name, territory_code, hiredate, amount, comm_amt, draw_amount, commission, incentivePC, incentive,
fiscal_period, draw_weeks)
select a.Salesperson ,
       r.salesperson_name ,
	   r.territory_code,
       dbo.adm_format_pltdate_f(r.date_hired) hiredate ,
       a.amount ,
       a.comm_amt
	   , r.draw_amount 
	   , commission = case WHEN ISNULL(r.commission,0) IN (0,12) THEN 12 ELSE r.commission end, 
	incentivePC = case when ISNULL(r.commission,0) IN (0, 12) 
					then case when amount >= 60000 then 2
						 when amount >= 50000 then 1
						 else 0 end
					else 0 end,
	incentive = case when ISNULL(r.commission,0) in (0, 12) 
					then case when amount >= 60000 then amount * .02
						 when amount >= 50000 then amount * .01
						 else 0 end
					else 0 end
	, a.fiscal_period
	, @drawweeks

from 
	(select salesperson, fiscal_period, 
		convert(money,SUM(amount)) amount, convert(money,SUM(comm_amt)) comm_amt 
	from cvo_commission_bldr_work_tbl
	WHERE fiscal_period = @fp
	GROUP BY Salesperson ,
         fiscal_period) a
	JOIN arsalesp r ON r.salesperson_code = a.Salesperson

end

SELECT * FROM #cvo_commission_summary_work_tbl AS ccswt

GO
GRANT EXECUTE ON  [dbo].[cvo_commiss_bldr_create_summary_sp] TO [public]
GO
