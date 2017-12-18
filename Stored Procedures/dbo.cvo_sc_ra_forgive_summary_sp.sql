SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[cvo_sc_ra_forgive_summary_sp] (@fiscal_period VARCHAR(8)) 
AS

BEGIN

-- execute cvo_sc_ra_forgive_summary_sp '09/2017'

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

IF ( OBJECT_ID('tempdb.dbo.#ts') IS NOT NULL )
    DROP TABLE #ts;

	
IF ( OBJECT_ID('tempdb.dbo.#tssummary') IS NOT NULL )
    DROP TABLE #tssummary;

CREATE TABLE #ts
    (
        region VARCHAR(3) ,
        manager_name VARCHAR(40) ,
        territory_code VARCHAR(8) ,
        salesperson_name VARCHAR(40) ,
        x_month INT ,
        year INT ,
        ytdty_netsales FLOAT(8) ,
        ytdty_bep FLOAT(8) ,
        ytdty_netret FLOAT(8) ,
        ytdty_wtyret FLOAT(8) ,
        ytdty_excret FLOAT(8) ,
        ytdly_netsales FLOAT(8) ,
        ytdly_bep FLOAT(8) ,
        ytdly_netret FLOAT(8) ,
        ytdly_wtyret FLOAT(8) ,
        ytdly_excret FLOAT(8) ,
        NetReturns FLOAT(8) ,
        NetReturns_wty FLOAT(8) ,
        NetReturns_Exc FLOAT(8) ,
        NetSales FLOAT(8) ,
        BEP_Sales FLOAT(8)
    );

-- SELECT * FROM dbo.cvo_date_range_vw AS drv

INSERT #ts 
EXEC dbo.cvo_tsbm_summary_sp @year, @month
;

SELECT hist.territory_code,
		SUM(hist.NetSales) NetSales,
       SUM(hist.NetReturns) NetReturns,
       AVG(hist.hist_RA_pct) hist_RA_pct,
	   CAST(0 AS FLOAT) curr_ra_pct
INTO     #tssummary
FROM 
(SELECT   territory_code ,
		 [YEAR] histyear,
         SUM(NetSales) NetSales ,
         SUM(NetReturns) NetReturns,
		 hist_RA_pct = CASE WHEN sum(netsales) <> 0 
						THEN SUM(netreturns)/SUM(netsales) ELSE 0 END
		 FROM     #ts
WHERE	 #ts.[year] = @year-2 OR #ts.[year] = @year-1
GROUP BY territory_code, [year]
) hist
GROUP BY hist.territory_code
;

UPDATE s SET s.curr_ra_pct = tt.curr_ra_pct
FROM #tssummary s JOIN 
(
SELECT territory_code, CASE WHEN SUM(t.netsales)+sum(netreturns) <>0
					THEN SUM(t.netreturns)/(SUM(t.netsales)+SUM(netreturns)) ELSE 0 END curr_ra_pct
FROM #ts AS t
WHERE t.year = @year AND t.x_month = @month
GROUP BY t.territory_code
) tt ON tt.territory_code = s.territory_code;


-- SELECT * FROM #ts AS t

DROP TABLE #ts;

--SELECT t.territory_code,
--       t.NetSales,
--       t.NetReturns,
--       t.RA_pct FROM #tssummary AS t

-- part 2 - forgive based on specific returns RA with POMs.  One/customer for the entire forgiveness period


IF ( OBJECT_ID('tempdb.dbo.#cb') IS NOT NULL )
    DROP TABLE #cb;

SELECT cbwt.Salesperson,
       cbwt.Territory,
       cbwt.Cust_code,
       cbwt.Ship_to,
       cbwt.Name,
       cbwt.Order_no,
       cbwt.Ext,
       cbwt.Invoice_no,
       cbwt.InvoiceDate,
       cbwt.DateShipped,
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
       CASE WHEN srf.forgive_me = 'yes' THEN srf.comm_amt ELSE 0 end comm_amt_forgive,
       srf.RA_amount,
       srf.pom_amount,
       srf.forgive_me
INTO #cb
FROM dbo.cvo_commission_bldr_work_tbl AS cbwt
LEFT OUTER JOIN dbo.cvo_sc_ra_forgiveness AS srf ON srf.Order_no = cbwt.Order_no AND srf.Ext = cbwt.Ext AND srf.Salesperson = cbwt.Salesperson
WHERE cbwt.fiscal_period <= @fiscal_period
AND cbwt.OrderType LIKE 'st%'
AND cbwt.OrderType NOT LIKE '%-RB'
-- AND 'Yes' = ISNULL(srf.forgive_me,'No')
AND EXISTS (SELECT 1 FROM dbo.cvo_sc_ra_forgiveness AS srf2 WHERE srf2.Salesperson = cbwt.Salesperson)



SELECT   t.territory_code ,
		 #cb.Salesperson,
		 @fiscal_period fiscal_period,
         SUM(CASE WHEN #cb.type = 'inv' THEN ISNULL(Amount,0)
                  ELSE 0
             END) invoice_amount ,
		 SUM(CASE WHEN #cb.type = 'crd' THEN ISNULL(amount,0) ELSE 0 END) credit_amount,
         SUM(ISNULL(CASE WHEN forgive_me = 'yes' THEN RA_amount ELSE 0 end,0)) srf_ra_amount ,
         SUM(ISNULL(CASE WHEN forgive_me = 'yes' THEN pom_amount ELSE 0 end,0)) srf_pom_amount ,
         SUM(ISNULL(comm_amt_forgive,0)) srf_forgive_comm ,
         t.hist_RA_pct hist_ra_pct ,
		 t.curr_ra_pct curr_ra_pct,
 		 --CASE WHEN SUM(CASE WHEN #cb.type = 'inv' THEN amount ELSE 0 end) = 0 THEN 0 else
    --     SUM(CASE WHEN #cb.type = 'crd' THEN ISNULL(amount,0) ELSE 0 END) / SUM(CASE WHEN #cb.type = 'inv' THEN Amount
    --                               ELSE 0
    --                          END) END *-1 curr_ra_pct,
		 MAX(Comm_pct)/100 curr_comm_pct
FROM     #cb
         JOIN #tssummary AS t ON t.territory_code = #cb.Territory
		 WHERE #cb.fiscal_period = @fiscal_period
GROUP BY t.territory_code,
         Salesperson,
         t.hist_RA_pct,
		 t.curr_ra_pct
HAVING SUM(ISNULL(ra_amount,0)) <> 0
;

END


GRANT EXECUTE ON cvo_sc_ra_forgive_summary_sp TO PUBLIC



GO
GRANT EXECUTE ON  [dbo].[cvo_sc_ra_forgive_summary_sp] TO [public]
GO
