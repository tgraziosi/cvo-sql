SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[cvo_direct_putaway_sp]	@receipt_no int,
										@po_no varchar(20),
										@po_line int,
										@location varchar(10),
										@part_no varchar(30),
										@bin_no	varchar(12),
										@qty decimal(20,8),
										@lot varchar(25),
										@release_date datetime,
										@tran_id int OUTPUT
AS
BEGIN
	-- DIRECTIVES
	SET NOCOUNT ON

	-- DECLARATIONS
	DECLARE	@FT_threshold	decimal(20,8),
			@qty_remaining	decimal(20,8),
			@row_id			int,
			@last_row_id	int,
			@new_qty		decimal(20,8),
			@fill_qty		decimal(20,8),
			@bin_type		int,
			@alloc_qty		decimal(20,8),
			@use_FT			int,
			@who			varchar(50),
			@new_bin_no		varchar(12),
			@consumed_qty	decimal(20,8),
			@icount			int,
			@ft_qty			decimal(20,8),
			@ft_qty2		decimal(20,8) -- v1.3

	-- WORKING TABLES
	CREATE TABLE #cvo_putaways (
		row_id		int IDENTITY(1,1),
		bin_type	int,
		bin_no		varchar(12),
		qty			decimal(20,8),
		fill_qty	decimal(20,8),
		pick_qty	decimal(20,8),
		put_qty		decimal(20,8),
		putaway_qty	decimal(20,8))

	CREATE TABLE #cvo_committed (
		bin_no		varchar(12),
		qty			decimal(20,8))

	--PROCESSING
	IF NOT EXISTS (SELECT 1 FROM tdc_bin_master (NOLOCK) WHERE location = @location AND bin_no = @bin_no AND usage_type_code = 'RECEIPT')
	BEGIN
		DROP TABLE #cvo_putaways
		DROP TABLE #cvo_committed
		RETURN 0
	END

	-- Get config setting for fast track threshold
	SELECT @FT_threshold = value_str FROM tdc_config (NOLOCK) WHERE [function] = 'FT_CART_THRESHOLD'
	IF (@FT_threshold IS NULL)
		SET @FT_threshold = 10

	-- v1.4 Start
	-- Get Fast Track Bin List (where stock exists)
	INSERT	#cvo_putaways (bin_type, bin_no, qty, fill_qty, pick_qty, put_qty, putaway_qty)
	SELECT	1, a.bin_no, 0, 0, 0, 0, 0
	FROM	tdc_bin_master a (NOLOCK)
	JOIN	lot_bin_stock b (NOLOCK)
	ON		a.location = b.location
	AND		a.bin_no = b.bin_no
	WHERE	a.location = @location
	AND		a.group_code = 'PICKAREA'
	AND		a.usage_type_code IN ('OPEN','REPLENISH')
	AND		a.status = 'A'
	AND		b.part_no = @part_no
	AND		LEFT(a.bin_no,4) = 'ZZZ-'

	IF (@@ROWCOUNT = 0)
	BEGIN
		-- Get Fast Track Bin List (where empty)
		INSERT	#cvo_putaways (bin_type, bin_no, qty, fill_qty, pick_qty, put_qty, putaway_qty)
		SELECT	1, a.bin_no, 0, 0, 0, 0, 0
		FROM	tdc_bin_master a (NOLOCK)
		LEFT JOIN lot_bin_stock b (NOLOCK)
		ON		a.location = b.location
		AND		a.bin_no = b.bin_no
		WHERE	a.location = @location
		AND		a.group_code = 'PICKAREA'
		AND		a.usage_type_code IN ('OPEN','REPLENISH')
		AND		a.status = 'A'
		AND		b.part_no IS NULL
		AND		LEFT(a.bin_no,4) = 'ZZZ-'

		IF (@@ROWCOUNT = 0)
		BEGIN
			-- Get Fast Track Bin List (any)
			INSERT	#cvo_putaways (bin_type, bin_no, qty, fill_qty, pick_qty, put_qty, putaway_qty)
			SELECT	1, bin_no, 0, 0, 0, 0, 0
			FROM	tdc_bin_master (NOLOCK)
			WHERE	location = @location
			AND		group_code = 'PICKAREA'
			AND		usage_type_code IN ('OPEN','REPLENISH')
			AND		status = 'A'
			AND		LEFT(bin_no,4) = 'ZZZ-'
		END
	END
	

	-- Get Reserve Bin List
	INSERT	#cvo_putaways (bin_type, bin_no, qty, fill_qty, pick_qty, put_qty, putaway_qty)
	SELECT	2, a.bin_no, 0, a.qty, 0, 0, 0 -- v1.4
	FROM	tdc_bin_part_qty a (NOLOCK)
	JOIN	tdc_bin_master b (NOLOCK)
	ON		a.location = b.location
	AND		a.bin_no = b.bin_no
	WHERE	a.location = @location
	AND		a.part_no = @part_no
	AND		b.group_code = 'RESERVE'
	AND		b.usage_type_code IN ('OPEN','REPLENISH')
	AND		b.status = 'A'
	ORDER BY a.seq_no ASC

	-- Get Forward Pick Bin List
	INSERT	#cvo_putaways (bin_type, bin_no, qty, fill_qty, pick_qty, put_qty, putaway_qty)
	SELECT	3, a.bin_no, 0, a.qty, 0, 0, 0 -- v1.4
	FROM	tdc_bin_part_qty a (NOLOCK)
	JOIN	tdc_bin_master b (NOLOCK)
	ON		a.location = b.location
	AND		a.bin_no = b.bin_no
	WHERE	a.location = @location
	AND		a.part_no = @part_no
	AND		b.group_code = 'PICKAREA'
	AND		b.usage_type_code IN ('OPEN','REPLENISH')
	AND		b.status = 'A'
	ORDER BY a.seq_no ASC


	-- Get High Bay Bin List
	-- v1.6 Start
	INSERT	#cvo_putaways (bin_type, bin_no, qty, fill_qty, pick_qty, put_qty, putaway_qty)
	SELECT	4, a.bin_no, 0, a.qty, 0, 0, 0 -- v1.4
	FROM	tdc_bin_part_qty a (NOLOCK)
	JOIN	tdc_bin_master b (NOLOCK)
	ON		a.location = b.location
	AND		a.bin_no = b.bin_no
	WHERE	a.location = @location
	AND		a.part_no = @part_no
	AND		b.group_code = 'HIGHBAY'
	AND		b.usage_type_code IN ('OPEN','REPLENISH')
	AND		b.status = 'A'
	ORDER BY a.seq_no ASC

