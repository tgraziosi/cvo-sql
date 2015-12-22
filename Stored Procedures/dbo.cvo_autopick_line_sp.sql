SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[cvo_autopick_line_sp]	@tran_id	int,
										@order_no	int,
										@order_ext	int,
										@line_no	int,
										@qty		decimal(20,8),
										@station_id int,
										@user_id	varchar(50)
AS
BEGIN
	SET NOCOUNT ON
	
	-- Declarations
	DECLARE	@date_expires	datetime,
			@bin_no			varchar(20),
			@lot_ser		varchar(20),
			@part_no		varchar(30),
			@qty_to_process	decimal(20,8),
			@location		varchar(10),
			@data			varchar(7500),
			@temp_created	SMALLINT

	-- Create working table for the picking
	IF OBJECT_ID('tempdb..#adm_pick_ship') IS NOT NULL
	BEGIN
		DELETE #adm_pick_ship
		SET @temp_created = 0
	END		
	ELSE
	BEGIN
		CREATE TABLE #adm_pick_ship (
			order_no	int	not null,
			ext			int	not null,
			line_no		int	not null,
			part_no		varchar(30)	not null, 
			tracking_no	varchar(30) null, 
			bin_no		varchar(12)	null, 
			lot_ser		varchar(25)	null, 
			location	varchar(10)	null, 
			date_exp	datetime	null, 
			qty			decimal(20,8) not null,
			err_msg		varchar(255) null, 
			row_id		int identity not null)
		
		SET @temp_created = 1
	END


	-- Process transaction 
	SELECT	@tran_id = tran_id,
			@part_no = part_no, 
			@bin_no = bin_no, 
			@lot_ser = lot, 
			@location = location, 
			@qty_to_process = @qty
	FROM	tdc_pick_queue
	WHERE	tran_id = @tran_id

	-- Need the date expires
	SELECT	@date_expires = date_expires
	FROM	lot_bin_stock (NOLOCK)
	WHERE	location = @location
	AND		bin_no = @bin_no
	AND		lot_ser = @lot_ser
	AND		part_no = @part_no

		
	-- Insert the data for record to pick	
	INSERT	#adm_pick_ship (order_no, ext, line_no, part_no, bin_no, lot_ser, location, date_exp, qty)
	VALUES (@order_no, @order_ext, @line_no, @part_no, @bin_no, @lot_ser, @location, ISNULL(@date_expires,GETDATE()), @qty_to_process)

	-- Call the standard picking routine
	EXEC dbo.tdc_queue_xfer_ship_pick_sp @tran_id, '', 'S', @station_id

	-- Build the data for the transaction log
	SET @data = dbo.f_create_tdc_log_order_pick_data_string (@order_no, @order_ext, @line_no)

	-- Record the action in the transaction log
	INSERT tdc_log (tran_date, userid, trans_source, module, trans, tran_no, tran_ext, part_no, lot_ser, bin_no, location, quantity, data)
	VALUES (getdate(),@user_id,'CO','QTX','STDPICK',CAST(@order_no AS varchar(16)), CAST(@order_ext AS varchar(5)), @part_no, @lot_ser, @bin_no, @location, CAST(@qty_to_process AS varchar(20)), @data)

	-- Autopick cases
	EXEC cvo_autopick_cases_sp	@order_no, @order_ext, @line_no, @qty, @station_id,	@user_id

	IF @temp_created = 1
	BEGIN
		IF OBJECT_ID('tempdb..#adm_pick_ship') IS NOT NULL
			DROP TABLE #adm_pick_ship
	END

END
GO
GRANT EXECUTE ON  [dbo].[cvo_autopick_line_sp] TO [public]
GO
