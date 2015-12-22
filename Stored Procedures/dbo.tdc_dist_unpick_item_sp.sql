SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[tdc_dist_unpick_item_sp]
AS 


DECLARE @order_no 	int, 
	@order_ext 	int, 
	@line_no 	int,
	@child_serial_no int, 
	@ret 		int,		-- if error return negative value else return zero
	@row_id		int

DECLARE	@tote_bin	varchar(12),
	@bin_no 	varchar(12), 	-- bin number where the part was picked from 
	@to_bin 	varchar(12),	-- bin number where the part is going to be unpicked to. it must be open bin or replenish bin
       	@lot_ser 	varchar(25), 
	@part_no 	varchar(30), 	-- either sub custom kit or regular part
	@location 	varchar(10),
	@language 	varchar(10),	-- default to us_english
	@who 		varchar(50),	-- user id
	@item 		varchar(30),	-- Custom kit
	@description 	varchar(60),
	@data		varchar(255),
	@msg		varchar(255),
	@uom		varchar(10),
	@serial_no	varchar(40)

DECLARE	@qty 		decimal (20,8), -- total quantity to be unpicked for part/lot/location combination
	@line_qty 	decimal (20,8),
	@avail_qty	decimal (20,8),
	@conv_factor	decimal (20,8),
	@qty_processed	decimal (20,8)

DECLARE	@lb_tracking 	char(1),
	@break 		char(1),	-- exit while loop
	@part_type 	char(1),	-- 'C' for custom kit
	@tdclog		char(1)

DECLARE @date_expired 	datetime,	-- get from lot_bin_ship table
	@date_tran	datetime

TRUNCATE TABLE #adm_bin_xfer
TRUNCATE TABLE #adm_pick_ship

SELECT 	@order_no = order_no, 
	@order_ext = order_ext, 
	@item = item,
	@part_no = part_no, 
	@lot_ser = lot_ser, 
	@to_bin = to_bin, 
	@location = location, 
	@qty = qty, 
	@who = who,
	@tote_bin = tote_bin,
	@line_no = line_no
FROM #tdc_unpick_item 

SELECT @language = Language FROM tdc_sec WHERE userid = @who
SELECT @language = ISNULL(@language, 'us_english')

-- make sure part number is valid. 
-- this is a case for a part number which is a regular line item and also a sub custom kit
-- if user try to unpick a custom kit: 
-- 1. through custom kit transaction we do not check the first select statement.
-- 2. through unpick transaction we unpick the regular line item first.
IF (@item IS NULL) OR (LEN(@item) = 0)
BEGIN
	SELECT @lb_tracking = lb_tracking, @description = substring([description], 1, 60) 
	FROM ord_list (nolock) 
	WHERE order_no = @order_no AND order_ext = @order_ext AND line_no = @line_no AND part_no = @part_no AND shipped > 0
END
ELSE
BEGIN
	-- check for custom kit item
	SELECT @lb_tracking = lb_tracking, @description = substring([description], 1, 60) 
	FROM ord_list_kit (nolock) 
	WHERE order_no = @order_no AND order_ext = @order_ext AND part_no = @part_no AND line_no = @line_no AND shipped > 0
END
	
IF @@ROWCOUNT = 0
BEGIN
	-- Quantity NOT available to be unpicked for Part: %s at Location: %s.
	SELECT @msg = err_msg FROM tdc_lookup_error (nolock) WHERE source = 'CO' AND module = 'ADH' AND trans = 'UNPICKKIT' AND err_no = -101 AND language = @language
	RAISERROR(@msg, 16, -1, @part_no, @location)
	RETURN -101
END

-- get custom kit part number. @part_type = 'C'
SELECT @item = part_no, @part_type = part_type, @uom = uom, @conv_factor = conv_factor, @location = location 
FROM ord_list (nolock) 
WHERE order_no = @order_no AND order_ext = @order_ext AND line_no = @line_no

-- make sure the part was picked through eWarehouse system
IF NOT EXISTS ( SELECT * FROM tdc_dist_item_pick (nolock) WHERE order_no = @order_no AND order_ext = @order_ext AND part_no = @part_no AND quantity > 0 AND [function] = 'S' ) 
BEGIN
	IF NOT EXISTS ( SELECT * FROM tdc_ord_list_kit (nolock) WHERE order_no = @order_no AND order_ext = @order_ext AND kit_part_no = @part_no AND kit_picked > 0 ) 
	BEGIN
		-- Invalid information: Order %d-%d / Part %s / Location %s.			
		SELECT @msg = err_msg FROM tdc_lookup_error WHERE source = 'CO' AND module = 'ADH' AND trans = 'UNPICKKIT' AND err_no = -102 AND language = @language
		RAISERROR(@msg, 16, -1, @order_no, @order_ext, @part_no, @location)
		RETURN -102
	END
