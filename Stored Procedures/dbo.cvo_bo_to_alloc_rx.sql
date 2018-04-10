SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[cvo_bo_to_alloc_rx] @ss INT = NULL
AS -- RX backorders to allocate
-- exec cvo_bo_to_alloc_rx
-- 030915 - change safety stock figure based on pom date
-- 04/09/2018 - add comments

    SET NOCOUNT ON;
    -- SET ANSI_WARNINGS OFF;

--declare @ss int -- safety stock level for reserve
--select @ss = 5


    DECLARE @today DATETIME ,
        @bo_hold VARCHAR(2);
    SELECT  @today = DATEADD(dd, DATEDIFF(dd, 0, GETDATE()), 0);
    SELECT  @bo_hold = 'xx';

    IF OBJECT_ID('tempdb..#t') IS NOT NULL
        DROP TABLE #t;


    SELECT  o.order_no ,
            o.ext ,
            ol.line_no ,
            o.user_category ,
            o.date_entered ,
            i.category brand ,
            ia.field_2 style ,
            ia.category_5 color_code ,
            ia.field_19 a_size ,
            ol.part_no ,
            i.type_code ,
            CASE WHEN ia.field_28 > @today THEN NULL
                 ELSE ia.field_28
            END AS pom_date ,
            ss = CASE WHEN ISNULL(ia.field_28, GETDATE()) < DATEADD(yy, -1,
                                                              @today) THEN 0
                      ELSE ISNULL(@ss, 5)
                 END ,
            ol.location ,
            ol.ordered - ol.shipped open_qty ,
            -1 AS qty_to_alloc ,
            0 AS qty_avl_to_alloc ,
            0 AS reserveqty ,
            0 AS quarantine ,
            SPACE(12) AS nextpoduedate ,
            0 AS DDTONEXTPO ,
            ol.note ,
            o.phone ,
            o.attention ,
            o.ship_to_name ,
            o.cust_code ,
            o.ship_to ,
            i.description ,
            bo_days = DATEDIFF(d, o.sch_ship_date, @today) ,
            CASE WHEN DATEDIFF(d, o.sch_ship_date, @today) < 0 THEN 'Future'
                 WHEN DATEDIFF(d, o.sch_ship_date, @today) = 0 THEN 'Current'
                 WHEN DATEDIFF(d, o.sch_ship_date, @today) BETWEEN 1 AND 21
                 THEN '1-21'
                 WHEN DATEDIFF(d, o.sch_ship_date, @today) BETWEEN 22 AND 42
                 THEN '22-42'
                 WHEN DATEDIFF(d, o.sch_ship_date, @today) > 42 THEN '43 +'
                 ELSE 'N/A'
            END AS DaysOverDue
    INTO    #t
    FROM    orders o ( NOLOCK )
            INNER JOIN CVO_orders_all co ( NOLOCK ) ON co.order_no = o.order_no
                                                       AND co.ext = o.ext
            LEFT OUTER JOIN CVO_promotions p ( NOLOCK ) ON p.promo_id = co.promo_id
                                                           AND p.promo_level = co.promo_level
            INNER JOIN ord_list ol ( NOLOCK ) ON o.order_no = ol.order_no
                                                 AND o.ext = ol.order_ext
            INNER JOIN CVO_ord_list col ( NOLOCK ) ON col.order_no = ol.order_no
                                                      AND col.order_ext = ol.order_ext
                                                      AND col.line_no = ol.line_no
            INNER JOIN inv_master i ( NOLOCK ) ON ol.part_no = i.part_no
            INNER JOIN inv_master_add ia ( NOLOCK ) ON ol.part_no = ia.part_no
            LEFT OUTER JOIN cvo_hard_allocated_vw alloc ( NOLOCK ) ON alloc.order_no = o.order_no
                                                              AND alloc.order_ext = o.ext
                                                              AND alloc.line_no = ol.line_no
                                                              AND alloc.order_type = 'S'
    WHERE   1 = 1
-- and  o.status ='N' 
            AND ( ( o.status = 'a'
                    AND ( o.hold_reason = @bo_hold
                          OR p.hold_reason = @bo_hold
                        )
                  )
                  OR o.status = 'n'
                )
            AND o.type = 'i' 
-- and o.who_entered in ('backordr','outofstock')
            -- AND o.sch_ship_date < @today
			AND DATEDIFF(d, o.sch_ship_date, @today) > 21 -- per KM 032618
            AND ol.ordered > ( ol.shipped + ISNULL(alloc.qty, 0) )
            AND i.type_code <> 'case'
            AND ( o.user_category LIKE 'rx%'
                  OR o.user_category = 'st-tr'
				  -- OR (o.user_category NOT LIKE 'rx%' AND DATEDIFF(d, o.sch_ship_date, @today) > 42) -- 5/5/2017 per CP request
                )
            AND col.is_customized = 'n'
            AND ol.part_type = 'p';

    CREATE INDEX idx_t ON #t (order_no, ext, location, part_no) INCLUDE (open_qty, qty_to_alloc);

