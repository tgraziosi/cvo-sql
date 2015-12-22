SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*

EXEC cvo_backorder_processing_print_pick_tickets_sp 'CT01'

-- v1.0 CT 28/11/2013 - Issue #1406 - Print queued pick tickets for the template passed in
-- v1.1 CT 17/02/2014 - Issue #1453 - Print pick tickets in order of bin number
-- v1.2 CT 08/04/2014 - Issue #572 - Printing consolidated pick tickets
-- v1.3 CB 08/09/2015 - On print if not already printed
*/

CREATE PROC [dbo].[cvo_backorder_processing_print_pick_tickets_sp]	@template_code VARCHAR(30)

AS
BEGIN
	DECLARE @rec_id				INT,
			@retval				SMALLINT,
			@order_no			INT,
			@ext				INT,
			@msg				VARCHAR(1000),
			@err_msg			VARCHAR(100),
			@is_transfer		SMALLINT,
			@printed			SMALLINT,
			@parent_rec_id		INT, -- v1.1
			@consolidation_no	INT -- v1.2
	

	IF ISNULL(@template_code,'') = ''
	BEGIN
		RETURN
	END

	-- Write log
	SET @msg = 'Starting pick ticket printing for template ' + @template_code
	EXEC dbo.cvo_backorder_processing_log_sp @msg	

	-- Check for custom frames which aren't available
	CREATE TABLE #line_exclusions (
		order_no		int,
		order_ext		int,
		line_no			int)

	CREATE TABLE #exclusions (
		order_no		int,
		order_ext		int,
		has_line_exc	int NULL)

	-- START v1.1
	CREATE TABLE #bin (
		order_no		INT,
		ext				INT,
		is_transfer		SMALLINT,
		parent_rec_id	INT,
		bin_no			VARCHAR(12))

	
	CREATE TABLE #print_order (
		rec_id			INT IDENTITY (1,1),		
		order_no		INT,
		ext				INT,
		is_transfer		SMALLINT,
		parent_rec_id	INT,
		bin_no			VARCHAR(12))

	-- Load records into first temp table
	INSERT INTO #bin(
		order_no,
		ext,
		is_transfer,
		parent_rec_id)
	SELECT
		order_no,
		ext,
		is_transfer,
		rec_id
	FROM
		dbo.CVO_backorder_processing_pick_tickets (NOLOCK) 
	WHERE 
		template_code = @template_code
		AND printed = 0
	ORDER BY
		rec_id	

	-- Update with lowest allocated bin number (orders)
	UPDATE
		a
	SET
		bin_no = b.bin_no
	FROM
		#bin a
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
		#bin a
	INNER JOIN
		dbo.cvo_lowest_allocated_bin_vw b (NOLOCK) 
	ON
		a.order_no = b.order_no
	WHERE
		a.is_transfer = 1
		AND b.order_type = 'T'

	-- Put any orders/transfers without a bin at the end
	UPDATE #bin SET bin_no = 'ZZZZZZZZZZZZ' WHERE ISNULL(bin_no,'') = ''
	
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
		parent_rec_id,
		bin_no
	FROM
		#bin
	ORDER BY
		bin_no,
		order_no,
		ext
				
	EXEC dbo.cvo_backorder_processing_CF_check_sp @template_code
	--EXEC dbo.cvo_backorder_processing_CF_check_sp
	-- END v1.1
	
	-- Loop through records
	SET @rec_id = 0
	WHILE 1=1 
	BEGIN
		-- START v1.1
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
			@ext = ext,
			@is_transfer = is_transfer,
			@printed = printed
		FROM
			dbo.CVO_backorder_processing_pick_tickets (NOLOCK) 
		WHERE 
			template_code = @template_code
			AND rec_id > @rec_id
			AND printed = 0
		ORDER BY
			rec_id
		*/

		IF @@ROWCOUNT = 0
			BREAK

		-- Get pick ticket details
		SELECT 
			@order_no = order_no,
			@ext = ext,
			@is_transfer = is_transfer,
			@printed = printed
		FROM
			dbo.CVO_backorder_processing_pick_tickets (NOLOCK) 
		WHERE 
			template_code = @template_code
			AND rec_id = @parent_rec_id
			AND printed = 0	
		-- END v1.1

		SET @err_msg = ''

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

					-- v1.3 Start
					IF NOT EXISTS (SELECT 1 FROM orders_all (NOLOCK) WHERE order_no = @order_no AND ext = @ext AND status IN ('Q','P'))
					BEGIN

						IF ISNULL(@consolidation_no,0) <> 0
						BEGIN
							SET @msg = 'Printing Consolidated Pick Ticket for set ' + CAST(@consolidation_no AS VARCHAR(10)) 
							EXEC dbo.cvo_backorder_processing_log_sp @msg
							
							EXEC dbo.cvo_print_consolidated_pick_ticket_sp @consolidation_no,1
							SET @printed = 1

							-- Mark other orders as printed
							UPDATE
								a
							SET
								printed = @printed,
								printed_date = GETDATE(),
								reason = @err_msg
							FROM
								dbo.CVO_backorder_processing_pick_tickets a
							INNER JOIN
								#print_order b
							ON
								a.rec_id = b.parent_rec_id
							INNER JOIN
								dbo.cvo_masterpack_consolidation_det c (NOLOCK)
							ON
								b.order_no = c.order_no
								AND b.ext = c.order_ext
							WHERE
								c.consolidation_no = @consolidation_no
								AND b.rec_id <> @rec_id

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
								AND a.rec_id <> @rec_id				

						END
						ELSE
						BEGIN

							SET @msg = 'Printing Pick Ticket for order ' + CAST(@order_no AS VARCHAR(10)) + '-' + CAST(@ext AS VARCHAR(5))
							EXEC dbo.cvo_backorder_processing_log_sp @msg
							
							EXEC dbo.cvo_print_pick_ticket_sp @order_no, @ext,1
							SET @printed = 1
						END
						-- END v1.2
					END -- v1.3 END
				END
				ELSE
				BEGIN
					SET @printed = -1
					SET @err_msg = 'Custom frame exclusions exist'
				END
			END
			ELSE
			BEGIN
				SET @printed = -1
				SET @err_msg = 'No allocations in tdc_soft_alloc_tbl'
			END
		END

		IF @is_transfer = 1
		BEGIN

			IF EXISTS (SELECT 1 FROM tdc_soft_alloc_tbl (NOLOCK) WHERE order_no = @order_no AND order_type = 'T')
			BEGIN
				SET @msg = 'Printing Pick Ticket for transfer ' + CAST(@order_no AS VARCHAR(10)) 
				EXEC dbo.cvo_backorder_processing_log_sp @msg

				EXEC dbo.cvo_print_xfer_pick_ticket_sp @order_no, 1	
				SET @printed = 1			
			END
			ELSE
			BEGIN
				SET @printed = -1
				SET @err_msg = 'No allocations in tdc_soft_alloc_tbl'
			END
		END

		-- Update record
		UPDATE
			dbo.CVO_backorder_processing_pick_tickets
		SET
			printed = @printed,
			printed_date = GETDATE(),
			reason = @err_msg
		WHERE
			-- START v1.1
			rec_id = @parent_rec_id
			--rec_id = @rec_id
			-- END v1.1
	END
	
	-- Write log
	SET @msg = 'Completed pick ticket printing for template ' + @template_code
	EXEC dbo.cvo_backorder_processing_log_sp @msg	

	DROP TABLE #line_exclusions
	DROP TABLE #exclusions 

	RETURN
END

GO
GRANT EXECUTE ON  [dbo].[cvo_backorder_processing_print_pick_tickets_sp] TO [public]
GO
