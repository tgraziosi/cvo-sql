SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[tdc_pps_validate_quantity_xfer_sp]
	@packing_flg 		int,	
	@user_method		varchar(2),
	@tote_bin		varchar(12),
	@xfer_no		int,
	@carton_no 		int,
	@line_no         	int,
	@location		varchar(10),
	@part_no		varchar(30),
	@uom			varchar(10),
	@lot_ser		varchar(25),
	@bin_no			varchar(12),
	@qty_passed_in		decimal(20,8) OUTPUT,
	@err_msg		varchar(255) OUTPUT 

AS 

DECLARE
	@qty_avail	decimal(24,8),
	@pick_method 	varchar(2),
	@carton_status 	varchar(25),
	@lReturn	int,
	@qty_ordered	decimal(20, 8), --36557
	@qty_shipped	decimal(20, 8), --36557
	@qty_packed 	decimal(24,8),
	@qty_picked 	decimal(24,8),
	@DisplayPart	varchar(50),
	@tote_qty	decimal(24,8),
	@language 	varchar(10),
	@ordered_uom	varchar(10),
	@base_uom	varchar(10),
	@base_conv_factor decimal(20, 8),
	@conv_factor	decimal(20, 8)

	SELECT @language = ISNULL((SELECT Language FROM tdc_sec (nolock) WHERE userid = (SELECT who FROM #temp_who)), 'us_english')

	--Make sure that a valid quantity was entered
	IF (@qty_passed_in <=0)
	BEGIN
		-- @err_msg = 'You must enter a valid quantity'
		SELECT @err_msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_pps_validate_quantity_xfer_sp' AND err_no = -101 AND language = @language 
		RETURN -1
	END


	--Make sure that the carton is not already closed.
	SELECT @carton_status = status 
	  FROM tdc_carton_tx (NOLOCK) 
	 WHERE carton_no      = @carton_no

	IF (@carton_status != 'O' AND ISNULL(@carton_status, '') <> '')
	BEGIN
		-- @err_msg = 'Carton already closed'
		SELECT @err_msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_pps_validate_quantity_xfer_sp' AND err_no = -102 AND language = @language 
		RETURN -1
	END  
 
	--Test for over unpick
	SELECT @qty_ordered = ordered * conv_factor, 
	       @qty_shipped = shipped * conv_factor,
	       @ordered_uom = uom, 
	       @conv_factor = conv_factor
          FROM xfer_list (NOLOCK)
	 WHERE xfer_no      = @xfer_no
	   AND line_no       = @line_no

	-- UOM Conversion
	-- scr 36556
	IF @ordered_uom != @uom 
	BEGIN		
		SELECT @base_uom = uom FROM inv_master(NOLOCK) where part_no = @part_no

		IF @base_uom = @uom
		BEGIN
			SELECT @conv_factor = 1
		END
		ELSE
		BEGIN
			IF EXISTS (SELECT 1 FROM uom_table WHERE item = @part_no AND alt_uom = @uom AND std_uom = @base_uom)  
				SELECT @conv_factor = conv_factor  
				FROM uom_table  
				WHERE item = @part_no
				AND std_uom = @base_uom
				AND alt_uom = @uom
			ELSE  
				SELECT conv_factor  
				FROM uom_table 


				WHERE item = 'STD' 
				AND std_uom = (SELECT uom FROM inv_master WHERE part_no = @part_no) 
				AND alt_uom = @uom
		END
	END

	SELECT @qty_passed_in = @qty_passed_in * @conv_factor 
 
         IF @packing_flg = 1 
        BEGIN					
		IF EXISTS(SELECT * 
			    FROM inv_master(NOLOCK) 
			   WHERE part_no     = @part_no 
			     AND lb_tracking = 'Y')
		BEGIN
			-- lot/bin tracked
			SELECT @qty_picked = ISNULL(SUM(qty),0) 
			  FROM lot_bin_xfer (NOLOCK)
			 WHERE tran_no     = @xfer_no
			   AND tran_ext    = 0
			   AND line_no     = @line_no
			   AND lot_ser     = @lot_ser
			   AND part_no     = @part_no
			--SCR 36532 05-30-06 ToddR
			SELECT @qty_packed = ISNULL(SUM(a.pack_qty),0)
			  FROM tdc_carton_detail_tx a(NOLOCK),
			       tdc_carton_tx b (NOLOCK)
			 WHERE a.carton_no  = b.carton_no
			   AND b.order_type = 'T'
			   AND a.order_no   = @xfer_no
			   AND a.order_ext  = 0
			   AND a.part_no    = @part_no
			   AND a.line_no    = @line_no
			   AND a.lot_ser    = @lot_ser

			 


		END
		ELSE
		BEGIN
			-- non lot/bin tracked
			SELECT @qty_picked = ISNULL(SUM(shipped),0) 
			  FROM xfer_list (NOLOCK)
			 WHERE xfer_no    = @xfer_no
			   AND line_no    = @line_no
			   AND part_no    = @part_no
	
			--SCR 36532 05-30-06 ToddR
			SELECT @qty_packed = ISNULL(SUM(a.pack_qty),0)
			  FROM tdc_carton_detail_tx a(NOLOCK),
			       tdc_carton_tx b (NOLOCK)
			 WHERE a.carton_no  = b.carton_no
			   AND b.order_type = 'T'
			   AND a.order_no   = @xfer_no
			   AND a.order_ext  = 0
			   AND a.part_no    = @part_no
			   AND a.line_no    = @line_no
			   AND a.lot_ser    = @lot_ser
		END
 
		
		IF ((@qty_passed_in + @qty_packed) > @qty_picked)
		BEGIN
		        -- @err_msg = 'Cannot pack more than picked' 
			SELECT @err_msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_pps_validate_quantity_xfer_sp' AND err_no = -103 AND language = @language 
                        RETURN -1
		END

		--If packing from a tote bin, 
		--make sure that there is enough of the part in the tote bin
		IF @tote_bin <> '' 
		BEGIN
			SELECT @tote_qty = ISNULL((SELECT SUM(quantity)
					    FROM tdc_tote_bin_tbl (NOLOCK)
					   WHERE bin_no     	     = @tote_bin
					     AND part_no    	     = @part_no
					     AND line_no    	     = @line_no
					     AND ISNULL(lot_ser, '') = ISNULL(@lot_ser, '')
					     AND order_type = 'T'), 0) 
			IF @tote_qty < @qty_passed_in
			BEGIN
				-- @err_msg = 'Quantity not available in tote bin'
				SELECT @err_msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_pps_validate_quantity_xfer_sp' AND err_no = -104 AND language = @language 
				RETURN -1
			END
		END
        END
	ELSE
	-- If unpacking, make sure that there are enough packed to unpack 

	BEGIN
	 
		SELECT @qty_avail = SUM(pack_qty) 
      		  FROM tdc_carton_detail_tx (NOLOCK)  
      		 WHERE carton_no   = @carton_no
		   AND line_no     = @line_no
		   AND part_no     = @part_no
      		 GROUP BY carton_no, line_no, part_no

		IF (@qty_avail < @qty_passed_in)
		BEGIN
			-- @err_msg = 'Quantity not available to unpack'
			SELECT @err_msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_pps_validate_quantity_xfer_sp' AND err_no = -105 AND language = @language 
			RETURN -1
		END


	END
 

RETURN 1      
GO
GRANT EXECUTE ON  [dbo].[tdc_pps_validate_quantity_xfer_sp] TO [public]
GO
