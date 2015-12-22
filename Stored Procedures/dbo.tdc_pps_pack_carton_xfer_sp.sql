SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[tdc_pps_pack_carton_xfer_sp]
	@serial_flg		int, 
	@user_id         	varchar(50),
	@station_id		varchar(10),
	@tote_bin		varchar(12),
	@xfer_no		int,
	@carton_no 		int,
	@line_no         	int,	
	@location		varchar(10),
	@part_no		varchar(30),		
	@lot_ser		varchar(25),
	@bin_no_passed_in	varchar(12),
	@serial_no_raw		varchar(40),
	@version		varchar(40),
	@qty_to_pack		decimal(20,8),
	@user_method		varchar(12),
	@err_msg		varchar(255) OUTPUT 

AS 

DECLARE @receipt	  varchar(30),
	@serial_no	  varchar(40),
	@bin_no		  varchar(12),
	@lb_tracking 	  char(1),
	@vendor_sn	  char(1),
	@warranty_track   bit,
	@ret		  int,
	@child_serial_no  int,
	@qty_avail	  decimal(20,8),
	@qty_to_process	  decimal(20,8),
	@qty_processed    decimal(20,8),
	@kits_packed	  decimal(20,8),
	@new_kits_packed  decimal(20,8),
	@language	  varchar(10)

