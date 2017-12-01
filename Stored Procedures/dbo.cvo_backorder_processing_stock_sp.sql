SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- EXEC cvo_backorder_processing_stock_sp 'CT01'
CREATE PROC [dbo].[cvo_backorder_processing_stock_sp] (@template_code VARCHAR(30))
AS
BEGIN
	DECLARE @part_no			VARCHAR(30),
			@location			VARCHAR(10),
			@po_due_from		DATETIME,
			@po_due_to			DATETIME,
			@check_po			SMALLINT,
			@available			DECIMAL(20,8),
			@po_available		DECIMAL(20,8),
			@rec_id				INT,
			@required			DECIMAL(20,8),
			@allocated			DECIMAL(20,8),
			@stock_allocated	DECIMAL(20,8),
			@po_allocated		DECIMAL(20,8),
			@change				SMALLINT,
			@po_applied			DECIMAL(20,8),
			@orig_po_available	DECIMAL(20,8),
			@orig_available		DECIMAL(20,8),
			@rx_reserve			int, -- v1.1
			@rx_reserve_days	int -- v1.1

	-- Load template info
	SELECT
		@location = location,
		@po_due_from = po_due_from,
		@po_due_to = po_due_to,
		@rx_reserve = ISNULL(rx_reserve,0), -- v1.1
		@rx_reserve_days = ISNULL(rx_reserve_days,22) -- v1.1
	FROM 
		dbo.CVO_backorder_processing_templates (NOLOCK)
	WHERE 
		template_code = @template_code

	IF @@ROWCOUNT = 0
	BEGIN
		RETURN
	END

	IF @po_due_from IS NULL AND @po_due_to IS NULL
	BEGIN
		SET @check_po = 0
	END
	ELSE
	BEGIN
		SET @check_po = 1
	END

	CREATE TABLE #stock(
		part_no			VARCHAR(30),
		available		DECIMAL(20,8),
		po_available	DECIMAL(20,8),
		to_allocate		DECIMAL(20,8))

	-- Load table for this template
	INSERT INTO #stock(
		part_no,
		available,
		po_available,
		to_allocate)
	SELECT 
		part_no,
		--SUM(CASE processed WHEN 1 THEN 0 ELSE stock_allocated * -1 END),
		0,
		--SUM(CASE processed WHEN 1 THEN 0 ELSE po_allocated * -1 END),
		0,
		0
	FROM
		dbo.CVO_backorder_processing_orders (NOLOCK)
	WHERE
		template_code = @template_code
	GROUP BY
		part_no

	UPDATE
		#stock
	SET
		to_allocate = available + po_available

	-- v1.1 Start
	IF (@rx_reserve = 0)
	BEGIN

		-- Loop through records and get stock
		SET @part_no = ''

		WHILE 1=1
		BEGIN
			SELECT TOP 1
				@part_no = part_no
			FROM
				#stock
			WHERE
				part_no > @part_no
			ORDER BY 
				part_no
			
			IF @@ROWCOUNT = 0
				BREAK
			
			-- Get available stock
			EXEC @available = dbo.cvo_backorder_processing_available_stock_sp @location, @part_no
			
			IF ISNULL(@available,0) <= 0 
			BEGIN
				SET @available = 0
			END 

			-- Get PO availability
			IF @check_po = 1
			BEGIN
				EXEC @po_available = dbo.cvo_backorder_processing_po_stock_sp @location, @part_no, @po_due_from, @po_due_to, 0
			END
		
			IF ISNULL(@po_available,0) <= 0 
			BEGIN
				SET @po_available = 0
			END 

			UPDATE
				#stock
			SET
				available = ISNULL(@available,0),
				po_available = ISNULL(@po_available,0),
				to_allocate = ISNULL(@available,0) + ISNULL(@po_available,0)
			WHERE
				part_no = @part_no

		END

		-- Loop through records and apply stock
		SET @part_no = ''

		WHILE 1=1
		BEGIN
			SELECT TOP 1
				@part_no = part_no,
				@available = ISNULL(available,0),
				@po_available = ISNULL(po_available,0)
			FROM
				#stock
			WHERE
				part_no > @part_no
				AND to_allocate > 0
			ORDER BY 
				part_no
		
			IF @@ROWCOUNT = 0
				BREAK
			
			-- Apply to order/transfer lines
			SET @rec_id = 0

			WHILE 1=1
			BEGIN

				IF @available <= 0 AND @po_available <= 0
					BREAK

				SELECT TOP 1
					@rec_id = rec_id,
					--@required = qty - allocated,
					@required = qty,
					--@allocated = allocated,
					@allocated = 0,
					--@stock_allocated = stock_allocated,
					@stock_allocated = 0,
					--@po_allocated  = po_allocated
					@po_allocated  = 0
				FROM
					dbo.CVO_backorder_processing_orders (NOLOCK)
				WHERE
					template_code = @template_code
					AND part_no = @part_no
					--AND qty - allocated > 0
					AND rec_id > @rec_id
					AND processed = 0
					AND stock_locked = 0 
					AND po_locked = 0
				ORDER BY
					rec_id

				IF @@ROWCOUNT = 0
					BREAK

				-- Store stock levels before applying to this order
				SELECT	@orig_available = @available,
						@orig_po_available = @po_available

				SET @change = 0

				-- Apply stock first
				IF @available > 0
				BEGIN
					IF @required > @available
					BEGIN
						SELECT	@required = @required - @available,
								@allocated = @allocated + @available,
								@stock_allocated = @stock_allocated + @available
						
						SET @available = 0

					END
					ELSE 
					BEGIN
						SELECT	@available = @available - @required,
								@allocated = @allocated + @required,
								@stock_allocated = @stock_allocated + @required
						
						SET @required = 0
					END

					SET @change = 1
				END			

				-- Apply PO stock if required
				IF @required > 0 AND @po_available > 0
				BEGIN
					SET @po_applied = 0

					IF @required > @po_available
					BEGIN
						SELECT	@required = @required - @po_available,
								@allocated = @allocated + @po_available,
								@po_allocated = @stock_allocated + @po_available,
								@po_applied = @po_available
						
						SET @po_available = 0

					END
					ELSE 
					BEGIN
						SELECT	@po_available = @po_available - @required,
								@allocated = @allocated + @required,
								@po_allocated = @stock_allocated + @required,
								@po_applied = @required
						
						SET @required = 0
					END

					SET @change = 1
				END
				
				-- Update record
				IF @change = 1
				BEGIN
					UPDATE
						dbo.CVO_backorder_processing_orders
					SET
						allocated = @allocated,
						stock_allocated = @stock_allocated,
						po_allocated = @po_allocated,
						process = 1,
						available = @orig_available,
						po_available = @orig_po_available,
						is_available = 1
					WHERE	
						rec_id = @rec_id

				END
			END
		END
	END
	ELSE
	BEGIN
		EXEC dbo.cvo_backorder_processing_rx_reserve_sp @template_code, @location
	END
	-- v1.1 End

	-- Mark all locked records as stock available
	UPDATE
		dbo.CVO_backorder_processing_orders
	SET
		is_available = 1
	WHERE	
		po_locked = 1 
		OR stock_locked = 1
END
	

GO
GRANT EXECUTE ON  [dbo].[cvo_backorder_processing_stock_sp] TO [public]
GO
