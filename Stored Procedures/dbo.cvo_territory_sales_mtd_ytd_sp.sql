SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[cvo_territory_sales_mtd_ytd_sp] @CompareYear VARCHAR(1000)
AS
BEGIN

    -- exec cvo_territory_sales_mtd_ytd_sp '2018'
	--
    --declare @compareyear varchar(1000)
    --set @compareyear = '2018'

	set NOCOUNT ON 

	    -- get workdays info
    DECLARE @workday INT, @today DATETIME,
            @totalworkdays INT,
            @pct_month FLOAT;

	SELECT @today = GETDATE();

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

    IF (OBJECT_ID('tempdb.dbo.#tsr') IS NOT NULL)
        DROP TABLE #tsr;

    CREATE TABLE #tsr
(
    territory_code VARCHAR(8),
    salesperson_code VARCHAR(40),
	salesperson_name VARCHAR(40),
	date_of_hire datetime,
    x_month INT,
    yYear INT,
    mmonth VARCHAR(15),
	agoal DECIMAL(20,8),
    anet decimal(20,8),
    qnet INTEGER,
    currentmonthsales decimal(20,8),
    Sales_type VARCHAR(11),
    region VARCHAR(3),
    Q INT,
    r_id INT,
    t_id INT,
    col VARCHAR(1),
    ly_ytd decimal(20,8),
	anet_ty DECIMAL(20,8),
	anet_ly DECIMAL(20,8)
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

    EXEC dbo.cvo_territory_sales_r2016_sp @compareyear = @CompareYear, @territory = null;

    UPDATE #tsr
    SET agoal = anet,
        anet = 0,
        qnet = 0,
        CurrentMonthSales = 0
    WHERE salesperson_name LIKE '%Goal%' AND yyear = @compareyear;

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
    WHERE slp.territory_code = #tsr.territory_code AND slp.salesperson_name = #tsr.salesperson_name;

	-- empty territories
    UPDATE #tsr
    SET #tsr.salesperson_name = slp.salesperson_name,
        #tsr.date_of_hire = slp.date_of_hire
    FROM dbo.arsalesp slp
    WHERE slp.salesperson_code = #tsr.salesperson_name;

    UPDATE #tsr
    SET anet_ty = anet
    WHERE yyear = @CompareYear;
    UPDATE #tsr
    SET anet_ly = CASE WHEN x_month = MONTH(@today) THEN currentmonthsales ELSE anet end
    WHERE yyear < @CompareYear AND x_month <= MONTH(@today);


    INSERT #tsr
    (
        territory_code,
        salesperson_name,
        date_of_hire,
        X_MONTH,
        yyear,
        mmonth,
        Region,
        agoal
    )
    SELECT ar.territory_code,
           frame.slp_name,
           frame.date_of_hire,
           frame.X_MONTH,
           frame.yyear,
           frame.mmonth,
           frame.Region,
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
               X_MONTH,
               yyear,
               mmonth,
               Region
        FROM #tsr y
        WHERE mmonth =
        (
        SELECT MAX(mmonth)
        FROM #tsr x
        WHERE x.territory_code = y.territory_code
		AND x.yyear = @compareyear
		AND x.anet <> 0
        )
        ) frame
            ON frame.territory_code = ar.territory_code
    WHERE s.c_year = @CompareYear - 1
    GROUP BY ar.territory_code,
             frame.slp_name,
             frame.date_of_hire,
             frame.X_MONTH,
             frame.yyear,
             frame.mmonth,
             frame.Region;



    SELECT #tsr.territory_code,
		   #tsr.salesperson_code,
           #tsr.salesperson_name,
           #tsr.date_of_hire,
           #tsr.X_MONTH,
           #tsr.yyear,
           #tsr.mmonth,
           --         #tsr.yyyymmdd,
           SUM(ISNULL(#tsr.anet,0)) anet,
           SUM(ISNULL(#tsr.qnet,0)) qnet,
           #tsr.Region,
           SUM(ISNULL(CASE WHEN #tsr.yyear = @CompareYear AND #tsr.X_MONTH = maxmth.maxmth THEN ISNULL(#tsr.anet,0) ELSE 0 END,0)) anet_mtd,
           SUM(currentmonthsales) CurrentMonthSales,
           SUM(ISNULL(CASE WHEN #tsr.yyear = @compareyear THEN  #tsr.agoal ELSE 0 end,0)) agoal,
           SUM(ISNULL(#tsr.anet_ty,0)) anet_ty,
           SUM(ISNULL(#tsr.anet_ly,0)) anet_ly,
           mgr.mgr_name,
           mgr.mgr_date_of_hire
    FROM #tsr
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
            ON #tsr.Region = mgr.region
        CROSS JOIN
        (SELECT MAX(x_month) maxmth FROM #tsr WHERE yyear = @compareyear AND anet <> 0) maxmth
    GROUP BY territory_code,
			 salesperson_code,
             salesperson_name,
             date_of_hire,
             X_MONTH,
             yyear,
             mmonth,
             #tsr.Region,
             mgr.mgr_name,
             mgr.mgr_date_of_hire;

-- set the goal to be LY total sales



END;




GO
GRANT EXECUTE ON  [dbo].[cvo_territory_sales_mtd_ytd_sp] TO [public]
GO
