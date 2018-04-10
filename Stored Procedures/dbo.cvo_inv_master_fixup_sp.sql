SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		elabarbera
-- Create date: 4/4/2013
-- Description:	inv_master nighly fixes & updates
-- EXEC cvo_inv_master_fixup_sp
-- =============================================

CREATE PROCEDURE [dbo].[cvo_inv_master_fixup_sp]
AS
BEGIN

    SET NOCOUNT ON;

    -- Update UPC codes into inv_master
    UPDATE inv_master
    SET upc_code = u.UPC
    FROM inv_master i
        JOIN uom_id_code u
            ON i.part_no = u.part_no
    WHERE i.upc_code <> u.UPC
          OR i.upc_code IS NULL;


    -- Inv Nightly update for setting BO based on POM
    UPDATE T1
    SET datetime_2 = DATEADD(DAY, 90, field_28), -- backorder date
        field_29 = DATEADD(DAY, 89, field_28)    -- cs_date per KM request 7/28/16
    FROM inv_master_add T1
    WHERE (
              datetime_2 IS NULL
              OR field_29 IS NULL
          )
          AND
          (
              field_28 IS NOT NULL
              AND field_28 <= GETDATE()
          ); -- dont mark future poms - 08/26/2016 tag

    UPDATE T1
    SET datetime_2 = NULL,
        field_29 = NULL
    FROM inv_master_add T1
    WHERE (
              datetime_2 IS NOT NULL
              OR field_29 IS NOT NULL
          )
          AND
          (
              field_28 IS NULL
              OR field_28 >= GETDATE()
          );

    --EL 7/15/2014 -- dont mark future poms - 082616 tag



    -- -- Nightly Process to check Discontinue and BackOrder Date
    -- First Pass check Backorder Date.  If it has passed, set obsolete flag
    UPDATE inv_master
    SET obsolete = 1
    FROM inv_master i,
         inv_master_add a
    WHERE i.part_no = a.part_no
          AND
          (
              a.datetime_2 <= GETDATE()
              AND i.obsolete = 0
          );

    UPDATE inv_master
    SET obsolete = 1
    FROM inv_master i,
         inv_master_add a
    WHERE i.part_no = a.part_no
          AND void = 'V'
          AND i.obsolete = 0; --EL 7/15/2014

    UPDATE inv_master
    SET obsolete = 0
    FROM inv_master i,
         inv_master_add a
    WHERE i.part_no = a.part_no
          AND
          (
              (
                  a.datetime_2 IS NULL
                  OR a.datetime_2 > GETDATE()
              )
              AND i.obsolete = 1
              AND void <> 'v'
          );

    --EL 7/15/2014

    -- Second Pass check Discontinue Date
    UPDATE inv_master
    SET non_sellable_flag = 'Y'
    FROM inv_master i,
         inv_master_add a
    WHERE i.part_no = a.part_no
          AND a.datetime_1 <= GETDATE()
          AND i.non_sellable_flag = 'N';

    -- TAG - 022414

    -- Remove unmatched part_no's from inv_master_add
    --DELETE  FROM inv_master_add
    --WHERE   part_no = ( SELECT  T1.part_no
    --                    FROM    inv_master_add T1
    --                            FULL OUTER JOIN inv_master T2 ON T1.part_no = T2.part_no
    --                    WHERE   T2.part_no IS NULL
    --                  );

    -- SELECT * 
    DELETE FROM dbo.inv_master_add
    WHERE NOT EXISTS
    (
        SELECT 1 FROM inv_master WHERE inv_master.part_no = inv_master_add.part_no
    );

    -- MAINTAIN CVO_INV_MASTER_ADD TABLE
    INSERT cvo_inv_master_add
    (
        part_no,
        prim_img
    )
    SELECT part_no,
           0 AS PRIM_IMG
    FROM inv_master I
    WHERE NOT EXISTS
    (
        SELECT 1 FROM cvo_inv_master_add WHERE part_no = I.part_no
    )
          AND type_code IN ( 'FRAME', 'SUN' );

    -- turn on web saleable for new items.

    UPDATE i
    SET i.web_saleable_flag = 'Y'
    -- select ia.field_26,  ia.field_28, i.web_saleable_flag, i.part_no , i.category, ia.field_2
    FROM inv_master i
        JOIN inv_master_add ia (NOLOCK)
            ON ia.part_no = i.part_no
    WHERE 1 = 1
          AND ISNULL(i.web_saleable_flag, 'N') = 'N'
          AND ia.field_26 <= GETDATE()
          AND ISNULL(ia.field_28, '1/1/1900') = '1/1/1900'
          AND ISNULL(ia.field_32, '') NOT IN ( 'retail', 'hvc', 'costco' )
          AND i.category <> 'bt'
          AND i.type_code IN ( 'frame', 'sun' )
          AND i.void = 'N'


    -- mark Red styles as not web saleable
    ;

    WITH c
    AS (SELECT part_no,
               dbo.f_cvo_get_part_tl_status(part_no, GETDATE()) ryg_stat
        FROM inv_master (NOLOCK)
        WHERE type_code IN ( 'frame', 'sun' ))
    UPDATE i
    SET web_saleable_flag = 'N'
    -- select i.category brand, ia.field_2 style, i.part_no, c.ryg_stat, i.web_saleable_flag
    FROM c
        JOIN inv_master i (ROWLOCK)
            ON c.part_no = i.part_no
        JOIN inv_master_add ia (NOLOCK)
            ON ia.part_no = i.part_no
               AND c.ryg_stat = 'R'
               AND ISNULL(web_saleable_flag, 'N') = 'Y';

    -- 1/29/2015 - tag turn off APR status if the release date has passed

    UPDATE inv_master_add WITH (ROWLOCK)
    SET field_35 = NULL
    -- select part_no, field_26 from inv_master_add
    WHERE ISNULL(field_35, '') IN ( 'yy', 'y' )
          AND ISNULL(field_26, GETDATE()) < GETDATE();

END;

-- 1/2018 - maintain cycle types in inv_master based on ABC classifications

UPDATE -- TOP (2500) 
    I
SET I.cycle_type = CASE
                       WHEN rank_class = 'A' THEN
                           'QTRLY'
                       WHEN RANK_CLASS = 'B' THEN
                           'BI-ANNUAL'
                       WHEN RANK_CLASS = 'C' THEN
                           'ANNUAL'
                       ELSE
                           'NEVER'
                   END

FROM inv_list (NOLOCK)
    JOIN inv_master I (ROWLOCK)
        ON I.part_no = inv_list.part_no
WHERE location = '001'
      AND I.cycle_type <> CASE
                       WHEN rank_class = 'A' THEN
                           'QTRLY'
                       WHEN RANK_CLASS = 'B' THEN
                           'BI-ANNUAL'
                       WHEN RANK_CLASS = 'C' THEN
                           'ANNUAL'
                       ELSE
                           'NEVER'
                          END;
GO
GRANT EXECUTE ON  [dbo].[cvo_inv_master_fixup_sp] TO [public]
GO
