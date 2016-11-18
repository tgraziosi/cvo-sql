SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[cvo_promo_incentive_tracker_2016_sp]
    @terr VARCHAR(1024) = NULL ,
    @debug INT = 0
AS -- exec cvo_promo_incentive_tracker_2016_sp 30302, 0


    BEGIN

        SET NOCOUNT ON;



        DECLARE @ytdstartty DATETIME ,
            @ytdendty DATETIME;
        SELECT  @ytdstartty = BeginDate ,
                @ytdendty = EndDate
-- SELECT *
        FROM    dbo.cvo_date_range_vw AS cdrv
        WHERE   Period = 'year to date';

		
        DECLARE @edate DATETIME , @sdate DATETIME, 
            @cutoffdate DATETIME; -- , @terr VARCHAR(1024)
        SELECT  @cutoffdate = '12/31/2016 23:59' , @sdate= '10/1/2015', 
                @edate = @ytdendty; -- '12/31/2016 23:59'; --,  @terr = NULL

--
        DECLARE @ytdstartly DATETIME ,
            @ytdendly DATETIME;
        SELECT  @ytdstartly = DATEADD(YEAR, -1, @ytdstartty) ,
                @ytdendly = DATEADD(YEAR, -1, @ytdendty);

-- SELECT @ytdendly, @ytdendty, @ytdstartly, @ytdstartty

        IF ( OBJECT_ID('tempdb.dbo.#promotrkr') IS NOT NULL )
            DROP TABLE #promotrkr;
        IF ( OBJECT_ID('tempdb.dbo.#p') IS NOT NULL )
            DROP TABLE #p;
        IF ( OBJECT_ID('tempdb.dbo.#r') IS NOT NULL )
            DROP TABLE #r;
        IF ( OBJECT_ID('tempdb.dbo.#f') IS NOT NULL )
            DROP TABLE #f;
        IF ( OBJECT_ID('tempdb.dbo.#doorsales') IS NOT NULL )
            DROP TABLE #doorsales;
			
        IF ( OBJECT_ID('tempdb.dbo.#territory') IS NOT NULL )
            DROP TABLE #territory;
        CREATE TABLE #territory
            (
              territory VARCHAR(10) ,
              region VARCHAR(3) ,
              salesperson_code VARCHAR(10) ,
              r_id INT ,
              t_id INT IDENTITY(1, 1) ,
              ytdtynet FLOAT ,
              ytdlynet FLOAT ,
              core_goal_amt FLOAT ,
              revo_goal_num INT 
            );

        IF @terr IS NULL
            BEGIN
                INSERT  #territory
                        ( territory ,
                          region ,
                          salesperson_code
                        )
                        SELECT DISTINCT
                                territory_code ,
                                dbo.calculate_region_fn(territory_code) region ,
                                salesperson_code
                        FROM    arsalesp
                        WHERE   territory_code IS NOT NULL
                                AND status_type = 1
                                AND EXISTS ( SELECT 1
                                             FROM   armaster ar
                                             WHERE  ar.territory_code = arsalesp.territory_code
                                                    AND ar.status_type = 1 )
                        ORDER BY territory_code;
            END;
        ELSE
            BEGIN
                INSERT  INTO #territory
                        ( territory ,
                          region ,
                          salesperson_code
                        )
                        SELECT DISTINCT
                                ListItem ,
                                dbo.calculate_region_fn(ListItem) region ,
                                slp.salesperson_code
                        FROM    dbo.f_comma_list_to_table(@terr) t
                                JOIN arsalesp slp ON slp.territory_code = t.ListItem
                                                     AND slp.status_type = 1 -- active
                        WHERE   EXISTS ( SELECT 1
                                         FROM   armaster ar
                                         WHERE  ar.territory_code = slp.territory_code
                                                AND ar.status_type = 1 )
                                AND slp.salesperson_code <> 'smithma'
                        ORDER BY ListItem;
            END;


			-- SELECT * FROM dbo.arsalesp AS a

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


        UPDATE  t
        SET     t.core_goal_amt = ISNULL(ts.Core_Goal_Amt,0) ,
                t.revo_goal_num = ts.revo_goal_amt
				
        FROM    #territory AS t
                LEFT OUTER JOIN dbo.cvo_terr_scorecard AS ts ON ts.Territory_Code = t.territory
        WHERE   ts.Stat_Year = CAST(YEAR(@cutoffdate) AS VARCHAR(4));


        UPDATE  t
        SET     ytdtynet = ISNULL(ytdty.net, 0) ,
                ytdlynet = ISNULL(ytdly.net, 0) 
        FROM    #territory AS t
                LEFT OUTER JOIN ( SELECT    tt.territory ,
                                            SUM(anet) net
                                  FROM      #territory AS tt
                                            JOIN armaster ar ON ar.territory_code = tt.territory
                                            JOIN dbo.cvo_sbm_details AS sbm ON ar.customer_code = sbm.customer
                                                              AND ar.ship_to_code = sbm.ship_to
                                  WHERE     yyyymmdd BETWEEN @ytdstartty AND @ytdendty
                                  GROUP BY  tt.territory
                                ) ytdty ON ytdty.territory = t.territory
                LEFT OUTER JOIN ( SELECT    tt.territory ,
                                            SUM(anet) net
                                  FROM      #territory AS tt
                                            JOIN armaster ar ON ar.territory_code = tt.territory
                                            JOIN dbo.cvo_sbm_details AS sbm ON ar.customer_code = sbm.customer
                                                              AND ar.ship_to_code = sbm.ship_to
                                  WHERE     yyyymmdd BETWEEN @ytdstartly AND @ytdendly
                                  GROUP BY  tt.territory
                                ) ytdly ON ytdly.territory = t.territory;

        IF @debug <> 0
            SELECT  *
            FROM    #territory AS t;

 		
        CREATE TABLE #p
            (
              promo_id VARCHAR(30) ,
              promo_level VARCHAR(30) ,
              sdate DATETIME ,
              Program VARCHAR(30)
            );


        INSERT  #p
        VALUES  ( 'revo', 'launch 1', '10/1/2015', 'REVO' );
        INSERT  #p
        VALUES  ( 'revo', 'launch 2', '10/1/2015', 'REVO' );
        INSERT  #p
        VALUES  ( 'revo', 'launch 3', '10/1/2015', 'REVO' );
        INSERT  #p
        VALUES  ( 'revo', '1', '10/1/2015', 'REVO' );
        INSERT  #p
        VALUES  ( 'revo', '2', '10/1/2015', 'REVO' );
        INSERT  #p
        VALUES  ( 'revo', '3', '10/1/2015', 'REVO' );
		INSERT  #p (PROMO_ID, PROMO_LEVEL, SDATE, PROGRAM)
		SELECT PROMO_ID, PROMO_LEVEL, '10/1/2015', 'REVO'
		FROM CVO_PROMOTIONS WHERE PROMO_ID = 'VE-REVO';

