SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- v1.0 CB 11/05/2011 - Case Part Consolidation
-- v1.1 CB 14/06/2012 - Call freight recalc for all packs
-- v1.2 CT 26/06/2013 - Issue #1308 - Don't calculate freight for ST or DO orders

CREATE PROC [dbo].[tdc_pps_scan_sp]
	@scanned_index		int,
	@is_one_order_per_ctn	char(1),
	@is_packing		char(1),
	@is_auto_qty		char(1),
	@is_cube_active		char(1),
	@is_using_tote_bins	char(1),
	@auto_lot		varchar(25),
	@auto_bin		varchar(12),
	@user_id		varchar(50),
	@station_id		varchar(3),
	@carton_no		int		OUTPUT,
	@tote_bin		varchar(12)	OUTPUT,	
	@carton_code		varchar(10)	OUTPUT,
	@pack_type		varchar(10)	OUTPUT,
	@order_no		int		OUTPUT,
	@order_ext		int		OUTPUT,
	@total_cartons		int		OUTPUT,
	@tran_id		int		OUTPUT,
	@part_no		varchar(30)     OUTPUT,
	@kit_item		varchar(30)	OUTPUT,
	@line_no		int		OUTPUT,
	@location		varchar(10)	OUTPUT,
	@lot_ser		varchar(25)	OUTPUT,
	@bin_no			varchar(12)	OUTPUT,
	@serial_no		varchar(40)	OUTPUT,
	@version		varchar(40)	OUTPUT,
	@qty			decimal(20, 8)  OUTPUT,
	@uom			varchar(10) 	OUTPUT,
	@err_msg		varchar(255)	OUTPUT

AS
 
DECLARE 	
	@language		varchar(10),
	@ret			int,
	@is_3_step		char(1), 
	@part			varchar(30),

	--FIELD INDEXES TO BE RETURNED TO VB
	@ID_TOTE_BIN 	   	int,
	@ID_ORDER	   	int,
	@ID_CARTON_NO	   	int,
	@ID_TOTAL_CARTONS 	int,
	@ID_CARTON_CODE		int,
	@ID_PACK_TYPE		int,
	@ID_QTX			int,
	@ID_PART_NO		int,
	@ID_KIT_ITEM		int,		
	@ID_LOCATION		int,
	@ID_LOT	 	 	int,
	@ID_BIN		 	int,
	@ID_UOM			int,
	@ID_VERSION		int,	
	@ID_QUANTITY		int,
	@ID_AUTO_SCAN_QTY	int,
	@ID_LINE_NO		int,
	@ID_SERIAL_NO		int,
	@ID_SERIAL_LOT		int,
	@ID_SERIAL_VERSION	int,	
	@ID_SCAN_SERIAL		int,
	@ID_PACK_UNPACK_SUCCESS int

	-- v1.0
	DECLARE @actual_qty	decimal(20,8),
			@con_rec	int
	-- v1.0
	DECLARE @con_line		int,
			@con_last_line	int,
			@con_qty		decimal(20,0)



