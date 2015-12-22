SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[tdc_dist_kit_pick_sp] 
AS

DECLARE @method 	varchar(2), 
	@location 	varchar(10), 
	@item 		varchar(30), 
	@part_no 	varchar(30), 
	@lot_ser 	varchar(25),
	@order_no 	int, 
	@order_ext 	int, 
	@line_no 	int, 
	@serial_no 	int,  
	@length 	int,
	@err_ret	int,
	@row_id		int,
	@dsf 		char(1), 
	@lb_track 	char(1), 
	@status 	char(1),
	@tdclog 	char(1),
	@language 	varchar(10),
	@bin	 	varchar(12),
	@bin_no 	varchar(12),
	@to_bin 	varchar(12),
	@who 		varchar(20), 
	@msg 		varchar(255),
	@description	varchar(255),
	@sub_part 	varchar(30),
	@uom	 	varchar(2),
	@qty 		decimal(20,8),
	@quantity 	decimal(20,8), 
	@tot_lb_qty 	decimal(20,8),
	@tot_picked 	decimal(20,8),
	@conv_factor 	decimal(20,8), 
	@ord_shipped 	decimal(20,8),
	@kit_shipped 	decimal(20,8), 
	@ordered 	decimal(20,8), 
	@qty_per 	decimal(20,8),
	@line_qty 	decimal(20,8), 
	@temp_qty 	decimal(20,8),
	@part_type 	char(1)

DECLARE @date_expired 	datetime,	-- get from lot_bin_ship table
		@date_tran	datetime,
		@login_id	varchar(50)
	
SELECT @err_ret = 0, @ordered = 0, @temp_qty = 0
SELECT @msg = 'Error message not found', @tdclog = 'N'

SELECT @order_no  = order_no, 
       @order_ext = order_ext, 
       @who 	  = who, 
       @method    = method, 
       @line_no   = line_no, 
       @location  = location, 
       @item      = item, 
       @part_no   = part_no, 	-- component to be picked / unpicked
       @sub_part  = sub_part_no,-- component that is substituted with @part_no
 --    @lot_ser   = lot_ser, 	
       @bin_no    = bin_no,	-- from bin
       @to_bin    = bin_no,
 --    @quantity  = quantity,
       @row_id    = row_id
  FROM #pick_custom_kit_order
 WHERE row_id = 1

SELECT @login_id = login_id FROM #temp_who

IF EXISTS (SELECT * FROM tdc_config (nolock) WHERE [function] = 'log_all_users' AND active = 'Y')
	SELECT @tdclog = 'Y'
ELSE IF EXISTS (SELECT * FROM tdc_sec (nolock) WHERE UserID = @login_id AND Log_User = 'Y')
	SELECT @tdclog = 'Y'

SELECT @language = Language 
  FROM tdc_sec (NOLOCK) 
 WHERE userid = @login_id

SELECT @language = ISNULL(@language, 'us_english')

IF NOT EXISTS (SELECT * 
	 	 FROM ord_list_kit (NOLOCK) 
		WHERE order_no = @order_no 
		  AND order_ext = @order_ext 
		  AND status BETWEEN 'N' AND 'Q')
BEGIN
	-- Error: Invalid order number %d-%d
  	SELECT @msg = err_msg 
	  FROM tdc_lookup_error (nolock)
	 WHERE module   = 'SPR' 
	   AND trans    = 'CUSTKIT' 
	   AND err_no   = -101 	
	   AND language = @language

	RAISERROR (@msg, 16, 1, @order_no, @order_ext)
	RETURN -101
END

IF (( SELECT SUM(shipped) 
	FROM ord_list (NOLOCK) 
       WHERE order_no  = @order_no 
	 AND order_ext = @order_ext ) > 0 )
BEGIN
	IF NOT EXISTS( SELECT * 
			 FROM tdc_dist_item_pick (NOLOCK) 
			WHERE order_no   = @order_no 	
			  AND order_ext  = @order_ext 
			  AND [function] = 'S')
	BEGIN
		-- Error: Order %d-%d is not controlled by TDC-LINCS system
  		SELECT @msg     = err_msg 
		  FROM tdc_lookup_error (nolock)
		 WHERE module   = 'SPR' 
		   AND trans    = 'CUSTKIT' 
		   AND err_no   = -102 
		   AND language = @language

		RAISERROR (@msg, 16, 1, @order_no, @order_ext)
		RETURN -102
	END
