SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[cvo_territory_sales_goal_tracker_r2016_sp]
    @CompareYear INT = NULL ,
--v2
    @territory VARCHAR(1000) = NULL -- multi-valued parameter
AS
    SET NOCOUNT ON;
    BEGIN

-- exec cvo_territory_sales_goal_tracker_r2016_sp 2016, '20201,20202'

--DECLARE @compareyear INT, @territory VARCHAR(1000)
--SELECT @compareyear = 2015, @territory = '20201'


        DECLARE @cy INT ,
            @terr VARCHAR(1000) ,
            @today DATETIME;
        SELECT  @cy = @CompareYear ,
                @terr = @territory ,
                @today = GETDATE();

-- 032614 - tag - performance improvements - add multi-value param for territory
--  move setting the region to last.

--declare @compareyear int
--set @compareyear = 2013

-- 082914 - performance
        DECLARE @sdate DATETIME ,
            @edate DATETIME ,
            @sdately DATETIME ,
            @edately DATETIME;

        IF @cy IS NULL
            SELECT  @cy = YEAR(@today);

        SET @sdately = DATEADD(YEAR, ( @cy - 1 ) - 1900, '01-01-1900');
        SET @edately = CASE WHEN @cy = YEAR(@today)
                            THEN DATEADD(dd,
                                         DATEDIFF(dd, 0,
                                                  DATEADD("yyyy", -1, @today))
                                         + -1, 0)
                            ELSE DATEADD(ms, -2,
                                         ( DATEADD(YEAR,
                                                   ( @cy - 1 ) - 1900 + 1,
                                                   '01-01-1900') ))
                       END;
        SET @sdate = DATEADD(YEAR, ( @cy ) - 1900, '01-01-1900');
        SET @edate = CASE WHEN @cy = YEAR(@today) THEN @today
                          ELSE DATEADD(ms, -2,
                                       ( DATEADD(YEAR, ( @cy ) - 1900 + 1,
                                                 '01-01-1900') ))
                     END;

        IF ( OBJECT_ID('tempdb.dbo.#temp') IS NOT NULL )
            DROP TABLE #temp;

        IF ( OBJECT_ID('tempdb.dbo.#territory') IS NOT NULL )
            DROP TABLE #territory;
        CREATE TABLE #territory
            (
              territory VARCHAR(10) ,
              region VARCHAR(3) ,
              r_id INT ,
              t_id INT IDENTITY(1, 1)
            );

        IF @terr IS NULL
            BEGIN
                INSERT  #territory
                        SELECT DISTINCT
                                territory_code ,
                                dbo.calculate_region_fn(territory_code) region ,
                                0
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

        UPDATE  t
        SET     t.r_id = r.r_id
-- SELECT * 
        FROM    #territory AS t
                JOIN ( SELECT DISTINCT
                                region ,
                                RANK() OVER ( ORDER BY region ) r_id
                       FROM     ( SELECT DISTINCT
                                            region
                                  FROM      #territory
                                ) AS r
                     ) AS r ON t.region = r.region;

-- SELECT * FROM #territory AS t

-- get workdays info
        DECLARE @workday INT ,
            @totalworkdays INT ,
            @pct_month FLOAT;
        SELECT  @workday = dbo.cvo_f_get_work_days(CONVERT(VARCHAR(25), DATEADD(dd,
                                                              -( DAY(@today)
                                                              - 1 ), @today), 101),
                                                   DATEADD(d, -1, @today)); 

        SELECT  @totalworkdays = dbo.cvo_f_get_work_days(CONVERT(VARCHAR(25), DATEADD(dd,
                                                              -( DAY(@today)
                                                              - 1 ), @today), 101),
                                                         CONVERT(VARCHAR(25), DATEADD(dd,
                                                              -( DAY(DATEADD(mm,
                                                              1, @today)) ),
                                                              DATEADD(mm, 1,
                                                              @today)), 101));

        SELECT  @pct_month = CAST(@workday AS FLOAT)
                / CAST(@totalworkdays AS FLOAT);

-- get TY net sales for core, revo and blutech
        SELECT  a.territory_code ,
                ISNULL(c.year, YEAR(@today)) AS Year ,
                SUM(ISNULL(c.anet, 0)) anet ,
                SUM(ISNULL(CASE WHEN i.type_code IN ( 'frame', 'sun' )
                                THEN c.qnet
                           END, 0)) qnet ,
                tot = CASE WHEN ISNULL(i.category, 'Core') IN ( 'revo', 'bt' )
                           THEN i.category
                           ELSE 'Core'
                      END
        INTO    #temp
        FROM    #territory t
                INNER JOIN armaster (NOLOCK) a ON a.territory_code = t.territory
                INNER JOIN cvo_sbm_details c ( NOLOCK ) ON a.customer_code = c.customer
                                                           AND a.ship_to_code = c.ship_to
                INNER JOIN inv_master i ( NOLOCK ) ON i.part_no = c.part_no
        WHERE   1 = 1
