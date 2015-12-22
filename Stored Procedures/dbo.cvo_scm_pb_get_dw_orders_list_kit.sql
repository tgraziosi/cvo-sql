SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[cvo_scm_pb_get_dw_orders_list_kit]	@order_no int, 
													@order_ext int 
AS
BEGIN

	SELECT	ord_list_kit.order_no,   
			ord_list_kit.order_ext,   
			ord_list_kit.line_no,   
			ord_list_kit.location,   
			ord_list_kit.part_no,   
			ord_list_kit.ordered,   
			ord_list_kit.shipped,   
			ord_list_kit.status,   
			ord_list_kit.lb_tracking,   
			ord_list_kit.cr_ordered,   
			ord_list_kit.cr_shipped,   
			ord_list_kit.uom,   
			ord_list_kit.conv_factor,   
			ord_list_kit.qty_per,   
			ord_list_kit.cost,   
			ord_list_kit.labor,   
			ord_list_kit.direct_dolrs,   
			ord_list_kit.ovhd_dolrs,   
			ord_list_kit.util_dolrs,   
			ord_list_kit.note,   
			ord_list_kit.row_id,   
			ord_list_kit.part_type,   
			ord_list_kit.qc_flag,   
			ord_list_kit.qc_no,   
			ord_list_kit.description,   
			inv_master.serial_flag  ,
			isnull(inv_master.weight_ea,0) weight_ea,
			0	_replace,
			cvo_ord_list_kit.order_no,
			cvo_ord_list_kit.order_ext,
			cvo_ord_list_kit.line_no,
			cvo_ord_list_kit.location,
			cvo_ord_list_kit.part_no,
			cvo_ord_list_kit.replaced,
			cvo_ord_list_kit.new1,
			cvo_ord_list_kit.part_no_original,
			NULL _inhouse_date
    FROM ord_list_kit 
	LEFT OUTER JOIN inv_master ON ord_list_kit.part_no = inv_master.part_no  
	LEFT OUTER JOIN	cvo_ord_list_kit ON ord_list_kit.order_no = cvo_ord_list_kit.order_no 
	AND		ord_list_kit.order_ext = cvo_ord_list_kit.order_ext 
	AND		ord_list_kit.line_no = cvo_ord_list_kit.line_no 
	AND		ord_list_kit.location = cvo_ord_list_kit.location 
	AND		ord_list_kit.part_no = cvo_ord_list_kit.part_no
	WHERE ( dbo.ord_list_kit.order_no = @order_no ) 
	AND   ( dbo.ord_list_kit.order_ext = @order_ext )   
ORDER BY ord_list_kit.row_id ASC   
  
END
GO
GRANT EXECUTE ON  [dbo].[cvo_scm_pb_get_dw_orders_list_kit] TO [public]
GO
