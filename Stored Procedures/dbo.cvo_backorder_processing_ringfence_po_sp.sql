SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*


*/

CREATE PROC [dbo].[cvo_backorder_processing_ringfence_po_sp]   (@order_no		INT,
															@ext			INT,
															@line_no		INT,	
															@part_no		VARCHAR(30),
															@location		VARCHAR(10),
															@qty			DECIMAL(20,8),
															@to_bin_no		VARCHAR(12),
															@template_code	VARCHAR(30))

AS
BEGIN
	DECLARE @po_rec_id			INT,
			@po_row_id			INT,
			@po_qty				DECIMAL(20,8),
			@row_id				INT,
			@po_no				VARCHAR(20),
			@po_line			INT,
			@po_applied			DECIMAL(20,8),
			@po_due_from		DATETIME,
			@po_due_to			DATETIME

	-- Load template info
	SELECT
		@po_due_from = po_due_from,
		@po_due_to = po_due_to
	FROM 
		dbo.CVO_backorder_processing_templates (NOLOCK)
	WHERE 
		template_code = @template_code


	-- Create temporary table
	CREATE TABLE #po_details (
		rec_id			INT IDENTITY(1,1),
		part_no			VARCHAR(30),
		po_no			VARCHAR(20),
		line			INT,
		qty				DECIMAL(20,8),
		due_date		DATETIME,
		row_id			INT)

	-- Get POs containing this part
	EXEC dbo.cvo_backorder_processing_po_stock_sp @location, @part_no, @po_due_from, @po_due_to, 1

	-- Loop through and consume PO qty in date order
	SET @po_applied = @qty
	SET @po_rec_id = 0
	WHILE 1=1
	BEGIN
		IF @po_applied <= 0
			BREAK

		SELECT TOP 1
			@po_rec_id = rec_id,
			@po_no = po_no,
			@po_line = line,
			@po_qty = qty,
			@po_row_id = row_id
		FROM
			#po_details
		WHERE
			rec_id  > @po_rec_id
			AND part_no = @part_no 
			AND qty > 0
		ORDER BY
			rec_id

		IF @@ROWCOUNT = 0
			BREAK

		IF @po_applied <= @po_qty
		BEGIN
			-- Write xref record
			INSERT CVO_backorder_processing_orders_po_xref (
				template_code,
				order_no,
				ext,
				line_no,
				part_no,
				po_no,
				po_line,
				qty_reqd,
				qty_ringfenced,
				qty_received,
				qty_ready_to_process,
				qty_processed,
				releases_row_id,
				[status])
			SELECT
				@template_code,
				@order_no,
				@ext,
				@line_no,
				@part_no,
				@po_no,
				@po_line,
				@qty,
				@po_applied,
				0,
				0,
				0,
				@po_row_id,
				0

			SET @po_qty = @po_qty - @po_applied
			SET @po_applied = 0
		END
		ELSE
		BEGIN
			-- Write xref record
			INSERT CVO_backorder_processing_orders_po_xref (
				template_code,
				order_no,
				ext,
				line_no,
				part_no,
				po_no,
				po_line,
				qty_reqd,
				qty_ringfenced,
				qty_received,
				releases_row_id)
			SELECT
				@template_code,
				@order_no,
				@ext,
				@line_no,
				@part_no,
				@po_no,
				@po_line,
				@qty,
				@po_qty,
				0,
				@po_row_id

			SET @po_applied = @po_applied - @po_qty
			SET @po_qty = 0
		END

		-- Update record
		UPDATE
			#po_details
		SET
			qty = @po_qty
		WHERE
			rec_id  = @po_rec_id
	END

	RETURN 0
END

GO
GRANT EXECUTE ON  [dbo].[cvo_backorder_processing_ringfence_po_sp] TO [public]
GO