--SELECT * FROM dbo.CVO_promotions
--JOIN #p on #p.promo_id = CVO_promotions.promo_id AND #p.promo_level = CVO_promotions.promo_level

-- tally promo activity

        SELECT DISTINCT
                o.order_no ,
                o.ext ,
                o.total_amt_order ,
                o.total_invoice ,
				0 AS FramesOrdered,
                o.orig_no ,
                o.orig_ext ,
                t.territory ,
                o.cust_code ,
                o.ship_to ,
                o.promo_id ,
                o.promo_level ,
                o.order_type ,
                o.back_ord_flag ,
                CAST('1/1/1900' AS DATETIME) AS return_date ,
                SPACE(40) AS reason ,
                CAST(0.00 AS DECIMAL(20, 8)) AS return_amt ,
                source = CASE WHEN o.date_entered > @cutoffdate THEN 'N'
                              ELSE o.source
                         END ,
                qual_order = 0 ,
                #p.Program
        INTO    #promotrkr
        FROM    #territory t
                INNER JOIN cvo_adord_vw AS o WITH ( NOLOCK ) ON t.territory = o.Territory
                INNER JOIN #p ON #p.promo_id = o.promo_id
                                 AND #p.promo_level = o.promo_level
        WHERE   1 = 1
                AND o.date_entered BETWEEN #p.sdate AND @edate
                AND o.who_entered <> 'backordr' -- 1/18/2016) -- don't count splits as extra programs
                AND o.status <> 'V'; -- 110714 - exclude void orders

