SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[cvo_cart_similar_orders_sp]
(
    @baseorder_no INT,
    @base_ext INT,
    @base_type VARCHAR(8),
    @num_orders INT
)
AS
BEGIN

    SET NOCOUNT ON
    ;


    -- usage:
    -- exec cvo_cart_similar_orders_sp 3130992, 0, '%ST%', 16
    /* 
 select top 1 order_no, ext From cvo_adord_vw where status = 'n' and date_sch_ship <= getdate()
 and who_entered <> 'backordr' and order_type like 'st%' and framesordered > 5 -- open order list
 order by framesordered desc

 select part_no, count(order_no) num_orders, min(order_no) min_order_no
  -- select * 
  from cvo_open_order_detail_vw
  where allocation_date <= getdate() and sch_ship_date <= getdate()
  and status = 'n' and restype in ('frame','sun') and qty_avl > 0
  group by part_no
 order by count(order_no) desc

*/

    DECLARE
        @threshold INT,
        -- @baseorder_no INT, @base_ext INT, 
        @totalordlist INT,
        @thresholdord_list INT
    ;


    SELECT @threshold = 0
    ; --, @baseorder_no = 2622825 , @base_ext = 0

    SELECT @totalordlist = COUNT(*)
    FROM ord_list
    WHERE
        order_no = @baseorder_no
        AND order_ext = @base_ext
    ;
    -- SELECT @totalordlist

    SELECT @thresholdord_list = @threshold * @totalordlist / 100
    ;

    -- SELECT @thresholdord_list

    IF (OBJECT_ID('tempdb.dbo.#O') IS NOT NULL)
        DROP TABLE #O
        ;
    SELECT
        REPLACE(CAST(@baseorder_no AS VARCHAR(8)) + '-' + CAST(@base_ext AS VARCHAR(2)), ' ', '') base_order,
        ALLorder.order_no,
        ALLorder.order_ext,
        o.user_category,
        o.sch_ship_date,
        co.allocation_date,
        co.promo_id,
        co.promo_level,
        COUNT(*) Common_items
    INTO #o
    FROM
        ord_list (NOLOCK) sample
        JOIN ord_list (NOLOCK) ALLorder
            ON ALLorder.part_no = sample.part_no
        LEFT OUTER JOIN dbo.cvo_hard_allocated_vw H
            ON H.line_no = ALLorder.line_no
               AND H.order_ext = ALLorder.order_ext
               AND H.order_no = ALLorder.order_no
        JOIN orders (NOLOCK) o
            ON o.order_no = ALLorder.order_no
               AND o.ext = ALLorder.order_ext
        JOIN CVO_orders_all (NOLOCK) co
            ON co.ext = o.ext
               AND co.order_no = o.order_no
        JOIN inv_master i (NOLOCK)
            ON i.part_no = ALLorder.part_no
    WHERE
        sample.order_no = @baseorder_no
        AND sample.order_ext = @base_ext
        AND sample.order_no <> ALLorder.order_no
        AND o.status IN ( 'n' )
        AND o.user_category LIKE @base_type
        AND o.type = 'i'
        AND i.type_code IN ( 'frame', 'sun' )
        AND ISNULL(co.st_consolidate, 0) = 0
        AND co.allocation_date <= GETDATE()
        AND o.sch_ship_date <= GETDATE()
		AND EXISTS (SELECT 1 FROM tdc_pick_queue WHERE trans_type_no = o.order_no AND trans_type_ext = o.ext)
    GROUP BY
        ALLorder.order_no,
        ALLorder.order_ext,
        o.user_category,
        co.promo_id,
        co.promo_level,
        o.sch_ship_date,
        co.allocation_date
    HAVING COUNT(*) > @thresholdord_list
    ;
    -- ORDER BY COUNT(*) DESC, o.sch_ship_date

    INSERT INTO #o
    SELECT
        REPLACE(CAST(@baseorder_no AS VARCHAR(8)) + '-' + CAST(@base_ext AS VARCHAR(2)), ' ', '') base_order,
        o.order_no,
        o.ext,
        o.user_category,
        o.sch_ship_date,
        co.allocation_date,
        co.promo_id,
        co.promo_level,
        999 Common_items
    FROM
        orders (NOLOCK) o
        JOIN CVO_orders_all (NOLOCK) co
            ON co.ext = o.ext
               AND co.order_no = o.order_no
    WHERE
        o.order_no = @baseorder_no
        AND o.ext = @base_ext
        AND o.status IN ( 'n' )
        AND o.type = 'i'
    ;

    SELECT TOP (@num_orders)
        ROW_NUMBER() OVER (ORDER BY order_no),
        base_order,
        order_no,
        order_ext,
        sch_ship_date,
        allocation_date,
        promo_id,
        promo_level,
        Common_items
    FROM #o
    ORDER BY
        Common_items DESC, sch_ship_date
    ;

END
;

GRANT ALL
ON cvo_cart_similar_orders_sp
TO  PUBLIC
;

GO

GRANT EXECUTE ON  [dbo].[cvo_cart_similar_orders_sp] TO [public]
GO
