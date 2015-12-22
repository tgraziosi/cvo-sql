SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROC [dbo].[tdc_inv_entry_validate_sp]
	@part_no	varchar(30),
	@mask_code	varchar(15),
	@upc_code	varchar(12),
	@auto_generate	int, --1)ON, 2)OFF
	@next_serial_no varchar(40),
	@edit_mode	int,--1) Insert, 2)Edit
	@err_msg	varchar(255) OUTPUT
AS
 
DECLARE
	@location		varchar(10),
	@masked_serial_no	varchar(40),
	@mask_data		varchar(100),
	@vendor_sn		char(1),
	@ret			int
----------------------------------------------------------------------------------------------------------
-- Validation for insert and edit mode
----------------------------------------------------------------------------------------------------------
--Validate upc	
IF ISNULL(@upc_code, '') <> '' 
BEGIN	
	IF EXISTS(SELECT * FROM inv_master(NOLOCK)
		WHERE part_no <> @part_no
		AND upc_code  = @upc_code)
	BEGIN
		SELECT @err_msg = 'UPC Code already in use for another part number'
		RETURN -1
	END
 
	IF NOT EXISTS(SELECT * FROM tdc_serial_no_mask (NOLOCK) WHERE mask_code = @mask_code)
	BEGIN	
		SELECT @err_msg = 'Invalid mask code'
		RETURN -1
	END

END

IF ISNULL(@mask_code, '') = ''
BEGIN
	SELECT @err_msg = 'Mask code is required'
	RETURN -1
END

IF @auto_generate = 1
BEGIN
	SELECT @mask_data = mask_data FROM tdc_serial_no_mask (NOLOCK) WHERE mask_code = @mask_code

	IF (SELECT CHARINDEX('<D>', 	@mask_data, 1)) > 0
	OR (SELECT CHARINDEX('<M>', 	@mask_data, 1)) > 0
	OR (SELECT CHARINDEX('<YY', 	@mask_data, 1)) > 0
	OR (SELECT CHARINDEX('<YYYY>', 	@mask_data, 1)) > 0
	OR (SELECT CHARINDEX('<P', 	@mask_data, 1)) > 0
	OR (SELECT CHARINDEX('<L', 	@mask_data, 1)) > 0
	BEGIN
		SELECT @err_msg = 'Auto Generate Serial Numbers is not allowed with a Mask Code that includes <D>, <M>, <YY>, <YYYY>, <J>, <Px>, <Lx>'
		RETURN -1
	END
END 

IF @auto_generate = 1 AND ISNULL(@next_serial_no, '') <> ''
BEGIN

	EXEC @ret = tdc_format_serial_mask_sp @part_no, @next_serial_no, @masked_serial_no, @err_msg OUTPUT, @mask_code
	IF @ret < 1 RETURN -1
 
END

