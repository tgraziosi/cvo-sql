SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROC [dbo].[tdc_pps_pick_sp]
	@tran_id_passed_in	int,
	@user_id 		varchar(50),
	@station_id		varchar(3),
	@order_no 		int,
	@order_ext 		int,
	@part_no 		varchar(30),  
	@kit_item		varchar(30),
	@location 		varchar(10), 
	@lot_ser 		varchar(25), 
	@bin_no 		varchar(12), 
	@line_no 		int, 
	@qty 			decimal (20,8), 
	@err_msg 		varchar(255) OUTPUT

AS 

DECLARE @Cnt	 	int,
	@DateExp 	datetime,
	@SerialNo	int,
	@err		int,
	@temp 		varchar(200),
	@tran_id	int,
	@queue_qty	decimal(24,8),
	@part		varchar(30),
	@lot		varchar(25), 
	@bin		varchar(12),
	@SUCCESS	int,
	@group_id	varchar(12),
	@conv_factor	decimal(20, 8),
	@prev_units_picked int,
	@new_units_picked int,
	@pick_qty	decimal(20, 8)

	SELECT @SUCCESS = 0

	IF @kit_item = ''
	BEGIN
		--Test for over unpick
		SELECT @conv_factor  = conv_factor
                  FROM ord_list (NOLOCK)
		 WHERE order_no      = @order_no
		   AND order_ext     = @order_ext
		   AND line_no       = @line_no
	END
 	ELSE --KIT ITEM
	BEGIN
		SELECT @conv_factor  = conv_factor
                  FROM ord_list_kit (NOLOCK)
		 WHERE order_no      = @order_no
		   AND order_ext     = @order_ext
		   AND line_no       = @line_no
		   AND part_no	     = @kit_item

		SELECT @prev_units_picked = MIN(kit_picked)
		  FROM tdc_ord_list_kit (NOLOCK)
		 WHERE order_no      = @order_no
		   AND order_ext     = @order_ext
		   AND line_no       = @line_no

	END  

	SELECT @group_id = group_id FROM tdc_pack_station_tbl(NOLOCK)
	 WHERE station_id = @station_id

	IF ISNULL(@kit_item, '') = ''
		SELECT @part = @part_no
	ELSE
		SELECT @part = @kit_item


	SELECT TOP 1 @tran_id = tran_id, @queue_qty = qty_to_process
	  FROM tdc_pick_queue
	 WHERE (tran_id = @tran_id_passed_in OR @tran_id_passed_in = 0 )
	   AND trans_type_no  = CAST(@order_no AS VARCHAR)
	   AND trans_type_ext = CAST(@order_ext AS VARCHAR)
	   AND lot 	      = @lot_ser
	   AND bin_no 	      = @bin_no
	   AND line_no 	      = @line_no
	   AND tx_lock	      = 'R'

	--Clear the temp tables
	TRUNCATE TABLE #dist_unit_status
	TRUNCATE TABLE #adm_pick_ship
	TRUNCATE TABLE #dist_unit_status
	TRUNCATE TABLE #pick_custom_kit_order
	
	SELECT @err = 0
	
	--get expiration date if Lot/Bin tracked
	IF (@lot_ser <> '')
	BEGIN
		SELECT @DateExp = date_expires 
		  FROM lot_bin_stock (NOLOCK)
		 WHERE part_no  = @part
		   AND lot_ser  = @lot_ser
		   AND bin_no   = @bin_no
		   AND location = @location   
	END --Lot/bin tracked 
	

	-- Initialize the lot/bin variables
	IF ISNULL(@lot_ser, '') != ''
		SELECT @lot = @lot_ser
	ELSE
		SELECT @lot = NULL

	IF ISNULL(@bin_no, '') != ''
		SELECT @bin = @bin_no
	ELSE
		SELECT @bin = NULL

	IF @kit_item = '' --Not a custom kit
	BEGIN
		--Insert part into temp table for picking
		INSERT INTO #adm_pick_ship ( order_no, ext, line_no, part_no, bin_no, lot_ser, location, Date_Exp, qty, err_msg, who)  
		VALUES(@order_no , @order_ext, @line_no, @part, @bin, @lot, @location, ISNULL(@DateExp, GETDATE()), @qty, NULL, @user_id)	
		
		--Call pick stored procedure
		EXEC @err = tdc_adm_pick_ship
	END
	ELSE -- Custom Kits
	BEGIN
		
		INSERT INTO #pick_custom_kit_order(method, order_no, order_ext, line_no, location, item, part_no, sub_part_no, 
						lot_ser, bin_no, quantity, who)
		VALUES('01', @order_no, @order_ext, @line_no, @location, @part_no, @kit_item, NULL, @lot, @bin, @qty, @user_id)

		EXEC @err = tdc_dist_kit_pick_sp
	END 


	IF (@err < 0) 
	BEGIN
		SELECT @err_msg = 'Critical error encountered during pick operation.'
		RETURN -1 
	END
	
	--If DSF is registered, update the soft_alloc_table    
	IF (@lot_ser <> '') --if lot/bin tracked
	BEGIN
		-- SCR 35671
		--UPDATE tdc_soft_alloc_tbl SET qty = qty - (@qty * @conv_factor)
		UPDATE tdc_soft_alloc_tbl SET qty = qty - @qty
		 WHERE  order_no  =  @order_no
		   AND order_ext  = @order_ext
		   AND line_no    = @line_no
		   AND part_no    = @part
		   AND lot_ser    = @lot_ser
		   AND bin_no     = @bin_no
		   AND order_type = 'S'

		IF (@@ERROR <> 0) 
		BEGIN			
			SELECT @err_msg = 'Update tdc_soft_alloc_tbl failed'	
			RETURN -2
		END
	END
	ELSE --Not lot/bin tracked
	BEGIN
		-- SCR 35671
		-- UPDATE tdc_soft_alloc_tbl SET qty = qty - (@qty * @conv_factor)
		UPDATE tdc_soft_alloc_tbl SET qty = qty - @qty
		 WHERE  order_no  =  @order_no
		   AND order_ext  = @order_ext
		   AND line_no    = @line_no
		   AND part_no    = @part
		   AND order_type = 'S'
		
		IF (@@ERROR <> 0) 
		BEGIN			
			SELECT @err_msg = 'Update tdc_soft_alloc_tbl failed'	
			RETURN -3
		END
	END
	
	--Make sure there are no 0 quantities
	DELETE FROM tdc_soft_alloc_tbl WITH (ROWLOCK)
	 WHERE order_no  =  @order_no
	   AND order_ext  = @order_ext
	   AND line_no    = @line_no
	   AND part_no    = @part
	   AND ISNULL(lot_ser, '')    = ISNULL(@lot_ser, '')
	   AND ISNULL(bin_no, '')     = ISNULL(@bin_no, '')
	   AND order_type = 'S'
           AND qty <= 0 
	
	IF (@@ERROR <> 0)
	BEGIN
		-- 'Critical error encountered during pick operation.'
		SELECT @err_msg = 'Delete from tdc_soft_alloc_tbl failed'
		RETURN -4
	END  
	
	
	--Insert part into temp table
	INSERT INTO #dist_unit_status (order_no, order_ext, new_type) 
	VALUES( @order_no, @order_ext, 'O1')
	
	--call stored procedure for update
	UPDATE tdc_order SET tdc_status = 'O1'
	 WHERE order_no  = @order_no 
	   AND order_ext = @order_ext
	
	IF (@@ERROR <> 0) 
	BEGIN
		SELECT @err_msg = 'Update tdc_order failed'
		RETURN -5
	END
	
	IF ISNULL(@kit_item, '') = ''
	BEGIN
		SELECT @pick_qty = @qty

		--If the record exists in dist_item_pick, update the quantity
		--If not, insert the record into the table
		IF NOT EXISTS(SELECT * FROM tdc_dist_item_pick (NOLOCK) 
			       WHERE order_no   	= @order_no
				 AND order_ext  	= @order_ext
				 AND line_no    	= @line_no
				 AND part_no    	= @part_no
				 AND ISNULL(lot_ser, '')= ISNULL(@lot_ser, '')
				 AND ISNULL(bin_no, '')	= ISNULL(@bin_no, '')
				 AND [function] = 'S')
		BEGIN
			--create new dist_item_pick record
			EXEC @SerialNo = tdc_get_serialno 
			
			IF (@SerialNo < 0)
			BEGIN
				SELECT @err_msg = 'tdc_get_serialno failed.'
				RETURN -6
			END 
		
			IF @pick_qty > 0
			BEGIN
				IF (@lot_ser <> '')--If lot/bin tracked
				BEGIN      
					INSERT INTO tdc_dist_item_pick(method, order_no, order_ext, line_no, part_no, lot_ser, bin_no, quantity, child_serial_no, [function], type)  
					VALUES ('01', @order_no, @order_ext, @line_no, @part_no, @lot_ser, @bin_no, @pick_qty, @SerialNo, 'S', '01')
				END
				ELSE --Not lot/bin tracked
				BEGIN
					INSERT INTO tdc_dist_item_pick(method, order_no, order_ext, line_no, part_no, lot_ser, bin_no, quantity, child_serial_no, [function], type)  
					VALUES ('01', @order_no, @order_ext, @line_no, @part_no, NULL, NULL, @pick_qty, @SerialNo, 'S', '01')
				END    
			END
		END
		ELSE --record exists
		BEGIN		
			IF (@lot_ser <> '') --If lot/bin tracked
			BEGIN
				UPDATE tdc_dist_item_pick SET quantity = quantity +  @pick_qty
				 WHERE order_no =  @order_no
				   AND order_ext = @order_ext
				   AND line_no = @line_no
				   AND part_no = @part_no
				   AND lot_ser = @lot_ser
				   AND bin_no = @bin_no
				   AND [function] = 'S'
			
				IF (@@ERROR <> 0)
				BEGIN
					SELECT @err_msg = 'UPDATE tdc_dist_item_pick failed'
					RETURN -7
				END 
		
			END
			ELSE --Not lot/bin tracked
			BEGIN
			
				UPDATE tdc_dist_item_pick SET quantity = quantity +  @pick_qty
				 WHERE order_no   =  @order_no
				   AND order_ext  = @order_ext
				   AND line_no    = @line_no
				   AND part_no    = @part_no
				   AND [function] = 'S'
				
				IF (@@ERROR <> 0)
				BEGIN
					SELECT @err_msg = 'UPDATE tdc_dist_item_pick failed'
					RETURN -8
				END 
			
			END
		END 	
	END
	ELSE -- Kit Item
	BEGIN

		SELECT @new_units_picked = MIN(kit_picked)
		  FROM tdc_ord_list_kit (NOLOCK)
		 WHERE order_no      = @order_no
		   AND order_ext     = @order_ext
		   AND line_no       = @line_no

		select @pick_qty = @new_units_picked - @prev_units_picked

		--If the record exists in dist_item_pick, update the quantity
		--If not, insert the record into the table
		IF NOT EXISTS(SELECT * FROM tdc_dist_item_pick (NOLOCK) 
			       WHERE order_no   	= @order_no
				 AND order_ext  	= @order_ext
				 AND line_no    	= @line_no
				 AND part_no    	= @part_no
				 AND [function] = 'S')
		BEGIN
			--create new dist_item_pick record
			EXEC @SerialNo = tdc_get_serialno 
			
			IF (@SerialNo < 0)
			BEGIN
				SELECT @err_msg = 'tdc_get_serialno failed.'
				RETURN -6
			END 
		
			IF @pick_qty > 0
			BEGIN
				INSERT INTO tdc_dist_item_pick(method, order_no, order_ext, line_no, part_no, lot_ser, bin_no, quantity, child_serial_no, [function], type)  
				VALUES ('01', @order_no, @order_ext, @line_no, @part_no, NULL, NULL, @pick_qty, @SerialNo, 'S', '01')
			END
		END
		ELSE --record exists
		BEGIN	

			UPDATE tdc_dist_item_pick SET quantity = quantity +  @pick_qty
			 WHERE order_no   =  @order_no
			   AND order_ext  = @order_ext
			   AND line_no    = @line_no
			   AND part_no    = @part_no
			   AND [function] = 'S'
			
			IF (@@ERROR <> 0)
			BEGIN
				SELECT @err_msg = 'UPDATE tdc_dist_item_pick failed'
				RETURN -8
			END 
		END 	
	END
	IF EXISTS(SELECT * FROM tdc_pack_queue(NOLOCK)
		   WHERE group_id = @group_id
		     AND order_no = @order_no
	 	     AND order_ext = @order_ext
		     AND line_no = @line_no
		     AND part_no = @part)
	BEGIN
		-- SCR 35671
		UPDATE tdc_pack_queue 
		--   SET picked = picked + (@qty * @conv_factor),
		SET picked = picked + @qty,
		       last_modified_date = GETDATE(),
		       last_modified_by = @user_id
		 WHERE group_id = @group_id
		   AND order_no = @order_no
	 	   AND order_ext = @order_ext
		   AND line_no = @line_no
		   AND part_no = @part		 
	END
	ELSE
	BEGIN
		INSERT INTO tdc_pack_queue(order_no, order_ext, line_no, part_no, picked, packed, group_id, station_id, last_modified_date, last_modified_by)
		VALUES(@order_no, @order_ext, @line_no, @part, @qty, 0, @group_id, @station_id, GETDATE(), @user_id)
	END
	
	RETURN @SUCCESS


GO
GRANT EXECUTE ON  [dbo].[tdc_pps_pick_sp] TO [public]
GO
