SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROC [dbo].[tdc_validate_inv_maint_io_sp]
	@location varchar(30),
	@part_no  varchar(30),
	@track_mode char(1),
	@err_msg varchar(255) OUTPUT
AS 
	-- executes block if there is inventory for that location --
	------------------------------------------------------------------------------------
	IF EXISTS  (Select * FROM inventory (NOLOCK)  
		where  part_no = @part_no AND location = @location and in_stock > 0)
			
	BEGIN
			-- test to be sure track mode has in fact changed
		-------------------------------------------------------------------------------
		IF NOT EXISTS (SELECT * 
				 FROM tdc_inv_list (NOLOCK)
			        WHERE vendor_sn = @track_mode 
				  AND location  = @location 
				  AND part_no   = @part_no)
		BEGIN

			IF @track_mode != 'N'
			BEGIN
				--Make sure the part is lot_bin tracked
				IF NOT EXISTS(SELECT * FROM inv_master(NOLOCK)
					      WHERE part_no = @part_no
					      AND lb_tracking = 'Y')
				BEGIN
					SELECT @err_msg = 'Part number must be lot-bin tracked'
					RETURN -1
				END
				IF EXISTS (SELECT allow_fractions FROM inventory
					   WHERE part_no = @part_no and allow_fractions = '1')
				BEGIN
					SELECT @err_msg = 'Cannot serial track a part number that allows fractions'
					RETURN -1
				END
				
				IF EXISTS (SELECT serial_flag FROM inventory 
					   WHERE part_no = @part_no and serial_flag = '1')
				BEGIN
					SELECT @err_msg = 'Cannot serial track a part number that is Epicor serial tracked'
					RETURN -1
				END
			END
			-- test to see if it is a legal change from N/A to Outbound.	
			-------------------------------------------------------------
			IF  @track_mode = 'O' 
			BEGIN
				IF NOT EXISTS (select * from tdc_inv_list (NOLOCK) -- test for N/A stored
				Where vendor_sn = 'N' and location = @location and part_no = @part_no)
				BEGIN
				  
					IF EXISTS (select * from tdc_inv_list (NOLOCK) -- test for inbound stored
					Where vendor_sn = 'I' and location = @location and part_no = @part_no)
					
						set @err_msg = 'Cannot set to Outbound while part is in stock'
						RETURN -1
					END
			
			END
		
			IF @track_mode = 'I'

			BEGIN
					Set @err_msg = 'Cannot change to inbound/outbound while part is currently in stock'
					Return -1				
			END

			IF @track_mode = 'N'
			BEGIN
					Set @err_msg = 'Cannot change to N/A while part is currently in stock'
					Return -1				
			END

		END	
	END

RETURN 1
GO
GRANT EXECUTE ON  [dbo].[tdc_validate_inv_maint_io_sp] TO [public]
GO
