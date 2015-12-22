SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/********************************************************************************************************/
/* This sp clears zero quanity										*/
/* input - serialId ( lowest serialID)									*/
/********************************************************************************************************/

CREATE PROCEDURE [dbo].[tdc_clear_zero_qty_sp]( @serial int) AS

SET NOCOUNT ON

DECLARE @err 		int,
	@link 		int,		-- tied to any pallets?
	@parent 	int,
	@temp_child 	int,		-- child_serial_no in tdc_pcs_group_tbl
	@temp_parent	int		-- parent_serial_no in tdc_pcs_group_tbl

SELECT 	@err 	= 0,
	@link 	= 0

BEGIN TRANSACTION

	--if a box contains multiple items, only need to delete item which has zero quantity
	-- don't have to delete this box in tdc_pcs_group_tbl
	IF( (SELECT count(*) FROM tdc_pcs_item WHERE child_serial_no = @serial) > 1 )
	BEGIN
		DELETE FROM tdc_pcs_item WHERE child_serial_no = @serial AND quantity = 0 	
	END
	
	-- if it is a single item in the box with zero quantity, delete this item 
	-- also need to delete this box in tdc_pcs_group_tbl
	ELSE
	BEGIN
		-- single item in the box, but is its quantity = 0?
		IF EXISTS( SELECT * FROM tdc_pcs_item WHERE child_serial_no = @serial AND quantity = 0)
		BEGIN
			DELETE FROM tdc_pcs_item WHERE child_serial_no = @serial AND quantity = 0
			
			SELECT @parent 	= (SELECT parent_serial_no FROM tdc_pcs_group WHERE child_serial_no = @serial)
			SELECT @link 	= (SELECT count(*) FROM tdc_pcs_group WHERE parent_serial_no = @parent)
	
			IF( @link = 1 )
			BEGIN
				SELECT @temp_child = @serial

				WHILE( @link = 1)
				BEGIN
					DELETE FROM tdc_pcs_group WHERE child_serial_no = @temp_child
					SELECT @temp_parent 	= @parent
					SELECT @parent 		= (SELECT parent_serial_no FROM tdc_pcs_group WHERE child_serial_no = @temp_parent)
					SELECT @link 		= (SELECT count(*) FROM tdc_pcs_group WHERE parent_serial_no = @parent)
					SELECT @temp_child 	= @temp_parent
					IF( @link > 1 )
					BEGIN
						SELECT @serial = @temp_child
					END			
									
				END
			END
			DELETE FROM tdc_pcs_group WHERE child_serial_no = @serial
		END
	END
COMMIT TRANSACTION
RETURN @err
GO
GRANT EXECUTE ON  [dbo].[tdc_clear_zero_qty_sp] TO [public]
GO
