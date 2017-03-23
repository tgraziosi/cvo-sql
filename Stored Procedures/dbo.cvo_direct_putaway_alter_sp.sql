SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[cvo_direct_putaway_alter_sp]	@receipt_no int,
											@location varchar(10),
											@part_no varchar(30),
											@qty_diff decimal(20,8)
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
			@ft_qty2		decimal(20,8),
			@po_no			varchar(20),
			@po_line		int,
			@bin_no			varchar(12),
			@qty			decimal(20,8),
			@lot			varchar(25),
			@release_date	datetime,
			@tran_id		int,
			@sa_qty			decimal(20,8), -- v1.6
			@repl_qty		decimal(20,8), -- v1.6
			@non_alloc		decimal(20,8), -- v1.6
			@available		decimal(20,8), -- v1.6
			@repl_non_sa	decimal(20,8) -- v1.6


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
	-- Get config setting for fast track threshold
	SELECT @FT_threshold = value_str FROM tdc_config (NOLOCK) WHERE [function] = 'FT_CART_THRESHOLD'
	IF (@FT_threshold IS NULL)
		SET @FT_threshold = 10

	-- Get Fast Track Bin List (where stock exists)
	IF NOT EXISTS (SELECT 1 FROM inv_master (NOLOCK) WHERE part_no = @part_no AND type_code = 'CASE')
	BEGIN
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

-- v1.1 Start
--		IF (@@ROWCOUNT = 0) -- No bulk bins contain the part so add an empty one
--		BEGIN
--			INSERT	#cvo_putaways (bin_type, bin_no, qty, fill_qty, pick_qty, put_qty, putaway_qty)	
--			SELECT	5, '', 0, 0, 0, 0, 0
--		END
-- v1.1 End

	END

	INSERT	#cvo_putaways (bin_type, bin_no, qty, fill_qty, pick_qty, put_qty, putaway_qty)	
	SELECT	6, '', 0, 0, 0, 0, 0

-- v1.4 Start
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
	ON		a.next_op = b.bin_no
	WHERE	a.location = @location
	AND		a.part_no = @part_no
	AND		a.trans = 'MGTB2B'	
	GROUP BY a.next_op

	UPDATE	a
	SET		pick_qty = a.pick_qty - b.qty
	FROM	#cvo_putaways a
	JOIN	#cvo_committed b
	ON		a.bin_no = b.bin_no
-- v1.4 End

	-- Puts
	TRUNCATE TABLE #cvo_committed

	INSERT	#cvo_committed
	SELECT	a.next_op, SUM(a.qty_to_process)
	FROM	tdc_put_queue a (NOLOCK)
	JOIN	#cvo_putaways b
	ON		a.next_op = b.bin_no -- v1.1
	WHERE	a.location = @location
	AND		a.part_no = @part_no
	AND		a.tran_receipt_no <> @receipt_no
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

	-- v1.6 Start
	CREATE TABLE #t1 (location varchar(10), part_no varchar(30), allocated_amt decimal(20,8), 
		quarantined_amt decimal(20,8), sce_version varchar(10), sa_qty decimal(20,8)) 

	INSERT #t1 (location, part_no, allocated_amt, quarantined_amt, sce_version)
	EXEC tdc_get_alloc_qntd_sp @location, @part_no

	SET @sa_qty = 0

	SELECT	@sa_qty = SUM(CASE WHEN a.deleted = 1 THEN (a.quantity * -1) ELSE a.quantity END)
	FROM	cvo_soft_alloc_det a (NOLOCK)
	JOIN	cvo_orders_all b (NOLOCK)
	ON		a.order_no = b.order_no
	AND		a.order_ext = b.ext
	WHERE	a.location = @location
	AND		a.part_no = @part_no
	AND		a.order_no <> 0
	AND		a.status IN (0,1)
	AND		CONVERT(varchar(10),b.allocation_date,120) <= CONVERT(varchar(10),GETDATE(),120)

	IF (@sa_qty IS NULL)
		SET @sa_qty = 0

	SELECT	@sa_qty = @sa_qty + ISNULL(SUM(a.quantity),0)
	FROM	cvo_soft_alloc_det a (NOLOCK)
	WHERE	a.location = @location
	AND		a.part_no = @part_no
	AND		a.order_no = 0
	AND		a.status IN (1)

	IF (@sa_qty IS NULL)
		SET @sa_qty = 0

	UPDATE	#t1
	SET		sa_qty = @sa_qty
	WHERE	location = @location
	AND		part_no = @part_no
		
	SET @repl_qty = 0
	SET @non_alloc = 0
	SET @available = 0
	SET @repl_non_sa = 0

	SELECT @repl_qty = SUM(qty) FROM cvo_replenishment_qty (NOLOCK) WHERE location = @location AND part_no = @part_no
		
	SELECT	@non_alloc = SUM(a.qty) - ISNULL(SUM(b.qty),0.0) 
	FROM	cvo_lot_bin_stock_exclusions a (NOLOCK)
	LEFT JOIN (SELECT SUM(qty) qty, location, part_no, bin_no FROM tdc_soft_alloc_tbl (NOLOCK) GROUP BY location, part_no, bin_no) b 
	ON		a.location = b.location
	AND		a.part_no = b.part_no
	AND		a.bin_no = b.bin_no
	WHERE	a.location = @location 
	AND		a.part_no = @part_no	

	IF (@repl_qty IS NULL)
		SET @repl_qty = 0

	IF (@non_alloc IS NULL)
		SET @non_alloc = 0

	SELECT	@alloc_qty = ABS(i.in_stock - (t.allocated_amt + t.sa_qty + t.quarantined_amt))
	FROM	cvo_inventory2 i
	JOIN	#t1 t
	ON		i.location = t.location
	AND		i.part_no = t.part_no

