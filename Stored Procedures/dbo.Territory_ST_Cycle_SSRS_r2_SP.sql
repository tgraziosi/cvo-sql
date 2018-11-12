SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


-- =============================================
-- Author:		elabarbera
-- Create date: 3/13/2013
-- Description:	Territory ST Cycle Report
-- EXEC Territory_ST_Cycle_SSRS_SP '06/30/2018' , '70721'
-- EXEC Territory_ST_Cycle_SSRS_r2_SP '06/30/2018' , '70721'
-- 033015 - add territory parameter for performance
-- 07/2018 - rewrite - TAG
-- 10/2018 - added number of visits r12
-- =============================================
CREATE PROCEDURE [dbo].[Territory_ST_Cycle_SSRS_r2_SP]
    @DateTo DATETIME,
    @Terr VARCHAR(1000) = NULL
-- , @debug INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- Territory ST Cycle Report
    --DECLARES
    DECLARE @DateFrom DATETIME;
    --		DECLARE @DateTo datetime		
    DECLARE @M1 DATETIME;
    DECLARE @M2 DATETIME;
    DECLARE @M3 DATETIME;
    DECLARE @M4 DATETIME;
    DECLARE @M5 DATETIME;
    DECLARE @M6 DATETIME;
    DECLARE @territory VARCHAR(1000);
    --SETS
    SELECT @territory = @Terr;
    --		SET @DateTo = '3/5/2014'
    SET @DateFrom = DATEADD(YEAR, -1, DATEADD(dd, 1, @DateTo));
    SET @DateTo = DATEADD(SECOND, -1, @DateTo);
    SET @DateTo = DATEADD(DAY, 1, @DateTo);
    SET @M1 = DATEADD(SECOND, 1, DATEADD(WEEK, -4, @DateTo));
    SET @M2 = DATEADD(SECOND, 1, DATEADD(WEEK, -8, @DateTo));
    SET @M3 = DATEADD(SECOND, 1, DATEADD(WEEK, -12, @DateTo));
    SET @M4 = DATEADD(SECOND, 1, DATEADD(WEEK, -16, @DateTo));
    SET @M5 = DATEADD(SECOND, 1, DATEADD(WEEK, -20, @DateTo));
    SET @M6 = DATEADD(SECOND, 1, DATEADD(WEEK, -24, @DateTo));
    --select @DateFrom, @DateTo



    IF (OBJECT_ID('tempdb.dbo.#Territory') IS NOT NULL)
        DROP TABLE dbo.#Territory;

    --declare @Territory varchar(1000)
    --select  @Territory = null

    CREATE TABLE #territory
    (
        territory VARCHAR(8)
    );

    IF @territory IS NULL
    BEGIN
        INSERT INTO #territory
        (
            territory
        )
        SELECT DISTINCT
               territory_code
        FROM armaster (NOLOCK);
    END;
    ELSE
    BEGIN
        INSERT INTO #territory
        (
            territory
        )
        SELECT ListItem
        FROM dbo.f_comma_list_to_table(@territory);
    END;

    IF (OBJECT_ID('tempdb.dbo.#OrdersAll') IS NOT NULL)
        DROP TABLE dbo.#OrdersAll;
    SELECT tmp.Terr,
           tmp.cust_code,
           tmp.ship_to,
           tmp.address_name,
           tmp.postal_code,
           tmp.phone,
           tmp.order_no,
           tmp.invoice_no,
           tmp.invoice_date,
           tmp.date_shipped,
           tmp.date_entered,
           tmp.user_category,
           tmp.total_amt_order,
           tmp.Qty
    INTO #OrdersAll
    FROM
    (
        SELECT DISTINCT
               t2.territory_code AS Terr,
               cust_code,
               ship_to,
               t2.address_name,
               LEFT(t2.postal_code, 5) postal_code,
               contact_phone AS phone,
               order_no,
               invoice_no,
               invoice_date,
               date_shipped,
               date_entered,
               user_category,
               SUM(total_amt_order) total_amt_order,
               (
                   SELECT SUM(ordered)
                   FROM ord_list t22
                       JOIN orders o
                           ON o.order_no = t22.order_no
                              AND o.ext = t22.order_ext
                       JOIN inv_master T33
                           ON t22.part_no = T33.part_no
                   WHERE t1.order_no = t22.order_no
                         AND o.who_entered <> 'backordr'
                         AND T33.type_code IN ( 'SUN', 'FRAME' )
               ) Qty
        FROM #territory t
            INNER JOIN armaster t2
                ON t.territory = t2.territory_code
            INNER JOIN orders_all t1
                ON t1.cust_code = t2.customer_code
                   AND t1.ship_to = t2.ship_to_code
        WHERE who_entered <> 'backordr'
              AND date_entered
              BETWEEN @DateFrom AND @DateTo
              --and date_entered between '1/1/2013' and '1/31/2013 23:59:59'
              AND user_category NOT LIKE 'RX%'
              AND type = 'I'
              AND status <> 'V'
        GROUP BY LEFT(t2.postal_code, 5),
                 t2.territory_code,
                 t1.cust_code,
                 t1.ship_to,
                 t2.address_name,
                 t2.contact_phone,
                 t1.order_no,
                 t1.invoice_no,
                 t1.invoice_date,
                 t1.date_shipped,
                 t1.date_entered,
                 t1.user_category
        --and status_type = 1
        UNION ALL
        SELECT DISTINCT
               t2.territory_code AS Terr,
               cust_code,
               ship_to,
               t2.address_name,
               LEFT(t2.postal_code, 5) postal_code,
               contact_phone AS phone,
               order_no,
               invoice_no,
               invoice_date,
               date_shipped,
               date_entered,
               user_category,
               total_amt_order,
               (
                   SELECT SUM(ordered)
                   FROM cvo_ord_list_hist t22
                       JOIN inv_master T33
                           ON t22.part_no = T33.part_no
                   WHERE t1.order_no = t22.order_no
                         AND T33.type_code IN ( 'SUN', 'FRAME' )
               ) Qty
        FROM #territory t
            INNER JOIN armaster t2
                ON t2.territory_code = t.territory
            INNER JOIN CVO_orders_all_Hist t1
                ON t1.cust_code = t2.customer_code
                   AND t1.ship_to = t2.ship_to_code
        WHERE who_entered <> 'backordr'
              AND date_entered
              BETWEEN @DateFrom AND @DateTo
              --and date_entered between '1/1/2013' and '1/31/2013 23:59:59'
              AND user_category NOT LIKE 'RX%'
              AND type = 'I'
              AND status = 'V'
    --and status_type = 1
    ) tmp;

    -- select * from armaster where status_type='1' and address_type<>9 

    IF (OBJECT_ID('tempdb.dbo.#STCYC') IS NOT NULL)
        DROP TABLE dbo.#STCYC;

    SELECT CASE
               WHEN status_type = 1 THEN
                   'Open'
               ELSE
                   'Closed'
           END AS status_type,
           territory_code,
           customer_code,
           ship_to_code,
           address_name,
           city,
           LEFT(postal_code, 5) postal_code,
           contact_phone AS phone,
           od.order_no 'Ord#',
           od.date_entered 'LastVisitDate',
           od.user_category 'Type',
           od.total_amt_order 'OrdAmt',
           od.Qty 'Qty',
           ISNULL(sls.anet, 0) NetSales12,
           CASE
               WHEN od.date_entered >= @M1 THEN
                   1
               WHEN od.date_entered >= @M2 THEN
                   2
               WHEN od.date_entered >= @M3 THEN
                   3
               WHEN od.date_entered >= @M4 THEN
                   4
               WHEN od.date_entered >= @M5 THEN
                   5
               WHEN od.date_entered >= @M6 THEN
                   6
               WHEN od.date_entered >= DATEADD(SECOND, 1, DATEADD(WEEK, -28, @DateTo)) THEN
                   7
               WHEN od.date_entered >= DATEADD(SECOND, 1, DATEADD(WEEK, -32, @DateTo)) THEN
                   8
               WHEN od.date_entered >= DATEADD(SECOND, 1, DATEADD(WEEK, -36, @DateTo)) THEN
                   9
               WHEN od.date_entered >= DATEADD(SECOND, 1, DATEADD(WEEK, -42, @DateTo)) THEN
                   10
               WHEN od.date_entered >= DATEADD(SECOND, 1, DATEADD(WEEK, -48, @DateTo)) THEN
                   11
               WHEN od.date_entered >= DATEADD(SECOND, 1, DATEADD(WEEK, -52, @DateTo)) THEN
                   12
               ELSE
                   13
           END AS M,
           CASE
               WHEN od.date_entered >= @M2 THEN
                   1
               WHEN od.date_entered >= @M4 THEN
                   2
               WHEN od.date_entered >= @M6 THEN
                   3
               ELSE
                   4
           END AS R
    INTO #STCYC
    FROM #territory AS t
        JOIN armaster T1
            ON t.territory = T1.territory_code
        LEFT OUTER JOIN
        (
            SELECT DISTINCT
                   oa.cust_code,
                   oa.ship_to,
                   oa.order_no,
                   oa.date_entered,
                   oa.user_category,
                   oa.total_amt_order,
                   oa.Qty,
                   RANK() OVER (PARTITION BY oa.cust_code, oa.ship_to ORDER BY date_shipped DESC) lastord
            FROM #OrdersAll AS oa
            WHERE oa.Qty >= 5
                  AND oa.date_shipped =
                  (
                      SELECT MIN(oam.date_shipped)
                      FROM #OrdersAll oam
                      WHERE oam.order_no = oa.order_no
                            AND oam.Qty = oa.Qty
                  )
        ) od
            ON od.cust_code = T1.customer_code
               AND od.ship_to = T1.ship_to_code
               AND od.lastord = 1
        LEFT OUTER JOIN
        (
            SELECT T2.customer,
                   T2.ship_to,
                   SUM(anet) anet
            FROM dbo.cvo_sbm_details T2 (NOLOCK)
            WHERE T2.yyyymmdd
            BETWEEN @DateFrom AND @DateTo
            GROUP BY T2.customer,
                     T2.ship_to
        ) sls
            ON sls.customer = T1.customer_code
               AND sls.ship_to = T1.ship_to_code
    --where status_type=1
    --and 
    WHERE address_type <> 9;


    ;WITH r12
    AS (SELECT oa.cust_code,
               oa.ship_to,
               COUNT(DISTINCT DATEPART(MONTH,oa.date_entered)) numvisits
        FROM #OrdersAll AS oa
        WHERE qty >= 5
        GROUP BY oa.cust_code,
                 oa.ship_to)
    SELECT status_type,
           territory_code,
           customer_code,
           ship_to_code,
           address_name,
           city,
           postal_code,
           phone,
           Ord#,
           LastVisitDate,
           Type,
           OrdAmt,
           Qty,
           NetSales12,
           r12.numvisits,
           M,
           R
    FROM #STCYC
        LEFT OUTER JOIN r12
            ON r12.cust_code = #STCYC.customer_code
               AND r12.ship_to = #STCYC.ship_to_code;

END;







GO
GRANT EXECUTE ON  [dbo].[Territory_ST_Cycle_SSRS_r2_SP] TO [public]
GO
