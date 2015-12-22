SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[cvo_transfer_summary_sp]	@xfer_no		int
AS
BEGIN
	-- Declarations
	DECLARE	@row_id					int,
			@last_row_id			int,
			@location				varchar(10),
			@part_no				varchar(30),
			@instock				decimal(20,8),
			@allocated				decimal(20,8),
			@quarantine				decimal(20,8),
			@available				decimal(20,8),
			@soft_alloc_qty			decimal(20,8),
			@alloc_to_this_order	DECIMAL(20,8),	-- v1.1
			@qty_picked				decimal(20,8)  -- v1.4

	-- Working table
	DECLARE @returndata TABLE
	(
		row_id			int identity(1,1),
		type_code		varchar(20),
		location		varchar(10),
		part_no			varchar(30),
		avail_quantity	decimal(20,8),
		quantity		decimal(20,8)
	)

	DECLARE @tdc_data TABLE
	(
		location		varchar(10),
		part_no			varchar(30),
		allocated_amt	decimal(20,8),
		quarantined_amt	decimal(20,8),
		apptype			varchar(20)
	)

	
	INSERT	@returndata (type_code, location, part_no, avail_quantity, quantity)
	SELECT	b.type_code, a.from_loc, a.part_no, 0, sum(a.ordered)
	FROM 	xfer_list a (NOLOCK) 
	JOIN	inv_master b (NOLOCK) 
	ON		a.part_no = b.part_no 
	WHERE 	a.xfer_no = @xfer_no 
	GROUP BY b.type_code, a.from_loc, a.part_no
	
	-- Update with the available quantites
	SET @last_row_id = 0

	SELECT	TOP 1 @row_id = row_id,
			@location = location,
			@part_no = part_no
	FROM	@returndata
	WHERE	row_id > @last_row_id
	ORDER BY row_id ASC

	WHILE @@ROWCOUNT <> 0
	BEGIN

		-- Get the instock figure
		SELECT	@instock = in_stock from inventory where location = @location and part_no = @part_no
		
		-- Get the allocated and quarantined quantities
		DELETE	@tdc_data
		INSERT	@tdc_data EXEC tdc_get_alloc_qntd_sp @location, @part_no
		SELECT	@allocated = allocated_amt,
				@quarantine = quarantined_amt
		FROM	@tdc_data
		WHERE	location = @location
		AND		part_no = @part_no

		-- Get qty soft allocated to other orders
		SELECT	@soft_alloc_qty = SUM(quantity)
		FROM	dbo.cvo_soft_alloc_det (NOLOCK)
		WHERE	location = @location
		AND		part_no = @part_no
		AND		status NOT IN (-2,-3)
	
		IF @soft_alloc_qty IS NULL
			SET @soft_alloc_qty = 0

		
		-- START v1.1 - get qty hard allocated to this transfer
		SET @alloc_to_this_order = 0

		SELECT 
			@alloc_to_this_order = SUM(qty)  
		FROM
			dbo.tdc_soft_alloc_tbl (NOLOCK)
		WHERE
			order_no = @xfer_no 
			AND order_ext = 0
			AND order_type = 'T' 
			AND location = @location  
			AND  part_no = @part_no
			AND	order_no <> 0 -- v1.3
		


		SET @qty_picked = 0

		SELECT	@qty_picked = SUM(shipped)
		FROM	tdc_dist_item_list (NOLOCK)
		WHERE	order_no = @xfer_no
		AND		part_no = @part_no
		AND		[function] = 'T'

		IF @qty_picked IS NULL
			SET @qty_picked = 0




		-- SELECT	@available = @instock - (@allocated + @quarantine) - ISNULL(@soft_alloc_qty,0)		
		SELECT @available = @instock - (@allocated + @quarantine) - ISNULL(@soft_alloc_qty,0) + ISNULL(@alloc_to_this_order,0) + @qty_picked -- v1.1 v1.4

		-- END v1.1

		IF @available < 0
			SET @available = 0

		UPDATE	@returndata
		SET		avail_quantity = CASE WHEN @available >= quantity THEN quantity ELSE @available END
		WHERE	row_id = @row_id

		SET @last_row_id = @row_id

		SELECT	TOP 1 @row_id = row_id,
				@location = location,
				@part_no = part_no
		FROM	@returndata
		WHERE	row_id > @last_row_id
		ORDER BY row_id ASC
	END

	-- return the summary data
	SELECT	type_code + ' x ' +  LTRIM(STR(SUM(quantity))) + CASE WHEN (SUM(avail_quantity) < SUM(quantity)) THEN ' (' +  LTRIM(STR(SUM(quantity) - SUM(avail_quantity))) + ' unavailable)' ELSE '' END
	FROM	@returndata
	GROUP BY type_code
	HAVING SUM(quantity) <> 0

END
GO
GRANT EXECUTE ON  [dbo].[cvo_transfer_summary_sp] TO [public]
GO