-- get reserve allocations
    IF OBJECT_ID('tempdb..#ra') IS NOT NULL
        DROP TABLE #ra;
    SELECT  t.location ,
            t.part_no ,
            SUM(t.qty) r_alloc
    INTO    #ra
    FROM    tdc_soft_alloc_tbl t ( NOLOCK )
            JOIN tdc_bin_master b ( NOLOCK ) ON b.bin_no = t.bin_no
                                                AND t.location = b.location
                                                AND b.group_code = 'reserve'
    GROUP BY t.location ,
            t.part_no;

-- for each sku, consume the avail inventory

    DECLARE @loc VARCHAR(12) ,
        @part VARCHAR(40) ,
        @qty_avl_to_alloc INT ,
        @line_no INT ,
        @order INT ,
        @ext INT ,
        @open_qty INT ,
        @qty_to_alloc INT ,
        @reserveqty INT ,
        @quarantine INT ,
        @nextpoduedate DATETIME;

    SELECT  @loc = '';
    SELECT  @part = '';
    SELECT  @loc = MIN(ISNULL(location, ''))
    FROM    #t
    WHERE   location > @loc;
-- select @loc
    SELECT  @part = MIN(ISNULL(part_no, ''))
    FROM    #t
    WHERE   location = @loc
            AND part_no > @part;
