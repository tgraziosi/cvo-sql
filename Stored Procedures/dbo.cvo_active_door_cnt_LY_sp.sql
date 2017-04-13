SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[cvo_active_door_cnt_LY_sp] @Terr VARCHAR(1024) = NULL
AS

-- execute cvo_active_door_cnt_ly_sp

BEGIN

    DECLARE @territory VARCHAR(1000)
    ;
    SET @territory = @Terr
    ;

    CREATE TABLE #territory
    (
        territory VARCHAR(10),
        region VARCHAR(3)
    )
    ;
    IF @territory IS NULL
    BEGIN
        INSERT INTO #territory
        (
            territory,
            region
        )
        SELECT DISTINCT
            territory_code,
            dbo.calculate_region_fn(territory_code) region
        FROM armaster (NOLOCK)
        WHERE
            status_type = 1
            AND address_type <> 9
        ; -- active accounts only
    END
    ;
    ELSE
    BEGIN
        INSERT INTO #territory
        (
            territory,
            region
        )
        SELECT
            ListItem,
            dbo.calculate_region_fn(ListItem) region
        FROM dbo.f_comma_list_to_table(@territory)
        ;
    END
    ;


    -- now get the active door count

    DECLARE
        @datefrom DATETIME,
        @dateto DATETIME,
        @datefromly DATETIME,
        @datetoly DATETIME
    ;
    SELECT
        @datefrom = BeginDate,
        @dateto = EndDate
    FROM dbo.cvo_date_range_vw AS drv
    WHERE Period = 'LAST YEAR'
    ;
    SELECT
        @datefromly = DATEADD(YEAR, -1, @datefrom),
        @datetoly = DATEADD(YEAR, -1, @dateto)
    ;

    -- SELECT * FROM dbo.cvo_date_range_vw AS drv WHERE period = 'last year'

    SELECT
        ar.territory_code terr,
        ar.customer_code customer,
        ship_to_code = CASE
                           WHEN car.door = 0 THEN
                               ''
                           ELSE
                               ar.ship_to_code
                       END,
        SUM(   CASE
                   WHEN sbm.yyyymmdd >= @datefrom THEN
                       ISNULL(sbm.anet, 0)
                   ELSE
                       0
               END
           ) net_sales_ty,
        SUM(   CASE
                   WHEN sbm.yyyymmdd <= @datetoly THEN
                       ISNULL(sbm.anet, 0)
                   ELSE
                       0
               END
           ) net_sales_ly
    INTO #salesdata
    FROM
        #territory AS t
        INNER JOIN armaster ar (NOLOCK)
            ON ar.territory_code = t.territory
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
    WHERE
        1 = 1
        AND
        (
            sbm.yyyymmdd
        BETWEEN @datefrom AND @dateto
            OR sbm.yyyymmdd
        BETWEEN @datefromly AND @datetoly
        )
    GROUP BY
        ar.territory_code,
        ar.customer_code,
        CASE
            WHEN car.door = 0 THEN
                ''
            ELSE
                ar.ship_to_code
        END,
        i.category
    ;

    -- get rid of any rolled up customers not in this territory (i.e. 030774)
    UPDATE s
    SET terr = ar.territory_code
    FROM
        #salesdata s
        INNER JOIN armaster ar (NOLOCK)
            ON ar.customer_code = s.customer
               AND ar.ship_to_code = s.ship_to_code
    ;

    DELETE FROM #salesdata
    WHERE NOT EXISTS
    (
        SELECT 1 FROM #territory AS t WHERE territory = #salesdata.terr
    )
    ;

    -- select * from #salesdata


    SELECT
        t.territory,
        t.region,
        ISNULL(door.Num_ActiveCust, 0) AS ActiveCustCntLY
    FROM
        #territory AS t
        LEFT OUTER JOIN
        (
            SELECT
                terr,
                COUNT(DISTINCT active.customer + active.ship_to_code) Num_ActiveCust
            FROM
            (
                SELECT
                    terr,
                    RIGHT(customer, 5) customer,
                    ship_to_code,
                    SUM(net_sales_ty) net_sales,
                    SUM(net_sales_ly) net_sales_ly
                FROM #salesdata
                GROUP BY
                    terr,
                    RIGHT(customer, 5),
                    ship_to_code
                HAVING
                (
                    SUM(net_sales_ty) > 2400
                    AND SUM(net_sales_ty) > 0
                )
            --OR ( SUM(net_sales_ly) > 2400
            --     AND SUM(net_sales_ly) > 0
            --   )
            ) active
            GROUP BY active.terr
        ) door
            ON door.terr = t.territory
    UNION ALL
    SELECT
        t.region,
        t.region,
        SUM(ISNULL(door.Num_ActiveCust, 0)) AS ActiveCustCntLY
    FROM
        #territory AS t
        LEFT OUTER JOIN
        (
            SELECT
                terr,
                COUNT(DISTINCT active.customer + active.ship_to_code) Num_ActiveCust
            FROM
            (
                SELECT
                    terr,
                    RIGHT(customer, 5) customer,
                    ship_to_code,
                    SUM(net_sales_ty) net_sales,
                    SUM(net_sales_ly) net_sales_ly
                FROM #salesdata
                GROUP BY
                    terr,
                    RIGHT(customer, 5),
                    ship_to_code
                HAVING
                (
                    SUM(net_sales_ty) > 2400
                    AND SUM(net_sales_ty) > 0
                )
            --OR ( SUM(net_sales_ly) > 2400
            --     AND SUM(net_sales_ly) > 0
            --   )
            ) active
            GROUP BY active.terr
        ) door
            ON door.terr = t.territory
    GROUP BY t.region

	UNION ALL
    SELECT
        'TOTAL',
        'TOTAL',
        SUM(ISNULL(door.Num_ActiveCust, 0)) AS ActiveCustCntLY
    FROM
        #territory AS t
        LEFT OUTER JOIN
        (
            SELECT
                terr,
                COUNT(DISTINCT active.customer + active.ship_to_code) Num_ActiveCust
            FROM
            (
                SELECT
                    terr,
                    RIGHT(customer, 5) customer,
                    ship_to_code,
                    SUM(net_sales_ty) net_sales,
                    SUM(net_sales_ly) net_sales_ly
                FROM #salesdata
                GROUP BY
                    terr,
                    RIGHT(customer, 5),
                    ship_to_code
                HAVING
                (
                    SUM(net_sales_ty) > 2400
                    AND SUM(net_sales_ty) > 0
                )
            --OR ( SUM(net_sales_ly) > 2400
            --     AND SUM(net_sales_ly) > 0
            --   )
            ) active
            GROUP BY active.terr
        ) door
            ON door.terr = t.territory
    ;

-- SELECT * FROM #temptable AS t -- WHERE t.Territory IN ('40454','70780','30338')

END
;
GO
