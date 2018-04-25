SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[cvo_inv_subs_refresh_sp]
AS
BEGIN

    SET NOCOUNT ON;

    IF
    (
    SELECT COUNT(*) FROM dbo.inv_substitutes AS isu
    ) > 0
        TRUNCATE TABLE dbo.inv_substitutes;


    WITH skus
    AS
    (
    SELECT DISTINCT
           i.part_no,
           i.category brand,
           ia.field_2 model,
           i.type_code,
           ia.category_2 primarydemo,
           ia.category_5 colorgroupcode,
           ia.field_17 eye_size
    FROM inv_master i
        (NOLOCK)
        JOIN inv_master_add ia
        (NOLOCK)
            ON ia.part_no = i.part_no
        LEFT OUTER JOIN
        (
        SELECT DISTINCT
               part_no
        FROM dbo.cvo_part_attributes AS pa
        WHERE pa.attribute NOT IN ( 'hvc', 'specialord', 'retail' )
        ) pa
            ON pa.part_no = i.part_no
    WHERE i.type_code IN ( 'frame', 'sun' )
          AND i.void = 'n'
          AND ia.field_26 <= GETDATE()
    --      AND NOT EXISTS
    --(
    --SELECT 1
    --FROM dbo.cvo_part_attributes AS pa
    --WHERE pa.part_no = i.part_no
    --      AND pa.attribute IN ( 'hvc', 'specialord', 'retail' )
    --)
    )
    INSERT dbo.inv_substitutes
    (
        part_no,
        customer_key,
        sub_part,
        priority
    )
    SELECT subs_list.part_no,
           subs_list.cust_key,
           subs_list.sub_part_no,
           MIN(subs_list.match_level) match_level
    FROM
    (
    -- match1
    SELECT skus.part_no,
           'ALL' cust_key,
           subs.part_no sub_part_no,
           1 match_level
    FROM skus
        JOIN skus subs
            ON subs.brand = skus.brand
               AND subs.model = skus.model
               AND subs.eye_size = skus.eye_size
               AND subs.type_code = skus.type_code
               AND subs.primarydemo = skus.primarydemo
    WHERE subs.part_no <> skus.part_no
          AND subs.colorgroupcode <> skus.colorgroupcode
    UNION ALL
    -- match2
    SELECT skus.part_no,
           'ALL' cust_key,
           subs.part_no sub_part_no,
           2 match_level
    FROM skus
        JOIN skus subs
            ON subs.brand = skus.brand
               AND subs.model = skus.model
               AND subs.colorgroupcode = skus.colorgroupcode
               AND subs.type_code = skus.type_code
               AND subs.primarydemo = skus.primarydemo
    WHERE subs.part_no <> skus.part_no
          AND subs.eye_size <> skus.eye_size
    UNION ALL
    -- match3
    SELECT skus.part_no,
           'ALL' cust_key,
           subs.part_no sub_part_no,
           3 match_level
    FROM skus
        JOIN skus subs
            ON subs.brand = skus.brand
               AND subs.colorgroupcode = skus.colorgroupcode
               AND subs.eye_size = skus.eye_size
               AND subs.type_code = skus.type_code
               AND subs.primarydemo = skus.primarydemo
    WHERE subs.part_no <> skus.part_no
          AND subs.model <> skus.model
    UNION ALL
    -- match4
    SELECT skus.part_no,
           'ALL' cust_key,
           subs.part_no sub_part_no,
           4 match_level
    FROM skus
        JOIN skus subs
            ON subs.brand = skus.brand
               AND subs.colorgroupcode = skus.colorgroupcode
               AND subs.type_code = skus.type_code
               AND subs.primarydemo = skus.primarydemo
    WHERE subs.part_no <> skus.part_no
          AND subs.eye_size <> skus.eye_size
          AND subs.model <> skus.model
    UNION ALL
    -- match5
    SELECT skus.part_no,
           'ALL' cust_key,
           subs.part_no sub_part_no,
           5 match_level
    FROM skus
        JOIN skus subs
            ON subs.brand = skus.brand
               AND subs.eye_size = skus.eye_size
               AND subs.type_code = skus.type_code
               AND subs.primarydemo = skus.primarydemo
    WHERE subs.part_no <> skus.part_no
          AND subs.model <> skus.model
          AND subs.colorgroupcode <> skus.colorgroupcode
    ) subs_list
    GROUP BY subs_list.part_no,
             subs_list.cust_key,
             subs_list.sub_part_no;



-- SELECT count(*) FROM dbo.inv_substitutes AS isu
-- TRUNCATE TABLE dbo.inv_substitutes

END;

GRANT EXECUTE ON dbo.cvo_inv_subs_refresh_sp TO PUBLIC;

GO