END

SELECT @ret = 0, @avail_qty = 0, @qty_processed = 0

-- make sure the part at location was picked
IF @lb_tracking = 'Y'
BEGIN
	IF @part_type = 'C'
		SELECT @ret = count(*) FROM lot_bin_ship (nolock) WHERE tran_no = @order_no AND tran_ext = @order_ext AND lot_ser = @lot_ser AND part_no = @part_no AND line_no = @line_no AND kit_flag = 'Y' AND qty > 0	
	ELSE
		SELECT @ret = count(*) FROM lot_bin_ship (nolock) WHERE tran_no = @order_no AND tran_ext = @order_ext AND lot_ser = @lot_ser AND part_no = @part_no AND line_no = @line_no AND kit_flag = 'N' AND qty > 0	
END
ELSE
BEGIN
	IF @part_type = 'C'
		SELECT @ret = count(*) FROM ord_list_kit (NOLOCK) WHERE order_no = @order_no AND order_ext = @order_ext AND part_no = @part_no AND line_no = @line_no AND shipped > 0
	ELSE
		SELECT @ret = count(*) FROM ord_list (nolock) WHERE order_no = @order_no AND order_ext = @order_ext AND part_no = @part_no AND line_no = @line_no AND shipped > 0
END

IF @ret = 0
BEGIN
	-- Quantity NOT available to be unpicked for Part: %s at Location: %s.
	SELECT @msg = err_msg FROM tdc_lookup_error (nolock) WHERE source = 'CO' AND module = 'ADH' AND trans = 'UNPICKKIT' AND err_no = -101 AND language = @language
	RAISERROR(@msg, 16, -1, @part_no, @location)
	RETURN -101
END

-- check max quantity can be unpicked
IF @lb_tracking = 'Y'
BEGIN
	IF @part_type = 'C'
		SELECT @avail_qty = sum(qty) 
		  FROM lot_bin_ship (nolock) 
		 WHERE tran_no = @order_no AND tran_ext = @order_ext AND lot_ser = @lot_ser AND part_no = @part_no AND line_no = @line_no AND kit_flag = 'Y'
	ELSE
		SELECT @avail_qty = sum(qty) 
		  FROM lot_bin_ship (nolock) 
		 WHERE tran_no = @order_no AND tran_ext = @order_ext AND lot_ser = @lot_ser AND part_no = @part_no AND line_no = @line_no AND kit_flag = 'N'
END
ELSE
BEGIN
	IF @part_type = 'C'
		SELECT @avail_qty = sum(shipped * conv_factor * qty_per) 
		  FROM ord_list_kit (nolock) 
		 WHERE order_no = @order_no AND order_ext = @order_ext AND part_no = @part_no AND line_no = @line_no
	ELSE
		SELECT @avail_qty = sum(shipped * conv_factor) 
		  FROM ord_list (nolock) 
		 WHERE order_no = @order_no AND order_ext = @order_ext AND part_no = @part_no AND line_no = @line_no
END

IF @avail_qty < @qty
BEGIN
	-- Unpicked quantity is more than picked quantity.		
	SELECT @msg = err_msg FROM tdc_lookup_error (nolock) WHERE source = 'CO' AND module = 'ADH' AND trans = 'UNPICKKIT' AND err_no = -103 AND language = @language
	RAISERROR(@msg, 16, -1)
	RETURN -103
END	

SELECT @avail_qty = @qty

IF EXISTS (SELECT * FROM tdc_config (nolock) WHERE [function] = 'log_all_users' AND active = 'Y')
	SELECT @tdclog = 'Y'
ELSE IF EXISTS (SELECT * FROM tdc_sec (nolock) WHERE UserID = @who AND Log_User = 'Y')
	SELECT @tdclog = 'Y'

BEGIN TRAN

