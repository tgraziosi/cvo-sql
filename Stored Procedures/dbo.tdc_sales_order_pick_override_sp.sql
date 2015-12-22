SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[tdc_sales_order_pick_override_sp] 
	@stationid int,
	@tote_bin varchar(12)
AS

DECLARE	@part_no varchar(30),
	@who varchar(50),
	@lot_ser varchar(25),
	@bin_no varchar(12),
	@loc varchar(10),
	@mask_code varchar(15),
	@serial_no varchar(40),
	@serial_raw varchar(40),
	@part_type char(1)

DECLARE	@line_no int,
	@order_no int,
	@order_ext int,
	@child_no int,
	@return int,
	@rowid int

DECLARE	@qty decimal(20,8),
	@tot_qty decimal(20,8)

SELECT @child_no = 0, @return = 0, @order_ext = 0
SELECT @who = who FROM #temp_who

BEGIN TRAN

IF EXISTS (SELECT * FROM #pick_custom_kit_order)
BEGIN
	SELECT @part_type = 'C'

	SELECT @order_no = order_no, @order_ext = order_ext, @line_no = line_no, @part_no = part_no, @loc = location
	  FROM #pick_custom_kit_order
	 WHERE row_id = 1	

	EXEC @return = tdc_dist_kit_pick_sp
END
ELSE
BEGIN
	SELECT @order_no = order_no, @order_ext = ext, @line_no = line_no, @part_no = part_no, @loc = location
	  FROM #adm_pick_ship
	 WHERE row_id = 1	

	EXEC @return = tdc_adm_pick_ship
END

IF (@return < 0)
BEGIN
	IF (@@TRANCOUNT > 0) ROLLBACK
	RETURN -101
END

UPDATE TDC_order 
   SET tdc_status = 'O1'
 WHERE order_no = @order_no 
   AND order_ext = @order_ext

IF (@stationid IS NOT NULL) AND (@stationid > 0)
BEGIN
	IF @part_type IS NULL
		SELECT @qty = SUM(qty) FROM #adm_pick_ship
	ELSE
		SELECT @qty = SUM(quantity) FROM #pick_custom_kit_order

	IF EXISTS (SELECT * 
		     FROM tdc_pack_queue
		    WHERE station_id = @stationid
		      AND order_no  = @order_no 
		      AND order_ext = @order_ext 
		      AND line_no   = @line_no 
		      AND part_no   = @part_no)
	BEGIN
		UPDATE tdc_pack_queue
		   SET picked = picked + @qty, last_modified_by = @who, last_modified_date = getdate()
		 WHERE station_id = @stationid
		   AND order_no  = @order_no 
		   AND order_ext = @order_ext
		   AND line_no   = @line_no 
		   AND part_no   = @part_no
	END
	ELSE
	BEGIN		
		INSERT INTO tdc_pack_queue (order_no, order_ext, line_no, part_no, picked, group_id, station_id, last_modified_by)
		SELECT @order_no, @order_ext, @line_no, @part_no, @qty, group_id, @stationid, @who
		  FROM tdc_pack_station_tbl 
		 WHERE station_id = @stationid
	END
END

SET @rowid = 0

WHILE (@rowid >= 0)
BEGIN
	IF @part_type IS NULL
	BEGIN
		SELECT @rowid = ISNULL((SELECT MIN(row_id) FROM #adm_pick_ship WHERE row_id > @rowid), -1)
		IF @rowid < 0 BREAK
	
		SELECT @lot_ser = lot_ser, @bin_no = bin_no, @qty = qty 
		  FROM #adm_pick_ship 
		 WHERE row_id = @rowid

		IF EXISTS (SELECT 1 
			     FROM tdc_dist_item_pick (nolock)
			    WHERE method     = '01'      
			      AND order_no   = @order_no
			      AND order_ext  = @order_ext
			      AND line_no    = @line_no
			      AND part_no    = @part_no
			      AND lot_ser    = @lot_ser
			      AND bin_no     = @bin_no
			      AND [function] = 'S')
		BEGIN
			UPDATE tdc_dist_item_pick
			   SET quantity   = quantity + @qty
			 WHERE method     = '01'
			   AND order_no   = @order_no
			   AND order_ext  = @order_ext
			   AND line_no    = @line_no
			   AND part_no    = @part_no
			   AND lot_ser    = @lot_ser
			   AND bin_no     = @bin_no
			   AND [function] = 'S'
		END
		ELSE
		BEGIN
			EXEC @child_no = tdc_get_serialno

			INSERT tdc_dist_item_pick (method, order_no,  order_ext,  line_no,  part_no,  lot_ser,  bin_no,  quantity, child_serial_no, [function], type) 
					    VALUES('01',  @order_no, @order_ext, @line_no, @part_no, @lot_ser, @bin_no, @qty, 	  @child_no, 	    'S', 'O1')
		END

		IF (@@ERROR <> 0)
		BEGIN
			IF (@@TRANCOUNT > 0) ROLLBACK
			RETURN -101
		END
	END
	ELSE
	BEGIN
		SELECT @rowid = ISNULL((SELECT MIN(row_id) FROM #pick_custom_kit_order WHERE row_id > @rowid), -1)
		IF @rowid < 0 BREAK
	
		SELECT @lot_ser = lot_ser, @bin_no = bin_no, @qty = quantity
		  FROM #pick_custom_kit_order 
		 WHERE row_id = @rowid
	END

	IF (EXISTS (SELECT * FROM tdc_config (nolock) WHERE [function] = 'tote_bin' AND active = 'Y')) AND (LEN(@tote_bin) > 0)
	BEGIN
		IF NOT EXISTS (SELECT 1
				 FROM tdc_tote_bin_tbl (nolock)
			        WHERE location   = @loc
				  AND order_no   = @order_no
				  AND order_ext  = @order_ext
				  AND line_no    = @line_no
				  AND part_no    = @part_no
				  AND lot_ser    = @lot_ser
				  AND bin_no     = @tote_bin 
				  AND orig_bin   = @bin_no
				  AND order_type = 'S')
		BEGIN
			INSERT tdc_tote_bin_tbl (bin_no,     order_no,  order_ext,  location, line_no,  part_no,  lot_ser,  orig_bin,  quantity, tran_date,  who, order_type)
					  VALUES(@tote_bin, @order_no, @order_ext, @loc,     @line_no, @part_no, @lot_ser, @bin_no,   @qty,      getdate(), @who, 'S')
		END
		ELSE
		BEGIN		
			UPDATE tdc_tote_bin_tbl
			   SET quantity   = quantity + @qty
			 WHERE bin_no     = @tote_bin
			   AND order_no   = @order_no
			   AND order_ext  = @order_ext
			   AND line_no    = @line_no
			   AND lot_ser    = @lot_ser
			   AND orig_bin   = @bin_no
			   AND order_type = 'S'
		END
	
		IF (@@ERROR <> 0)
		BEGIN
			IF (@@TRANCOUNT > 0) ROLLBACK
			RETURN -101
		END
	END

	IF EXISTS (SELECT * FROM tdc_inv_list (nolock) WHERE location = @loc AND part_no = @part_no AND vendor_sn IN ('I', 'O'))
	BEGIN
		SELECT @mask_code = mask_code FROM tdc_inv_master (nolock) WHERE part_no = @part_no

		DECLARE serial_cursor CURSOR FOR
			SELECT serial_no, serial_raw
			  FROM #serial_no_backup

		OPEN serial_cursor
		FETCH NEXT FROM serial_cursor INTO @serial_no, @serial_raw

		WHILE @@FETCH_STATUS = 0
		BEGIN
			IF NOT EXISTS (SELECT * FROM tdc_serial_no_track (nolock) WHERE part_no = @part_no AND lot_ser = @lot_ser AND serial_no = @serial_no)
			BEGIN
				INSERT tdc_serial_no_track (location, transfer_location, part_no,  lot_ser,  mask_code, serial_no, serial_no_raw, IO_count, init_control_type, init_trans, init_tx_control_no, last_control_type, last_trans, last_tx_control_no, date_time, [User_id], ARBC_No)
						    VALUES( @loc,     @loc, 		@part_no, @lot_ser, @mask_code,  @serial_no, @serial_raw,    2,        'S',       'SOPICKOR',     @order_no, 	      'S', 	 'SOPICKOR',     @order_no, 	  getdate(), @who, 	NULL)
			END
			ELSE
			BEGIN		
				UPDATE tdc_serial_no_track
				   SET IO_Count = IO_count + 1,
				       last_trans = 'SOPICKOR', 
				       last_tx_control_no = @order_no,
				       last_control_type  = 'S',
				       date_time = getdate(), 
				       [User_id] = @who,
				       transfer_location = @loc
				 WHERE part_no   = @part_no 
				   AND lot_ser   = @lot_ser 
				   AND serial_no = @serial_no
			END
	
			IF (@@ERROR <> 0)
			BEGIN
				DEALLOCATE serial_cursor
				IF (@@TRANCOUNT > 0) ROLLBACK
				RETURN -101
			END

			FETCH NEXT FROM serial_cursor INTO @serial_no, @serial_raw
		END
		
		CLOSE serial_cursor
		DEALLOCATE serial_cursor
	END
END

IF (@@TRANCOUNT > 0) COMMIT TRAN

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[tdc_sales_order_pick_override_sp] TO [public]
GO
