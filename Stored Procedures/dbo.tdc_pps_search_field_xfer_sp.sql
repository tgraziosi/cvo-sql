SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[tdc_pps_search_field_xfer_sp]
@tote_bin	VARCHAR(30),
@order_no	INT,
@carton_no	INT,
@field_index	INT,	--1)PCSN  	2)PART  3)COMPONENT
			--4)LOCATION  	5)LOT   6)BIN
@packing	INT,    --1)PACKING	0)UNPACKING
@pick_pack	INT,	--1)ON		0)OFF
@PCSN		INT,
@line_no	INT,
@part_no	VARCHAR(30),
@location 	VARCHAR(12),
@lot		VARCHAR(25)
AS


TRUNCATE TABLE #temp_pps_search_field_xfer
/*
IF @field_index = 1 --PCSN
BEGIN
END
*/
--ELSE 
IF @field_index = 2 --PART
BEGIN
	--RETRIEVE THE PART NUMBER FROM THE TEMP TABLE
	--THE PPS GRID IS BOUND TO.  THE GRID'S TEMP TABLE
	--MUST BE CREATED BEFORE RUNNING THIS STORED PROCEDURE
	IF @packing = 1
	BEGIN
		IF @pick_pack = 0
		BEGIN
			IF ISNULL(@tote_bin, '') = '' 
			BEGIN
				INSERT INTO #temp_pps_search_field_xfer (part_no)
				SELECT DISTINCT part_no
				FROM #tdc_pack_out_item_xfer a(NOLOCK)
				WHERE cum_packed < ordered
				AND (part_no IN (SELECT DISTINCT part_no FROM tdc_dist_item_pick (NOLOCK)
						  WHERE order_no = @order_no
						  AND order_ext = 0
						  AND quantity > 0
						  AND [function] = 'T'
						  AND line_no = a.line_no)) 

				ORDER BY part_no
			END
			ELSE
			BEGIN
				INSERT INTO #temp_pps_search_field_xfer (part_no)
				SELECT DISTINCT part_no
				FROM #tdc_pack_out_item_xfer a(NOLOCK)
				WHERE cum_packed < ordered
				AND part_no IN (SELECT DISTINCT part_no FROM tdc_tote_bin_tbl (NOLOCK)
					WHERE order_no = @order_no
					AND order_ext = 0
					AND bin_no = @tote_bin
					AND line_no = a.line_no) 
				AND ((part_no IN (SELECT DISTINCT part_no FROM tdc_dist_item_pick (NOLOCK)
						  WHERE order_no = @order_no
						  AND order_ext = 0
						  AND [function] = 'T'
						  AND quantity > 0
						  AND line_no = a.line_no)) )
					
				ORDER BY part_no
			END
		
		END
		ELSE --PICK/PACK ON
		BEGIN
			IF ISNULL(@tote_bin, '') = '' 
			BEGIN
				INSERT INTO #temp_pps_search_field_xfer (part_no)
				SELECT DISTINCT part_no
				FROM #tdc_pack_out_item_xfer a(NOLOCK)
				WHERE cum_packed < ordered
				ORDER BY part_no
			END
			ELSE
			BEGIN
				INSERT INTO #temp_pps_search_field_xfer (part_no)
				SELECT DISTINCT part_no
				FROM #tdc_pack_out_item_xfer a(NOLOCK)
				WHERE cum_packed < ordered
				AND part_no IN (SELECT DISTINCT part_no FROM tdc_tote_bin_tbl (NOLOCK)
					WHERE order_no = @order_no
					AND order_ext = 0
					AND bin_no = @tote_bin
					AND line_no = a.line_no) 
				ORDER BY part_no
			END
		END
	END
	ELSE --UNPACKING
	BEGIN
		IF ISNULL(@tote_bin, '') = '' 
		BEGIN
			INSERT INTO #temp_pps_search_field_xfer (part_no)
			SELECT DISTINCT part_no
			FROM #tdc_pack_out_item_xfer a
			WHERE cum_packed > 0
			ORDER BY part_no
		END
		ELSE
		BEGIN
			INSERT INTO #temp_pps_search_field_xfer (part_no)
			SELECT DISTINCT part_no
			FROM #tdc_pack_out_item_xfer a
			WHERE cum_packed > 0
			AND part_no IN (SELECT DISTINCT part_no FROM tdc_tote_bin_tbl (NOLOCK)
				WHERE order_no = @order_no
				AND order_ext = 0
				AND bin_no = @tote_bin
				AND line_no = a.line_no) 
			ORDER BY part_no
		END
	END
