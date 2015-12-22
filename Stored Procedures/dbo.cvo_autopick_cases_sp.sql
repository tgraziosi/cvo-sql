SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[cvo_autopick_cases_sp]	@order_no	int,
										@order_ext	int,
										@line_no	int,
										@qty		decimal(20,8),
										@station_id int,
										@user_id	varchar(50)
AS
BEGIN
	
	-- Check the config, is autopick switched on
	IF NOT EXISTS (SELECT 1 FROM dbo.tdc_config WHERE [function] = 'AUTOPICK_CASES' and active = 'Y')
		RETURN

	-- Declarations
	DECLARE	@case_line_no	int,
			@qty_remaining	decimal(20,8),
			@tran_id		int,
			@last_tran_id	int,
			@date_expires	datetime,
			@bin_no			varchar(20),
			@lot_ser		varchar(20),
			@part_no		varchar(30),
			@qty_to_process	decimal(20,8),
			@location		varchar(10),
			@data			varchar(7500)

	-- Create working tables
	CREATE TABLE #cvo_ord_list (
		order_no		int,
		order_ext		int,
		line_no			int,
		add_case		varchar(1),
		add_pattern		varchar(1),
		from_line_no	int,
		is_case			int,
		is_pattern		int,
		add_polarized	varchar(1),
		is_polarized	int,
		is_pop_gif		int,
		is_amt_disc		varchar(1),
		amt_disc		decimal(20,8),
		is_customized	varchar(1),
		promo_item		varchar(1),
		list_price		decimal(20,8),
		orig_list_price	decimal(20,8))	

	CREATE TABLE #trans_to_pick (	
		tran_id			int,
		part_no			varchar(30),
		bin_no			varchar(20),
		lot_ser			varchar(20),
		location		varchar(10),
		qty_to_process	decimal(20,8))


	-- Call routine to populate #cvo_ord_list with the frame/case relationship
	EXEC CVO_create_fc_relationship_sp @order_no, @order_ext

	-- Is there a related case
	SET @case_line_no = 0
	SELECT	@case_line_no = line_no
	FROM	#cvo_ord_list
	WHERE	from_line_no = @line_no
	AND		is_case = 1
	
	-- If there is no related case then exit
	IF (@case_line_no = 0 OR @case_line_no IS NULL)
		RETURN
	
	-- Get a list of all the pick queue for the related case as the quantity could be from multiple bins
	INSERT	#trans_to_pick (tran_id, part_no, bin_no, lot_ser, location, qty_to_process)
	SELECT	tran_id, part_no, bin_no, lot, location, qty_to_process
	FROM	tdc_pick_queue (NOLOCK)
	WHERE	trans_type_no = @order_no
	AND		trans_type_ext = @order_ext
	AND		line_no = @case_line_no
	AND		trans = 'STDPICK'

	-- if there are transations to process then autopick
	IF NOT EXISTS(SELECT 1 FROM #trans_to_pick)
		RETURN

	-- Create working table for the picking
	IF OBJECT_ID('tempdb..#adm_pick_ship') IS NOT NULL
		DROP TABLE #adm_pick_ship

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


	-- Process each transaction until the qty passed in has been consumed
	SET	@qty_remaining = @qty
	SET @last_tran_id = 0

	SELECT	TOP 1 @tran_id = tran_id,
			@part_no = part_no, 
			@bin_no = bin_no, 
			@lot_ser = lot_ser, 
			@location = location, 
			@qty_to_process = qty_to_process
	FROM	#trans_to_pick
	WHERE	tran_id > @last_tran_id
	ORDER BY tran_id ASC

	WHILE @@ROWCOUNT <> 0
	BEGIN
		-- If the qty on the pick record is greater than that of the case then use the frame qty
		IF @qty_to_process > @qty_remaining
			SET @qty_to_process = @qty_remaining		

		IF @qty_to_process > @qty
			SET @qty_to_process = @qty		

		-- Need the date expires
		SELECT	@date_expires = date_expires
		FROM	lot_bin_stock (NOLOCK)
		WHERE	location = @location
		AND		bin_no = @bin_no
		AND		lot_ser = @lot_ser
		AND		part_no = @part_no

		-- Clear the working table
		TRUNCATE TABLE #adm_pick_ship

		-- Insert the data for record to pick	
		INSERT	#adm_pick_ship (order_no, ext, line_no, part_no, bin_no, lot_ser, location, date_exp, qty)
		VALUES (@order_no, @order_ext, @case_line_no, @part_no, @bin_no, @lot_ser, @location, ISNULL(@date_expires,GETDATE()), @qty_to_process)

		-- Call the standard picking routine
		EXEC dbo.tdc_queue_xfer_ship_pick_sp @tran_id, '', 'S', @station_id

		-- Build the data for the transaction log
		SET @data = 'Autopicked case from line: ' + CAST(@line_no AS varchar(10))

		-- Record the action in the transaction log
		INSERT tdc_log  WITH (ROWLOCK) (tran_date, userid, trans_source, module, trans, tran_no, tran_ext, part_no, lot_ser, bin_no, location, quantity, data)
		VALUES (getdate(),@user_id,'CO','QTX','STDPICK',CAST(@order_no AS varchar(16)), CAST(@order_ext AS varchar(5)), @part_no, @lot_ser, @bin_no, @location, CAST(@qty_to_process AS varchar(20)), @data)

		-- START v1.1
		EXEC cvo_masterpack_update_consolidated_case_pick_sp @tran_id, @qty_to_process
		-- END v1.1

		-- update the qty left to process
		SET @qty_remaining = @qty_remaining - @qty_to_process

		-- Once the qty remaining has been used then break
		IF @qty_remaining <= 0
			BREAK

		SET @last_tran_id = @tran_id

		SELECT	TOP 1 @tran_id = tran_id,
				@part_no = part_no, 
				@bin_no = bin_no, 
				@lot_ser = lot_ser, 
				@location = location, 
				@qty_to_process = qty_to_process
		FROM	#trans_to_pick
		WHERE	tran_id > @last_tran_id
		ORDER BY tran_id ASC

	END
	DROP TABLE #trans_to_pick
	DROP TABLE #cvo_ord_list

END
GO
GRANT EXECUTE ON  [dbo].[cvo_autopick_cases_sp] TO [public]
GO
