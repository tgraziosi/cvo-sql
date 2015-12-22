SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[tdc_inv_part_no_find_sp] 
		@intInvEntry_TabMode INTEGER
AS

DECLARE 
	@intInsertMode 	AS INTEGER , 
	@intViewMode 	AS INTEGER

SELECT @intInsertMode 	= 0
SELECT @intViewMode 	= 2
		
IF @intInvEntry_TabMode = @intViewMode
	BEGIN
		SELECT a.part_no as part_no	,	location	, 
			[description]		, 	type_code, 
			category		,	vendor, 
			freight_class		, 	uom, 
			rpt_uom			, 	cycle_type, 
			account			, 	unit_height , 
			unit_length		, 	unit_width, 
			case_qty		,	pack_qty, 
			pallet_qty		,	pcsn_flag ,
			a.allow_fractions 	,	a.status
 		   FROM  inv_master a (NOLOCK) , tdc_inv_list b (NOLOCK)
		   WHERE a.part_no = b.part_no 
		   ORDER BY  a.part_no
	END

ELSE IF @intInvEntry_TabMode = @intInsertMode
	BEGIN
		SELECT part_no	, sku_no	, [description]	, vendor ,status , allow_fractions
		   FROM inv_master (NOLOCK) 
		   WHERE uom <> 'HR'
		   AND lb_tracking = 'Y'
		   AND status IN ('H' , 'P')
		   --AND allow_fractions = 0
		   ORDER BY part_no
	END

RETURN

GO
GRANT EXECUTE ON  [dbo].[tdc_inv_part_no_find_sp] TO [public]
GO