-- SELECT * FROM #promotrkr AS p

-- Collect the returns

        SELECT  o.orig_no order_no ,
                o.orig_ext ext ,
                return_date = o.date_entered ,
                reason = MIN(rc.return_desc)
        INTO    #r
        FROM    #promotrkr t
                INNER JOIN orders o ( NOLOCK ) ON t.order_no = o.orig_no
                                                  AND t.ext = o.orig_ext
                INNER JOIN ord_list ol ( NOLOCK ) ON ol.order_no = o.order_no
                                                     AND ol.order_ext = o.ext
                INNER JOIN inv_master i ( NOLOCK ) ON ol.part_no = i.part_no
                INNER JOIN po_retcode rc ( NOLOCK ) ON ol.return_code = rc.return_code
        WHERE   1 = 1
 -- and LEFT(ol.return_code, 2) <> '05' -- AND i.type_code = 'sun'
                AND o.status = 't'
                AND o.type = 'c'
                AND ( o.total_invoice = t.total_invoice
                      OR o.total_amt_order = t.total_amt_order
                    )
        GROUP BY o.orig_no ,
                o.orig_ext ,
                o.date_entered ,
                o.total_amt_order; -- o.total_invoice

-- update the info for an order prior to the cutoff.
        UPDATE  t
        SET     t.return_date = #r.return_date ,
                t.reason = #r.reason
        FROM    #r ,
                #promotrkr t
        WHERE   #r.order_no = t.order_no
                AND #r.ext = t.ext
                AND #r.return_date < @cutoffdate;

        INSERT  #promotrkr
                ( order_no ,
                  ext ,
                  territory ,
                  cust_code ,
                  ship_to ,
                  Program ,
                  source ,
                  qual_order,
				  framesordered
                )
                SELECT  r.order_no ,
                        r.ext ,
                        p.territory ,
                        p.cust_code ,
                        p.ship_to ,
                        p.Program ,
                        'R' ,
                        -1,
						0
                FROM    #r AS r
                        JOIN #promotrkr AS p ON p.order_no = r.order_no
                                                AND p.ext = r.ext
                WHERE   r.return_date >= @cutoffdate;
 
        UPDATE  t
        SET     qual_order = CASE WHEN source = 'A' THEN 0
                                  WHEN source = 'R' THEN -1 -- if it was returned but after the cut-off.  take it away from programs written (n)
                                  WHEN ISNULL(reason, '') = ''
                                       AND NOT EXISTS ( SELECT
                                                              1
                                                        FROM  cvo_promo_override_audit poa
                                                        WHERE poa.order_no = t.order_no
                                                              AND poa.order_ext = t.ext )
										AND t.ext = (SELECT MIN(ext) FROM orders o WHERE o.order_no = t.order_no AND o.status <> 'V') 
                                  THEN 1
					              ELSE 0
                             END
        FROM    #promotrkr t;