-- and (yyyymmdd between @sdately and @edately) or (yyyymmdd between @sdate and @edate)
                AND ( yyyymmdd BETWEEN @sdate AND @edate )
        GROUP BY a.territory_code ,
                c.year ,
                CASE WHEN ISNULL(i.category, 'Core') IN ( 'revo', 'bt' )
                     THEN i.category
                     ELSE 'Core'
                END;

-- fill in the blanks so that all buckets are covered
-- select * from #temp
-- ty
        INSERT  INTO #temp
                SELECT   DISTINCT
                        territory ,
                        @cy AS Year ,
                        0 anet ,
                        0 qnet ,
                        'Core'
                FROM    #territory AS t
                WHERE   NOT EXISTS ( SELECT 1
                                     FROM   #temp
                                     WHERE  #temp.territory_code = t.territory
                                            AND tot = 'core' );

        INSERT  INTO #temp
                SELECT   DISTINCT
                        territory ,
                        @cy AS Year ,
                        0 anet ,
                        0 qnet ,
                        'BT'
                FROM    #territory AS t
                WHERE   NOT EXISTS ( SELECT 1
                                     FROM   #temp
                                     WHERE  #temp.territory_code = t.territory
                                            AND tot = 'bt' );
	
        INSERT  INTO #temp
                SELECT   DISTINCT
                        territory ,
                        @cy AS Year ,
                        0 anet ,
                        0 qnet ,
                        'REVO'
                FROM    #territory AS t
                WHERE   NOT EXISTS ( SELECT 1
                                     FROM   #temp
                                     WHERE  #temp.territory_code = t.territory
                                            AND tot = 'revo' );
-- get this year figures

        SELECT  a.territory_code ,
                a.Year ,
                SUM(a.anet) anet ,
                SUM(a.qnet) qnet ,
                a.tot
        INTO    #ty
        FROM    #temp a
        WHERE   a.Year = @cy
        GROUP BY a.territory_code ,
                a.Year ,
                a.tot;

-- fixup sales person names

        SELECT  t.territory territory_code ,
                salesperson_code = ISNULL(( SELECT TOP 1
                                                    salesperson_name
                                            FROM    arsalesp
                                            WHERE   salesperson_code <> 'smithma'
                                                    AND territory_code = t.territory
                                                    AND ISNULL(date_of_hire,
                                                              '1/1/1900') <= @today
                                                    AND status_type = 1
                                          ), 'Empty') ,
                t.region ,
                t.r_id ,
                t.t_id
        INTO    #s1
        FROM    #territory t;

-- select * From #territory order by territory
-- select * from #s1 where territory_code in (30398,30399) order by territory_code 
-- select * From arsalesp where territory_code = 30398

        SELECT  #ty.territory_code ,
                #s1.salesperson_code ,
                Year ,
                ROUND(anet, 2) anet ,
                qnet ,
                tot ,
                #s1.region ,
                #s1.r_id ,
                #s1.t_id
        FROM    #ty -- ty
                LEFT OUTER JOIN #s1 ON #s1.territory_code = #ty.territory_code
        UNION ALL -- get goals
        SELECT  g.Territory_Code ,
                'Goal' AS salesperson_code ,
                @cy AS yyear ,
                ISNULL(g.Core_Goal_Amt, 0) AS anet ,
                0 AS qnet ,
                'Core' tot ,
                terr.region ,
                #s1.r_id ,
                #s1.t_id
        FROM    #territory terr
                LEFT OUTER JOIN dbo.cvo_terr_scorecard AS g ON terr.territory = g.Territory_Code
                LEFT OUTER JOIN #s1 ON #s1.territory_code = g.Territory_Code
        WHERE   1 = 1
                AND ( g.Stat_Year = CAST(@cy AS VARCHAR(5)) )
        UNION ALL
        SELECT  g.Territory_Code ,
                'Goal' AS salesperson_code ,
                @cy AS yyear ,
                ISNULL(g.Revo_Goal_Amt, 0) AS anet ,
                0 AS qnet ,
                'Revo' tot ,
                terr.region ,
                #s1.r_id ,
                #s1.t_id
        FROM    #territory terr
                LEFT OUTER JOIN dbo.cvo_terr_scorecard AS g ON terr.territory = g.Territory_Code
                LEFT OUTER JOIN #s1 ON #s1.territory_code = g.Territory_Code
        WHERE   1 = 1
                AND ( g.Stat_Year = CAST(@cy AS VARCHAR(5)) )
        UNION ALL
        SELECT  g.Territory_Code ,
                'Goal' AS salesperson_code ,
                @cy AS yyear ,
                ISNULL(g.Blutech_Goal_Amt, 0) AS anet ,
                0 AS qnet ,
                'BT' tot ,
                terr.region ,
                #s1.r_id ,
                #s1.t_id
        FROM    #territory terr
                LEFT OUTER JOIN dbo.cvo_terr_scorecard AS g ON terr.territory = g.Territory_Code
                LEFT OUTER JOIN #s1 ON #s1.territory_code = g.Territory_Code
        WHERE   1 = 1
                AND ( g.Stat_Year = CAST(@cy AS VARCHAR(5)) );
	
    END;




GO
