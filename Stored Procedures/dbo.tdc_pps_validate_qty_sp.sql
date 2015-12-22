SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- v1.0 CB 12/05/2011 - Case Part Consolidation
-- v1.1 CB 08/09/2012 - If autopack then do not do the consolidated case validation


CREATE PROCEDURE [dbo].[tdc_pps_validate_qty_sp]	
	@is_packing	char(1),	
	@is_3_step	char(1),
	@carton_no	int,
	@tote_bin	varchar(12),
	@order_no	int,
	@order_ext	int,
	@tran_id	int,
	@part_no	varchar(30), 
	@kit_item	varchar(30),
	@line_no	int,
	@uom		varchar(10),
	@lot_ser	varchar(25),
	@bin_no		varchar(12),
	@qty_passed_in	decimal(20, 8) OUTPUT,
	@err_msg	varchar(255)   OUTPUT

AS

DECLARE
	@qty_avail	decimal(24,8),
	@conv_factor	decimal(20, 8),
	@pick_method 	varchar(2),
	@carton_status 	varchar(25),
	@Part		varchar(30),
	@qty_ordered	decimal(20, 8), --scr 36557
	@qty_shipped	decimal(20, 8), --scr 36557
	@qty_packed 	decimal(24,8),
	@qty_picked 	decimal(24,8),
	@DisplayPart	varchar(50),
	@tote_qty	decimal(24,8),
	@tx_lock	char(1),
	@queue_qty	decimal(24,8),
	@SUCCESS	int,
	@std_uom	varchar(10),
	@ordered_uom	varchar(10),
	@base_uom	varchar(10),
	@base_conv_factor decimal(20, 8)

	-- v1.0
	DECLARE @con_qty	decimal(20,8)

	SELECT @SUCCESS = 0

	--Make sure that a valid quantity was entered
	IF (@qty_passed_in <= 0)
	BEGIN
		SELECT @err_msg = 'You must enter a valid quantity'
		RETURN -1
	END			

	--Make sure that the carton is not already closed.
	SELECT @carton_status = status 
	  FROM tdc_carton_tx (NOLOCK) 
	 WHERE carton_no      = @carton_no

	IF (@carton_status != 'O' AND ISNULL(@carton_status, '') <> '')
	BEGIN
		SELECT @err_msg = 'Carton already closed'
		RETURN -2
	END  

	-- v1.0 - Case Part Consolidation
	-- v1.1 Start - If autopack then do not validate the consolidated cases
	IF NOT EXISTS (SELECT 1 FROM cvo_autopack_carton (NOLOCK) WHERE order_no = @order_no 
				AND order_ext = @order_ext AND part_no = @part_no AND line_no = @line_no)
	BEGIN
		IF EXISTS (SELECT 1 FROM #temp_pps_carton_display WHERE order_no = @order_no 
					AND order_ext = @order_ext AND part_no = @part_no AND line_no = @line_no
					AND con_ref = @line_no) AND @is_packing = 'Y'
		BEGIN
			SET @con_qty = 0.00

			SELECT	@con_qty = con_qty
			FROM	#temp_pps_carton_display 
			WHERE	order_no = @order_no 
			AND		order_ext = @order_ext 
			AND		part_no = @part_no 
			AND		line_no = @line_no
			AND		con_ref = @line_no

			IF @qty_passed_in <> @con_qty
			BEGIN
				SELECT @err_msg = 'You Must Pack the Picked Qty'
				RETURN -11
			END

			RETURN 0

		END
	END -- v1.1 End
 
	-- v1.0 - Case Part Consolidation
	IF EXISTS (SELECT 1 FROM #temp_pps_carton_display WHERE order_no = @order_no 
				AND order_ext = @order_ext AND part_no = @part_no AND line_no = @line_no
				AND con_ref = @line_no) AND @is_packing = 'N'
	BEGIN
		SET @con_qty = 0.00

		SELECT	@con_qty = con_carton_qty
		FROM	#temp_pps_carton_display 
		WHERE	order_no = @order_no 
		AND		order_ext = @order_ext 
		AND		part_no = @part_no 
		AND		line_no = @line_no
		AND		con_ref = @line_no

		IF @qty_passed_in <> @con_qty
		BEGIN
			SELECT @err_msg = 'You Must UnPack the Packed Qty'
			RETURN -12
		END

		RETURN 0

	END


	IF @kit_item = ''
	BEGIN
		SELECT @Part = @part_no

		SELECT @qty_ordered  = ordered * conv_factor, 
		       @qty_shipped  = shipped * conv_factor,
		       @conv_factor  = conv_factor,
		       @ordered_uom  = uom
                  FROM ord_list (NOLOCK)
		 WHERE order_no      = @order_no
		   AND order_ext     = @order_ext
		   AND line_no       = @line_no
	END
 	ELSE --KIT ITEM
	BEGIN
		SELECT @Part = @kit_item
		SELECT @conv_factor  = conv_factor
                  FROM ord_list_kit (NOLOCK)
		 WHERE order_no      = @order_no
		   AND order_ext     = @order_ext
		   AND line_no       = @line_no
		   AND part_no	     = @kit_item

		SELECT @ordered_uom  = uom
                  FROM ord_list (NOLOCK)
		 WHERE order_no      = @order_no
		   AND order_ext     = @order_ext
		   AND line_no       = @line_no

		SELECT @qty_ordered 	= 0
		SELECT @qty_ordered  	= ordered * qty_per_kit
                  FROM tdc_ord_list_kit (NOLOCK)
		 WHERE order_no      	= @order_no
		   AND order_ext     	= @order_ext
		   AND line_no       	= @line_no
		   AND kit_part_no   	= @kit_item 
		   AND sub_kit_part_no IS NULL

		SELECT @qty_shipped 	= 0
		SELECT @qty_shipped  = SUM(kit_picked)
                  FROM tdc_ord_list_kit (NOLOCK)
		 WHERE order_no      = @order_no
		   AND order_ext     = @order_ext
		   AND line_no       = @line_no
		   AND kit_part_no   = @kit_item 
		 GROUP BY order_no, order_ext, line_no, part_no		



	END  

	-- UOM Conversion scr 36556
	IF @ordered_uom != @uom 
	BEGIN		
		SELECT @base_uom = uom FROM inv_master(NOLOCK) where part_no = @part

		IF @base_uom = @uom
		BEGIN
			SELECT @conv_factor = 1
		END
		ELSE
		BEGIN
			IF EXISTS (SELECT 1 FROM uom_table WHERE item = @part AND alt_uom = @uom AND std_uom = @base_uom)  
				SELECT @conv_factor = conv_factor  
				FROM uom_table  
				WHERE item = @part
				AND std_uom = @base_uom
				AND alt_uom = @uom
			ELSE  
				SELECT conv_factor  
				FROM uom_table 


				WHERE item = 'STD' 
				AND std_uom = (SELECT uom FROM inv_master WHERE part_no = @part) 
				AND alt_uom = @uom
		END
	END

	SELECT @qty_passed_in = @qty_passed_in * @conv_factor 


	-- if pickpack is activated and unpicking, make sure that there are enough picked
	IF (@is_3_step = 'Y' AND @is_packing = 'N')
	BEGIN
		IF (@qty_shipped < @qty_passed_in)	
		BEGIN
			SELECT @err_msg = 'Cannot unpick/unpack more items than were picked'
			RETURN -3
		END
	END

	ELSE IF @is_3_step = 'Y' AND EXISTS(SELECT * FROM ord_list(NOLOCK) WHERE order_no = @order_no AND order_ext = @order_ext AND line_no = @line_no AND part_type = 'V')
	BEGIN

		IF (@qty_ordered < (@qty_shipped + @qty_passed_in))
		BEGIN
			SELECT @err_msg = 'Cannot pack more than ordered'
			RETURN -3
		END
	END
 

    	-- if pickpack is activated, make sure we are able to pick the part
	ELSE IF (@is_3_step = 'Y' and @is_packing = 'Y')
	BEGIN
		-- If a queue tran id was passed in, do all validation from the record in the queue
		IF @tran_id > 0
		BEGIN
			IF NOT EXISTS(SELECT * FROM tdc_pick_queue (NOLOCK)
				       WHERE tran_id = @tran_id
				         AND trans_type_no = CAST(@order_no AS VARCHAR)
					 AND trans_type_ext = CAST(@order_ext AS VARCHAR)
					 AND line_no = @line_no
					 AND part_no = @part
					 AND ISNULL(lot, '') = ISNULL(@lot_ser, '')
					 AND ISNULL(bin_no, '') = ISNULL(@bin_no, '')
					 AND tx_lock = '3'
					 AND qty_to_process >= (@qty_passed_in))
			BEGIN
			-- Queue tran id no longer valid, find out why.
	
				SELECT @tx_lock = tx_lock, @queue_qty = qty_to_process
				  FROM tdc_pick_queue (NOLOCK)
			         WHERE tran_id = @tran_id
		
				IF @tx_lock  = 'H'
				BEGIN
					SELECT @err_msg = 'Queue Tran ID on hold'
					RETURN -4
				END
				ELSE IF @qty_passed_in > @queue_qty
				BEGIN
					SELECT @err_msg = 'Quantity cannot be greater than quantity remaining for queue tran ID'
					RETURN -5
				END
				ELSE
				BEGIN
					SELECT @err_msg = 'Queue tran ID no longer valid'
					RETURN -6
				END
			END
			ELSE
			BEGIN
				RETURN @SUCCESS							 
			END
		END
		ELSE
		BEGIN
			SELECT @queue_qty = 0
			SELECT @queue_qty = SUM(qty_to_process)
			  FROM tdc_pick_queue (NOLOCK)
		         WHERE trans_type_no = CAST(@order_no as varchar)
			   AND trans_type_ext = CAST(@order_ext as varchar)
			   AND line_no = @line_no
			   AND part_no = @part
			   AND ISNULL(lot, '') = ISNULL(@lot_ser, '')
			   AND ISNULL(bin_no, '') = ISNULL(@bin_no, '')
			   AND tx_lock IN ('R','3')
			 GROUP BY trans_type_no, trans_type_ext, line_no, part_no, lot, bin_no

			IF (@qty_passed_in) > @queue_qty
			BEGIN
				SELECT @err_msg = 'Quantity cannot be greater than quantity remaining for queue tran ID.  Qty remaining: ' + CAST(@queue_qty AS VARCHAR)
				RETURN -7
			END
			ELSE
				RETURN @SUCCESS			
		END
        END
	ELSE IF (@is_3_step = 'N' AND @is_packing = 'Y')
        BEGIN			
		--if part is a custom kit
		IF @kit_item <> '' 
		BEGIN
			-- custom kit sub-component is specified, perform check for sub-component
			IF EXISTS(SELECT * 
				    FROM inv_master(NOLOCK) 
				   WHERE part_no = @kit_item 
				     AND lb_tracking = 'Y')
			BEGIN
				-- lot/bin tracked
				SELECT @qty_picked = ISNULL(SUM(qty),0) 
				  FROM lot_bin_ship (NOLOCK)
				 WHERE tran_no  = @order_no
				   AND tran_ext = @order_ext
				   AND line_no  = @line_no
				   AND lot_ser  = @lot_ser
				   AND Part_no  = @kit_item	
			END
			ELSE
			BEGIN  -- non lot/bin tracked		
				SELECT @qty_picked = 0
				SELECT @qty_picked = ISNULL(SUM(kit_picked),0)
				  FROM tdc_ord_list_kit (NOLOCK)
				 WHERE order_no    = @order_no 
				   AND order_ext   = @order_ext 
				   AND kit_part_no = @kit_item 
				   AND line_no     = @line_no
				 GROUP BY order_no, order_ext, kit_part_no, line_no
				
			END --non lot/bin tracked

			SELECT @qty_packed  = ISNULL(SUM(a.pack_qty),0)
			  FROM tdc_carton_detail_tx a(NOLOCK),
			       tdc_carton_tx b (NOLOCK)
			 WHERE a.carton_no  = b.carton_no
			   AND b.order_type = 'S'
			   AND a.order_no   = @order_no 
			   AND a.order_ext  = @order_ext 
			   AND a.part_no    = @kit_item
			   AND a.line_no    = @line_no
			   AND a.lot_ser    = @lot_ser

			SELECT @qty_packed  = ISNULL(@qty_packed, 0) + ISNULL(SUM(pack_qty),0)
			  FROM tdc_carton_detail_tx a(NOLOCK),
			       tdc_carton_tx b (NOLOCK)
			 WHERE a.carton_no  = b.carton_no
			   AND b.order_type = 'S'
			   AND a.order_no   = @order_no 
			   AND a.order_ext  = @order_ext 
			   AND a.line_no    = @line_no
			   AND a.lot_ser    = @lot_ser
			   AND a.part_no   IN (SELECT sub_kit_part_no 
					         FROM tdc_ord_list_kit(NOLOCK)
					        WHERE order_no    = @order_no
					          AND order_ext   = @order_ext
					          AND line_no     = @line_no
					          AND ISNULL(sub_kit_part_no, '') <> ''
					          AND kit_part_no = @kit_item)
			 GROUP BY a.carton_no, b.order_type, a.order_no, a.order_ext, a.line_no, a.lot_ser, a.part_no
			 
		END
		ELSE
		BEGIN
			-- item is not a custom kit
			IF EXISTS(SELECT * 
				    FROM inv_master(NOLOCK) 
				   WHERE part_no     = @part_no 
				     AND lb_tracking = 'Y')
			BEGIN
				-- lot/bin tracked
				SELECT @qty_picked = ISNULL(SUM(qty),0) 
				  FROM lot_bin_ship (NOLOCK)
				 WHERE tran_no     = @order_no
				   AND tran_ext    = @order_ext
				   AND line_no     = @line_no
				   AND lot_ser     = @lot_ser
				   AND part_no     = @part_no
	
				SELECT @qty_packed = ISNULL(SUM(pack_qty),0)
				  FROM tdc_carton_detail_tx (NOLOCK)
				 WHERE order_no  = @order_no 
				   AND order_ext = @order_ext 
				   AND part_no   = @part_no
				   AND line_no   = @line_no
				   AND lot_ser   = @lot_ser
			END
			ELSE
			BEGIN
				-- non lot/bin tracked
				SELECT @qty_picked = ISNULL(SUM(shipped * conv_factor),0) 
				  FROM ord_list (NOLOCK)
				 WHERE order_no   = @order_no
				   AND order_ext  = @order_ext
				   AND line_no    = @line_no
				   AND part_no    = @part_no
		
				SELECT @qty_packed = ISNULL(SUM(pack_qty),0)
				  FROM tdc_carton_detail_tx (NOLOCK)
				 WHERE order_no   = @order_no 
				   AND order_ext  = @order_ext 
				   AND part_no    = @part_no
				   AND line_no   = @line_no
			END
		END
 
		IF ((@qty_passed_in + (@qty_packed)) > @qty_picked)
		BEGIN
		        SELECT @err_msg = 'Cannot pack more than picked' 
			RETURN -8
		END

		--If packing from a tote bin, 
		--make sure that there is enough of the part in the tote bin
		IF @tote_bin <> '' 
		BEGIN

			SELECT @tote_qty = ISNULL((SELECT SUM(quantity)
					    FROM tdc_tote_bin_tbl (NOLOCK)
					   WHERE bin_no     	     = @tote_bin
					     AND part_no    	     = @part
					     AND line_no    	     = @line_no
					     AND ISNULL(lot_ser, '') = ISNULL(@lot_ser, '')
					     AND order_type = 'S'), 0) 


			IF @tote_qty < (@qty_passed_in)
			BEGIN

				SELECT @err_msg = 'Quantity not available in tote bin'
				RETURN -9
			END
		END
        END

	-- If unpacking, make sure that there are enough packed to unpack 
	IF (@is_packing = 'N')
	BEGIN
		--If a custom kit
		IF (@kit_item <> '')
		BEGIN
			SELECT @qty_avail = SUM(tcd.pack_qty) 
              		  FROM tdc_ord_list_kit     olk (NOLOCK) , 
			       tdc_carton_detail_tx tcd (NOLOCK)  
              		 WHERE olk.order_no    =  @order_no
              		   AND olk.order_ext   =  @order_ext
              		   AND olk.order_no    = tcd.order_no 
              		   AND olk.order_ext   = tcd.order_ext 
              		   AND olk.kit_Part_no = tcd.part_no 
			   AND olk.line_no     = tcd.line_no
			   AND olk.line_no     = @line_no
			   AND olk.part_no     = @part_no
			   AND olk.kit_part_no = @kit_item
			   AND ISNULL(lot_ser, '') = ISNULL(@lot_ser, '')
              		 GROUP BY tcd.carton_no, olk.part_no, olk.line_no,olk.kit_part_no,olk.qty_per_kit, olk.kit_picked 
		END
		ELSE
		BEGIN
			SELECT @qty_avail = SUM(pack_qty) 
              		  FROM tdc_carton_detail_tx (NOLOCK)  
              		 WHERE carton_no   = @carton_no
			   AND line_no     = @line_no
			   AND part_no     = @part_no
			   AND ISNULL(lot_ser, '') = ISNULL(@lot_ser, '')
              		 GROUP BY carton_no, line_no, part_no

		END		

		IF ((@qty_avail) < @qty_passed_in)
		BEGIN
			SELECT @err_msg = 'Quantity not available to unpack'
			RETURN -10
		END


	END

RETURN @SUCCESS
GO
GRANT EXECUTE ON  [dbo].[tdc_pps_validate_qty_sp] TO [public]
GO
