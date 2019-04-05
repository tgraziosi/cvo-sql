SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[cvo_spv_list_sp] @update SMALLINT = NULL
AS

-- exec cvo_spv_list_sp 0

BEGIN


    --DECLARE @update SMALLINT;
    --SELECT @update = 0;

    SET NOCOUNT ON;
    SET ANSI_WARNINGS OFF;

    -- Figure out Special Values List

    DECLARE @today DATETIME,
            @asofdate DATETIME;
    SELECT @today = DATEADD(dd, DATEDIFF(dd, 0, GETDATE()), 0);
    SELECT @asofdate = DATEADD(mm, DATEDIFF(mm, 0, GETDATE()), 0);

    DECLARE @location VARCHAR(10),
            @collection VARCHAR(1000),
            @Style_list VARCHAR(8000);

    IF (OBJECT_ID('tempdb..#avl') IS NOT NULL)
        DROP TABLE #avl;

    IF (OBJECT_ID('tempdb..#spv') IS NOT NULL)
        DROP TABLE #spv;

    IF (OBJECT_ID('tempdb..#ifp') IS NOT NULL)
        DROP TABLE #ifp;
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
        frame_type VARCHAR(40),
        last_order_date DATETIME
    );



    CREATE TABLE #spv
    (
        [Brand] VARCHAR(10),
        [Style] VARCHAR(40),
        [Color_desc] VARCHAR(40),
        [eye_size] DECIMAL(20, 8),
        [part_no] VARCHAR(30),
        [qty_avl] DECIMAL(38, 8),
        [POM_date] DATETIME,
        pom_inv_qty INT,
        num_color int,
        num_color_avl INT,
        num_size int,
        num_sizes_avl int
    );


    IF @update IS NULL
        SELECT @update = 0;


    SELECT iav.Brand,
           iav.Style,
           iav.Color_desc,
           ia.field_17 eye_size,
           iav.part_no,
           iav.qty_avl,
           iav.POM_date,
           0 pom_inv_qty
    INTO #avl
    FROM dbo.cvo_item_avail_vw AS iav
        JOIN dbo.inv_master_add ia
            ON ia.part_no = iav.part_no
    WHERE iav.location = '001'
          -- AND iav.qty_avl >= 50
          AND iav.ResType IN ( 'frame' )
          AND iav.Brand NOT IN ( 'jc', 'rr', 'pt', 'izx', 'dh', 'ko', 'di' )
          AND iav.POM_date < DATEADD(mm,11,@asofdate);

    -- run ifps for future pom items and get the enting inventorty in the month after POM month.  must be > 50


    SELECT @collection = '',
           @Style_list = '',
           @location = '';

    SELECT @collection = STUFF(
                         (
                             SELECT DISTINCT
                                    ',' + Brand
                             FROM #avl
                             WHERE POM_date > @today
                             FOR XML PATH('')
                         ),
                         1,
                         1,
                         ''
                              ),
           @Style_list = STUFF(
                         (
                             SELECT DISTINCT
                                    ',' + Style
                             FROM #avl
                             WHERE POM_date > @today
                             FOR XML PATH('')
                         ),
                         1,
                         1,
                         ''
                              ),
           @location = '001';


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
        frame_type,
        last_order_date
    )
    EXEC dbo.cvo_inv_fcst_r3_sp @asofdate = @asofdate,
                                @collection = @collection,
                                @Style = @Style_list,
                                @location = @location,
                                @usg_option = 'o',
                                @ResType = 'frame,sun',
                                @current = 1; -- show all;  

    UPDATE a
    SET a.pom_inv_qty = ifp.quantity
    FROM #avl a
        JOIN #ifp ifp
            ON ifp.sku = a.part_no
    WHERE LINE_TYPE = 'V'
          AND MONTH(bucket) = MONTH(DATEADD(MONTH, 1, ISNULL(ifp.p_pom_date, ifp.pom_date)))
          AND bucket >= ISNULL(ifp.p_pom_date, ifp.pom_date);

    WITH sizes
    AS (SELECT Brand,
               Style,
               COUNT(DISTINCT Color_desc) num_color,
               COUNT(DISTINCT eye_size) num_size
        FROM #avl
        GROUP BY Brand,
                 Style),
             num_colors_per_size
    AS (SELECT a.Brand,
               a.Style,
               a.eye_size,
               COUNT(a.Color_desc) num_colors_avl
        FROM #avl AS a
        WHERE a.qty_avl >= 50
              AND CASE
                      WHEN a.POM_date > @today THEN
                          a.pom_inv_qty
                      ELSE
                          50
                  END >= 50
        GROUP BY a.Brand,
                 a.Style,
                 a.eye_size),

         num_sizes_per_color
    AS (SELECT a.Brand,
               a.Style,
               a.Color_desc,
               COUNT(a.eye_size) num_sizes_avl
        FROM #avl AS a
        JOIN num_colors_per_size nc ON nc.Brand = a.Brand AND nc.Style = a.Style AND nc.eye_size = a.eye_size
        WHERE nc.num_colors_avl >= 2
              AND a.qty_avl >= 50
              AND CASE
                      WHEN a.POM_date > @today THEN
                          a.pom_inv_qty
                      ELSE
                          50
                  END >= 50
        GROUP BY a.Brand,
                 a.Style,
                 a.Color_desc),

         almost_done
    AS (SELECT avl.Brand,
               avl.Style,
               avl.Color_desc,
               avl.eye_size,
               avl.part_no,
               avl.qty_avl,
               avl.POM_date,
               avl.pom_inv_qty,
               sizes.num_color,
               nc.num_colors_avl,
               sizes.num_size,
               ns.num_sizes_avl
   
        FROM #avl avl
            LEFT OUTER JOIN sizes
                ON sizes.Brand = avl.Brand
                   AND avl.Style = sizes.Style
            LEFT OUTER JOIN num_sizes_per_color ns
                ON ns.Brand = avl.Brand
                   AND ns.Style = avl.Style
                   AND ns.Color_desc = avl.Color_desc
            LEFT OUTER JOIN num_colors_per_size nc
                ON nc.Brand = avl.Brand
                   AND nc.Style = avl.Style
                   AND nc.eye_size = avl.eye_size
        WHERE avl.qty_avl >= 50
              AND CASE
                      WHEN avl.POM_date > @today THEN
                          avl.pom_inv_qty
                      ELSE
                          50
                  END >= 50
              AND ns.num_sizes_avl >= CASE WHEN sizes.num_size = 1 THEN 1 ELSE 2 END 
              AND nc.num_colors_avl >= 2)
    --SELECT *
    --FROM almost_done;

    INSERT INTO #spv
    SELECT almost_done.Brand,
           almost_done.Style,
           almost_done.Color_desc,
           almost_done.eye_size,
           almost_done.part_no,
           almost_done.qty_avl,
           almost_done.POM_date,
           almost_done.pom_inv_qty,
           num_color,
           num_colors_avl,
           num_size,
           num_sizes_avl
    FROM almost_done
        JOIN
        (
            SELECT Brand,
                   Style,
                   eye_size,
                   COUNT(part_no) num_part
            FROM almost_done
            GROUP BY Brand,
                     Style,
                     eye_size
            HAVING COUNT(part_no) > 1
        ) xx
            ON xx.Brand = almost_done.Brand
               AND xx.Style = almost_done.Style
               AND xx.eye_size = almost_done.eye_size;


