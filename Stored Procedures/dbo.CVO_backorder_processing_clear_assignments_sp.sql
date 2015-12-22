SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*
v1.0 - CT 04/06/13 - Clears stock assigned to a template

EXEC dbo.CVO_backorder_processing_clear_assignments_sp	'CT01'
*/
CREATE PROC [dbo].[CVO_backorder_processing_clear_assignments_sp]	@template_code	VARCHAR(30)
AS
BEGIN
	DECLARE @rec_id			INT,
			@order_no		INT,
			@ext			INT,
			@line_no		INT,
			@part_no		VARCHAR(30),
			@allocated		DECIMAL(20,8),
			@location		VARCHAR(10),
			@ringfenced		DECIMAL(20,8)

	-- Loop through any stock records which are locked (virtually allocated)
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
			AND processed = 0
			AND rec_id > @rec_id
		ORDER BY
			rec_id
		
		IF @@ROWCOUNT = 0
			BREAK
			
		-- Release the stock
		EXEC dbo.cvo_backorder_processing_unringfence_stock_sp  @order_no, @ext, @line_no, @part_no, @location, @template_code

		-- Update the record 
		UPDATE
			dbo.cvo_backorder_processing_orders
		SET
			stock_locked = 0
		WHERE
			rec_id = @rec_id
	END

	-- Loop through any po records which are locked (virtually allocated)
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
			AND processed = 0
			AND rec_id > @rec_id
		ORDER BY
			rec_id
		
		IF @@ROWCOUNT = 0
			BREAK
	
		-- Release the po stock
		EXEC dbo.cvo_backorder_processing_unringfence_po_sp  @order_no, @ext, @line_no, @part_no, @location, @template_code	

		-- Update the record 
		UPDATE
			dbo.cvo_backorder_processing_orders
		SET
			po_locked = 0
		WHERE
			rec_id = @rec_id
	END

	RETURN 0
END

GO
GRANT EXECUTE ON  [dbo].[CVO_backorder_processing_clear_assignments_sp] TO [public]
GO
