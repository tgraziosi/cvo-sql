SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- exec dbo.cvo_assigned_stock_sp '001','bcgcol5316'
CREATE PROC [dbo].[cvo_assigned_stock_sp]	@location	varchar(10),
										@part_no	varchar(30)
AS
BEGIN
	-- DIRECTIVES
	SET NOCOUNT ON

	-- Declarations
	DECLARE	@row_id			int,
			@last_row_id	int,
			@order_no		int,
			@order_ext		int,
			@line_no		int,
			@qty			decimal(20,8),
			@avail_qty		decimal(20,8)

	-- Working tables
	CREATE TABLE #avail_stock (
		location		varchar(10),
		part_no			varchar(30),
		bin_no			varchar(20),
		qty				decimal(20,8))

	CREATE TABLE #alloc_stock (
		location		varchar(10),
		part_no			varchar(30),
		bin_no			varchar(20),
		qty				decimal(20,8))

	CREATE TABLE #assigned_stock (
		row_id			int IDENTITY(1,1),
		soft_alloc_no	int,
		order_no		int,
		order_ext		int,
		line_no			int,
		location		varchar(10),
		part_no			varchar(30),
		ordered			decimal(20,8),
		qty_assigned	decimal(20,8))

	-- Insert data into working table
	INSERT	#avail_stock
	SELECT	a.location,
			a.part_no,
			a.bin_no,
			SUM(qty) qty
	FROM	lot_bin_stock a (NOLOCK)
	JOIN	tdc_bin_master b (NOLOCK)
	ON		a.location = b.location
	AND		a.bin_no = b.bin_no
	WHERE	b.usage_type_code IN ('REPLENISH','OPEN')
	AND		ISNULL(b.bm_udef_e,0) <> 1
	AND		a.location = @location
	AND		a.part_no = @part_no
	GROUP BY a.location,
			a.part_no,
			a.bin_no

	INSERT	#alloc_stock
	SELECT	c.location,
			c.part_no,
			c.bin_no,
			SUM(c.qty) qty
	FROM	tdc_soft_alloc_tbl c (NOLOCK)
	JOIN	lot_bin_stock a (NOLOCK)
	ON		c.location = a.location
	AND		c.part_no = a.part_no
	AND		c.bin_no = a.bin_no
	JOIN	tdc_bin_master b (NOLOCK)
	ON		a.location = b.location
	AND		a.bin_no = b.bin_no
	WHERE	b.usage_type_code IN ('REPLENISH','OPEN')
	AND		ISNULL(b.bm_udef_e,0) <> 1
	AND		c.location = @location
	AND		c.part_no = @part_no
	GROUP BY c.location,
			c.part_no,
			c.bin_no

	UPDATE	a
	SET		qty = a.qty - b.qty
	FROM	#avail_stock a
	JOIN	#alloc_stock b
	ON		a.location = b.location
	AND		a.part_no = b.part_no
	AND		a.bin_no = b.bin_no

	INSERT	#assigned_stock (soft_alloc_no, order_no, order_ext, line_no, location, part_no, ordered)
	SELECT	soft_alloc_no,
			order_no,
			order_ext,
			line_no,
			location,
			part_no,
			CASE WHEN deleted = 1 THEN (quantity * -1) ELSE quantity END
	FROM	cvo_soft_alloc_det	(NOLOCK)
	WHERE	status IN (0,1,-1,-4)
	AND		location = @location
	AND		part_no = @part_no
	ORDER BY soft_alloc_no ASC

	SELECT	@avail_qty = SUM(qty)
	FROM	#avail_stock
	
	SET @last_row_id = 0

	SELECT	TOP 1 @row_id = row_id,
			@qty = ordered
	FROM	#assigned_stock
	WHERE	row_id > @last_row_id
	ORDER BY row_id ASC

	WHILE (@@ROWCOUNT <> 0)
	BEGIN

		IF (@qty <= @avail_qty)
		BEGIN
			UPDATE	#assigned_stock
			SET		qty_assigned = @qty
			WHERE	row_id = @row_id
		END
		ELSE
		BEGIN
			UPDATE	#assigned_stock
			SET		qty_assigned = @avail_qty
			WHERE	row_id = @row_id
			BREAK
		END

		SET	@avail_qty = @avail_qty - @qty

		IF (@avail_qty <= 0)
			BREAK

		SET @last_row_id = @row_id

		SELECT	TOP 1 @row_id = row_id,
				@qty = ordered
		FROM	#assigned_stock
		WHERE	row_id > @last_row_id
		ORDER BY row_id ASC

	END

	UPDATE	#assigned_stock
	SET		qty_assigned = 0.00
	WHERE	qty_assigned IS NULL

	SELECT * FROM #assigned_stock ORDER BY row_id

END
GO
GRANT EXECUTE ON  [dbo].[cvo_assigned_stock_sp] TO [public]
GO
