SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[tdc_ins_upd_carton_det_rec] 
	@order_no 			int, 
	@order_ext 			int,
	@carton_no			int,
	@line_no			int,
	@part_no 			varchar(30),
	@quantity			decimal(20,8),
	@lot_ser			varchar(25),
	@serial_no			varchar(40),
	@serial_flag			char(1),
	@version_no			varchar(40),
	@warranty_track 		bit,
	@tran_num 			int,
	@err_msg			varchar(255) OUTPUT ,
	@user_id 			varchar (50) = '' ,
	@location 			varchar (10),
	@serial_no_raw			varchar(40) = ''
AS

-- Declare local variables  
DECLARE @cnt 			int,
	@serial_no_track 	varchar(40),
	@mask_code		varchar(15),
	@order_type 		char(1), 
	@to_loc 		varchar(10),
	@qty_to_pack		decimal(24,8)

SELECT @cnt = 0
SELECT @qty_to_pack = 0

SELECT @order_type = order_type 
  FROM tdc_carton_tx (NOLOCK) 
 WHERE carton_no   = @carton_no
   AND order_no    = @order_no
   AND order_ext   = @order_ext

IF (@quantity >= 0)  /* Packing */
BEGIN
	-- Check if record already exists.  If so then simply update.  Otherwise, create new record.
	IF EXISTS(SELECT *
		  FROM tdc_carton_detail_tx (NOLOCK)
		 WHERE carton_no 		 = @carton_no
		   AND order_no			 = @order_no
		   AND order_ext		 = @order_ext
		   AND part_no                   = @part_no
		   AND line_no   		 = @line_no
		   AND ISNULL(lot_ser,       '') = ISNULL(@lot_ser,           '')
		   AND ISNULL(serial_no_raw, '') = ISNULL(@serial_no_raw, '')
		   AND ISNULL(serial_no,     '') = ISNULL(@serial_no,     ''))

	BEGIN
		UPDATE tdc_carton_detail_tx
		   SET pack_qty 		  = pack_qty    + @quantity, 
		       qty_to_pack                = qty_to_pack + @qty_to_pack,
		       version_no		  = @version_no
		 WHERE carton_no 		  = @carton_no
		   AND order_no			  = @order_no
		   AND order_ext		  = @order_ext
		   AND part_no                    = @part_no
		   AND line_no 		  	  = @line_no
		   AND ISNULL(lot_ser,       '')  = ISNULL(@lot_ser,           '')
		   AND ISNULL(serial_no_raw, '')  = ISNULL(@serial_no_raw, '')
		   AND ISNULL(serial_no,     '')  = ISNULL(@serial_no,     '')
	END
	ELSE -- record doesn't exist, go ahead and create a new one.  
	BEGIN
		INSERT INTO tdc_carton_detail_tx 
		            (order_no, order_ext, carton_no, tx_date, line_no, part_no, price, lot_ser, rec_date, bom_line_no,void, 
		             pack_qty, serial_no, status, version_no, tran_num, warranty_track, serial_no_raw, qty_to_pack, pack_tx)
		VALUES      (@order_no, @order_ext, @carton_no, getdate(), @line_no, @part_no, 0, @lot_ser, getdate(), NULL, NULL, 
    		             @quantity, @serial_no, 'O', @version_no, @tran_num, @warranty_track, @serial_no_raw, @qty_to_pack, '')
	END

	IF (@@ERROR <> 0)
	BEGIN 
		SELECT @err_msg = 'Error Update / Insert tdc_carton_detail_tx table.'
		RETURN -1
	END

	-- if serial for part&loc is Inbound/Outbound, increase IO_count by 1
	IF(@serial_flag = 'I')
	BEGIN
		IF @order_type = 'T' 
			SELECT @to_loc = to_loc 
			  FROM xfers (NOLOCK) 
			 WHERE xfer_no = @order_no
		ELSE
			SELECT @to_loc = @location

		UPDATE tdc_serial_no_track 
		   SET IO_Count = IO_Count + 1 , 
		       last_control_type = 'S' ,
		       last_trans = CASE WHEN @order_type = 'S' THEN 'SPACK' 
				         WHEN @order_type = 'T' THEN 'TPACK'
				    END, 
		       last_tx_control_no = @order_no , 
		       date_time          = getdate(),	
		       [user_id]          = @user_id,
		       transfer_location  = @to_loc
		 WHERE serial_no_raw = @serial_no_raw 
		   AND part_no       = @part_no
		   AND lot_ser       = @lot_ser

		IF (@@ERROR <> 0)
		BEGIN 
			SELECT @err_msg = 'Update tdc_serial_no_track table failed.'
			RETURN -2
		END
	END
	ELSE IF @serial_flag = 'O'
	BEGIN
		IF EXISTS (SELECT * FROM tdc_inv_master (nolock) WHERE part_no = @part_no AND tdc_generated = 0)
		BEGIN
			SELECT @mask_code = mask_code FROM tdc_inv_master (nolock) WHERE part_no = @part_no
			INSERT tdc_serial_no_track (location,  transfer_location, part_no, lot_ser,  mask_code, serial_no, serial_no_raw, IO_count, init_control_type, init_trans, init_tx_control_no, last_control_type, last_trans, last_tx_control_no, date_time, [User_id], ARBC_No)
					    SELECT @location, @location, 	 @part_no,   @lot_ser, @mask_code, @serial_no_raw, @serial_no_raw,    2,   @order_type,            @order_type + 'PACK', @order_no, 	       @order_type, 	  @order_type + 'PACK',     @order_no,   getdate(), @user_id, 	NULL						
		END
	END
