SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[tdc_packverify_quickpack_sp] 
		@order_no 	int,
		@order_ext 	int,
		@carton_no	int,
		@carton_type    varchar(10),
		@carton_class   varchar(10),
		@user_id 	varchar(50),
		@station_id	int,
		@error_msg 	varchar(255) 	OUTPUT

  
AS 

DECLARE @return		int,
	@line_no 	int, 
	@location 	varchar(10), 
	@part_no 	varchar(30), 
	@lot_ser 	varchar(25), 
	@bin_no 	varchar(12), 
	@qty 		decimal(24,8),
	@bin_qty	decimal(20, 8),
	@qty_alloc	decimal(24,8),
	@qty_to_pack	decimal(24,8),
	@language 	varchar(10)

	SELECT @language = ISNULL((SELECT Language FROM tdc_sec (nolock) WHERE userid = (SELECT who FROM #temp_who)), 'us_english')

	-- 1. Check if carton has any TDC serialized items pre-packed
	IF EXISTS (SELECT * 
		     FROM tdc_inv_list         a (NOLOCK),
			  tdc_carton_detail_tx b (NOLOCK),
			  ord_list	       c (NOLOCK)
		    WHERE carton_no   = @carton_no
		      AND b.order_no  = c.order_no
		      AND b.order_ext = c.order_ext
		      AND a.part_no   = b.part_no
		      AND a.location  = c.location
		      AND vendor_sn  != 'N')
	BEGIN
		-- 'Unable to Quick Pack: Carton has TDC Serialized item(s) pre-packed.'
		SELECT @error_msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_packverify_quickpack_sp' AND err_no = -101 AND language = @language 
		RETURN -1
	END	

	-- 2. Get all the parts to be Quick Packed
	DECLARE parts_cursor CURSOR FOR
		SELECT part_no, line_no, lot_ser, (qty_to_pack - pack_qty)
		  FROM tdc_carton_detail_tx
		 WHERE carton_no   = @carton_no
                   AND qty_to_pack > pack_qty
		 ORDER BY line_no, lot_ser

	OPEN parts_cursor
	FETCH NEXT FROM parts_cursor INTO @part_no, @line_no, @lot_ser, @qty

	WHILE (@@FETCH_STATUS = 0)
	BEGIN
		-- 3. Get Location
		SELECT @location = location
		  FROM ord_list
		 WHERE order_no   = @order_no
                   AND order_ext  = @order_ext
		   AND line_no    = @line_no

		-- 4. Get BIN
		IF ISNULL(@lot_ser, '') = ''
		BEGIN
			EXEC @return  = tdc_packverify_pickpack_sp 	@order_no, @order_ext,  @carton_no, @line_no,     @location, @part_no,  
									NULL,      NULL,        @qty,       @carton_type, @carton_class, 
									@user_id,  @station_id, 'N',        @error_msg  OUTPUT
			IF @return <> 0
			BEGIN
				CLOSE parts_cursor
				DEALLOCATE parts_cursor
				RETURN -2
			END
		END
		ELSE
		BEGIN
			DECLARE bins_cursor CURSOR FOR
				SELECT bin_no, qty
				  FROM tdc_soft_alloc_tbl
				 WHERE order_no   = @order_no
		                   AND order_ext  = @order_ext
				   AND order_type = 'S'
				   AND location   = @location
				   AND line_no    = @line_no
				   AND lot_ser    = @lot_ser
				 ORDER BY bin_no
	
			OPEN bins_cursor
			FETCH NEXT FROM bins_cursor INTO @bin_no, @qty_alloc
		
			WHILE (@@FETCH_STATUS = 0 AND @qty > 0)
			BEGIN
									
				IF @qty_alloc >= @qty 
					SELECT @qty_to_pack = @qty
				ELSE
					SELECT @qty_to_pack = @qty_alloc
				
				SELECT @qty = @qty - @qty_to_pack

				EXEC @return  = tdc_packverify_pickpack_sp 	@order_no, @order_ext,   @carton_no,   @line_no,     
										@location, @part_no,     @lot_ser,     @bin_no,     
										@qty_to_pack,            @carton_type, @carton_class, 
										@user_id,  @station_id,  'N', @error_msg  OUTPUT
				IF @return <> 0
				BEGIN
					CLOSE      bins_cursor
					DEALLOCATE bins_cursor
					CLOSE      parts_cursor
					DEALLOCATE parts_cursor
					RETURN -3
				END
	
				FETCH NEXT FROM bins_cursor INTO @bin_no, @qty_alloc
			END
		
			CLOSE      bins_cursor
			DEALLOCATE bins_cursor
		END

		FETCH NEXT FROM parts_cursor INTO @part_no, @line_no, @lot_ser, @qty
	END

	CLOSE      parts_cursor
        DEALLOCATE parts_cursor

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[tdc_packverify_quickpack_sp] TO [public]
GO
