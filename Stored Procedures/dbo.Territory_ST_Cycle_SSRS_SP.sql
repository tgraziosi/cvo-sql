SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


-- =============================================
-- Author:		elabarbera
-- Create date: 3/13/2013
-- Description:	Territory ST Cycle Report
-- EXEC Territory_ST_Cycle_SSRS_SP '06/30/2018' , '20201'
-- 033015 - add territory parameter for performance
-- =============================================
CREATE PROCEDURE [dbo].[Territory_ST_Cycle_SSRS_SP]
    @DateTo DATETIME,
    @Terr VARCHAR(1000) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- Territory ST Cycle Report
    --DECLARES
    DECLARE @DateFrom DATETIME;
    --		DECLARE @DateTo datetime		
    DECLARE @JDateFrom INT;
    DECLARE @JDateTo INT;
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
           tmp.ext,
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
           ext,
           invoice_no,
           invoice_date,
           date_shipped,
           date_entered,
           user_category,
           total_amt_order,
           (
           SELECT SUM(ordered)
           FROM ord_list t22
               JOIN inv_master T33
                   ON t22.part_no = T33.part_no
           WHERE t1.order_no = t22.order_no
                 AND t1.ext = t22.order_ext
                 AND t22.order_ext = 0
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
           ext,
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
                 AND t1.ext = t22.order_ext
                 AND t22.order_ext = 0
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
    ) tmp
    ORDER BY Terr,
             cust_code,
             ship_to,
             date_entered DESC;
    -- select * from armaster where status_type='1' and address_type<>9 

    IF (OBJECT_ID('tempdb.dbo.#STCYC') IS NOT NULL)
        DROP TABLE dbo.#STCYC;

    SELECT CASE WHEN status_type = 1 THEN 'Open' ELSE 'Closed' END AS status_type,
           territory_code,
           customer_code,
           ship_to_code,
           address_name,
           city,
           LEFT(postal_code, 5) postal_code,
           contact_phone AS phone,
           (
           SELECT TOP 1
                  order_no
           FROM #OrdersAll T11
           WHERE T1.customer_code = T11.cust_code
                 AND T1.SHIP_TO_CODE = T11.ship_to
                 AND T11.Qty >= 5
           ORDER BY date_shipped DESC
           ) 'Ord#',
           (
           SELECT TOP 1
                  date_entered
           FROM #OrdersAll T11
           WHERE T1.customer_code = T11.cust_code
                 AND T1.SHIP_TO_CODE = T11.ship_to
                 AND T11.Qty >= 5
           ORDER BY date_shipped DESC
           ) 'LastVisitDate',
           (
           SELECT TOP 1
                  user_category
           FROM #OrdersAll T11
           WHERE T1.customer_code = T11.cust_code
                 AND T1.SHIP_TO_CODE = T11.ship_to
                 AND T11.Qty >= 5
           ORDER BY date_shipped DESC
           ) 'Type',
           (
           SELECT TOP 1
                  total_amt_order
           FROM #OrdersAll T11
           WHERE T1.customer_code = T11.cust_code
                 AND T1.SHIP_TO_CODE = T11.ship_to
                 AND T11.Qty >= 5
           ORDER BY date_shipped DESC
           ) 'OrdAmt',
           (
           SELECT TOP 1
                  Qty
           FROM #OrdersAll T11
           WHERE T1.customer_code = T11.cust_code
                 AND T1.SHIP_TO_CODE = T11.ship_to
                 AND T11.Qty >= 5
           ORDER BY date_shipped DESC
           ) 'Qty',
           ISNULL(
           (
           SELECT SUM(anet)
           FROM cvo_sbm_details T2
           WHERE T1.CUSTOMER_CODE = T2.customer
                 AND T1.SHIP_TO_CODE = T2.ship_to
                 AND T2.yyyymmdd
                 BETWEEN @DateFrom AND @DateTo
           ),
           0
                 ) NetSales12,
           CASE WHEN
                (
                SELECT TOP 1
                       date_entered
                FROM #OrdersAll T11
                WHERE T1.customer_code = T11.cust_code
                      AND T1.SHIP_TO_CODE = T11.ship_to
                      AND T11.Qty >= 5
                ORDER BY date_shipped DESC
                ) >= @M1 THEN 1
           WHEN
           (
           SELECT TOP 1
                  date_entered
           FROM #OrdersAll T11
           WHERE T1.customer_code = T11.cust_code
                 AND T1.SHIP_TO_CODE = T11.ship_to
                 AND T11.Qty >= 5
           ORDER BY date_shipped DESC
           ) >= @M2 THEN 2
           WHEN
           (
           SELECT TOP 1
                  date_entered
           FROM #OrdersAll T11
           WHERE T1.customer_code = T11.cust_code
                 AND T1.SHIP_TO_CODE = T11.ship_to
                 AND T11.Qty >= 5
           ORDER BY date_shipped DESC
           ) >= @M3 THEN 3
           WHEN
           (
           SELECT TOP 1
                  date_entered
           FROM #OrdersAll T11
           WHERE T1.customer_code = T11.cust_code
                 AND T1.SHIP_TO_CODE = T11.ship_to
                 AND T11.Qty >= 5
           ORDER BY date_shipped DESC
           ) >= @M4 THEN 4
           WHEN
           (
           SELECT TOP 1
                  date_entered
           FROM #OrdersAll T11
           WHERE T1.customer_code = T11.cust_code
                 AND T1.SHIP_TO_CODE = T11.ship_to
                 AND T11.Qty >= 5
           ORDER BY date_shipped DESC
           ) >= @M5 THEN 5
           WHEN
           (
           SELECT TOP 1
                  date_entered
           FROM #OrdersAll T11
           WHERE T1.customer_code = T11.cust_code
                 AND T1.SHIP_TO_CODE = T11.ship_to
                 AND T11.Qty >= 5
           ORDER BY date_shipped DESC
           ) >= @M6 THEN 6
           WHEN
           (
           SELECT TOP 1
                  date_entered
           FROM #OrdersAll T11
           WHERE T1.customer_code = T11.cust_code
                 AND T1.SHIP_TO_CODE = T11.ship_to
                 AND T11.Qty >= 5
           ORDER BY date_shipped DESC
           ) >= DATEADD(SECOND, 1, DATEADD(WEEK, -28, @DateTo)) THEN 7
           WHEN
           (
           SELECT TOP 1
                  date_entered
           FROM #OrdersAll T11
           WHERE T1.customer_code = T11.cust_code
                 AND T1.SHIP_TO_CODE = T11.ship_to
                 AND T11.Qty >= 5
           ORDER BY date_shipped DESC
           ) >= DATEADD(SECOND, 1, DATEADD(WEEK, -32, @DateTo)) THEN 8
           WHEN
           (
           SELECT TOP 1
                  date_entered
           FROM #OrdersAll T11
           WHERE T1.customer_code = T11.cust_code
                 AND T1.SHIP_TO_CODE = T11.ship_to
                 AND T11.Qty >= 5
           ORDER BY date_shipped DESC
           ) >= DATEADD(SECOND, 1, DATEADD(WEEK, -36, @DateTo)) THEN 9
           WHEN
           (
           SELECT TOP 1
                  date_entered
           FROM #OrdersAll T11
           WHERE T1.customer_code = T11.cust_code
                 AND T1.SHIP_TO_CODE = T11.ship_to
                 AND T11.Qty >= 5
           ORDER BY date_shipped DESC
           ) >= DATEADD(SECOND, 1, DATEADD(WEEK, -42, @DateTo)) THEN 10
           WHEN
           (
           SELECT TOP 1
                  date_entered
           FROM #OrdersAll T11
           WHERE T1.customer_code = T11.cust_code
                 AND T1.SHIP_TO_CODE = T11.ship_to
                 AND T11.Qty >= 5
           ORDER BY date_shipped DESC
           ) >= DATEADD(SECOND, 1, DATEADD(WEEK, -48, @DateTo)) THEN 11
           WHEN
           (
           SELECT TOP 1
                  date_entered
           FROM #OrdersAll T11
           WHERE T1.customer_code = T11.cust_code
                 AND T1.SHIP_TO_CODE = T11.ship_to
                 AND T11.Qty >= 5
           ORDER BY date_shipped DESC
           ) >= DATEADD(SECOND, 1, DATEADD(WEEK, -52, @DateTo)) THEN 12 ELSE 13
           END AS M,
           CASE WHEN
                (
                SELECT TOP 1
                       date_entered
                FROM #OrdersAll T11
                WHERE T1.customer_code = T11.cust_code
                      AND T1.SHIP_TO_CODE = T11.ship_to
                      AND T11.Qty >= 5
                ORDER BY date_shipped DESC
                ) >= @M2 THEN 1
           WHEN
           (
           SELECT TOP 1
                  date_entered
           FROM #OrdersAll T11
           WHERE T1.customer_code = T11.cust_code
                 AND T1.SHIP_TO_CODE = T11.ship_to
                 AND T11.Qty >= 5
           ORDER BY date_shipped DESC
           ) >= @M4 THEN 2
           WHEN
           (
           SELECT TOP 1
                  date_entered
           FROM #OrdersAll T11
           WHERE T1.customer_code = T11.cust_code
                 AND T1.SHIP_TO_CODE = T11.ship_to
                 AND T11.Qty >= 5
           ORDER BY date_shipped DESC
           ) >= @M6 THEN 3 ELSE 4
           END AS R
    INTO #STCYC
    FROM #territory AS t
        JOIN armaster T1
            ON t.territory = T1.territory_code
    --where status_type=1
    --and 
    WHERE address_type <> 9
    GROUP BY status_type,
             territory_code,
             customer_code,
             ship_to_code,
             address_name,
             city,
             postal_code,
             contact_phone;


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
           M,
           R
    FROM #STCYC
    ORDER BY territory_code,
             R,
             M;

END;



GO
