SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[cvo_bo_to_subst_st]
AS
BEGIN

    -- ST backorders to substitute
    -- exec cvo_bo_to_subst_st
    -- 6/15/2015 - tag - update to look at only stock with min 10 ATP
	-- 03/08/2018 - tag - use IFP data to look for available subs

    SET NOCOUNT ON;
    SET ANSI_WARNINGS OFF;

    DECLARE @asofdate DATETIME,
            @location VARCHAR(10),
            @collection VARCHAR(1000),
            @Style_list VARCHAR(8000)
            ;

    DECLARE @today DATETIME;
    SELECT @today = DATEADD(dd, DATEDIFF(dd, 0, GETDATE()), 0);

    SELECT @asofdate = DATEADD(mm, DATEDIFF(mm, 0, GETDATE()), 0);


    IF OBJECT_ID('tempdb..#orders') IS NOT NULL
        DROP TABLE #orders;
    CREATE TABLE #orders
    (
        id INT IDENTITY(1, 1),
        order_no INT,
        ext INT,
        line_no INT,
        user_category VARCHAR(10),
        date_entered DATETIME,
        brand VARCHAR(20),
        style VARCHAR(20),
        color VARCHAR(20),
        size FLOAT,
        part_no VARCHAR(40),
        type_code VARCHAR(10),
        location VARCHAR(12),
        open_qty INT,
        qty_to_sub INT,
        sub_part_no VARCHAR(40),
        qty_avl_to_sub INT,
        nextpoduedate VARCHAR(12)
    );

    INSERT #orders
    SELECT o.order_no,
           o.ext,
           ol.line_no,
           o.user_category,
           o.date_entered,
           i.category brand,
           ia.field_2 style,
           ia.category_5 color,
           ia.field_17 size,
           ol.part_no,
           i.type_code,
           ol.location,
           ol.ordered - ol.shipped open_qty,
           -1 AS qty_to_sub,
           SPACE(40) AS sub_part_no,
           0 AS qty_avl_to_sub,
           SPACE(12) AS nextpoduedate
    -- into #orders
    FROM dbo.orders o (NOLOCK)
        INNER JOIN ord_list ol (NOLOCK)
            ON o.order_no = ol.order_no
               AND o.ext = ol.order_ext
        INNER JOIN dbo.CVO_ord_list col (NOLOCK)
            ON col.order_no = ol.order_no
               AND col.order_ext = ol.order_ext
               AND col.line_no = ol.line_no
        INNER JOIN dbo.inv_master i (NOLOCK)
            ON ol.part_no = i.part_no
        INNER JOIN dbo.inv_master_add ia (NOLOCK)
            ON ol.part_no = ia.part_no
        INNER JOIN dbo.cvo_item_avail_vw iav (NOLOCK)
            ON ol.part_no = iav.part_no
               AND o.location = iav.location
        JOIN dbo.CVO_armaster_all car (NOLOCK)
            ON car.customer_code = o.cust_code
               AND car.ship_to = o.ship_to
        LEFT OUTER JOIN dbo.cvo_hard_allocated_vw alloc (NOLOCK)
            ON alloc.order_no = o.order_no
               AND alloc.order_ext = o.ext
               AND alloc.line_no = ol.line_no
               AND alloc.order_type = 'S'
    WHERE o.status = 'n'
          AND ia.field_26 <= @today
          AND ISNULL(iav.qty_avl, 0) <= 0
          AND ISNULL(car.allow_substitutes, 0) = 1
          AND o.type = 'i'
          -- and o.who_entered in ('backordr','outofstock')
          AND o.sch_ship_date < @today
          AND ol.ordered > (ol.shipped + ISNULL(alloc.qty, 0))
          AND i.type_code IN ( 'frame', 'sun' )
          AND o.user_category LIKE 'st%'
          AND o.user_category NOT IN ('st-tr','st-ts')
          AND col.is_customized = 'n'
          AND ol.part_type = 'p';

    CREATE NONCLUSTERED INDEX idx_t
    ON #orders
    (
    order_no,
    ext,
    location,
    part_no
    )
    INCLUDE
    (
    open_qty,
    qty_to_sub
    );

    -- get parts and qtys available as substitutes

    IF OBJECT_ID('tempdb..#ifp') IS NOT NULL
        DROP TABLE #ifp;

    CREATE TABLE #ifp
    (
        brand VARCHAR(10),
        style VARCHAR(40),
        vendor VARCHAR(12),
        type_code VARCHAR(10),
        gender VARCHAR(15),
        material VARCHAR(40),
        moq VARCHAR(255),
        watch VARCHAR(15),
        sf VARCHAR(40),
        rel_date DATETIME,
        pom_date DATETIME,
        mth_since_rel INT,
        s_sales_m1_3 FLOAT(8),
        s_sales_m1_12 FLOAT(8),
        s_e4_wu INT,
        s_e12_wu INT,
        s_e52_wu INT,
        s_promo_w4 INT,
        s_promo_w12 INT,
        s_gross_w4 INT,
        s_gross_w12 INT,
        LINE_TYPE VARCHAR(3),
        sku VARCHAR(30),
        location VARCHAR(12),
        mm INT,
        p_rel_date DATETIME,
        p_pom_date DATETIME,
        lead_time INT,
        bucket DATETIME,
        QOH INT,
        atp INT,
        reserve_qty INT,
        quantity INT,
        mult DECIMAL(20, 8),
        s_mult DECIMAL(20, 8),
        sort_seq INT,
        alloc_qty INT,
        non_alloc_qty INT,
        pct_of_style DECIMAL(37, 19),
        pct_first_po FLOAT(8),
        pct_sales_style_m1_3 FLOAT(8),
        p_e4_wu INT,
        p_e12_wu INT,
        p_e52_wu INT,
        p_subs_w4 INT,
        p_subs_w12 INT,
        s_mth_usg INT,
        p_mth_usg INT,
        s_mth_usg_mult DECIMAL(31, 8),
        p_sales_m1_3 INT,
        p_po_qty_y1 DECIMAL(38, 8),
        ORDER_THRU_DATE DATETIME,
        TIER VARCHAR(1),
        p_type_code VARCHAR(10),
        s_rx_w4 INT,
        s_rx_w12 INT,
        p_rx_w4 INT,
        p_rx_w12 INT,
        s_ret_w4 INT,
        s_ret_w12 INT,
        p_ret_w4 INT,
        p_ret_w12 INT,
        s_wty_w4 INT,
        s_wty_w12 INT,
        p_wty_w4 INT,
        p_wty_w12 INT,
        p_gross_w4 INT,
        p_gross_w12 INT,
        price DECIMAL(20, 8),
        frame_type VARCHAR(40)
    );


	SELECT @collection = '', @Style_list = '', @location = '';

    SELECT @collection = stuff ((SELECT DISTINCT ',' + brand
		   FROM #orders FOR XML PATH('') ),1,1, ''),
		   @Style_list = stuff ((SELECT DISTINCT ',' + style
		   FROM #orders FOR XML PATH('') ),1,1, ''),
		   @location = stuff ((SELECT DISTINCT ',' + location
		   FROM #orders FOR XML PATH('') ),1,1, '')
		    ;


	--SELECT @collection, @Style_list, @location;

	INSERT INTO #ifp
	(
	    brand,
	    style,
	    vendor,
	    type_code,
	    gender,
	    material,
	    moq,
	    watch,
	    sf,
	    rel_date,
	    pom_date,
	    mth_since_rel,
	    s_sales_m1_3,
	    s_sales_m1_12,
	    s_e4_wu,
	    s_e12_wu,
	    s_e52_wu,
	    s_promo_w4,
	    s_promo_w12,
	    s_gross_w4,
	    s_gross_w12,
	    LINE_TYPE,
	    sku,
	    location,
	    mm,
	    p_rel_date,
	    p_pom_date,
	    lead_time,
	    bucket,
	    QOH,
	    atp,
	    reserve_qty,
	    quantity,
	    mult,
	    s_mult,
	    sort_seq,
	    alloc_qty,
	    non_alloc_qty,
	    pct_of_style,
	    pct_first_po,
	    pct_sales_style_m1_3,
	    p_e4_wu,
	    p_e12_wu,
	    p_e52_wu,
	    p_subs_w4,
	    p_subs_w12,
	    s_mth_usg,
	    p_mth_usg,
	    s_mth_usg_mult,
	    p_sales_m1_3,
	    p_po_qty_y1,
	    ORDER_THRU_DATE,
	    TIER,
	    p_type_code,
	    s_rx_w4,
	    s_rx_w12,
	    p_rx_w4,
	    p_rx_w12,
	    s_ret_w4,
	    s_ret_w12,
	    p_ret_w4,
	    p_ret_w12,
	    s_wty_w4,
	    s_wty_w12,
	    p_wty_w4,
	    p_wty_w12,
	    p_gross_w4,
	    p_gross_w12,
	    price,
	    frame_type
	)
    EXEC dbo.cvo_inv_fcst_r3_sp @asofdate = @asofdate,
                                @collection = @collection,
                                @Style = @Style_list,
                                @location = @location,
								@usg_option = 'o',
								@restype = 'frame,sun',						
                                @current = 0; -- show all;

    IF OBJECT_ID('tempdb..#subs') IS NOT NULL
        DROP TABLE #subs;

    SELECT DISTINCT
           ifp.brand,
           ifp.style,
           ia.category_5 color,
           ia.field_17 size,
           ifp.part_no sub_part_no,
           ifp.location,
           ifp.SOF qty_avl_to_sub
    INTO #subs
    FROM #orders O
        INNER JOIN
        (
        SELECT DISTINCT
               brand,
               style,
               location,
               sku AS part_no,
               atp,
               quantity AS SOF
        FROM #ifp
        WHERE LINE_TYPE = 'v'
              AND sort_seq = 4
              AND atp > 0
              AND quantity > 50
        ) AS ifp
            ON O.brand = ifp.brand
               AND O.style = ifp.style
               AND O.location = ifp.location
        INNER JOIN DBO.inv_master_add ia
            ON ia.part_no = ifp.part_no
    WHERE 1 = 1
          AND o.part_no <> ifp.part_no;

    -- select * from dpr_report where style = 'brynn'

    -- select * from #orders order by brand, style, part_no
    -- select * from #subs order by brand, style, sub_part_no

    DECLARE @loc VARCHAR(12),
            @brand VARCHAR(20),
            @style VARCHAR(20),
            @part VARCHAR(40),
            @qty_avl_to_sub INT,
            @open_qty INT,
            @qty_to_sub INT,
            @sub_part_no VARCHAR(40),
            @color VARCHAR(20),
            @size FLOAT,
            @id INT;

    SELECT @loc = MIN(location)
    FROM #orders;
    -- select @loc
    SELECT @part = MIN(part_no)
    FROM #orders
    WHERE location = @loc;
    SELECT @brand = brand,
           @style = style,
           @size = size,
           @color = color
    FROM #orders
    WHERE location = @loc
          AND part_no = @part;

    SELECT @id = MIN(id)
    FROM #orders
    WHERE @part = part_no
          AND @loc = location;

    -- check for a sub on size first
    SELECT @sub_part_no = '',
           @qty_avl_to_sub = 0;
    SELECT TOP (1)
           @sub_part_no = ISNULL(sub_part_no, ''),
           @qty_avl_to_sub = ISNULL(qty_avl_to_sub, 0)
    FROM #subs s
    WHERE s.location = @loc
          AND s.brand = @brand
          AND s.style = @style
          AND @color = color
          AND @size <> size
          AND s.sub_part_no <> @part
    ORDER BY qty_avl_to_sub DESC;
    -- check for a sub on color with same size
    IF @sub_part_no = ''
        SELECT TOP (1)
               @sub_part_no = ISNULL(sub_part_no, ''),
               @qty_avl_to_sub = ISNULL(qty_avl_to_sub, 0)
        FROM #subs
        WHERE location = @loc
              AND brand = @brand
              AND style = @style
              AND @color <> color
              AND @size = size
              AND sub_part_no <> @part
        ORDER BY qty_avl_to_sub DESC;
    -- check for a sub on anything within the style
    IF @sub_part_no = ''
        SELECT TOP 1
               @sub_part_no = ISNULL(sub_part_no, ''),
               @qty_avl_to_sub = ISNULL(qty_avl_to_sub, 0)
        FROM #subs
        WHERE location = @loc
              AND brand = @brand
              AND style = @style
              AND @color <> color
              AND @size <> size
              AND sub_part_no <> @part
        ORDER BY qty_avl_to_sub DESC;

    UPDATE o
    SET nextpoduedate =
        (
        SELECT TOP (1) NextPODueDate
        FROM dbo.cvo_item_avail_vw
        WHERE location = @loc
              AND part_no = @part
		ORDER BY location, Part_no
        ),
        sub_part_no = @sub_part_no,
        qty_avl_to_sub = @qty_avl_to_sub
		FROM #orders o
	    WHERE o.part_no = @part
          AND o.location = @loc;

    WHILE @loc IS NOT NULL
    BEGIN

        WHILE @part IS NOT NULL
        BEGIN

            WHILE @sub_part_no <> '' AND @qty_avl_to_sub > 0 AND @id IS NOT NULL
            BEGIN
                SELECT @open_qty = open_qty
                FROM #orders
                WHERE id = @id;
                SELECT @qty_to_sub
                    = CASE WHEN ISNULL(@qty_avl_to_sub, 0) >= @open_qty THEN @open_qty ELSE @qty_avl_to_sub END;
                UPDATE #orders
                SET #orders.qty_to_sub = @qty_to_sub,
                    #orders.qty_avl_to_sub = @qty_avl_to_sub
                WHERE id = @id;
                SELECT @qty_avl_to_sub = @qty_avl_to_sub - @qty_to_sub;
                SELECT @id = MIN(id)
                FROM #orders
                WHERE location = @loc
                      AND part_no = @part
                      AND id > @id;
            END; -- do we have anything to sub?

            UPDATE #subs
            SET qty_avl_to_sub = @qty_avl_to_sub
            WHERE sub_part_no = @sub_part_no
                  AND location = @loc;

            SELECT @part = MIN(part_no)
            FROM #orders
            WHERE location = @loc
                  AND part_no > @part;

            SELECT @brand = brand,
                   @style = style,
                   @size = size,
                   @color = color
            FROM #orders
            WHERE location = @loc
                  AND part_no = @part;
            SELECT @id = MIN(id)
            FROM #orders
            WHERE @part = part_no
                  AND @loc = location;
            -- check for a sub on size first
            SELECT @sub_part_no = '',
                   @qty_avl_to_sub = 0;
            SELECT TOP (1)
                   @sub_part_no = ISNULL(sub_part_no, ''),
                   @qty_avl_to_sub = ISNULL(qty_avl_to_sub, 0)
            FROM #subs
            WHERE location = @loc
                  AND brand = @brand
                  AND style = @style
                  AND @color = color
                  AND @size <> size
                  AND sub_part_no <> @part
            ORDER BY qty_avl_to_sub DESC;
            -- check for a sub on color with same size
            IF @sub_part_no = ''
                SELECT TOP (1)
                       @sub_part_no = ISNULL(sub_part_no, ''),
                       @qty_avl_to_sub = ISNULL(qty_avl_to_sub, 0)
                FROM #subs
                WHERE location = @loc
                      AND brand = @brand
                      AND style = @style
                      AND @color <> color
                      AND @size = size
                      AND sub_part_no <> @part
                ORDER BY qty_avl_to_sub DESC;
            -- check for a sub on anything within the style
            IF @sub_part_no = ''
                SELECT TOP (1)
                       @sub_part_no = ISNULL(sub_part_no, ''),
                       @qty_avl_to_sub = ISNULL(qty_avl_to_sub, 0)
                FROM #subs
                WHERE location = @loc
                      AND brand = @brand
                      AND style = @style
                      AND @color <> color
                      AND @size <> size
                      AND sub_part_no <> @part
                ORDER BY qty_avl_to_sub DESC;

            UPDATE o
            SET nextpoduedate =
                (
                SELECT TOP (1) NextPODueDate
                FROM dbo.cvo_item_avail_vw
                WHERE location = @loc
                      AND part_no = @part
					  ORDER BY location, part_no
                ),
                sub_part_no = @sub_part_no,
                qty_avl_to_sub = @qty_avl_to_sub
				FROM #orders o
            WHERE o.part_no = @part
                  AND o.location = @loc;


        END; -- part

        SELECT @loc = MIN(location)
        FROM #orders
        WHERE location > @loc;
        SELECT @part = MIN(part_no)
        FROM #orders
        WHERE location = @loc;
        SELECT @brand = brand,
               @style = style,
               @size = size,
               @color = color
        FROM #orders
        WHERE location = @loc
              AND part_no = @part;
        SELECT @sub_part_no = '',
               @qty_avl_to_sub = 0;
        SELECT @id = MIN(id)
        FROM #orders
        WHERE @part = part_no
              AND @loc = location;
        -- check for a sub on size first
        SELECT TOP (1)
               @sub_part_no = ISNULL(sub_part_no, ''),
               @qty_avl_to_sub = ISNULL(qty_avl_to_sub, 0)
        FROM #subs
        WHERE location = @loc
              AND brand = @brand
              AND style = @style
              AND @color = color
              AND @size <> size
              AND sub_part_no <> @part
        ORDER BY qty_avl_to_sub DESC;
        -- check for a sub on color with same size
        IF @sub_part_no = ''
            SELECT TOP (1)
                   @sub_part_no = ISNULL(sub_part_no, ''),
                   @qty_avl_to_sub = ISNULL(qty_avl_to_sub, 0)
            FROM #subs
            WHERE location = @loc
                  AND brand = @brand
                  AND style = @style
                  AND @color <> color
                  AND @size = size
                  AND sub_part_no <> @part
            ORDER BY qty_avl_to_sub DESC;
        -- check for a sub on anything within the style
        IF @sub_part_no = ''
            SELECT TOP (1)
                   @sub_part_no = ISNULL(sub_part_no, ''),
                   @qty_avl_to_sub = ISNULL(qty_avl_to_sub, 0)
            FROM #subs
            WHERE location = @loc
                  AND brand = @brand
                  AND style = @style
                  AND @color <> color
                  AND @size <> size
                  AND sub_part_no <> @part
            ORDER BY qty_avl_to_sub DESC;

        UPDATE o
        SET nextpoduedate =
            (
            SELECT TOP (1) NextPODueDate
            FROM dbo.cvo_item_avail_vw
            WHERE location = @loc
                  AND part_no = @part
            ),
            sub_part_no = @sub_part_no,
            qty_avl_to_sub = @qty_avl_to_sub
			FROM #orders o
        WHERE o.part_no = @part
              AND o.location = @loc;


    END; -- location


    --select #qty.*,#orders.order_no, #orders.ext, #orders.open_qty, #orders.qty_to_sub from #qty
    --join #orders on #qty.part_no = #orders.part_no and #qty.location = #orders.location

    SELECT brand,
           style,
           -- color_code, a_size, 
           part_no,
           type_code,
           order_no,
           ext,
           -- line_no, 
           user_category,
           date_entered,
           location,
           open_qty,
           sub_part_no,
           qty_to_sub,
           qty_avl_to_sub,
           ISNULL(nextpoduedate, '') nextpoduedate
    FROM #orders
    WHERE 1 = 1
    -- and qty_to_sub > 0 
    ORDER BY part_no,
             order_no;

END;




GO
GRANT EXECUTE ON  [dbo].[cvo_bo_to_subst_st] TO [public]
GO
