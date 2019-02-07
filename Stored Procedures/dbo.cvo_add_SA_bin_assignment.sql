SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[cvo_add_SA_bin_assignment]
(
    @part_no VARCHAR(40),
    @location VARCHAR(10) = '001',
    @bin_no VARCHAR(10) OUTPUT
)
AS

/*
DECLARE @bin_no VARCHAR(10)

EXECUTE cvo_add_sa_bin_assignment 'BCANOBLA5116', '001', @bin_no output
SELECT @bin_no

EXECUTE cvo_add_sa_bin_assignment 'BCCHFBER5314', '001', @bin_no output
SELECT @bin_no

EXECUTE cvo_add_sa_bin_assignment 'BCDYNWIN5416', '001', @bin_no output
SELECT @bin_no

EXECUTE cvo_add_sa_bin_assignment 'BCANOAUB5116', '001', @bin_no output
SELECT @bin_no

select * From tdc_bin_part_qty where part_no in ('BCANOBLA5116','BCCHFBER5314')

*/

BEGIN
    SET NOCOUNT ON;

    DECLARE
        --@part_no VARCHAR(40),
        --       @location VARCHAR(10),
        --        @bin_no VARCHAR(12),
        @fill_qty_max INT,
        @seq_no INT;


    -- 1)
    -- cleanup any empty assigned bins
    DELETE tbpq
    -- SELECT biv.*
    FROM dbo.cvo_bin_inquiry_vw AS biv
        JOIN dbo.tdc_bin_part_qty AS tbpq
            ON tbpq.bin_no = biv.bin_no
               AND tbpq.location = biv.location
               AND tbpq.part_no = biv.part_no
    WHERE biv.Is_Assigned = 'yes'
          AND biv.qty = 0
          AND biv.bin_no LIKE 'S____'
          AND biv.group_code = 'pickarea'
          AND biv.usage_type_code = 'open'
          AND biv.location = @location
          AND (EXISTS
    (
        SELECT 1
        FROM lot_bin_tran lb
        WHERE lb.part_no = biv.part_no
              AND lb.bin_no = biv.bin_no
              AND lb.location = biv.location
    )
              );

    -- 2)
    -- get the next available bin
    SELECT @bin_no = NULL;

    SELECT TOP (1)
           @bin_no = bin_no
    FROM dbo.cvo_whse_planning_vw AS wpv
    WHERE wpv.part_no = @part_no
          AND wpv.location = @location
          AND wpv.group_code = 'pickarea'
          AND wpv.usage_type_code = 'open'
          AND wpv.bin_no LIKE 'S____'
    ORDER BY wpv.bin_no;

    IF @bin_no IS NULL
    BEGIN
        SELECT TOP (1)
               @bin_no = bin_no
        FROM dbo.cvo_whse_planning_vw AS wpv
        WHERE wpv.bin_no LIKE 'S____'
              AND location = @location
              AND wpv.group_code = 'PICKAREA'
              AND wpv.usage_type_code = 'OPEN'
              AND Is_Assigned = 'Empty'
        ORDER BY wpv.bin_no;

        -- 3)
        -- create the assignment with minimal info
        IF @bin_no IS NOT NULL
        BEGIN

            SELECT @fill_qty_max = ISNULL(maximum_level, 10)
            FROM dbo.tdc_bin_master b (NOLOCK)
            WHERE b.location = @location
                  AND b.bin_no = @bin_no;
            SELECT @seq_no = MAX(ISNULL(seq_no, -1)) + 1
            FROM dbo.tdc_bin_part_qty AS tbpq (NOLOCK)
            WHERE location = @location
                  AND tbpq.bin_no = @bin_no
                  AND tbpq.part_no = @part_no;

            INSERT dbo.tdc_bin_part_qty
            (
                location,
                part_no,
                bin_no,
                qty,
                [primary],
                seq_no
            )
            VALUES
            (@location, @part_no, @bin_no, @fill_qty_max, 'N', ISNULL(@seq_no, 0));

        END;
    END;
    --INSERT dbo.tdc_bin_part_qty
    --(
    --    location,
    --    part_no,
    --    bin_no,
    --    qty,
    --    [primary],
    --    seq_no
    --)
    --SELECT wpv.location, wpv.part_no, wpv.bin_no, wpv.max_lvl, 'N', CASE WHEN maxs.max_seq IS NULL THEN 0 ELSE maxs.max_seq + 1 end
    --FROM dbo.cvo_whse_planning_vw AS wpv
    --LEFT OUTER JOIN
    --(SELECT tbpq.part_no, MAX(seq_no) max_seq FROM dbo.tdc_bin_part_qty AS tbpq WHERE location = '001'
    --GROUP BY part_no) maxs ON maxs.part_no = wpv.part_no
    --WHERE location = '001' AND wpv.group_code = 'pickarea' AND wpv.usage_type_code = 'open' AND bin_no LIKE 'S____'
    --AND qty <> 0 AND wpv.Is_Assigned = 'No'

    RETURN;

END;


GO
GRANT EXECUTE ON  [dbo].[cvo_add_SA_bin_assignment] TO [public]
GO
