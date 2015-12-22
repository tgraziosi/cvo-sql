SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[tdc_inv_list_part_sp]
	@strPart_No     VARCHAR(30) ,
	@intTabMode	INTEGER = 2
 AS

DECLARE @intViewMode	AS INTEGER,
	@intInsertMode	AS INTEGER

SELECT @intInsertMode = 0
SELECT @intViewMode = 2

IF @intTabMode = @intViewMode  /* Select the top one that meets the criteria they entered   */
	BEGIN
	SELECT  TOP 1
			tdc_inv_list.part_no	, 	tdc_inv_list.location, 
    			tdc_inv_list.unit_height, 	tdc_inv_list.unit_length, 
    			tdc_inv_list.unit_width	, 	tdc_inv_list.case_qty, 
    			tdc_inv_list.pack_qty	, 	tdc_inv_list.pallet_qty, 
    			tdc_inv_list.pcsn_flag	, 	inv_master.[description], 
    			inv_master.type_code	, 	inv_master.uom, 
			inv_master.rpt_uom	, 	inv_master.category , 	
			inv_master.cycle_type	, 	inv_master.vendor ,	 	
			inv_master.account	, 	inv_master.freight_class,
			tdc_inv_list.version_capture,   tdc_inv_list.warranty_track, 
		 ISNULL(tdc_inv_list.vendor_sn,'N') 	AS vendor_sn ,	
			tdc_inv_master.mask_code,	inv_master.upc_code
		  FROM 	tdc_inv_master (NOLOCK) RIGHT OUTER JOIN
    			inv_master (NOLOCK) ON 
    			tdc_inv_master.part_no = inv_master.part_no RIGHT OUTER JOIN
    			tdc_inv_list (NOLOCK) ON 
    			inv_master.part_no = tdc_inv_list.part_no
		   WHERE tdc_inv_list.part_no 	= @strPart_No
		   ORDER BY tdc_inv_list.part_no, location  

/*
		SELECT TOP 1 
			tdc_inv_list.part_no	, 	tdc_inv_list.location, 
    			tdc_inv_list.unit_height, 	tdc_inv_list.unit_length, 
    			tdc_inv_list.unit_width	, 	tdc_inv_list.case_qty, 
    			tdc_inv_list.pack_qty	, 	tdc_inv_list.pallet_qty, 
    			tdc_inv_list.pcsn_flag	, 	inv_master.[description], 
    			inv_master.type_code	, 	inv_master.uom, 
			inv_master.rpt_uom	, 	inv_master.category , 	
			inv_master.cycle_type	, 	inv_master.vendor , 	
			inv_master.account	, 	inv_master.freight_class
		   FROM tdc_inv_list (NOLOCK) LEFT OUTER JOIN
    			inv_master (NOLOCK) ON 
    			tdc_inv_list.part_no = inv_master.part_no
			WHERE tdc_inv_list.part_no = @strPart_No
		   ORDER BY tdc_inv_list.part_no, location

*/

	END
ELSE 
	BEGIN
		SELECT 	part_no, 	[description],
			type_code, 	category, 	
			vendor, 	freight_class, 	
			uom, 		rpt_uom, 	
			cycle_type, 	account
		   FROM inv_master (NOLOCK) 
		   WHERE uom <> 'HR'
		   AND lb_tracking = 'Y'
		   AND part_no = @strPart_No
	END

RETURN

GO
GRANT EXECUTE ON  [dbo].[tdc_inv_list_part_sp] TO [public]
GO
