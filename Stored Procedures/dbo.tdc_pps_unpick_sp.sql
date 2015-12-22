SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROC [dbo].[tdc_pps_unpick_sp]	
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
	@qty_to_unpick		decimal (20,8), 
	@err_msg 		varchar(255) OUTPUT

AS 

DECLARE @part		varchar(30),	
	@bin_qty	decimal(20, 8),
	@err		int,
	@alloc_type	varchar(2),
	@fill_pct	decimal(20,8),
	@qty_ordered	decimal(20,8),
	@q_priority 	int,
	@pack_group	varchar(12),
	@conv_factor	decimal(20, 8),
	@prev_units_picked int,
	@new_units_picked int,
	@unpick_qty	decimal(20, 8)

	-----------------------------------------------------------------------------------------------------------
	-- Clear the tables
	-----------------------------------------------------------------------------------------------------------
	TRUNCATE TABLE #dist_unit_status
	TRUNCATE TABLE #adm_pick_ship
	TRUNCATE TABLE #dist_unit_status
	TRUNCATE TABLE #pick_custom_kit_order

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

	END  

	SELECT @pack_group = group_id 
	  FROM tdc_pack_station_tbl(NOLOCK)
	 WHERE station_id = @station_id
	 
	-- Initialize the part
	IF ISNULL(@kit_item, '') = ''
		SELECT @part = @part_No
	ELSE
		SELECT @part = @kit_item

	-- Initialize the lot/bin variables
	IF ISNULL(@lot_ser, '') != ''
		SELECT @lot_ser = @lot_ser
	ELSE
		SELECT @lot_ser = NULL

	IF ISNULL(@bin_no, '') != ''
		SELECT @bin_no = @bin_no
	ELSE
		SELECT @bin_no = NULL

 
	IF @lot_ser IS NOT NULL 
	BEGIN
		DECLARE unpick_cur CURSOR FOR
			SELECT bin_no, qty from lot_bin_ship 
			 WHERE tran_no = @order_no
			   AND tran_ext = @order_ext
			   AND line_no = @line_no
			   AND part_no = @part
			   AND qty > 0
	END
	ELSE
	BEGIN
		DECLARE unpick_cur CURSOR FOR
			SELECT NULL, @qty_to_unpick
	END

	-----------------------------------------------------------------------------------------------------------
	-- Get the allocation_type, and fill percent
	-----------------------------------------------------------------------------------------------------------
	SELECT @alloc_type = alloc_type 
	  FROM tdc_cons_ords 
	 WHERE order_no = @order_no 
	   AND order_ext = @order_ext 
	   AND location = @location

	IF ISNULL(@kit_item, '') = ''
	BEGIN
		SELECT @qty_ordered = ordered 
		  FROM ord_list 
		 WHERE order_no = @order_no 
		   AND order_ext = @order_ext 
		   AND location = @location 
		   AND line_no = @line_no 
		   AND part_no = @part
	END
	ELSE
	BEGIN
		SELECT @qty_ordered = ordered 
		  FROM ord_list_kit 
		 WHERE order_no = @order_no 
		   AND order_ext = @order_ext 
		   AND location = @location 
		   AND line_no = @line_no 
		   AND part_no = @part
	END
	SELECT @fill_pct = (@qty_to_unpick / @qty_ordered) * 100

	OPEN unpick_cur
	FETCH NEXT FROM unpick_cur INTO @bin_no, @bin_qty

	WHILE @@FETCH_STATUS = 0 AND @qty_to_unpick > 0
	BEGIN

		IF @bin_qty > @qty_to_unpick SELECT @bin_qty = @qty_to_unpick		
	
		-----------------------------------------------------------------------------------------------------------
		--Not a custom kit
		-----------------------------------------------------------------------------------------------------------
		IF @kit_item = '' --Not a custom kit
		BEGIN
			TRUNCATE TABLE #adm_pick_ship
			--Insert part into temp table for picking
			INSERT INTO #adm_pick_ship ( order_no, ext, line_no, part_no, bin_no, lot_ser, location, Date_Exp, qty, err_msg, who)  
			VALUES(@order_no , @order_ext, @line_no, @part_no, @bin_no, @lot_ser, @location, GETDATE(), -@bin_qty, NULL, @user_id)	
		
			IF @@ERROR <> 0
			BEGIN
				CLOSE unpick_cur
				DEALLOCATE unpick_cur
				SELECT @err_msg = 'Insert into #adm_pick_ship failed.'
				RETURN -1
			END
			 
			--Call pick stored procedure
			EXEC @err = tdc_adm_pick_ship
		END
		-----------------------------------------------------------------------------------------------------------
		-- Custom kit
		-----------------------------------------------------------------------------------------------------------
		ELSE -- Custom Kits
		BEGIN
			TRUNCATE TABLE #pick_custom_kit_order
			INSERT INTO #pick_custom_kit_order(method, order_no, order_ext, line_no, location, item, part_no, sub_part_no, 
							lot_ser, bin_no, quantity, who)
			VALUES('01', @order_no, @order_ext, @line_no, @location, @part_no, @kit_item, NULL, @lot_ser, @bin_no,  -@bin_qty, @user_id)
	
		SELECT @prev_units_picked = MIN(kit_picked)
		  FROM tdc_ord_list_kit (NOLOCK)
		 WHERE order_no      = @order_no
		   AND order_ext     = @order_ext
		   AND line_no       = @line_no

			EXEC @err = tdc_dist_kit_pick_sp

			SELECT @new_units_picked = MIN(kit_picked)
			  FROM tdc_ord_list_kit (NOLOCK)
			 WHERE order_no      = @order_no
			   AND order_ext     = @order_ext
			   AND line_no       = @line_no
		END 
	
	    	IF (@@ERROR <> 0) 
	    	BEGIN
			CLOSE unpick_cur
			DEALLOCATE unpick_cur
			SELECT @err_msg = 'Unable to unpick'
			RETURN -1 
	    	END
	        
	
		-----------------------------------------------------------------------------------------------------------
		-- Subtract the item from dist_item_pick
		-----------------------------------------------------------------------------------------------------------
		IF ISNULL(@kit_item, '') = ''
		BEGIN
			UPDATE tdc_dist_item_pick SET quantity = quantity - @bin_qty
			 WHERE order_no   	   = @order_no
			   AND order_ext  	   = @order_ext
			   AND line_no    	   = @line_no
			   AND part_no    	   = @part_no
			   AND ISNULL(lot_ser, '') = ISNULL(@lot_ser, '')
			   AND ISNULL(bin_no, '')  = ISNULL(@bin_no, '')
			   AND [function] 	   = 'S'	
		END	
		ELSE
		BEGIN

			SELECT @unpick_qty = abs(@new_units_picked - @prev_units_picked)

			UPDATE tdc_dist_item_pick SET quantity = quantity - @unpick_qty
			 WHERE order_no   	   = @order_no
			   AND order_ext  	   = @order_ext
			   AND line_no    	   = @line_no
			   AND part_no    	   = @part_no
			   AND [function] 	   = 'S'
		END

		--If quantity <   0, remove it from the table.
		DELETE FROM tdc_dist_item_pick   
		 WHERE order_no   	   = @order_no
		   AND order_ext  	   = @order_ext
		   AND line_no    	   = @line_no
		   AND part_no    	   = @part_no
		   AND ISNULL(lot_ser, '') = ISNULL(@lot_ser, '')
		   AND ISNULL(bin_no, '')  = ISNULL(@bin_no, '')
		   AND [function] 	   = 'S'
		   AND quantity 	   < 0	        
	
		-----------------------------------------------------------------------------------------------------------
		-- Set status of tdc_order back to 'Q1'
		-----------------------------------------------------------------------------------------------------------
	        UPDATE TDC_order  
	  	   SET TDC_status = 'Q1'  
	         WHERE order_no  =  @order_no
	           AND order_ext =  @order_ext
	
	
		-----------------------------------------------------------------------------------------------------------
		-- Re-allocate the item
		-----------------------------------------------------------------------------------------------------------
		IF EXISTS (SELECT * FROM tdc_soft_alloc_tbl  
			    WHERE order_no   = @order_no
			      AND order_ext  = @order_ext
			      AND order_type = 'S'
			      AND location   = @location 
			      AND line_no    = @line_no 
			      AND part_no    = @part 
			      AND ISNULL(lot_ser, '') = ISNULL(@lot_ser, '')
		   	      AND ISNULL(bin_no, '')  = ISNULL(@bin_no, ''))
		BEGIN
			UPDATE tdc_soft_alloc_tbl
			   SET qty = qty  + (@bin_qty * @conv_factor)
		         WHERE order_no   = @order_no 
			   AND order_ext  = @order_ext
		           AND order_type = 'S'
		           AND location   = @location 
		           AND line_no    = @line_no
		           AND part_no    = @part 
			      AND ISNULL(lot_ser, '') = ISNULL(@lot_ser, '')
		   	      AND ISNULL(bin_no, '')  = ISNULL(@bin_no, '')
		END
		ELSE
		BEGIN		
			SELECT @q_priority = 5
			SELECT @q_priority = CAST(value_str AS INT)
			  FROM tdc_config(NOLOCK)
			 WHERE [function] = 'Pick_Q_Priority'
			IF @q_priority IN ('', 0)
				SELECT @q_priority = 5

			INSERT INTO tdc_soft_alloc_tbl(order_no, order_ext, location, line_no, part_no,lot_ser,  
						       bin_no, qty, order_type, target_bin, dest_bin, alloc_type, q_priority)
				SELECT @order_no, @order_ext, @location, @line_no, @part, @lot_ser, @bin_no, @bin_qty * @conv_factor, 'S', @bin_no, @pack_group, @alloc_type, @q_priority
		END 
	
		INSERT INTO tdc_alloc_history_tbl(order_no, order_ext, location, fill_pct, alloc_date, alloc_by, order_type)
			VALUES (@order_no, @order_ext, @location, @fill_pct, getdate(), @user_id, 'S')			

		SELECT @qty_to_unpick = @qty_to_unpick - @bin_qty

		FETCH NEXT FROM unpick_cur INTO @bin_no, @bin_qty
	END

	CLOSE unpick_cur
	DEALLOCATE unpick_cur

	UPDATE tdc_pack_queue 
	   SET picked = picked - (@qty_to_unpick * @conv_factor),
	       last_modified_date = GETDATE(),
	       last_modified_by = @user_id
	 WHERE group_id = @pack_group
	   AND order_no = @order_no
 	   AND order_ext = @order_ext
	   AND line_no = @line_no
	   AND part_no = @part		

	DELETE FROM tdc_pack_queue 
	 WHERE group_id = @pack_group
	   AND order_no = @order_no
 	   AND order_ext = @order_ext
	   AND line_no = @line_no
	   AND part_no = @part		
	   AND picked <= 0


RETURN 0

GO
GRANT EXECUTE ON  [dbo].[tdc_pps_unpick_sp] TO [public]
GO
