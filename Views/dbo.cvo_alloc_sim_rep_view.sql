SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[cvo_alloc_sim_rep_view]
AS
	SELECT	user_spid, 0 rep_seq, 0 order_no, 0 order_ext, '' order_no_ext, '' cust_code, '' cust_name, '' ship_date, '' order_type,
			0 so_priority, '' cust_type, '' promotion, '' part_no, SUM(alloc_qty) qty, '' bin_no, '' bin_type
	FROM	cvo_allocation_simulation_summary_hdr
	GROUP BY user_spid
	UNION ALL
	SELECT	user_spid, 1 rep_seq, 0 order_no, 0 order_ext, '' order_no_ext, '' cust_code, '' cust_name, '' ship_date, '' order_type,
			0 so_priority, '' cust_type, '' promotion, '' part_no, alloc_qty qty, '' bin_no, bin_group bin_type
	FROM	cvo_allocation_simulation_summary_hdr
	UNION ALL
	SELECT	user_spid, 2 rep_seq, 0 order_no, 0 order_ext, '' order_no_ext, '' cust_code, '' cust_name, '' ship_date, '' order_type,
			0 so_priority, '' cust_type, '' promotion, part_no, alloc_qty qty, bin_no, bin_group bin_type
	FROM	cvo_allocation_simulation_summary_det
	UNION ALL
	SELECT	user_spid, 3 rep_seq, order_no, order_ext, order_no_ext, cust_code, cust_name, ship_date, order_type,
			so_priority, cust_type, promotion, part_no, qty, bin_no, bin_type
	FROM	cvo_allocation_simulation_detail

GO
GRANT SELECT ON  [dbo].[cvo_alloc_sim_rep_view] TO [public]
GO
