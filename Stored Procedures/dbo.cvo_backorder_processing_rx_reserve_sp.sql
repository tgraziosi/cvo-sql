SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[cvo_backorder_processing_rx_reserve_sp]	@template_code varchar(30), 
														@location varchar(10)
AS
BEGIN
	-- DIRECTIVES
	SET NOCOUNT ON

	-- DECLARATIONS
	DECLARE @part_no			varchar(30),
			@available			decimal(20,8),
			@po_stat			int,
			@bo_stat			int,
			@po_no				varchar(10),	
			@rec_id				int,
			@required			decimal(20,8),
			@allocated			decimal(20,8),
			@stock_allocated	decimal(20,8),
			@change				smallint,
			@orig_available		decimal(20,8)

	-- WORKING TABLES
	CREATE TABLE #rx_stock(
		part_no			varchar(30),
		available		decimal(20,8),
		po_stat			int)


	CREATE TABLE #available_stock (
		bin_no		varchar(30),
		in_stock	decimal(20,8))

	CREATE TABLE #allocated_stock (
		bin_no		varchar(30),
		allocated	decimal(20,8))

	-- PROCESSING
	INSERT #rx_stock (part_no, available, po_stat)
	SELECT	part_no,
			0,
			0
	FROM	dbo.CVO_backorder_processing_orders (NOLOCK)
	WHERE	template_code = @template_code
	GROUP BY part_no

	-- Loop through records and get stock
	SET @part_no = ''

	WHILE (1 = 1)
	BEGIN
		SELECT	TOP 1 @part_no = part_no
		FROM	#rx_stock
		WHERE	part_no > @part_no
		ORDER BY part_no
		
		IF (@@ROWCOUNT = 0)
			BREAK

		-- Check if the backorder date has been reached
		IF EXISTS (SELECT 1 FROM inv_master_add (NOLOCK) WHERE part_no = @part_no AND ISNULL(datetime_2,(GETDATE() + 1)) < GETDATE())
			SET @bo_stat = 1
		ELSE
			SET @bo_stat = 0			
		
		-- Check for POs
		SET @po_no = NULL
		SELECT	 TOP 1 @po_no = po_no
		FROM	releases (NOLOCK)
		WHERE	location = @location
		AND		part_no = @part_no
		AND		status = 'O'
		AND		quantity > received
-- v1.2	AND		inhouse_date >= GETDATE() -- v1.1
		ORDER BY inhouse_date DESC -- v1.1

		IF (@po_no IS NOT NULL)
		BEGIN
			SELECT	@po_stat = CASE WHEN DATEDIFF(d,GETDATE(),inhouse_date) >= 15 THEN 5 ELSE 4 END -- v1.1
			FROM	releases (NOLOCK)
			WHERE	po_no = @po_no
			AND		location = @location
			AND		part_no = @part_no
			AND		status = 'O'
			AND		quantity > received
-- v1.2		AND		inhouse_date >= GETDATE() -- v1.1	

			SET @bo_stat = 0 -- v1.3
								
		END
		ELSE
		BEGIN
			SET @po_stat = 2
		END

		IF (@bo_stat = 1)
			SET @po_stat = 3

		-- Find reserve stock
		TRUNCATE TABLE #available_stock
		TRUNCATE TABLE #allocated_stock

		INSERT	#available_stock
		SELECT	a.bin_no, a.qty
		FROM	lot_bin_stock a (NOLOCK)
		JOIN	tdc_bin_master b (NOLOCK)
		ON		a.location = b.location		
		AND		a.bin_no = b.bin_no
		WHERE	a.location = @location
		AND		a.part_no = @part_no
		AND		b.group_code = 'RESERVE'
		AND		b.usage_type_code IN ('OPEN','REPLENISH')
	
		INSERT	#allocated_stock
		SELECT	a.bin_no, SUM(a.qty)
		FROM	tdc_soft_alloc_tbl a (NOLOCK)
		JOIN	tdc_bin_master b (NOLOCK)
		ON		a.location = b.location		
		AND		a.bin_no = b.bin_no
		WHERE	a.location = @location
		AND		a.part_no = @part_no
		AND		b.group_code = 'RESERVE'
		AND		b.usage_type_code IN ('OPEN','REPLENISH')
		GROUP BY a.bin_no

		UPDATE	a
		SET		in_stock =  a.in_stock - b.allocated
		FROM	#available_stock a
		JOIN	#allocated_stock b
		ON		a.bin_no = b.bin_no

		UPDATE	#available_stock
		SET		in_stock = 0
		WHERE	in_stock < 0

		SET @available = 0

		SELECT	@available = SUM(in_stock)
		FROM	#available_stock

		IF (@po_stat = 5)
			SET @available = @available - 10
		IF (@po_stat = 4)
			SET @available = @available - 5

		IF (@available < 0)
			SET @available = 0

		UPDATE	#rx_stock
		SET		available = ISNULL(@available,0),
				po_stat = @po_stat
		WHERE	part_no = @part_no

	END

	UPDATE	a
	SET		po_locked = (b.po_stat * -1)
	FROM	dbo.CVO_backorder_processing_orders a
	JOIN	#rx_stock b
	ON		a.part_no = b.part_no

	-- Loop through records and apply stock
	SET @part_no = ''

	WHILE (1 = 1)
	BEGIN
		SELECT	TOP 1 @part_no = part_no,
				@available = ISNULL(available,0),
				@po_stat = po_stat
		FROM	#rx_stock	
		WHERE	part_no > @part_no
		AND		available > 0
		AND		po_stat <> 2
		ORDER BY part_no
	
		IF (@@ROWCOUNT = 0)
			BREAK
		
		-- Apply to order
		SET @rec_id = 0

		WHILE 1=1
		BEGIN

			IF (@available <= 0)
				BREAK

			SELECT	TOP 1 @rec_id = rec_id,
					@required = qty,
					@allocated = 0,
					@stock_allocated = 0
			FROM	dbo.CVO_backorder_processing_orders (NOLOCK)
			WHERE	template_code = @template_code
			AND		part_no = @part_no
			AND		rec_id > @rec_id
			AND		processed = 0
			AND		stock_locked = 0 
			ORDER BY rec_id

			IF (@@ROWCOUNT = 0)
				BREAK

			-- Store stock levels before applying to this order
			SELECT	@orig_available = @available

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
			
			-- Update record
			IF @change = 1
			BEGIN
				UPDATE	dbo.CVO_backorder_processing_orders
				SET		allocated = @allocated,
						stock_allocated = @stock_allocated,
						process = 1,
						available = @orig_available,
						is_available = 1
				WHERE	rec_id = @rec_id
			END
		END
	END


END
	

GO
GRANT EXECUTE ON  [dbo].[cvo_backorder_processing_rx_reserve_sp] TO [public]
GO
