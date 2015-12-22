SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[fs_phy_report] @phy_id int AS 


BEGIN

SELECT 		p.location, 
		p.part_no, 
		lbp.bin_no, 
		lbp.lot_ser,
		case when lbp.part_no is NULL then p.qty else lbp.qty_physical end,	-- mls 10/2/01 SCR 27688
		case when lbp.part_no is NULL then p.orig_qty else lbp.qty end,	-- mls 10/2/01 SCR 27688
		i.description, 
		p.phy_batch, 
		p.phy_no		
FROM physical p
join inv_master i (nolock) on p.part_no = i.part_no
left outer join lot_bin_phy lbp (nolock) on p.part_no = lbp.part_no and 
  p.phy_no = lbp.phy_no and p.phy_batch = lbp.phy_batch and p.location = lbp.location 
WHERE p.phy_batch = @phy_id AND 
		p.qty <> p.orig_qty
ORDER BY p.location, p.part_no, p.phy_no


END
GO
GRANT EXECUTE ON  [dbo].[fs_phy_report] TO [public]
GO