IF (@lb_tracking = 'Y')
BEGIN
	IF @part_type = 'C'
	BEGIN
		DECLARE unpick_items CURSOR FOR
			SELECT bin_no, date_expires, qty, date_tran 
			  FROM lot_bin_ship (nolock) 
			 WHERE tran_no = @order_no AND tran_ext = @order_ext AND lot_ser = @lot_ser AND part_no = @part_no AND line_no = @line_no AND kit_flag = 'Y' 
			ORDER BY date_tran DESC
		OPEN unpick_items 
		FETCH NEXT FROM unpick_items INTO @bin_no, @date_expired, @line_qty, @date_tran	
	END
	ELSE
	BEGIN
		DECLARE unpick_items CURSOR FOR
			SELECT bin_no, date_expires, qty, date_tran 
			  FROM lot_bin_ship (nolock) 
			 WHERE tran_no = @order_no AND tran_ext = @order_ext AND lot_ser = @lot_ser AND part_no = @part_no AND line_no = @line_no AND kit_flag = 'N' 
			ORDER BY date_tran DESC
		OPEN unpick_items 
		FETCH NEXT FROM unpick_items INTO @bin_no, @date_expired, @line_qty, @date_tran
	END

	WHILE @@FETCH_STATUS = 0
	BEGIN
		IF @avail_qty <= @line_qty
		BEGIN
			SELECT @line_qty = @avail_qty
			SELECT @break = 'Y'
		END
		ELSE
			SELECT @avail_qty = @avail_qty - @line_qty
	
		IF @part_type = 'C'
		BEGIN
			TRUNCATE TABLE #pick_custom_kit_order

			INSERT INTO #pick_custom_kit_order (method, order_no, order_ext, line_no, location, item, part_no, lot_ser, bin_no, quantity, who) 
						    VALUES ('01', @order_no, @order_ext, @line_no, @location, @item, @part_no, @lot_ser, @bin_no, -@line_qty, @who)

			IF(@tdclog = 'Y')
			BEGIN
				SELECT @data = 'LP_USER_STAT_ID: ' + @who + '; LP_LINE_NO: ' + convert(varchar(5), @line_no) + '; LP_ITEM_DESC: ' + @description + '; LP_LB_TRACKING: Y.' + '; LP_LB_UOM: ' + @uom
		
				INSERT INTO tdc_log (tran_date,UserID,trans_source,module,trans,tran_no,tran_ext,part_no,lot_ser,bin_no,location,quantity,data) 
					VALUES (getdate(), @who, 'CO', 'DIS', 'UNPICKIT', convert(varchar(10), @order_no), convert(varchar(5), @order_ext), @part_no, @lot_ser, @bin_no, @location, convert(varchar(20), RTRIM(LTRIM(STR(@line_qty, 20, 2)))), @data)
			END

			EXEC @ret = tdc_dist_kit_pick_sp
	
			IF @ret < 0
			BEGIN
				CLOSE unpick_items
				DEALLOCATE unpick_items
	
				IF @@TRANCOUNT > 0 ROLLBACK
	 			RETURN -105
			END
		END
		ELSE
		BEGIN			
			INSERT INTO #adm_pick_ship (order_no, ext, line_no, part_no, bin_no, lot_ser, location, date_exp, qty) 
					    VALUES (@order_no, @order_ext, @line_no, @part_no, @bin_no, @lot_ser, @location, @date_expired, -@line_qty)
			
			UPDATE tdc_dist_item_pick 
			   SET quantity = quantity - @line_qty 
			 WHERE order_no = @order_no AND order_ext = @order_ext AND part_no = @part_no AND line_no = @line_no AND lot_ser = @lot_ser AND bin_no = @bin_no AND [function] = 'S'
	
			SELECT @child_serial_no = child_serial_no 
			  FROM tdc_dist_item_pick (nolock) 
			 WHERE order_no = @order_no AND order_ext = @order_ext AND line_no = @line_no AND lot_ser = @lot_ser AND bin_no = @bin_no AND [function] = 'S'
			
			IF NOT EXISTS ( SELECT * FROM tdc_dist_group (nolock) WHERE child_serial_no = @child_serial_no AND [function] = 'S' )
				DELETE FROM tdc_dist_item_pick WHERE child_serial_no = @child_serial_no AND [function] = 'S' AND quantity <= 0
	
			IF(@tdclog = 'Y')
			BEGIN
				SELECT @data = 'LP_USER_STAT_ID: ' + @who + '; LP_LINE_NO: ' + convert(varchar(5), @line_no) + '; LP_ITEM_DESC: ' + @description + '; LP_LB_TRACKING: Y.' + '; LP_LB_UOM: ' + @uom
		
				INSERT INTO tdc_log (tran_date,UserID,trans_source,module,trans,tran_no,tran_ext,part_no,lot_ser,bin_no,location,quantity,data) 
					VALUES (getdate(), @who, 'CO', 'DIS', 'UNPICK', convert(varchar(10), @order_no), convert(varchar(5), @order_ext), @part_no, @lot_ser, @bin_no, @location, convert(varchar(20), RTRIM(LTRIM(STR(@line_qty, 20, 2)))), @data)
			END
		END

		SELECT @qty_processed = qty_processed 
		  FROM tdc_pick_queue (nolock)
		 WHERE trans = 'STDPICK' AND trans_type_no = @order_no AND trans_type_ext = @order_ext
		   AND part_no = @part_no AND lot = @lot_ser AND bin_no = @bin_no AND line_no = @line_no
		   AND trans_source = 'PLW' AND location = @location

		IF(@qty_processed > @line_qty)
			SELECT @qty_processed = @qty_processed - @line_qty
		ELSE
			SELECT @qty_processed = 0

		UPDATE tdc_pick_queue 
		   SET qty_processed = @qty_processed, [user_id] = @who
		 WHERE trans = 'STDPICK' 
		   AND trans_type_no = @order_no 
		   AND trans_type_ext = @order_ext
		   AND part_no = @part_no 
		   AND lot = @lot_ser 
		   AND bin_no = @bin_no 
		   AND line_no = @line_no
		   AND trans_source = 'PLW' 
		   AND location = @location

		IF @tote_bin IS NOT NULL
		BEGIN
			UPDATE tdc_tote_bin_tbl
			   SET quantity = quantity - @line_qty
			 WHERE order_no = @order_no 
			   AND order_ext = @order_ext 
			   AND bin_no = @tote_bin 
			   AND lot_ser = @lot_ser 
			   AND orig_bin = @bin_no 
			   AND line_no = @line_no 
			   AND part_no = @part_no 
			   AND order_type = 'S'

			DELETE FROM tdc_tote_bin_tbl
			WHERE order_no = @order_no 
			  AND order_ext = @order_ext 
			  AND line_no = @line_no 
			  AND part_no = @part_no 
			  AND lot_ser = @lot_ser
			  AND bin_no = @tote_bin
			  AND quantity <= 0
			  AND order_type = 'S'
		END

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
					VALUES (getdate(), @who, 'CO', 'PUR', 'BN2BN', convert(varchar(10), @order_no), convert(varchar(5), @order_ext), @part_no, @lot_ser, @bin_no, @location, convert(varchar(20), RTRIM(LTRIM(STR(@line_qty, 20, 2)))), @data)			
			END
		END
	
		IF @break = 'Y' BREAK
			
		FETCH NEXT FROM unpick_items INTO @bin_no, @date_expired, @line_qty, @date_tran
	END
	
	CLOSE unpick_items
	DEALLOCATE unpick_items
