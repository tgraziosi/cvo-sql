SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[cvo_scm_pb_get_dw_oe_releases]  @order_no int 
AS
BEGIN

	SELECT	ord_list.order_no,   
			ord_list.order_ext,   
			ord_list.line_no,   
			ord_list.location,   
			ord_list.part_no,   
			ord_list.description,   
			ord_list.time_entered,   
			ord_list.ordered,   
			ord_list.shipped,   
			ord_list.price,   
			ord_list.price_type,   
			ord_list.note,   
			ord_list.status,   
			ord_list.cost,   
			ord_list.who_entered,   
			ord_list.sales_comm,   
			ord_list.temp_price,   
			ord_list.temp_type,   
			ord_list.cr_ordered,   
			ord_list.cr_shipped,   
			ord_list.discount,   
			ord_list.uom,   
			ord_list.conv_factor,   
			ord_list.void,   
			ord_list.void_who,   
			ord_list.void_date,   
			ord_list.std_cost,   
			ord_list.cubic_feet,   
			ord_list.printed,   
			ord_list.lb_tracking,   
			ord_list.labor,   
			ord_list.direct_dolrs,   
			ord_list.ovhd_dolrs,   
			ord_list.util_dolrs,   
			ord_list.taxable,   
			ord_list.weight_ea,   
			orders.sch_ship_date,   
			orders.status,   
			orders.date_shipped,   
			dbo.orders.sch_ship_date c_date,   
			inv_master.allow_fractions,   
			ord_list.qc_flag,   
			ord_list.reason_code,   
			ord_list.qc_no,   
			ord_list.rejected,   
			ord_list.part_type,   
			ord_list.orig_part_no,   
			ord_list.back_ord_flag,   
			ord_list.gl_rev_acct,   
			ord_list.total_tax,   
			ord_list.tax_code,   
			ord_list.curr_price,   
			ord_list.oper_price,   
			ord_list.display_line,   
			ord_list.std_direct_dolrs,   
			ord_list.std_ovhd_dolrs,   
			ord_list.std_util_dolrs,   
			ord_list.reference_code,   
			ord_list.contract,   
			space(100) _curr_mask,   
			dbo.ord_list.line_no*0 _curr_precision,   
			inv_master.lb_tracking,   
			ord_list.service_agreement_flag,   
			ord_list.create_po_flag,   
			dbo.ord_list.ordered * 0 tot_ordered  ,
			ord_list.organization_id
	FROM	ord_list LEFT OUTER JOIN inv_master ON ord_list.part_no = inv_master.part_no,   
			orders  
	WHERE	( ord_list.order_no = orders.order_no ) and  
			( ord_list.order_ext = orders.ext ) and  
			( ( dbo.ord_list.order_no = @order_no ) AND  
			( dbo.ord_list.order_ext > 0 ) )   
	ORDER BY ord_list.line_no ASC 

END
GO
GRANT EXECUTE ON  [dbo].[cvo_scm_pb_get_dw_oe_releases] TO [public]
GO
