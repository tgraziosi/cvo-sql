SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[cvo_territory_sales_mtd_ytd_sp]
    @CompareYear VARCHAR(1000),
    @t VARCHAR(1024) = NULL -- territory
AS
BEGIN

    --  
    -- cvo_territory_sales_mtd_ytd_sp '2018', '50503'
    -- declare @compareyear varchar(1000)
    -- set @compareyear = '2018'

    SET NOCOUNT ON;

    -- get workdays info
    DECLARE @workday INT,
            @today DATETIME,
            @sdate DATETIME,
            @edate DATETIME,
            @totalworkdays INT,
            @terr VARCHAR(1024),
            @pct_month FLOAT;

    SELECT @today = GETDATE(),
           @terr = @t;


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

    -- get TY LY UC from STock order Activity report


    IF (OBJECT_ID('tempdb.dbo.#st') IS NOT NULL)
        DROP TABLE #st;

    CREATE TABLE #st
    (
        cust_code VARCHAR(10) NULL,
        ship_to VARCHAR(10) NULL,
        ship_To_door VARCHAR(10),
        ship_to_name VARCHAR(40),
        salesperson VARCHAR(10),
        salesperson_name VARCHAR(60),
        Territory VARCHAR(10),
        region VARCHAR(3),
        total_amt_order DECIMAL(38, 8),
        total_discount DECIMAL(38, 8),
        total_tax DECIMAL(38, 8),
        freight DECIMAL(38, 8),
        qty_ordered DECIMAL(38, 8),
        qty_shipped DECIMAL(38, 8),
        total_invoice DECIMAL(38, 8),
        FramesOrdered DECIMAL(38, 8),
        FramesShipped DECIMAL(38, 8),
        FramesRMA INT,
        net_rx DECIMAL(38, 8),
        net_sales DECIMAL(38, 8),
        yy VARCHAR(2) NULL
    );

    SELECT @sdate = BeginDate,
           @edate = EndDate
    FROM dbo.cvo_date_range_vw AS drv
    WHERE Period = 'Month to Date';
    INSERT #st
    (
        cust_code,
        ship_to,
        ship_To_door,
        ship_to_name,
        salesperson,
        salesperson_name,
        Territory,
        region,
        total_amt_order,
        total_discount,
        total_tax,
        freight,
        qty_ordered,
        qty_shipped,
        total_invoice,
        FramesOrdered,
        FramesShipped,
        FramesRMA,
        net_rx,
        net_sales
    )
    EXEC dbo.cvo_ST_Activity_log_sp @startdate = @sdate,
                                    @enddate = @edate,
                                    @Territory = @terr,
                                    @qualorder = 1,
                                    @detail = 0;
    UPDATE #st
    SET yy = 'TY'
    WHERE yy IS NULL;

    SELECT @sdate = BeginDate,
           @edate = EndDate
    FROM dbo.cvo_date_range_vw AS drv
    WHERE Period = 'Month to Date LY';
    INSERT #st
    (
        cust_code,
        ship_to,
        ship_To_door,
        ship_to_name,
        salesperson,
        salesperson_name,
        Territory,
        region,
        total_amt_order,
        total_discount,
        total_tax,
        freight,
        qty_ordered,
        qty_shipped,
        total_invoice,
        FramesOrdered,
        FramesShipped,
        FramesRMA,
        net_rx,
        net_sales
    )
    EXEC dbo.cvo_ST_Activity_log_sp @startdate = @sdate,
                                    @enddate = @edate,
                                    @Territory = @terr,
                                    @qualorder = 1,
                                    @detail = 0;
    UPDATE #st
    SET yy = 'LY'
    WHERE yy IS NULL;



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

    CREATE NONCLUSTERED INDEX idx_tsr ON #tsr (territory_code);


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



    SELECT #tsr.territory_code,
           #tsr.salesperson_code,
           #tsr.salesperson_name,
           #tsr.date_of_hire,
           #tsr.x_month,
           #tsr.yYear,
           #tsr.mmonth,
           --         #tsr.yyyymmdd,
           SUM(ISNULL(#tsr.anet, 0)) anet,
           SUM(ISNULL(#tsr.qnet, 0)) qnet,
           #tsr.region,
           SUM(ISNULL(   CASE
                             WHEN #tsr.yYear = @CompareYear
                                  AND #tsr.x_month = maxmth.maxmth THEN
                                 ISNULL(#tsr.anet, 0)
                             ELSE
                                 0
                         END,
                         0
                     )
              ) anet_mtd,
           SUM(currentmonthsales) CurrentMonthSales,
           SUM(ISNULL(   CASE
                             WHEN #tsr.yYear = @CompareYear THEN
                                 #tsr.agoal
                             ELSE
                                 0
                         END,
                         0
                     )
              ) agoal,
           SUM(ISNULL(#tsr.anet_ty, 0)) anet_ty,
           SUM(ISNULL(#tsr.anet_ly, 0)) anet_ly,
           SUM(ISNULL(   CASE
                             WHEN #tsr.yYear <> @CompareYear
                                  AND #tsr.x_month = maxmth.maxmth THEN
                                 ISNULL(#tsr.anet, 0)
                             ELSE
                                 0
                         END,
                         0
                     )
              ) anet_mth_LY,
           mgr.mgr_name,
           mgr.mgr_date_of_hire,
           st.tyuc,
           st.lyuc,
           ISNULL(avg_mth.avg_net_sales, 0) avg_mth_net
    FROM #tsr
        LEFT OUTER JOIN
        (
            SELECT yrs.territory_code,
                   MAX(year) max_year,
                   AVG(yrs.net_sales) avg_net_sales
            FROM
            (
                SELECT ar.territory_code,
                       sd.year,
                       SUM(anet) net_sales
                FROM
                (SELECT DISTINCT territory_code FROM #tsr) tsr
                    JOIN dbo.armaster ar (NOLOCK)
                        ON ar.territory_code = tsr.territory_code
                    JOIN dbo.cvo_sbm_details AS sd (NOLOCK)
                        ON ar.customer_code = sd.customer
                           AND ar.ship_to_code = sd.ship_to
                WHERE sd.X_MONTH = DATEPART(MONTH, @edate)
                      AND sd.year >= @CompareYear - 5
                GROUP BY ar.territory_code,
                         sd.year
            ) yrs
            GROUP BY yrs.territory_code
        ) avg_mth
            ON avg_mth.territory_code = #tsr.territory_code
               AND #tsr.yyear = @CompareYear
               AND #tsr.x_month = (SELECT MAX(x_month) FROM #tsr)
        LEFT OUTER JOIN
        (
            SELECT dbo.calculate_region_fn(territory_code) region,
                   salesperson_name mgr_name,
                   date_of_hire mgr_date_of_hire
            FROM dbo.arsalesp
            WHERE salesperson_type = 1
                  AND territory_code IS NOT NULL
                  AND status_type = 1 -- add status check for active
            UNION
            SELECT '800',
                   'Corporate Accounts',
                   '1/1/1949'
        ) mgr
            ON #tsr.region = mgr.region
        LEFT OUTER JOIN
        (
            SELECT Territory,
                   COUNT(DISTINCT CASE
                                      WHEN yy = 'TY' THEN
                                          cust_code + ship_to
                                      ELSE
                                          NULL
                                  END
                        ) tyuc,
                   COUNT(DISTINCT CASE
                                      WHEN yy = 'LY' THEN
                                          cust_code + ship_to
                                      ELSE
                                          NULL
                                  END
                        ) lyuc
            FROM #st
            GROUP BY Territory
        ) st
            ON st.Territory = #tsr.territory_code
        CROSS JOIN
        (
            SELECT MAX(x_month) maxmth
            FROM #tsr
            WHERE yYear = @CompareYear
                  AND anet <> 0
        ) maxmth
    GROUP BY ISNULL(avg_mth.avg_net_sales, 0),
             #tsr.territory_code,
             salesperson_code,
             salesperson_name,
             date_of_hire,
             x_month,
             yYear,
             mmonth,
             #tsr.region,
             mgr.mgr_name,
             mgr.mgr_date_of_hire,
             st.tyuc,
             st.lyuc;

-- set the goal to be LY total sales



END;








GO
GRANT EXECUTE ON  [dbo].[cvo_territory_sales_mtd_ytd_sp] TO [public]
GO
