SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[tdc_get_mfg_pick_tkt_detl_sp]
	@intProd_No	INTEGER ,
	@intProd_Ext	INTEGER
AS

--DMcMinoway  1/13/00
--We want the info from the prod_list , lot_bin_prod ,  inv_master

SELECT	 prod_list.line_no	,	 	prod_list.seq_no,
	 prod_list.part_no	, 		inv_master.[description], 
	prod_list.uom	, 		prod_list.plan_qty, 
    	prod_list.used_qty, 		lot_bin_prod.lot_ser, 
	lot_bin_prod.bin_no, 		inv_master.note, 
	prod_list.note AS comment,  	tdc_bin_master.group_code, 
	tdc_bin_master.group_code_id, 	tdc_bin_master.seq_no AS Expr1, 
    	tdc_bin_master.bin_no AS Expr2
FROM tdc_bin_master RIGHT OUTER JOIN
   	 lot_bin_prod (NOLOCK) ON 
   	 tdc_bin_master.bin_no = lot_bin_prod.bin_no RIGHT OUTER JOIN
   	 prod_list (NOLOCK) INNER JOIN
    	inv_master (NOLOCK) ON 
    	prod_list.part_no = inv_master.part_no ON 
    	lot_bin_prod.tran_no = prod_list.prod_no 
AND        lot_bin_prod.tran_ext = prod_list.prod_ext
AND        lot_bin_prod.line_no = prod_list.line_no
WHERE (prod_list.direction < 0) 
AND (prod_list.prod_no = @intProd_No) 
AND  (prod_list.prod_ext = @intProd_Ext) 

UNION

SELECT 		prod_list.line_no,		 	prod_list.seq_no, 
		prod_list.part_no, 		 	inv_master.[description], 
		prod_list.uom, 		 	prod_list.plan_qty, 
    		prod_list.used_qty, 		lot_bin_prod.lot_ser, 
		lot_bin_prod.bin_no, 		inv_master.note, 
		prod_list.note AS comment,  	tdc_bin_master.group_code, 
		tdc_bin_master.group_code_id, 	tdc_bin_master.seq_no AS Expr1, 
    		tdc_bin_master.bin_no AS Expr2
FROM tdc_bin_master RIGHT OUTER JOIN
    	lot_bin_prod (NOLOCK) ON 
   	 tdc_bin_master.bin_no = lot_bin_prod.bin_no RIGHT OUTER JOIN
    	prod_list (NOLOCK) INNER JOIN
    	inv_master (NOLOCK) ON 
    	prod_list.part_no = inv_master.part_no ON 
    	lot_bin_prod.tran_no = prod_list.prod_no 
AND        lot_bin_prod.tran_ext = prod_list.prod_ext 
AND        lot_bin_prod.line_no = prod_list.line_no
WHERE (prod_list.direction < 0) 
AND (prod_list.prod_no = @intProd_No) 
AND (prod_list.prod_ext = @intProd_Ext )
ORDER BY tdc_bin_master.group_code, 	tdc_bin_master.seq_no, 
	     lot_bin_prod.bin_no,    		prod_list.line_no,
	    prod_list.part_no
GO
GRANT EXECUTE ON  [dbo].[tdc_get_mfg_pick_tkt_detl_sp] TO [public]
GO
