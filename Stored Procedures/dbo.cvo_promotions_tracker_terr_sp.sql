SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[cvo_promotions_tracker_terr_sp]
-- @promo varchar(20), 
    @sdate DATETIME ,
    @edate DATETIME ,
    @Terr VARCHAR(1000) = NULL ,
    @Promo VARCHAR(5000) = NULL ,
    @PromoLevel VARCHAR(5000) = NULL
-- updates
-- 10/30 - make promo multi-value list - need to repmove parameter
-- exec cvo_promotions_tracker_terr_sp '11/1/2015','10/15/2016', null, 'sunps', 'op'
AS -- 122614 put parameters into local variables to prevent 'sniffing'
-- 011816 - change who_entered criteria

    DECLARE @startdate DATETIME ,
        @enddate DATETIME;
    SET @startdate = @sdate;
    SET @enddate = @edate;

    DECLARE @territory VARCHAR(1000);
    SET @territory = @Terr;

    CREATE TABLE #territory
        (
          territory VARCHAR(10) ,
          region VARCHAR(3)
        );
    IF @territory IS NULL
        BEGIN
            INSERT  INTO #territory
                    ( territory ,
                      region
                    )
                    SELECT DISTINCT
                            territory_code ,
                            dbo.calculate_region_fn(territory_code) region
                    FROM    armaster (NOLOCK)
                    WHERE   status_type = 1; -- active accounts only
        END;
    ELSE
        BEGIN
            INSERT  INTO #territory
                    ( territory ,
                      region
                    )
                    SELECT  ListItem ,
                            dbo.calculate_region_fn(ListItem) region
                    FROM    dbo.f_comma_list_to_table(@territory);
        END;

    DECLARE @promo_id VARCHAR(5000) ,
        @promo_level VARCHAR(5000);
    SELECT  @promo_id = @Promo ,
            @promo_level = @PromoLevel;

    CREATE TABLE #promo_id ( promo_id VARCHAR(20) );
    IF @promo_id IS NULL
        BEGIN
            INSERT  INTO #promo_id
                    ( promo_id
                    )
                    SELECT DISTINCT
                            promo_id
                    FROM    CVO_promotions
                    WHERE   void <> 'V'
                            OR void IS NULL; 
        END;
    ELSE
        BEGIN 
            INSERT  INTO #promo_id
                    ( promo_id
                    )
                    SELECT  ListItem
                    FROM    dbo.f_comma_list_to_table(@promo_id);
        END;

    CREATE TABLE #promo_level
        (
          promo_level VARCHAR(30)
        );
    IF @promo_level IS NULL
        BEGIN
            INSERT  INTO #promo_level
                    ( promo_level
                    )
                    SELECT DISTINCT
                            promo_level
                    FROM    CVO_promotions p
                            INNER JOIN #promo_id pp ON p.promo_id = pp.promo_id
                    WHERE   void <> 'V'
                            OR void IS NULL; 
        END;
    ELSE
        BEGIN 
            INSERT  INTO #promo_level
                    ( promo_level
                    )
                    SELECT  ListItem
                    FROM    dbo.f_comma_list_to_table(@promo_level);
        END;

-- exec cvo_promotions_tracker_terr_sp '11/1/2013','10/31/2014' ,'20206'

    SELECT  o.order_no ,
            o.ext ,
            o.cust_code ,
            o.ship_to ,
            o.ship_to_name ,
            o.location ,
            o.cust_po ,
            o.routing ,
            o.fob ,
            o.attention ,
            o.tax_id ,
            o.terms ,
            o.curr_key ,
            ar.salesperson_code salesperson ,
            ar.territory_code Territory , 