--	SELECT	@alloc_qty = SUM(a.ordered - a.shipped) - SUM(ISNULL(b.qty,0))
--	FROM	ord_list a (NOLOCK)
--	LEFT JOIN tdc_soft_alloc_tbl b (NOLOCK)
--	ON		a.order_no = b.order_no
--	AND		a.order_ext = b.order_ext
--	AND		a.line_no = b.line_no
--	WHERE	a.location = @location
--	AND		a.part_no = @part_no
--	AND		a.status < 'R'
--	AND		(b.order_type = 'S' OR b.order_type IS NULL)
	-- v1.6 End


	SET @ft_qty = 0
	SELECT	@ft_qty = SUM(qty)
	FROM	#cvo_putaways
	WHERE	bin_type = 1 

	SET @ft_qty2 = 0
	SELECT	@ft_qty2 = SUM(qty_to_process)
	FROM	tdc_put_queue (NOLOCK)
	WHERE	location = @location
	AND		part_no = @part_no
	AND		next_op LIKE 'ZZZ-%'

	IF (@ft_qty2 IS NULL)
		SET @ft_qty2 = 0

	SET @ft_qty = @ft_qty + @ft_qty2

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

	DELETE	#cvo_putaways
	WHERE	(fill_qty - put_qty) <= 0
	AND		bin_type NOT IN (1,6) -- v1.1
	AND		fill_qty <> 0 -- v1.3

	DELETE	#cvo_putaways
	WHERE	(fill_qty - qty) <= 0
	AND		bin_type NOT IN (1,6) -- v1.1
	AND		fill_qty <> 0 -- v1.3

	DELETE	#cvo_putaways
	WHERE	((fill_qty - qty) - put_qty) <= 0
	AND		bin_type NOT IN (1,6) -- v1.1
	AND		fill_qty <> 0 -- v1.3

	SELECT	@qty = SUM(qty_to_process)
	FROM	tdc_put_queue (NOLOCK)
	WHERE	tran_receipt_no = @receipt_no

	SET @qty_remaining = @qty + @qty_diff

	IF (@use_FT = 1)
		SET @bin_type = 1
	ELSE
		SET @bin_type = 2

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
				BEGIN -- v1.5 Start
					IF (@bin_type = 6) -- v1.4
					BEGIN
						SET @new_qty = @qty_remaining
						SET @qty_remaining = 0
					END
					ELSE
					BEGIN
						IF (@bin_type <> 6)
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
						ELSE
						BEGIN
							SET @new_qty = @fill_qty
							SET @qty_remaining = @qty_remaining - @fill_qty
						END
					END -- v1.5 End
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
		
		IF (@bin_type = 7)
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
			SET @tran_id = 0

			SELECT	@tran_id = tran_id 
			FROM	tdc_put_queue (NOLOCK) 
			WHERE	tran_receipt_no = @receipt_no 
			AND		part_no = @part_no 
			AND		next_op = @new_bin_no
			AND		warehouse_no = 'DIR'
			
			IF (@tran_id <> 0)
			BEGIN
				UPDATE	tdc_put_queue
				SET		qty_to_process = @fill_qty
				WHERE	tran_id = @tran_id

				DELETE	tdc_put_queue
				WHERE	tran_id = @tran_id
				AND		qty_to_process <= 0

			END
			ELSE
			BEGIN
				IF (@fill_qty > 0)
					EXEC dbo.cvo_create_poptwy_transaction_sp @location, @po_no, @receipt_no, @part_no, @lot, @bin_no, @new_bin_no, @fill_qty, @who, @tran_id OUTPUT, 1
			END

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
	
		RETURN -99999 -- v1.2 Start
		/*
		IF (@icount = 1)
			RETURN 0
		ELSE
			RETURN -99999
		*/ -- v1.2 End
	END
END
GO
GRANT EXECUTE ON  [dbo].[cvo_direct_putaway_alter_sp] TO [public]
GO
