SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		tine graziosi
-- Create date: 122014
-- Description:	Sales Territory/Salesperson ScoreCard (also for NSM  AWARDS)
-- EXEC CVO_Sales_ScoreCard_terr_SP '1/1/2016', '04/01/2016'
-- 7/29/2015 - new counts for retention pcts
-- =============================================
CREATE PROCEDURE [dbo].[CVO_Sales_ScoreCard_Terr_SP]
    @DF DATETIME = NULL,
    @DT DATETIME = NULL
--,@Terr varchar(1024) = null

AS
BEGIN
    SET NOCOUNT ON;
    SET ANSI_WARNINGS OFF;



    DECLARE @DateFrom DATETIME,
            @DateTo DATETIME,
            @Territory VARCHAR(1024);

    -- uncomment for testing
    --DECLARE @DF datetime, @DT datetime
    --select @df = '01/01/2017', @dt = '09/29/2017'
    IF @df IS NULL OR @dt IS NULL
        SELECT @df = begindate, @dt = enddate FROM dbo.cvo_date_range_vw AS drv WHERE period = 'rolling 12 TY'

    SELECT @DateFrom = @DF,
           @DateTo = @DT,
           @Territory = NULL;

    IF (OBJECT_ID('tempdb.dbo.#Territory') IS NOT NULL)
        DROP TABLE dbo.#Territory;

    --declare @Territory varchar(1000)
    --select  @Territory = null

    CREATE TABLE #territory
    (
        territory VARCHAR(8)
    );

    IF @Territory IS NULL
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
        FROM dbo.f_comma_list_to_table(@Territory);
    END;

    --Declare @DateFrom datetime
    --Declare @DateTo datetime
    --Set @DateFrom = '12/1/2013'
    --Set @DateTo = '11/30/2014'
    SET @DateTo = DATEADD(SECOND, -1, DATEADD(D, 1, @DateTo));
    --  select @DateFrom, @DateTo, (dateadd(day,-1,dateadd(year,1,@DateFrom))), dateadd(year,-1,@DateFrom) , dateadd(day,-1,@DateFrom)

    DECLARE @DateFromly DATETIME,
            @DateToly DATETIME;
    SELECT @DateFromly = DATEADD(YEAR, -1, @DateFrom),
           @DateToly = DATEADD(YEAR, -1, @DateTo);

    DECLARE @minBrandSales DECIMAL(20, 8),
            @numbrands INT;
    SELECT @minBrandSales = 750,
           @numbrands = 4;

    -- PULL ALL Territories
    IF (OBJECT_ID('tempdb.dbo.#Terrs') IS NOT NULL)
        DROP TABLE dbo.#Terrs;
    SELECT DISTINCT
           dbo.calculate_region_fn(armaster.territory_code) AS Region,
           armaster.territory_code AS Terr
    INTO #TERRS
    FROM #territory
        INNER JOIN armaster (NOLOCK)
            ON armaster.territory_code = #territory.territory
    WHERE armaster.territory_code NOT LIKE '%00'
    ORDER BY armaster.territory_code;
    -- select * from #Terrs

    -- BUILD REP DATA
    IF (OBJECT_ID('tempdb.dbo.#Slp') IS NOT NULL)
        DROP TABLE dbo.#Slp;
    SELECT dbo.calculate_region_fn(#territory.territory) Region,
           #territory.territory AS Terr,
           REPLACE(salesperson_name, 'DEFAULT', '') AS Salesperson,
           ISNULL(date_of_hire, '1/1/1950') date_of_hire,
           CASE
               WHEN date_of_hire
                    BETWEEN @DateFrom AND DATEADD(DAY, -1, DATEADD(YEAR, 1, @DateFrom)) THEN
                   DATEPART(YEAR, DATEADD(DAY, -1, DATEADD(YEAR, 1, @DateFrom)))
               WHEN date_of_hire
                    BETWEEN DATEADD(YEAR, -1, @DateFrom) AND DATEADD(DAY, -1, @DateFrom) THEN
                   DATEPART(YEAR, DATEADD(DAY, -1, @DateFrom))
               ELSE
                   ISNULL(DATEPART(YEAR, date_of_hire), DATEPART(YEAR, DATEADD(DAY, -1, @DateFrom)))
           END AS ClassOf,
           CASE
               WHEN date_of_hire
                    BETWEEN @DateFrom AND (DATEADD(DAY, -1, DATEADD(YEAR, 1, @DateFrom))) THEN
                   'Newbie'
               WHEN date_of_hire
                    BETWEEN DATEADD(YEAR, -1, @DateFrom) AND DATEADD(DAY, -1, @DateFrom) THEN
                   'Rookie'
               WHEN salesperson_name LIKE '%DEFAULT%'
                    OR salesperson_name LIKE '%COMPANY%' THEN
                   'Empty'
               WHEN date_of_hire > @DateFrom THEN
                   'Newbie'
               ELSE
                   'Veteran'
           END AS Status,
           ISNULL(x.PresCouncil, 0) PC
    INTO #Slp
    FROM #territory
        INNER JOIN arsalesp
            ON arsalesp.territory_code = #territory.territory
        INNER JOIN CVO_TerritoryXref x
            ON #territory.territory = CAST(x.territory_code AS VARCHAR(8))
    WHERE status_type = 1
          AND #territory.territory NOT LIKE '%00'
          AND salesperson_name NOT IN ( 'Marcella Smith', 'Alanna Martin' )
    ORDER BY territory;
    --  select * from #Slp

    IF (OBJECT_ID('tempdb.dbo.#SlpInfo') IS NOT NULL)
        DROP TABLE dbo.#SlpInfo;
    SELECT t1.Region,
           t1.Terr,
           ISNULL(
           (
               SELECT TOP 1 Salesperson FROM #Slp t2 WHERE t1.Terr = t2.Terr
           ),
           (Terr + ' DEFAULT')
                 ) AS Salesperson,
           ISNULL(
           (
               SELECT TOP 1 date_of_hire FROM #Slp t2 WHERE t1.Terr = t2.Terr
           ),
           '1/1/1950'
                 ) AS date_of_hire,
           ISNULL(
           (
               SELECT TOP 1 ClassOf FROM #Slp t2 WHERE t1.Terr = t2.Terr
           ),
           '1950'
                 ) AS ClassOf,
           ISNULL(
           (
               SELECT TOP 1 Status FROM #Slp t2 WHERE t1.Terr = t2.Terr
           ),
           'Empty'
                 ) AS Status,
           ISNULL(
           (
               SELECT TOP 1 PC FROM #Slp t2 WHERE t1.Terr = t2.Terr
           ),
           0
                 ) AS PC,
           0 AS top9
    -- , cast(0 as decimal(20,8)) as netty

    INTO #SlpInfo
    FROM #TERRS t1
    WHERE t1.Region IS NOT NULL;
    -- select * from #SLPInfo

    IF (OBJECT_ID('tempdb.dbo.#salesdata') IS NOT NULL)
        DROP TABLE dbo.#salesdata;
    IF (OBJECT_ID('tempdb.dbo.#brands') IS NOT NULL)
        DROP TABLE dbo.#brands;
    IF (OBJECT_ID('tempdb.dbo.#active') IS NOT NULL)
        DROP TABLE dbo.#active;
    IF (OBJECT_ID('tempdb.dbo.#door500') IS NOT NULL)
        DROP TABLE dbo.#door500;

    SELECT ar.territory_code terr,
           ar.customer_code customer,
           ship_to_code = CASE
                              WHEN car.door = 0 THEN
                                  ''
                              ELSE
                                  ar.ship_to_code
                          END,
           --, address_name = case when car.door = 1 then ar.address_name 
           --		else (select customer_name from arcust (nolock) where customer_code = ar.customer_code) end 
           --, car.door
           i.category brand,
           SUM(   CASE
                      WHEN sbm.yyyymmdd >= @DateFrom THEN
                          ISNULL(sbm.anet, 0)
                      ELSE
                          0
                  END
              ) net_sales_ty,
           SUM(   CASE
                      WHEN sbm.yyyymmdd <= @DateToly THEN
                          ISNULL(sbm.anet, 0)
                      ELSE
                          0
                  END
              ) net_sales_ly
    INTO #salesdata
    FROM #territory
        INNER JOIN armaster ar (NOLOCK)
            ON ar.territory_code = #territory.territory
        INNER JOIN CVO_armaster_all car (NOLOCK)
            ON car.customer_code = ar.customer_code
               AND car.ship_to = ar.ship_to_code
        INNER JOIN cvo_sbm_details sbm (NOLOCK)
            ON sbm.customer = ar.customer_code
               AND sbm.ship_to = ar.ship_to_code
        INNER JOIN inv_master i (NOLOCK)
            ON i.part_no = sbm.part_no
        INNER JOIN inv_master_add ia (NOLOCK)
            ON ia.part_no = i.part_no
    WHERE 1 = 1
          AND
          (
              sbm.yyyymmdd
          BETWEEN @DateFrom AND @DateTo
              OR sbm.yyyymmdd
          BETWEEN @DateFromly AND @DateToly
          )
    GROUP BY ar.territory_code,
             ar.customer_code,
             CASE
                 WHEN car.door = 0 THEN
                     ''
                 ELSE
                     ar.ship_to_code
             END,
             i.category;

    -- get rid of any rolled up customers not in this territory (i.e. 030774)
    UPDATE s
    SET terr = ar.territory_code
    FROM #salesdata s
        INNER JOIN armaster ar (NOLOCK)
            ON ar.customer_code = s.customer
               AND ar.ship_to_code = s.ship_to_code;

    DELETE FROM #salesdata
    WHERE NOT EXISTS
    (
        SELECT 1 FROM #territory WHERE territory = #salesdata.terr
    );

    -- select * from #salesdata

    SELECT terr,
           RIGHT(customer, 5) customer,
           ship_to_code,
           --, address_name
           SUM(net_sales_ty) net_sales,
           SUM(net_sales_ly) net_sales_ly
    INTO #active
    FROM #salesdata
    --where door = 1 
    GROUP BY terr,
             RIGHT(customer, 5),
             ship_to_code
    -- , address_name
    HAVING (
               SUM(net_sales_ty) > 2400
               AND SUM(net_sales_ty) > 0
           )
           OR
           (
               SUM(net_sales_ly) > 2400
               AND SUM(net_sales_ly) > 0
           );

    -- select * from #active

    SELECT terr,
           RIGHT(customer, 5) customer,
           ship_to_code,
           --, address_name
           SUM(net_sales_ty) net_sales,
           SUM(net_sales_ly) net_sales_ly
    INTO #door500
    FROM #salesdata
    --where door = 1 
    GROUP BY terr,
             RIGHT(customer, 5),
             ship_to_code
    --, address_name
    HAVING (
               SUM(net_sales_ty) >= 500
               AND SUM(net_sales_ty) > 0
           )
           OR
           (
               SUM(net_sales_ly) >= 500
               AND SUM(net_sales_ly) > 0
           );
    WITH brands
    AS (SELECT terr,
               RIGHT(customer, 5) customer,
               ship_to_code,
               --, address_name
               brand,
               SUM(net_sales_ty) net_sales
        FROM #salesdata
        --where door = 1
        GROUP BY terr,
                 RIGHT(customer, 5),
                 ship_to_code,
                 --, address_name
                 brand
        HAVING @minBrandSales <= SUM(net_sales_ty)
               AND SUM(net_sales_ty) > 0.00)
    SELECT terr,
           customer,
           ship_to_code,
           -- , address_name
           COUNT(DISTINCT brand) num_brands
    INTO #brands
    FROM brands
    GROUP BY terr,
             customer,
             ship_to_code
    --, address_name
    HAVING @numbrands <= COUNT(DISTINCT brand);

    --select * from #salesdata where terr = 20225 order by customer

    --select * from #brands where terr = 20225

    -- BUILD PROGRAMS SUB REPORT
    IF (OBJECT_ID('tempdb.dbo.#ProgramData') IS NOT NULL)
        DROP TABLE #ProgramData;
    IF (OBJECT_ID('tempdb.dbo.#Progsummary') IS NOT NULL)
        DROP TABLE #Progsummary;
    SELECT t.territory,
           o.order_no,
           o.ext,
           o.promo_id,
           o.promo_level,
           CASE
               WHEN ISNULL(p.season_program, 0) = 1 THEN
                   'S'
               WHEN ISNULL(p.annual_program, 0) = 1 THEN
                   'A'
               ELSE
                   'Z'
           END ProgType,
           o.total_invoice
    INTO #programdata
    FROM #territory t
        INNER JOIN cvo_adord_vw o (NOLOCK)
            ON t.territory = o.Territory
        JOIN CVO_promotions p
            ON p.promo_id = o.promo_id
               AND p.promo_level = o.promo_level
    WHERE 1 = 1
          AND ISNULL(o.promo_id, '') <> '' -- 10/31/2013
          AND o.date_entered
          BETWEEN @DateFrom AND @DateTo
          -- AND ((o.who_entered <> 'backordr' and o.ext = 0) or o.who_entered = 'outofstock') 
          AND o.who_entered <> 'backordr'
          AND o.status <> 'V'
          AND NOT EXISTS
    (
        SELECT 1
        FROM cvo_promo_override_audit poa
        WHERE poa.order_no = o.order_no
              AND poa.order_ext = o.ext
    )
          AND NOT EXISTS
    (
        SELECT 1
        FROM orders r (NOLOCK)
        WHERE r.total_invoice = o.total_invoice
              AND r.orig_no = o.order_no
              AND r.orig_ext = o.ext
              AND r.status = 't'
              AND r.type = 'c'
    );


    UPDATE #programdata
    SET ProgType = 'X'
    WHERE promo_id IN ( 'pc', 'ff', 'rxe', 'rx1' )
          OR promo_level IN ( 'rx', 'try', 'free', 'pc' )
          OR
          (
              promo_id = 've aspire'
              AND promo_level = 'custom'
          );


    -- select promo_id, promo_level, progtype, count(order_no) from #ProgramData group by promo_id, promo_level, progtype

    SELECT pd.territory,
           -- ,AnnualProg = sum(case when promo_id in ('AAP','APR','BEP','RCP','ROT64','FOD','SS','award') then 1 else 0 end)
           AnnualProg = SUM(   CASE
                                   WHEN pd.ProgType = 'A' THEN
                                       1
                                   ELSE
                                       0
                               END
                           ),
           --,SeasonalProg = sum(case when promo_id IN
           -- ('ASPIRE','BOGO','DOR','ME','PURITI','IZOD','KIDS','SUN','sunps','ar','CH','CVO','BCBG', 'ET','SUN SPRING','IZOD CLEAR'
           -- ,'BLUE','JMC','REVO') then 1 else 0 end)
           SeasonalProg = SUM(   CASE
                                     WHEN pd.ProgType = 'S' THEN
                                         1
                                     ELSE
                                         0
                                 END
                             ),
           rxeprog = SUM(   CASE
                                WHEN pd.promo_id IN ( 'rxe' ) THEN
                                    1
                                ELSE
                                    0
                            END
                        ),
           aspireprog = SUM(   CASE
                                   WHEN pd.promo_id IN ( 'aspire' ) THEN
                                       1
                                   ELSE
                                       0
                               END
                           )
    INTO #progsummary
    FROM #programdata pd
    GROUP BY pd.territory;


    -- BUILD STOCK ORDERS SUB REPORT


    -- -- # STOCK ORDERS PER MONTH  
    -- PULL DATA FOR ST SHIPPED ORDERS / CREDITS OVER 5PCS
    IF (OBJECT_ID('tempdb.dbo.#Invoices') IS NOT NULL)
        DROP TABLE #Invoices;
    -- Orders
    SELECT o.type,
           o.status,
           car.door,
           ar.territory_code,
           cust_code,
           ship_to = CASE
                         WHEN car.door = 1 THEN
                             o.ship_to
                         ELSE
                             ''
                     END,
           cust_key = cust_code + CASE
                                      WHEN car.door = 1 THEN
                                          o.ship_to
                                      ELSE
                                          ''
                                  END,
           promo_id,
           user_category,
           o.order_no,
           o.ext,
           QTY = SUM(ol.qty),
           SUM(total_amt_order - total_discount) ord_value,
           added_by_date,
           o.date_entered,
           DATEADD(DAY, DATEDIFF(DAY, 0, o.date_shipped), 0) date_shipped,
           DATEADD(mm, DATEDIFF(MONTH, 0, o.date_shipped), 0) period,
           MONTH(date_shipped) AS X_MONTH
    INTO #invoices
    FROM #territory
        JOIN armaster (NOLOCK) ar
            ON #territory.territory = ar.territory_code
        INNER JOIN CVO_armaster_all (NOLOCK) car
            ON car.customer_code = ar.customer_code
               AND car.ship_to = ar.ship_to_code
        INNER JOIN orders_all (NOLOCK) o
            ON o.cust_code = ar.customer_code
               AND o.ship_to = ar.ship_to_code
        INNER JOIN CVO_orders_all (NOLOCK) co
            ON o.order_no = co.order_no
               AND o.ext = co.ext
        -- inner JOIN ORD_LIST (NOLOCK) ol ON o.ORDER_NO = ol.ORDER_NO AND o.EXT=ol.ORDER_EXT
        -- inner join inv_master (nolock) i on ol.part_no=i.part_no
        INNER JOIN
        (
            SELECT ol.order_no,
                   ol.order_ext,
                   SUM(ol.shipped) qty
            FROM ord_list ol (NOLOCK)
                INNER JOIN inv_master (NOLOCK) i
                    ON ol.part_no = i.part_no
            WHERE type_code IN ( 'frame', 'sun' )
            GROUP BY order_no,
                     order_ext
        ) AS ol
            ON ol.order_no = o.order_no
               AND ol.order_ext = o.ext
    WHERE o.status = 't'
          AND o.date_shipped <= @DateTo
          AND type = 'I'
          AND o.who_entered <> 'backordr'
          -- and type_code in('sun','frame')
          AND user_category LIKE 'ST%'
          AND RIGHT(user_category, 2) NOT IN ( 'RB', 'TB' )
    -- and (total_amt_order - total_discount) <> 0 
    -- and user_category not in ( 'ST-RB', 'DO')
    GROUP BY ar.territory_code,
             door,
             cust_code,
             o.ship_to,
             co.promo_id,
             user_category,
             o.order_no,
             o.ext,
             o.status,
             o.type,
             added_by_date,
             date_entered,
             date_shipped;

    -- credits
    INSERT INTO #invoices
    SELECT o.type,
           o.status,
           car.door,
           ar.territory_code,
           cust_code,
           ship_to = CASE
                         WHEN car.door = 1 THEN
                             o.ship_to
                         ELSE
                             ''
                     END,
           cust_key = cust_code + CASE
                                      WHEN car.door = 1 THEN
                                          o.ship_to
                                      ELSE
                                          ''
                                  END,
           promo_id,
           user_category,
           o.order_no,
           o.ext,
           QTY = -1 * SUM(ol.qty),
           -1 * SUM(total_amt_order - total_discount) ord_value,
           added_by_date,
           o.date_entered,
           DATEADD(DAY, DATEDIFF(DAY, 0, o.date_shipped), 0) date_shipped,
           DATEADD(mm, DATEDIFF(MONTH, 0, o.date_shipped), 0) period,
           MONTH(date_shipped) AS X_MONTH
    FROM #territory
        JOIN armaster (NOLOCK) ar
            ON #territory.territory = ar.territory_code
        INNER JOIN CVO_armaster_all (NOLOCK) car
            ON car.customer_code = ar.customer_code
               AND car.ship_to = ar.ship_to_code
        INNER JOIN orders_all (NOLOCK) o
            ON o.cust_code = ar.customer_code
               AND o.ship_to = ar.ship_to_code
        INNER JOIN CVO_orders_all (NOLOCK) co
            ON o.order_no = co.order_no
               AND o.ext = co.ext
        INNER JOIN
        (
            SELECT order_no,
                   order_ext,
                   SUM(cr_shipped) qty
            FROM ord_list (NOLOCK) ol
                INNER JOIN inv_master (NOLOCK) i
                    ON ol.part_no = i.part_no
            WHERE type_code IN ( 'sun', 'frame' )
            GROUP BY order_no,
                     order_ext
        ) AS ol
            ON ol.order_no = o.order_no
               AND ol.order_ext = o.ext
    WHERE o.status = 't'
          AND o.date_shipped <= @DateTo
          AND type = 'C'
          AND o.who_entered <> 'backordr'
          AND EXISTS
    (
        SELECT 1
        FROM ord_list ol
        WHERE ol.order_no = o.order_no
              AND ol.order_ext = o.ext
              AND ol.return_code LIKE '06%'
    )
    GROUP BY ar.territory_code,
             door,
             cust_code,
             o.ship_to,
             co.promo_id,
             user_category,
             o.order_no,
             o.ext,
             o.status,
             o.type,
             added_by_date,
             date_entered,
             date_shipped;


    -- select * from #Invoices   where territory_code = 20299

    -- Pull Unique Custs Orders by Month >=5pcs
    IF (OBJECT_ID('tempdb.dbo.#InvStCount') IS NOT NULL)
        DROP TABLE #InvStCount;
    SELECT territory_code,
           COUNT(DISTINCT cust_key) STOrds,
           SUM(ISNULL(ord_value, 0)) ord_value,
           X_MONTH
    INTO #InvStCount
    FROM #invoices
    WHERE 1 = 1
          AND date_shipped
          BETWEEN @DateFrom AND @DateTo
          AND (ord_value) <> 0
    GROUP BY territory_code,
             cust_key,
             X_MONTH
    HAVING SUM(QTY) >= 5;
    --order by territory_code, X_Month, cust_code
    -- select * from #InvStCount order by territory_code, cust_code

    -- REACTIVATED -- -- PULL Last & 2nd Last ST Order
    IF (OBJECT_ID('tempdb.dbo.#DATA') IS NOT NULL)
        DROP TABLE #DATA;

    SELECT t1.territory_code AS Territory,
           t1.customer_code,
           ship_to_code,
           t2.door,
           added_by_date,
           SUM(anet) YTDNET,
           -- FirstSTNew
           LastST =
           (
               SELECT MIN(date_shipped)
               FROM #invoices inv
               WHERE type = 'i'
                     AND QTY >= 5
                     AND date_shipped >= @DateFrom
                     AND inv.cust_code = t1.customer_code
                     AND inv.ship_to = t1.ship_to_code
           ),
           -- PrevstNew
           [2ndLastST] =
           (
               SELECT MAX(date_shipped)
               FROM #invoices t11
               WHERE type = 'i'
                     AND t11.date_shipped <
                     (
                         SELECT MIN(inv.date_shipped)
                         FROM #invoices inv
                         WHERE type = 'i'
                               AND QTY >= 5
                               AND date_shipped >= @DateFrom
                               AND inv.cust_code = t1.customer_code
                               AND inv.ship_to = t1.ship_to_code
                     )
                     AND QTY >= 5
                     AND t11.cust_code = t1.customer_code
                     AND t11.ship_to = t1.ship_to_code
           )
    INTO #DATA
    FROM armaster t1 (NOLOCK)
        JOIN CVO_armaster_all t2 (NOLOCK)
            ON t1.customer_code = t2.customer_code
               AND t1.ship_to_code = t2.ship_to
        JOIN cvo_sbm_details t3
            ON RIGHT(t3.customer, 5) = RIGHT(t1.customer_code, 5)
               AND t3.ship_to = t1.ship_to_code
        INNER JOIN #territory
            ON #territory.territory = t1.territory_code
    WHERE t1.address_type <> 9
          AND t2.door = 1
    -- AND yyyymmdd BETWEEN @DateFrom AND @DateTo
    GROUP BY t1.territory_code,
             t1.customer_code,
             ship_to_code,
             t2.door,
             added_by_date;
    -- select * from #Data WHERE CUSTOMER_CODE = '047859'
    -- select * from #INVOICES WHERE CUST_CODE = '047859' ORDER BY DATE_SHIPPED DESC

    IF (OBJECT_ID('tempdb.dbo.#DATA2') IS NOT NULL)
        DROP TABLE #DATA2;

    SELECT T1.Territory,
           T1.customer_code,
           T1.ship_to_code,
           T1.door,
           T1.added_by_date,
           T1.YTDNET,
           T1.LastST,
           T1.[2ndLastST],
           CASE
               WHEN DATEDIFF(D, ISNULL([2ndLastST], LastST), LastST) > 365
                    AND LastST > @DateFrom
                    AND added_by_date < @DateFrom THEN
                   'REA'
               ELSE
                   ''
           END AS STAT,
           CASE
               WHEN DATEDIFF(D, ISNULL([2ndLastST], LastST), LastST) > 365
                    AND LastST > @DateFrom
                    AND added_by_date < @DateFrom THEN
                   ISNULL(MONTH(LastST), 1)
               ELSE
                   ''
           END AS X_MONTH
    INTO #DATA2
    FROM #DATA T1;

    -- select stat,* from #Data2 where stat <> ''

    -- FINAL FOR ST COUNT & REA COUNT
    IF (OBJECT_ID('tempdb.dbo.#STREAD') IS NOT NULL)
        DROP TABLE #STREAD;
    SELECT tmp.Territory,
           tmp.NumStOrds,
           tmp.ord_value,
           tmp.NumRea
    INTO #STREAD
    FROM
    (
        SELECT territory_code AS Territory,
               COUNT(STOrds) NumStOrds,
               SUM(ord_value) ord_value,
               0 AS NumRea
        FROM #InvStCount
        WHERE STOrds <> 0
        GROUP BY territory_code,
                 X_MONTH
        UNION ALL
        SELECT Territory,
               0 AS NumStOrds,
               0 AS ord_value,
               COUNT(door) NumRea
        FROM #DATA2
        WHERE STAT = 'REA'
        GROUP BY Territory
    ) tmp
    ORDER BY Territory;

    IF (OBJECT_ID('tempdb.dbo.#STREA') IS NOT NULL)
        DROP TABLE #STREA;
    SELECT Territory,
           SUM(NumStOrds) NumStOrds,
           SUM(ord_value) ord_value,
           SUM(NumRea) NumRea
    INTO #STREA
    FROM #STREAD
    GROUP BY Territory;
    -- Select * from #STREA

    -- BUILD TERRITORY SALES

    IF (OBJECT_ID('tempdb.dbo.#t1') IS NOT NULL)
        DROP TABLE #t1;

    SELECT T.Terr,
           return_code,
           user_category,
           SUM(anet) NETTY,
           SUM(asales) Gross,
           SUM(areturns) Ret,
           CASE
               WHEN return_code = '' THEN
                   SUM(areturns)
           END AS RetSA,
           CASE
               WHEN user_category LIKE 'RX%'
                    AND RIGHT(user_category, 2) NOT IN ( 'RB', 'TB' ) THEN
                   SUM(anet)
           END AS RX
    INTO #t1
    FROM #TERRS T
        LEFT OUTER JOIN armaster T2
            ON T.Terr = T2.territory_code
        LEFT OUTER JOIN cvo_sbm_details t1
            ON t1.customer = T2.customer_code
               AND t1.ship_to = T2.ship_to_code
    WHERE yyyymmdd
    BETWEEN @DateFrom AND @DateTo
    GROUP BY T.Terr,
             return_code,
             user_category
    ORDER BY T.Terr,
             user_category,
             return_code;

    UPDATE #SlpInfo
    SET #SlpInfo.top9 = CASE
                            WHEN r.top9 <= 9 THEN
                                1
                            ELSE
                                0
                        END
    -- , #slpinfo.netty = r.netty
    FROM #SlpInfo
        INNER JOIN
        (
            SELECT rr.Terr,
                   rr.netty,
                   ROW_NUMBER() OVER (ORDER BY rr.netty DESC) AS top9
            FROM
            (
                SELECT #t1.Terr,
                       SUM(#t1.NETTY) netty
                FROM #t1
                    INNER JOIN CVO_TerritoryXref x
                        ON #t1.Terr = CAST(x.territory_code AS VARCHAR(8))
                    INNER JOIN #SlpInfo s
                        ON s.Terr = #t1.Terr
                WHERE ISNULL(x.PresCouncil, 0) = 0
                      AND s.Status = 'Veteran'
                      AND x.Status = 1
                GROUP BY #t1.Terr
            ) AS rr
        ) AS r
            ON r.Terr = #SlpInfo.Terr;

    -- select * from #slpinfo

    -- SELECT * FROM #T1 where Terr in ('40449','30315')

    IF (OBJECT_ID('tempdb.dbo.#TerrSales') IS NOT NULL)
        DROP TABLE #TerrSales;

    SELECT T.Terr,
           ISNULL(SUM(NETTY), 0) NetSTY,
           ISNULL(g_sales.netsly, 0) netsly,
           ISNULL(g_sales.netsty_goal, 0) netsty_goal,
           ISNULL(SUM(Gross), 0) Gross,
           ISNULL(SUM(Ret), 0) Ret,
           ISNULL(SUM(RetSA), 0) RetSa,
           ISNULL(SUM(RX), 0) RX,
           -- add sales goal for the year ending @dateto
           TerrGoal = ISNULL(
                      (
                          SELECT SUM(ISNULL(goal_amt, 0))
                          FROM dbo.cvo_territory_goal g
                          WHERE T.Terr = g.territory_code
                                AND g.yyear = YEAR(@DateTo)
                      ),
                      0
                            )
    INTO #TerrSales
    FROM #TERRS T
        LEFT OUTER JOIN #t1 t1
            ON T.Terr = t1.Terr
        LEFT OUTER JOIN
        (
            SELECT ar.territory_code,
                   SUM(   CASE
                              WHEN yyyymmdd
                                   BETWEEN @DateFromly AND @DateToly THEN
                                  ISNULL(anet, 0)
                              ELSE
                                  0
                          END
                      ) netsly,
                   SUM(   CASE
                              WHEN yyyymmdd
                                   BETWEEN @DateFrom AND @DateTo
                                   AND t11.part_no NOT LIKE 'AS%' THEN
                                  ISNULL(anet, 0)
                              ELSE
                                  0
                          END
                      ) netsty_goal
            FROM cvo_sbm_details t11
                JOIN armaster ar
                    ON t11.customer = ar.customer_code
                       AND t11.ship_to = ar.ship_to_code
            WHERE 1 = 1
                  AND
                  (
                      yyyymmdd
                  BETWEEN @DateFromly AND @DateToly
                      OR yyyymmdd
                  BETWEEN @DateFrom AND @DateTo
                  )
            GROUP BY ar.territory_code
        ) g_sales
            ON g_sales.territory_code = T.Terr
    GROUP BY T.Terr,
             t1.Terr,
             g_sales.netsly,
             g_sales.netsty_goal;

    -- select * from #TerrSales Order by Terr

    -- FINAL SELECT
    IF (OBJECT_ID('tempdb.dbo.#FINAL') IS NOT NULL)
        DROP TABLE #FINAL;

    SELECT T1.Region,
           T1.Terr,
           T1.Salesperson,
           T1.date_of_hire,
           T1.ClassOf,
           T1.Status,
           T1.PC,
           T1.top9,
           Active = ISNULL(
                    (
                        SELECT COUNT(customer)
                        FROM #active t3
                        WHERE T1.Terr = t3.terr
                              AND t3.net_sales > 2400
                    ),
                    0
                          ),
           ReActive = ISNULL(
                      (
                          SELECT SUM(NumRea) FROM #STREA T5 WHERE T1.Terr = T5.Territory
                      ),
                      0
                            ),
           New = ISNULL(
                 (
                     SELECT COUNT(customer_code)
                     FROM #DATA2 t6
                     WHERE T1.Terr = t6.Territory
                           AND
                           (
                               (
                                   added_by_date >= @DateFrom
                                   AND ISNULL(LastST, 0) >= @DateFrom
                               )
                               OR
                               (
                                   LastST >= @DateFrom
                                   AND ISNULL([2ndLastST], 0) = 0
                               )
                           )
                 ),
                 0
                       ),
           STOrds = ISNULL(
                    (
                        SELECT SUM(NumStOrds) FROM #STREA T5 WHERE T1.Terr = T5.Territory
                    ),
                    0
                          ),
           ord_value = ISNULL(
                       (
                           SELECT SUM(ord_value) FROM #STREA WHERE T1.Terr = #STREA.Territory
                       ),
                       0
                             ),
           ISNULL(ps.AnnualProg, 0) AnnualProg,
           ISNULL(ps.SeasonalProg, 0) SeasonalProg,
           ISNULL(ps.rxeprog, 0) RXEProg,
           ISNULL(ps.aspireprog, 0) AspireProg,
           --ISNULL((SELECT COUNT(Order_no) from #ProgramData T4 where t1.terr=t4.territory 	and promo_id in ('AAP','APR','BEP','RCP','ROT64','FOD','SS') ),0)AnnualProg,
           --ISNULL((SELECT COUNT(Order_no) from #ProgramData T4 where t1.terr=t4.territory 	and promo_id in ('BOGO','DOR','ME','PURITI','IZOD','KIDS','SUN','sunps','T3','CH','CVO','BCBG', 'ET', 'SUN SPRING', 'IZOD CLEAR'  ) ),0)SeasonalProg,  
           --ISNULL((SELECT COUNT(Order_no) from #ProgramData T4 where t1.terr=t4.territory 	and promo_id in ('RXE') ),0)RXEProg,  

           ISNULL(
           (
               SELECT COUNT(customer) FROM #brands T2 WHERE T1.Terr = T2.terr
           ),
           0
                 ) [4Brands],
           -- ISNULL((SELECT SUM(NETSTY)-SUM(NETSLY) FROM #TerrSales T3 WHERE T1.TERR=T3.TERR ),0)IncreaseDol,
           IncreaseDol = t.NetSTY - t.netsly,
           IncreasePct = CASE
                             WHEN t.netsly = 0 THEN
                                 1
                             WHEN t.netsly < 0 THEN
           (t.NetSTY - t.netsly) / (t.netsly * -1)
                             ELSE
           (t.NetSTY - t.netsly) / t.netsly
                         END,
           RXPct = CASE
                       WHEN t.NetSTY = 0 THEN
                           0
                       ELSE
                           t.RX / t.NetSTY
                   END,
           GrossSTY = t.Gross,
           RetSRATY = t.RetSa,
           RetPct = CASE
                        WHEN t.Gross = 0
                             AND t.RetSa = 0 THEN
                            0
                        WHEN t.Gross = 0 THEN
                            0
                        ELSE
                            t.RetSa / t.Gross
                    END,
           --ISNULL((SELECT CASE WHEN SUM(NETSLY) = 0 THEN 1 
           --			  WHEN SUM(NETSLY) < 0 THEN ((SUM(NETSTY)-SUM(NETSLY))/-SUM(NETSLY))
           --			  ELSE ((SUM(NETSTY)-SUM(NETSLY))/SUM(NETSLY)) END 
           --		 from #TerrSales T3 WHERE T1.TERR=T3.TERR),0)IncreasePct,
           --ISNULL((SELECT CASE WHEN sum(NETSTY) = 0 THEN 0 
           --	  ELSE sum(RX)/sum(NETSTY) END 
           -- from #TerrSales T3 WHERE T1.TERR=T3.TERR),0) RXPct,
           --  ISNULL((SELECT sum(Gross) from #TerrSales T3 WHERE T1.TERR=T3.TERR),0)GrossSTY,
           --ISNULL((SELECT sum(RetSa) from #TerrSales T3 WHERE T1.TERR=T3.TERR),0)RetSRATY,
           --  ISNULL((SELECT CASE WHEN sum(Gross) = 0 AND sum(RetSa) = 0 THEN 0 
           --				ELSE sum(RetSa)/sum(Gross) END 
           --		 from #TerrSales T3 WHERE T1.TERR=T3.TERR),0)RetPct,
           ISNULL(
           (
               SELECT COUNT(customer)
               FROM #door500 T3
               WHERE T1.Terr = T3.terr
                     AND T3.net_sales > 500
           ),
           0
                 ) Door500,
           --ISNULL((SELECT SUM(NETSTY) FROM #TerrSales T3 WHERE T1.TERR=T3.TERR ),0)NetsTY,
           --ISNULL((SELECT SUM(RX) FROM #TerrSales T3 WHERE T1.TERR=T3.TERR ),0)RXs,
           --ISNULL((SELECT SUM(NETSLY) FROM #TerrSales T3 WHERE T1.TERR=T3.TERR ),0)NetsLY
           t.NetSTY,
           t.netsty_goal,
           RXs = t.RX,
           ISNULL(t.netsly, 0) NetSLY,
           ISNULL(t.TerrGoal, 0) TerrGoal,
           TerrGoalPCT = CASE
                             WHEN ISNULL(t.TerrGoal, 0) = 0 THEN
                                 0
                             ELSE
                                 ISNULL(t.netsty_goal, 0) / t.TerrGoal
                         END,
           -- 7/29/2015 - new counts for retention pcts
           activeretaincnt = ISNULL(
                             (
                                 SELECT COUNT(customer)
                                 FROM #active a
                                 WHERE a.terr = T1.Terr
                                       -- AND a.net_sales > a.net_sales_ly
                                       AND a.net_sales > 2400
                                       AND a.net_sales_ly > 2400
                             ),
                             0
                                   ),
           door500retaincnt = ISNULL(
                              (
                                  SELECT COUNT(customer)
                                  FROM #door500 a
                                  WHERE a.terr = T1.Terr
                                        -- AND a.net_sales > a.net_sales_ly
                                        AND a.net_sales >= 500
                                        AND a.net_sales_ly >= 500
                              ),
                              0
                                    ),
           activeretainvalue = ISNULL(
                               (
                                   SELECT SUM(net_sales) - SUM(net_sales_ly)
                                   FROM #active a
                                   WHERE a.terr = T1.Terr
                                         AND a.net_sales > 2400
                                         AND a.net_sales_ly > 2400
                               ),
                               0
                                     ),
           door500retainvalue = ISNULL(
                                (
                                    SELECT SUM(net_sales) - SUM(net_sales_ly)
                                    FROM #door500 a
                                    WHERE a.terr = T1.Terr
                                          AND a.net_sales >= 500
                                          AND a.net_sales_ly >= 500
                                ),
                                0
                                      )
    INTO #FINAL
    FROM #SlpInfo T1
        LEFT OUTER JOIN #TerrSales t
            ON t.Terr = T1.Terr
        LEFT OUTER JOIN #progsummary ps
            ON ps.territory = T1.Terr;
    -- select * from #final

    SELECT #FINAL.Region,
           #FINAL.Terr,
           #FINAL.Salesperson,
           #FINAL.date_of_hire,
           #FINAL.ClassOf,
           #FINAL.Status,
           #FINAL.PC,
           #FINAL.top9,
           #FINAL.Active,
           #FINAL.ReActive,
           #FINAL.New,
           #FINAL.STOrds,
           #FINAL.ord_value,
           #FINAL.AnnualProg,
           #FINAL.SeasonalProg,
           #FINAL.RXEProg,
           #FINAL.AspireProg,
           #FINAL.[4Brands],
           #FINAL.IncreaseDol,
           #FINAL.IncreasePct,
           #FINAL.RXPct,
           #FINAL.GrossSTY,
           #FINAL.RetSRATY,
           #FINAL.RetPct,
           #FINAL.Door500,
           #FINAL.NetSTY,
           #FINAL.netsty_goal,
           #FINAL.RXs,
           #FINAL.NetSLY,
           #FINAL.TerrGoal,
           #FINAL.TerrGoalPCT,
           #FINAL.activeretaincnt,
           #FINAL.door500retaincnt,
           #FINAL.activeretainvalue,
           #FINAL.door500retainvalue,
           veteran_status = CASE
                                WHEN Status = 'Veteran' THEN
                                    CASE
                                        WHEN PC = 1 THEN
                                            'PC'
                                        WHEN top9 = 1 THEN
                                            'Top 9'
                                        ELSE
                                            'Other'
                                    END
                                ELSE
                                    ''
                            END
    FROM #FINAL;
-- Order by Terr

-- EXEC CVO_Sales_ScoreCard_terr_SP '1/1/2015', '12/31/2015'
--SELECT * FROM #active where terr = 30302
--SELECT * FROM #door500

--SELECT *
----SUM(net_sales) - SUM(net_sales_ly) 
--FROM #active a WHERE a.terr = 30302
--AND a.net_sales > 2400 AND a.net_sales_ly > 2400

END;

--SELECT SUM(anet), x_month, year, ship_to
-- FROM cvo_sbm_details WHERE customer = '032056' AND YEAR IN (2014, 2015) 
-- GROUP BY X_MONTH, YEAR, ship_to

-- SELECT * FROM dbo.armaster WHERE customer_code = '032056'

--SELECT * FROM #data2 AS s WHERE (s.Territory='20203' and stat='rea') OR s.customer_code = '013853'



GO
