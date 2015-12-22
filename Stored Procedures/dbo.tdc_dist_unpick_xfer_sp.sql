SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[tdc_dist_unpick_xfer_sp]
--WITH ENCRYPTION 
AS 


DECLARE @xfer_no 	int, 
	@line_no 	int,
	@child_serial_no int, 
	@ret 		int		-- if error return negative value else return zero

DECLARE	@tote_bin	varchar(12),
	@bin_no 	varchar(12), 	-- bin number where the part was picked from 
	@to_bin 	varchar(12),	-- bin number where the part is going to be unpicked to. it must be open bin or replenish bin
       	@lot_ser 	varchar(25), 
	@part_no 	varchar(30), 	-- either sum custom kit or regular part
	@location 	varchar(10),
	@language 	varchar(10),	-- default to us_english
	@who 		varchar(50),	-- user id
	@item 		varchar(30),	-- Custom kit
	@description 	varchar(60),
	@data		varchar(255),
	@msg		varchar(255),
	@serial_no	varchar(40)

DECLARE	@qty 		decimal (20,8), -- total quantity to be unpicked for part/lot/location combination
	@line_qty 	decimal (20,8),
	@avail_qty	decimal (20,8),
	@tdc_avail_qty	decimal (20,8),
	@qty_processed	decimal (20,8)

DECLARE	@lb_tracking 	char(1),
	@break 		char(1),	-- exit while loop
	@part_type 	char(1),	-- 'C' for custom kit
	@tdclog		char(1)

DECLARE @date_expired 	datetime,	-- get from lot_bin_ship table
	@date_tran	datetime

TRUNCATE TABLE #adm_bin_xfer
TRUNCATE TABLE #adm_pick_xfer

SELECT 	@xfer_no = xfer_no, 
	@part_no = part_no, 
	@lot_ser = lot_ser, 
	@to_bin = to_bin, 
	@location = location, 
	@qty = qty, 
	@who = who,
	@tote_bin = tote_bin  
  FROM #tdc_unpick_xfer 
      		
SELECT @language = Language FROM tdc_sec (nolock) WHERE userid = @who
SELECT @language = ISNULL(@language, 'us_english')

SELECT @lb_tracking = lb_tracking, @description = substring([description], 1, 60) 
  FROM xfer_list (nolock) 
 WHERE xfer_no = @xfer_no AND part_no = @part_no AND shipped > 0

IF @@ROWCOUNT = 0
BEGIN
	-- Quantity NOT available to be unpicked for Part: %s.
	SELECT @msg = err_msg 
	  FROM tdc_lookup_error (nolock) 
	 WHERE source = 'CO' AND module = 'ADH' AND trans = 'UNPICKKIT' AND err_no = -101 AND language = @language

	RAISERROR(@msg, 16, -1, @part_no)
	RETURN -101
END

-- make sure the part was picked through eWarehouse system
IF NOT EXISTS ( SELECT * FROM tdc_dist_item_pick (nolock) WHERE order_no = @xfer_no AND part_no = @part_no AND quantity > 0 AND [function] = 'T' ) 
BEGIN
	-- Part %s Not Found In eWarehouse System For Order %d.			
	SELECT @msg = err_msg 
	  FROM tdc_lookup_error (nolock) 
	 WHERE source = 'CO' AND module = 'ADH' AND trans = 'UNPICKKIT' AND err_no = -102 AND language = @language

	RAISERROR(@msg, 16, -1, @part_no, @xfer_no)
	RETURN -102
END

-- check max quantity can be unpicked
IF @lb_tracking = 'Y'
BEGIN
	SELECT @avail_qty = sum(qty * conv_factor) 
	  FROM lot_bin_xfer
	 WHERE tran_no = @xfer_no AND lot_ser = @lot_ser AND part_no = @part_no

	SELECT @tdc_avail_qty = sum(quantity) 
	  FROM tdc_dist_item_pick
	 WHERE order_no = @xfer_no AND part_no = @part_no AND lot_ser = @lot_ser AND [function] = 'T'
END
ELSE
BEGIN
	SELECT @avail_qty = sum(shipped * conv_factor) 
	  FROM xfer_list 
	 WHERE xfer_no = @xfer_no AND part_no = @part_no

	SELECT @tdc_avail_qty = sum(quantity) 
	  FROM tdc_dist_item_pick
	 WHERE order_no = @xfer_no AND part_no = @part_no AND [function] = 'T'
END

IF ((@tdc_avail_qty < @qty) OR (@avail_qty < @qty) OR (@tdc_avail_qty > @avail_qty))
BEGIN
	-- Unpicked quantity is more than picked quantity.
	SELECT @msg = err_msg 
	  FROM tdc_lookup_error (nolock) 
	 WHERE source = 'CO' AND module = 'ADH' AND trans = 'UNPICKKIT' AND err_no = -103 AND language = @language

	RAISERROR(@msg, 16, -1)
	RETURN -103
END

SELECT @avail_qty = @qty

