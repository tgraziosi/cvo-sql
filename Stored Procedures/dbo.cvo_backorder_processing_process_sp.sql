SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*
Returns:	0 = Success
			-1 = No rignfence bin exists

v1.1 CT 28/11/2013 - Issue #1406 - Optional parameter to hold whether the allocation process should be run straightaway
v1.2 CT 27/01/2014 - Issue #1406 - Check allocated stock for this template, if the order number and line is no longer linked to template then unallocate
*/

-- EXEC cvo_backorder_processing_process_sp 'CT01'
CREATE PROC [dbo].[cvo_backorder_processing_process_sp] @template_code VARCHAR(30),
													@allocate SMALLINT = 0 -- v1.1
AS
BEGIN
	
	DECLARE @ringfence_bin	VARCHAR(12),
			@rec_id			INT,
			@order_no		INT,
			@ext			INT,
			@line_no		INT,
			@part_no		VARCHAR(30),
			@allocated		DECIMAL(20,8),
			@location		VARCHAR(10),
			@ringfenced		DECIMAL(20,8)

	-- Get ringfence bin for allocated stock
	SELECT @ringfence_bin = value_str FROM dbo.tdc_config WHERE [function] = 'BACKORDER_PROCESSING_RINGFENCE_BIN' 

	IF ISNULL(@ringfence_bin,'') = '' 
	BEGIN
		RETURN -1
	END

	-- Loop through any stock records no longer locked
	SET @rec_id = 0

	WHILE 1=1
	BEGIN
		SELECT TOP 1
			@rec_id = rec_id,
			@order_no = order_no,
			@ext = ext,
			@line_no = line_no,
			@part_no = part_no,
			@location = location
		FROM
			dbo.cvo_backorder_processing_orders
		WHERE
			template_code = @template_code 
			AND stock_locked = 1
			AND (stock_allocated = 0 OR process = 0)
			AND processed = 0
			AND rec_id > @rec_id
		ORDER BY
			rec_id
		
		IF @@ROWCOUNT = 0
			BREAK
			
		-- Release the stock
		EXEC dbo.cvo_backorder_processing_unringfence_stock_sp  @order_no, @ext, @line_no, @part_no, @location, @template_code

		-- Unlock the record 
		UPDATE
			dbo.cvo_backorder_processing_orders
		SET
			stock_locked = 0
		WHERE
			rec_id = @rec_id
	
	END

	-- Loop through changes in stock allocated qty
	SET @rec_id = 0

	WHILE 1=1
	BEGIN
		SELECT TOP 1
			@rec_id = rec_id,
			@order_no = order_no,
			@ext = ext,
			@line_no = line_no,
			@part_no = part_no,
			@location = location,
			@allocated = stock_allocated
		FROM
			dbo.cvo_backorder_processing_orders
		WHERE
			template_code = @template_code 
			AND stock_locked = 1
			AND stock_allocated > 0
			AND processed = 0
			AND process = 1
			AND rec_id > @rec_id
		ORDER BY
			rec_id
		
		IF @@ROWCOUNT = 0
			BREAK

		-- Get how much is already allocated
		SELECT
			@ringfenced = SUM(qty_ringfenced)
		FROM
			dbo.CVO_backorder_processing_orders_ringfenced_stock
		WHERE
			template_code = @template_code 
			AND order_no = @order_no
			AND ext = @ext
			AND line_no = @line_no
			
		-- If there is a change in qty then process the change
		IF (@allocated - @ringfenced) <> 0
		BEGIN

			-- Release the stock
			EXEC dbo.cvo_backorder_processing_unringfence_stock_sp  @order_no, @ext, @line_no, @part_no, @location, @template_code

			-- Ringfence stock
			EXEC dbo.cvo_backorder_processing_ringfence_stock_sp @order_no, @ext, @line_no, @part_no, @location, @allocated, @ringfence_bin, @template_code
		
		END
	END

	-- Loop through newly stock allocated records, ringfence stock and lock the record
	SET @rec_id = 0

	WHILE 1=1
	BEGIN
		SELECT TOP 1
			@rec_id = rec_id,
			@order_no = order_no,
			@ext = ext,
			@line_no = line_no,
			@part_no = part_no,
			@location = location,
			@allocated = stock_allocated
		FROM
			dbo.cvo_backorder_processing_orders
		WHERE
			template_code = @template_code 
			AND stock_locked = 0
			AND stock_allocated > 0
			AND processed = 0
			AND process = 1
			AND rec_id > @rec_id
		ORDER BY
			rec_id
		
		IF @@ROWCOUNT = 0
			BREAK

		-- Ringfence stock
		EXEC dbo.cvo_backorder_processing_ringfence_stock_sp @order_no, @ext, @line_no, @part_no, @location, @allocated, @ringfence_bin, @template_code

		-- Lock the record
		UPDATE
			dbo.cvo_backorder_processing_orders
		SET
			stock_locked = 1
		WHERE
			rec_id = @rec_id

	END
	
	-- Loop through any PO records no longer locked
	SET @rec_id = 0

	WHILE 1=1
	BEGIN
		SELECT TOP 1
			@rec_id = rec_id,
			@order_no = order_no,
			@ext = ext,
			@line_no = line_no,
			@part_no = part_no,
			@location = location
		FROM
			dbo.cvo_backorder_processing_orders
		WHERE
			template_code = @template_code 
			AND po_locked = 1
			AND (po_allocated = 0 OR process = 0)
			AND processed = 0
			AND rec_id > @rec_id
		ORDER BY
			rec_id
		
		IF @@ROWCOUNT = 0
			BREAK
	
		-- Release the po stock
		EXEC dbo.cvo_backorder_processing_unringfence_po_sp  @order_no, @ext, @line_no, @part_no, @location, @template_code	

		-- Unlock the record 
		UPDATE
			dbo.cvo_backorder_processing_orders
		SET
			po_locked = 0
		WHERE
			rec_id = @rec_id
	END

	-- Loop through changes in po allocated qty
	SET @rec_id = 0

	WHILE 1=1
	BEGIN
		SELECT TOP 1
			@rec_id = rec_id,
			@order_no = order_no,
			@ext = ext,
			@line_no = line_no,
			@part_no = part_no,
			@location = location,
			@allocated = po_allocated
		FROM
			dbo.cvo_backorder_processing_orders
		WHERE
			template_code = @template_code 
			AND po_locked = 1
			AND po_allocated > 0
			AND processed = 0
			AND process = 1
			AND rec_id > @rec_id
		ORDER BY
			rec_id
		
		IF @@ROWCOUNT = 0
			BREAK

		-- Get how much is already allocated
		SELECT
			@ringfenced = SUM(qty_ringfenced)
		FROM
			dbo.CVO_backorder_processing_orders_po_xref
		WHERE
			template_code = @template_code 
			AND order_no = @order_no
			AND ext = @ext
			AND line_no = @line_no
			
		-- If there is a change in qty then process the change
		IF (@allocated - @ringfenced) <> 0
		BEGIN

			-- Release the stock
			EXEC dbo.cvo_backorder_processing_unringfence_po_sp  @order_no, @ext, @line_no, @part_no, @location, @template_code

			-- Ringfence stock
			EXEC dbo.cvo_backorder_processing_ringfence_po_sp @order_no, @ext, @line_no, @part_no, @location, @allocated, @ringfence_bin, @template_code
		END
	END

	-- Loop through newly po allocated records, ringfence stock and lock the record
	SET @rec_id = 0

	WHILE 1=1
	BEGIN
		SELECT TOP 1
			@rec_id = rec_id,
			@order_no = order_no,
			@ext = ext,
			@line_no = line_no,
			@part_no = part_no,
			@location = location,
			@allocated = po_allocated
		FROM
			dbo.cvo_backorder_processing_orders
		WHERE
			template_code = @template_code 
			AND po_locked = 0
			AND po_allocated > 0
			AND processed = 0
			AND process = 1
			AND rec_id > @rec_id
		ORDER BY
			rec_id
		
		IF @@ROWCOUNT = 0
			BREAK

		-- Ringfence stock
		EXEC dbo.cvo_backorder_processing_ringfence_po_sp @order_no, @ext, @line_no, @part_no, @location, @allocated, @ringfence_bin, @template_code

		-- Lock the record
		UPDATE
			dbo.cvo_backorder_processing_orders
		SET
			po_locked = 1
		WHERE
			rec_id = @rec_id

	END

	-- START v1.2
	EXEC cvo_backorder_processing_clear_orphaned_ringfence_sp @template_code
	-- END v1.2

	-- START v1.1
	IF ISNULL(@allocate,0) = 1
	BEGIN
		EXEC dbo.cvo_backorder_processing_process_and_allocate_sp @template_code
	END
	-- END v1.1

	RETURN 0
END
	

GO
GRANT EXECUTE ON  [dbo].[cvo_backorder_processing_process_sp] TO [public]
GO