END
			
SELECT @ordered     = ordered * conv_factor, -- convert it to base quantity
       @qty_per     = qty_per,       
       @lb_track    = lb_tracking,
       @description = [description],
       @part_type   = part_type
  FROM ord_list_kit (NOLOCK) 
 WHERE order_no     = @order_no 
   AND order_ext    = @order_ext 
   AND part_no      = @part_no 
   AND line_no      = @line_no 

IF (@@ROWCOUNT = 0)
BEGIN
	--Error: 'This part number %s is not on this order' 				
  	SELECT @msg = err_msg 
	  FROM tdc_lookup_error (NOLOCK) 
	 WHERE module   = 'SPR' 
	   AND trans    = 'CUSTKIT' 
	   AND err_no   = -103 
	   AND language = @language

	RAISERROR (@msg, 16, 1, @part_no)
	RETURN -103
END

SELECT @uom = uom, @conv_factor = conv_factor
  FROM ord_list (nolock) 
 WHERE order_no = @order_no 
   AND order_ext = @order_ext
   AND line_no = @line_no

SELECT @length = ISNULL(LEN(@sub_part), 0)
SELECT @tot_picked = sum(quantity) FROM #pick_custom_kit_order
SELECT @row_id = 0

IF ( @tot_picked < 0 )
BEGIN
	IF (@length = 0)
		SELECT @kit_shipped = kit_picked 
		  FROM tdc_ord_list_kit (NOLOCK) 
		 WHERE order_no     = @order_no 
		   AND order_ext    = @order_ext 
		   AND kit_part_no  = @part_no 
		   AND line_no      = @line_no 
		   AND sub_kit_part_no IS NULL
	ELSE
		SELECT @kit_shipped 	= kit_picked 
		  FROM tdc_ord_list_kit (NOLOCK) 
		 WHERE order_no 	= @order_no 
		   AND order_ext 	= @order_ext 
		   AND kit_part_no 	= @sub_part 
		   AND line_no 		= @line_no 
		   AND sub_kit_part_no  = @part_no

	IF ( @kit_shipped < -@tot_picked )
	BEGIN
		-- Error: 'Cannot unpick more than was picked' 	
 		SELECT @msg = err_msg 
		  FROM tdc_lookup_error (NOLOCK)
		 WHERE module   = 'SPR' 
		   AND trans    = 'CUSTKIT' 
		   AND err_no   = -104 
		   AND language = @language

		RAISERROR (@msg, 16, 1)
		RETURN -104
	END
END
	
IF (( SELECT in_stock 
	FROM inventory (NOLOCK) 
       WHERE part_no  = @part_no 
	 AND location = @location ) < @tot_picked) AND (@part_type <> 'V')
BEGIN
	--Error: 'There is not enough of item %s in stock' 	
	SELECT @msg = err_msg 
	  FROM tdc_lookup_error(NOLOCK) 
	 WHERE module   = 'SPR' 
	   AND trans    = 'CUSTKIT' 
	   AND err_no   = -106 
	   AND language = @language

	RAISERROR (@msg, 16, 1, @part_no)
	RETURN -106
END

