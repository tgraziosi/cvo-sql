SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Tine Graziosi - CVO
-- Create date: 6/1/2012
-- Description:	Sales Detail By Day - for Reporting
-- =============================================
-- exec [dbo].[CVO_sbm_details_sp]
-- select asales, areturns, lsales, * from cvo.dbo.cvo_sbm_details where iscl = 1 -- order by customer, ship_to, month 
-- select * From tempdb.dbo.#cvo_sbm_det
/*
select sum(asales), sum(areturns), sum(qsales), sum(qreturns),sum(anet), sum(lsales),
sum(csales) from cvo_sbm_details --  WHERE c_year = 2017

select sum(asales), sum(areturns), sum(qsales), sum(qreturns),sum(anet), sum(lsales),
sum(csales) from cvo_sbm_details --  WHERE c_year = 2017

select lsales, round(lsales,2), * From cvo_sbm_details where round(lsales,2) <> lsales

select * from cvo_sbm_details where part_No = 'bcgcolink5316'
select sum(asales), sum(areturns), sum(qsales), sum(qreturns) from cvo_csbm_shipto_daily  WHERE CUSTOMER = '011111'
*/
--select sum(asales), sum(areturns), sum(qsales), sum(qreturns) from cvo_csbm_shipto WHERE CUSTOMER = '011111'

/* 9/5/2012 - make qty's frames and suns only, and add unposted AR */
/* 9/9/2013 - add location for DRP support */
-- 11/8/2013 - add identity column for Data Warehouse. move Drop/Create table right before insert
-- 5/2014 - add isCL and isBO indicators
-- 10/2014 - add salesperson on order/invoice for Sales Details in Cube
-- 1/2017 - don't recreate everything everytime.  set the first and last dates to refresh/add