--	INSERT	#cvo_putaways (bin_type, bin_no, qty, fill_qty, pick_qty, put_qty, putaway_qty)
--	SELECT	4, a.bin_no, 0, a.min_qty, 0, 0, 0
--	FROM	CVO_bin_replenishment_tbl a (NOLOCK)
--	JOIN	tdc_bin_master b (NOLOCK)
--	ON		a.bin_no = b.bin_no
--	WHERE	b.location = @location
--	AND		a.part_no = @part_no
--	AND		b.group_code = 'HIGHBAY'
--	AND		b.usage_type_code IN ('OPEN','REPLENISH')
--	AND		b.status = 'A'
	-- v1.6 End

	-- v1.1 Start
	-- Get Bulk Bin List
	INSERT	#cvo_putaways (bin_type, bin_no, qty, fill_qty, pick_qty, put_qty, putaway_qty)
	SELECT	5, a.bin_no, 0, a.qty, 0, 0, 0
	FROM	tdc_bin_part_qty a (NOLOCK)
	JOIN	tdc_bin_master b (NOLOCK)
	ON		a.location = b.location
	AND		a.bin_no = b.bin_no
	WHERE	a.location = @location
	AND		a.part_no = @part_no
	AND		b.group_code = 'BULK'
	AND		b.usage_type_code IN ('OPEN','REPLENISH')
	AND		b.status = 'A'
	ORDER BY a.seq_no ASC

	IF (@@ROWCOUNT = 0)
	BEGIN
		-- Get Bulk Bin List (Where stock exists)
		INSERT	#cvo_putaways (bin_type, bin_no, qty, fill_qty, pick_qty, put_qty, putaway_qty)
		SELECT	5, a.bin_no, a.qty, 0, 0, 0, 0
		FROM	lot_bin_stock a (NOLOCK)
		JOIN	tdc_bin_master b (NOLOCK)
		ON		a.location = b.location
		AND		a.bin_no = b.bin_no
		WHERE	a.location = @location
		AND		a.part_no = @part_no
		AND		b.group_code = 'BULK'
		AND		b.usage_type_code IN ('OPEN','REPLENISH')
		AND		b.status = 'A'
	END
	-- v1.1 End

	IF (@@ROWCOUNT = 0) -- No bulk bins contain the part so add an empty one
	BEGIN
		INSERT	#cvo_putaways (bin_type, bin_no, qty, fill_qty, pick_qty, put_qty, putaway_qty)	
		SELECT	5, '', 0, 0, 0, 0, 0
	END

	-- Update the commited quantities due to be picked
	-- Picks
	TRUNCATE TABLE #cvo_committed

	INSERT	#cvo_committed
	SELECT	a.bin_no, SUM(a.qty_to_process)
	FROM	tdc_pick_queue a (NOLOCK)
	JOIN	#cvo_putaways b
	ON		a.bin_no = b.bin_no
	WHERE	a.location = @location
	AND		a.part_no = @part_no
	AND		a.trans LIKE '%PICK'
	GROUP BY a.bin_no	

	UPDATE	a
	SET		pick_qty = b.qty
	FROM	#cvo_putaways a
	JOIN	#cvo_committed b
	ON		a.bin_no = b.bin_no

	-- Bin Moves Out
	TRUNCATE TABLE #cvo_committed

	INSERT	#cvo_committed
	SELECT	a.bin_no, SUM(a.qty_to_process)
	FROM	tdc_pick_queue a (NOLOCK)
	JOIN	#cvo_putaways b
	ON		a.bin_no = b.bin_no
	WHERE	a.location = @location
	AND		a.part_no = @part_no
	AND		a.trans = 'MGTB2B'	
	GROUP BY a.bin_no

	UPDATE	a
	SET		pick_qty = a.pick_qty + b.qty
	FROM	#cvo_putaways a
	JOIN	#cvo_committed b
	ON		a.bin_no = b.bin_no

	-- Bin Moves In
	TRUNCATE TABLE #cvo_committed

	INSERT	#cvo_committed
	SELECT	a.next_op, SUM(a.qty_to_process)
	FROM	tdc_pick_queue a (NOLOCK)
	JOIN	#cvo_putaways b
	ON		a.bin_no = b.bin_no
	WHERE	a.location = @location
	AND		a.part_no = @part_no
	AND		a.trans = 'MGTB2B'	
	GROUP BY a.next_op

	UPDATE	a
	SET		pick_qty = a.pick_qty - b.qty
	FROM	#cvo_putaways a
	JOIN	#cvo_committed b
	ON		a.bin_no = b.bin_no

	-- Puts
	TRUNCATE TABLE #cvo_committed

	INSERT	#cvo_committed
	SELECT	a.next_op, SUM(a.qty_to_process)
	FROM	tdc_put_queue a (NOLOCK)
	JOIN	#cvo_putaways b
	ON		a.next_op = b.bin_no -- v1.1
	WHERE	a.location = @location
	AND		a.part_no = @part_no
	GROUP BY a.next_op

	UPDATE	a
	SET		put_qty = b.qty
	FROM	#cvo_putaways a
	JOIN	#cvo_committed b
	ON		a.bin_no = b.bin_no

	-- Bin Quantities
	UPDATE	a
	SET		qty = b.qty
	FROM	#cvo_putaways a
	JOIN	lot_bin_stock b (NOLOCK)
	ON		a.bin_no = b.bin_no
	WHERE	b.location = @location
	AND		b.part_no = @part_no

	-- Get open orders and backorders
	SET @use_FT = 0
	SET @alloc_qty = 0

	SELECT	@alloc_qty = SUM(a.ordered - a.shipped) - SUM(ISNULL(b.qty,0))
	FROM	ord_list a (NOLOCK)
	LEFT JOIN tdc_soft_alloc_tbl b (NOLOCK)
	ON		a.order_no = b.order_no
	AND		a.order_ext = b.order_ext
	AND		a.line_no = b.line_no
	WHERE	a.location = @location
	AND		a.part_no = @part_no
	AND		a.status < 'R'
	AND		(b.order_type = 'S' OR b.order_type IS NULL)

	SET @ft_qty = 0
	SELECT	@ft_qty = SUM(qty)
	FROM	#cvo_putaways
	WHERE	bin_type = 1 -- v1.4

	-- v1.3 Start
	SET @ft_qty2 = 0
	SELECT	@ft_qty2 = SUM(qty_to_process)
	FROM	tdc_put_queue (NOLOCK)
	WHERE	location = @location
	AND		part_no = @part_no
	AND		next_op LIKE 'ZZZ-%'

	IF (@ft_qty2 IS NULL)
		SET @ft_qty2 = 0

	SET @ft_qty = @ft_qty + @ft_qty2
	-- v1.3 End

	IF (@alloc_qty IS NULL)
		SET @alloc_qty = 0

	SET @alloc_qty = @alloc_qty - ISNULL(@ft_qty,0)

	IF (@alloc_qty >= @FT_threshold)
		SET @use_FT = 1

	-- Check for backorder processing consuming the PO
	IF EXISTS (SELECT 1 FROM CVO_backorder_processing_orders_po_xref_trans (NOLOCK) WHERE tran_id = @tran_id)
	BEGIN
		SELECT	@consumed_qty = qty
		FROM	CVO_backorder_processing_orders_po_xref_trans (NOLOCK) 
		WHERE	tran_id = @tran_id
	
		IF (@consumed_qty IS NOT NULL)
		BEGIN
			SET @qty = @qty - @consumed_qty
		
			IF (@qty < 0) 
			BEGIN
				SET @qty = 0
				DROP TABLE #cvo_putaways
				DROP TABLE #cvo_committed
				RETURN 0
			END
		END
	END

	-- v1.1 Start
	DELETE	#cvo_putaways
	WHERE	(fill_qty - put_qty) <= 0
	AND		bin_type NOT IN (1,5) -- v1.3 <> 5 -- v1.2 -- v1.4
	-- v1.1 End

	-- v1.5 Start
	DELETE	#cvo_putaways
	WHERE	(fill_qty - qty) <= 0
	AND		bin_type NOT IN (1,5)
	-- v1.5 End


	SET @qty_remaining = @qty
	-- v1.4 Start
	IF (@use_FT = 1)
		SET @bin_type = 1
	ELSE
		SET @bin_type = 2
	-- v1.4 End

	WHILE (@qty_remaining > 0)
	BEGIN

		-- Reserve Bins
		SET @row_id = NULL
		SELECT	@row_id = MIN(row_id)
		FROM	#cvo_putaways
		WHERE	bin_type = @bin_type

		IF (@row_id IS NOT NULL)
		BEGIN
			SELECT	@fill_qty = (((fill_qty + pick_qty) - put_qty) - qty)
			FROM	#cvo_putaways
			WHERE	row_id = @row_id

			IF (@fill_qty <= @qty_remaining)
			BEGIN 
				IF (@fill_qty <= 0)
				BEGIN
					IF (@bin_type <> 1) -- v1.4
					BEGIN
						SET @new_qty = @qty_remaining
						SET @qty_remaining = 0
					END
					ELSE
					BEGIN
						IF (@alloc_qty >= @qty_remaining)
						BEGIN
							SET @new_qty = @qty_remaining
							SET @qty_remaining = 0			
						END
						ELSE
						BEGIN
							SET @new_qty = @alloc_qty
							SET @qty_remaining = @qty_remaining - @alloc_qty			
						END
					END
				END
				ELSE
				BEGIN
					SET @new_qty = @fill_qty
					SET @qty_remaining = @qty_remaining - @fill_qty
				END
			END
			ELSE
			BEGIN
				SET @new_qty = @qty_remaining
				SET @qty_remaining = 0
			END

			UPDATE	#cvo_putaways
			SET		putaway_qty = @new_qty
			WHERE	row_id = @row_id

		END

		SET @bin_type = @bin_type + 1
		
		-- v1.4 IF (@bin_type = 3 AND @use_FT = 0)
		-- v1.4 	SET @bin_type = @bin_type + 1

		IF (@bin_type = 6)
			SET @qty_remaining = 0
	END

	-- No bins set up
	IF (@qty_remaining <> 0)
	BEGIN
		DROP TABLE #cvo_putaways
		DROP TABLE #cvo_committed
		RETURN 0
	END
	ELSE
	BEGIN
		-- Create putaways
		SELECT	@who = who 
		FROM	#temp_who

		DELETE	#cvo_putaways
		WHERE	putaway_qty <= 0

		DELETE	tdc_put_queue
		WHERE	tran_id = @tran_id
		
		SET @last_row_id = 0
		SET @icount = 0

		SELECT	TOP 1 @row_id = row_id,
				@new_bin_no = bin_no,
				@fill_qty = putaway_qty
		FROM	#cvo_putaways
		WHERE	row_id > @last_row_id
		ORDER BY row_id ASC

		WHILE (@@ROWCOUNT <> 0)
		BEGIN

			EXEC dbo.cvo_create_poptwy_transaction_sp @location, @po_no, @receipt_no, @part_no, @lot, @bin_no, @new_bin_no, @fill_qty, @who, @tran_id OUTPUT, 1

			SET @icount = @icount + 1

			SET @last_row_id = @row_id

			SELECT	TOP 1 @row_id = row_id,
					@new_bin_no = bin_no,
					@fill_qty = putaway_qty
			FROM	#cvo_putaways
			WHERE	row_id > @last_row_id
			ORDER BY row_id ASC
		END

		DROP TABLE #cvo_putaways
		DROP TABLE #cvo_committed
	
		IF (@icount = 1)
			RETURN 0
		ELSE
			RETURN -99999
	END
END
GO
GRANT EXECUTE ON  [dbo].[cvo_direct_putaway_sp] TO [public]
GO
