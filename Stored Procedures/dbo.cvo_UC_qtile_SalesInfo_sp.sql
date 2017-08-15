SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[cvo_UC_qtile_SalesInfo_sp]
    @startdate DATETIME = NULL, @enddate DATETIME = NULL, @debug INT = 0
AS
BEGIN

    -- exec cvo_uc_qtile_salesinfo_sp @debug = 1

    -- declare @startdate DATETIME, @enddate DATETIME, @debug int
	

    SET NOCOUNT ON
    ;
    SET ANSI_WARNINGS OFF
    ;

    DECLARE
        @r12tys DATETIME, @r12tye DATETIME
    ;
    DECLARE
        @r12lys DATETIME,
        @r12lye DATETIME,
        @r12pys DATETIME,
        @r12pye DATETIME
    ;

    SELECT
        @r12tys = @startdate, @r12tye = @enddate
    ;

    IF @startdate IS NULL
       OR @enddate IS NULL
    BEGIN
        SELECT
            @r12tys = drv.BeginDate,
            @r12tye = EndDate
        FROM dbo.cvo_date_range_vw AS drv
        WHERE Period = 'rolling 12 ty'
        ;
    END
    ;

    SELECT
        @r12tys = '5/1/2016', @r12tye = '4/30/2017'
    ;

    SELECT
        @r12lys = DATEADD(YEAR, -1, @r12tys),
        @r12lye = DATEADD(YEAR, -1, @r12tye),
        @r12pys = DATEADD(YEAR, -2, @r12tys),
        @r12pye = DATEADD(YEAR, -2, @r12tye)
    ;

    SELECT
        terr.region,
        terr.territory_code,
        CASE
            WHEN ISNULL(sbm.yyyymmdd, @r12tye)
                 BETWEEN @r12pys AND @r12pye THEN
                'PY'
            WHEN ISNULL(sbm.yyyymmdd, @r12tye)
                 BETWEEN @r12lys AND @r12lye THEN
                'LY'
            ELSE
                'TY'
        END AS sbm_year,
        ar.customer_code UC_code,
        ROUND(SUM(ISNULL(anet, 0)), 2) netsales,
		null AS qtile
    INTO #salesdetails
    FROM
        (
            SELECT DISTINCT
                territory_code, dbo.calculate_region_fn(territory_code) region
            FROM armaster ar (NOLOCK)
        ) terr
        JOIN armaster ar (NOLOCK)
            ON ar.territory_code = terr.territory_code
        LEFT OUTER JOIN cvo_sbm_details sbm (NOLOCK)
            ON sbm.customer = ar.customer_code
               AND sbm.ship_to = ar.ship_to_code
    WHERE
        sbm.yyyymmdd
    BETWEEN @r12pys AND @r12tye
	AND region < '800'
    GROUP BY
        CASE
            WHEN ISNULL(sbm.yyyymmdd, @r12tye)
                 BETWEEN @r12pys AND @r12pye THEN
                'PY'
            WHEN ISNULL(sbm.yyyymmdd, @r12tye)
                 BETWEEN @r12lys AND @r12lye THEN
                'LY'
            ELSE
                'TY'
        END,
        terr.region,
        terr.territory_code,
        ar.customer_code
    ;

	DECLARE @tiles INT, @running_total DECIMAL(20,2), @current DECIMAL(20,2), @cust VARCHAR(10), @yr CHAR(2)

	-- TY
	SELECT @running_total = (SELECT SUM(s.netsales) FROM #salesdetails AS s WHERE sbm_year = 'TY')/4, @yr = 'TY'
	SELECT @current = @running_total, 
					  @cust = (SELECT TOP 1 s.UC_code FROM #salesdetails AS s WHERE qtile IS NULL AND s.sbm_year = @yr
												ORDER BY s.netsales DESC), 
					  @tiles = 1

	WHILE @current > 0 AND @cust IS NOT NULL AND @tiles <=4
	BEGIN
    
		SELECT @current = @current - (SELECT TOP 1 netsales FROM #salesdetails AS s WHERE s.UC_code = @cust AND s.sbm_year = @yr AND qtile IS null)

		UPDATE s SET qtile = @tiles
		FROM #salesdetails AS s
		WHERE UC_code = @cust AND qtile IS NULL AND sbm_year = @yr

		SELECT @cust = (SELECT top 1 s.uc_code FROM #salesdetails AS s 
			WHERE qtile IS NULL AND s.sbm_year = @yr AND s.UC_code <> @cust
			ORDER BY s.netsales DESC)

		IF @current < 0 -- then start the next tile
			SELECT @tiles = @tiles + 1, @current = @running_total

	END
    
	-- LY
	SELECT @running_total = (SELECT SUM(s.netsales) FROM #salesdetails AS s WHERE sbm_year = 'LY')/4, @yr = 'LY'
	SELECT @current = @running_total, 
					  @cust = (SELECT TOP 1 s.UC_code
							  FROM #salesdetails AS s WHERE qtile IS NULL AND s.sbm_year = @yr
					
							  ORDER BY s.netsales DESC), 
					  @tiles = 1

	WHILE @current > 0 AND @cust IS NOT NULL AND @tiles <=4
	BEGIN
    
		SELECT @current = @current - (SELECT TOP 1 netsales FROM #salesdetails AS s WHERE s.UC_code = @cust AND s.sbm_year = @yr AND qtile IS null)

		UPDATE s SET qtile = @tiles
		FROM #salesdetails AS s
		WHERE UC_code = @cust AND qtile IS NULL AND sbm_year = @yr

		SELECT @cust = (SELECT TOP 1 s.uc_code  
			FROM #salesdetails AS s 
			WHERE qtile IS NULL AND s.sbm_year = @yr
			AND s.UC_code <> @cust
			ORDER BY s.netsales DESC)

		IF @current < 0 -- then start the next tile
			SELECT @tiles = @tiles + 1, @current = @running_total

	end


    --SELECT * FROM qtiles
    --RETURN

	SELECT summary.region,
		   summary.qtile,
		   qtile_text = CASE
				WHEN summary.qtile = 1 THEN
					'Top 25%'
				WHEN summary.qtile = 2 THEN
					'25% - 50%'
				WHEN summary.qtile = 3 THEN
					'50% - 75%'
				WHEN summary.qtile = 4 THEN
					'Bottom 25%'
			END,
		summary.comp_year,
		SUM(summary.UP) UP,
		SUM(summary.DOWN) DOWN

    FROM
    (
        SELECT
            ty.region,
            ty.qtile,
			ty.UC_code,
            'TY' comp_year,
            UP = SUM(   CASE
                            WHEN ty.netsalesty >= qtilesly.netsalesly THEN
                                1
                            ELSE
                                0
                        END
                    ),
            DOWN = SUM(   CASE
                              WHEN ty.netsalesty < qtilesly.netsalesly THEN
                                  1
                              ELSE
                                  0
                          END
                      )
        FROM
            (   SELECT
					s.region,
                    s.UC_code,
                    s.sbm_year,
                    s.netsales netsalesty,
                    s.qtile
                FROM #salesdetails AS s
                WHERE s.sbm_year = 'TY'
            ) ty
            LEFT OUTER JOIN
            (
                SELECT
                    s.region, s.UC_code, s.netsales netsalesly
                FROM #salesdetails s
                WHERE s.sbm_year = 'LY'

            ) qtilesly
                ON qtilesly.UC_code = ty.UC_code AND qtilesly.region = ty.region
        WHERE
            ty.sbm_year IN ( 'ty' )

		GROUP BY ty.region, ty.qtile, ty.UC_code
		

        UNION ALL

        SELECT
            ly.region,
            ly.qtile,
            ly.UC_code,
            'LY' comp_year,
            UP = SUM(   CASE
                            WHEN ly.netsalesly >= qtilespy.netsalesly THEN
                                1
                            ELSE
                                0
                        END
                    ),
            DOWN = SUM(   CASE
                              WHEN ly.netsalesly < qtilespy.netsalesly THEN
                                  1
                              ELSE
                                  0
                          END
                      )
        FROM
            (
                SELECT
                    s.region,
                    s.UC_code,
                    s.sbm_year,
                    s.netsales netsalesly,
                    s.qtile 
                FROM #salesdetails AS s
                WHERE s.sbm_year = 'LY'
   
            ) ly
            LEFT OUTER JOIN
            (
                SELECT
                    s.region, s.UC_code, s.netsales netsalesly
                FROM #salesdetails s
                WHERE s.sbm_year = 'PY'

            ) qtilespy
                ON qtilespy.UC_code = ly.UC_code AND qtilespy.region = ly.region
        WHERE
            ly.sbm_year IN ( 'LY' )

		GROUP BY ly.region, ly.qtile, ly.UC_code

    ) summary

	GROUP BY CASE
             WHEN summary.qtile = 1 THEN
             'Top 25%'
             WHEN summary.qtile = 2 THEN
             '25% - 50%'
             WHEN summary.qtile = 3 THEN
             '50% - 75%'
             WHEN summary.qtile = 4 THEN
             'Bottom 25%'
             END,
             summary.region,
             summary.qtile,
             summary.comp_year

			 ORDER BY summary.region, summary.qtile
    ;

-- SELECT * FROM #salesdetails AS s

IF @debug = 1
begin
                SELECT
                    s.region,
                    s.UC_code,
                    s.sbm_year,
                    s.netsales, 
					s.qtile
                FROM #salesdetails AS s
       
end

END
;


GRANT EXECUTE
ON dbo.cvo_UC_qtile_SalesInfo_sp
TO  PUBLIC
;


GO
GRANT EXECUTE ON  [dbo].[cvo_UC_qtile_SalesInfo_sp] TO [public]
GO