SELECT @language = ISNULL((SELECT Language FROM tdc_sec (nolock) WHERE userid = (SELECT who FROM #temp_who)), 'us_english')

----------------------------------------------------------------------------------------------------------------------------
--Set the values of the field indexes
----------------------------------------------------------------------------------------------------------------------------
SELECT @ID_TOTE_BIN = field_index FROM tdc_pps_field_index_tbl (NOLOCK)
	WHERE order_type = 'S' AND field_name = 'TOTE_BIN'

SELECT @ID_ORDER = field_index FROM tdc_pps_field_index_tbl (NOLOCK)
	WHERE order_type = 'S' AND field_name = 'ORDER'

SELECT @ID_CARTON_NO = field_index FROM tdc_pps_field_index_tbl (NOLOCK)
	WHERE order_type = 'S' AND field_name = 'CARTON_NO'

SELECT @ID_TOTAL_CARTONS = field_index FROM tdc_pps_field_index_tbl (NOLOCK)
	WHERE order_type = 'S' AND field_name = 'TOTAL_CARTONS'

SELECT @ID_CARTON_CODE = field_index FROM tdc_pps_field_index_tbl (NOLOCK)
	WHERE order_type = 'S' AND field_name = 'CARTON_CODE'

SELECT @ID_PACK_TYPE = field_index FROM tdc_pps_field_index_tbl (NOLOCK)
	WHERE order_type = 'S' AND field_name = 'PACK_TYPE'

SELECT @ID_QTX = field_index FROM tdc_pps_field_index_tbl (NOLOCK)
	WHERE order_type = 'S' AND field_name = 'QTX'

SELECT @ID_PART_NO = field_index FROM tdc_pps_field_index_tbl (NOLOCK)
	WHERE order_type = 'S' AND field_name = 'PART_NO'

SELECT @ID_KIT_ITEM = field_index FROM tdc_pps_field_index_tbl (NOLOCK)
	WHERE order_type = 'S' AND field_name = 'KIT_ITEM'

SELECT @ID_LOCATION = field_index FROM tdc_pps_field_index_tbl (NOLOCK)
	WHERE order_type = 'S' AND field_name = 'LOCATION'

SELECT @ID_LOT = field_index FROM tdc_pps_field_index_tbl (NOLOCK)
	WHERE order_type = 'S' AND field_name = 'LOT'

SELECT @ID_BIN = field_index FROM tdc_pps_field_index_tbl (NOLOCK)
	WHERE order_type = 'S' AND field_name = 'BIN'

SELECT @ID_VERSION = field_index FROM tdc_pps_field_index_tbl (NOLOCK)
	WHERE order_type = 'S' AND field_name = 'VERSION'


SELECT @ID_UOM = field_index FROM tdc_pps_field_index_tbl (NOLOCK)
	WHERE order_type = 'S' AND field_name = 'UOM'

SELECT @ID_QUANTITY = field_index FROM tdc_pps_field_index_tbl (NOLOCK)
	WHERE order_type = 'S' AND field_name = 'QTY'

SELECT @ID_AUTO_SCAN_QTY = field_index FROM tdc_pps_field_index_tbl (NOLOCK)
	WHERE order_type = 'S' AND field_name = 'AUTO_SCAN_QTY'

SELECT @ID_LINE_NO = field_index FROM tdc_pps_field_index_tbl (NOLOCK)
	WHERE order_type = 'S' AND field_name = 'LINE_NO'

SELECT @ID_SERIAL_NO = field_index FROM tdc_pps_field_index_tbl (NOLOCK)
	WHERE order_type = 'S' AND field_name = 'SERIAL_NO'

SELECT @ID_SERIAL_LOT = field_index FROM tdc_pps_field_index_tbl (NOLOCK)
	WHERE order_type = 'S' AND field_name = 'SERIAL_LOT'

SELECT @ID_SERIAL_VERSION = field_index FROM tdc_pps_field_index_tbl (NOLOCK)
	WHERE order_type = 'S' AND field_name = 'SERIAL_VERSION'

SELECT @ID_SCAN_SERIAL = field_index FROM tdc_pps_field_index_tbl (NOLOCK)
	WHERE order_type = 'S' AND field_name = 'SCAN_SERIAL'

SELECT @ID_PACK_UNPACK_SUCCESS = field_index FROM tdc_pps_field_index_tbl (NOLOCK)
	WHERE order_type = 'S' AND field_name = 'PACK_UNPACK_SUCCESS'

 
	IF @kit_item != ''
		SELECT @part = @kit_item
	ELSE
		SELECT @part = @part_no
	
----------------------------------------------------------------------------------------------------------------------------
-- Determine if the order was 3 step or 4 step
----------------------------------------------------------------------------------------------------------------------------
IF @order_no > 0
BEGIN
	IF EXISTS(SELECT * 
		    FROM tdc_cons_ords (NOLOCK)
		   WHERE order_no = @order_no
		     AND order_ext = @order_ext
	 	     AND alloc_type = 'PP')
	BEGIN
		SELECT @is_3_step = 'Y'
	END
	ELSE
		SELECT @is_3_step = 'N'


END
ELSE
	SELECT @is_3_step = 'N'

----------------------------------------------------------------------------------------------------------------------------
-- Validate the Tote Bin
----------------------------------------------------------------------------------------------------------------------------
IF @scanned_index = @ID_TOTE_BIN
BEGIN
	EXEC @ret = tdc_pps_validate_tote_sp @is_packing, @is_one_order_per_ctn, @carton_no, @tote_bin, @order_no OUTPUT, @order_ext OUTPUT, @err_msg OUTPUT 
END

----------------------------------------------------------------------------------------------------------------------------
-- Validate the Carton
----------------------------------------------------------------------------------------------------------------------------
IF @scanned_index = @ID_CARTON_NO
BEGIN
	EXEC @ret = tdc_pps_validate_carton_sp @is_one_order_per_ctn, @is_packing, @is_using_tote_bins, @carton_no, @order_no, @order_ext, @total_cartons OUTPUT, @carton_code OUTPUT, @pack_type OUTPUT, @err_msg OUTPUT
END

----------------------------------------------------------------------------------------------------------------------------
-- Validate the Carton Code
----------------------------------------------------------------------------------------------------------------------------
IF @scanned_index = @ID_CARTON_CODE
BEGIN
	EXEC @ret = tdc_pps_validate_carton_code_sp @is_packing, @is_3_step, @carton_no, @carton_code OUTPUT, @err_msg OUTPUT
END 

----------------------------------------------------------------------------------------------------------------------------
-- Validate the pack type
----------------------------------------------------------------------------------------------------------------------------
IF @scanned_index = @ID_PACK_TYPE
BEGIN
	EXEC @ret = tdc_pps_validate_pack_type_sp @is_packing, @is_3_step, @carton_no, @pack_type OUTPUT, @err_msg OUTPUT
END 

----------------------------------------------------------------------------------------------------------------------------
-- Validate the Order
----------------------------------------------------------------------------------------------------------------------------
IF @scanned_index = @ID_ORDER
BEGIN
	EXEC @ret = tdc_pps_validate_order_sp @is_one_order_per_ctn, @is_packing, @carton_no, @tote_bin, @order_no, @order_ext, @total_cartons OUTPUT, @carton_code OUTPUT, @pack_type OUTPUT, @err_msg OUTPUT
END

----------------------------------------------------------------------------------------------------------------------------
-- Validate the total cartons
----------------------------------------------------------------------------------------------------------------------------
IF @scanned_index = @ID_TOTAL_CARTONS
BEGIN
	EXEC @ret = tdc_pps_validate_carton_total_sp @is_packing, @is_3_step, @carton_no, @order_no, @order_ext, @total_cartons OUTPUT, @carton_code OUTPUT, @pack_type OUTPUT, @err_msg OUTPUT
END


----------------------------------------------------------------------------------------------------------------------------
-- Validate the qtx
----------------------------------------------------------------------------------------------------------------------------
IF @scanned_index = @ID_QTX
BEGIN
	EXEC @ret = tdc_pps_validate_tran_id_sp @is_packing, @tote_bin, @order_no, @order_ext, @tran_id, @part_no OUTPUT, @kit_item OUTPUT, @uom OUTPUT, @line_no OUTPUT, @location OUTPUT, @lot_ser OUTPUT, @bin_no OUTPUT, @err_msg OUTPUT
END

----------------------------------------------------------------------------------------------------------------------------
-- Validate the part
----------------------------------------------------------------------------------------------------------------------------
IF @scanned_index = @ID_PART_NO
BEGIN
	--Make sure carton_no is not '0'
	IF (@carton_no <= 0)
	BEGIN
		SELECT @err_msg = 'Invalid Carton Number'
		RETURN -1
	END

	EXEC @ret = tdc_pps_validate_part_sp 'Y', @is_packing, @is_3_step, @carton_no, @tote_bin, @order_no, @order_ext, @auto_lot, @auto_bin, @tran_id, @part_no OUTPUT, @kit_item OUTPUT, @line_no OUTPUT, @location OUTPUT, @uom OUTPUT, @lot_ser OUTPUT, @bin_no OUTPUT, @err_msg OUTPUT
END

----------------------------------------------------------------------------------------------------------------------------
-- Validate the line
----------------------------------------------------------------------------------------------------------------------------
IF @scanned_index = @ID_LINE_NO
BEGIN
	EXEC @ret = tdc_pps_validate_part_sp 'N', @is_packing, @is_3_step, @carton_no, @tote_bin, @order_no, @order_ext, @auto_lot, @auto_bin, @tran_id, @part_no OUTPUT, @kit_item OUTPUT, @line_no OUTPUT, @location OUTPUT, @uom OUTPUT, @lot_ser OUTPUT, @bin_no OUTPUT, @err_msg OUTPUT	
END

----------------------------------------------------------------------------------------------------------------------------
-- Validate the kit item
----------------------------------------------------------------------------------------------------------------------------
IF @scanned_index = @ID_KIT_ITEM
BEGIN
	EXEC @ret = tdc_pps_validate_kit_sp @is_packing, @is_3_step, @carton_no, @tote_bin, @order_no, @order_ext, @auto_lot, @auto_bin, @part_no, @kit_item OUTPUT, @line_no, @uom OUTPUT, @lot_ser OUTPUT, @bin_no OUTPUT, @err_msg OUTPUT
END

----------------------------------------------------------------------------------------------------------------------------
-- Validate the UOM
----------------------------------------------------------------------------------------------------------------------------
IF @scanned_index = @ID_UOM
BEGIN
	EXEC @ret = tdc_pps_validate_uom_sp @is_packing, @is_3_step, @carton_no, @tote_bin, @order_no, @order_ext, @auto_lot, @auto_bin, @tran_id, @part_no, @kit_item OUTPUT, @line_no, @location OUTPUT, @uom OUTPUT, @lot_ser OUTPUT, @bin_no OUTPUT, @err_msg OUTPUT 
END

----------------------------------------------------------------------------------------------------------------------------
-- Validate the lot
----------------------------------------------------------------------------------------------------------------------------
IF @scanned_index = @ID_LOT
BEGIN
	EXEC @ret = tdc_pps_validate_lot_sp @is_packing, @is_3_step, @carton_no, @tote_bin, @order_no, @order_ext, @auto_bin, @part_no OUTPUT, @kit_item OUTPUT, @line_no OUTPUT, @location OUTPUT, @lot_ser OUTPUT, @bin_no OUTPUT, @qty OUTPUT, @err_msg OUTPUT
END

----------------------------------------------------------------------------------------------------------------------------
-- Validate the bin
----------------------------------------------------------------------------------------------------------------------------
IF @scanned_index = @ID_BIN
BEGIN
	EXEC @ret = tdc_pps_validate_bin_sp @is_packing, @carton_no, @tote_bin, @order_no, @order_ext, @part_no, @kit_item, @line_no, @location, @lot_ser, @bin_no, @qty OUTPUT, @err_msg OUTPUT
END

----------------------------------------------------------------------------------------------------------------------------
-- Validate the serial number
----------------------------------------------------------------------------------------------------------------------------
IF @scanned_index = @ID_SERIAL_NO
BEGIN
	EXEC @ret = tdc_pps_validate_serial_sp @is_packing, @is_3_step, @tote_bin, @carton_no, @order_no, @order_ext, @line_no, @part_no, @kit_item, @location, @serial_no, @lot_ser OUTPUT, @bin_no OUTPUT, @err_msg OUTPUT, @tran_id	
END
----------------------------------------------------------------------------------------------------------------------------
-- Validate the serial lot
----------------------------------------------------------------------------------------------------------------------------
IF @scanned_index = @ID_SERIAL_LOT
BEGIN
	EXEC @ret = tdc_pps_validate_serial_lot_sp @is_packing, @is_3_step, @carton_no, @order_no, @order_ext, @line_no, @part, @location, @serial_no, @lot_ser, @err_msg OUTPUT 
END

----------------------------------------------------------------------------------------------------------------------------
-- serial version (There is no validation, pack the item).
----------------------------------------------------------------------------------------------------------------------------
IF @scanned_index = @ID_SERIAL_VERSION
BEGIN
	SELECT @ret = 0
END

----------------------------------------------------------------------------------------------------------------------------
-- serail version (There is no validation, pack the item).
----------------------------------------------------------------------------------------------------------------------------
IF @scanned_index = @ID_VERSION
BEGIN
	IF EXISTS(SELECT * 
		    FROM inv_master (NOLOCK) 
	           WHERE part_no = @part
		     AND lb_tracking = 'Y' 
		     AND serial_flag = 1) 
	BEGIN
		SELECT @qty = 1
		SELECT @ret = @ID_AUTO_SCAN_QTY 
	END 
	ELSE
		SELECT @ret = @ID_QUANTITY 
END

----------------------------------------------------------------------------------------------------------------------------
-- Validate the quantity
----------------------------------------------------------------------------------------------------------------------------
IF @scanned_index = @ID_QUANTITY 
OR @ret = @ID_AUTO_SCAN_QTY 
OR (@ret = @ID_QUANTITY AND @is_auto_qty = 'Y')
BEGIN
	--Make sure carton_no is not '0'
	IF (@carton_no <= 0)
	BEGIN
		SELECT @err_msg = 'Invalid Carton Number'
		RETURN -1
	END

	-- If auto qty, set the qty to 1
	IF @is_auto_qty = 'Y' AND @qty = 0 SELECT @qty = 1
 
	SELECT @ret = @ID_PART_NO
	----------------------------------------------------------------------------------------------------------------------------
	-- Re-validate the qtx
	----------------------------------------------------------------------------------------------------------------------------
	IF @scanned_index = @ID_QTX
	BEGIN
		EXEC @ret = tdc_pps_validate_tran_id_sp @is_packing, @tote_bin, @order_no, @order_ext, @tran_id, @part_no OUTPUT, @kit_item OUTPUT, @uom OUTPUT, @line_no OUTPUT, @location OUTPUT, @lot_ser OUTPUT, @bin_no OUTPUT, @err_msg OUTPUT
		IF @ret < 0 RETURN @ret
	END
	
	----------------------------------------------------------------------------------------------------------------------------
	-- Re-validate the part
	----------------------------------------------------------------------------------------------------------------------------
	IF @ret = @ID_PART_NO
	BEGIN
		EXEC @ret = tdc_pps_validate_part_sp 'N', @is_packing, @is_3_step, @carton_no, @tote_bin, @order_no, @order_ext, @auto_lot, @auto_bin, @tran_id, @part_no OUTPUT, @kit_item OUTPUT, @line_no OUTPUT, @location OUTPUT, @uom, @lot_ser OUTPUT, @bin_no OUTPUT, @err_msg OUTPUT
		IF @ret < 0 RETURN @ret
	END
	
	IF @ret = @ID_SCAN_SERIAL
	BEGIN

		EXEC @ret = tdc_pps_validate_serial_sp @is_packing, @is_3_step, @tote_bin, @carton_no, @order_no, @order_ext, @line_no, @part_no, @kit_item, @location, @serial_no, @lot_ser OUTPUT, @bin_no OUTPUT, @err_msg OUTPUT, @tran_id	
		IF @ret < 0 RETURN @ret
	END

	IF @ret = @ID_UOM
	BEGIN
		EXEC @ret = tdc_pps_validate_uom_sp @is_packing, @is_3_step, @carton_no, @tote_bin, @order_no, @order_ext, @auto_lot, @auto_bin, @tran_id, @part_no, @kit_item OUTPUT, @line_no, @location OUTPUT, @uom OUTPUT, @lot_ser OUTPUT, @bin_no OUTPUT, @err_msg OUTPUT 
		IF @ret < 0 RETURN @ret
	END

	IF @ret = @ID_SERIAL_LOT
	BEGIN	
		EXEC @ret = tdc_pps_validate_serial_lot_sp @is_packing, @is_3_step, @carton_no, @order_no, @order_ext, @line_no, @part, @location, @serial_no, @lot_ser, @err_msg OUTPUT 
		IF @ret < 0 RETURN @ret
	END

	----------------------------------------------------------------------------------------------------------------------------
	-- Re-validate the lot
	----------------------------------------------------------------------------------------------------------------------------
	IF @ret = @ID_LOT
	BEGIN
		EXEC @ret = tdc_pps_validate_lot_sp @is_packing, @is_3_step, @carton_no, @tote_bin, @order_no, @order_ext, @auto_bin, @part_no OUTPUT, @kit_item OUTPUT, @line_no OUTPUT, @location OUTPUT, @lot_ser OUTPUT, @bin_no OUTPUT, @qty OUTPUT, @err_msg OUTPUT
		IF @ret < 0 RETURN @ret
	END

	IF @ret = @ID_SERIAL_NO
	BEGIN
		EXEC @ret = tdc_pps_validate_serial_sp @is_packing, @is_3_step, @tote_bin, @carton_no, @order_no, @order_ext, @line_no, @part_no, @kit_item, @location, @serial_no, @lot_ser OUTPUT, @bin_no OUTPUT, @err_msg OUTPUT, @tran_id	
		IF @ret < 0 RETURN @ret
	END

	IF @ret = @ID_SERIAL_LOT
	BEGIN	
		EXEC @ret = tdc_pps_validate_serial_lot_sp @is_packing, @is_3_step, @carton_no, @order_no, @order_ext, @line_no, @part, @location, @serial_no, @lot_ser, @err_msg OUTPUT 
		IF @ret < 0 RETURN @ret
	END
	
	----------------------------------------------------------------------------------------------------------------------------
	-- Re-validate the bin
	----------------------------------------------------------------------------------------------------------------------------
	IF @ret = @ID_BIN
	BEGIN
		EXEC @ret = tdc_pps_validate_bin_sp @is_packing, @carton_no, @tote_bin, @order_no, @order_ext, @part_no, @kit_item, @line_no, @location, @lot_ser, @bin_no, @qty OUTPUT, @err_msg OUTPUT
		IF @ret < 0 RETURN @ret
	END

	----------------------------------------------------------------------------------------------------------------------------
	-- Validate the quantity
	----------------------------------------------------------------------------------------------------------------------------
	EXEC @ret = tdc_pps_validate_qty_sp @is_packing, @is_3_step, @carton_no, @tote_bin, @order_no, @order_ext, @tran_id, @part_no, @kit_item, @line_no, @uom, @lot_ser, @bin_no, @qty OUTPUT, @err_msg OUTPUT
	IF @ret < 0 RETURN @ret

	----------------------------------------------------------------------------------------------------------------------------
	-- If success, do pack or unpack
	----------------------------------------------------------------------------------------------------------------------------
	IF @ret = 0 
	BEGIN
		-- If 3 step packing, do the pick operation
		IF @is_packing = 'Y' AND @is_3_step = 'Y'
		BEGIN
			EXEC tdc_pps_pick_sp @tran_id, @user_id, @station_id, @order_no, @order_ext, @part_no, @kit_item, @location, @lot_ser, @bin_no, @line_no, @qty, @err_msg OUTPUT
			IF @ret < 0 RETURN @ret
 
			IF (@is_cube_active IN ('Y', 'B')) And (@bin_no <> '')
			BEGIN
				INSERT INTO dbo.tdc_ei_bin_log (module, trans, tran_no, tran_ext, location, part_no, from_bin, begin_tran, stationid, userid, direction, quantity)
				VALUES ('PPS', 'Pack Carton Sales', @order_no, @order_ext, @location, @part, @bin_no, GETDATE(), @station_id, @user_id, -1, @qty)
			END
		END

		-- v1.0 - Case Part Consolidation
		SET	@con_rec = 0

		IF @is_packing = 'Y'
		BEGIN
			-- v1.0 - Case Part Consolidation
			IF EXISTS (SELECT 1 FROM #temp_pps_carton_display WHERE order_no = @order_no 
						AND order_ext = @order_ext AND part_no = @part_no AND line_no = @line_no
						AND con_ref = @line_no) AND @is_packing = 'Y'
			BEGIN
				SET	@con_rec = 1		

				SELECT	@actual_qty = picked
				FROM	#temp_pps_carton_display 
				WHERE	order_no = @order_no 
				AND		order_ext = @order_ext 
				AND		part_no = @part_no 
				AND		line_no = @line_no
				AND		con_ref = @line_no
			
				SET @qty = @actual_qty
			END

			EXEC @ret = tdc_pps_pack_sp @is_cube_active, @carton_no, @carton_code, @pack_type, @user_id, @station_id, @tote_bin, @order_no, @order_ext, @serial_no, @version, @line_no, @part_no, @kit_item, @location, @lot_ser, @bin_no, @qty, @err_msg OUTPUT
			IF @ret < 0 RETURN @ret

			-- v1.0 If a consolidated line then process the other releated lines
			IF @con_rec = 1
			BEGIN
				
				SET @con_last_line = 0
				SET	@con_qty = 0.00
				SET @con_line = 0

				SELECT	TOP 1 @con_line = line_no,
						@con_qty = picked
				FROM	#temp_pps_carton_display
				WHERE	order_no = @order_no 
				AND		order_ext = @order_ext 
				AND		part_no = @part_no 
				AND		con_ref = @line_no
				AND		line_no > @con_last_line
				ORDER BY line_no ASC

				WHILE @@ROWCOUNT <> 0
				BEGIN

					EXEC @ret = tdc_pps_pack_sp @is_cube_active, @carton_no, @carton_code, @pack_type, @user_id, @station_id, @tote_bin, @order_no, @order_ext, @serial_no, @version, @con_line, @part_no, @kit_item, @location, @lot_ser, @bin_no, @con_qty, @err_msg OUTPUT
					IF @ret < 0 RETURN @ret

					SET @con_last_line = @con_line

					SELECT	TOP 1 @con_line = line_no,
							@con_qty = picked
					FROM	#temp_pps_carton_display
					WHERE	order_no = @order_no 
					AND		order_ext = @order_ext 
					AND		part_no = @part_no 
					AND		con_ref = @line_no
					AND		line_no > @con_last_line
					ORDER BY line_no ASC

				END

			END

		END
		ELSE
		BEGIN
			-- v1.0 - Case Part Consolidation
			IF EXISTS (SELECT 1 FROM #temp_pps_carton_display WHERE order_no = @order_no 
						AND order_ext = @order_ext AND part_no = @part_no AND line_no = @line_no
						AND con_ref = @line_no) AND @is_packing = 'N'
			BEGIN
				SET	@con_rec = 1		

				SELECT	@actual_qty = carton_packed
				FROM	#temp_pps_carton_display 
				WHERE	order_no = @order_no 
				AND		order_ext = @order_ext 
				AND		part_no = @part_no 
				AND		line_no = @line_no
				AND		con_ref = @line_no
			
				SET @qty = @actual_qty
			END


			EXEC tdc_pps_unpack_sp @is_cube_active, @carton_no, @user_id, @station_id, @tote_bin, @order_no, @order_ext, @serial_no, @version, @line_no, @part_no, @kit_item, @location, @lot_ser, @bin_no, @qty, @err_msg OUTPUT
			IF @ret < 0 RETURN @ret

			-- v1.0 If a consolidated line then process the other releated lines
			IF @con_rec = 1
			BEGIN
				
				SET @con_last_line = 0
				SET	@con_qty = 0.00
				SET @con_line = 0

				SELECT	TOP 1 @con_line = line_no,
						@con_qty = carton_packed
				FROM	#temp_pps_carton_display
				WHERE	order_no = @order_no 
				AND		order_ext = @order_ext 
				AND		part_no = @part_no 
				AND		con_ref = @line_no
				AND		line_no > @con_last_line
				ORDER BY line_no ASC

				WHILE @@ROWCOUNT <> 0
				BEGIN

					EXEC tdc_pps_unpack_sp @is_cube_active, @carton_no, @user_id, @station_id, @tote_bin, @order_no, @order_ext, @serial_no, @version, @con_line, @part_no, @kit_item, @location, @lot_ser, @bin_no, @con_qty, @err_msg OUTPUT
					IF @ret < 0 RETURN @ret

					SET @con_last_line = @con_line

					SELECT	TOP 1 @con_line = line_no,
							@con_qty = carton_packed
					FROM	#temp_pps_carton_display
					WHERE	order_no = @order_no 
					AND		order_ext = @order_ext 
					AND		part_no = @part_no 
					AND		con_ref = @line_no
					AND		line_no > @con_last_line
					ORDER BY line_no ASC

				END

			END

		END
 
		-- If 3 step un-packing, do the unpick operation
		IF @is_packing = 'N' AND @is_3_step = 'Y'
		BEGIN
			EXEC tdc_pps_unpick_sp @user_id, @station_id, @order_no, @order_ext, @part_no, @kit_item, @location, @lot_ser, @bin_no, @line_no, @qty, @err_msg OUTPUT
			IF @ret < 0 RETURN @ret

			IF (@is_cube_active IN ('Y', 'B')) And (@bin_no <> '')
			BEGIN
				INSERT INTO dbo.tdc_ei_bin_log (module, trans, tran_no, tran_ext, location, part_no, from_bin, begin_tran, stationid, userid, direction, quantity)
				VALUES ('PPS', 'Pack Carton Sales', @order_no, @order_ext, @location, @part, @bin_no, GETDATE(), @station_id, @user_id, 1, @qty)
			END
		END

		SELECT @ret = @ID_PACK_UNPACK_SUCCESS	
		
		--BEGIN JVM 03/02/10 -- Freight Lookup Recalculation
		--freight recalculation every pack or unpack
-- v1.1		IF (EXISTS(SELECT * FROM dbo.tdc_pack_station_tbl WHERE station_id = @station_id AND master_pack = 'N')										AND 		   
--		    EXISTS(SELECT ISNULL(free_shipping,'N') FROM CVO_orders_all WHERE order_no = @order_no AND ext = @order_ext AND free_shipping = 'N'))
--				EXEC CVO_GetFreight_recalculate_sp @order_no, @order_ext		
		IF (EXISTS(SELECT ISNULL(free_shipping,'N') FROM CVO_orders_all WHERE order_no = @order_no AND ext = @order_ext AND free_shipping = 'N'))
		-- START v1.2
		BEGIN
			IF NOT EXISTS (SELECT 1 FROM dbo.orders_all (NOLOCK) WHERE order_no = @order_no AND ext = @order_ext AND LEFT(user_category,2) IN ('ST','DO'))
			BEGIN 
				EXEC CVO_GetFreight_recalculate_sp @order_no, @order_ext	
			END
		END
		-- END v1.2	

		--END   JVM 03/02/10 -- Freight Lookup Recalculation
		
	END 
END
 
RETURN @ret


GO
GRANT EXECUTE ON  [dbo].[tdc_pps_scan_sp] TO [public]
GO
