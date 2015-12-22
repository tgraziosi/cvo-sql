SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[tdc_inventoryAdmin_find_sp] 
		@intTabMode 	     INTEGER, --this is only needed by the Inventory Entry tab
		@strField	     VARCHAR(30),
		@strPart_No	     VARCHAR(30) = '',
		@strLocation	     VARCHAR(30) = ''
AS

--This SP is used by Inventory Entry and Serial No Mask tabs on the frmWMSInventoryAdmin screen when the user
-- double clicks on a field that has BOLD lettering

DECLARE 
	@intInsertMode 	AS INTEGER , 
	@intViewMode 	AS INTEGER ,
	@intEditMode 	AS INTEGER 

SELECT @intInsertMode 	= 0
SELECT @intEditMode 	= 1
SELECT @intViewMode 	= 2

IF @strField = 'mask_code' --we don't care what mode the tab is in
	BEGIN
		SELECT * FROM tdc_serial_no_mask (NOLOCK)
		RETURN
	END
		
IF @intTabMode = @intViewMode --Retrieve info from tdc_inv_list
	BEGIN
		IF @strField = 'part_no'
			BEGIN
				SELECT a.part_no as part_no	,	 location	, 
					[description], 	 type_code, 
					category		, 	vendor, 
					freight_class		, 	uom, 
					rpt_uom			, 	cycle_type, 
					account			, 	unit_height , 
					unit_length		, 	unit_width, 
					case_qty		, 	pack_qty, 
					pallet_qty		,	pcsn_flag ,
					a.allow_fractions	,	a.status
 		   		   FROM  inv_master a (NOLOCK) , tdc_inv_list b (NOLOCK)
		   		   WHERE a.part_no = b.part_no 
		   		   ORDER BY  a.part_no
			END
		ELSE IF @strField = 'location' --retieve all records from tdc_inv_list based on part_no
			BEGIN
				SELECT *
				   FROM tdc_inv_list (NOLOCK)
				   WHERE part_no = @strPart_No

			END

	END


ELSE IF @intTabMode = @intInsertMode  --show only part_no that are lot bin tracked AND 
					       --whose uom is not 'HR'(human resource)
	BEGIN
		IF @strField = 'part_no'
			BEGIN
				SELECT 	part_no, 	[description], 	type_code, 	category, 	vendor, 
    				      	freight_class, 	uom, 		rpt_uom, 	cycle_type, 	account ,
					status	,	allow_fractions
				   FROM inv_master (NOLOCK) 
				   WHERE inv_master.uom <> 'HR'
				   AND lb_tracking = 'Y'
				   AND status IN ('H' , 'P')
				   --AND allow_fractions = 0
				   ORDER BY part_no
			END

		ELSE IF @strField = 'location'  --the location MUST exist in inv_list for
						--this part AND it cannot already be in 
						--tdc_inv_list for this part
			BEGIN
				SELECT DISTINCT locations.location, locations.[name], locations.zone_code 
				   FROM locations (NOLOCK)
				   WHERE locations.location NOT IN 
					(SELECT DISTINCT location 
					   FROM tdc_inv_list (NOLOCK)
					   WHERE part_no = @strPart_No )
				   AND locations.location IN
					(SELECT DISTINCT location 
						FROM inv_list (NOLOCK)
						WHERE part_no = @strPart_No )

			END

	END






ELSE IF @intTabMode = @intEditMode  -- RETRIEVE ALL locations that are not already in the tdc_inv_list Table for
					     -- this part_no AS WELL AS the location for the record that is being edited
	BEGIN
		IF @strField = 'location'  
			BEGIN
				SELECT DISTINCT locations.location, locations.[name], locations.zone_code 
				   FROM locations (NOLOCK), inv_list
				   WHERE locations.location = inv_list.location  
				   AND locations.location NOT IN 
					(SELECT DISTINCT location 
					   FROM tdc_inv_list (NOLOCK)
					   WHERE part_no = @strPart_No )
				   
				UNION

				SELECT DISTINCT location, [name], zone_code 
				   FROM locations (NOLOCK)
				   WHERE location = @strLocation			
				

			END

	END

RETURN

GO
GRANT EXECUTE ON  [dbo].[tdc_inventoryAdmin_find_sp] TO [public]
GO
