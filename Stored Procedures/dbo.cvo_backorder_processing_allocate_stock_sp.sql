SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*

EXEC cvo_backorder_processing_allocate_stock_sp 

-- v1.1 CT 12/07/2013 - Issue #695 - auto print pick tickets
-- v1.2 CT 25/07/2013 - Issue #695 - fix pick ticket logic
-- v1.3 CT 11/10/2013 - Issue #1396 - call pick ticket routines using flag to denote this is from backorder processing
-- v1.4 CT 28/11/2013 - Issue #1406 - Write pick ticket details to table instead of printing straight away
-- v1.5 CT 29/11/2013 - Issue #1406 - Stock no longer ringfenced, qty allocated may not be qty required
-- v1.6 CT 03/04/2014 - Issue #572 - Changes for Masterpack order consolidation
-- v1.7 CB 18/12/2015 - Issue #1582 - If nothing allocated then do not add record to print table
-- v1.8 CB 28/07/2017 - Reset print
*/

CREATE PROC [dbo].[cvo_backorder_processing_allocate_stock_sp]

AS
BEGIN
	DECLARE @rec_id			INT,
			@retval			SMALLINT,
			@order_no		INT,
			@ext			INT,
			@line_no		INT,
			@part_no		VARCHAR(30),
			@location		VARCHAR(10),
			@bin_no			VARCHAR(12),
			@orig_bin_no	VARCHAR(12),
			@ringfenced		DECIMAL(20,8),
			@template_code	VARCHAR(30),
			@msg			VARCHAR(1000),
			@err_msg		VARCHAR(500),
			@is_transfer	SMALLINT,
			@no_print		smallint -- v1.7
	
	-- Write log
	EXEC dbo.cvo_backorder_processing_log_sp	'Starting allocation process'

	-- START v1.4
	-- Temp table no longer required
	/*
	-- START v1.1
	-- Create temp table
	CREATE TABLE #print_list(
		rec_id INT IDENTITY (1,1),
		order_no INT,
		ext INT,
		is_transfer SMALLINT)
	-- END v1.1
	*/
	-- END v1.4

	-- START v1.6
	-- Create temp table
	CREATE TABLE #allocated_orders(
		order_no	INT,
		ext			INT)
	-- END v1.6


	-- Clear previously processed stock
	DELETE FROM dbo.CVO_backorder_processing_orders_ringfenced_stock WHERE [status] = 2
	
	-- Lock records for processing 
	UPDATE
		dbo.CVO_backorder_processing_orders_ringfenced_stock
	SET
		[status] = -1
	WHERE 
		[status] <= 0

	SET @rec_id = 0

	-- Loop through an process the stock
	WHILE 1=1
	BEGIN

		SELECT TOP 1
			@rec_id = rec_id,
			@template_code = template_code,
			@order_no = order_no,
			@ext = ext,
			@line_no = line_no,
			@part_no = part_no,
			@location = location,
			@bin_no = bin_no,
			@orig_bin_no = orig_bin_no,
			@ringfenced = qty_ringfenced 
		FROM
			dbo.CVO_backorder_processing_orders_ringfenced_stock (NOLOCK)
		WHERE
			rec_id > @rec_id
			AND [status] = -1
		ORDER BY
			rec_id

		IF @@ROWCOUNT = 0
			BREAK

		SET @no_print = 0 -- v1.7

		-- Write log
		SET @msg = 'Processing - Template: ' + @template_code 
		SET @msg = @msg + CASE @ext WHEN -1 THEN ' Transfer: '  + CAST(@order_no AS VARCHAR(10)) ELSE ' Order: ' + CAST(@order_no AS VARCHAR(10)) + '-' + CAST(@ext AS VARCHAR(3)) END  
		SET @msg = @msg + ' Part: ' + @part_no + ' Qty: ' + CAST(CAST(@ringfenced AS INT) AS VARCHAR(10))
		EXEC dbo.cvo_backorder_processing_log_sp	@msg

		-- Mark record as being processed
		UPDATE
			dbo.CVO_backorder_processing_orders_ringfenced_stock
		SET
			[status] = -2
		WHERE	
			rec_id = @rec_id

		-- If ext = -1 then this is a transfer, set the ext back to 0 for allocation purposes
		IF @ext = -1
		BEGIN
			SET @is_transfer = 1
			SET @ext = 0
		END
		ELSE
		BEGIN
			SET @is_transfer = 0
		END
		
		-- START v1.6
		-- If this is an order, check if this order is already on a consolidation set and the order is printed, if so don't process it
		IF @is_transfer = 0
		BEGIN
			IF (SELECT dbo.f_check_consolidation_set_for_order_allocation (@order_no, @ext)) = 1
			BEGIN
				SET @msg = 'Skipping allocation - Order ' + CAST(@order_no AS VARCHAR(10)) + '-' + CAST(@ext AS VARCHAR(5)) + ' is currently printed on a consolidation set'
				EXEC dbo.cvo_backorder_processing_log_sp @msg

				-- Mark record as being unprocessed
				UPDATE
					dbo.CVO_backorder_processing_orders_ringfenced_stock
				SET
					[status] = 0
				WHERE	
					rec_id = @rec_id

				CONTINUE
			END
		END
		-- END v1.6

		-- Process the record
		SET @retval = 0
		SET @err_msg = ''
		EXEC @retval = dbo.cvo_backorder_processing_allocate_stock_line_sp  @rec_id, @order_no, @ext, @line_no, @part_no, @location, @bin_no,
																			@orig_bin_no, @ringfenced, @is_transfer, @template_code, @err_msg OUTPUT

		-- START v1.5
		-- Remove qty from message as the qty may have change (due to stock not being ringfenced)
		SET @msg = 'Processing - Template: ' + @template_code 
		SET @msg = @msg + CASE @ext WHEN -1 THEN ' Transfer: '  + CAST(@order_no AS VARCHAR(10)) ELSE ' Order: ' + CAST(@order_no AS VARCHAR(10)) + '-' + CAST(@ext AS VARCHAR(3)) END  
		SET @msg = @msg + ' Part: ' + @part_no
		-- END v1.5

		-- Log
		IF @retval = 0
		BEGIN
			SET @msg = REPLACE(@msg, 'Processing', 'Processed')
		END
		ELSE
		BEGIN
			SET @msg = REPLACE(@msg, 'Processing', 'Error processing') + ' - ' + ISNULL(@err_msg,'ERROR MESSAGE MISSING')
		END
		EXEC dbo.cvo_backorder_processing_log_sp	@msg


		-- Mark record as processed
		UPDATE
			dbo.CVO_backorder_processing_orders_ringfenced_stock
		SET
			[status] = CASE ISNULL(@retval,-1) WHEN 0 THEN 2 ELSE 1 END,
			qty_processed = CASE ISNULL(@retval,-1) WHEN 0 THEN qty_ringfenced ELSE qty_processed END
		WHERE	
			rec_id = @rec_id

		IF @retval = 0
		BEGIN
			-- v1.7 Start
			IF (@is_transfer = 0)
			BEGIN
				IF NOT EXISTS (SELECT 1 FROM tdc_soft_alloc_tbl (NOLOCK) WHERE order_no = @order_no AND order_ext = @ext AND order_type = 'S')
				BEGIN
					SET @no_print = 1
				END
			END
			ELSE
			BEGIN
				IF NOT EXISTS (SELECT 1 FROM tdc_soft_alloc_tbl (NOLOCK) WHERE order_no = @order_no AND order_ext = @ext AND order_type = 'T')
				BEGIN
					SET @no_print = 1
				END
			END

			IF (@no_print = 0)
			BEGIN
				UPDATE
					a
				SET
					processed = 1
				FROM
					dbo.CVO_backorder_processing_orders a
				INNER JOIN
					dbo.CVO_backorder_processing_orders_ringfenced_stock b (NOLOCK)
				ON
					a.template_code = b.template_code
					AND a.order_no = b.order_no
					AND a.ext = b.ext
					AND a.line_no = b.line_no
				WHERE	
					b.rec_id = @rec_id

				-- START v1.4
				-- Add the order to the table of pick tickets to be printed
				-- v1.8 Start
				IF EXISTS (SELECT 1 FROM CVO_backorder_processing_pick_tickets (NOLOCK) WHERE template_code = @template_code AND order_no = @order_no AND ext = @ext 
								AND is_transfer = @is_transfer)
				BEGIN
					UPDATE	CVO_backorder_processing_pick_tickets
					SET		printed = 0,
							printed_date = NULL,
							reason = NULL
					WHERE	template_code = @template_code 
					AND		order_no = @order_no 
					AND		ext = @ext 
					AND		is_transfer = @is_transfer
				END
				-- v1.8 End


				IF NOT EXISTS (SELECT 1 FROM CVO_backorder_processing_pick_tickets WHERE template_code = @template_code AND order_no = @order_no AND ext = @ext 
								AND is_transfer = @is_transfer AND printed = 0)
				BEGIN
					INSERT INTO dbo.CVO_backorder_processing_pick_tickets (
						rec_date,
						template_code,
						order_no,
						ext,
						is_transfer,
						printed) 
					SELECT
						GETDATE(),
						@template_code,
						@order_no, 
						@ext, 
						@is_transfer,
						0

					SET @msg = 'Queuing printing of Pick Ticket for order ' + CAST(@order_no AS VARCHAR(10)) + '-' + CAST(@ext AS VARCHAR(5))
					EXEC dbo.cvo_backorder_processing_log_sp @msg
				END
			END
			-- v1.7 End
			/*
			-- START v1.1
			-- Add the order to the list of pick tickets to be printed
			IF NOT EXISTS (SELECT 1 FROM #print_list WHERE order_no = @order_no AND ext = @ext AND is_transfer = @is_transfer)
			BEGIN
				INSERT INTO #print_list (order_no, ext, is_transfer) VALUES (@order_no, @ext, @is_transfer)
			END
			-- END v1.1
			*/
			-- END v1.4

			-- START v1.6
			-- Add order to table to be consolidated
			IF @is_transfer = 0
			BEGIN
				IF NOT EXISTS (SELECT 1 FROM #allocated_orders WHERE order_no = @order_no AND ext = @ext)
				BEGIN
					INSERT INTO #allocated_orders (
						order_no,
						ext)
					SELECT
						@order_no,
						@ext
				END
			END
			-- END v1.6

		END
	END

	-- START v1.6
	-- Call consolidation routine
	IF EXISTS (SELECT 1 FROM #allocated_orders)
	BEGIN
		EXEC dbo.cvo_masterpack_consolidate_orders_sp 'BO'
	END 
	-- END v1.6
	

	-- START v1.4
	-- No longer required, printing of pick titckets is now queued
	/*
	-- START v1.1
	-- Print order pick tickets
	IF EXISTS (SELECT 1 FROM #print_list WHERE is_transfer = 0)
	BEGIN

		-- Check for custom frames which aren't available
		CREATE TABLE #line_exclusions (
		order_no		int,
		order_ext		int,
		line_no			int)

		CREATE TABLE #exclusions (
		order_no		int,
		order_ext		int,
		has_line_exc	int NULL)
		
		EXEC dbo.cvo_soft_alloc_CF_check_sp

		-- Loop through orders
		SET @rec_id = 0
		WHILE 1=1 
		BEGIN
			SELECT TOP 1
				@rec_id = rec_id,
				-- START v1.2
				@order_no = order_no,
				--@order_no = @order_no,
				@ext = ext
				--@ext = @ext
				-- END v1.2
			FROM
				#print_list 
			WHERE 
				is_transfer = 0
				AND rec_id > @rec_id
			ORDER BY
				rec_id
			
			IF @@ROWCOUNT = 0
				BREAK

			IF EXISTS (SELECT 1 FROM tdc_soft_alloc_tbl (NOLOCK) WHERE order_no = @order_no AND order_ext = @ext AND order_type = 'S')
			BEGIN

				IF NOT EXISTS (SELECT 1 FROM #line_exclusions WHERE order_no = @order_no AND order_ext = @ext) 
				BEGIN

					SET @msg = 'Printing Pick Ticket for order ' + CAST(@order_no AS VARCHAR(10)) + '-' + CAST(@ext AS VARCHAR(5))
					EXEC dbo.cvo_backorder_processing_log_sp @msg
					
					-- START v1.3
					EXEC dbo.cvo_print_pick_ticket_sp @order_no, @ext,1
					-- EXEC dbo.cvo_print_pick_ticket_sp @order_no, @ext
					-- END v1.3
				END
			END
		END
	END

	-- Print transfer pick tickets
	IF EXISTS (SELECT 1 FROM #print_list WHERE is_transfer <> 0)
	BEGIN

		-- Loop through orders
		SET @rec_id = 0
		WHILE 1=1 
		BEGIN
			SELECT TOP 1
				@rec_id = rec_id,
				-- START v1.2
				@order_no = order_no
				--@order_no = @order_no
				-- END v1.2
			FROM
				#print_list 
			WHERE 
				is_transfer <> 0
				AND rec_id > @rec_id
			ORDER BY
				rec_id
			
			IF @@ROWCOUNT = 0
				BREAK

			IF EXISTS (SELECT 1 FROM tdc_soft_alloc_tbl (NOLOCK) WHERE order_no = @order_no AND order_type = 'T')
			BEGIN
				SET @msg = 'Printing Pick Ticket for transfer ' + CAST(@order_no AS VARCHAR(10)) 
				EXEC dbo.cvo_backorder_processing_log_sp @msg

				-- START v1.3
				EXEC dbo.cvo_print_xfer_pick_ticket_sp @order_no, 1
				-- EXEC dbo.cvo_print_xfer_pick_ticket_sp @order_no
				-- END v1.3
				
			END
		END
	END
	-- END v1.1
	*/
	-- END v1.4

	-- Write log
	EXEC dbo.cvo_backorder_processing_log_sp	'Completed allocation process'

	RETURN 0
END

GO
GRANT EXECUTE ON  [dbo].[cvo_backorder_processing_allocate_stock_sp] TO [public]
GO