SELECT @language = ISNULL((SELECT Language FROM tdc_sec (nolock) WHERE userid = (SELECT who FROM #temp_who)), 'us_english')

--------------------------------------------------------------------------------------------------------------------
-- Determine if lb tracked
--------------------------------------------------------------------------------------------------------------------
SELECT @lb_tracking = lb_tracking
  FROM inventory (NOLOCK)
 WHERE part_no = @part_no

--------------------------------------------------------------------------------------------------------------------
-- Get vendor_sn
--------------------------------------------------------------------------------------------------------------------
SELECT @vendor_sn = vendor_sn
  FROM tdc_inv_list (NOLOCK)
 WHERE location = @location
   AND part_no  = @part_no

--------------------------------------------------------------------------------------------------------------------
-- Determine if lb tracked
--------------------------------------------------------------------------------------------------------------------
--Check if Carton Header record exists. 
IF NOT EXISTS(SELECT * FROM tdc_carton_tx (NOLOCK) 
	       WHERE order_no   = @xfer_no
	         AND order_ext  = 0
		 AND carton_no  = @carton_no
		 AND order_type = 'T')

BEGIN
	--Refresh the carton header record in case the Order information has changed
	EXEC @ret = tdc_refresh_carton_sp @carton_no
	
	IF @ret <> 0
	BEGIN
		-- 'SP tdc_refresh_carton_sp failed.'
		SELECT @err_msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_pps_pack_carton_xfer_sp' AND err_no = -101 AND language = @language
		RETURN -1
	END
	
	INSERT INTO tdc_carton_tx (order_no, order_ext, carton_no, carton_type, carton_class, cust_code, cust_po, 
		carrier_code, shipper, ship_to_no, [name], address1, address2, address3, city, state, zip, 
		country, attention, date_shipped, weight, weight_uom, cs_tx_no, cs_tracking_no, cs_zone, 
		cs_oversize, cs_call_tag_no, cs_airbill_no, cs_other, cs_pickup_no, cs_dim_weight, 
		cs_published_freight, cs_disc_freight, cs_estimated_freight, cust_freight, freight_to, 
		adjust_rate, template_code, operator, consolidated_pick_no, void, status, station_id, 
		charge_code, bill_to_key, last_modified_date, modified_by, order_type, stlbin_no, stl_status)      
  SELECT @xfer_no, 0, @carton_no, 0, '', ISNULL(o.cust_code, ''), NULL, o.routing, '',  
	       '', o.to_loc_name, o.to_loc_addr1, o.to_loc_addr2,  
	       o.to_loc_addr3, b.city, b.state,  
	       b.zip, b.country, o.attention, o.date_shipped, 0, 'LB',  
	       '', '', NULL, '', '', NULL, NULL, '', NULL, NULL, NULL, NULL,  
	       NULL, NULL, NULL , '',@user_id, 0 , '0',  
	       'O', @station_id, o.freight_type, NULL, getdate(), @user_id,  
	       'T', '', 'N' 
	  FROM xfers o,
	       tdc_xfers b
	 WHERE o.xfer_no = @xfer_no
	   AND o.xfer_no = b.xfer_no   
 
	IF @@ERROR <> 0
	BEGIN
		-- 'Insert into tdc_carton_tx failed.'
		SELECT @err_msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_pps_pack_carton_xfer_sp' AND err_no = -102 AND language = @language
		RETURN -1
	END
	
END --Carton header exists

--------------------------------------------------------------------------------------------------------------------
-- Get Warranty tracking
--------------------------------------------------------------------------------------------------------------------
IF EXISTS(SELECT * 
	    FROM tdc_inv_list (NOLOCK)
	   WHERE location = @location
	     AND part_no  = @part_no
	     AND warranty_track = 1)
	SELECT @warranty_track = 1
ELSE
	SELECT @warranty_track = 0

--------------------------------------------------------------------------------------------------------------------
-- Get receipt/tran_no
--------------------------------------------------------------------------------------------------------------------
SELECT @Receipt = tran_num 
  FROM tdc_carton_detail_tx (NOLOCK) 
 WHERE ISNULL(tran_num, '') <> '' 
   AND serial_no <> '' 
   AND carton_no = @carton_no

--------------------------------------------------------------------------------------------------------------------
-- NON LOT/BIN TRACKED PARTS OR PICK/PACK (Not from multiple bins)
--------------------------------------------------------------------------------------------------------------------
IF @lb_tracking = 'N' 
BEGIN
    	EXEC @ret = tdc_ins_upd_carton_det_rec @xfer_no, 0, @carton_no, @line_no, @part_no, @qty_to_pack, 
						   @lot_ser, @serial_no_raw, @vendor_sn, @version, @warranty_track, @receipt, 
						   @err_msg OUTPUT, @user_id, @location, @serial_no_raw 

	SELECT @child_serial_no = child_serial_no	
	  FROM tdc_dist_item_pick (NOLOCK)
 	 WHERE method    		= @user_method	
	   AND order_no  		= @xfer_no
	   AND order_ext 		= 0
	   AND line_no   		= @line_no
	   AND part_no   		= @part_no
	   AND ISNULL(lot_ser, '')	= ISNULL(@lot_ser, '')
	   AND ISNULL(bin_no,  '')	= ISNULL(@bin_no_passed_in,  '')
	   AND [function]		= 'T'


	IF EXISTS(SELECT * 
		    FROM tdc_dist_group (NOLOCK)
		   WHERE parent_serial_no = @carton_no
		     AND child_serial_no  = @child_serial_no
		     AND [function]       = 'T'
		     AND method		  = @user_method)
	BEGIN
		UPDATE tdc_dist_group 
		   SET quantity = quantity + @qty_to_pack
		 WHERE parent_serial_no = @carton_no 
		   AND child_serial_no  = @child_serial_no
		   AND [function] 	= 'T' 
		   AND method 		= @user_method
	END
	ELSE
	BEGIN	
		INSERT tdc_dist_group (method, type, parent_serial_no, child_serial_no, quantity, status, [function])
		VALUES (@user_method, 'N1', @carton_no, @child_serial_no, @qty_to_pack, 'O', 'T')
	END
		
	UPDATE tdc_dist_item_pick
	   SET quantity = quantity - @qty_to_pack
	 WHERE child_serial_no  = @child_serial_no
	   AND [function] 	= 'T'  
	   AND method 		= @user_method	
 
	UPDATE tdc_tote_bin_tbl SET quantity = quantity - @qty_to_pack
	 WHERE bin_no    = @tote_bin
           AND order_no  = @xfer_no
     	   AND order_ext = 0
	   AND location  = @location
	   AND line_no   = @line_no
	   AND part_no   = @part_no
	   AND lot_ser   IS NULL
	   AND orig_bin  IS NULL
		
	DELETE FROM tdc_tote_bin_tbl 
	 WHERE quantity = 0
	   AND bin_no    = @tote_bin
           AND order_no  = @xfer_no
     	   AND order_ext = 0
	   AND location  = @location
	   AND line_no   = @line_no
	   AND part_no   = @part_no
	   AND lot_ser   IS NULL
	   AND orig_bin  IS NULL
 
END
ELSE
--------------------------------------------------------------------------------------------------------------------
-- LOT/BIN TRACKED PARTS NOT PICK/PACK (Use cursor to pack from multiple bins)
--------------------------------------------------------------------------------------------------------------------
BEGIN

	SELECT @qty_to_process = @qty_to_pack

	DECLARE pack_cur 
	 CURSOR FOR 
		SELECT child_serial_no, bin_no, quantity
		  FROM tdc_dist_item_pick (NOLOCK)
	 	 WHERE method    	= @user_method	
		   AND order_no  	= @xfer_no
		   AND order_ext 	= 0
		   AND line_no   	= @line_no
		   AND part_no   	= @part_no
		   AND lot_ser		= @lot_ser 
		   AND [function]	= 'T'

	OPEN pack_cur
	FETCH NEXT FROM pack_cur INTO @child_serial_no, @bin_no, @qty_avail

	WHILE @@FETCH_STATUS = 0 AND @qty_to_process > 0
	BEGIN

		IF @qty_to_process <= @qty_avail
		BEGIN
			SELECT @qty_processed = @qty_to_process
			SELECT @qty_to_process = 0
		END	
		ELSE
		BEGIN
			SELECT @qty_processed = @qty_avail
			SELECT @qty_to_process = @qty_to_process - @qty_avail
		END	

		IF EXISTS(SELECT * 
			    FROM tdc_dist_group (NOLOCK)
			   WHERE parent_serial_no = @carton_no
			     AND child_serial_no  = @child_serial_no
			     AND [function]       = 'T'
			     AND method		  = @user_method)
		BEGIN
			UPDATE tdc_dist_group 
			   SET quantity = quantity + @qty_processed
			 WHERE parent_serial_no = @carton_no 
			   AND child_serial_no  = @child_serial_no
			   AND [function] 	= 'T' 
			   AND method 		= @user_method
		END
		ELSE
		BEGIN	
			INSERT tdc_dist_group (method, type, parent_serial_no, child_serial_no, quantity, status, [function])
			VALUES (@user_method, 'N1', @carton_no, @child_serial_no, @qty_processed, 'O', 'T')
		END
			
		UPDATE tdc_dist_item_pick
		   SET quantity = quantity - @qty_processed
		 WHERE child_serial_no  = @child_serial_no
		   AND [function] 	= 'T'  
		   AND method 		= @user_method

		UPDATE tdc_tote_bin_tbl SET quantity = quantity - @qty_processed
		 WHERE bin_no    = @tote_bin
	           AND order_no  = @xfer_no
	     	   AND order_ext = 0
		   AND location  = @location
		   AND line_no   = @line_no
		   AND part_no   = @part_no
		   AND lot_ser   = @lot_ser
		   AND orig_bin  = @bin_no
			
		DELETE FROM tdc_tote_bin_tbl 
		 WHERE quantity = 0
		   AND bin_no    = @tote_bin
	           AND order_no  = @xfer_no
	     	   AND order_ext = 0
		   AND location  = @location
		   AND line_no   = @line_no
		   AND part_no   = @part_no
		   AND lot_ser   = @lot_ser
		   AND orig_bin  = @bin_no

	    	EXEC @ret = tdc_ins_upd_carton_det_rec @xfer_no, 0, @carton_no, @line_no, @part_no, @qty_processed, 
						       @lot_ser, @serial_no_raw, @vendor_sn, @version, @warranty_track, @receipt, 
						       @err_msg OUTPUT, @user_id, @location, @serial_no_raw 
	
		FETCH NEXT FROM pack_cur INTO @child_serial_no, @bin_no, @qty_avail
	END

	CLOSE pack_cur
	DEALLOCATE pack_cur
END

RETURN 1
GO
GRANT EXECUTE ON  [dbo].[tdc_pps_pack_carton_xfer_sp] TO [public]
GO
