SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		tgraziosi
-- Create date: 1/20/2015
-- Description:	Sun Presell 5 Yr Tracker
-- exec SSRS_SunPreSell_v2_sp
-- switch to date ordered and summarize by level
-- =============================================

CREATE PROCEDURE [dbo].[SSRS_SunPreSell_v2_sp]
    @asofdate DATETIME = NULL ,
    @sdate DATETIME = NULL ,
    @edate DATETIME = NULL,
	@debug INT = 0

AS
    BEGIN

        -- exec ssrs_sunpresell_V2_sp '10/20/2017', '11/1/2017', '1/31/2018', 0

        SET NOCOUNT ON;



        IF @sdate IS NULL
            SET @sdate = '11/1/2017';
        IF @edate IS NULL
            SET @edate = '1/31/2018';

        IF @asofdate IS NULL
            SELECT @asofdate = @sdate;

        -- SUN PRESELL 6 year Customer Tracker
        DECLARE @P1From DATETIME ,
                @P1To DATETIME ,
                @P2From DATETIME ,
                @P2To DATETIME ,
                @P3From DATETIME ,
                @P3To DATETIME ,
                @P4From DATETIME ,
                @P4To DATETIME ,
                @P5From DATETIME ,
                @P5To DATETIME,
				@P6From DATETIME ,
                @P6To DATETIME
				;

        -- Orders Entered
        SET @P1From = @sdate;
        --CASE WHEN @asofdate > ( '11/1/'
        --                                            + CONVERT(
        --                                                  VARCHAR(4) ,
        --                                                  ( DATEPART(
        --                                                        YEAR ,@asofdate)))) THEN
        --      ( '11/1/' + CONVERT(VARCHAR(4), ( DATEPART(YEAR, @asofdate))))
        --                         ELSE
        --      ( '11/1/'
        --        + CONVERT(
        --              VARCHAR(4), ( DATEPART(YEAR, DATEADD(YEAR, -1, @asofdate)))))
        --                    END;
        --    
        SET @P1To = DATEADD(MILLISECOND, -3, DATEADD(DAY, 1, @edate));

        -- Invoices Shipped
        SET @P2From = DATEADD(YEAR, -1, @P1From);
        SET @P2To = DATEADD(YEAR, -1, @P1To);
        SET @P3From = DATEADD(YEAR, -2, @P1From);
        SET @P3To = DATEADD(YEAR, -2, @P1To);
        SET @P4From = DATEADD(YEAR, -3, @P1From);
        SET @P4To = DATEADD(YEAR, -3, @P1To);
        SET @P5From = DATEADD(YEAR, -4, @P1From);
        SET @P5To = DATEADD(YEAR, -4, @P1To);
		SET @P6From = DATEADD(YEAR, -5, @P1From);
        SET @P6To = DATEADD(YEAR, -5, @P1To);

        IF @debug = 1 select @P1From, @P1To, @P2From, @P2To, @P3From, @P3To, @P4From, @P4To, @P5From, @P5To

        -- -- --  select * from inv_master
        -- -- --
        IF ( OBJECT_ID('tempdb.dbo.#sunps') IS NOT NULL )
            DROP TABLE #sunps;
		CREATE TABLE #sunps
			(
				cust_code VARCHAR(10) ,
				ship_to VARCHAR(10) ,
				type CHAR(1) ,
				order_no INT ,
				invoice_no NVARCHAR(15) ,
				date_entered DATETIME ,
				date_shipped DATETIME ,
				Promo_id VARCHAR(255) ,
				Promo_level VARCHAR(255) ,
				OrdQty DECIMAL(38, 8) ,
				ShipQty DECIMAL(38, 8) ,
				CRQty DECIMAL(38, 8) ,
				Cnt INT ,
				period INT
			);

        ---- HISTORY INVOICES
		INSERT INTO #sunps
		SELECT   cust_code ,
		         o.ship_to ,
		         o.type ,
		         o.order_no ,
		         invoice_no ,
		         date_entered ,
		         date_shipped ,
		         UPPER(user_def_fld3) AS Promo_id ,
		         user_def_fld9 AS Promo_level ,
		         CASE WHEN type = 'C' THEN 0
		              ELSE SUM(ordered)
		         END AS OrdQty ,
		         SUM(shipped) ShipQty ,
		         SUM(cr_shipped) CRQty ,
		         CASE WHEN type = 'I' THEN 1
		              ELSE -1
		         END AS Cnt ,
		         period = CASE WHEN o.date_entered
		                            BETWEEN @P2From AND @P2To THEN
		                           DATEPART(YEAR, @P2To)
		                       WHEN o.date_entered
		                            BETWEEN @P3From AND @P3To THEN
		                           DATEPART(YEAR, @P3To)
		                       WHEN o.date_entered
		                            BETWEEN @P4From AND @P4To THEN
		                           DATEPART(YEAR, @P4To)
		                       WHEN o.date_entered
		                            BETWEEN @P5From AND @P5To THEN
		                           DATEPART(YEAR, @P5To)
							WHEN o.date_entered
		                            BETWEEN @P6From AND @P6To THEN
		                           DATEPART(YEAR, @P6To)
		                       ELSE ''
		                  END
		--INTO     #sunps

		FROM     CVO_orders_all_Hist ( NOLOCK ) o
		         JOIN cvo_ord_list_hist ( NOLOCK ) ol ON o.order_no = ol.order_no
		                                                 AND o.ext = ol.order_ext
		         JOIN inv_master ( NOLOCK ) i ON ol.part_no = i.part_no
		WHERE    o.status <> 'v'
		         AND user_def_fld3 LIKE '%SUNPS%'
		         AND o.ext = 0
		         AND o.date_entered
		         BETWEEN @P6From AND @P2To
		         AND i.type_code IN ( 'frame', 'sun' )
		GROUP BY cust_code ,
		         o.ship_to ,
		         o.type ,
		         o.order_no ,
		         invoice_no ,
		         date_entered ,
		         date_shipped ,
		         user_def_fld3 ,
		         user_def_fld9;

        -- LIVE INVOICES
        INSERT INTO #sunps
                    SELECT   cust_code ,
                             o.ship_to ,
                             o.type ,
                             o.order_no ,
                             CAST(invoice_no AS VARCHAR(12)) ,
                             date_entered ,
                             date_shipped ,
                             UPPER(promo_id) promo_id ,
                             promo_level ,
                             SUM(ordered) OrdQty ,
                             SUM(shipped) ShipQty ,
                             SUM(cr_shipped) CRQty ,
                             CASE WHEN type = 'I' THEN 1
                                  ELSE -1
                             END AS Cnt ,
                             period = CASE WHEN o.date_entered
                                                BETWEEN @P2From AND @P2To THEN
                                               DATEPART(YEAR, @P2To)
                                           WHEN o.date_entered
                                                BETWEEN @P3From AND @P3To THEN
                                               DATEPART(YEAR, @P3To)
                                           WHEN o.date_entered
                                                BETWEEN @P4From AND @P4To THEN
                                               DATEPART(YEAR, @P4To)
                                           WHEN o.date_entered
                                                BETWEEN @P5From AND @P5To THEN
                                               DATEPART(YEAR, @P5To)
										   WHEN o.date_entered	
												BETWEEN @p6from AND @p6to THEN
												DATEPART(YEAR, @p6to)
                                           ELSE 0
                                      END
					-- INTO #sunps
                    FROM     orders_all ( NOLOCK ) o
                             JOIN ord_list ( NOLOCK ) ol ON o.order_no = ol.order_no
                                                            AND o.ext = ol.order_ext
                             JOIN CVO_orders_all ( NOLOCK ) co ON o.order_no = co.order_no
                                                                  AND o.ext = co.ext
                             JOIN inv_master ( NOLOCK ) i ON ol.part_no = i.part_no
                    WHERE    o.status <> 'v'
                             AND promo_id LIKE '%SUNPS%'
                             -- AND co.promo_level IN ('1','2','3') -- 11/3/2016
                             -- and (o.ext=0 OR (o.ext>0 and o.who_entered='OutOfStock'))
                             AND o.who_entered <> 'backordr'
                             AND o.date_entered
                             BETWEEN @P6From AND @P2To
                             AND i.type_code IN ( 'frame', 'sun' )
                             -- and right(o.user_category,2) not in ('rb','tb')
                             AND NOT EXISTS (   SELECT 1
                                                FROM   cvo_promo_override_audit poa
                                                WHERE  poa.order_no = o.order_no
                                                       AND poa.order_ext = o.ext )

                    GROUP BY cust_code ,
                             o.ship_to ,
                             o.type ,
                             o.order_no ,
                             invoice_no ,
                             date_entered ,
                             date_shipped ,
                             promo_id ,
                             promo_level;

        IF @debug = 1 select * from #sunps

        -- Current Year Open Orders

        INSERT INTO #sunps
                    SELECT   cust_code ,
                             o.ship_to ,
                             type ,
                             o.order_no ,
                             CAST(invoice_no AS VARCHAR(12)) ,
                             date_entered ,
                             date_shipped ,
                             UPPER(promo_id) promo_id ,
                             promo_level ,
                             SUM(ordered) OrdQty ,
                             SUM(shipped) ShipQty ,
                             SUM(cr_shipped) CRQty ,
                             CASE WHEN type = 'I' THEN 1
                                  ELSE -1
                             END AS Cnt ,
                             period = DATEPART(YEAR, @edate)

                    FROM     orders_all ( NOLOCK ) o
                             JOIN ord_list ( NOLOCK ) ol ON o.order_no = ol.order_no
                                                            AND o.ext = ol.order_ext
                             JOIN CVO_orders_all ( NOLOCK ) co ON o.order_no = co.order_no
                                                                  AND o.ext = co.ext
                             JOIN inv_master ( NOLOCK ) i ON ol.part_no = i.part_no
                    WHERE    o.status <> 'v'
                             AND promo_id LIKE '%SUNPS%'
                             -- and (o.ext='0' OR (o.ext>0 and o.who_entered='OutOfStock'))
                             AND o.who_entered <> 'backordr'
                             AND date_entered
                             BETWEEN @P1From AND @P1To
                             AND type_code IN ( 'sun', 'frame' )
                             -- and right(o.user_category,2) not in ('rb','tb')
                             AND NOT EXISTS (   SELECT 1
                                                FROM   cvo_promo_override_audit poa
                                                WHERE  poa.order_no = o.order_no
                                                       AND poa.order_ext = o.ext )
                    GROUP BY cust_code ,
                             o.ship_to ,
                             type ,
                             o.order_no ,
                             invoice_no ,
                             date_entered ,
                             date_shipped ,
                             promo_id ,
                             promo_level;

        -- Final Select

        -- select * from #sunps  where cust_code = '045134'

        SELECT Status = CASE WHEN t1.status_type = '1' THEN 'Act'
                             WHEN t1.status_type = '2' THEN 'Inact'
                             ELSE 'NoNewBus'
                        END ,
               t1.territory_code AS Terr ,
               customer_code ,
               ship_to_code ,
               t2.Promo_level ,
               t1.address_name ,
               t1.addr2 ,
               CASE WHEN addr3 LIKE '%, __ %' THEN ''
                    ELSE addr3
               END AS addr3 ,
               city ,
               state ,
               postal_code ,
               country_code ,
               contact_phone ,
               tlx_twx ,
               contact_email = CASE WHEN t1.contact_email IS NULL
                                         OR t1.contact_email LIKE '%@CVOPTICAL.COM'
                                         OR t1.contact_email = 'REFUSED' THEN
                                        ''
                                    ELSE LOWER(t1.contact_email)
                               END ,
               t2.period ,
               CASE WHEN t2.Inv_cnt < 0 THEN 0
                    ELSE t2.Inv_cnt
               END AS Inv_cnt ,
               CASE WHEN t2.Inv_cnt < 0 THEN 0
                    ELSE t2.Inv_qty
               END AS Inv_qty

        FROM   (   SELECT   cust_code ,
                            CASE WHEN car.door = 0 THEN ''
                                 ELSE s.ship_to
                            END AS ship_to ,
                            s.Promo_level ,
                            period ,
                            SUM(ISNULL(Cnt, 0)) Inv_cnt ,
                            SUM(ISNULL(OrdQty, 0) - ISNULL(CRQty, 0)) Inv_qty
                   FROM     #sunps s
                            INNER JOIN CVO_armaster_all car ON car.customer_code = s.cust_code
                                                               AND car.ship_to = s.ship_to
				   WHERE period <> 0
                   GROUP BY cust_code ,
                            CASE WHEN car.door = 0 THEN ''
                                 ELSE s.ship_to
                            END ,
                            s.Promo_level ,
                            period
                   HAVING   SUM(ISNULL(Cnt, 0)) >= 0 ) AS t2
               INNER JOIN armaster t1 ON t1.customer_code = t2.cust_code
                                         AND t1.ship_to_code = t2.ship_to
        WHERE  Inv_qty <> 0
               AND Inv_cnt <> 0;

    END;



GO
