SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[cvo_Territory_BrandSales_sp]
    (
      @terr VARCHAR(1024) = NULL,
      @asofdate DATETIME = NULL
    )
AS

SET NOCOUNT ON;

-- exec cvo_territory_brandsales_sp 20201, '12/7/2016'

	DECLARE @asofdately datetime

    IF @asofdate IS NULL
        SELECT  @asofdate = BeginDate
        FROM    dbo.cvo_date_range_vw AS drv
        WHERE   Period = 'TODAY';

	SELECT @asofdately = DATEADD(YEAR,-1, @asofdate)

    IF ( OBJECT_ID('tempdb.dbo.#t') IS NOT NULL )
        DROP TABLE #t;

    IF ( OBJECT_ID('tempdb.dbo.#territory') IS NOT NULL )
        DROP TABLE #territory;
    CREATE TABLE #territory
        (
          territory VARCHAR(10) ,
          region VARCHAR(3)
        );

    IF @terr IS NULL
        BEGIN
            INSERT  #territory
                    SELECT DISTINCT
                            territory_code ,
                            dbo.calculate_region_fn(territory_code) region 
                    FROM    armaster
                    WHERE   territory_code IS NOT NULL
                    ORDER BY territory_code;
        END;
    ELSE
        BEGIN
            INSERT  INTO #territory
                    ( territory ,
                      region 
                    )
                    SELECT DISTINCT
                            ListItem ,
                            dbo.calculate_region_fn(ListItem) region 
                    FROM    dbo.f_comma_list_to_table(@terr)
                    ORDER BY ListItem;
        END;

    SELECT  t.territory ,
            brands.brand ,
			DATEPART(YEAR,@asofdate) yy,
            0.00 AS mtd_net ,
            0 AS mtd_qty ,
            0.00 AS ytd_net ,
            0 AS ytd_qty
    FROM    #territory AS t
            CROSS JOIN ( SELECT DISTINCT
                                kys brand
                         FROM   category
                         WHERE  void = 'N'
						 AND kys NOT IN ('fp','corp')
                       ) brands

	UNION ALL

        SELECT  t.territory ,
            brands.brand ,
			DATEPART(YEAR,@asofdately) yy,
            0.00 AS mtd_net ,
            0 AS mtd_qty ,
            0.00 AS ytd_net ,
            0 AS ytd_qty
    FROM    #territory AS t
            CROSS JOIN ( SELECT DISTINCT
                                kys brand
                         FROM   category
                         WHERE  void = 'N'
						 AND kys NOT IN ('fp','corp')
                       ) brands

	UNION ALL
    
    SELECT  t.territory ,
            i.category Brand ,
			DATEPART(YEAR,@asofdate) yy,
            CAST(SUM(CASE WHEN MONTH(ISNULL(yyyymmdd, @asofdate)) = MONTH(@asofdate)
                          THEN ISNULL(anet, 0)
                          ELSE 0
                     END) AS DECIMAL(20, 2)) AS mtd_net ,
            CAST(SUM(CASE WHEN MONTH(ISNULL(yyyymmdd, @asofdate)) = MONTH(@asofdate)
                               AND i.type_code IN ( 'frame', 'sun' )
                          THEN ISNULL(qnet, 0)
                          ELSE 0
                     END) AS INTEGER) AS mtd_qty ,
            CAST(SUM(ISNULL(anet, 0)) AS DECIMAL(20, 2)) AS ytd_net ,
            CAST(SUM(CASE WHEN i.type_code IN ( 'frame', 'sun' )
                          THEN ISNULL(qnet, 0)
                          ELSE 0
                     END) AS DECIMAL(20, 2)) AS ytd_qty
    FROM    #territory t
            JOIN armaster ar ON ar.territory_code = t.territory
            JOIN cvo_sbm_details sbm ON sbm.customer = ar.customer_code
                                        AND sbm.ship_to = ar.ship_to_code
            JOIN inv_master i ON i.part_no = sbm.part_no
    WHERE   YEAR(yyyymmdd) = YEAR(@asofdate)
			AND yyyymmdd <= @asofdate
	GROUP BY t.territory, i.category
    
	UNION ALL
    
	SELECT  t.territory ,
            i.category Brand ,
			DATEPART(YEAR,@asofdately) yy,
            CAST(SUM(CASE WHEN MONTH(ISNULL(yyyymmdd, @asofdately)) = MONTH(@asofdately)
                          THEN ISNULL(anet, 0)
                          ELSE 0
                     END) AS DECIMAL(20, 2)) AS mtd_net ,
            CAST(SUM(CASE WHEN MONTH(ISNULL(yyyymmdd, @asofdately)) = MONTH(@asofdately)
                               AND i.type_code IN ( 'frame', 'sun' )
                          THEN ISNULL(qnet, 0)
                          ELSE 0
                     END) AS INTEGER) AS mtd_qty ,
            CAST(SUM(ISNULL(anet, 0)) AS DECIMAL(20, 2)) AS ytd_net ,
            CAST(SUM(CASE WHEN i.type_code IN ( 'frame', 'sun' )
                          THEN ISNULL(qnet, 0)
                          ELSE 0
                     END) AS DECIMAL(20, 2)) AS ytd_qty
    FROM    #territory t
            JOIN armaster ar ON ar.territory_code = t.territory
            JOIN cvo_sbm_details sbm ON sbm.customer = ar.customer_code
                                        AND sbm.ship_to = ar.ship_to_code
            JOIN inv_master i ON i.part_no = sbm.part_no
    WHERE   YEAR(yyyymmdd) = YEAR(@asofdately)
			AND yyyymmdd <= @asofdately
    GROUP BY t.territory, i.category
    ; -- ORDER BY territory_code;

	
GO
GRANT EXECUTE ON  [dbo].[cvo_Territory_BrandSales_sp] TO [public]
GO
