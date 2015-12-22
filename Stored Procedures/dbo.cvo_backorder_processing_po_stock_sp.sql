SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
  
CREATE PROC [dbo].[cvo_backorder_processing_po_stock_sp]	@location		varchar(10),
														@part_no		varchar(30),
														@po_due_from	DATETIME,
														@po_due_to		DATETIME,
														@stock_only		SMALLINT -- 0 = return stock qty, 1 = return POs
AS
BEGIN
	-- Declarations
	DECLARE	@ret_val		decimal(20,8)

	SET @ret_val = 0

	IF @stock_only = 1
	BEGIN
		-- Retrieve PO details
		INSERT INTO #po_details (
			part_no,
			po_no,
			line,
			qty,
			row_id)
		SELECT
			a.part_no,
			a.po_no,
			a.po_line,
			CASE WHEN a.quantity > a.received THEN (a.quantity - a.received) - ISNULL(b.qty,0) ELSE 0 END,
			a.row_id
		FROM
			dbo.releases a (NOLOCK)
		LEFT JOIN
			dbo.cvo_backorder_processing_po_qty_vw b (NOLOCK)
		ON
			a.row_id = b.releases_row_id
		WHERE
			a.location = @location
			AND a.part_no = @part_no
			AND a.[status] = 'O'
			AND (@po_due_from IS NULL OR a.due_date >= @po_due_from)
			AND (@po_due_to IS NULL OR a.due_date <= @po_due_to)
		ORDER BY
			a.due_date
		
		SET @ret_val = 0
	END
	ELSE
	BEGIN

		-- Retrieve the available PO stock
		SELECT
			@ret_val = 	ISNULL(SUM(CASE WHEN quantity > received THEN (a.quantity - a.received) - ISNULL(b.qty,0) ELSE 0 END),0)
		FROM
			dbo.releases a (NOLOCK)
		LEFT JOIN
			dbo.cvo_backorder_processing_po_qty_vw b (NOLOCK)
		ON
			a.row_id = b.releases_row_id
		WHERE
			a.location = @location
			AND a.part_no = @part_no
			AND a.[status] = 'O'
			AND (@po_due_from IS NULL OR a.due_date >= @po_due_from)
			AND (@po_due_to IS NULL OR a.due_date <= @po_due_to)

		IF ISNULL(@ret_val,0) < 0 
		BEGIN
			SET @ret_val = 0
		END
	END

	-- Return value
	RETURN	@ret_val
	
END

GO
GRANT EXECUTE ON  [dbo].[cvo_backorder_processing_po_stock_sp] TO [public]
GO
