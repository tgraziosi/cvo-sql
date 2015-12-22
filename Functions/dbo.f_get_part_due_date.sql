SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- Epicor Software (UK) Ltd (c)2013
-- For ClearVision Optical - 68668
-- v1.0 CT 12/06/2013 - Returns due date as a string for a part
-- v1.1 CT 05/08/2013 - New logic
-- v1.2 CB 21/11/2013 - Add sort order

-- SELECT dbo.f_get_part_due_date ('BC804HOR5818','001',6)

CREATE FUNCTION [dbo].[f_get_part_due_date](@part_no	VARCHAR(30),
										@location	VARCHAR(10),
										@qty		DECIMAL(20,8)) 
-- START v1.1
RETURNS DATETIME
--RETURNS VARCHAR(10)
-- END v1.1
AS
BEGIN
	DECLARE @due_date DATETIME,
	-- START v1.1
	@rec_id		INT,
	@po_qty		DECIMAL(20,8),
	@prev_qty	DECIMAL(20,8),
	@to_qty		DECIMAL(20,8),
	@from_qty	DECIMAL(20,8)

	--DECLARE @po TABLE (po_no VARCHAR(16), line_no INT, qty DECIMAL(20,8), inhouse_date DATETIME)

	DECLARE @po TABLE (
		rec_id INT IDENTITY(1,1), 
		po_no VARCHAR(16), 
		line_no INT, 
		qty DECIMAL(20,8), 
		inhouse_date DATETIME, 
		from_qty DECIMAL(20,8), 
		to_qty DECIMAL(20,8) )

	-- Get replenishment moves
	IF EXISTS (SELECT 1 FROM dbo.tdc_soft_alloc_tbl (NOLOCK) WHERE order_no = 0 AND part_no = @part_no AND location = @location)
	BEGIN
		INSERT INTO @po(
			po_no,
			line_no,
			qty,
			inhouse_date,
			from_qty,
			to_qty)
		SELECT
			'REPLEN',
			0,
			SUM(qty) qty,
			DATEADD(d,2,GETDATE()),
			0,
			0
		FROM 
			dbo.tdc_soft_alloc_tbl (NOLOCK) 
		WHERE 
			order_no = 0 
			AND part_no = @part_no 
			AND location = @location
	END
	
	-- Get POs
	INSERT INTO @po (
		po_no,
		line_no,
		inhouse_date,
		qty,
		from_qty,
		to_qty)
	SELECT 
		a.po_no,
		a.po_line,
		a.inhouse_date,
		a.quantity - (a.received + ISNULL(b.qty,0)) available,
		0,
		0
	FROM
		dbo.releases a (NOLOCK)
	LEFT JOIN
		(SELECT po_no, po_line, releases_row_id, SUM(qty_ringfenced - qty_received) as qty 
		 FROM dbo.CVO_backorder_processing_orders_po_xref (NOLOCK)
		 WHERE [status] <> 2
		 GROUP BY po_no, po_line, releases_row_id) b 
	ON
		a.po_no = b.po_no
		AND a.po_line = b.po_line
		AND a.row_id = b.releases_row_id
	WHERE
		a.status = 'O'
		AND a.quantity > a.received
		AND a.part_no = @part_no
		AND a.location = @location
	ORDER BY a.inhouse_date, a.po_no -- v1.2
/*
	-- If there is sufficient stock allocated to replenishment move	
	IF EXISTS (SELECT 1 FROM dbo.tdc_soft_alloc_tbl WHERE order_no = 0 AND part_no = @part_no AND location = @location AND qty >=@qty)
	BEGIN
		SET @due_date = DATEADD(d,2,GETDATE())
		RETURN CONVERT(VARCHAR(10),@due_date,101)	
	END

	-- Get the in-house date from the next PO for the part
	INSERT INTO @po (
		po_no,
		line_no,
		inhouse_date,
		qty)
	SELECT 
		a.po_no,
		a.po_line,
		a.inhouse_date,
		a.quantity - (a.received + ISNULL(b.qty,0)) available
	FROM
		dbo.releases a (NOLOCK)
	LEFT JOIN
		(SELECT po_no, po_line, releases_row_id, SUM(qty_ringfenced - qty_received) as qty 
		 FROM dbo.CVO_backorder_processing_orders_po_xref (NOLOCK)
		 WHERE [status] <> 2
		 GROUP BY po_no, po_line, releases_row_id) b 
	ON
		a.po_no = b.po_no
		AND a.po_line = b.po_line
		AND a.row_id = b.releases_row_id
	WHERE
		a.status = 'O'
		AND a.quantity > a.received
		AND a.part_no = @part_no
		AND a.location = @location
	

	SELECT TOP 1 
		@due_date = inhouse_date 
	FROM 
		@po
	WHERE
		qty >= @qty
	ORDER BY
		inhouse_date 
	*/

	-- Calculate qty ranges in table
	SET @rec_id = 0
	SET @prev_qty = 0
	WHILE 1=1
	BEGIN
		SELECT TOP 1
			@rec_id = rec_id,
			@po_qty = qty,
			@from_qty = from_qty,
			@to_qty = to_qty
		FROM
			@po
		WHERE
			rec_id > @rec_id
		ORDER BY 
			rec_id

		IF @@ROWCOUNT = 0
			BREAK

		
		SET @from_qty = @prev_qty + 1
		SET @to_qty = @prev_qty + @po_qty
		SET @prev_qty = @to_qty 

		UPDATE 
			@po
		SET
			from_qty = @from_qty,
			to_qty = @to_qty
		WHERE
			rec_id = @rec_id
			
	END		

	-- Get due date
	SELECT 
		@due_date = inhouse_date
	FROM
		@po
	WHERE
		from_qty <= @qty
		AND to_qty >= @qty
		
	-- END v1.1

	IF @due_date IS NULL
	BEGIN

		-- Get CS date from part
		SELECT 
			@due_date = field_29
		FROM
			dbo.inv_master_add (NOLOCK)
		WHERE
			part_no = @part_no
	END

	-- START v1.1
	RETURN @due_date

	/*
	IF @due_date IS NULL
	BEGIN
		RETURN ''
	END
	
	RETURN CONVERT(VARCHAR(10),@due_date,101)
	*/

END
GO
GRANT REFERENCES ON  [dbo].[f_get_part_due_date] TO [public]
GO
GRANT EXECUTE ON  [dbo].[f_get_part_due_date] TO [public]
GO
