SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*

EXEC cvo_backorder_processing_process_and_allocate_sp 

-- v1.0 CT 28/11/2013 - Issue #1406 - Allocate stock from the Backorder Processing Results form
-- v1.1 CT 17/02/2014 - Issue #1453 - Print pick tickets in order of bin number
-- v1.2 CT 03/04/2014 - Issue #572 - Changes for Masterpack order consolidation
-- v1.3 CB 07/11/2017 - Add process info for tdc_log
*/

CREATE PROC [dbo].[cvo_backorder_processing_process_and_allocate_sp] @template_code VARCHAR(30)

AS
BEGIN
	DECLARE @rec_id				INT,
			@retval				SMALLINT,
			@order_no			INT,
			@ext				INT,
			@line_no			INT,
			@part_no			VARCHAR(30),
			@location			VARCHAR(10),
			@bin_no				VARCHAR(12),
			@orig_bin_no		VARCHAR(12),
			@ringfenced			DECIMAL(20,8),
			@msg				VARCHAR(1000),
			@err_msg			VARCHAR(500),
			@is_transfer		SMALLINT,
			@parent_rec_id		INT, -- v1.1
			@consolidation_no	INT -- v1.2
	
	-- Write log
--	SET @msg = 'Starting realtime allocation process for template ' + @template_code
	EXEC dbo.cvo_backorder_processing_log_sp	@msg