----------------------------------------------------------------------------------------------------------
-- Insert Mode
----------------------------------------------------------------------------------------------------------
IF (@edit_mode in (1, 3)) --Insert or Duplicate mode
BEGIN		
	IF EXISTS(SELECT * FROM tdc_inv_master(NOLOCK) WHERE part_no = @part_no)
	BEGIN
		SELECT @err_msg = 'Part has already been added.'
		RETURN -1
	END
	
	IF NOT EXISTS(SELECT * 
			FROM inv_master (NOLOCK)
		       WHERE part_no = @part_no
		         AND status IN ('H', 'M', 'P'))
	BEGIN 
		SELECT @err_msg = 'Invalid part number'
		RETURN -1
	END			

	IF @mask_code <> 'NONE'
	BEGIN
		IF EXISTS(SELECT * 
			    FROM inv_master (NOLOCK)
			   WHERE part_no = @part_no
			     AND lb_tracking = 'N')
		BEGIN
			SELECT @err_msg = 'Non lot/bin tracked parts cannot have a mask code other than "NONE"'
			RETURN -1
		END
	END

		

	----------------------------------------------------------------------------------------------------------
	-- If the user is validating the locations screen, validate vendor_sn
	----------------------------------------------------------------------------------------------------------
	IF EXISTS(SELECT * FROM #inv_insert)
	BEGIN
		DECLARE insert_locations_cur CURSOR FOR
		SELECT location, vendor_sn
		  FROM #inv_insert
		 WHERE vendor_sn NOT IN ('N', 'O')

		OPEN insert_locations_cur
		FETCH NEXT FROM insert_locations_cur INTO @location, @vendor_sn
		
		WHILE (@@FETCH_STATUS = 0)
		BEGIN	
			IF EXISTS(SELECT * 
				    FROM inventory(NOLOCK)
				   WHERE location = @location
				     AND part_no  = @part_no
				     AND in_stock > 0)			
			BEGIN
				SELECT @err_msg = 'Part is in stock at location: ' + @location + char(13) + 
						  'Serial tracking direction must be "NONE" for that location.'
				CLOSE      insert_locations_cur 
				DEALLOCATE insert_locations_cur 
				RETURN -1
			END
			FETCH NEXT FROM insert_locations_cur INTO @location, @vendor_sn  
		END -- END WHILE
		
		CLOSE      insert_locations_cur 
		DEALLOCATE insert_locations_cur 
	END



END

----------------------------------------------------------------------------------------------------------
-- Edit Mode
----------------------------------------------------------------------------------------------------------
ELSE IF @edit_mode = 2 --Edit
BEGIN
	IF NOT EXISTS(SELECT * FROM inv_master (NOLOCK)
		      WHERE part_no = @part_no
		      AND status IN ('H', 'M', 'P'))
	BEGIN 
		SELECT @err_msg = 'Invalid part number'
		RETURN -1
	END

	IF @mask_code <> (SELECT mask_code FROM tdc_inv_master (NOLOCK)
			  WHERE part_no = @part_no)
	BEGIN
			IF EXISTS  (Select * FROM inventory (NOLOCK)  
			WHERE  part_no = @part_no and in_stock > 0)
			BEGIN
				SELECT @err_msg = 'Cannot change mask code while part is in stock'
				RETURN -1
			END
	END	

	IF EXISTS (SELECT * FROM tdc_inv_list (NOLOCK)
		   WHERE part_no = @part_no
		   AND vendor_sn = 'I') 
	AND @mask_code = 'NONE'
	BEGIN
		SELECT @err_msg = 'Inbound / Outbound tracked parts must have a valid mask code'
		RETURN -1
	END
		
	DECLARE edit_locations_cur CURSOR FOR	
		SELECT location, vendor_sn
		  FROM #temp_inv_list
		 ORDER BY location

	OPEN edit_locations_cur
	FETCH NEXT FROM edit_locations_cur INTO @location, @vendor_sn
	
	------------------------------------------------------------------------------------------------------------------
	--		Verify the temp table to the rules put forth then - Update regular table			--
	--														--		
	--		1)@vendor_sn can be edited all other ways as long as inventory doesn't exist IN THAT LOCATION  --
	--		2)@vendor_sn can only be edited from N/A to outbound while inventory exists			--	
	------------------------------------------------------------------------------------------------------------------	

	WHILE (@@FETCH_STATUS = 0)
	BEGIN	
		EXEC @ret = tdc_validate_inv_maint_io_sp @location, @part_no, @vendor_sn, @err_msg OUTPUT
		IF @ret = -1
		BEGIN
			CLOSE      edit_locations_cur 
			DEALLOCATE edit_locations_cur 
			RETURN -1
		END
		FETCH NEXT FROM edit_locations_cur INTO @location, @vendor_sn  
	END -- END WHILE
	
	CLOSE      edit_locations_cur 
	DEALLOCATE edit_locations_cur 

END
RETURN 1

GO
GRANT EXECUTE ON  [dbo].[tdc_inv_entry_validate_sp] TO [public]
GO
