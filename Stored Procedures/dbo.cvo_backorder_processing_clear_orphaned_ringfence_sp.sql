SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*
v1.0 CT 27/01/2013 - Issue #1406 - Check if there is any stock allocated for this template where the order is no longer on the template, if so unringfence it.
*/

-- EXEC cvo_backorder_processing_clear_orphaned_ringfence_sp 'CT01'
CREATE PROC [dbo].[cvo_backorder_processing_clear_orphaned_ringfence_sp] @template_code VARCHAR(30)
AS
BEGIN
	
	DECLARE @rec_id			INT,
			@order_no		INT,
			@ext			INT,
			@line_no		INT,
			@part_no		VARCHAR(30),
			@location		VARCHAR(10)
	
	SET NOCOUNT ON

	-- Stock records
	SET @rec_id = 0
	WHILE 1=1
	BEGIN
		SELECT TOP 1
			@rec_id = a.rec_id,
			@order_no = a.order_no,
			@ext = a.ext,
			@line_no = a.line_no,
			@part_no = a.part_no,
			@location = a.location
		FROM
			dbo.cvo_backorder_processing_orders_ringfenced_stock a (NOLOCK)
		LEFT JOIN
			dbo.cvo_backorder_processing_orders b (NOLOCK)
		ON
			a.template_code = b.template_code
			AND a.order_no = b.order_no
			AND a.ext = b.ext
			AND a.line_no = b.line_no
		WHERE
			a.rec_id > @rec_id
			AND a.template_code = @template_code
			AND a.[status] = 0
			AND b.order_no IS NULL
		ORDER BY 
			a.rec_id
		
		IF @@ROWCOUNT = 0
			BREAK

		-- Release the stock
		EXEC dbo.cvo_backorder_processing_unringfence_stock_sp  @order_no, @ext, @line_no, @part_no, @location, @template_code
	END

	-- PO records
	SET @rec_id = 0
	WHILE 1=1
	BEGIN
		SELECT TOP 1
			@rec_id = a.rec_id,
			@order_no = a.order_no,
			@ext = a.ext,
			@line_no = a.line_no,
			@part_no = a.part_no,
			@location = ''
		FROM
			dbo.CVO_backorder_processing_orders_po_xref a (NOLOCK)
		LEFT JOIN
			dbo.cvo_backorder_processing_orders b (NOLOCK)
		ON
			a.template_code = b.template_code
			AND a.order_no = b.order_no
			AND a.ext = b.ext
			AND a.line_no = b.line_no
		WHERE
			a.rec_id > @rec_id
			AND a.template_code = @template_code
			AND b.order_no IS NULL
			AND a.[status] = 0
		ORDER BY 
			a.rec_id
		
		IF @@ROWCOUNT = 0
			BREAK

		-- Release the po stock
		EXEC dbo.cvo_backorder_processing_unringfence_po_sp  @order_no, @ext, @line_no, @part_no, @location, @template_code	
	END

	RETURN 0

END

GO
GRANT EXECUTE ON  [dbo].[cvo_backorder_processing_clear_orphaned_ringfence_sp] TO [public]
GO
