SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- v1.1 CT 30/07/2012 - Remove inserts/deletes of tdc_config option mod_ebo_inv
-- v1.2 CT 23/10/2012 - For orders marked as Replenish Sales Consultant Inventory, call code to create transfer
-- v1.3 CT 25/10/2012 - Remove v1.2
-- v1.4 CB 19/06/2014 - Performance
CREATE PROC [dbo].[CVO_Ship_Rep_Orders_sp]	@Order_no	int,
										@order_ext	int
AS
BEGIN

	
	-- DECLARATIONS
	DECLARE	@line_no		int,
			@last_line_no	int,
			@qty			decimal(20,8),
			@part_no		varchar(30),
			@bin_no			varchar(20),
			@lot_ser		varchar(20),
			@location		varchar(10),
			@freight		decimal(20,8),
			@date_expires	datetime,
			@uom			varchar(10),
			@conv_factor	decimal(20,8)

	-- START v1.1
	/*
	-- Switch on the TDC config to allow an order to be updated
	IF NOT EXISTS (SELECT * FROM dbo.tdc_config WHERE [function] = 'mod_ebo_inv')  
		INSERT INTO tdc_config ([function],mod_owner, description, active) VALUES ('mod_ebo_inv','EBO','Allow modify inventory from eBO','Y')   
	*/
	-- END v1.1

	SELECT	@freight = freight,
			@location = location
	FROM	dbo.orders_all (NOLOCK)
	WHERE	order_no = @order_no
	AND		ext = @order_ext

	SET @last_line_no = 0

	SELECT	TOP 1 @line_no = line_no,
			@part_no = part_no,
			@qty = ordered,
			@uom = uom,
			@conv_factor = conv_factor
	FROM	dbo.ord_list (NOLOCK)
	WHERE	order_no = @order_no
	AND		order_ext = @order_ext
	AND		line_no > @last_line_no
	ORDER BY line_no ASC

	WHILE @@ROWCOUNT <> 0
	BEGIN

		SET @bin_no = NULL

		SELECT	TOP 1 @bin_no = bin_no,
				@lot_ser = lot_ser,
				@date_expires = date_expires
		FROM	dbo.lot_bin_stock (NOLOCK)
		WHERE	location = @location
		AND		part_no = @part_no
		AND		qty >= @qty

		IF @bin_no IS NULL
			RETURN

		UPDATE	dbo.ord_list_ship_vw WITH (ROWLOCK)
		SET		shipped = @qty, 
				status = 'R', 
				picked_dt = GETDATE(), 
				who_picked_id = 'sa' 
		WHERE	order_no = @order_no 
		AND		order_ext = @order_ext 
		AND		line_no = @line_no

		INSERT INTO lot_bin_ship WITH (ROWLOCK)( location, part_no, bin_no, lot_ser, tran_code, tran_no, tran_ext, date_tran,
								date_expires, qty, direction, cost, uom, uom_qty, conv_factor, qc_flag, who, line_no, kit_flag ) 
		VALUES ( @location, @part_no, @bin_no, @lot_ser, 'R', @order_no, @order_ext, GETDATE(), @date_expires, @qty, -1, 
					0.00000000, @uom, @qty * @conv_factor, @conv_factor, 'N', 'sa', @line_no, 'N' )

		UPDATE	dbo.lot_bin_ship WITH (ROWLOCK)
		SET		date_tran = GETDATE(), 
				who = 'sa' 
		WHERE	location = @location 
		AND		part_no = @part_no 
		AND		bin_no = @bin_no 
		AND		lot_ser = @lot_ser 
		AND		tran_no = @order_no 
		AND		tran_ext = @order_ext 
		AND		line_no = @line_no 

		UPDATE	dbo.tdc_soft_alloc_tbl WITH (ROWLOCK)
		SET		qty = qty - @qty
		WHERE	location = @location 
		AND		part_no = @part_no 
		AND		bin_no = @bin_no 
		AND		lot_ser = @lot_ser 
		AND		order_no = @order_no 
		AND		order_ext = @order_ext 
		AND		line_no = @line_no 
		AND		order_type = 'S'

		SET @last_line_no = @line_no

		SELECT	TOP 1 @line_no = line_no,
				@part_no = part_no,
				@qty = ordered,
				@uom = uom,
				@conv_factor = conv_factor
		FROM	dbo.ord_list (NOLOCK)
		WHERE	order_no = @order_no
		AND		order_ext = @order_ext
		AND		line_no > @last_line_no
		ORDER BY line_no ASC

	END


	UPDATE	dbo.orders_shipping_vw WITH (ROWLOCK)
	SET		date_shipped = GETDATE(), 
			status = 'R', 
			freight = @freight, 
			printed = 'R' 
	WHERE	order_no = @order_no 
	AND		ext = @order_ext 

	EXEC dbo.fs_calculate_oetax_wrap @ord = @order_no, @ext = @order_ext, @batch_call = -1  

	EXEC dbo.fs_updordtots @ordno =	@order_no,	@ordext = @order_ext 

	-- START v1.3
	/*
	-- START v1.2
	IF EXISTS (SELECT 1 FROM dbo.cvo_orders_all (NOLOCK) WHERE order_no = @order_no AND ext = @order_ext AND ISNULL(replen_inv,0) = 1 AND ISNULL(xfer_no,0) = 0)
	BEGIN
		EXEC dbo.CVO_create_inv_replen_transfer_sp @order_no, @order_ext
	END
	-- END v1.2 
	*/
	-- END v1.3

	-- START v1.1
	/*
	-- Remove Config setting
	DELETE FROM dbo.tdc_config WHERE [function] = 'mod_ebo_inv'  
	*/
	-- END v1.1
END
GO
GRANT EXECUTE ON  [dbo].[CVO_Ship_Rep_Orders_sp] TO [public]
GO
