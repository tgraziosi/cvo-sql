SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[tdc_pps_unpack_carton_xfer_sp]
	@serial_flg		int, 
	@user_id       	 	varchar(50),
	@tote_bin		varchar(12),
	@xfer_no		int,
	@carton_no 		int,
	@line_no        	int,
	@part_no  		varchar(30),	
	@location		varchar(10),
	@lot_ser		varchar(25),
	@bin_no_passed_in	varchar(12),	
	@serial_no		varchar(40),
	@version		varchar(40),
	@qty_to_unpack 	  	decimal(24,8),
	@user_method		varchar(3),
	@err_msg		varchar(255) OUTPUT
AS

DECLARE @bin_no		  varchar(12),
	@qty_avail	  decimal(24,8),
	@qty_to_process	  decimal(24,8),
	@qty_processed	  decimal(24,8),
	@parent_serial_no int, 
	@child_serial_no  int,
	--@part_no	  varchar(30),
	@vendor_sn	  char(1),
	@warranty_track	  int,
	@tran_num	  int,
	@ret		  int,
	@carton_qty	  decimal(24,8),
	@lb_tracking	  char(1),
	@kits_packed	  decimal(24,8),
	@kits_unpacked  decimal(24,8),
	@language	varchar(10)

	SELECT @language = ISNULL((SELECT Language FROM tdc_sec (nolock) WHERE userid = (SELECT who FROM #temp_who)), 'us_english')
	SELECT @qty_to_process = @qty_to_unpack
	
	SELECT @lb_tracking = lb_tracking
	  FROM inv_master (NOLOCK)
	 WHERE part_no = @part_no

	-------------------------------------------------------------------------------------------------------------------
	-- Get the serial info
	-------------------------------------------------------------------------------------------------------------------
	IF (@serial_flg = 1)
	BEGIN
	    	SELECT @vendor_sn 	= vendor_sn, 
		       @warranty_track  = warranty_track 
		  FROM tdc_inv_list(NOLOCK)  
	         WHERE part_no  = @part_no 
	           AND location = @Location
	
	   	 --Get the receipt            
	    	SELECT @tran_num = tran_num 
		  FROM tdc_carton_detail_tx (NOLOCK) 
		 WHERE ISNULL(tran_num,'') <> '' 
		   AND serial_no != '' 
		   AND carton_no  = @carton_no
	END --Serialized
	
	
	-------------------------------------------------------------------------------------------------------------------
	-- Update carton detail record(s)
	-------------------------------------------------------------------------------------------------------------------
	SELECT @carton_qty = 0 - @qty_to_unpack
	EXEC @ret = tdc_ins_upd_carton_det_rec  @xfer_no, 0, @carton_no, @line_no, @part_no, 	
						@carton_qty, @lot_ser, '', @vendor_sn, @version, 
						@warranty_track, @tran_num, @err_msg OUTPUT,
				    		@user_id, @location, @serial_no 	    
	IF (@ret <> 0) 
	BEGIN
		-- 'Critical error encountered during unpack operation.'
		SELECT @err_msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_pps_unpack_carton_xfer_sp' AND err_no = -101 AND language = @language 
		RETURN -1
	END
		
	IF EXISTS (SELECT * FROM tdc_inv_list (nolock) WHERE part_no = @part_no AND location = @location AND vendor_sn = 'O')
	BEGIN
		DELETE FROM tdc_serial_no_track WHERE location = @location and lot_ser = @lot_ser and serial_no = @serial_no and part_no = @part_no
	END

	DECLARE un_pack_cur
	 CURSOR FOR 
	
	SELECT a.bin_no, b.quantity, b.parent_serial_no, b.child_serial_no
	  FROM tdc_dist_item_pick a(NOLOCK),
	       tdc_dist_group     b(NOLOCK)
	 WHERE a.order_no   	  	= @xfer_no
	   AND a.order_ext 	  	= 0
	   AND a.line_no   	  	= @line_no
	   AND ISNULL(a.lot_ser, '')	= ISNULL(@lot_ser, '')
	   AND part_no     	  	= @part_no
	   AND a.child_serial_no  	= b.child_serial_no
	   AND b.parent_serial_no 	= @carton_no
	 ORDER BY CASE WHEN ISNULL(a.bin_no, '') 	= ISNULL(@bin_no_passed_in, '')
				THEN 'A' + ISNULL(a.bin_no, '')
				ELSE 'B' + ISNULL(a.bin_no, '')
			END
	OPEN un_pack_cur
	FETCH NEXT FROM un_pack_cur INTO @bin_no, @qty_avail, @parent_serial_no, @child_serial_no
	
	
	
	WHILE @@FETCH_STATUS = 0 AND @qty_to_process > 0
	BEGIN
	
		IF (@qty_to_process <= @qty_avail)
		BEGIN
			UPDATE tdc_dist_group 
			   SET quantity = quantity - @qty_to_process
			 WHERE parent_serial_no = @parent_serial_no 
			   AND child_serial_no  = @child_serial_no
			   AND [function] 	= 'T' 
			   AND method 		= @user_method
	
			UPDATE tdc_dist_item_pick
			   SET quantity = quantity + @qty_to_process
			 WHERE child_serial_no  = @child_serial_no
			   AND [function] 	= 'T'  
			   AND method 		= @user_method
	
			DELETE FROM tdc_dist_group
			 WHERE parent_serial_no = @parent_serial_no 
			   AND child_serial_no  = @child_serial_no 
			   AND quantity 	= 0 
			   AND method 		= @user_method
			   AND [function] 	= 'T'
	
			SELECT @qty_processed = @qty_to_process
			SELECT @qty_to_process = 0
		END
		ELSE
		BEGIN
			DELETE FROM tdc_dist_group
			 WHERE parent_serial_no = @parent_serial_no 
			   AND child_serial_no  = @child_serial_no
			   AND [function] 	= 'T' 
			   AND method 		= @user_method
	
			UPDATE tdc_dist_item_pick
			   SET quantity = quantity + @qty_avail
			 WHERE child_serial_no  = @child_serial_no
			   AND [function] 	= 'T' 
			   AND method 		= @user_method
			
			SELECT @qty_processed  = @qty_avail
			SELECT @qty_to_process = @qty_to_process - @qty_avail
		END		        
		
		IF @tote_bin != ''
		BEGIN
			IF @lb_tracking = 'N'
			BEGIN
				IF EXISTS(SELECT * 
					    FROM tdc_tote_bin_tbl (NOLOCK)
					   WHERE bin_no    = @tote_bin
					     AND order_no  = @xfer_no
					     AND order_ext = 0
					     AND location  = @location
					     AND line_no   = @line_no
					     AND part_no   = @part_no
					     AND lot_ser   IS NULL
					     AND orig_bin  IS NULL)
				BEGIN
					UPDATE tdc_tote_bin_tbl SET quantity = quantity + @qty_processed
					 WHERE bin_no    = @tote_bin
				           AND order_no  = @xfer_no
				     	   AND order_ext = 0
					   AND location  = @location
					   AND line_no   = @line_no
					   AND part_no   = @part_no
					   AND lot_ser   IS NULL
					   AND orig_bin  IS NULL
				END
				ELSE
				BEGIN
					INSERT INTO tdc_tote_bin_tbl (bin_no, order_no, order_ext, location, line_no,
								      part_no, lot_ser, orig_bin, quantity, tran_date, who, order_type)
					VALUES (@tote_bin, @xfer_no, 0, @location, @line_no, @part_no, NULL, 
						NULL, @qty_processed, GETDATE(), @user_id, 'T')
				END	
			END
			ELSE --LB TRACKED
			BEGIN
				IF EXISTS(SELECT * 
					    FROM tdc_tote_bin_tbl (NOLOCK)
					   WHERE bin_no    = @tote_bin
					     AND order_no  = @xfer_no
					     AND order_ext = 0
					     AND location  = @location
					     AND line_no   = @line_no
					     AND part_no   = @part_no
					     AND lot_ser   = @lot_ser
					     AND orig_bin  = @bin_no)
				BEGIN
					UPDATE tdc_tote_bin_tbl SET quantity = quantity + @qty_processed
					 WHERE bin_no    = @tote_bin
				           AND order_no  = @xfer_no
				     	   AND order_ext = 0
					   AND location  = @location
					   AND line_no   = @line_no
					   AND part_no   = @part_no
					   AND lot_ser   = @lot_ser
					   AND orig_bin  = @bin_no
				END
				ELSE
				BEGIN
					INSERT INTO tdc_tote_bin_tbl (bin_no, order_no, order_ext, location, line_no,
								      part_no, lot_ser, orig_bin, quantity, tran_date, who, order_type)
					VALUES (@tote_bin, @xfer_no, 0, @location, @line_no, @part_no, @lot_ser, 
						@bin_no, @qty_processed, GETDATE(), @user_id, 'T'	)
				END	
			END
		END
		FETCH NEXT FROM un_pack_cur INTO @bin_no, @qty_avail, @parent_serial_no, @child_serial_no
	
	END
	CLOSE un_pack_cur
	DEALLOCATE un_pack_cur
	
	-------------------------------------------------------------------------------------------------------------------
	-- Make sure unpack did not fail
	-------------------------------------------------------------------------------------------------------------------
	IF @qty_to_process > 0 
	BEGIN
		-- 'Unpack failed.  Please try again'
		SELECT @err_msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_pps_unpack_carton_xfer_sp' AND err_no = -102 AND language = @language 
		RETURN -1
	END


RETURN 1
GO
GRANT EXECUTE ON  [dbo].[tdc_pps_unpack_carton_xfer_sp] TO [public]
GO