END
ELSE
BEGIN
	IF @part_type = 'C'
	BEGIN			
		TRUNCATE TABLE #pick_custom_kit_order

		INSERT INTO #pick_custom_kit_order (method, order_no, order_ext, line_no, location, item, part_no, quantity, who) 
					    VALUES ('01', @order_no, @order_ext, @line_no, @location, @item, @part_no, -@avail_qty, @who)

		IF(@tdclog = 'Y')
		BEGIN
			SELECT @data = 'LP_USER_STAT_ID: ' + @who + '; LP_LINE_NO: ' + convert(varchar(5), @line_no) + '; LP_ITEM_DESC: ' + @description + '; LP_LB_TRACKING: N' + '; LP_LB_UOM: ' + @uom
	
			INSERT INTO tdc_log (tran_date,UserID,trans_source,module,trans,tran_no,tran_ext,part_no,lot_ser,bin_no,location,quantity,data) 
				VALUES (getdate(), @who, 'CO', 'DIS', 'UNPICKIT', convert(varchar(10), @order_no), convert(varchar(5), @order_ext), @part_no, NULL, NULL, @location, convert(varchar(20), RTRIM(LTRIM(STR(@avail_qty, 20, 2)))), @data)
		END

		EXEC @ret = tdc_dist_kit_pick_sp

		IF @ret < 0
		BEGIN
			IF @@TRANCOUNT > 0 ROLLBACK
 			RETURN -105
		END
	END
	ELSE
	BEGIN
		INSERT INTO #adm_pick_ship (order_no, ext, line_no, part_no, location, qty) 
				    VALUES (@order_no, @order_ext, @line_no, @part_no, @location, -@avail_qty)
			
		UPDATE tdc_dist_item_pick 
		   SET quantity = quantity - @avail_qty 
		 WHERE order_no = @order_no AND order_ext = @order_ext AND part_no = @part_no AND line_no = @line_no AND [function] = 'S'

		SELECT @child_serial_no = child_serial_no 
		  FROM tdc_dist_item_pick (nolock) 
		 WHERE order_no = @order_no AND order_ext = @order_ext AND line_no = @line_no AND [function] = 'S'
		
		IF NOT EXISTS ( SELECT * FROM tdc_dist_group (nolock) WHERE child_serial_no = @child_serial_no AND [function] = 'S' )
			DELETE FROM tdc_dist_item_pick WHERE child_serial_no = @child_serial_no AND [function] = 'S' AND quantity <= 0

		IF(@tdclog = 'Y')
		BEGIN
			SELECT @data = 'LP_USER_STAT_ID: ' + @who + '; LP_LINE_NO: ' + convert(varchar(5), @line_no) + '; LP_ITEM_DESC: ' + @description + '; LP_LB_TRACKING: N' + '; LP_LB_UOM: ' + @uom
	
			INSERT INTO tdc_log (tran_date,UserID,trans_source,module,trans,tran_no,tran_ext,part_no,lot_ser,bin_no,location,quantity,data) 
				VALUES (getdate(), @who, 'CO', 'DIS', 'UNPICK', convert(varchar(10), @order_no), convert(varchar(5), @order_ext), @part_no, @lot_ser, @bin_no, @location, convert(varchar(20), RTRIM(LTRIM(STR(@avail_qty, 20, 2)))), @data)	
		END
	END

	SELECT @qty_processed = qty_processed 
	  FROM tdc_pick_queue (nolock)
	 WHERE trans = 'STDPICK' 
	   AND trans_type_no = @order_no 
	   AND trans_type_ext = @order_ext
	   AND part_no = @part_no 
	   AND line_no = @line_no

	IF(@qty_processed > @avail_qty)
		SELECT @qty_processed = @qty_processed - @avail_qty
	ELSE
		SELECT @qty_processed = 0

	UPDATE tdc_pick_queue 
	   SET qty_processed = @qty_processed, [user_id] = @who
	 WHERE  trans = 'STDPICK' 
	   AND trans_type_no = @order_no 
	   AND trans_type_ext = @order_ext
	   AND part_no = @part_no 
	   AND line_no = @line_no

	IF @tote_bin IS NOT NULL
	BEGIN
		UPDATE tdc_tote_bin_tbl
		   SET quantity = quantity - @avail_qty
		 WHERE order_no = @order_no 
		   AND order_ext = @order_ext 
		   AND bin_no = @tote_bin 
		   AND part_no = @part_no 
		   AND line_no = @line_no 
		   AND order_type = 'S'

		DELETE FROM tdc_tote_bin_tbl
		WHERE order_no = @order_no 
		  AND order_ext = @order_ext 
		  AND line_no = @line_no 
		  AND part_no = @part_no 
		  AND bin_no = @tote_bin
		  AND quantity <= 0
		  AND order_type = 'S'
	END
