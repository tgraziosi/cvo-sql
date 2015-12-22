SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[tdc_packverify_unpack_sp] 
	@order_no 	int,
	@order_ext 	int,
	@carton_no 	int,
	@line_no 	int, 
	@part_no 	varchar(30), 
	@location 	varchar(10), 
	@lot_ser	varchar(25),
	@bin_no  	varchar(12),
	@qty 		decimal(24,8), 
	@user_id 	varchar(50),
	@error_msg 	varchar(255) OUTPUT
AS

DECLARE @serial_flag 	varchar(10),
	@return_value	int,
	@serial_no_raw  varchar(40),
	@language 	varchar(10)

SELECT @error_msg = NULL

SELECT @qty = -@qty

-- Check if item is TDC serialized
SELECT @serial_flag = 'N'
SELECT @serial_flag = vendor_sn FROM tdc_inv_list (NOLOCK) WHERE part_no = @part_no AND location = @location
SELECT @language = ISNULL((SELECT Language FROM tdc_sec (nolock) WHERE userid = (SELECT who FROM #temp_who)), 'us_english')

IF (@serial_flag <> 'N') -- TDC Serialized
BEGIN		
	DECLARE serials_cursor CURSOR FOR 
		SELECT DISTINCT serial_no, lot_ser, bin_no FROM #scanned_serials
		
	OPEN serials_cursor
	FETCH NEXT FROM serials_cursor INTO @serial_no_raw, @lot_ser, @bin_no
	
	WHILE (@@FETCH_STATUS <> -1)
	BEGIN
		
	    	EXEC @return_value = tdc_ins_upd_carton_det_rec @order_no, @order_ext, @carton_no, @line_no, @part_no, -1, 
							        @lot_ser,  NULL, @serial_flag, NULL, NULL, NULL,
							        @error_msg OUTPUT, @user_id, @location, @serial_no_raw

	    	IF (@return_value <> 0) 
	    	BEGIN
			-- 'Unable to UnPack: tdc_ins_upd_carton_det_rec SP failed - '			
			SELECT @error_msg = (SELECT err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_packverify_unpack_sp' AND err_no = -101 AND language = @language) + @error_msg
			RETURN -1 
	    	END

		INSERT INTO #dist_un_group (parent_serial_no, type, method, order_no, order_ext, part_no, lot_ser, bin_no, quantity, [function], line_no)  
                VALUES (@carton_no, 'N1', '01', @order_no, @order_ext, @part_no, @lot_ser, @bin_no, 1, 'S', @line_no)

		EXEC @return_value = tdc_item_pack_ungroup_sp
	
	    	IF (@return_value <> 0) 
	    	BEGIN
			-- 'Unable to UnPack: tdc_item_pack_ungroup_sp SP failed.'
			SELECT @error_msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_packverify_unpack_sp' AND err_no = -102 AND language = @language
			RETURN -2
	    	END

		FETCH NEXT FROM serials_cursor INTO @serial_no_raw, @lot_ser, @bin_no
	END

	CLOSE      serials_cursor
	DEALLOCATE serials_cursor
END 
ELSE	-- Not TDC serialized
BEGIN
    	EXEC @return_value = tdc_ins_upd_carton_det_rec @order_no, @order_ext, @carton_no, @line_no, @part_no, @qty, @lot_ser, NULL, 
							@serial_flag, NULL, NULL, NULL, @error_msg OUTPUT, @user_id, @location, NULL
	    
    	IF (@return_value <> 0) 
    	BEGIN
		-- 'Unable to UnPack: tdc_ins_upd_carton_det_rec SP failed - '
		SELECT @error_msg = (SELECT err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_packverify_unpack_sp' AND err_no = -103 AND language = @language) + @error_msg
		RETURN -3
    	END

	--	Move from distribution table to pick table	--	
	TRUNCATE TABLE #dist_un_group

	SELECT @qty = -@qty

	INSERT INTO #dist_un_group (parent_serial_no, type, method, order_no, order_ext, part_no, lot_ser, bin_no, quantity, [function], line_no)  
        VALUES (@carton_no, 'N1', '01', @order_no, @order_ext, @part_no, @lot_ser, @bin_no, @qty, 'S', @line_no)

	EXEC @return_value = tdc_item_pack_ungroup_sp

    	IF (@return_value <> 0) 
    	BEGIN
		-- 'Unable to UnPack: tdc_item_pack_ungroup_sp SP failed.'
		SELECT @error_msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_packverify_unpack_sp' AND err_no = -104 AND language = @language
		RETURN -4
    	END	
END

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[tdc_packverify_unpack_sp] TO [public]
GO
