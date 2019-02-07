SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [dbo].[cvo_rr_putaway_and_refurb_vw] AS 
SELECT lb.location,
       lb.part_no,
       lb.bin_no,
       lb.date_tran,
       lb.qty,
       wpv.bin_no primary_bin_no
FROM lot_bin_stock lb (nolock)
    LEFT OUTER JOIN dbo.cvo_whse_planning_vw AS wpv
        ON wpv.part_no = lb.part_no
           AND wpv.location = lb.location
WHERE lb.location = '001'
      AND lb.bin_no IN ( 'rr putaway', 'rr refurb' )
      AND wpv.primary_bin = 'y'
      AND wpv.group_code = 'pickarea';

GO
GRANT SELECT ON  [dbo].[cvo_rr_putaway_and_refurb_vw] TO [public]
GO
