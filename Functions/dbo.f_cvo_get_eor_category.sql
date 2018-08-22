SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE FUNCTION [dbo].[f_cvo_get_eor_category]
    (
        @part_no VARCHAR(30)
    )
RETURNS VARCHAR(10)
-- EORS, EOR, RED, QOP, <blank>
AS
    BEGIN
        -- select dbo.f_cvo_get_eor_category('ASMEMBLA5116')
        DECLARE
            @today   DATETIME,
            @eor_cat VARCHAR(10);
        SELECT
            @today = DATEADD(dd, DATEDIFF(dd, 0, GETDATE()), 0);
        ;WITH eor
        AS (   SELECT
                       i.part_no,
                       i.description,
                       ia.field_28,
                       i.type_code,
                       CASE
                           WHEN i.type_code = 'SUN'
                                AND ISNULL(ia.field_28, @today) < @today
                                AND ISNULL(ia.field_36, '') <> 'sunps'
                                AND i.category <> 'REVO' -- 5/4/2017 - SHOW ALL REVOS
                                AND NOT EXISTS
                                            ( -- dont inlucde item on the sun specials selldown list - 
                                                SELECT
                                                    1
                                                FROM
                                                    dbo.cvo_eos_tbl AS EOS
                                                WHERE
                                                    EOS.part_no = i.part_no
                                                    AND EOS.obs_date IS NULL
                                            )
                               THEN
                               'EORS'
                           WHEN dbo.f_cvo_get_part_tl_status(i.part_no, @today) = 'R'
                                AND DATEDIFF(m, ISNULL(ia.field_28, @today), @today) < 9
                               THEN
                               'RED'
                           WHEN DATEDIFF(m, ISNULL(ia.field_28, @today), @today) >= 24
                                AND i.type_code <> 'SUN'
                               THEN
                               'EOR'
                           WHEN DATEDIFF(m, ISNULL(ia.field_28, @today), @today) >= 9
                                AND i.type_code <> 'SUN'
                               THEN
                               'QOP'
                           ELSE
                               i.type_code
                       END AS eor_category
               FROM
                       inv_master     i (NOLOCK)
                   JOIN
                       inv_master_add ia (NOLOCK)
                           ON ia.part_no = i.part_no
               WHERE
                       i.type_code IN (
                                          'frame', 'sun'
                                      )
                       AND ISNULL(ia.field_28, @today) < @today)
        SELECT
            @eor_cat = ISNULL(eor.eor_category, '')
        FROM
            eor
        WHERE
            eor.type_code <> eor.eor_category
            AND eor.part_no = @part_no;
        RETURN ISNULL(@eor_cat, '');
    END;
GO