IF EXISTS (SELECT * FROM tdc_config (nolock) WHERE [function] = 'log_all_users' AND active = 'Y')
OR EXISTS (SELECT * FROM tdc_sec (nolock) WHERE UserID = @who AND Log_User = 'Y')
	SELECT @tdclog = 'Y'

DECLARE unpick_items CURSOR FOR
	SELECT line_no, bin_no, quantity, child_serial_no 
	  FROM tdc_dist_item_pick
	 WHERE order_no = @xfer_no 
	   AND part_no = @part_no 
	   AND ((lot_ser IS NULL AND @lot_ser IS NULL) OR (lot_ser = @lot_ser))
	   AND quantity > 0
	   AND [function] = 'T'  
--	ORDER BY child_serial_no DESC

OPEN unpick_items 
FETCH NEXT FROM unpick_items INTO @line_no, @bin_no, @line_qty, @child_serial_no

BEGIN TRAN

WHILE @@FETCH_STATUS = 0
BEGIN
	IF @avail_qty <= @line_qty
	BEGIN
		SELECT @line_qty = @avail_qty
		SELECT @break = 'Y'
	END
	ELSE
		SELECT @avail_qty = @avail_qty - @line_qty

	IF @lb_tracking = 'Y'
	BEGIN
		SELECT @date_expired = date_expires
		  FROM lot_bin_xfer
		 WHERE tran_no = @xfer_no AND part_no = @part_no AND lot_ser = @lot_ser AND bin_no = @bin_no

		INSERT INTO #adm_pick_xfer (xfer_no, line_no, from_loc, part_no, bin_no, lot_ser, date_exp, qty, who) 
				     VALUES(@xfer_no, @line_no, @location, @part_no, @bin_no, @lot_ser, @date_expired, -@line_qty, @who)
	END
	ELSE
	BEGIN
		INSERT INTO #adm_pick_xfer (xfer_no, line_no, from_loc, part_no, qty, who) 
				     VALUES(@xfer_no, @line_no, @location, @part_no, -@line_qty, @who)
	END

	UPDATE tdc_dist_item_pick 
	   SET quantity = quantity - @line_qty 
	 WHERE CURRENT OF unpick_items

	IF NOT EXISTS ( SELECT * FROM tdc_dist_group WHERE child_serial_no = @child_serial_no AND [function] = 'T' )
	BEGIN
		DELETE FROM tdc_dist_item_pick 
		WHERE child_serial_no = @child_serial_no 
		  AND [function] = 'T' 
		  AND quantity <= 0
	END

	IF(@tdclog = 'Y')
	BEGIN
		SELECT @data = 'LP_USER_STAT_ID: ' + @who + '; LP_LINE_NO: ' + convert(varchar(5), @line_no) + '; LP_ITEM_DESC: ' + @description + '; LP_LB_TRACKING: ' + @lb_tracking
	
		INSERT INTO tdc_log (tran_date,UserID,trans_source,module,trans,tran_no,tran_ext,part_no,lot_ser,bin_no,location,quantity,data) 
			VALUES (getdate(), @who, 'CO', 'ADH', 'UNPCKXFR', convert(varchar(10), @xfer_no), convert(varchar(5), 0), @part_no, @lot_ser, @bin_no, @location, convert(varchar(20), RTRIM(LTRIM(STR(@line_qty, 20, 2)))), @data)
	END

	IF @lb_tracking = 'Y'
		SELECT @qty_processed = qty_processed 
		  FROM tdc_pick_queue
		 WHERE trans = 'XFERPICK' 
		   AND trans_type_no = @xfer_no 
		   AND line_no = @line_no
		   AND part_no = @part_no 
		   AND lot = @lot_ser 
		   AND bin_no = @bin_no 
		   AND location = @location		
		   AND trans_source = 'PLW' 
		   AND trans_type_ext = 0
	ELSE
		SELECT @qty_processed = qty_processed 
		  FROM tdc_pick_queue
		 WHERE trans = 'XFERPICK' 
		   AND trans_type_no = @xfer_no 
		   AND line_no = @line_no
		   AND part_no = @part_no 
		   AND location = @location		
		   AND trans_source = 'PLW' 
		   AND trans_type_ext = 0

	IF(@qty_processed > @line_qty)
		SELECT @qty_processed = @qty_processed - @line_qty
	ELSE
		SELECT @qty_processed = 0

	IF @lb_tracking = 'Y'
		UPDATE tdc_pick_queue 
		   SET qty_processed = @qty_processed, [user_id] = @who
		 WHERE trans = 'XFERPICK' 
		   AND trans_type_no = @xfer_no 
		   AND line_no = @line_no
		   AND part_no = @part_no 
		   AND lot = @lot_ser 
		   AND bin_no = @bin_no 
		   AND location = @location		
		   AND trans_source = 'PLW' 
		   AND trans_type_ext = 0
	ELSE
		UPDATE tdc_pick_queue 
		   SET qty_processed = @qty_processed, [user_id] = @who
		 WHERE trans = 'XFERPICK' 
		   AND trans_type_no = @xfer_no 
		   AND line_no = @line_no
		   AND part_no = @part_no 
		   AND location = @location		
		   AND trans_source = 'PLW' 
		   AND trans_type_ext = 0

	IF @lb_tracking = 'Y'
	BEGIN
		IF @to_bin != @bin_no
		BEGIN
			IF EXISTS ( SELECT * FROM #adm_bin_xfer WHERE bin_from = @bin_no )
				UPDATE #adm_bin_xfer 
				   SET qty = qty + @line_qty 
				 WHERE bin_from = @bin_no
			ELSE
				INSERT INTO #adm_bin_xfer (location, part_no, lot_ser, bin_from, bin_to, date_expires, qty, who_entered) 
						   VALUES ( @location, @part_no, @lot_ser, @bin_no, @to_bin, @date_expired, @line_qty, @who )

			IF(@tdclog = 'Y')
			BEGIN
				SELECT @data = 'LP_USER_STAT_ID: ' + @who + '; LP_LINE_NO: ' + convert(varchar(5), @line_no) + '; LP_ITEM_DESC: ' + @description + '; LP_LB_TRACKING: ' + @lb_tracking + '; LP_TO_BIN: ' + @to_bin
	
				INSERT INTO tdc_log (tran_date,UserID,trans_source,module,trans,tran_no,tran_ext,part_no,lot_ser,bin_no,location,quantity,data) 
					VALUES (getdate(), @who, 'CO', 'ADH', 'BN2BN', convert(varchar(10), @xfer_no), convert(varchar(5), 0), @part_no, @lot_ser, @bin_no, @location, convert(varchar(20), RTRIM(LTRIM(STR(@line_qty, 20, 2)))), @data)
			END
		END
	END

	IF @tote_bin IS NOT NULL
	BEGIN
		IF @lb_tracking = 'Y'
			UPDATE tdc_tote_bin_tbl
			   SET quantity = quantity - @line_qty
			 WHERE order_no = @xfer_no 
			   AND bin_no = @tote_bin 
			   AND lot_ser = @lot_ser
			   AND orig_bin = @bin_no 
			   AND location = @location 
			   AND line_no = @line_no
			   AND order_type = 'T'
		ELSE			
			UPDATE tdc_tote_bin_tbl
			   SET quantity = quantity - @line_qty
			 WHERE order_no = @xfer_no 
			   AND bin_no = @tote_bin 
			   AND location = @location 
			   AND line_no = @line_no
			   AND order_type = 'T'

		DELETE FROM tdc_tote_bin_tbl
		 WHERE order_no = @xfer_no 
		   AND line_no = @line_no
		   AND quantity <= 0
		   AND order_type = 'T'
	END	

	IF @break = 'Y'
		BREAK

	FETCH NEXT FROM unpick_items INTO @line_no, @bin_no, @line_qty, @child_serial_no
END

CLOSE unpick_items
DEALLOCATE unpick_items

IF EXISTS ( SELECT * FROM #adm_pick_xfer )
BEGIN
	EXEC @ret = tdc_pick_xfer

	IF @ret < 0
	BEGIN
		IF @@TRANCOUNT > 0
			ROLLBACK
 		RETURN -106
	END

	IF NOT EXISTS ( SELECT * FROM tdc_dist_item_pick (nolock) WHERE order_no = @xfer_no AND [function] = 'T' ) 
		UPDATE tdc_xfers SET tdc_status = 'Q1' WHERE xfer_no = @xfer_no
END

IF EXISTS ( SELECT * FROM #adm_bin_xfer )
BEGIN
	EXEC @ret = tdc_bin_xfer

	IF @ret < 0
	BEGIN
		IF @@TRANCOUNT > 0
			ROLLBACK
 		RETURN -107
	END
END

SELECT @serial_no = MIN(serial_no) FROM #serial_no

WHILE @serial_no IS NOT NULL
BEGIN
	IF EXISTS (SELECT * FROM tdc_serial_no_track (nolock) WHERE part_no = @part_no AND lot_ser = @lot_ser AND serial_no = @serial_no AND init_control_type = 'T' AND init_tx_control_no = @xfer_no AND (IO_count % 2 = 0))
	BEGIN
		DELETE FROM tdc_serial_no_track WHERE part_no = @part_no AND lot_ser = @lot_ser AND serial_no = @serial_no			    
	END
	ELSE
	BEGIN		
		UPDATE  tdc_serial_no_track
		   SET	IO_Count  = IO_count + 1,
			date_time = getdate(), 
			[User_id] = @who,
			transfer_location = location,
			last_trans = 'UNPCKXFR'
		 WHERE	part_no   = @part_no AND
			lot_ser   = @lot_ser AND
			serial_no = @serial_no
	END

	IF (@@ERROR <> 0)
	BEGIN
		IF (@@TRANCOUNT > 0) ROLLBACK
		RETURN -101
	END

	SELECT @serial_no = MIN(serial_no) FROM #serial_no WHERE serial_no > @serial_no
END

IF @@TRANCOUNT > 0
	COMMIT TRAN

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[tdc_dist_unpick_xfer_sp] TO [public]
GO