SELECT avl.*,
       CASE
           WHEN spv.part_no IS NOT NULL THEN
               'Yes'
           ELSE
               NULL
       END spv,
       spv.num_color,
       spv.num_color_avl,
       spv.num_size,
       spv.num_sizes_avl
FROM #avl avl
    LEFT OUTER JOIN #spv spv
        ON spv.part_no = avl.part_no
ORDER BY avl.Brand,
         avl.Style,
         avl.eye_size,
         avl.Color_desc;

    IF @update = 1
    BEGIN

        -- Maintain SV attribute for Special Values List
        -- 02/12/2019

        DELETE FROM dbo.cvo_part_attributes
        WHERE attribute IN ( 'SPV', 'QOP', 'EOR' );

        UPDATE ia
        SET ia.field_32 = NULL
        -- SELECT * 
        FROM inv_master_add ia
        WHERE ia.field_32 IN ( 'SPV', 'QOP', 'EOR' );

        INSERT dbo.cvo_part_attributes
        (
            part_no,
            attribute
        )
        SELECT ia.part_no,
               'SPV'
        FROM inv_master_add ia
            JOIN #spv spv
                ON spv.part_no = ia.part_no
        WHERE NOT EXISTS
        (
            SELECT 1
            FROM cvo_part_attributes p
            WHERE p.part_no = ia.part_no
                  AND p.attribute IN ( 'SPV' )
        );

        INSERT dbo.cvo_part_attributes
        (
            part_no,
            attribute
        )
        SELECT avl.part_no,
               CASE
                   WHEN DATEDIFF(m, ISNULL(avl.POM_date, @today), @today) >= 24 THEN
                       'EOR'
                   ELSE
                       'QOP'
               END
        FROM #avl avl
            LEFT OUTER JOIN #spv spv
                ON spv.part_no = avl.part_no
        WHERE DATEDIFF(m, ISNULL(avl.POM_date, @today), @today) >= 9
              AND avl.Brand <> 'AS'
              AND spv.part_no IS NULL;

        UPDATE ia
        SET ia.field_32 = pa.attribute
        -- SELECT ia.part_no, field_32, pa.attribute , ia.field_26, ia.field_28
        FROM inv_master_add ia
            JOIN dbo.cvo_part_attributes AS pa
                ON pa.part_no = ia.part_no
        WHERE ia.field_32 IS NULL;

        UPDATE ia
        SET ia.field_32 = '[MULTIPLE]'
        -- SELECT ia.part_no, field_32, pa.attribute, ia.field_2  
        FROM dbo.inv_master_add ia
            JOIN dbo.cvo_part_attributes AS pa
                ON pa.part_no = ia.part_no
        WHERE ia.field_32 <> pa.attribute
              AND ia.field_32 <> '[MULTIPLE]'
              AND ia.field_32 IS NOT NULL
              AND
              (
                  SELECT COUNT(*)
                  FROM dbo.cvo_part_attributes AS pa2
                  WHERE pa2.part_no = ia.part_no
              ) > 1;

    END;
-- SELECT * FROM #avl WHERE style = 'ELODIE'
END;



GO
GRANT EXECUTE ON  [dbo].[cvo_spv_list_sp] TO [public]
GO
