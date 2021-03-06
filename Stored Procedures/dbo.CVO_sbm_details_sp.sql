SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- SELECT * FROM #xxad
-- select x_month, count(*) from cvo_sbm_details where c_year in ( 2018 ) group by x_month
-- SELECT * FROM dbo.cvo_sbm_by_year_vw AS sbyv

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
-- 7/2018 - update closeout logic

CREATE PROCEDURE [dbo].[CVO_sbm_details_sp]
AS
BEGIN
    -- SET NOCOUNT ON added to prevent extra result sets from
    -- interfering with SELECT statements.
    SET NOCOUNT ON;

    -- exec cvo_sbm_details_sp

    -- exec cvo_csbm_shipto_sp
    DECLARE @first DATETIME,
            @last DATETIME,
            @jfirst INT,
            @jlast INT,
            @numrecs INT,
            @numrecs_to_delete INT;

    --SELECT  @first = '1/1/2017';	-- add 09 and 10 once validated and fixed
    --SELECT  @last = '12/31/2017';

    -- change the period here to rebuild sbm_details as needed
    SELECT @first = BeginDate,
           @last = EndDate
    FROM dbo.cvo_date_range_vw AS drv
    WHERE Period = 'Last 60 days';

    --SELECT @first = '1/1/2015'; -- add 09 and 10 once validated and fixed
    --SELECT @last = '12/31/2015';

    SELECT @jfirst = dbo.adm_get_pltdate_f(@first);

    SELECT @jlast = dbo.adm_get_pltdate_f(@last);

    IF (OBJECT_ID('tempdb.dbo.#cvo_sbm_det') IS NOT NULL)
        DROP TABLE #cvo_sbm_det;


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
            slp VARCHAR(10),
			doctype CHAR(1) -- 7/9/18 - for closeout calculation
        );
    END;


    CREATE NONCLUSTERED INDEX idx_sbm_det_tmp
    ON #cvo_sbm_det (
                    asales,
                    areturns,
                    qsales,
                    qreturns,
                    lsales
                    );

    -- get all the ar transaction numbers and the apply dates for the period

    IF (OBJECT_ID('tempdb.dbo.#xxad') IS NULL)
    BEGIN
        CREATE TABLE #xxad
        (
            trx_ctrl_num VARCHAR(24) NOT NULL,
            date_applied INT NOT NULL,
            date_applied_dt DATETIME NOT NULL
        );

        CREATE CLUSTERED INDEX idx_trx_ar
        ON #xxad (
                 trx_ctrl_num,
                 date_applied_dt
                 );
    END;


    ;WITH Dates (Date_applied_dt, date_applied_int)
    AS
    (
    SELECT CONVERT(DATETIME, @first) AS date_applied_dt,
           dbo.adm_get_pltdate_f(CONVERT(DATETIME, @first)) date_applied_int
    UNION ALL
    SELECT DATEADD(DAY, 1, Date_applied_dt),
           dbo.adm_get_pltdate_f(DATEADD(DAY, 1, Date_applied_dt))
    FROM Dates
    WHERE Date_applied_dt < CONVERT(DATETIME, @last)
    )
    INSERT INTO #xxad
    (
        trx_ctrl_num,
        date_applied,
        date_applied_dt
    )
    SELECT DISTINCT
           trx.trx_ctrl_num,
           trx.date_applied,
           Dates.Date_applied_dt
    FROM
    (
    SELECT DISTINCT
           h.trx_ctrl_num,
           h.date_applied
    FROM dbo.artrx h
        (NOLOCK)
    WHERE 1 = 1
          AND h.date_applied
          BETWEEN @jfirst AND @jlast
          AND h.trx_type IN ( 2031, 2032 )
          AND h.doc_desc NOT LIKE 'converted%'
          AND h.doc_desc NOT LIKE '%nonsales%'
          AND h.doc_ctrl_num NOT LIKE 'cb%'
          AND h.doc_ctrl_num NOT LIKE 'fin%'
    UNION ALL
    SELECT DISTINCT
           h.trx_ctrl_num,
           h.date_applied
    FROM dbo.arinpchg_all AS h
        (NOLOCK)
    WHERE 1 = 1
          AND h.date_applied
          BETWEEN @jfirst AND @jlast
          AND h.trx_type IN ( 2031, 2032 )
          AND h.doc_desc NOT LIKE 'converted%'
          AND h.doc_desc NOT LIKE '%nonsales%'
          AND h.doc_ctrl_num NOT LIKE 'cb%'
          AND h.doc_ctrl_num NOT LIKE 'fin%'
    ) trx
        JOIN Dates
            ON Dates.date_applied_int = trx.date_applied
    OPTION (MAXRECURSION 32767);

    -- load live data - use artrx to capture validated sales #

    INSERT INTO #cvo_sbm_det
    (
        customer,
        ship_to,
        part_no,
        PROMO_ID,
        promo_level,
        return_code,
        user_category,
        location,
        c_month,
        c_year,
        x_month,
        month,
        year,
        asales,
        areturns,
        qsales,
        qreturns,
        csales,
        lsales,
        DateShipped,
        DateOrdered,
        isCL,
        isBO,
        slp,
		doctype
    )
    SELECT ISNULL(xx.customer_code, '') customer,
           ISNULL(xx.ship_to_code, '') ship_to,
           ISNULL(i.part_no, 'CVZPOSTAGE') AS PART_NO,
           CASE WHEN ol.return_code = '05-24' AND co.promo_id = 'BEP' THEN '' ELSE ISNULL(co.promo_id, '') END AS promo_id,
           CASE WHEN ol.return_code = '05-24' AND co.promo_id = 'BEP' THEN '' ELSE ISNULL(co.promo_level, '') END AS promo_level,
           ISNULL(ol.return_code, '') return_code,
           ISNULL(o.user_category, 'ST') user_category,
           ol.location,                                            -- tag 090913
           DATEPART(MONTH, xxad.date_applied_dt) c_month,
           DATEPART(YEAR, xxad.date_applied_dt) c_year,
           DATEPART(MONTH, xxad.date_applied_dt) x_month,
           DATENAME(MONTH, xxad.date_applied_dt) month,
           DATEPART(YEAR, xxad.date_applied_dt) year,
           CASE o.type
           WHEN 'i' THEN
               CASE ISNULL(cl.is_amt_disc, 'n')
               WHEN 'y' THEN ROUND(ol.shipped * (ROUND(ol.curr_price, 2) - ROUND(ISNULL(cl.amt_disc, 0), 2)), 2, 1) ELSE
                                                                                                                        ROUND(
                                                                                                                                 ol.shipped
                                                                                                                                 * (ROUND(
                                                                                                                                             ol.curr_price,
                                                                                                                                             2
                                                                                                                                         )
                                                                                                                                    - ROUND(
                                                                                                                                               ROUND(
                                                                                                                                                        ol.curr_price,
                                                                                                                                                        2
                                                                                                                                                    )
                                                                                                                                               * (ol.discount
                                                                                                                                                  / 100.00
                                                                                                                                                 ),
                                                                                                                                               2
                                                                                                                                           )
                                                                                                                                   ),
                                                                                                                                 2
                                                                                                                             )
               END ELSE 0
           END AS asales,
           CASE o.type
           WHEN 'c' THEN
               ROUND(ol.cr_shipped * ROUND(ol.curr_price, 2), 2)
               - ROUND(ol.cr_shipped * (ROUND(ol.curr_price, 2) * (ol.discount / 100.00)), 2) ELSE 0
           END AS areturns,
           CASE WHEN o.type = 'i' THEN ol.shipped ELSE 0 END AS qsales,
           CASE WHEN o.type = 'c' THEN ol.cr_shipped ELSE 0 END AS qreturns,
                                                                   -- add cost and list 11/12/13
           ROUND((ol.shipped - ol.cr_shipped) * (ol.cost + ol.ovhd_dolrs + ol.util_dolrs), 2) AS csales,
           ROUND((ol.shipped - ol.cr_shipped) * cl.list_price, 2) AS lsales,
                                                                   --
           xxad.date_applied_dt DateShipped,
           DATEADD(dd, DATEDIFF(dd, 0, oo.date_entered), 0) DateOrdered,
           0,                                                      -- isCL
           CASE WHEN o.who_entered = 'BACKORDR' THEN 1 ELSE 0 END, -- isBO
           o.salesperson slp                                       -- salesperson on this order -- 100314
		   , o.type
    FROM #xxad AS xxad
        (NOLOCK)
        JOIN dbo.artrx xx
        (NOLOCK)
            ON xx.trx_ctrl_num = xxad.trx_ctrl_num
        INNER JOIN dbo.orders_invoice oi
        (NOLOCK)
            ON oi.trx_ctrl_num = xx.trx_ctrl_num
        INNER JOIN dbo.orders o
        (NOLOCK)
            ON o.order_no = oi.order_no
               AND o.ext = oi.order_ext
        INNER JOIN dbo.CVO_orders_all co
        (NOLOCK)
            ON co.order_no = o.order_no
               AND co.ext = o.ext
        INNER JOIN dbo.ord_list ol
        (NOLOCK)
            ON ol.order_no = o.order_no
               AND ol.order_ext = o.ext
        LEFT OUTER JOIN dbo.CVO_ord_list cl
        (NOLOCK)
            ON cl.order_no = ol.order_no
               AND cl.order_ext = ol.order_ext
               AND cl.line_no = ol.line_no
        LEFT OUTER JOIN
        (
        SELECT order_no,
               MIN(ooo.date_entered)
        FROM dbo.orders ooo
            (NOLOCK)
        WHERE ooo.status <> 'v'
        GROUP BY ooo.order_no
        ) AS oo(order_no, date_entered)
            ON oo.order_no = o.order_no
        -- tag 013114
        LEFT OUTER JOIN dbo.inv_master i
        (NOLOCK)
            ON i.part_no = ol.part_no
    WHERE 1 = 1
          AND xx.void_flag = 0
          AND xx.posted_flag = 1
    UNION ALL

    -- unposted invoices

    SELECT ISNULL(xx.customer_code, '') customer,
           ISNULL(xx.ship_to_code, '') ship_to,
           ISNULL(i.part_no, 'CVZPOSTAGE') AS PART_NO,
           CASE WHEN ol.return_code = '05-24' AND co.promo_id = 'BEP' THEN '' ELSE ISNULL(co.promo_id, '') END AS promo_id,
           CASE WHEN ol.return_code = '05-24' AND co.promo_id = 'BEP' THEN '' ELSE ISNULL(co.promo_level, '') END AS promo_level,
           ISNULL(ol.return_code, '') return_code,
           ISNULL(o.user_category, 'ST') user_category,
           ol.location, -- 090913 tag
           DATEPART(MONTH, xxad.date_applied_dt) c_month,
           DATEPART(YEAR, xxad.date_applied_dt) c_year,
           DATEPART(MONTH, xxad.date_applied_dt) x_month,
           DATENAME(MONTH, xxad.date_applied_dt) month,
           DATEPART(YEAR, xxad.date_applied_dt) year,
           CASE o.type
           WHEN 'i' THEN
               CASE ISNULL(cl.is_amt_disc, 'n')
               WHEN 'y' THEN ROUND(ol.shipped * (ROUND(ol.curr_price, 2) - ROUND(ISNULL(cl.amt_disc, 0), 2)), 2, 1) ELSE
                                                                                                                        ROUND(
                                                                                                                                 ol.shipped
                                                                                                                                 * (ROUND(
                                                                                                                                             ol.curr_price,
                                                                                                                                             2
                                                                                                                                         )
                                                                                                                                    - ROUND(
                                                                                                                                               ol.curr_price
                                                                                                                                               * (ol.discount
                                                                                                                                                  / 100.00
                                                                                                                                                 ),
                                                                                                                                               2
                                                                                                                                           )
                                                                                                                                   ),
                                                                                                                                 2
                                                                                                                             )
               END ELSE 0
           END AS asales,
           CASE o.type
           WHEN 'c' THEN
               ROUND(ol.cr_shipped * ROUND(ol.curr_price, 2), 2)
               - ROUND(ol.cr_shipped * (ROUND(ol.curr_price, 2) * (ol.discount / 100.00)), 2) ELSE 0
           END AS areturns,
           CASE WHEN o.type = 'i' THEN ol.shipped ELSE 0 END AS qsales,
           CASE WHEN o.type = 'c' THEN ol.cr_shipped ELSE 0 END AS qreturns,
                        -- add cost and list 11/12/13
           ROUND((ol.shipped - ol.cr_shipped) * (ol.cost + ol.ovhd_dolrs + ol.util_dolrs), 2) AS csales,
           ROUND((ol.shipped - ol.cr_shipped) * cl.list_price, 2) AS lsales,
                        --
           xxad.date_applied_dt DateShipped,
           xxad.date_applied_dt AS dateOrdered,
           0,
           CASE WHEN o.who_entered = 'BACKORDR' THEN 1 ELSE 0 END,
           o.salesperson slp,
		   o.type
    FROM #xxad xxad
        (NOLOCK)
        JOIN dbo.arinpchg xx
        (NOLOCK)
            ON xx.trx_ctrl_num = xxad.trx_ctrl_num
        INNER JOIN dbo.orders_invoice oi
        (NOLOCK)
            ON oi.trx_ctrl_num = xx.trx_ctrl_num
        INNER JOIN dbo.orders o
        (NOLOCK)
            ON oi.order_no = o.order_no
               AND oi.order_ext = o.ext
        INNER JOIN dbo.CVO_orders_all co
        (NOLOCK)
            ON co.order_no = o.order_no
               AND co.ext = o.ext
        INNER JOIN dbo.ord_list ol
        (NOLOCK)
            ON ol.order_no = o.order_no
               AND ol.order_ext = o.ext
        LEFT OUTER JOIN dbo.CVO_ord_list cl
        (NOLOCK)
            ON cl.order_no = ol.order_no
               AND cl.order_ext = ol.order_ext
               AND cl.line_no = ol.line_no
        LEFT OUTER JOIN
        (
        SELECT order_no,
               MIN(ooo.date_entered)
        FROM dbo.orders ooo
            (NOLOCK)
        WHERE ooo.status <> 'v'
        GROUP BY ooo.order_no
        ) AS oo(order_no, date_entered)
            ON oo.order_no = o.order_no
        -- 013114
        LEFT OUTER JOIN dbo.inv_master i
        (NOLOCK)
            ON i.part_no = ol.part_no
    WHERE 1 = 1
    UNION ALL

    -- AR Only Activity

    SELECT h.customer_code customer,
           h.ship_to_code ship_to,
           ISNULL(i.part_no, 'CVZPOSTAGE') AS PART_NO,
                              /*case when d.item_code = '' 
OR NOT EXISTS (SELECT 1 FROM INV_MASTER WHERE PART_NO = D.ITEM_CODE) 
then 'CVZPOSTAGE' ELSE D.ITEM_CODE END AS  part_no,
*/
           CASE WHEN CHARINDEX('-', h.order_ctrl_num) <= 1 THEN '' ELSE
                                                                       ISNULL(
                                                                       (
                                                                       SELECT TOP (1)
                                                                              promo_id
                                                                       FROM dbo.CVO_orders_all co
                                                                           (NOLOCK)
                                                                       WHERE co.order_no = LEFT(h.order_ctrl_num, CHARINDEX(
                                                                                                                               '-',
                                                                                                                               h.order_ctrl_num
                                                                                                                           )
                                                                                                                  - 1)
                                                                             AND co.ext = 0
                                                                       ),
                                                                       ''
                                                                             )
           END AS promo_id,
           CASE WHEN CHARINDEX('-', h.order_ctrl_num) <= 1 THEN '' ELSE
                                                                       ISNULL(
                                                                       (
                                                                       SELECT TOP (1)
                                                                              promo_level
                                                                       FROM dbo.CVO_orders_all co
                                                                       WHERE co.order_no = LEFT(h.order_ctrl_num, CHARINDEX(
                                                                                                                               '-',
                                                                                                                               h.order_ctrl_num
                                                                                                                           )
                                                                                                                  - 1)
                                                                             AND co.ext = 0
                                                                       ),
                                                                       ''
                                                                             )
           END AS promo_level,
           CASE WHEN h.trx_type = 2032 THEN '06-13' ELSE '' END AS return_code,
           CASE WHEN CHARINDEX('-', h.order_ctrl_num) <= 1 THEN '' ELSE
                                                                       ISNULL(
                                                                       (
                                                                       SELECT TOP (1)
                                                                              user_category
                                                                       FROM dbo.orders co
                                                                       WHERE co.order_no = LEFT(h.order_ctrl_num, CHARINDEX(
                                                                                                                               '-',
                                                                                                                               h.order_ctrl_num
                                                                                                                           )
                                                                                                                  - 1)
                                                                             AND co.ext = 0
                                                                       ),
                                                                       ''
                                                                             )
           END AS user_category,
           '001' AS location, -- tag - 090913 
           DATEPART(MONTH, xxad.date_applied_dt) c_month,
           DATEPART(YEAR, xxad.date_applied_dt) c_year,
           DATEPART(MONTH, xxad.date_applied_dt) x_month,
           DATENAME(MONTH, xxad.date_applied_dt) month,
           DATEPART(YEAR, xxad.date_applied_dt) year,
           CASE WHEN h.trx_type = 2031 THEN ROUND(d.extended_price, 2) ELSE 0 END AS asales,
           CASE WHEN h.trx_type = 2032 THEN ROUND(d.extended_price, 2) ELSE 0 END AS areturns,
           CASE WHEN h.trx_type = 2031 THEN ROUND((d.qty_shipped), 2) ELSE 0 END AS qsales,
           CASE WHEN h.trx_type = 2032 THEN ROUND((d.qty_returned), 2) ELSE 0 END AS qreturns,
           CASE WHEN h.trx_type = 2031 THEN ROUND(d.amt_cost * d.qty_shipped, 2)
           WHEN h.trx_type = 2032 THEN ROUND(d.amt_cost * d.qty_returned * -1, 2) ELSE 0
           END AS csales,
           CASE WHEN h.trx_type = 2031 THEN ROUND(d.extended_price, 2)
           WHEN h.trx_type = 2032 THEN ROUND(d.extended_price * -1, 2) ELSE 0
           END AS lsales,
           xxad.date_applied_dt DateShipped,
           xxad.date_applied_dt AS dateOrdered,
           0,
           0,
           h.salesperson_code AS slp,
		   CASE WHEN h.trx_type = 2031 THEN 'I' ELSE 'C' END doctype
    FROM #xxad xxad
        (NOLOCK)
        JOIN dbo.artrx_all h
        (NOLOCK)
            ON h.trx_ctrl_num = xxad.trx_ctrl_num
        JOIN dbo.artrxcdt d
        (NOLOCK)
            ON h.trx_ctrl_num = d.trx_ctrl_num
        -- 013114
        LEFT OUTER JOIN dbo.inv_master i
        (NOLOCK)
            ON i.part_no = d.item_code
    WHERE NOT EXISTS
    (
    SELECT 1
    FROM dbo.orders_invoice oi
        (NOLOCK)
    WHERE oi.trx_ctrl_num = h.trx_ctrl_num
    )
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
    --v2.0  

    UNION ALL

    -- ar unposted

    SELECT h.customer_code customer,
           h.ship_to_code ship_to,
           ISNULL(i.part_no, 'CVZPOSTAGE') AS PART_NO,
                              /*case when d.item_code = '' 
OR NOT EXISTS (SELECT 1 FROM INV_MASTER WHERE PART_NO = D.ITEM_CODE) 
then 'CVZPOSTAGE' ELSE D.ITEM_CODE END AS  part_no, 
*/
                              -- d.item_code part_no,
           CASE WHEN CHARINDEX('-', h.order_ctrl_num) <= 1 THEN '' ELSE
                                                                       ISNULL(
                                                                       (
                                                                       SELECT TOP (1)
                                                                              promo_id
                                                                       FROM dbo.CVO_orders_all co
                                                                           (NOLOCK)
                                                                       WHERE co.order_no = LEFT(h.order_ctrl_num, CHARINDEX(
                                                                                                                               '-',
                                                                                                                               h.order_ctrl_num
                                                                                                                           )
                                                                                                                  - 1)
                                                                             AND co.ext = 0
                                                                       ),
                                                                       ''
                                                                             )
           END AS promo_id,
           CASE WHEN CHARINDEX('-', h.order_ctrl_num) <= 1 THEN '' ELSE
                                                                       ISNULL(
                                                                       (
                                                                       SELECT TOP (1)
                                                                              promo_level
                                                                       FROM dbo.CVO_orders_all co
                                                                           (NOLOCK)
                                                                       WHERE co.order_no = LEFT(h.order_ctrl_num, CHARINDEX(
                                                                                                                               '-',
                                                                                                                               h.order_ctrl_num
                                                                                                                           )
                                                                                                                  - 1)
                                                                             AND co.ext = 0
                                                                       ),
                                                                       ''
                                                                             )
           END AS promo_level,
           CASE WHEN h.trx_type = 2032 THEN '06-13' ELSE '' END AS return_code,
           CASE WHEN CHARINDEX('-', h.order_ctrl_num) <= 1 THEN '' ELSE
                                                                       ISNULL(
                                                                       (
                                                                       SELECT TOP (1)
                                                                              user_category
                                                                       FROM dbo.orders co
                                                                           (NOLOCK)
                                                                       WHERE co.order_no = LEFT(h.order_ctrl_num, CHARINDEX(
                                                                                                                               '-',
                                                                                                                               h.order_ctrl_num
                                                                                                                           )
                                                                                                                  - 1)
                                                                             AND co.ext = 0
                                                                       ),
                                                                       ''
                                                                             )
           END AS user_category,
           '001' AS location, -- 090913 tag
           DATEPART(MONTH, xxad.date_applied_dt) c_month,
           DATEPART(YEAR, xxad.date_applied_dt) c_year,
           DATEPART(MONTH, xxad.date_applied_dt) x_month,
           DATENAME(MONTH, xxad.date_applied_dt) month,
           DATEPART(YEAR, xxad.date_applied_dt) year,
           CASE WHEN h.trx_type = 2031 THEN ROUND(d.extended_price, 2) ELSE 0 END AS asales,
           CASE WHEN h.trx_type = 2032 THEN ROUND(d.extended_price, 2) ELSE 0 END AS areturns,
           CASE WHEN h.trx_type = 2031 THEN ROUND((d.qty_shipped), 2) ELSE 0 END AS qsales,
           CASE WHEN h.trx_type = 2032 THEN ROUND((d.qty_returned), 2) ELSE 0 END AS qreturns,
           CASE WHEN h.trx_type = 2031 THEN ROUND(d.unit_cost * d.qty_shipped, 2)
           WHEN h.trx_type = 2032 THEN ROUND(d.unit_cost * d.qty_returned * -1, 2) ELSE 0
           END AS csales,
           CASE WHEN h.trx_type = 2031 THEN ROUND(d.extended_price, 2)
           WHEN h.trx_type = 2032 THEN ROUND(d.extended_price * -1, 2) ELSE 0
           END AS lsales,
           xxad.date_applied_dt AS DateShipped,
           xxad.date_applied_dt AS dateOrdered,
           0,
           0,
           h.salesperson_code slp,
		   CASE WHEN h.trx_type = 2031 THEN 'I' ELSE 'C' END doctype
    FROM #xxad xxad
        (NOLOCK)
        JOIN dbo.arinpchg h
        (NOLOCK)
            ON h.trx_ctrl_num = xxad.trx_ctrl_num
        JOIN dbo.arinpcdt d
        (NOLOCK)
            ON h.trx_ctrl_num = d.trx_ctrl_num
        -- 013114
        LEFT OUTER JOIN dbo.inv_master i
        (NOLOCK)
            ON i.part_no = d.item_code
    WHERE NOT EXISTS
    (
    SELECT 1 FROM dbo.orders_invoice oi WHERE oi.trx_ctrl_num = h.trx_ctrl_num
    )
          AND h.terms_code NOT LIKE 'ins%'
          AND
          (
          d.gl_rev_acct LIKE '4000%'
          OR d.gl_rev_acct LIKE '4500%'
          OR d.gl_rev_acct LIKE '4530%'
          OR d.gl_rev_acct LIKE '4600%'
          OR d.gl_rev_acct LIKE '4999%'
          );

    -- load history data


    IF @first <= '2012-01-12 00:00:00.000'
    BEGIN

        INSERT INTO #cvo_sbm_det
        SELECT ISNULL(oa.cust_code, '') customer,
               CASE WHEN NOT EXISTS
    (
    SELECT 1
    FROM dbo.armaster ar
    WHERE ar.customer_code = oa.cust_code
          AND ar.ship_to_code = oa.ship_to
    )          THEN ''
               WHEN oa.ship_to IS NULL THEN '' ELSE oa.ship_to
               END AS ship_to,
               ISNULL(i.part_no, 'CVZPOSTAGE') part_no,
               ISNULL(oa.user_def_fld3, '') AS promo_id,
               ISNULL(oa.user_def_fld9, '') AS promo_level,
               ISNULL(o.return_code, '') AS return_code,
               ISNULL(oa.user_category, 'ST') AS user_category,
               ISNULL(o.location, '001') location,                     -- 090913 tag
               ISNULL(DATEPART(MONTH, oa.date_shipped), '') AS c_month,
               ISNULL(DATEPART(YEAR, oa.date_shipped), '') AS c_year,
               CASE WHEN oa.date_shipped >= '12/26/2011' THEN DATEPART(MONTH, '1/1/2012') ELSE
                                                                                              ISNULL(
                                                                                                        DATEPART(
                                                                                                                    MONTH,
                                                                                                                    oa.date_shipped
                                                                                                                ),
                                                                                                        ''
                                                                                                    )
               END AS x_month,
               CASE WHEN oa.date_shipped >= '12/26/2011' THEN DATENAME(MONTH, '1/1/2012') ELSE
                                                                                              DATENAME(
                                                                                                          MONTH,
                                                                                                          oa.date_shipped
                                                                                                      ) END AS month,
               CASE WHEN oa.date_shipped >= '12/26/2011' THEN DATEPART(YEAR, '1/1/2012') ELSE
                                                                                             DATEPART(
                                                                                                         YEAR,
                                                                                                         oa.date_shipped
                                                                                                     ) END AS year,
               CASE WHEN oa.type = 'i' THEN ISNULL(o.shipped * o.price, 0) ELSE 0 END AS asales,
               CASE WHEN oa.type = 'c' THEN ISNULL(o.cr_shipped * o.price, 0) ELSE 0 END AS areturns,
               CASE WHEN oa.type = 'I' THEN ISNULL(o.shipped, 0) ELSE 0 END AS qsales,
               CASE WHEN oa.type = 'C' THEN ISNULL(o.cr_shipped, 0) ELSE 0 END AS qreturns,
                                                                       -- 11/12/13
               ROUND(ISNULL((o.shipped - o.cr_shipped) * o.cost, 0), 2) AS csales,
               ROUND(ISNULL((o.shipped - o.cr_shipped) * pp.price_a, 0), 2) AS lsales,
               CONVERT(VARCHAR(10), oa.date_shipped, 101) DateShipped, -- for daily version
               oo.date_entered AS dateOrdered,
               0,
               0,
               oa.salesperson slp,
			   oa.type

        --
        FROM dbo.CVO_orders_all_Hist oa
            (NOLOCK)
            INNER JOIN dbo.cvo_ord_list_hist o
            (NOLOCK)
                ON oa.order_no = o.order_no
                   AND oa.ext = o.order_ext
            LEFT OUTER JOIN dbo.inv_master i
            (NOLOCK)
                ON o.part_no = i.part_no
            LEFT OUTER JOIN dbo.part_price pp
            (NOLOCK)
                ON pp.part_no = o.part_no
            LEFT OUTER JOIN
            (
            SELECT order_no,
                   MIN(ooo.date_entered)
            FROM dbo.CVO_orders_all_Hist ooo
                (NOLOCK)
            WHERE ooo.status <> 'v'
            GROUP BY ooo.order_no
            ) AS oo(order_no, date_entered)
                ON oo.order_no = oa.order_no
        WHERE 1 = 1
              AND oa.date_shipped
              BETWEEN @first AND @last;

    END;

    -- need to regen history ?

    -- 4/25/2014 - classify closeouts

	CREATE NONCLUSTERED INDEX idx_sbm_det_promo
    ON #cvo_sbm_det (PROMO_ID, promo_level)
	;

    CREATE NONCLUSTERED INDEX idx_sbm_det_lsales
    ON #cvo_sbm_det (lsales, doctype)
    INCLUDE (
            asales,
            areturns
            );

    UPDATE c SET isCL = 1
	-- SELECT *
	FROM #cvo_sbm_det  c
	LEFT JOIN cvo_promotions p ON p.promo_id = c.PROMO_ID AND p.promo_level = c.promo_level
	LEFT OUTER JOIN dbo.CVO_line_discounts AS ld ON ld.promo_ID = c.PROMO_ID AND ld.promo_level = c.promo_level
	WHERE ((ISNULL(ld.price_override,'N') = 'Y' AND ISNULL(c.PROMO_ID,'') NOT IN ('sunps'))
		  OR (ISNULL(ld.discount_per,0) BETWEEN 50 AND 99 AND ISNULL(c.PROMO_ID,'') NOT IN ('aap','eag','ff','pc'))
		  )
		  OR c.user_category = 'ST-CL'
		  OR 
		  ( c.lsales <> 0 AND c.doctype = 'I'
          -- AND (1 - (asales - areturns) / lsales)
		  AND (1 - (c.asales) / CASE WHEN c.lsales = 0 THEN 1 ELSE c.lsales end)
          BETWEEN .8 AND .99);

    IF (OBJECT_ID('cvo.dbo.cvo_sbm_details') IS NOT NULL)
    -- drop table cvo.dbo.cvo_sbm_details
    BEGIN
        SELECT @numrecs = COUNT(*)
        FROM dbo.cvo_sbm_details
        WHERE yyyymmdd
        BETWEEN @first AND @last;

        SET @numrecs_to_delete
            = @numrecs / CASE WHEN DATEDIFF(MONTH, @first, @last) <> 0 THEN DATEDIFF(MONTH, @first, @last) ELSE 1 END;

        -- delete a month at a time

        --			SELECT COUNT(*) FROM cvo_sbm_details WHERE yyyymmdd BETWEEN '9/1/2016' AND '12/31/2016' - 535k

        WHILE @numrecs > 0
        BEGIN;
            --DELETE TOP (@numrecs_to_delete)
            --FROM dbo.cvo_sbm_details
            --WHERE yyyymmdd
            --BETWEEN @first AND @last;
            WITH dd
            AS
            (
            SELECT TOP (@numrecs_to_delete)
                   id
            FROM dbo.cvo_sbm_details AS sd
            WHERE yyyymmdd
            BETWEEN @first AND @last
            )
            DELETE FROM dd;

            SELECT @numrecs = COUNT(*)
            FROM dbo.cvo_sbm_details
            WHERE yyyymmdd
            BETWEEN @first AND @last;
        END;
    END;


    IF (OBJECT_ID('cvo.dbo.cvo_sbm_details') IS NULL)
    BEGIN
        CREATE TABLE dbo.cvo_sbm_details
        (
            customer VARCHAR(10) NOT NULL,
            ship_to VARCHAR(10) NULL,
            customer_name VARCHAR(40) NULL,
            part_no VARCHAR(30) NULL,
            promo_id VARCHAR(20) NULL,
            promo_level VARCHAR(30) NULL,
            return_code VARCHAR(10) NULL,
            user_category VARCHAR(10) NULL,
            location VARCHAR(10) NULL,
            c_month INT NULL,
            c_year INT NULL,
            X_MONTH INT NULL,
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
            yyyymmdd DATETIME NULL,
            DateOrdered DATETIME NULL,
            orig_return_code VARCHAR(10) NULL,
            id INT IDENTITY(1, 1) NOT NULL,
            isCL INT NULL,
            isBO INT NULL,
            slp VARCHAR(10) NULL
        ) ON [PRIMARY];

        GRANT SELECT ON dbo.cvo_sbm_details TO [public];

        /****** Object:  Index [pk_sbm_details]    Script Date: 2/22/2018 2:50:53 PM ******/
        CREATE CLUSTERED INDEX pk_sbm_details
        ON dbo.cvo_sbm_details (id ASC)
        WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF,
              ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON
             )
        ON [PRIMARY];


        CREATE NONCLUSTERED INDEX idx_cvo_sbm_cust
        ON dbo.cvo_sbm_details (
                               customer ASC,
                               ship_to ASC,
                               yyyymmdd ASC,
                               DateOrdered ASC
                               )
        WITH (SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF)
        ON [PRIMARY];


        CREATE INDEX idx_cvo_sbm_prod
        ON dbo.cvo_sbm_details (
                           part_no ASC,
                           yyyymmdd ASC
                           );

        CREATE INDEX idx_cvo_sbm_prod ON #cvo_sbm_det (part_no ASC);

        CREATE NONCLUSTERED INDEX idx_cvo_sbm_cust_part
        ON dbo.cvo_sbm_details (
                           customer ASC,
                           part_no ASC
                           );

        CREATE NONCLUSTERED INDEX idx_sbm_det_for_drp
        ON dbo.cvo_sbm_details (
                               part_no ASC,
                               location ASC,
                               qsales ASC,
                               qreturns ASC
                               )
        WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF,
              DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON
             )
        ON [PRIMARY];


        CREATE NONCLUSTERED INDEX idx_sbm_details_amts
        ON dbo.cvo_sbm_details (
                               asales,
                               areturns,
                               qsales,
                               qreturns,
                               lsales
                               );

        CREATE NONCLUSTERED INDEX idx_cvo_sbm_yyyymmdd
        ON dbo.cvo_sbm_details (yyyymmdd)
        INCLUDE (
                customer,
                ship_to,
                part_no,
                user_category,
                c_month,
                c_year,
                anet
                );

        --11/17/2015 - for new HS CIR
        CREATE NONCLUSTERED INDEX idx_cvo_sbm_yyyymmdd_cir
        ON dbo.cvo_sbm_details (yyyymmdd)
        INCLUDE (
                customer,
                ship_to,
                part_no,
                return_code,
                user_category,
                qsales,
                qreturns,
                DateOrdered,
                isCL
                );

    END;


    INSERT dbo.cvo_sbm_details
    (
        customer,
        ship_to,
        customer_name,
        part_no,
        promo_id,
        promo_level,
        return_code,
        user_category,
        location,
        c_month,
        c_year,
        X_MONTH,
        month,
        year,
        asales,
        areturns,
        anet,
        qsales,
        qreturns,
        qnet,
        csales,
        lsales,
        yyyymmdd,
        DateOrdered,
        orig_return_code,
        isCL,
        isBO,
        slp
    )
    SELECT customer,
           ship_to,
           ar.address_name customer_name,
           part_no,
           ISNULL(PROMO_ID, '') promo_id,
           ISNULL(promo_level, '') promo_level,
           CASE WHEN return_code LIKE '04%' THEN 'WTY'
           -- 030514 - tag dont' mark sales as exc returns -- oops
           WHEN return_code NOT IN ( '06-13', '06-13B', '06-27', '06-32', '' ) THEN 'EXC'
           WHEN return_code IS NULL THEN '' ELSE ''
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
    FROM #cvo_sbm_det
        LEFT OUTER JOIN dbo.armaster
        (NOLOCK) ar
            ON ar.customer_code = customer
               AND ar.ship_to_code = ship_to
    WHERE (
          asales <> 0
          OR qsales <> 0
          OR areturns <> 0
          OR qreturns <> 0
          )
    GROUP BY customer,
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
             slp;


END;








GO
