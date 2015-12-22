SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[tdc_packverify_unpick_sp] 
	@order_no 	int,
	@order_ext 	int,
	@line_no 	int, 
	@part_no 	varchar(30), 
	@location 	varchar(10), 
	@lot_ser	varchar(25),
	@bin_no  	varchar(12),
	@qty 		decimal(24,8), 
	@user_id 	varchar(50),
	@error_msg 	varchar(255) OUTPUT
AS

DECLARE @return_value 	int,
	@serial_flag  	char(1),
	@language 	varchar(10)

--Remove data from temp table in case of an error
TRUNCATE TABLE #adm_pick_ship

SELECT @language = ISNULL((SELECT Language FROM tdc_sec (nolock) WHERE userid = (SELECT who FROM #temp_who)), 'us_english')

-- Check if item is TDC serialized
SELECT @serial_flag = 'N'
SELECT @serial_flag = vendor_sn FROM tdc_inv_list (NOLOCK) WHERE part_no = @part_no AND location = @location

IF (@serial_flag = 'N') -- Not TDC Serialized
BEGIN		
	--Insert part into temp table for unpicking
	INSERT INTO #adm_pick_ship ( order_no,        ext,  line_no,  part_no,  bin_no,  lot_ser,  location, date_exp,    qty, err_msg, who)  
	VALUES			   (@order_no, @order_ext, @line_no, @part_no, @bin_no, @lot_ser, @location, GETDATE(), -@qty, NULL, @user_id)
	
	--Call pick stored procedure
	EXEC @return_value = tdc_adm_pick_ship

	IF (@return_value < 0) 
	BEGIN
--		'Unable to UnPick: tdc_adm_pick_ship SP failed.'
		SELECT @error_msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_packverify_unpick_sp' AND err_no = -101 AND language = @language 
		RETURN -1
	END
	
	-- Decriment the picked quantity
	UPDATE tdc_dist_item_pick 
	   SET quantity  	   = quantity - @qty
	 WHERE order_no  	   = @order_no
	   AND order_ext 	   = @order_ext
	   AND line_no   	   = @line_no
	   AND part_no   	   = @part_no
	   AND ISNULL(lot_ser, '') = ISNULL(@lot_ser, '')
	   AND ISNULL(bin_no,  '') = ISNULL(@bin_no,  '')
	   AND [function] 	   = 'S'
	
	IF (@@ERROR <> 0) 
	BEGIN
		-- 'Unable to UnPick: Update tdc_dist_item_pick failed.'
		SELECT @error_msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_packverify_unpick_sp' AND err_no = -102 AND language = @language 
		RETURN -2
	END
END
ELSE -- TDC Serialized item
BEGIN
	DECLARE serials_cursor CURSOR FOR 
		SELECT DISTINCT lot_ser, bin_no FROM #scanned_serials
		
	OPEN serials_cursor
	FETCH NEXT FROM serials_cursor INTO @lot_ser, @bin_no
	
	WHILE (@@FETCH_STATUS <> -1)
	BEGIN
			-- Get qty to unpick
		SELECT @qty = COUNT(*) 
	          FROM #scanned_serials
		 WHERE lot_ser = @lot_ser
	           AND bin_no  = @bin_no
	
		--Insert part into temp table for unpicking
		INSERT INTO #adm_pick_ship (order_no, ext, line_no, part_no, bin_no, lot_ser, location, date_exp, qty, err_msg, who)  
		VALUES			   (@order_no, @order_ext, @line_no, @part_no, @bin_no, @lot_ser, @location, GETDATE(), -@qty, NULL, @user_id)
	
		--Call pick stored procedure
		EXEC @return_value = tdc_adm_pick_ship
	
		IF (@return_value < 0) 
		BEGIN
			-- 'Unable to UnPick: tdc_adm_pick_ship SP failed.'
			SELECT @error_msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_packverify_unpick_sp' AND err_no = -101 AND language = @language 
			RETURN -1
		END
	
		-- Decriment the picked quantity
		UPDATE tdc_dist_item_pick 
		   SET quantity   = quantity - 1
		 WHERE order_no   = @order_no
		   AND order_ext  = @order_ext
		   AND line_no    = @line_no
		   AND part_no    = @part_no
		   AND lot_ser    = @lot_ser
		   AND bin_no     = @bin_no
		   AND [function] = 'S'
	
		IF (@@ERROR <> 0) 
		BEGIN
			-- 'Unable to UnPick: Update tdc_dist_item_pick failed.'
			SELECT @error_msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_packverify_unpick_sp' AND err_no = -102 AND language = @language 
			RETURN -2
		END

		FETCH NEXT FROM serials_cursor INTO @lot_ser, @bin_no
	END
	
	CLOSE      serials_cursor
	DEALLOCATE serials_cursor
END

--If quantity < 0, remove it from the table.
DELETE FROM tdc_dist_item_pick
 FROM tdc_dist_item_pick p
WHERE quantity < 0 
  AND order_no  = @order_no 
  AND order_ext = @order_ext 
  AND [function] = 'S'
  AND line_no   = @line_no
  AND part_no   = @part_no
  AND EXISTS (SELECT * FROM tdc_dist_group (nolock) WHERE child_serial_no = p.child_serial_no)

--Set status of tdc_order back to 'Q1'
UPDATE tdc_order  
   SET TDC_status = 'Q1'  
 WHERE order_no   =  @order_no
   AND order_ext  =  @order_ext

IF (@@ERROR <> 0) 
BEGIN
	-- 'Unable to UnPick: Update tdc_order failed.'
	SELECT @error_msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_packverify_unpick_sp' AND err_no = -103 AND language = @language 
	RETURN -3
END
 
-- If this is the last packed item on the order, change the status of the order back to N
IF NOT EXISTS (SELECT * FROM ord_list (NOLOCK) 
		WHERE order_no  = @order_no
                  AND order_ext = @order_ext
                  AND shipped   > 0)  
BEGIN
	UPDATE orders   SET status = 'N' WHERE order_no = @order_no AND ext       = @order_ext
	UPDATE ord_list SET status = 'N' WHERE order_no = @order_no AND order_ext = @order_ext
END
       
RETURN 0
GO
GRANT EXECUTE ON  [dbo].[tdc_packverify_unpick_sp] TO [public]
GO
