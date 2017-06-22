SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[cvo_cart_auto_select_sp]
(
    @cart_no VARCHAR(50),
    @base_Type VARCHAR(10),
    @NUM_ORDERS INT
)

-- EXEC CVO_CART_AUTO_SELECT_SP 'TG Test Cart', '%st%', 16

-- SELECT * FROM dbo.cvo_cart_order_parts AS cop

AS
BEGIN

    SET NOCOUNT ON
    ;

    DECLARE
        @base_ord INT, @base_ext INT, @id INT, @debug INT
    ;

    SELECT @debug = 1
    ;

	IF @debug = 1
	SELECT TOP 10 a.order_no, a.ext
    FROM
        cvo_adord_vw a (NOLOCK)
        JOIN CVO_orders_all co
            ON co.ext = a.ext
               AND co.order_no = a.order_no
    WHERE
        a.status = 'n'
        AND a.date_sch_ship <= GETDATE()
        AND a.allocation_date <= GETDATE()
        AND a.who_entered <> 'backordr'
        AND ISNULL(co.st_consolidate, 0) = 0
        AND a.order_type LIKE @base_Type
		AND a.FramesOrdered >= CASE WHEN a.order_type LIKE '%st%' THEN 5 ELSE 1 end
        AND EXISTS
    (
        SELECT 1
        FROM tdc_pick_queue (NOLOCK)
        WHERE
            trans_type_no = a.order_no
            AND trans_type_ext = a.ext
    )
    ;

    SELECT TOP 1
        @base_ord = a.order_no, @base_ext = a.ext
    FROM
        cvo_adord_vw a (NOLOCK)
        JOIN CVO_orders_all co
            ON co.ext = a.ext
               AND co.order_no = a.order_no
    WHERE
        a.status = 'n'
        AND a.date_sch_ship <= GETDATE()
        AND a.allocation_date <= GETDATE()
        AND a.who_entered <> 'backordr'
        AND ISNULL(co.st_consolidate, 0) = 0
        AND a.order_type LIKE @base_Type
		AND a.FramesOrdered >= CASE WHEN a.order_type LIKE '%st%' THEN 5 ELSE 1 end
        AND EXISTS
    (
        SELECT 1
        FROM tdc_pick_queue (NOLOCK)
        WHERE
            trans_type_no = a.order_no
            AND trans_type_ext = a.ext
    )
    ;


    IF @debug = 1
        SELECT
            @base_ord, @base_ext
        ;

    IF (OBJECT_ID('dbo.#orders_to_check_in')) IS NOT NULL
        DROP TABLE #orders_to_check_in
        ;

    CREATE TABLE #ORDERS_TO_CHECK_IN
    (
        rec_id INT,
        base_order VARCHAR(8000),
        order_no INT,
        order_ext INT,
        sch_ship_date DATETIME,
        allocation_date DATETIME,
        promo_id VARCHAR(20),
        promo_level VARCHAR(30),
        Common_items INT
    )
    ;

    INSERT #ORDERS_TO_CHECK_IN
    (
        rec_id,
        base_order,
        order_no,
        order_ext,
        sch_ship_date,
        allocation_date,
        promo_id,
        promo_level,
        Common_items
    )
    EXEC cvo_cart_similar_orders_sp
        @base_ord, @base_ext, @base_Type, @NUM_ORDERS
    ;

    IF @debug = 1
        SELECT *
        FROM #ORDERS_TO_CHECK_IN AS otci
        ;

    -- do the check-ins now
    SELECT @id = MIN(rec_id)
    FROM #ORDERS_TO_CHECK_IN AS otci
    ;

    WHILE @id IS NOT NULL
    BEGIN
        SELECT
            @base_ord = order_no, @base_ext = order_ext
        FROM #ORDERS_TO_CHECK_IN AS otci
        WHERE otci.rec_id = @id
        ;
        IF @debug = 1
            SELECT
                @cart_no, @base_ord, @base_ext
            ;
        IF @debug <> 1
            EXEC dbo.cvo_pick_cart_process_sp
                @cart_no = @cart_no,
                @order_no = @base_ord,  -- int
                @order_ext = @base_ext, -- int
                @proc_option = 0
            ; -- int

        SELECT @id = MIN(rec_id)
        FROM #ORDERS_TO_CHECK_IN AS otci
        WHERE rec_id > @id
		;
    END
    ;

END
;

GRANT EXECUTE
ON CVO_CART_AUTO_SELECT_SP
TO  PUBLIC
;
GO
GRANT EXECUTE ON  [dbo].[cvo_cart_auto_select_sp] TO [public]
GO
