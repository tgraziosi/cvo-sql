SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[f_get_excluded_bins_1_vw]
AS

	SELECT	
		a.location location,
		a.part_no part_no, 
		NULL bins, 
		SUM(a.qty) - ISNULL(SUM(b.qty),0.0) qty
	FROM	
		dbo.cvo_lot_bin_stock_exclusions a (NOLOCK)
	LEFT JOIN (SELECT SUM(qty) qty, location, part_no, bin_no FROM tdc_soft_alloc_tbl (NOLOCK) GROUP BY location, part_no, bin_no) b 
	ON	a.location = b.location
	AND	a.bin_no = b.bin_no
	AND	a.part_no = b.part_no
	GROUP BY 
		a.location,
		a.part_no
GO
GRANT REFERENCES ON  [dbo].[f_get_excluded_bins_1_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[f_get_excluded_bins_1_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[f_get_excluded_bins_1_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[f_get_excluded_bins_1_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[f_get_excluded_bins_1_vw] TO [public]
GO
