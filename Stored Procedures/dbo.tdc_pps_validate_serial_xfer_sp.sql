SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[tdc_pps_validate_serial_xfer_sp]
	@packing_flg	INT,
	@xfer_no	INT,
	@carton_no	INT,
	@part_no	VARCHAR(30),
	@line_no	INT,
	@location	VARCHAR(10),
	@lot_ser	VARCHAR(25) OUTPUT,
	@serial_no	VARCHAR(40),
	@err_msg	VARCHAR(255) OUTPUT
AS 

DECLARE @version_flag 	bit
DECLARE @vendor_sn 	CHAR(1)
DECLARE @masked_serial 	VARCHAR(40)
DECLARE @ret		INT
DECLARE @language 	varchar(10),
	@ID_SCAN_SERIAL		int,
	@ID_SERIAL_LOT		int,
	@ID_SERIAL_VERSION	int
 
SELECT @language = ISNULL((SELECT Language FROM tdc_sec (nolock) WHERE userid = (SELECT who FROM #temp_who)), 'us_english')

SELECT @ID_SCAN_SERIAL = field_index FROM tdc_pps_field_index_tbl (NOLOCK)
	WHERE order_type = 'T' AND field_name = 'SCAN_SERIAL'

SELECT @ID_SERIAL_LOT = field_index FROM tdc_pps_field_index_tbl (NOLOCK)
	WHERE order_type = 'T' AND field_name = 'SERIAL_LOT'

SELECT @ID_SERIAL_VERSION = field_index FROM tdc_pps_field_index_tbl (NOLOCK)
	WHERE order_type = 'T' AND field_name = 'SERIAL_VERSION'


	SELECT @language = ISNULL((SELECT Language FROM tdc_sec (nolock) WHERE userid = (SELECT who FROM #temp_who)), 'us_english')

	--Get formatted serial no
	EXEC @ret = tdc_format_serial_mask_sp @part_no, @serial_no, @masked_serial OUTPUT, @err_msg OUTPUT
	IF @ret <> 1 RETURN -1

	--Get version
	SELECT @version_flag = version_capture 
		FROM tdc_inv_list  (NOLOCK)
		WHERE part_no = @part_no
		AND location = @location

	--Find the direction of the serial track
	SELECT @vendor_sn = vendor_sn FROM tdc_inv_list (NOLOCK)
		WHERE location = @location
		AND part_no = @part_no
	


	--If I/O count is even, then part is out of stock
	--if I/O count is odd, part is in stock
	--If unpacking 
	IF (@packing_flg = 0)
	BEGIN
		IF ISNULL((SELECT COUNT(lot_ser)
				FROM tdc_carton_detail_tx a(NOLOCK),
				     tdc_carton_tx b(NOLOCK)	
				       WHERE a.carton_no = @carton_no
				 AND a.order_no = @xfer_no
				 AND a.carton_no = b.carton_no
				 AND b.order_type = 'T'
				 AND a.part_no = @part_no
		   		 AND a.serial_no_raw = @serial_no), 0) > 1
			BEGIN
				RETURN @ID_SERIAL_LOT
			END
			ELSE
				SELECT @lot_ser = lot_ser
				FROM tdc_carton_detail_tx a(NOLOCK),
				     tdc_carton_tx b(NOLOCK)	
				       WHERE a.carton_no = @carton_no
				 AND a.order_no = @xfer_no
				 AND a.carton_no = b.carton_no
				 AND b.order_type = 'T'
				 AND a.part_no = @part_no
		   		 AND a.serial_no_raw = @serial_no

		IF @vendor_sn = 'I'
		BEGIN
			IF NOT EXISTS(SELECT * FROM tdc_serial_no_track (NOLOCK)  
                           		WHERE part_no = @part_no
                           		AND serial_no_raw = @serial_no
                           		AND location = @location
                        		AND last_control_type <> 'Q'  
                       			AND last_trans <> 'STDXPICK'  
                          		AND last_trans <> 'STDXSHVF')
			BEGIN
				-- @err_msg = 'Invalid serial number'
				SELECT @err_msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_pps_validate_serial_xfer_sp' AND err_no = -101 AND language = @language 
				RETURN -2
			END
			IF NOT EXISTS(SELECT * FROM tdc_serial_no_track (NOLOCK)  
                           		WHERE part_no = @part_no
                           		AND serial_no_raw = @serial_no
                           		AND location = @location
                        		AND last_control_type <> 'Q'  
                       			AND last_trans <> 'STDXPICK'  
                          		AND last_trans <> 'STDXSHVF' 
			 		AND io_count % 2 = 0 )
			BEGIN

				-- @err_msg = 'Serial number already in inventory'
				SELECT @err_msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_pps_validate_serial_xfer_sp' AND err_no = -102 AND language = @language 
				RETURN -3
			END
		END
		IF (@vendor_sn = 'O' OR @vendor_sn = 'I')
		BEGIN
			IF NOT EXISTS(SELECT * FROM tdc_carton_detail_tx a (NOLOCK), 
					tdc_carton_tx b(NOLOCK)
                       			WHERE part_no = @part_no
					AND a.carton_no = b.carton_no
					AND b.order_type = 'T'
                           		AND a.serial_no_raw = @serial_no)
			BEGIN
				-- @err_msg = 'Serial number has not been packed'
				SELECT @err_msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_pps_validate_serial_xfer_sp' AND err_no = -103 AND language = @language 
				RETURN -4
			END

			IF NOT EXISTS(SELECT * FROM tdc_carton_detail_tx a(NOLOCK),
					tdc_carton_tx b(NOLOCK)			
                       			WHERE a.part_no = @part_no
					AND a.carton_no = b.carton_no
					AND b.order_type = 'T'
                           		AND a.serial_no_raw = @serial_no
					AND a.carton_no = @carton_no)
			BEGIN
				-- @err_msg = 'Serial number is not in carton'
				SELECT @err_msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_pps_validate_serial_xfer_sp' AND err_no = -104 AND language = @language 
				RETURN -5
			END
		END
	END
	ELSE --Packing
	BEGIN
		

		IF (@vendor_sn = 'I')
		BEGIN
			IF NOT EXISTS(SELECT * FROM tdc_serial_no_track (NOLOCK)  
                           	WHERE part_no = @part_no
                           	AND serial_no_raw = @serial_no
                           	AND location = @location
                        	AND last_control_type <> 'Q'  
                          	AND last_trans <> 'STDXSHVF')
			BEGIN
				-- @err_msg = 'Invalid serial number'
				SELECT @err_msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_pps_validate_serial_xfer_sp' AND err_no = -101 AND language = @language 
				RETURN -6
			END

/*                      	IF EXISTS(SELECT * FROM tdc_carton_detail_tx a(NOLOCK),
				tdc_carton_tx b(NOLOCK)
                      		WHERE a.order_no = @xfer_no
				AND a.carton_no = b.carton_no
				AND b.order_type = 'T'
				AND a.order_ext = 0
                            	AND a.part_no = @part_no
				AND a.
                            	AND a.serial_no_raw = @serial_no)
			BEGIN
				-- @err_msg = 'Serial number already packed'
				SELECT @err_msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_pps_validate_serial_xfer_sp' AND err_no = -105 AND language = @language 
				RETURN -7
			END
*/

			IF NOT EXISTS(SELECT * FROM tdc_serial_no_track (NOLOCK)  
                           	WHERE part_no = @part_no
                           	AND serial_no_raw = @serial_no
                           	AND location = @location
                        	AND last_control_type <> 'Q'  
                       		AND last_trans <> 'STDXPICK'  
                          	AND last_trans <> 'STDXSHVF' 
			 	AND io_count % 2 != 0 )
			BEGIN
				-- @err_msg = 'Serial number not in inventory'
				SELECT @err_msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_pps_validate_serial_xfer_sp' AND err_no = -106 AND language = @language 
				RETURN -8
			END

		END
		IF (@vendor_sn = 'O')
		BEGIN
                      	IF EXISTS(SELECT * FROM tdc_carton_detail_tx a(NOLOCK),
				tdc_carton_tx b(NOLOCK)  
                      		WHERE a.order_no = @xfer_no
				AND a.carton_no = b.carton_no
				AND b.order_type = 'T'
				AND a.order_ext = 0
                            	AND a.part_no = @part_no
                            	AND a.serial_no_raw = @serial_no)
			BEGIN
				-- @err_msg = 'Serial number already packed'
				SELECT @err_msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_pps_validate_serial_xfer_sp' AND err_no = -105 AND language = @language 
				RETURN -9
			END

                     	IF EXISTS(SELECT * FROM tdc_serial_no_track a(NOLOCK) 
                      		WHERE part_no = @part_no
                            	  AND serial_no_raw = @serial_no)
			BEGIN
				-- @err_msg = 'Duplicate serial number: '
				SELECT @err_msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_pps_validate_serial_xfer_sp' AND err_no = -107 AND language = @language 
				SELECT @err_msg = @err_msg + @serial_no
				RETURN -10
			END
		END

		---------------------------------------------------------------------------------------------------
		-- Determine where to go next
		---------------------------------------------------------------------------------------------------
		IF (SELECT COUNT(lot_ser) 
		      FROM tdc_serial_no_track(NOLOCK)
		     WHERE location = @location
		       AND part_no = @part_no
		       AND serial_no_raw = @serial_no
		       AND last_control_type <> 'Q'  
	 	       AND last_trans <> 'STDXPICK'  
	  	       AND last_trans <> 'STDXSHVF'
		       AND lot_ser IN (SELECT lot_ser
					 FROM tdc_dist_item_pick(NOLOCK)
					WHERE order_no = @xfer_no
					  AND line_no = @line_no
					  AND [function] = 'T'
					UNION 
				       SELECT lot_ser
					 FROM lot_bin_xfer(NOLOCK)
					WHERE tran_no = @xfer_no
					  AND line_No = @line_no
					  AND part_no = @part_no)) > 1

		BEGIN
			RETURN @ID_SERIAL_LOT
		END
		ELSE
		BEGIN			 
			SELECT @lot_ser = lot_ser
			  FROM tdc_serial_no_track (NOLOCK)
			 WHERE location = @location
			   AND part_no = @part_no
			   AND serial_no_raw = @serial_no
		           AND lot_ser IN (SELECT lot_ser
					 FROM tdc_dist_item_pick(NOLOCK)
					WHERE order_no = @xfer_no
					  AND line_no = @line_no
					  AND [function] = 'T'
					UNION 
				       SELECT lot_ser
					 FROM lot_bin_xfer(NOLOCK)
					WHERE tran_no = @xfer_no
					  AND part_no = @part_no) 
			 
		END

	END
 

--If version tracked, return version field
--else begin pack/unpack
IF (@version_flag <> 0) AND @packing_flg = 1
	RETURN @ID_SERIAL_VERSION

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[tdc_pps_validate_serial_xfer_sp] TO [public]
GO