IF @lb_track = 'Y'
BEGIN
	WHILE (@row_id >= 0)
	BEGIN
		SELECT @row_id = ISNULL((SELECT min(row_id) FROM #pick_custom_kit_order WHERE row_id > @row_id), -1)
		IF @row_id < 0 BREAK
	
		SELECT @lot_ser = lot_ser, @quantity = quantity
		  FROM #pick_custom_kit_order
		 WHERE row_id = @row_id

		IF ( @quantity < 0 ) -- unpick
		BEGIN
			IF (( SELECT sum(qty)
				FROM lot_bin_ship (NOLOCK) 
			       WHERE tran_no = @order_no 
				 AND tran_ext = @order_ext 
				 AND part_no = @part_no 
				 AND line_no = @line_no 
				 AND lot_ser = @lot_ser 
				 AND kit_flag = 'Y') < -@quantity)
			BEGIN 

				--Error: 'Cannot unpick more than was picked'
	  			SELECT @msg = err_msg 
				  FROM tdc_lookup_error (NOLOCK) 
				 WHERE module   = 'SPR' 
				   AND trans    = 'CUSTKIT' 
				   AND err_no   = -104 
				   AND language = @language
	
				RAISERROR (@msg, 16, 1) 						
				RETURN -104
			END

			SELECT @tot_lb_qty = ABS(@quantity)

			-- if this item was picked from different bins with @lot_ser
			DECLARE un_pick_kit_items CURSOR FOR
				SELECT bin_no, date_expires, qty, date_tran
				  FROM lot_bin_ship (nolock) 	
				 WHERE tran_no = @order_no 
				   AND tran_ext = @order_ext 
				   AND lot_ser = @lot_ser 
				   AND part_no = @part_no 
				   AND line_no = @line_no 
				   AND kit_flag = 'Y' 
				ORDER BY date_tran DESC
			OPEN un_pick_kit_items 
			FETCH NEXT FROM un_pick_kit_items INTO @bin_no, @date_expired, @line_qty, @date_tran
			
			WHILE @@FETCH_STATUS = 0
			BEGIN
				IF @tot_lb_qty > @line_qty
					SELECT @tot_lb_qty = @tot_lb_qty - @line_qty
				ELSE
				BEGIN
					SELECT @line_qty = @tot_lb_qty 
					SELECT @tot_lb_qty  = 0
				END
	
				UPDATE lot_bin_ship 
				   SET qty      = qty - @line_qty, 
				       uom_qty  = (qty - @line_qty) / conv_factor, 
				       who      = @who
				 WHERE tran_no  = @order_no 
				   AND tran_ext = @order_ext 
				   AND line_no  = @line_no 
				   AND part_no  = @part_no 
				   AND lot_ser  = @lot_ser 
				   AND bin_no   = @bin_no 

				DELETE FROM lot_bin_ship
				 WHERE tran_no  = @order_no 
				   AND tran_ext = @order_ext 
				   AND line_no  = @line_no 
				   AND part_no  = @part_no 
				   AND qty     <= 0

				IF (@to_bin != @bin_no)
				BEGIN
					IF EXISTS ( SELECT * FROM #adm_bin_xfer WHERE bin_from = @bin_no AND lot_ser = @lot_ser)
						UPDATE #adm_bin_xfer 
						   SET qty = qty + @line_qty 
						 WHERE bin_from = @bin_no
					ELSE
						INSERT INTO #adm_bin_xfer (location, part_no, lot_ser, bin_from, bin_to, date_expires, qty, who_entered) 
								 VALUES ( @location, @part_no, @lot_ser, @bin_no, @to_bin, @date_expired, @line_qty, @who )

					IF(@tdclog = 'Y')
					BEGIN
						SELECT @msg = 'LP_USER_STAT_ID: ' + @login_id + '; LP_LINE_NO: ' + convert(varchar(5), @line_no) + '; LP_ITEM_DESC: ' + @description + '; LP_LB_TRACKING: ' + @lb_track + '; LP_TO_BIN: ' + @to_bin
			
						INSERT INTO tdc_log (tran_date,UserID,trans_source,module,trans,tran_no,tran_ext,part_no,lot_ser,bin_no,location,quantity,data) 
							VALUES (getdate(), @login_id, 'CO', 'ADH', 'BN2BN', rtrim(ltrim(convert(varchar(10), @order_no))), ltrim(rtrim(convert(varchar(5), @order_ext))), @part_no, @lot_ser, @bin_no, @location, convert(varchar(20), RTRIM(LTRIM(STR(@line_qty, 20, 2)))), @msg)			
					END
				END
	
				IF @tot_lb_qty <= 0 BREAK
	
				FETCH NEXT FROM un_pick_kit_items INTO @bin_no, @date_expired, @line_qty, @date_tran
			END
			DEALLOCATE un_pick_kit_items
	
			IF EXISTS ( SELECT * FROM #adm_bin_xfer )
			BEGIN
				EXEC @err_ret = tdc_bin_xfer
			
				IF @err_ret < 0 RETURN -107
			END

			TRUNCATE TABLE #adm_bin_xfer
		END
		ELSE
		BEGIN	-- pick
			IF NOT EXISTS (SELECT * 
					 FROM lot_bin_stock (NOLOCK) 
					WHERE part_no  = @part_no 
					  AND location = @location 	
					  AND lot_ser  = @lot_ser 
					  AND bin_no   = @bin_no )
			BEGIN
				--Error: 'Invalid Lot/Bin Infomation for Part number %s' 	
	  			SELECT @msg = err_msg 
				  FROM tdc_lookup_error (NOLOCK) 
				 WHERE module   = 'SPR' 
				   AND trans    = 'CUSTKIT' 
				   AND err_no   = -105 
				   AND language = @language
				RAISERROR (@msg, 16, 1, @part_no)					
				RETURN -105
			END
	
			IF NOT EXISTS ( SELECT * 
					  FROM lot_bin_stock (NOLOCK) 
					 WHERE part_no = @part_no 
					   AND location = @location 
					   AND lot_ser = @lot_ser 
					   AND bin_no = @bin_no 
					   AND qty >= @quantity)
			BEGIN
				-- Error: 'There is not enough of item %s in stock' 	
	 			SELECT @msg = err_msg 
				  FROM tdc_lookup_error(NOLOCK) 
				 WHERE module   = 'SPR' 
				   AND trans    = 'CUSTKIT' 
				   AND err_no   = -106 
				   AND language = @language
	
				RAISERROR (@msg, 16, 1, @part_no)					
				RETURN -106
			END

			IF NOT EXISTS (SELECT * 
					 FROM lot_bin_ship (NOLOCK) 
					WHERE tran_no  = @order_no 
					  AND tran_ext = @order_ext 
					  AND line_no  = @line_no 
					  AND part_no  = @part_no 
					  AND lot_ser  = @lot_ser 
					  AND bin_no   = @bin_no )
			BEGIN
				INSERT lot_bin_ship (location, part_no, bin_no, lot_ser, tran_code, tran_no, tran_ext, 
						     date_tran, date_expires, qty, direction, cost, uom, uom_qty, 
						     conv_factor, line_no, who, qc_flag, kit_flag )
				SELECT @location, @part_no, @bin_no, @lot_ser, 'P', @order_no, @order_ext, 
				       GETDATE(), l.date_expires, @quantity, -1, o.cost, @uom, @quantity / @conv_factor, 
				       @conv_factor, @line_no, @who, o.qc_flag, 'Y'
		       		  FROM ord_list_kit  o (NOLOCK), 
				       lot_bin_stock l (NOLOCK) 
		       	         WHERE l.lot_ser   = @lot_ser 
				   AND l.bin_no    = @bin_no 
				   AND l.location  = @location 
				   AND l.part_no   = @part_no
				   AND o.line_no   = @line_no 
				   AND o.order_ext = @order_ext 
				   AND o.order_no  = @order_no 
				   AND o.part_no   = @part_no 
			END
			ELSE
			BEGIN
				UPDATE lot_bin_ship 
				   SET qty      = qty + @quantity, 
				       uom_qty  = (qty + @quantity) / @conv_factor, 
				       who      = @who
				 WHERE tran_no  = @order_no 
				   AND tran_ext = @order_ext 
				   AND line_no  = @line_no 
				   AND part_no  = @part_no 
				   AND lot_ser  = @lot_ser 
				   AND bin_no   = @bin_no 
			END
		END
	END
END
	
UPDATE ord_list_kit 
   SET status = 'P'
 WHERE order_no  = @order_no 
   AND order_ext = @order_ext 
   AND status IN ('N', 'Q')
		
IF ( @length = 0 )
BEGIN   -- is not a substituted item
	SELECT @temp_qty = SUM(kit_picked)
	  FROM tdc_ord_list_kit (NOLOCK)
	 WHERE order_no    = @order_no 
	   AND order_ext   = @order_ext 
	   AND line_no 	   = @line_no 
	   AND kit_part_no = @part_no

	UPDATE tdc_ord_list_kit 
	   SET kit_picked  = kit_picked + @tot_picked, 
	       picked      = (@temp_qty + @tot_picked) / @qty_per -- FLOOR((@temp_qty + @quantity) / @qty_per)
	 WHERE order_no    = @order_no 
	   AND order_ext   = @order_ext 
	   AND kit_part_no = @part_no 
	   AND line_no     = @line_no 
	   AND sub_kit_part_no IS NULL

	SELECT @temp_qty = ISNULL(SUM(kit_picked), 0)
	  FROM tdc_ord_list_kit (NOLOCK)
	 WHERE order_no    = @order_no 
	   AND order_ext   = @order_ext 
	   AND line_no 	   = @line_no 
	   AND kit_part_no = @part_no
	   AND sub_kit_part_no IS NULL

	-- avoid using shipped = shipped + current pick/unpick to update the shipped quantity
	UPDATE ord_list_kit 
	   SET shipped   = @temp_qty / conv_factor / qty_per
	 WHERE order_no  = @order_no 
	   AND order_ext = @order_ext 
	   AND line_no   = @line_no 
	   AND part_no   = @part_no
END
ELSE
BEGIN   -- for substituted item 
	UPDATE tdc_ord_list_kit 
	   SET kit_picked  	= kit_picked + @tot_picked
	 WHERE order_no    	= @order_no 
	   AND order_ext   	= @order_ext 
	   AND kit_part_no 	= @sub_part 
	   AND line_no     	= @line_no 
	   AND sub_kit_part_no 	= @part_no

	SELECT @temp_qty = sum(kit_picked)
	  FROM tdc_ord_list_kit (NOLOCK)  
	 WHERE order_no    = @order_no 
	   AND order_ext   = @order_ext 
	   AND line_no     = @line_no 
	   AND kit_part_no = @sub_part

	UPDATE tdc_ord_list_kit 
	   SET picked      = @temp_qty / @qty_per -- FLOOR(@temp_qty / @qty_per)
	 WHERE order_no    = @order_no 
	   AND order_ext   = @order_ext 
	   AND kit_part_no = @sub_part 
	   AND line_no     = @line_no 
	   AND sub_kit_part_no IS NULL

	SELECT @temp_qty = ISNULL(sum(kit_picked), 0)
	  FROM tdc_ord_list_kit (NOLOCK)
	 WHERE order_no    	= @order_no 
	   AND order_ext   	= @order_ext 
	   AND kit_part_no 	= @sub_part 
	   AND line_no     	= @line_no 
	   AND sub_kit_part_no 	= @part_no

	UPDATE ord_list_kit 
	   SET shipped   = @temp_qty / conv_factor / qty_per
	 WHERE order_no  = @order_no 
	   AND order_ext = @order_ext 
	   AND line_no   = @line_no 
	   AND part_no   = @part_no

	DELETE FROM ord_list_kit 
	 WHERE order_no = @order_no 
	   AND order_ext = @order_ext 
	   AND line_no = @line_no 
	   AND part_no = @part_no 
	   AND shipped = 0
	   AND EXISTS (SELECT * 
			 FROM tdc_ord_list_kit 
			WHERE order_no = @order_no 
			  AND order_ext = @order_ext 
			  AND line_no = @line_no 
			  AND sub_kit_part_no = @part_no 
			  AND kit_picked = 0)

	DELETE FROM tdc_ord_list_kit 
	 WHERE order_no        = @order_no 
	   AND order_ext       = @order_ext 
	   AND kit_part_no     = @sub_part
	   AND line_no         = @line_no 
	   AND sub_kit_part_no = @part_no 
	   AND kit_picked = 0
END

SELECT @kit_shipped = 0, 
       @ord_shipped = 0
	
SELECT @ord_shipped = shipped
  FROM ord_list (NOLOCK)  
 WHERE order_no  = @order_no 
   AND order_ext = @order_ext 
   AND line_no   = @line_no
	
SELECT @kit_shipped = floor(min(picked)/@conv_factor) -- MIN(picked)
  FROM tdc_ord_list_kit (NOLOCK)
 WHERE order_no  = @order_no 
   AND order_ext = @order_ext 
   AND line_no   = @line_no 
   AND sub_kit_part_no IS NULL

UPDATE ord_list 
   SET status = 'P'
 WHERE order_no  = @order_no 
   AND order_ext = @order_ext 
   AND status IN ('N', 'Q')

UPDATE orders 
   SET status     = 'P', 
       printed    = 'P',
       who_picked = @who 
 WHERE order_no   = @order_no 
   AND ext        = @order_ext
   AND status IN ('N', 'Q')

IF ( @kit_shipped <> @ord_shipped )
BEGIN
	UPDATE ord_list 
	   SET shipped   = @kit_shipped
	 WHERE order_no  = @order_no 
	   AND order_ext = @order_ext 
 	   AND line_no   = @line_no

	IF ( @kit_shipped > 0 )
	BEGIN
		SELECT @kit_shipped = @kit_shipped * @conv_factor

		IF EXISTS (SELECT * 
			     FROM tdc_dist_item_pick (NOLOCK) 
			    WHERE order_no   = @order_no 
			      AND order_ext  = @order_ext 
			      AND line_no    = @line_no 
			      AND [function] = 'S')
		BEGIN
			SELECT @kit_shipped = @kit_shipped - ISNULL((SELECT sum(quantity) 
						                       FROM tdc_dist_group g (nolock) 
						       	              WHERE g.[function] = 'S' 
						         	        AND g.child_serial_no IN (SELECT p.child_serial_no 
										     	            FROM tdc_dist_item_pick p (nolock)
										                   WHERE p.order_no  = @order_no 
										                     AND p.order_ext = @order_ext 
								                                     AND p.line_no   = @line_no 
								                                     AND p.[function] = 'S')), 0)
			UPDATE tdc_dist_item_pick 
			   SET quantity   = @kit_shipped -- quantity + @kit_shipped - @ord_shipped
			 WHERE order_no   = @order_no 
			   AND order_ext  = @order_ext 
			   AND line_no    = @line_no 
			   AND [function] = 'S'

			DELETE FROM tdc_dist_item_pick 
			  FROM tdc_dist_item_pick p (nolock)
			 WHERE p.order_no   = @order_no 
			   AND p.order_ext  = @order_ext 
	                   AND p.line_no    = @line_no 
	                   AND p.[function] = 'S'			   
			   AND p.quantity   = 0
			   AND NOT EXISTS (SELECT * 
					     FROM tdc_dist_group g (nolock) 
					    WHERE g.[function] = 'S' 
					      AND p.child_serial_no = g.child_serial_no)
		END
		ELSE
		BEGIN
			UPDATE tdc_dist_next_serial_num
			   SET @serial_no = serial_no = serial_no + 1

			INSERT tdc_dist_item_pick
			VALUES ( @method, @order_no, @order_ext, @line_no, @item, NULL, 
				 NULL, @kit_shipped, @serial_no, 'S', 'O1', NULL )
		END
	END
	ELSE
	BEGIN	-- @kit_shipped = 0
		DELETE FROM tdc_dist_item_pick 
		 WHERE order_no   = @order_no 
		   AND order_ext  = @order_ext 
                   AND line_no    = @line_no 
                   AND [function] = 'S'
	END

	IF OBJECT_ID('tempdb..#adm_taxinfo') IS NOT NULL
		TRUNCATE TABLE #adm_taxinfo

	IF OBJECT_ID('tempdb..#adm_taxtype') IS NOT NULL
		TRUNCATE TABLE #adm_taxtype

	IF OBJECT_ID('tempdb..#adm_taxtyperec') IS NOT NULL
		TRUNCATE TABLE #adm_taxtyperec

	IF OBJECT_ID('tempdb..#adm_taxcode') IS NOT NULL
		TRUNCATE TABLE #adm_taxcode

	IF OBJECT_ID('tempdb..#cents') IS NOT NULL
		TRUNCATE TABLE #cents

	EXEC dbo.fs_calculate_oetax @order_no, @order_ext, @err_ret OUT
	IF @err_ret <> 1 
	BEGIN
		RAISERROR ('SP fs_calculate_oetax failed', 16, 1)
		RETURN -111
	END

	EXEC dbo.fs_updordtots @order_no, @order_ext  	
	IF @@ERROR <> 0 
	BEGIN
		RAISERROR ('SP fs_updordtots failed', 16, 1)
		RETURN -112
	END
END

-- don't lock this table
IF EXISTS (SELECT * 
	     FROM tdc_dist_item_pick (NOLOCK) 
	    WHERE order_no   = @order_no 
	      AND order_ext  = @order_ext 
	      AND [function] = 'S' )
OR EXISTS (SELECT * 
             FROM tdc_ord_list_kit (NOLOCK) 
	    WHERE order_no   = @order_no 
	      AND order_ext  = @order_ext 
	      AND kit_picked > 0 )

	UPDATE tdc_order 
	   SET tdc_status = 'O1' 
	 WHERE order_no   = @order_no 
	   AND order_ext  = @order_ext
ELSE
	UPDATE tdc_order 
	   SET tdc_status = 'Q1' 
	 WHERE order_no   = @order_no 
	   AND order_ext  = @order_ext

UPDATE tdc_dist_item_list 
   SET shipped = adm.shipped * adm.conv_factor
  FROM ord_list adm, tdc_dist_item_list tdc
 WHERE tdc.order_no   = @order_no 
   AND tdc.order_ext  = @order_ext 
   AND tdc.[function] = 'S'
   AND adm.order_no   = @order_no 
   AND adm.order_ext  = @order_ext 
   AND tdc.line_no    = adm.line_no
   AND adm.line_no = @line_no

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[tdc_dist_kit_pick_sp] TO [public]
GO