-- select @part

    SELECT  @ss = ss
    FROM    #t
    WHERE   location = @loc
            AND part_no = @part;

    SELECT  @qty_avl_to_alloc = ISNULL(ReserveQty, 0) - @ss
            - ISNULL(#ra.r_alloc, 0) ,
            @reserveqty = ISNULL(ReserveQty, 0) - ISNULL(#ra.r_alloc, 0) ,
            @quarantine = ISNULL(Quarantine, 0) ,
            @nextpoduedate = NextPODueDate
    FROM    cvo_item_avail_vw cia
            LEFT OUTER JOIN #ra ON #ra.location = @loc
                                   AND #ra.part_no = @part
    WHERE   cia.location = @loc
            AND cia.part_no = @part
            AND qty_avl <= 0.;
    UPDATE  #t
    SET     nextpoduedate = @nextpoduedate ,
            DDTONEXTPO = DATEDIFF(DD, @today,
                                  ISNULL(@nextpoduedate, '12/31/2020'))
    WHERE   #t.part_no = @part;
-- select @qty_avl
 

    WHILE @loc IS NOT NULL
        BEGIN
            WHILE @part IS NOT NULL
                BEGIN
                    WHILE @qty_avl_to_alloc > 0
                        BEGIN
                            SELECT TOP 1
                                    @order = ISNULL(#t.order_no, -1) ,
                                    @ext = ISNULL(#t.ext, 0) ,
                                    @line_no = ISNULL(#t.line_no, 0) ,
                                    @open_qty = ISNULL(#t.open_qty, 0)
                            FROM    #t
                            WHERE   #t.part_no = @part
                                    AND #t.location = @loc
                                    AND #t.qty_to_alloc = -1
                            ORDER BY #t.order_no ASC; 
                            IF @order = -1
                                BREAK;
                            SELECT  @qty_to_alloc = CASE WHEN @qty_avl_to_alloc >= @open_qty
                                                         THEN @open_qty
                                                         ELSE @qty_avl_to_alloc
                                                    END;
                            UPDATE  #t
                            SET     #t.qty_to_alloc = @qty_to_alloc ,
                                    #t.qty_avl_to_alloc = @qty_avl_to_alloc ,
                                    #t.reserveqty = @reserveqty -- , #t.quarantine = @quarantine -- , #t.nextpoduedate = @nextpoduedate
                            WHERE   order_no = @order
                                    AND ext = @ext
                                    AND line_no = @line_no
                                    AND location = @loc
                                    AND part_no = @part;
                            SELECT  @qty_avl_to_alloc = @qty_avl_to_alloc
                                    - @qty_to_alloc;
			-- select 'qty', @loc loc, @part part , @qty_avl qty_avl
                        END; -- qty
                    SELECT  @part = MIN(ISNULL(part_no, ''))
                    FROM    #t
                    WHERE   location = @loc
                            AND part_no > @part;
                    IF @part = ''
                        BREAK;
		
                    SELECT  @ss = ss
                    FROM    #t
                    WHERE   location = @loc
                            AND part_no = @part;

                    SELECT  @qty_avl_to_alloc = ISNULL(ReserveQty, 0) - @ss
                            - ISNULL(#ra.r_alloc, 0) ,
                            @reserveqty = ISNULL(ReserveQty, 0)
                            - ISNULL(#ra.r_alloc, 0) ,
                            @quarantine = ISNULL(Quarantine, 0) ,
                            @nextpoduedate = NextPODueDate
                    FROM    cvo_item_avail_vw cia
                            LEFT OUTER JOIN #ra ON #ra.location = @loc
                                                   AND #ra.part_no = @part
                    WHERE   cia.location = @loc
                            AND cia.part_no = @part
                            AND qty_avl <= 0.;
		-- select 'part', @loc loc, @part part , @qty_avl qty_avl
                    UPDATE  #t
                    SET     quarantine = ISNULL(@quarantine, 0) ,
                            nextpoduedate = @nextpoduedate ,
                            DDTONEXTPO = DATEDIFF(DD, @today,
                                                  ISNULL(@nextpoduedate,
                                                         '12/31/2020'))
                    WHERE   #t.part_no = @part;
                END; -- part
            SELECT  @loc = MIN(ISNULL(location, ''))
            FROM    #t
            WHERE   location > @loc;
            IF @loc = ''
                BREAK;
            SELECT  @part = MIN(ISNULL(part_no, ''))
            FROM    #t
            WHERE   location = @loc
                    AND part_no > @part;
            IF @part = ''
                BREAK;
            SELECT  @ss = ss
            FROM    #t
            WHERE   location = @loc
                    AND part_no = @part;

            SELECT  @qty_avl_to_alloc = ISNULL(ReserveQty, 0) - @ss
                    - ISNULL(#ra.r_alloc, 0) ,
                    @reserveqty = ISNULL(ReserveQty, 0) - ISNULL(#ra.r_alloc,
                                                              0) ,
                    @quarantine = ISNULL(Quarantine, 0) ,
                    @nextpoduedate = NextPODueDate
            FROM    cvo_item_avail_vw cia
                    LEFT OUTER JOIN #ra ON #ra.location = @loc
                                           AND #ra.part_no = @part
            WHERE   cia.location = @loc
                    AND cia.part_no = @part
                    AND qty_avl <= 0.;
            UPDATE  #t
            SET     quarantine = ISNULL(@quarantine, 0) ,
                    nextpoduedate = @nextpoduedate ,
                    DDTONEXTPO = DATEDIFF(DD, @today,
                                          ISNULL(@nextpoduedate, '12/31/2020'))
            WHERE   #t.part_no = @part;
	-- select ' loc', @loc loc, @part part , @qty_avl qty_avl

        END; -- location


--select #qty.*,#t.order_no, #t.ext, #t.open_qty, #t.qty_to_alloc from #qty
--join #t on #qty.part_no = #t.part_no and #qty.location = #t.location

    SELECT  brand ,
            style , 
-- color_code, a_size, 
            part_no ,
            type_code ,
            pom_date ,
            ss ,
            #t.order_no ,
            #t.ext , 
-- line_no, 
            user_category ,
            date_entered ,
            location ,
            open_qty ,
            qty_to_alloc , 
-- qty_avl_to_alloc, 
            reserveqty ,
            reserve_bin = ( SELECT TOP 1
                                    lbs.bin_no
                            FROM    lot_bin_stock lbs
                                    JOIN tdc_bin_master bm ON bm.location = lbs.location
                                                              AND bm.bin_no = lbs.bin_no
                                                              AND bm.group_code = 'RESERVE'
                            WHERE   lbs.part_no = #t.part_no
                                    AND lbs.location = #t.location
                                    AND lbs.qty >= qty_avl_to_alloc
                          ) ,
            quarantine ,
            ISNULL(nextpoduedate, '') nextpoduedate ,
            DDTONEXTPO ,
            note ,
            CASE WHEN LEN(phone) = 10
                 THEN SUBSTRING(phone, 1, 3) + '-' + SUBSTRING(phone, 4, 3)
                      + '-' + SUBSTRING(phone, 7, 4)
                 ELSE phone
            END AS phone ,
            attention ,
            ship_to_name ,
            cust_code ,
            ship_to ,
            description ,
            bo_days ,
            DaysOverDue,
			ISNULL(c.comment,'<Click here to enter a comment>') comment -- 4/9/2018
    FROM    #t
	LEFT OUTER JOIN cvo_rxbo_comment_tbl c ON c.order_no = #t.order_no AND c.ext = #t.ext
    WHERE   1 = 1
-- and qty_to_alloc > 0 
ORDER BY    part_no ,
            qty_avl_to_alloc DESC;





GO
GRANT EXECUTE ON  [dbo].[cvo_bo_to_alloc_rx] TO [public]
GO