CREATE PROCEDURE [dbo].[CVO_sbm_details_sp]
AS
BEGIN
    -- SET NOCOUNT ON added to prevent extra result sets from
    -- interfering with SELECT statements.
    SET NOCOUNT ON
    ;

    -- exec cvo_sbm_details_sp

    -- exec cvo_csbm_shipto_sp
    DECLARE @first DATETIME
    ;
    DECLARE @last DATETIME
    ;
    DECLARE @jfirst INT
    ;
    DECLARE @jlast INT
    ;

    --SELECT  @first = '1/1/2017';	-- add 09 and 10 once validated and fixed
    --SELECT  @last = '12/31/2017';

    -- change the period here to rebuild sbm_details as needed
    SELECT
        @first = BeginDate, @last = EndDate
    FROM dbo.cvo_date_range_vw AS drv
    WHERE Period = 'Last 90 days'
    ;

    SELECT @jfirst = dbo.adm_get_pltdate_f(@first)
    ;

    SELECT @jlast = dbo.adm_get_pltdate_f(@last)
    ;

    IF (OBJECT_ID('tempdb.dbo.#cvo_sbm_det') IS NOT NULL)
        DROP TABLE #cvo_sbm_det
        ;


    IF (OBJECT_ID('tempdb.dbo.#cvo_sbm_det') IS NULL)
    BEGIN
        CREATE TABLE #cvo_sbm_det
        (
            customer VARCHAR(10),
            ship_to VARCHAR(10),
            part_no VARCHAR(30),
            PROMO_ID VARCHAR(20),
            promo_level VARCHAR(30),
            return_code VARCHAR(10),
            user_category VARCHAR(10),
            location VARCHAR(10), -- tag 090913
            c_month INT,
            c_year INT,
            x_month INT,
            month VARCHAR(16),
            year INT,
            asales DECIMAL(20, 6),
            areturns DECIMAL(20, 6),
            qsales DECIMAL(20, 0),
            qreturns DECIMAL(20, 0),
            csales FLOAT,
            lsales FLOAT,
            DateShipped DATETIME,
            DateOrdered DATETIME,
            isCL INT,             -- 4/25/2014 - closeout flag  0=no, 1= yes.  80% - 99% discounts should be classed as CLs
            isBO INT,             -- is this a backorder 0 = no, 1 = yes
            slp VARCHAR(10)
        )
        ;
    END
    ;


    CREATE NONCLUSTERED INDEX idx_sbm_det_tmp
    ON #cvo_sbm_det
    (
        asales,
        areturns,
        qsales,
        qreturns,
        lsales
    )
    ;


    -- load live data - use artrx to capture validated sales #

    INSERT INTO #cvo_sbm_det
    SELECT
        customer = ISNULL(xx.customer_code, ''),
        ship_to = ISNULL(xx.ship_to_code, ''),
        ISNULL(i.part_no, 'CVZPOSTAGE') AS PART_NO,
        CASE
            WHEN ol.return_code = '05-24'
                 AND co.promo_id = 'BEP' THEN
                ''
            ELSE
                ISNULL(co.promo_id, '')
        END AS promo_id,
        CASE
            WHEN ol.return_code = '05-24'
                 AND co.promo_id = 'BEP' THEN
                ''
            ELSE
                ISNULL(co.promo_level, '')
        END AS promo_level,
        ISNULL(ol.return_code, '') return_code,
        ISNULL(o.user_category, 'ST') user_category,
        ol.location,      -- tag 090913
        DATEPART(MONTH, dbo.adm_format_pltdate_f(xx.date_applied)) c_month,
        DATEPART(YEAR, dbo.adm_format_pltdate_f(xx.date_applied)) c_year,
        DATEPART(MONTH, dbo.adm_format_pltdate_f(xx.date_applied)) x_month,
        DATENAME(MONTH, dbo.adm_format_pltdate_f(xx.date_applied)) month,
        DATEPART(YEAR, dbo.adm_format_pltdate_f(xx.date_applied)) year,
        CASE o.type
            WHEN 'i' THEN
                CASE ISNULL(cl.is_amt_disc, 'n')
                    WHEN 'y' THEN
                        ROUND(ol.shipped * (ol.curr_price - ROUND(ISNULL(cl.amt_disc, 0), 2)), 2, 1)
                    ELSE
                        ROUND(ol.shipped * (ol.curr_price - ROUND(ol.curr_price * (ol.discount / 100.00), 2)), 2)
                END
            ELSE
                0
        END AS asales,
        CASE o.type
            WHEN 'c' THEN
                ROUND(ol.cr_shipped * ol.curr_price, 2)
                - ROUND(ol.cr_shipped * (ol.curr_price * (ol.discount / 100.00)),
                           2
                       )
            ELSE
                0
        END AS areturns,
        CASE
            WHEN o.type = 'i' THEN
                ol.shipped
            ELSE
                0
        END AS qsales,
        CASE
            WHEN o.type = 'c' THEN
                ol.cr_shipped
            ELSE
                0
        END AS qreturns,
                          -- add cost and list 11/12/13
        ROUND((ol.shipped - ol.cr_shipped) * (ol.cost + ol.ovhd_dolrs + ol.util_dolrs),
                 2
             ) AS csales,
        ROUND((ol.shipped - ol.cr_shipped) * cl.list_price,
                 2
             ) AS lsales,
                          --
        dbo.adm_format_pltdate_f(xx.date_applied) DateShipped,
        DATEADD(dd, DATEDIFF(dd, 0, oo.date_entered), 0) DateOrdered,
        0,                -- isCL
        CASE
            WHEN o.who_entered = 'BACKORDR' THEN
                1
            ELSE
                0
        END,              -- isBO
        o.salesperson slp -- salesperson on this order -- 100314
    FROM
        artrx xx (NOLOCK)
        INNER JOIN orders_invoice oi (NOLOCK)
            ON oi.trx_ctrl_num = xx.trx_ctrl_num
        INNER JOIN orders o (NOLOCK)
            ON o.order_no = oi.order_no
               AND o.ext = oi.order_ext
        INNER JOIN CVO_orders_all co (NOLOCK)
            ON co.order_no = o.order_no
               AND co.ext = o.ext
        INNER JOIN ord_list ol (NOLOCK)
            ON ol.order_no = o.order_no
               AND ol.order_ext = o.ext
        LEFT OUTER JOIN CVO_ord_list cl (NOLOCK)
            ON cl.order_no = ol.order_no
               AND cl.order_ext = ol.order_ext
               AND cl.line_no = ol.line_no
        LEFT OUTER JOIN
        (
            SELECT
                order_no,
                MIN(ooo.date_entered)
            FROM orders ooo (NOLOCK)
            WHERE ooo.status <> 'v'
            GROUP BY ooo.order_no
        ) AS oo(order_no, date_entered)
            ON oo.order_no = o.order_no
        -- tag 013114
        LEFT OUTER JOIN inv_master i
            ON i.part_no = ol.part_no
    WHERE
        1 = 1
        AND xx.date_applied
        BETWEEN @jfirst AND @jlast
        AND xx.trx_type IN ( 2031, 2032 )
        AND xx.doc_desc NOT LIKE 'converted%'
        AND xx.doc_desc NOT LIKE '%nonsales%'
        AND xx.doc_ctrl_num NOT LIKE 'cb%'
        AND xx.doc_ctrl_num NOT LIKE 'fin%'
        AND xx.void_flag = 0
        AND xx.posted_flag = 1
    ;


    -- unposted invoices

    INSERT INTO #cvo_sbm_det
    SELECT
        customer = ISNULL(xx.customer_code, ''),
        ship_to = ISNULL(xx.ship_to_code, ''),
        ISNULL(i.part_no, 'CVZPOSTAGE') AS PART_NO,
        CASE
            WHEN ol.return_code = '05-24'
                 AND co.promo_id = 'BEP' THEN
                ''
            ELSE
                ISNULL(co.promo_id, '')
        END AS promo_id,
        CASE
            WHEN ol.return_code = '05-24'
                 AND co.promo_id = 'BEP' THEN
                ''
            ELSE
                ISNULL(co.promo_level, '')
        END AS promo_level,
        ISNULL(ol.return_code, '') return_code,
        ISNULL(o.user_category, 'ST') user_category,
        ol.location, -- 090913 tag
        DATEPART(MONTH, dbo.adm_format_pltdate_f(xx.date_applied)) c_month,
        DATEPART(YEAR, dbo.adm_format_pltdate_f(xx.date_applied)) c_year,
        DATEPART(MONTH, dbo.adm_format_pltdate_f(xx.date_applied)) x_month,
        DATENAME(MONTH, dbo.adm_format_pltdate_f(xx.date_applied)) month,
        DATEPART(YEAR, dbo.adm_format_pltdate_f(xx.date_applied)) year,
        CASE o.type
            WHEN 'i' THEN
                CASE ISNULL(cl.is_amt_disc, 'n')
                    WHEN 'y' THEN
                        ROUND(ol.shipped * (ol.curr_price - ROUND(ISNULL(cl.amt_disc, 0), 2)), 2, 1)
                    ELSE
                        ROUND(ol.shipped * (ol.curr_price - ROUND(ol.curr_price * (ol.discount / 100.00), 2)), 2)
                END
            ELSE
                0
        END AS asales,
        CASE o.type
            WHEN 'c' THEN
                ROUND(ol.cr_shipped * ol.curr_price, 2)
                - ROUND(ol.cr_shipped * (ol.curr_price * (ol.discount / 100.00)),
                           2
                       )
            ELSE
                0
        END AS areturns,
        CASE
            WHEN o.type = 'i' THEN
                ol.shipped
            ELSE
                0
        END AS qsales,
        CASE
            WHEN o.type = 'c' THEN
                ol.cr_shipped
            ELSE
                0
        END AS qreturns,
                     -- add cost and list 11/12/13
        ROUND((ol.shipped - ol.cr_shipped) * (ol.cost + ol.ovhd_dolrs + ol.util_dolrs),
                 2
             ) AS csales,
        ROUND((ol.shipped - ol.cr_shipped) * cl.list_price,
                 2
             ) AS lsales,
                     --
        CONVERT(VARCHAR,
                   DATEADD(d,
                              xx.date_applied - 711858,
                              '1/1/1950'
                          ),
                   101
               ) DateShipped,
        ISNULL(
                  DATEADD(dd, DATEDIFF(dd, 0, oo.date_entered), 0),
                  CONVERT(VARCHAR,
                             DATEADD(d,
                                        xx.date_applied - 711858,
                                        '1/1/1950'
                                    ),
                             101
                         )
              ) AS dateOrdered,
        0,
        CASE
            WHEN o.who_entered = 'BACKORDR' THEN
                1
            ELSE
                0
        END,
        o.salesperson slp
    FROM
        arinpchg xx (NOLOCK)
        INNER JOIN orders_invoice oi (NOLOCK)
            ON oi.trx_ctrl_num = xx.trx_ctrl_num
        INNER JOIN orders o (NOLOCK)
            ON oi.order_no = o.order_no
               AND oi.order_ext = o.ext
        INNER JOIN CVO_orders_all co (NOLOCK)
            ON co.order_no = o.order_no
               AND co.ext = o.ext
        INNER JOIN ord_list ol (NOLOCK)
            ON ol.order_no = o.order_no
               AND ol.order_ext = o.ext
        LEFT OUTER JOIN CVO_ord_list cl (NOLOCK)
            ON cl.order_no = ol.order_no
               AND cl.order_ext = ol.order_ext
               AND cl.line_no = ol.line_no
        LEFT OUTER JOIN
        (
            SELECT
                order_no,
                MIN(ooo.date_entered)
            FROM orders ooo (NOLOCK)
            WHERE ooo.status <> 'v'
            GROUP BY ooo.order_no
        ) AS oo(order_no, date_entered)
            ON oo.order_no = o.order_no
        -- 013114
        LEFT OUTER JOIN inv_master i
            ON i.part_no = ol.part_no
    WHERE
        1 = 1
        AND xx.date_applied
        BETWEEN @jfirst AND @jlast
        AND xx.trx_type IN ( 2031, 2032 )
        AND xx.doc_desc NOT LIKE 'converted%'
        AND xx.doc_desc NOT LIKE '%nonsales%'
        AND xx.doc_ctrl_num NOT LIKE 'cb%'
        AND xx.doc_ctrl_num NOT LIKE 'fin%'
    ;

    -- AR Only Activity

    INSERT INTO #cvo_sbm_det
    SELECT
        h.customer_code customer,
        h.ship_to_code ship_to,
        ISNULL(i.part_no, 'CVZPOSTAGE') AS PART_NO,
                           /*case when d.item_code = '' 
	 OR NOT EXISTS (SELECT 1 FROM INV_MASTER WHERE PART_NO = D.ITEM_CODE) 
	then 'CVZPOSTAGE' ELSE D.ITEM_CODE END AS  part_no,
*/
        CASE
            WHEN CHARINDEX('-', h.order_ctrl_num) <= 1 THEN
                ''
            ELSE
                ISNULL(
                (
                    SELECT TOP 1
                        promo_id
                    FROM CVO_orders_all co
                    WHERE
                        co.order_no = LEFT(h.order_ctrl_num, CHARINDEX('-',
                                                                          h.order_ctrl_num
                                                                      ) - 1)
                        AND co.ext = 0
                ),
                          ''
                      )
        END AS promo_id,
        CASE
            WHEN CHARINDEX('-', h.order_ctrl_num) <= 1 THEN
                ''
            ELSE
                ISNULL(
                (
                    SELECT TOP 1
                        promo_level
                    FROM CVO_orders_all co
                    WHERE
                        co.order_no = LEFT(h.order_ctrl_num, CHARINDEX('-',
                                                                          h.order_ctrl_num
                                                                      ) - 1)
                        AND co.ext = 0
                ),
                          ''
                      )
        END AS promo_level,
        CASE
            WHEN h.trx_type = 2032 THEN
                '06-13'
            ELSE
                ''
        END AS return_code,
        CASE
            WHEN CHARINDEX('-', h.order_ctrl_num) <= 1 THEN
                ''
            ELSE
                ISNULL(
                (
                    SELECT TOP 1
                        user_category
                    FROM orders co
                    WHERE
                        co.order_no = LEFT(h.order_ctrl_num, CHARINDEX('-',
                                                                          h.order_ctrl_num
                                                                      ) - 1)
                        AND co.ext = 0
                ),
                          ''
                      )
        END AS user_category,
        '001' AS location, -- tag - 090913 
        DATEPART(MONTH, dbo.adm_format_pltdate_f(h.date_applied)) c_month,
        DATEPART(YEAR, dbo.adm_format_pltdate_f(h.date_applied)) c_year,
        DATEPART(MONTH, dbo.adm_format_pltdate_f(h.date_applied)) x_month,
        DATENAME(MONTH, dbo.adm_format_pltdate_f(h.date_applied)) month,
        DATEPART(YEAR, dbo.adm_format_pltdate_f(h.date_applied)) year,
        CASE
            WHEN h.trx_type = 2031 THEN
                ROUND(d.extended_price, 2)
            ELSE
                0
        END AS asales,
        CASE
            WHEN h.trx_type = 2032 THEN
                ROUND(d.extended_price, 2)
            ELSE
                0
        END AS areturns,
        CASE
            WHEN h.trx_type = 2031 THEN
                ROUND((d.qty_shipped), 2)
            ELSE
                0
        END AS qsales,
        CASE
            WHEN h.trx_type = 2032 THEN
                ROUND((d.qty_returned), 2)
            ELSE
                0
        END AS qreturns,
        CASE
            WHEN h.trx_type = 2031 THEN
                ROUND(d.amt_cost * d.qty_shipped, 2)
            WHEN h.trx_type = 2032 THEN
                ROUND(d.amt_cost * d.qty_returned * -1, 2)
        END AS csales,
        CASE
            WHEN h.trx_type = 2031 THEN
                ROUND(d.extended_price, 2)
            WHEN h.trx_type = 2032 THEN
                ROUND(d.extended_price * -1, 2)
        END AS lsales,
        CONVERT(VARCHAR,
                   DATEADD(d,
                              h.date_applied - 711858,
                              '1/1/1950'
                          ),
                   101
               ) DateShipped,
        CONVERT(VARCHAR,
                   DATEADD(d,
                              h.date_applied - 711858,
                              '1/1/1950'
                          ),
                   101
               ) AS dateOrdered,
        0,
        0,
        h.salesperson_code AS slp
    FROM
        artrx_all h (NOLOCK)
        JOIN artrxcdt d (NOLOCK)
            ON h.trx_ctrl_num = d.trx_ctrl_num
        -- 013114
        LEFT OUTER JOIN inv_master i
            ON i.part_no = d.item_code
    WHERE
        NOT EXISTS
    (
        SELECT 1 FROM orders_invoice oi WHERE oi.trx_ctrl_num = h.trx_ctrl_num
    )
        AND h.date_applied
        BETWEEN @jfirst AND @jlast
        AND h.trx_type IN ( 2031, 2032 )
        AND h.doc_ctrl_num NOT LIKE 'FIN%'
        AND h.doc_ctrl_num NOT LIKE 'CB%'
        AND h.doc_desc NOT LIKE 'converted%'
        AND h.doc_desc NOT LIKE '%nonsales%'
        AND h.terms_code NOT LIKE 'ins%'
        AND
        (
            d.gl_rev_acct LIKE '4000%'
            OR d.gl_rev_acct LIKE '4500%'
            OR d.gl_rev_acct LIKE '4530%'
            OR -- 022514 - tag - add account for debit promo's
            d.gl_rev_acct LIKE '4600%'
            OR d.gl_rev_acct LIKE '4999%'
        )
        AND h.void_flag <> 1
    ; --v2.0  

    -- ar unposted

    INSERT INTO #cvo_sbm_det
    SELECT
        h.customer_code customer,
        h.ship_to_code ship_to,
        ISNULL(i.part_no, 'CVZPOSTAGE') AS PART_NO,
                           /*case when d.item_code = '' 
	OR NOT EXISTS (SELECT 1 FROM INV_MASTER WHERE PART_NO = D.ITEM_CODE) 
	then 'CVZPOSTAGE' ELSE D.ITEM_CODE END AS  part_no, 
*/
                           -- d.item_code part_no,
        CASE
            WHEN CHARINDEX('-', h.order_ctrl_num) <= 1 THEN
                ''
            ELSE
                ISNULL(
                (
                    SELECT TOP 1
                        promo_id
                    FROM CVO_orders_all co
                    WHERE
                        co.order_no = LEFT(h.order_ctrl_num, CHARINDEX('-',
                                                                          h.order_ctrl_num
                                                                      ) - 1)
                        AND co.ext = 0
                ),
                          ''
                      )
        END AS promo_id,
        CASE
            WHEN CHARINDEX('-', h.order_ctrl_num) <= 1 THEN
                ''
            ELSE
                ISNULL(
                (
                    SELECT TOP 1
                        promo_level
                    FROM CVO_orders_all co
                    WHERE
                        co.order_no = LEFT(h.order_ctrl_num, CHARINDEX('-',
                                                                          h.order_ctrl_num
                                                                      ) - 1)
                        AND co.ext = 0
                ),
                          ''
                      )
        END AS promo_level,
        CASE
            WHEN h.trx_type = 2032 THEN
                '06-13'
            ELSE
                ''
        END AS return_code,
        CASE
            WHEN CHARINDEX('-', h.order_ctrl_num) <= 1 THEN
                ''
            ELSE
                ISNULL(
                (
                    SELECT TOP 1
                        user_category
                    FROM orders co
                    WHERE
                        co.order_no = LEFT(h.order_ctrl_num, CHARINDEX('-',
                                                                          h.order_ctrl_num
                                                                      ) - 1)
                        AND co.ext = 0
                ),
                          ''
                      )
        END AS user_category,
        '001' AS location, -- 090913 tag
        DATEPART(MONTH, dbo.adm_format_pltdate_f(h.date_applied)) c_month,
        DATEPART(YEAR, dbo.adm_format_pltdate_f(h.date_applied)) c_year,
        DATEPART(MONTH, dbo.adm_format_pltdate_f(h.date_applied)) x_month,
        DATENAME(MONTH, dbo.adm_format_pltdate_f(h.date_applied)) month,
        DATEPART(YEAR, dbo.adm_format_pltdate_f(h.date_applied)) year,
        CASE
            WHEN h.trx_type = 2031 THEN
                ROUND(d.extended_price, 2)
            ELSE
                0
        END AS asales,
        CASE
            WHEN h.trx_type = 2032 THEN
                ROUND(d.extended_price, 2)
            ELSE
                0
        END AS areturns,
        CASE
            WHEN h.trx_type = 2031 THEN
                ROUND((d.qty_shipped), 2)
            ELSE
                0
        END AS qsales,
        CASE
            WHEN h.trx_type = 2032 THEN
                ROUND((d.qty_returned), 2)
            ELSE
                0
        END AS qreturns,
        CASE
            WHEN h.trx_type = 2031 THEN
                ROUND(d.unit_cost * d.qty_shipped, 2)
            WHEN h.trx_type = 2032 THEN
                ROUND(d.unit_cost * d.qty_returned * -1, 2)
        END AS csales,
        CASE
            WHEN h.trx_type = 2031 THEN
                ROUND(d.extended_price, 2)
            WHEN h.trx_type = 2032 THEN
                ROUND(d.extended_price * -1, 2)
        END AS lsales,
        CONVERT(VARCHAR,
                   DATEADD(d,
                              h.date_applied - 711858,
                              '1/1/1950'
                          ),
                   101
               ) DateShipped,
        CONVERT(VARCHAR,
                   DATEADD(d,
                              h.date_applied - 711858,
                              '1/1/1950'
                          ),
                   101
               ) AS dateOrdered,
        0,
        0,
        h.salesperson_code slp
    FROM
        arinpchg h (NOLOCK)
        JOIN arinpcdt d (NOLOCK)
            ON h.trx_ctrl_num = d.trx_ctrl_num
        -- 013114
        LEFT OUTER JOIN inv_master i
            ON i.part_no = d.item_code
    WHERE
        NOT EXISTS
    (
        SELECT 1 FROM orders_invoice oi WHERE oi.trx_ctrl_num = h.trx_ctrl_num
    )
        AND h.trx_type IN ( 2031, 2032 )
        AND h.date_applied
        BETWEEN @jfirst AND @jlast
        AND h.doc_ctrl_num NOT LIKE 'FIN%'
        AND h.doc_ctrl_num NOT LIKE 'CB%'
        AND h.terms_code NOT LIKE 'ins%'
        AND h.doc_desc NOT LIKE 'converted%'
        AND h.doc_desc NOT LIKE '%nonsales%'
        AND
        (
            d.gl_rev_acct LIKE '4000%'
            OR d.gl_rev_acct LIKE '4500%'
            OR d.gl_rev_acct LIKE '4530%'
            OR d.gl_rev_acct LIKE '4600%'
            OR d.gl_rev_acct LIKE '4999%'
        )
    ;
    -- load history data


    IF @first <= '2012-01-12 00:00:00.000'
    BEGIN

        INSERT INTO #cvo_sbm_det
        SELECT
            customer = ISNULL(oa.cust_code, ''),
            CASE
                WHEN NOT EXISTS
    (
        SELECT *
        FROM armaster ar
        WHERE
            ar.customer_code = oa.cust_code
            AND ar.ship_to_code = oa.ship_to
    )       THEN
                    ''
                WHEN oa.ship_to IS NULL THEN
                    ''
                ELSE
                    oa.ship_to
            END AS ship_to,
            ISNULL(i.part_no, 'CVZPOSTAGE') part_no,
            ISNULL(oa.user_def_fld3, '') AS promo_id,
            ISNULL(oa.user_def_fld9, '') AS promo_level,
            ISNULL(o.return_code, '') AS return_code,
            ISNULL(oa.user_category, 'ST') AS user_category,
            ISNULL(o.location, '001') location,                     -- 090913 tag
            ISNULL(DATEPART(MONTH, oa.date_shipped), '') AS c_month,
            ISNULL(DATEPART(YEAR, oa.date_shipped), '') AS c_year,
            CASE
                WHEN oa.date_shipped >= '12/26/2011' THEN
                    DATEPART(MONTH, '1/1/2012')
                ELSE
                    ISNULL(DATEPART(MONTH,
                                       oa.date_shipped
                                   ),
                              ''
                          )
            END AS x_month,
            CASE
                WHEN oa.date_shipped >= '12/26/2011' THEN
                    DATENAME(MONTH, '1/1/2012')
                ELSE
                    DATENAME(MONTH, oa.date_shipped)
            END AS month,
            CASE
                WHEN oa.date_shipped >= '12/26/2011' THEN
                    DATEPART(YEAR, '1/1/2012')
                ELSE
                    DATEPART(YEAR, oa.date_shipped)
            END AS year,
            CASE
                WHEN type = 'i' THEN
                    ISNULL(o.shipped * o.price, 0)
                ELSE
                    0
            END AS asales,
            CASE
                WHEN type = 'c' THEN
                    ISNULL(o.cr_shipped * o.price, 0)
                ELSE
                    0
            END AS areturns,
            CASE
                WHEN type = 'I' THEN
                    ISNULL(o.shipped, 0)
                ELSE
                    0
            END AS qsales,
            CASE
                WHEN type = 'C' THEN
                    ISNULL(o.cr_shipped, 0)
                ELSE
                    0
            END AS qreturns,
                                                                    -- 11/12/13
            ROUND(ISNULL((o.shipped - o.cr_shipped) * o.cost, 0), 2) AS csales,
            ROUND(ISNULL((o.shipped - o.cr_shipped) * pp.price_a, 0), 2) AS lsales,
            CONVERT(VARCHAR(10), oa.date_shipped, 101) DateShipped, -- for daily version
            oo.date_entered AS dateOrdered,
            0,
            0,
            oa.salesperson slp

                                                                    --
        FROM
            CVO_orders_all_Hist oa (NOLOCK)
            INNER JOIN cvo_ord_list_hist o (NOLOCK)
                ON oa.order_no = o.order_no
                   AND oa.ext = o.order_ext
            LEFT OUTER JOIN inv_master i (NOLOCK)
                ON o.part_no = i.part_no
            LEFT OUTER JOIN part_price pp (NOLOCK)
                ON pp.part_no = o.part_no
            LEFT OUTER JOIN
            (
                SELECT
                    order_no,
                    MIN(ooo.date_entered)
                FROM CVO_orders_all_Hist ooo (NOLOCK)
                WHERE ooo.status <> 'v'
                GROUP BY ooo.order_no
            ) AS oo(order_no, date_entered)
                ON oo.order_no = oa.order_no
        WHERE
            1 = 1
            AND oa.date_shipped
            BETWEEN @first AND @last
        ;

    END
    ; -- need to regen history ?

    -- 4/25/2014 - classify closeouts

    UPDATE #cvo_sbm_det
    SET isCL = 1
    WHERE
        lsales <> 0
        AND (1 - (asales - areturns) / lsales)
        BETWEEN .8 AND .99
    ;

    IF (OBJECT_ID('cvo.dbo.cvo_sbm_details') IS NOT NULL)
        -- drop table cvo.dbo.cvo_sbm_details
        DELETE FROM dbo.cvo_sbm_details
        WHERE
            yyyymmdd
        BETWEEN @first AND @last
        ;


    IF (OBJECT_ID('cvo.dbo.cvo_sbm_details') IS NULL)
    BEGIN
        CREATE TABLE dbo.cvo_sbm_details
        (
            customer VARCHAR(10) NOT NULL,
            ship_to VARCHAR(10),
            customer_name VARCHAR(40),
                                          -- new
            part_no VARCHAR(30) NULL,
            promo_id VARCHAR(20) NULL,
            promo_level VARCHAR(30) NULL,
            return_code VARCHAR(10) NULL,
            user_category VARCHAR(10) NULL,
                                          -- new
            location VARCHAR(10) NULL,    -- tag 090913
            c_month INT NULL,             -- 061213 - calendar month
            c_year INT NULL,
            X_MONTH INT NULL,             -- fiscal month
            month VARCHAR(15) NULL,
            year INT NULL,
            asales FLOAT NULL,
            areturns FLOAT NULL,
            anet FLOAT NULL,
            qsales FLOAT NULL,
            qreturns FLOAT NULL,
            qnet FLOAT NULL,
            csales FLOAT NULL,
            lsales FLOAT NULL,
            yyyymmdd DATETIME,
            DateOrdered DATETIME,
            orig_return_code VARCHAR(10), -- for EL 12/10/2013
            id INT IDENTITY,              -- 11/8/2013 - for DW
            isCL INT,                     -- 4/25/2014 - Close out flag
            isBO INT,
            slp VARCHAR(10)
        ) ON [PRIMARY]
        ;
        GRANT SELECT
        ON dbo.cvo_sbm_details
        TO  [public]
        ;
        CREATE NONCLUSTERED INDEX idx_cvo_sbm_cust
        ON dbo.cvo_sbm_details
        (
            customer ASC,
            ship_to ASC,
            yyyymmdd ASC,
            DateOrdered ASC
        )
        WITH (SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF) ON [PRIMARY]
        ;


        CREATE INDEX idx_cvo_sbm_prod
        ON cvo_sbm_details
        (
            part_no ASC,
            yyyymmdd ASC
        )
        ;

        CREATE INDEX idx_cvo_sbm_prod
        ON #cvo_sbm_det (part_no ASC)
        ;

        CREATE INDEX idx_cvo_sbm_cust_part
        ON cvo_sbm_details
        (
            customer ASC,
            part_no ASC
        )
        ;

        CREATE NONCLUSTERED INDEX idx_sbm_det_for_drp
        ON dbo.cvo_sbm_details
        (
            part_no ASC,
            location ASC,
            qsales ASC,
            qreturns ASC
        )
        WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF,
                 DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON
             ) ON [PRIMARY]
        ;


        CREATE NONCLUSTERED INDEX idx_sbm_details_amts
        ON dbo.cvo_sbm_details
        (
            asales,
            areturns,
            qsales,
            qreturns,
            lsales
        )
        ;

        CREATE NONCLUSTERED INDEX idx_cvo_sbm_yyyymmdd
        ON dbo.cvo_sbm_details (yyyymmdd)
        INCLUDE
        (
            customer,
            ship_to,
            part_no,
            user_category,
            c_month,
            c_year,
            anet
        )
        ;

        --11/17/2015 - for new HS CIR
        CREATE NONCLUSTERED INDEX idx_cvo_sbm_yyyymmdd_cir
        ON dbo.cvo_sbm_details (yyyymmdd)
        INCLUDE
        (
            customer,
            ship_to,
            part_no,
            return_code,
            user_category,
            qsales,
            qreturns,
            DateOrdered,
            isCL
        )
        ;

    END
    ;


    INSERT cvo_sbm_details
    SELECT
        customer,
        ship_to,
        ar.address_name customer_name,
        part_no,
        ISNULL(PROMO_ID, '') promo_id,
        ISNULL(promo_level, '') promo_level,
        CASE
            WHEN return_code LIKE '04%' THEN
                'WTY'
            -- 030514 - tag dont' mark sales as exc returns -- oops
            WHEN return_code NOT IN ( '06-13', '06-13B', '06-27', '06-32', '' ) THEN
                'EXC'
            WHEN return_code IS NULL THEN
                ''
            ELSE
                ''
        END AS return_code,
        ISNULL(user_category, 'ST') AS user_category,
        ISNULL(location, '001') location, -- 090913 tag
        c_month,
        c_year,
        x_month,
        month,
        year,
        ROUND(SUM(asales), 2) asales,
        SUM(areturns) areturns,
        ROUND(SUM(asales), 2) - SUM(areturns) AS anet,
        SUM(qsales) qsales,
        SUM(qreturns) qreturns,
        SUM(qsales) - SUM(qreturns) AS qnet,
        SUM(ISNULL(csales, 0)) csales,
        ROUND(SUM(ISNULL(lsales, 0)), 2) lsales,
        DateShipped AS yyyymmdd,
        DateOrdered,
        return_code AS orig_return_code,
        isCL,
        isBO,
        slp
    FROM
        #cvo_sbm_det
        LEFT OUTER JOIN armaster (NOLOCK) ar
            ON ar.customer_code = customer
               AND ar.ship_to_code = ship_to
    WHERE
    (
        asales <> 0
        OR qsales <> 0
        OR areturns <> 0
        OR qreturns <> 0
    )
    GROUP BY
        customer,
        ship_to,
        ar.address_name,
        part_no,
        promo_id,
        promo_level,
        return_code,
        user_category,
        location,
        year,
        c_year,
        c_month,
        x_month,
        month,
        DateShipped,
        DateOrdered,
        isCL,
        isBO,
        slp
    ;


END
;




GO