END

ELSE IF @field_index = 3 --LOCATION
BEGIN

	INSERT INTO #temp_pps_search_field_xfer (location)
	SELECT DISTINCT location 
	FROM ord_list a(NOLOCK), #tdc_pack_out_item_xfer b(NOLOCK)
        WHERE order_no = @order_no
        AND order_ext = 0
        AND a.part_no = @part_no 
	AND b.part_no = @part_no 
	ORDER BY location
END

ELSE IF @field_index = 4 --LOT
BEGIN

	IF ISNULL(@tote_bin, '') = ''
	BEGIN
		IF @pick_pack = 0 
		BEGIN

			IF @packing = 1
			BEGIN
				INSERT INTO #temp_pps_search_field_xfer (lot)
				SELECT DISTINCT a.lot_ser
				FROM tdc_dist_item_pick a (NOLOCK), lot_bin_xfer b(NOLOCK)
				WHERE a.order_no = b.tran_no
				AND a.order_ext = b.tran_ext
				AND a.line_no = b.line_no
				AND a.bin_no = b.bin_no
				AND a.[function] = 'T'
				AND a.lot_ser = b.lot_ser
				AND a.part_no = b.part_no
				AND a.order_no = @order_no
				AND a.order_ext = 0
				and b.location = @location
				AND a.part_no = @part_no
				AND a.line_no = @line_no
			END
			ELSE --UNPACKING
			BEGIN
				INSERT INTO #temp_pps_search_field_xfer (lot)
				SELECT DISTINCT lot_ser
				FROM tdc_carton_detail_tx (NOLOCK)
				WHERE carton_no = @carton_no
				AND line_no = @line_no
				AND part_no = @part_no
			END
		END
		ELSE --PICKPACK
		BEGIN
			IF @packing = 1
			BEGIN
				INSERT INTO #temp_pps_search_field_xfer (lot)
				SELECT DISTINCT lot_ser
				FROM lot_bin_stock (NOLOCK)
				WHERE part_no = @part_no
				AND location = @location
			END
			ELSE --UNPACKING
			BEGIN
				INSERT INTO #temp_pps_search_field_xfer (lot)
				SELECT DISTINCT lot_ser
				FROM tdc_carton_detail_tx (NOLOCK)
				WHERE carton_no = @carton_no
				AND line_no = @line_no
				AND part_no = @part_no
			END
		END
	END
	ELSE
	BEGIN
		INSERT INTO #temp_pps_search_field_xfer(lot)
		SELECT DISTINCT lot_ser  
                FROM tdc_tote_bin_tbl tb (NOLOCK)                                
                WHERE order_no = @order_no
                AND order_ext = 0
                AND part_no = @part_no                          
                AND bin_no = @tote_bin
		ORDER BY lot_ser
	END
END

ELSE IF @field_index = 5 --BIN
BEGIN
	IF ISNULL(@tote_bin, '') = ''
	BEGIN
		IF @packing = 1
		BEGIN
			INSERT INTO #temp_pps_search_field_xfer (bin, quantity, date_expires)
			SELECT DISTINCT bin_no, qty, date_expires 
			FROM lot_bin_stock (NOLOCK) 
			WHERE part_no = @part_no
			AND lot_ser = @lot
			AND location = @location
			ORDER BY bin_no
		END
		ELSE
		BEGIN
			INSERT INTO #temp_pps_search_field_xfer (bin, quantity, date_expires)
			SELECT DISTINCT bin_no, qty, date_expires 
			FROM lot_bin_stock a(NOLOCK), tdc_carton_detail_tx b(NOLOCK)
			WHERE a.part_no = @part_no
			AND a.lot_ser = @lot
			AND a.location = @location
			AND b.part_no = a.part_no
			AND b.lot_ser = a.lot_ser
			AND b.line_no = @line_no
			AND b.carton_no = @Carton_no
			ORDER BY bin_no
		END
	END
	ELSE
	BEGIN
		INSERT INTO #temp_pps_search_field_xfer(bin)
		SELECT DISTINCT orig_bin                                    
                FROM tdc_tote_bin_tbl tb (NOLOCK)                                
                WHERE order_no = @order_no
                AND order_ext = 0
                AND part_no = @part_no                  
                AND bin_no = @tote_bin      
                AND lot_ser = @lot           
		ORDER BY orig_bin
	END
END
GO
GRANT EXECUTE ON  [dbo].[tdc_pps_search_field_xfer_sp] TO [public]
GO
