SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[cvo_territory_sales_r2019_sp]

    @CompareYear INT = NULL,
    --v2
    @territory VARCHAR(1000) = NULL

AS
SET NOCOUNT ON;

BEGIN

    -- exec cvo_territory_sales_r2019_sp 2018, '20201'

    --DECLARE @compareyear INT, @territory VARCHAR(1000)
    --SELECT @compareyear = 2015, @territory = '20201'


    DECLARE @cy INT,
            @terr VARCHAR(1000),
            @today DATETIME;

    SELECT @cy = @CompareYear,
           @terr = @territory,
           @today = GETDATE()

    -- 032614 - tag - performance improvements - add multi-value param for territory
    --  move setting the region to last.

    --declare @compareyear int
    --set @compareyear = 2013

    -- exec cvo_territory_sales_r2015_sp 2015, '30302' '20201,40454' ,20202,20203,20204,20205,20206,20210,20215'
    -- exec cvo_territory_sales_r2_sp 2015, '40438'
    -- select distinct territory_code from armaster

    -- 082914 - performance
    DECLARE @sdate DATETIME,
            @edate DATETIME,
            @sdately DATETIME,
            @edately DATETIME;

    IF @cy IS NULL
        SELECT @cy = YEAR(@today);

    SET @sdately = DATEADD(YEAR, (@cy - 1) - 1900, '01-01-1900');
    SET @edately
        = CASE WHEN @cy = YEAR(@today) THEN DATEADD(dd, DATEDIFF(dd, 0, DATEADD("yyyy", -1, @today)) + -1, 0) ELSE
                                            DATEADD(ms,-2,(DATEADD(YEAR,(@cy-1)-1900+1,'01-01-1900'))) END;
    SET @sdate = DATEADD(YEAR, (@cy) - 1900, '01-01-1900');
    SET @edate
        = CASE WHEN @cy = YEAR(@today) THEN @today ELSE
                                                   DATEADD(ms, -2, (DATEADD(YEAR, (@cy) - 1900 + 1, '01-01-1900'))) END;

    -- SELECT @sdately, @edately, @sdate, @edate


    IF (OBJECT_ID('tempdb.dbo.#temp') IS NOT NULL)
        DROP TABLE #temp;


    DECLARE @terr_tbl TABLE
    (
        territory VARCHAR(10),
        region VARCHAR(3),
        r_id INT,
        t_id INT
    );

    IF @terr IS NULL
    BEGIN
        INSERT @terr_tbl
        SELECT DISTINCT
               territory_code,
               dbo.calculate_region_fn(territory_code) region,
               0,
               0
        FROM armaster ar (NOLOCK)
        WHERE territory_code IS NOT NULL
        ORDER BY territory_code;
    END;
    ELSE
    BEGIN
        INSERT INTO @terr_tbl
        (
            territory,
            region,
            r_id,
            t_id
        )
        SELECT DISTINCT
               ListItem,
               dbo.calculate_region_fn(ListItem) region,
               0,
               0
        FROM dbo.f_comma_list_to_table(@terr)
        ORDER BY ListItem;
    END;

    UPDATE t
    SET t.r_id = r.r_id,
        t.t_id = tr.t_id
    -- SELECT * 
    FROM @terr_tbl AS t
        JOIN
        (
        SELECT DISTINCT
               region,
               RANK() OVER (ORDER BY region) r_id
        FROM
        (SELECT DISTINCT region FROM @terr_tbl) AS r
        ) AS r
            ON t.region = r.region
        JOIN
        (
        SELECT DISTINCT
               territory,
               RANK() OVER (PARTITION BY region ORDER BY territory) t_id
        FROM
        (SELECT DISTINCT region, territory FROM @terr_tbl) AS tr
        ) AS tr
            ON t.territory = tr.territory;

    -- SELECT * FROM @terr_tbl AS t

    -- get workdays info
    DECLARE @workday INT,
            @totalworkdays INT,
            @pct_month FLOAT;

    SELECT @workday
        = dbo.cvo_f_get_work_days(
                                     CONVERT(VARCHAR(25), DATEADD(dd, - (DAY(@today) - 1), @today), 101),
                                     DATEADD(d, -1, @today)
                                 );

    SELECT @totalworkdays
        = dbo.cvo_f_get_work_days(
                                     CONVERT(VARCHAR(25), DATEADD(dd, - (DAY(@today) - 1), @today), 101),
                                     CONVERT(
                                                VARCHAR(25),
                                                DATEADD(dd, - (DAY(DATEADD(mm, 1, @today))), DATEADD(mm, 1, @today)),
                                                101
                                            )
                                 );

    SELECT @pct_month = CAST(@workday AS FLOAT) / CAST(@totalworkdays AS FLOAT);

    -- get TY and LY sales details
    SELECT a.territory_code,
           ISNULL(c.X_MONTH, MONTH(@today)) AS x_month,
           ISNULL(c.year, YEAR(@today)) AS Year,
           ISNULL(c.month, DATENAME(MONTH, @today)) AS month,
           SUM(ISNULL(c.anet, 0)) anet,
           SUM(ISNULL(CASE WHEN i.type_code IN ( 'frame', 'sun' ) THEN c.qnet ELSE 0 END, 0)) qnet,
           '' Sales_type
    INTO #temp
    FROM @terr_tbl t
        INNER JOIN armaster (NOLOCK) a
            ON a.territory_code = t.territory
        INNER JOIN cvo_sbm_details c (NOLOCK)
            ON a.customer_code = c.customer
               AND a.ship_to_code = c.ship_to
        INNER JOIN inv_master i (NOLOCK)
            ON i.part_no = c.part_no

    WHERE 1 = 1
          -- and (yyyymmdd between @sdately and @edately) or (yyyymmdd between @sdate and @edate)
          AND (c.yyyymmdd
          BETWEEN @sdately AND @edate
              )
    GROUP BY ISNULL(c.X_MONTH, MONTH(@today)),
             ISNULL(c.year, YEAR(@today)),
             ISNULL(c.month, DATENAME(MONTH, @today)),
             CASE WHEN ISNULL(i.category, 'Core') IN ( 'OP' ) AND i.type_code = 'ACC' THEN 'Accessories' ELSE 'Core' END,
             a.territory_code;

    -- fill in the blanks so that all buckets are covered
    -- select * from #temp
    -- ty

    DECLARE @month INT;

    SELECT @month = 12;

    WHILE @month > 0
    BEGIN
        INSERT INTO #temp
        SELECT DISTINCT
               a.territory_code,
               @month AS X_MONTH,
               y.yyear AS Year,
               DATENAME(MONTH, CAST(@month AS VARCHAR(2)) + '/01/' + CAST(y.yyear AS VARCHAR(4))) AS month,
               0 anet,
               0 qnet,
               '' Sales_type
        FROM armaster (NOLOCK) a
            INNER JOIN @terr_tbl terr
                ON terr.territory = a.territory_code
            CROSS JOIN
            (SELECT @cy AS yyear UNION SELECT @cy - 1 AS yyear) y
        WHERE a.territory_code IS NOT NULL
              AND a.salesperson_code <> 'smithma';

        SELECT @month = @month - 1;
    END;

    -- SELECT * FROM #temp

    -- get current month sales mtd from lastyear

    SELECT a.territory_code,
           s.year,
           s.X_MONTH,
           SUM(s.anet) AS CurrentMonthSales,
           -- Sales_Type = CASE WHEN ISNULL(i.category, 'Core') IN ( 'op' ) AND i.type_code = 'ACC' THEN 'Accessories' ELSE 'Core' END
           '' AS Sales_Type
    INTO #MonthKey
    FROM @terr_tbl t
        INNER JOIN armaster a (NOLOCK)
            ON a.territory_code = t.territory
        INNER JOIN cvo_sbm_details s (NOLOCK)
            ON s.customer = a.customer_code
               AND s.ship_to = a.ship_to_code
        INNER JOIN inv_master i (NOLOCK)
            ON i.part_no = s.part_no

    WHERE 1 = 1
          AND s.yyyymmdd
          BETWEEN DATEADD(m, DATEDIFF(mm, 0, @edately), 0) AND @edately
    -- AND i.type_code NOT IN ('lens')
    GROUP BY -- CASE WHEN ISNULL(i.category, 'Core') IN ( 'op' ) AND i.type_code = 'ACC' THEN 'Accessories' ELSE 'Core' END,
             a.territory_code,
             s.year,
             s.X_MONTH;

    ; WITH LY AS
    (
    SELECT a.territory_code,
           a.x_month,
           a.Year,
           a.month,
           SUM(a.anet) anet,
           SUM(a.qnet) qnet,
           MAX(ISNULL(m.CurrentMonthSales, 0)) currentmonthsales,
           a.Sales_type
     FROM #temp a
        LEFT JOIN #MonthKey m
            ON a.territory_code = m.territory_code
               AND a.Year = m.year
               AND a.x_month = m.X_MONTH
    WHERE a.Year = @cy - 1
    GROUP BY a.territory_code,
             a.x_month,
             a.Year,
             a.month,
             a.Sales_type
    ),

    TY AS 
    -- get this year figures
    (
    SELECT a.territory_code,
           a.x_month,
           a.Year,
           a.month,
           SUM(a.anet) anet,
           SUM(a.qnet) qnet,
           0 AS currentmonthsales,
           a.Sales_type
    FROM #temp a
    WHERE a.Year = @cy
    GROUP BY a.territory_code,
             a.x_month,
             a.Year,
             a.month,
             a.Sales_type
    ),
    Goal AS
    (
        SELECT a.territory_code,
           a.mmonth x_month,
           a.yyear Year,
           DATENAME(MONTH, CAST(a.mmonth AS VARCHAR(2)) + '/01/' + CAST(a.yyear AS VARCHAR(4))) AS month,
           SUM(a.goal_amt) anet,
           0 AS qnet,
           0 AS currentmonthsales,
           '' Sales_type
    FROM @terr_tbl AS tt 
    JOIN dbo.cvo_territory_goal AS a ON a.territory_code = tt.territory
    WHERE a.yYear = @cy
    GROUP BY a.territory_code,
             a.mmonth,
             a.yYear    
    ),
    
    
    -- fixup sales person names
        S1 AS 
    (
    SELECT LTRIM(RTRIM(t.territory)) territory_code,
           salesperson_code = LTRIM(RTRIM(ISNULL(
                                          (
                                          SELECT TOP 1
                                                 salesperson_name
                                          FROM arsalesp
                                          WHERE salesperson_code <> 'smithma'
                                                AND territory_code = t.territory
                                                AND ISNULL(date_of_hire, '1/1/1900') <= @today
                                                AND status_type = 1
                                          ),
                                          'Empty'
                                                )
                                         )
                                   ),
           -- , dbo.calculate_region_fn(t.territory) as region
           t.region,
           t.r_id,
           t.t_id
    FROM @terr_tbl t
    )

    -- select * From @terr_tbl order by territory
    -- select * from s1 where territory_code in (30398,30399) order by territory_code 
    -- select * From arsalesp where territory_code = 30398

    SELECT TY.territory_code,
           s1.salesperson_code,
           x_month,
           Year,
           month,
           ROUND(anet, 2) anet,
           qnet,
           ROUND(currentmonthsales, 2) currentmonthsales,
           Sales_type,
           s1.region,
           CAST( (x_month+2)/3 AS INTEGER ) aS Q,
           s1.r_id,
           s1.t_id,
           ly_ytd = 0
    FROM TY -- ty
        LEFT OUTER JOIN s1
            ON s1.territory_code = TY.territory_code
    UNION ALL
    SELECT LY.territory_code,
           s1.salesperson_code,
           x_month,
           Year,
           month,
           ROUND(anet, 2) anet,
           qnet,
           ROUND(currentmonthsales, 2) currentmonthsales,
           Sales_type,
           s1.region,
           cast ( (x_month + 2)/3 AS int) Q,
           s1.r_id,
           s1.t_id,
           ly_ytd = CASE WHEN x_month < MONTH(@edately) THEN ROUND(anet, 2)
                    WHEN x_month = MONTH(@edately) THEN ROUND(currentmonthsales, 2) ELSE 0
                    END
    FROM LY -- ly
        LEFT OUTER JOIN s1
            ON s1.territory_code = LY.territory_code
    UNION ALL
    SELECT goal.territory_code,
           salesperson_code,
           goal.x_month,
           goal.Year,
           goal.[month],
           ROUND(anet, 2) anet,
           0 qnet,
           0 currentmonthsales,
           'Goal' Sales_type,
           s1.region,
           (goal.[x_month] + 2)/3 AS Q,
           s1.r_id,
           s1.t_id,
           ly_ytd = CASE WHEN [x_month] < MONTH(@edate) THEN ROUND(anet, 2)
                    WHEN [x_month] = MONTH(@edate) THEN ROUND(anet*@pct_month, 2) ELSE 0
                    END
    FROM goal 
        LEFT OUTER JOIN s1
            ON s1.territory_code = goal.territory_code;



END;

GO
GRANT EXECUTE ON  [dbo].[cvo_territory_sales_r2019_sp] TO [public]
GO
