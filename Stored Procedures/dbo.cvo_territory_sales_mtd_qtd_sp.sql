SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[cvo_territory_sales_mtd_qtd_sp]
    @CompareYear VARCHAR(1000),
    @t VARCHAR(1024) = NULL
AS
BEGIN

    --  
    -- cvo_territory_sales_mtd_qtd_sp '2019'
    -- set @compareyear = '2018'

    SET NOCOUNT ON;

    -- get workdays info
    DECLARE @workday INT,
            @today DATETIME,
            @sdate DATETIME,
            @edate DATETIME,
            @totalworkdays INT,
            @terr VARCHAR(1024),
            @pct_qtr FLOAT;

    SELECT @today = GETDATE(),
           @terr = @t;

    SELECT @sdate = BeginDate,
           @edate = EndDate
    FROM dbo.cvo_date_range_vw AS drv
    WHERE Period = 'This Quarter';


    SELECT @workday = dbo.cvo_f_get_work_days(@sdate, DATEADD(d, -1, @today));

    SELECT @totalworkdays = dbo.cvo_f_get_work_days(@sdate, @edate);

    SELECT @pct_qtr = CAST(@workday AS FLOAT) / CAST(@totalworkdays AS FLOAT);

    -- get TY LY UC from STock order Activity report



    IF (OBJECT_ID('tempdb.dbo.#tsr') IS NOT NULL)
        DROP TABLE #tsr;

    CREATE TABLE #tsr
    (
        territory_code VARCHAR(8),
        salesperson_code VARCHAR(40),
        salesperson_name VARCHAR(40),
        date_of_hire DATETIME,
        x_month INT,
        yYear INT,
        mmonth VARCHAR(15),
        agoal DECIMAL(20, 8),
        anet DECIMAL(20, 8),
        qnet INTEGER,
        currentmonthsales DECIMAL(20, 8),
        Sales_type VARCHAR(11),
        region VARCHAR(3),
        Q INT,
        r_id INT,
        t_id INT,
        col VARCHAR(1),
        ly_ytd DECIMAL(20, 8),
        anet_ty DECIMAL(20, 8),
        anet_ly DECIMAL(20, 8)
    );


    INSERT INTO #tsr
    (
        territory_code,
        salesperson_name,
        x_month,
        yYear,
        mmonth,
        anet,
        qnet,
        currentmonthsales,
        Sales_type,
        region,
        Q,
        r_id,
        t_id,
        col,
        ly_ytd
    )
    EXEC dbo.cvo_territory_sales_r2016_sp @CompareYear = @CompareYear,
                                          @territory = @terr;

    UPDATE #tsr
    SET agoal = anet,
        anet = 0,
        qnet = 0,
        currentmonthsales = 0
    WHERE salesperson_name LIKE '%Goal%'
          AND yYear = @CompareYear;

    UPDATE #tsr
    SET #tsr.salesperson_name = #terr.salesperson_name
    FROM #tsr
        INNER JOIN
        (
            SELECT DISTINCT
                   #tsr.territory_code,
                   #tsr.salesperson_name
            FROM #tsr
            WHERE #tsr.salesperson_name NOT LIKE '%Goal%'
        ) #terr
            ON #terr.territory_code = #tsr.territory_code;

    UPDATE #tsr
    SET #tsr.salesperson_code = slp.salesperson_code,
        #tsr.date_of_hire = slp.date_of_hire
    FROM dbo.arsalesp slp
    WHERE slp.territory_code = #tsr.territory_code
          AND slp.salesperson_name = #tsr.salesperson_name;

    -- empty territories
    UPDATE #tsr
    SET #tsr.salesperson_name = slp.salesperson_name,
        #tsr.date_of_hire = slp.date_of_hire
    FROM dbo.arsalesp slp
    WHERE slp.salesperson_code = #tsr.salesperson_name;

    UPDATE #tsr
    SET anet_ty = anet
    WHERE yYear = @CompareYear;

    UPDATE #tsr
    SET anet_ly = CASE
                      WHEN x_month = MONTH(@today) THEN
                          currentmonthsales
                      ELSE
                          anet
                  END
    WHERE yYear < @CompareYear
          AND x_month <= MONTH(@today);


    INSERT #tsr
    (
        territory_code,
        salesperson_name,
        date_of_hire,
        x_month,
        yYear,
        mmonth,
        region,
        agoal
    )
    SELECT ar.territory_code,
           frame.slp_name,
           frame.date_of_hire,
           frame.x_month,
           frame.yYear,
           frame.mmonth,
           frame.region,
           SUM(anet) lynetsales
    FROM cvo_sbm_details s
        JOIN armaster ar (NOLOCK)
            ON ar.customer_code = s.customer
               AND ar.ship_to_code = s.ship_to
        JOIN
        (
            SELECT DISTINCT
                   territory_code,
                   '     Goal' slp_name,
                   date_of_hire,
                   x_month,
                   yYear,
                   mmonth,
                   region
            FROM #tsr y
            WHERE mmonth =
            (
                SELECT MAX(mmonth)
                FROM #tsr x
                WHERE x.territory_code = y.territory_code
                      AND x.yYear = @CompareYear
                      AND x.anet <> 0
            )
        ) frame
            ON frame.territory_code = ar.territory_code
    WHERE s.c_year = @CompareYear - 1
    GROUP BY ar.territory_code,
             frame.slp_name,
             frame.date_of_hire,
             frame.x_month,
             frame.yYear,
             frame.mmonth,
             frame.region;


    ;WITH mgr
    AS (SELECT dbo.calculate_region_fn(territory_code) region,
               salesperson_name mgr_name,
               date_of_hire mgr_date_of_hire
        FROM dbo.arsalesp
        WHERE salesperson_type = 1
              AND territory_code IS NOT NULL
              AND status_type = 1 -- add status check for active
              AND salesperson_name <> 'Patti Gertzen'
        UNION
        SELECT '800',
               'Corporate Accounts',
               '1/1/1949')
    SELECT territory_code,
           #tsr.salesperson_code,
           #tsr.salesperson_name,
           #tsr.date_of_hire,
           #tsr.x_month,
           #tsr.Q,
           #tsr.yYear,
           SUM(ISNULL(#tsr.anet, 0)) anet,
           SUM(ISNULL(#tsr.qnet, 0)) qnet,
           #tsr.region,
           SUM(ISNULL(   CASE
                             WHEN #tsr.yYear = @CompareYear THEN
                                 ISNULL(#tsr.anet, 0)
                             ELSE
                                 0
                         END,
                         0
                     )
              ) anet_qtd,
           SUM(ISNULL(   CASE
                             WHEN #tsr.yYear <> @CompareYear THEN
                                 ISNULL(#tsr.anet, 0)
                             ELSE
                                 0
                         END,
                         0
                     )
              ) anet_qtd_LY,
           SUM(ISNULL(   CASE
                             WHEN #tsr.yYear <> @CompareYear
                                  AND #tsr.x_month = 12 THEN
                                 ISNULL(#tsr.anet, 0)
                             ELSE
                                 0
                         END,
                         0
                     )
              ) anet_ly_dec,
           SUM(ISNULL(#tsr.anet_ty, 0)) anet_ty,
           SUM(ISNULL(#tsr.anet_ly, 0)) anet_ly,
           mgr.mgr_name,
           mgr.mgr_date_of_hire,
           CASE
               WHEN #tsr.yYear = @CompareYear
                    AND #tsr.x_month = MONTH(@today) THEN
                   g.Q4_G1
               ELSE
                   0
           END q4_g1,
           CASE
               WHEN #tsr.yYear = @CompareYear
                    AND #tsr.x_month = MONTH(@today) THEN
                   g.Q4_G2
               ELSE
                   0
           END q4_g2,
           @pct_qtr pct_qtr,
           @workday workday,
           @totalworkdays totalworkdays
    FROM #tsr
        LEFT OUTER JOIN mgr
            ON #tsr.region = mgr.region
        LEFT OUTER JOIN
        (SELECT territory, Q4_G1, Q4_G2 FROM dbo.cvo_q4_goal_2018) g
            ON g.territory = #tsr.territory_code
    WHERE #tsr.Q = DATEPART(QUARTER, @edate)
          AND 0 <> ISNULL(g.Q4_G1, 0)
    GROUP BY territory_code,
             salesperson_code,
             salesperson_name,
             date_of_hire,
             x_month,
             Q,
             yYear,
             #tsr.region,
             mgr.mgr_name,
             mgr.mgr_date_of_hire,
             g.Q4_G1,
             g.Q4_G2;

-- set the goal to be LY total sales



END;













GO