-- mark the non-door ship-to's so we can roll them up into the master account
        UPDATE  t
        SET     ship_to = ''
        FROM    #promotrkr t
                INNER JOIN CVO_armaster_all car ON car.ship_to = t.ship_to
                                                   AND car.customer_code = t.cust_code
        WHERE   car.door = 0
                AND t.ship_to <> '';

        SELECT DISTINCT
                p.order_no ,
                p.ext ,
                t.region ,
                t.territory ,
                t.salesperson_code ,
                ar.customer_code cust_code ,
                ar.ship_to_code ship_to ,
                ar.address_name ,
                0 AS ytdtynet ,
                0 AS ytdlynet ,
                ISNULL(p.source, 'E') source ,
                ISNULL(p.qual_order, 0) qual_order ,
                p.Program ,
                ROW_NUMBER() OVER ( PARTITION BY ar.customer_code,
                                    ar.ship_to_code ORDER BY ar.customer_code, ar.ship_to_code ) rank_cust,
				0 AS core_goal_amt,
				0 AS revo_goal_num,
				0 AS FramesOrdered
        INTO    #f
        FROM    #promotrkr p
                LEFT OUTER JOIN armaster ar ON ar.customer_code = p.cust_code
                                               AND ar.ship_to_code = p.ship_to
                LEFT OUTER JOIN #territory AS t ON t.territory = p.territory;

-- fill in the blanks

-- JOIN #territory AS t ON t.territory = p.territory
        INSERT  INTO #f
                ( region ,
                  territory ,
                  salesperson_code ,
                  Program ,
                  source ,
                  qual_order ,
                  ytdtynet ,
                  ytdlynet,
				  core_goal_amt,
				  revo_goal_num,
				  FramesOrdered
	            )
                SELECT DISTINCT
                        t.region ,
                        t.territory ,
                        slp.salesperson_code ,
                        #p.Program ,
                        'A' AS source ,
                        0 AS qual_order ,
                        t.ytdtynet ,
                        t.ytdlynet,
						ISNULL(t.core_goal_amt,0),
						ISNULL(t.revo_goal_num,0),
						0 AS framesordered
                FROM    #p
                        CROSS JOIN #territory t
                        LEFT OUTER JOIN arsalesp slp ON slp.territory_code = t.territory
                                                        AND slp.status_type = 1
                WHERE   region < '800';

		-- tally the total non-zero units

		INSERT INTO #f
			( region,
			  territory,
			  salesperson_code,
			  source,
			  qual_order,
			  ytdtynet,
			  ytdlynet,
			  core_goal_amt,
			  revo_goal_num,
			  FramesOrdered,
			  Program)
			  SELECT t.region,
					 t.territory,
					 slp.salesperson_code,
					 'U', -- units
					  0 AS qual_order ,
                      0 AS ytdtynet ,
                      0 AS ytdlynet,
					  0 AS core_goal_amt,
					  0 AS revo_goal_num,
					 SUM(gv.Shipped) ,
					 'REVO'

			  FROM #territory t
              LEFT OUTER JOIN arsalesp slp ON slp.territory_code = t.territory AND slp.status_type = 1
			  LEFT OUTER JOIN dbo.cvo_gdserial_vw AS gv ON gv.territory_code = slp.territory_code -- source for cvo_item_sales
				WHERE gv.category = 'revo' 
				AND type_code IN ('frame','sun')
				AND gv.date_applied between @sdate AND @edate 
				AND gv.price <> 0

			  GROUP BY t.region,
					 t.territory,
					 slp.salesperson_code


        
        SELECT DISTINCT
                #f.order_no ,
                #f.ext ,
                #f.region ,
                #f.territory ,
                #f.salesperson_code ,
				s.salesperson_name,
                #f.cust_code ,
                #f.ship_to ,
                #f.address_name ,
                #f.ytdtynet ,
                #f.ytdlynet ,
				#F.core_goal_amt,
				#F.revo_goal_num,
				ceiling(ISNULL(CAST(#f.Revo_Goal_num AS DECIMAL),0.00) / 2.00) revo_goal_num_ty,
                #f.source ,
                #f.qual_order ,
                #f.Program,
                @cutoffdate cutoffdate,
				#f.FramesOrdered
        FROM    #f
                LEFT OUTER JOIN #territory AS t ON t.territory = #f.territory
				LEFT OUTER JOIN arsalesp s ON s.salesperson_code = #f.salesperson_code;




    END;










GO