-- t.territory Territory, 
            t.region ,
            o.total_amt_order ,
            o.total_discount ,
            o.total_tax ,
            o.freight ,
            o.qty_ordered ,
            o.qty_shipped ,
            o.total_invoice ,
            o.invoice_no ,
            o.doc_ctrl_num ,
            o.date_invoice ,
            o.date_entered ,
            o.date_sch_ship ,
            o.date_shipped ,
            o.status ,
            CASE o.status
              WHEN 'A' THEN 'Hold'
              WHEN 'B' THEN 'Credit Hold'
              WHEN 'C' THEN 'Credit Hold'
              WHEN 'E' THEN 'Other'
              WHEN 'H' THEN 'Hold'
              WHEN 'M' THEN 'Other'
              WHEN 'N' THEN 'Received'
              WHEN 'P'
              THEN CASE WHEN ISNULL(( SELECT TOP ( 1 )
                                                c.status
                                      FROM      tdc_carton_tx c ( NOLOCK )
                                      WHERE     o.order_no = c.order_no
                                                AND o.ext = c.order_ext
                                                AND ( c.void = 0
                                                      OR c.void IS NULL
                                                    )
                                    ), '') IN ( 'F', 'S', 'X' ) THEN 'Shipped'
                        ELSE 'Processing'
                   END
              WHEN 'Q' THEN 'Processing'
              WHEN 'R' THEN 'Shipped'
              WHEN 'S' THEN 'Shipped'
              WHEN 'T' THEN 'Shipped'
              WHEN 'V' THEN 'Void'
              WHEN 'X' THEN 'Void'
              ELSE ''
            END AS status_desc ,
            o.who_entered ,
            o.shipped_flag ,
            o.hold_reason ,
            o.orig_no ,
            o.orig_ext ,
            o.promo_id ,
            o.promo_level ,
            o.order_type ,
            o.FramesOrdered ,
            o.FramesShipped ,
            o.back_ord_flag ,
            o.Cust_type ,
            CAST('1/1/1900' AS DATETIME) AS return_date ,
            SPACE(40) AS reason ,
            CAST(0.00 AS DECIMAL(20, 8)) AS return_amt ,
            0 AS return_qty ,
            o.source ,
            uc = 0
    INTO    #temp
    FROM    #territory t
            INNER JOIN cvo_adord_vw AS o WITH ( NOLOCK ) ON t.territory = o.Territory
            INNER JOIN #promo_id p ON p.promo_id = o.promo_id
            INNER JOIN #promo_level pl ON pl.promo_level = o.promo_level
            INNER JOIN armaster ar ( NOLOCK ) ON ar.customer_code = o.cust_code
                                                 AND ar.ship_to_code = o.ship_to
    WHERE   1 = 1
            AND ISNULL(o.promo_id, '') <> '' -- 10/31/2013
-- 10/30/2013 WHERE (o.promo_id IN (@Promo)) 
/*
and (o.promo_id in (@PromoLevel)) 
*/
            AND ( o.date_entered BETWEEN @startdate
                                 AND     DATEADD(ms, -3,
                                                 DATEADD(dd,
                                                         DATEDIFF(dd, 0,
                                                              @enddate) + 1, 0)) )
-- AND (o.Territory IN (@Territory)) 
            AND o.who_entered <> 'backordr' -- 1/18/2016
-- AND ((o.who_entered <> 'backordr' and o.ext = 0) or o.who_entered = 'outofstock') 
-- AND              (o.order_type <> 'st-rb') 
            AND o.status <> 'V'; -- 110714 - exclude void orders

-- look for split international orders -- TBD

-- Collect the returns

    SELECT  o.orig_no order_no ,
            o.orig_ext ext ,
            return_date = o.date_entered ,
            reason = MIN(rc.return_desc)
    INTO    #r
    FROM    #temp t
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



    UPDATE  t
    SET     t.return_date = #r.return_date ,
            t.reason = #r.reason
    FROM    #r ,
            #temp t
    WHERE   #r.order_no = t.order_no
            AND #r.ext = t.ext;

--select * from #r
--select * From #temp

-- delete from #temp where order_no = 1639532 -- manual exclusion