--	EXEC dbo.cvo_auto_alloc_process_sp 1, 'cvo_backorder_processing_process_and_allocate_sp' -- v1.3

	-- Create temp table
	CREATE TABLE #print_list(
		rec_id		INT IDENTITY (1,1),
		order_no	INT,
		ext			INT,
		is_transfer SMALLINT,
		bin_no		VARCHAR(12)) -- v1.1

	-- START v1.2
	-- Create temp table
	CREATE TABLE #allocated_orders(
		order_no	INT,
		ext			INT)
	-- END v1.2
		
	-- Lock records for processing 
	UPDATE
		dbo.CVO_backorder_processing_orders_ringfenced_stock
	SET
		[status] = -1
	WHERE 
		[status] <= 0
		AND template_code = @template_code

	SET @rec_id = 0

	-- Loop through and process the stock
	WHILE 1=1
	BEGIN

		SELECT TOP 1
			@rec_id = rec_id,
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
			AND template_code = @template_code
			AND [status] = -1
		ORDER BY
			rec_id

		IF @@ROWCOUNT = 0
			BREAK

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
		
		-- START v1.2
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
		-- END v1.2

		-- Process the record
		SET @retval = 0
		SET @err_msg = ''
		EXEC @retval = dbo.cvo_backorder_processing_allocate_stock_line_sp  @rec_id, @order_no, @ext, @line_no, @part_no, @location, @bin_no,
																			@orig_bin_no, @ringfenced, @is_transfer, @template_code, @err_msg OUTPUT

		-- Remove qty from message as the qty may have change (due to stock not being ringfenced)
		SET @msg = 'Processing - Template: ' + @template_code 
		SET @msg = @msg + CASE @ext WHEN -1 THEN ' Transfer: '  + CAST(@order_no AS VARCHAR(10)) ELSE ' Order: ' + CAST(@order_no AS VARCHAR(10)) + '-' + CAST(@ext AS VARCHAR(3)) END  
		SET @msg = @msg + ' Part: ' + @part_no

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

			-- Add the order to the list of pick tickets to be printed
			IF NOT EXISTS (SELECT 1 FROM #print_list WHERE order_no = @order_no AND ext = @ext AND is_transfer = @is_transfer)
			BEGIN
				INSERT INTO #print_list (order_no, ext, is_transfer) VALUES (@order_no, @ext, @is_transfer)
			END

			-- START v1.2
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
			-- END v1.2
		END
	END

	-- START v1.2
	-- Call consolidation routine
	IF EXISTS (SELECT 1 FROM #allocated_orders)
	BEGIN
		EXEC dbo.cvo_masterpack_consolidate_orders_sp 'BO'
	END 
	-- END v1.2

	-- START v1.1
	-- If order pick tickets exist then do CF check
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

		EXEC dbo.cvo_backorder_processing_CF_check_sp @template_code
		--EXEC dbo.cvo_backorder_processing_CF_check_sp
	END 

	-- Create temp table to put the pick tickets in correct order	
	CREATE TABLE #print_order (
		rec_id			INT IDENTITY (1,1),		
		order_no		INT,
		ext				INT,
		is_transfer		SMALLINT,
		parent_rec_id	INT,
		bin_no			VARCHAR(12))

	-- Update with lowest allocated bin number (orders)
	UPDATE
		a
	SET
		bin_no = b.bin_no
	FROM
		#print_list a
	INNER JOIN
		dbo.cvo_lowest_allocated_bin_vw b (NOLOCK) 
	ON
		a.order_no = b.order_no
		AND a.ext = b.order_ext
	WHERE
		a.is_transfer = 0
		AND b.order_type = 'S'

	-- Update with lowest allocated bin number (transfers)
	UPDATE
		a
	SET
		bin_no = b.bin_no
	FROM
		#print_list a
	INNER JOIN
		dbo.cvo_lowest_allocated_bin_vw b (NOLOCK) 
	ON
		a.order_no = b.order_no
	WHERE
		a.is_transfer = 1
		AND b.order_type = 'T'

	-- Put any orders/transfers without a bin at the end
	UPDATE #print_list SET bin_no = 'ZZZZZZZZZZZZ' WHERE ISNULL(bin_no,'') = ''
	
	-- Load into print order table
	INSERT INTO #print_order(
		order_no,
		ext,
		is_transfer,
		parent_rec_id,
		bin_no)
	SELECT
		order_no,
		ext,
		is_transfer,
		rec_id,
		bin_no
	FROM
		#print_list
	ORDER BY
		bin_no,
		order_no,
		ext

	-- Loop through orders
	SET @rec_id = 0
	WHILE 1=1 
	BEGIN
		
		SELECT TOP 1
			@rec_id = rec_id,
			@parent_rec_id = parent_rec_id
		FROM
			#print_order
		WHERE
			rec_id > @rec_id
		ORDER BY
			rec_id

		/*
		SELECT TOP 1
			@rec_id = rec_id,
			@order_no = order_no,
			@ext = ext
		FROM
			#print_list 
		WHERE 
			is_transfer = 0
			AND rec_id > @rec_id
		ORDER BY
			rec_id
		*/	
		
		IF @@ROWCOUNT = 0
			BREAK

		-- Get pick ticket details
		SELECT 
			@order_no = order_no,
			@ext = ext,
			@is_transfer = is_transfer
		FROM
			#print_list
		WHERE 
			rec_id = @parent_rec_id
			
		
		IF @is_transfer = 0
		BEGIN

			IF EXISTS (SELECT 1 FROM tdc_soft_alloc_tbl (NOLOCK) WHERE order_no = @order_no AND order_ext = @ext AND order_type = 'S')
			BEGIN

				IF NOT EXISTS (SELECT 1 FROM #line_exclusions WHERE order_no = @order_no AND order_ext = @ext) 
				BEGIN
					-- START v1.2
					-- Check if this is a consolidated order
					SET @consolidation_no = 0
					SELECT
						@consolidation_no = consolidation_no
					FROM
						dbo.cvo_masterpack_consolidation_det (NOLOCK)
					WHERE
						order_no = @order_no
						AND order_ext = @ext

					IF ISNULL(@consolidation_no,0) <> 0
					BEGIN
						SET @msg = 'Printing Consolidated Pick Ticket for set ' + CAST(@consolidation_no AS VARCHAR(10)) 
						EXEC dbo.cvo_backorder_processing_log_sp @msg
						
						EXEC dbo.cvo_print_consolidated_pick_ticket_sp @consolidation_no,1

						-- Remove other orders for this set from the print table
						DELETE 
							a
						FROM 
							#print_order a
						INNER JOIN
							dbo.cvo_masterpack_consolidation_det b (NOLOCK)
						ON
							a.order_no = b.order_no
							AND a.ext = b.order_ext
						WHERE
							b.consolidation_no = @consolidation_no
					END
					ELSE
					BEGIN

						SET @msg = 'Printing Pick Ticket for order ' + CAST(@order_no AS VARCHAR(10)) + '-' + CAST(@ext AS VARCHAR(5))
						EXEC dbo.cvo_backorder_processing_log_sp @msg
						
						EXEC dbo.cvo_print_pick_ticket_sp @order_no, @ext,1
					END
					-- END v1.2
				END
			END
		END

	/*
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
				@order_no = order_no
			FROM
				#print_list 
			WHERE 
				is_transfer <> 0
				AND rec_id > @rec_id
			ORDER BY
				rec_id
			
			IF @@ROWCOUNT = 0
				BREAK
	*/
		IF @is_transfer = 1
		BEGIN
			IF EXISTS (SELECT 1 FROM tdc_soft_alloc_tbl (NOLOCK) WHERE order_no = @order_no AND order_type = 'T')
			BEGIN
				SET @msg = 'Printing Pick Ticket for transfer ' + CAST(@order_no AS VARCHAR(10)) 
				EXEC dbo.cvo_backorder_processing_log_sp @msg

				EXEC dbo.cvo_print_xfer_pick_ticket_sp @order_no, 1				
			END
		END
	END
	-- END v1.1

	-- Write log
--	SET @msg = 'Completed realtime allocation process for template ' + @template_code
	EXEC dbo.cvo_backorder_processing_log_sp	@msg
--	EXEC dbo.cvo_auto_alloc_process_sp 0 -- v1.3

	RETURN 0
END

GO
GRANT EXECUTE ON  [dbo].[cvo_backorder_processing_process_and_allocate_sp] TO [public]
GO
