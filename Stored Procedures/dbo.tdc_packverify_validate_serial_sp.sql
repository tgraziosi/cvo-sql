SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[tdc_packverify_validate_serial_sp]
	@packing	 	int,
	@carton_no	 	int,
	@part_no	 	varchar(30),
	@location	 	varchar(10),
	@serial_no	 	varchar(40),
	@vendor_sn		char(1),
	@version_capture 	int         	OUTPUT
AS 

DECLARE	@formatted_serial 	varchar(40),
	@Ret			int,
	@io_count		int,
	@ErrMsg			varchar(255),
	@language 		varchar(10)

	SELECT @language = ISNULL((SELECT Language FROM tdc_sec (nolock) WHERE userid = (SELECT who FROM #temp_who)), 'us_english')

	IF @serial_no = ''
	BEGIN	
		-- 'Serial Number cannot be blank.'
		SELECT @ErrMsg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_packverify_validate_serial_sp' AND err_no = -101 AND language = @language 
		RAISERROR (@ErrMsg, 16, 1)
		RETURN -1
	END
	
    	-- Check to see if the serial has already been scanned.
	IF EXISTS(SELECT * FROM #scanned_serials WHERE serial_no = @serial_no)
	BEGIN	
		-- 'Serial Number has already been scanned.'
		SELECT @ErrMsg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_packverify_validate_serial_sp' AND err_no = -102 AND language = @language 
		RAISERROR (@ErrMsg, 16, 1)
		RETURN -2
	END

	IF @vendor_sn = 'I'
	BEGIN
	    	-- Check to see if the serial is available for the carton.
		IF NOT EXISTS(SELECT * FROM #available_serials WHERE serial_no = @serial_no)
		BEGIN	
			-- 'Serial Number is not available for carton: %d.'
			SELECT @ErrMsg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_packverify_validate_serial_sp' AND err_no = -103 AND language = @language 
			RAISERROR (@ErrMsg, 16, 1, @carton_no)	
			RETURN -3
		END

		-- Get the io_count 
		SELECT @io_count = io_count
		  FROM tdc_serial_no_track (NOLOCK)
		 WHERE part_no       	  = @part_no
	 	   AND serial_no_raw 	  = @serial_no
	 	   AND location           = @location
	 	   AND last_control_type != 'Q'  
	 	   AND last_trans    NOT IN ('STDXPICK', 'STDXSHVF')
	
		IF (@io_count IS NULL) 
		BEGIN
			-- 'Invalid serial number'
			SELECT @ErrMsg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_packverify_validate_serial_sp' AND err_no = -104 AND language = @language 
			RAISERROR (@ErrMsg, 16, 1)
			RETURN -4
		END
	END

	-- Get formatted serial no
	EXEC @Ret = tdc_format_serial_mask_sp @part_no, @serial_no, @formatted_serial OUTPUT, @ErrMsg OUTPUT

	IF (@Ret <> 1) 
	BEGIN	
		RAISERROR (@ErrMsg, 16, 1)	
		RETURN -5
	END

	-- Get version and the direction of the serial track
	SELECT @version_capture = version_capture
	  FROM tdc_inv_list  (NOLOCK)
	 WHERE part_no  = @part_no
	   AND location = @location

	-- If unpacking 
	IF (@packing = 0)
	BEGIN
		--if I/O count is odd, part is in stock
		IF (@vendor_sn = 'I') AND (@io_count % 2 > 0 )
		BEGIN
			-- 'Serial number already in inventory.'
			SELECT @ErrMsg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_packverify_validate_serial_sp' AND err_no = -105 AND language = @language 
			RAISERROR (@ErrMsg, 16, 1)
			RETURN -6
		END

		IF NOT EXISTS(SELECT * FROM tdc_carton_detail_tx (NOLOCK)
               			      WHERE carton_no     = @carton_no
					AND part_no       = @part_no
                   		        AND serial_no_raw = @serial_no)
		BEGIN
			-- 'Serial number is not in the carton.'
			SELECT @ErrMsg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_packverify_validate_serial_sp' AND err_no = -106 AND language = @language 
			RAISERROR (@ErrMsg, 16, 1)
			RETURN -7
		END
	END
	ELSE --Packing
	BEGIN
              	IF EXISTS(SELECT * FROM tdc_carton_detail_tx (NOLOCK)
              		   WHERE part_no       = @part_no
                    	     AND serial_no_raw = @serial_no)
		BEGIN
			-- 'Serial number already packed.'
			SELECT @ErrMsg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_packverify_validate_serial_sp' AND err_no = -107 AND language = @language 
			RAISERROR (@ErrMsg, 16, 1)
			RETURN -8
		END
		
		-- If I/O count is even, then part is out of stock
		IF (@vendor_sn = 'I') AND (@io_count % 2 = 0) 
		BEGIN
			-- 'Serial number is not in inventory.'
			SELECT @ErrMsg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_packverify_validate_serial_sp' AND err_no = -108 AND language = @language 
			RAISERROR (@ErrMsg, 16, 1)
			RETURN -9
		END
	END

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[tdc_packverify_validate_serial_sp] TO [public]
GO
