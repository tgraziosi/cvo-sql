SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[cvo_spv_list_sp] @update SMALLINT = NULL
AS

-- exec cvo_spv_list_sp 1

BEGIN

    SET NOCOUNT ON
    SET ANSI_WARNINGS OFF
    
    -- Figure out Special Values List

    IF (OBJECT_ID('tempdb..#avl') IS NOT NULL)
        DROP TABLE #avl;

    IF (OBJECT_ID('tempdb..#spv') IS NOT NULL)
        DROP TABLE #spv;

    IF (OBJECT_ID('tempdb..#usg') IS NOT NULL)
        DROP TABLE #usg;

    CREATE TABLE #spv
    (
        [Brand] VARCHAR(10),
        [Style] VARCHAR(40),
        [Color_desc] VARCHAR(40),
        [eye_size] DECIMAL(20, 8),
        [part_no] VARCHAR(30),
        [qty_avl] DECIMAL(38, 8),
        [POM_date] DATETIME,
        [mth_usage] INT
    );


    IF @update IS NULL
        SELECT @update = 0;

    SELECT part_no,
           e12_wu * 52 / 12 mth_usage
    INTO #usg
    FROM dbo.f_cvo_calc_weekly_usage_loc('O', 'T', 'frame', '001');


    SELECT iav.Brand,
           iav.Style,
           iav.Color_desc,
           ia.field_17 eye_size,
           iav.part_no,
           iav.qty_avl,
           iav.POM_date,
           ISNULL(   CASE
                         WHEN POM_date > GETDATE() THEN
                             ISNULL(u.mth_usage, 0)
                         ELSE
                             0
                     END,
                     0
                 ) mth_usage
    INTO #avl
    FROM dbo.cvo_item_avail_vw AS iav
        JOIN dbo.inv_master_add ia
            ON ia.part_no = iav.part_no
        LEFT OUTER JOIN #usg u
            ON u.part_no = iav.part_no
    WHERE iav.location = '001'
          -- AND iav.qty_avl >= 50
          AND iav.ResType IN ( 'frame' )
          AND iav.Brand NOT IN ( 'jc', 'rr', 'pt', 'izx', 'dh', 'ko', 'di' )
          AND iav.POM_date IS NOT NULL;

    WITH sizes
    AS (SELECT Brand,
               Style,
               COUNT(DISTINCT Color_desc) num_color,
               COUNT(DISTINCT eye_size) num_size
        FROM #avl
        GROUP BY Brand,
                 Style),
         num_sizes_per_color
    AS (SELECT a.Brand,
               a.Style,
               a.Color_desc,
               COUNT(a.eye_size) num_sizes_avl
        FROM #avl AS a
        WHERE a.qty_avl >= 50 + a.mth_usage
        GROUP BY a.Brand,
                 a.Style,
                 a.Color_desc),
         num_colors_per_size
    AS (SELECT a.Brand,
               a.Style,
               a.eye_size,
               COUNT(a.Color_desc) num_colors_avl
        FROM #avl AS a
        WHERE a.qty_avl >= 50 + a.mth_usage
        GROUP BY a.Brand,
                 a.Style,
                 a.eye_size),
         almost_done
    AS (SELECT avl.Brand,
               avl.Style,
               avl.Color_desc,
               avl.eye_size,
               avl.part_no,
               avl.qty_avl,
               avl.POM_date,
               avl.mth_usage
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
        WHERE avl.qty_avl >= 50 + avl.mth_usage
              AND num_sizes_avl >= sizes.num_size
              AND nc.num_colors_avl >= 2)
    INSERT INTO #spv
    SELECT almost_done.Brand,
           almost_done.Style,
           almost_done.Color_desc,
           almost_done.eye_size,
           almost_done.part_no,
           almost_done.qty_avl,
           almost_done.POM_date,
           almost_done.mth_usage
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


    SELECT s.Brand,
           s.Style,
           s.Color_desc,
           s.eye_size,
           s.part_no,
           s.qty_avl,
           s.POM_date,
           s.mth_usage
    FROM #spv AS s
    ORDER BY s.Brand,
             s.Style,
             s.eye_size,
             s.Color_desc;

    IF @update = 1
    BEGIN

        -- Maintain SV attribute for Special Values List
        -- 02/12/2019

        DELETE FROM dbo.cvo_part_attributes
        WHERE attribute = 'SPV';

        UPDATE ia
        SET ia.field_32 = NULL
        -- SELECT * 
        FROM inv_master_add ia
        WHERE ia.field_32 = 'SPV';

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
