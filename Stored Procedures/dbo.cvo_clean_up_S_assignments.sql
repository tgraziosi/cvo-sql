SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[cvo_clean_up_S_assignments]
AS 
BEGIN
SET NOCOUNT ON

-- Clean up empty bins in S____ inventory area in mezzanine

DECLARE @location VARCHAR(10)
SELECT  @location = '001'

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
    --      AND (EXISTS
    --(
    --    SELECT 1
    --    FROM lot_bin_tran lb
    --    WHERE lb.part_no = biv.part_no
    --          AND lb.bin_no = biv.bin_no
    --          AND lb.location = biv.location
    --)
    --          )
    ;

    END
    
GO
GRANT EXECUTE ON  [dbo].[cvo_clean_up_S_assignments] TO [public]
GO