END
ELSE IF (@quantity < 0) /* Un-packing  we use the serial_no_raw value instead of the serial_no value*/
BEGIN
	-- Check if record exists.  
	IF EXISTS(SELECT *
		    FROM tdc_carton_detail_tx
		   WHERE carton_no 		 = @carton_no
		     AND order_no			 = @order_no
		     AND order_ext		 = @order_ext
		     AND part_no                   = @part_no
		     AND line_no 			 = @line_no
		     AND ISNULL(lot_ser,       '') = ISNULL(@lot_ser,           '')
		     AND ISNULL(serial_no_raw, '') = ISNULL(@serial_no_raw, ''))
	BEGIN
		UPDATE tdc_carton_detail_tx
		   SET pack_qty 		 = pack_qty + @quantity, 
		       status 			 = 'O'
		 WHERE carton_no 		 = @carton_no
		   AND order_no			 = @order_no
		   AND order_ext		 = @order_ext
         	   AND part_no                   = @part_no
		   AND line_no 			 = @line_no
		   AND ISNULL(lot_ser,       '') = ISNULL(@lot_ser,           '')
		   AND ISNULL(serial_no_raw, '') = ISNULL(@serial_no_raw, '')

		IF (@@ERROR <> 0)
		BEGIN 
			SELECT @err_msg = 'Update tdc_carton_detail_tx table failed.'
			RETURN -3
		END

		UPDATE tdc_carton_tx 
		  SET status 		    = 'O',
		       carton_type 	    = NULL,
		       carton_class 	    = NULL,
		       weight 		    = 0,
		       carton_content_value = NULL
		 WHERE carton_no = @carton_no
		   AND order_no  = @order_no
		   AND order_ext = @order_ext

		IF (@@ERROR <> 0)
		BEGIN 
			SELECT @err_msg = 'Update tdc_carton_tx table failed.'
			RETURN -4
		END

		UPDATE tdc_dist_group SET status = 'O' WHERE parent_serial_no = @carton_no	
		
		IF (@@ERROR <> 0)
		BEGIN 
			SELECT @err_msg = 'Update tdc_dist_group table failed.'
			RETURN -6
		END

		DELETE FROM tdc_carton_detail_tx 
		 WHERE carton_no = @carton_no
		   AND order_no  = @order_no
		   AND order_ext = @order_ext
		   AND pack_qty <= 0
 		   
		-- if serial for part&loc is Inbound/Outbound, decrease IO_count by 1
		IF(@serial_flag = 'I')
		BEGIN
			UPDATE tdc_serial_no_track 
			   SET IO_Count = IO_Count + 1, 
			       last_control_type = @order_type ,
			       last_trans = CASE WHEN @order_type = 'S' THEN 'SUNPACK'
				       	         WHEN @order_type = 'T' THEN 'TUNPACK'
				 	    END , 
			       last_tx_control_no = @order_no , 
			       date_time          = getdate(),	
			       [user_id]          = @user_id
			WHERE serial_no_raw = @serial_no_raw
			  AND part_no 	    = @part_no
			  AND lot_ser 	    = @lot_ser

	 		IF (@@ERROR <> 0)
			BEGIN 
				SELECT @err_msg = 'Update tdc_serial_no_track table failed.'
				RETURN -7
			END
		END
		ELSE IF(@serial_flag = 'O')
		BEGIN
			UPDATE tdc_serial_no_track 
			   SET IO_Count = IO_Count + 2, 
			       last_control_type = @order_type ,
			       last_trans = CASE WHEN @order_type = 'S' THEN 'SUNPACK'
				       	         WHEN @order_type = 'T' THEN 'TUNPACK'
				 	    END , 
			       last_tx_control_no = @order_no , 
			       date_time          = getdate(),	
			       [user_id]          = @user_id
			WHERE serial_no_raw = @serial_no_raw
			  AND part_no 	    = @part_no
			  AND lot_ser 	    = @lot_ser

	 		IF (@@ERROR <> 0)
			BEGIN 
				SELECT @err_msg = 'Update tdc_serial_no_track table failed.'
				RETURN -7
			END
		END
		ELSE
		BEGIN
			DELETE FROM tdc_serial_no_track WHERE location = @location and lot_ser = @lot_ser and serial_no = @serial_no_raw and part_no = @part_no
		END
	END
	ELSE
	BEGIN
		/* Record not found, most likely an Invalid S/N or range was specified. */
		SELECT @err_msg = 'Record not found, verify S/N'
		RETURN 1
	END
END -- UnPack

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[tdc_ins_upd_carton_det_rec] TO [public]
GO