END

IF EXISTS ( SELECT * FROM #adm_pick_ship )
BEGIN
	EXEC @ret = tdc_adm_pick_ship

	IF @ret < 0
	BEGIN
		IF @@TRANCOUNT > 0
			ROLLBACK
 		RETURN -106
	END

	IF NOT EXISTS ( SELECT * FROM tdc_dist_item_pick (nolock) WHERE order_no = @order_no AND order_ext = @order_ext AND [function] = 'S' ) 
		UPDATE tdc_order SET tdc_status = 'Q1' WHERE order_no = @order_no AND order_ext = @order_ext
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
	IF EXISTS (SELECT * FROM tdc_serial_no_track (nolock) WHERE part_no = @part_no AND lot_ser = @lot_ser AND serial_no = @serial_no AND init_control_type = 'S' AND init_tx_control_no = @order_no AND (IO_count % 2 = 0))
	BEGIN
		DELETE FROM tdc_serial_no_track WHERE part_no = @part_no AND lot_ser = @lot_ser AND serial_no = @serial_no			    
	END
	ELSE
	BEGIN		
		UPDATE tdc_serial_no_track
		   SET IO_Count   = IO_count + 1,
		       date_time = getdate(), 
		       [User_id] = @who
		 WHERE part_no   = @part_no
		   AND lot_ser   = @lot_ser
		   AND serial_no = @serial_no
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
GRANT EXECUTE ON  [dbo].[tdc_dist_unpick_item_sp] TO [public]
GO