-- make sure you have all territories in output, even if no data exists

    SELECT   DISTINCT
            s.territory_code ,
            t.region ,
            s.salesperson_code
    INTO    #reps
    FROM    #territory t -- inner join armaster (nolock) a on t.territory = a.territory_code 
            INNER JOIN arsalesp (NOLOCK) s ON s.territory_code = t.territory
    WHERE   s.territory_code IS NOT NULL
            AND s.salesperson_code <> 'smithma'
    -- and a.status_type = 1 -- active accounts only
            AND s.status_type = 1;
    
    SELECT DISTINCT
            promo_id ,
            promo_level ,
            status
    INTO    #promos
    FROM    #temp;
    
    INSERT  INTO #temp
            ( Territory ,
              region ,
              salesperson ,
              cust_code ,
              ship_to ,
              ship_to_name ,
              tax_id ,
              date_entered ,
              status ,
              status_desc ,
              shipped_flag ,
              FramesOrdered ,
              FramesShipped ,
              Cust_type ,
              return_qty ,
              source ,
              uc ,
              promo_id ,
              promo_level
            )
            SELECT  #reps.territory_code ,
                    #reps.region ,
                    #reps.salesperson_code ,
                    '' ,
                    '' ,
                    '' ,
                    '' ,
                    @enddate ,
                    #promos.status ,
                    '' ,
                    '' ,
                    0 ,
                    0 ,
                    '' ,
                    0 ,
                    'T' ,
                    0 ,
                    #promos.promo_id ,
                    #promos.promo_level
            FROM    #reps
                    CROSS JOIN #promos;
 
    UPDATE  t
    SET     uc = 1
    FROM    ( SELECT    cust_code ,
                        promo_id ,
                        MIN(order_no) min_order,
						MIN(ext) min_ext
              FROM      #temp
                        INNER JOIN CVO_armaster_all car ( NOLOCK ) ON car.customer_code = #temp.cust_code
                                                              AND car.ship_to = #temp.ship_to
              WHERE     source <> 'T'
                        AND ( ISNULL(reason, '') = ''
                              AND NOT EXISTS ( SELECT   1
                                               FROM     cvo_promo_override_audit poa
                                               WHERE    poa.order_no = #temp.order_no
                                                        AND poa.order_ext = #temp.ext )
							  AND #temp.ext = (SELECT MIN(o.ext) FROM orders o WHERE o.order_no = #temp.order_no AND o.status <> 'V')
                            )
                        AND car.door = 1
              GROUP BY  cust_code ,
                        promo_id
            ) AS m
            INNER JOIN #temp t ON t.cust_code = m.cust_code
                                  AND t.promo_id = m.promo_id
                                  AND t.order_no = m.min_order
								  AND t.ext = m.min_ext;
   

    SELECT DISTINCT
            order_no ,
            ext ,
            cust_code ,
            ship_to ,
            ship_to_name ,
            location ,
            cust_po ,
            routing ,
            fob ,
            attention ,
            tax_id ,
            terms ,
            curr_key ,
            salesperson ,
            Territory ,
            region ,
            total_amt_order ,
            total_discount ,
            total_tax ,
            freight ,
            qty_ordered ,
            qty_shipped ,
            ISNULL(total_invoice, 0) total_invoice ,
            invoice_no ,
            doc_ctrl_num ,
            date_invoice ,
            date_entered ,
            date_sch_ship ,
            date_shipped ,
            status ,
-- 022714 - tag - fineline the reason for the disqualification on rebills
--  you'll find the rebill order later as a qualified order
            CASE WHEN reason = 'Credit & Rebill' THEN 'Credit/Rebill'
                 ELSE status_desc
            END AS status_desc ,
            who_entered ,
            shipped_flag ,
            hold_reason ,
            orig_no ,
            orig_ext ,
            promo_id ,
            promo_level ,
            order_type ,
            FramesOrdered ,
            FramesShipped ,
            back_ord_flag ,
            Cust_type ,
            return_date ,
            LTRIM(RTRIM(reason)) reason ,
            ISNULL(return_amt, 0) return_amt ,
            ISNULL(return_qty, 0) return_qty ,
            CASE WHEN #temp.ext <> (SELECT MIN(ext) FROM orders o WHERE o.order_no = #temp.order_no AND o.status <> 'V') THEN 'S' ELSE source END AS source ,
            Qual_order = CASE WHEN source = 'T' THEN 0
                              WHEN ISNULL(reason, '') = ''
                                   AND NOT EXISTS ( SELECT  1
                                                    FROM    cvo_promo_override_audit poa
                                                    WHERE   poa.order_no = #temp.order_no
                                                            AND poa.order_ext = #temp.ext )
								   AND #temp.ext = (SELECT MIN(ext) FROM orders o WHERE o.order_no = #temp.order_no AND o.status <> 'V') -- don't qualify split orders
                              THEN 1

                              ELSE 0
                         END ,
            ( SELECT TOP 1
                        LTRIM(RTRIM(failure_reason))
              FROM      cvo_promo_override_audit poa
              WHERE     poa.order_no = #temp.order_no
                        AND poa.order_ext = #temp.ext
              ORDER BY  override_date DESC
            ) override_reason ,
            uc  
-- 2/10/16 - for region weekly summary
            ,
            CONVERT(VARCHAR, DATEADD(dd,
                                     1 - ( DATEPART(dw, date_entered) - 1 ),
                                     date_entered), 101) wk_Begindate ,
            CONVERT(VARCHAR, DATEADD(dd, ( 9 - DATEPART(dw, date_entered) ),
                                     date_entered), 101) wk_EndDate
    FROM    #temp;






GO


GRANT EXECUTE ON  [dbo].[cvo_promotions_tracker_terr_sp] TO [public]
GO
