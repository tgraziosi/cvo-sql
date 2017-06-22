SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		tine graziosi
-- Create date: 060117
-- Description:	Unique Customers by Territory by Week
-- EXEC CVO_UC_week_sp '1/1/2017', '12/31/2017', '20201'
-- =============================================

CREATE PROCEDURE [dbo].[cvo_uc_week_sp]
    @DF DATETIME,
    @DT DATETIME,
	@T varchar(1024) = null

AS

    BEGIN
        SET NOCOUNT ON
        ;
        SET ANSI_WARNINGS OFF
        ;

        DECLARE
            @DateFrom DATETIME,
            @DateTo DATETIME,
            @Territory VARCHAR(1024)
        ;


		
        -- uncomment for testing
        --DECLARE
        --    @DF DATETIME, @DT DATETIME, @T VARCHAR(1024)
        --;
        --SELECT
        --    @DF = '01/01/2017', @DT = '12/31/2017', @T = null
        --;

        SELECT
            @DateFrom = @DF, @DateTo = @DT, @Territory = @T
        ;

        IF (OBJECT_ID('tempdb.dbo.#Territory') IS NOT NULL)
            DROP TABLE dbo.#Territory
            ;

        --declare @Territory varchar(1000)
        --select  @Territory = null

        CREATE TABLE #territory (territory VARCHAR(8), region VARCHAR(3))
        ;

        IF @Territory IS NULL
        BEGIN
            INSERT INTO #territory
            (
                territory, region
            )
            SELECT DISTINCT
                territory_code, dbo.calculate_region_fn(territory_code)
            FROM armaster (NOLOCK)
            ;
        END
        ;
        ELSE
        BEGIN
            INSERT INTO #territory
            (
                territory, region
            )
            SELECT ListItem, dbo.calculate_region_fn(listitem)
            FROM dbo.f_comma_list_to_table(@Territory)
            ;
        END
        ;

        SET @DateTo = DATEADD(SECOND, -1, DATEADD(D, 1, @DateTo))
        ;


        -- -- # STOCK ORDERS PER MONTH  
        -- PULL DATA FOR ST SHIPPED ORDERS / CREDITS OVER 5PCS
        IF (OBJECT_ID('tempdb.dbo.#Invoices') IS NOT NULL)
            DROP TABLE #Invoices
            ;
        -- Orders
        SELECT
            ar.territory_code,
            cust_key = cust_code + CASE
                                       WHEN car.door = 1 THEN
                                           o.ship_to
                                       ELSE
                                           ''
                                   END,
            QTY = SUM(ol.qty),
            SUM(total_amt_order - total_discount) ord_value,
            DATEADD(DAY, DATEDIFF(DAY, 0, o.date_shipped), 0) date_shipped,
			DATEADD(wk, DATEDIFF(wk, 0, o.date_shipped), 0) wk_shipped ,
			DATEPART(WEEK,o.date_shipped) week_num
        INTO #invoices
        FROM
            #territory
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
                SELECT
                    ol.order_no, ol.order_ext, SUM(ol.shipped) qty
                FROM
                    ord_list ol (NOLOCK)
                    INNER JOIN inv_master (NOLOCK) i
                        ON ol.part_no = i.part_no
                WHERE
                    type_code IN ( 'frame', 'sun' )
                GROUP BY
                    order_no, order_ext
            ) AS ol
                ON ol.order_no = o.order_no
                   AND ol.order_ext = o.ext
        WHERE
            o.status = 't'
            AND o.date_shipped BETWEEN @DateFrom AND @DateTo
            AND type = 'I'
            AND o.who_entered <> 'backordr'
            AND user_category LIKE 'ST%'
            AND RIGHT(user_category, 2) NOT IN ( 'RB', 'TB' )
        GROUP BY ar.territory_code ,
                 cust_code + CASE
                                       WHEN car.door = 1 THEN
                                           o.ship_to
                                       ELSE
                                           ''
                                   END,
				o.date_shipped

                 

        -- credits
        INSERT INTO #invoices
        SELECT
            ar.territory_code,
            cust_key = cust_code + CASE
                                       WHEN car.door = 1 THEN
                                           o.ship_to
                                       ELSE
                                           ''
                                   END,
             QTY = -1 * SUM(ol.qty),
            -1 * SUM(total_amt_order - total_discount) ord_value,
            DATEADD(DAY, DATEDIFF(DAY, 0, o.date_shipped), 0) date_shipped,
			DATEADD(wk, DATEDIFF(wk, 0, o.date_shipped), 0) wk_shipped ,
			DATEPART(WEEK,o.date_shipped) week_num

        FROM
            #territory
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
                SELECT
                    order_no, order_ext, SUM(cr_shipped) qty
                FROM
                    ord_list (NOLOCK) ol
                    INNER JOIN inv_master (NOLOCK) i
                        ON ol.part_no = i.part_no
                WHERE
                    type_code IN ( 'sun', 'frame' )
                GROUP BY
                    order_no, order_ext
            ) AS ol
                ON ol.order_no = o.order_no
                   AND ol.order_ext = o.ext
        WHERE
            o.status = 't'
            AND o.date_shipped <= @DateTo
            AND type = 'C'
            AND o.who_entered <> 'backordr'
            AND EXISTS
        (
            SELECT 1
            FROM ord_list ol
            WHERE
                ol.order_no = o.order_no
                AND ol.order_ext = o.ext
                AND ol.return_code LIKE '06%'
        )
        GROUP BY
            ar.territory_code,
            cust_code + CASE
                                       WHEN car.door = 1 THEN
                                           o.ship_to
                                       ELSE
                                           ''
                                   END,
			o.date_shipped

        ;


		
		-- build framework of weeks

		;WITH weeks
		AS (SELECT DATEADD(DAY, DATEDIFF(DAY, 0, @DateFrom), 0) AS week_date
			UNION ALL
			SELECT DATEADD(WEEK, 1, week_date) AS Week_date
			FROM weeks
			WHERE DATEADD(WEEK, 1, Week_date) <=  DATEADD(DAY, DATEDIFF(DAY, 0, @dateto), 0)
		   )
		     SELECT
			 t.region,
             t.territory,
			 s.salesperson_name,
			 week_date,
			 DATEPART(WEEK, weeks.week_date) week_num
		INTO #weeks
		FROM weeks
		CROSS JOIN #territory AS t
		JOIN arsalesp s ON s.territory_code = t.territory
		WHERE s.status_type = 1
		;


        -- Pull Unique Custs Orders by Month >=5pcs
        --IF (OBJECT_ID('tempdb.dbo.#InvStCount') IS NOT NULL)
        --    DROP TABLE #InvStCount
        --    ;
	    
        SELECT
			t.region,
            i.territory_code,
			s.salesperson_name,
            COUNT(DISTINCT i.cust_key) STOrds, 
            SUM(ISNULL(i.ord_value, 0)) ord_value,
            week_num,
			ceiling(week_num/8.0) AS wk_cycle,
			i.wk_shipped week_date
        -- INTO #InvStCount
        FROM #invoices i
		JOIN #territory AS t ON i.territory_code = t.territory
		JOIN arsalesp s ON s.territory_code = i.territory_code
        WHERE
            1 = 1
            AND i.date_shipped
            BETWEEN @DateFrom AND @DateTo
            AND (i.ord_value) <> 0
			AND s.status_type = 1
        GROUP BY
            t.region,
			i.territory_code, s.salesperson_name, week_num, i.wk_shipped
        HAVING SUM(QTY) >= 5
    
		UNION ALL
       	SELECT region, territory, salesperson_name, 0, 0, week_num, CEILING(week_num/8.0) AS wk_cycle, week_date
		FROM #weeks
		
    
	    ;


    END
    ;

	GRANT EXECUTE ON cvo_uc_week_sp TO PUBLIC
    



GO
GRANT EXECUTE ON  [dbo].[cvo_uc_week_sp] TO [public]
GO
