SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[cvo_sc_ra_forgive_detail_sp] (@fiscal_period VARCHAR(8)) 
AS

BEGIN

-- execute cvo_sc_ra_forgive_detail_sp '09/2017'

-- compares credits individually select to forgive and historic return rate vs current return rate to add back the more favorable amount to the rep.

SET NOCOUNT ON;
SET ANSI_WARNINGS OFF;

-- part 1 - forgive based on relative return rate

-- DECLARE @terr VARCHAR(10), @fiscal_period VARCHAR(8);
DECLARE @st DATETIME ,
        @enddate DATETIME;
DECLARE @year INT, @month int

--SELECT @st = DATEADD(MONTH, -6, EndDate) ,
--       @enddate = EndDate
--FROM   dbo.cvo_date_range_vw AS drv
--WHERE  Period = 'rolling 12 ty';
--SELECT @st = '6/19/2017' ,
--       @enddate = '11/30/2017';

--SELECT @st = a.date_of_hire, @enddate = DATEADD(MONTH,6,a.date_of_hire)
--FROM dbo.arsalesp AS a
--WHERE A.status_type = 1 AND a.territory_code = @terr

--SELECT @st = DATEADD(MONTH, -6, EndDate) ,
--       @enddate = EndDate
--FROM   dbo.cvo_date_range_vw AS drv
--WHERE  Period = 'Last Quarter';

--SELECT @year = YEAR(@enddate), @month = MONTH(@enddate), @fiscal_period = RIGHT('00' + CAST(MONTH(@enddate) AS VARCHAR(2)), 2) + '/'
--                + CAST(YEAR(@enddate) AS VARCHAR(4));

-- SELECT @fiscal_period

SELECT @year = CAST(RIGHT(@fiscal_period, 4) AS INT), @month = CAST(LEFT(@fiscal_period,2) AS INT)

-- part 2 - forgive based on specific returns RA with POMs.  One/customer for the entire forgiveness period

SELECT cbwt.Salesperson,
       cbwt.Territory,
       cbwt.Cust_code,
       cbwt.Ship_to,
       cbwt.Name,
       cbwt.Order_no,
       cbwt.Ext,
       cbwt.Invoice_no,
       cbwt.InvoiceDate_dt InvoiceDate,
       cbwt.DateShipped_dt DateShipped,
       cbwt.OrderType,
       cbwt.Promo_id,
       cbwt.Level,
       cbwt.type,
       cbwt.Net_Sales,
       cbwt.Brand,
       cbwt.Amount,
       cbwt.Comm_pct,
       cbwt.Comm_amt,
       cbwt.salesperson_name,
       cbwt.HireDate,
       cbwt.fiscal_period,
       cbwt.added_date,
       cbwt.added_by,
       srf.comm_amt comm_amt_forgive,
       srf.RA_amount,
       srf.pom_amount,
       srf.forgive_me
FROM dbo.cvo_commission_bldr_work_tbl AS cbwt
LEFT OUTER JOIN dbo.cvo_sc_ra_forgiveness AS srf ON srf.Order_no = cbwt.Order_no AND srf.Ext = cbwt.Ext AND srf.Salesperson = cbwt.Salesperson
WHERE cbwt.fiscal_period <= @fiscal_period
AND cbwt.OrderType LIKE 'st%'
AND cbwt.OrderType NOT LIKE '%-RB'
AND 'Yes' = ISNULL(srf.forgive_me,'No')
AND EXISTS (SELECT 1 FROM dbo.cvo_sc_ra_forgiveness AS srf2 WHERE srf2.Salesperson = cbwt.Salesperson)


END


GRANT EXECUTE ON cvo_sc_ra_forgive_detail_sp TO PUBLIC


GO
GRANT EXECUTE ON  [dbo].[cvo_sc_ra_forgive_detail_sp] TO [public]
GO
