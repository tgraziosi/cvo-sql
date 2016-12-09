SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[cvo_replenish_retrieve_sp]	@replen_group		varchar(20),
											@location			varchar(10),
											@perc_to_min		int,
											@instock_option		int,
											@instock_qty		decimal(20,8),
											@available_option	int,
											@available_qty		decimal(20,8),
											@part_type			varchar(20),
											@pom_from			datetime,
											@pom_to				datetime,
											@results_returned	int,
											@filltype			char(1),
											@review				int
AS
BEGIN

	-- Directives
	SET NOCOUNT ON
	SET QUOTED_IDENTIFIER OFF

	-- Declarations
	DECLARE	@from_bin_group			varchar(10),
			@to_bin_group			varchar(10),
			@curr_replen_group		varchar(20),
			@curr_replen_id			int,
			@last_replen_group		varchar(20),
			@curr_perc_to_min		int,
			@curr_instock_option	int,
			@curr_instock_qty		decimal(20,8),
			@curr_available_option	int,
			@curr_available_qty		decimal(20,8),
			@curr_part_type			varchar(20),
			@last_part_no			varchar(30),
			@part_no				varchar(30),
			@qty					decimal(20,8),
			@debug					int -- v1.4

	SET @debug = 1 -- v1.4
	

	IF (@review = 1)
		DELETE	#temp_repl_display

	-- v1.2 Start
	CREATE TABLE #bins_to_include (
		location		varchar(10),
		group_code		varchar(10),
		bin_no			varchar(20),
		part_no			varchar(30),
		in_stock		decimal(20,8),
		allocated		decimal(20,8),
		max_level		decimal(20,8))

	-- v1.6 Start
	INSERT	#bins_to_include (location, group_code, bin_no, part_no, in_stock, allocated, max_level)
	SELECT	a.location, a.group_code, a.bin_no, b.part_no, SUM(c.qty), d.qty, b.replenish_max_lvl
	FROM	tdc_bin_master a (NOLOCK)
	JOIN	tdc_bin_replenishment b (NOLOCK)
	ON		a.location = b.location 
	AND		a.bin_no = b.bin_no 
	JOIN	lot_bin_stock c (NOLOCK) 
	ON		b.location = c.location 
	AND		b.part_no = c.part_no 
	AND		b.bin_no = c.bin_no
	JOIN	(SELECT SUM(qty) qty, location, part_no, bin_no FROM tdc_soft_alloc_tbl (NOLOCK) GROUP BY location, part_no, bin_no) d
	ON		b.location = d.location 
	AND		b.part_no = d.part_no 
	AND		b.bin_no = d.bin_no
	WHERE	a.usage_type_code IN ('REPLENISH', 'OPEN')
	AND		LEFT(a.bin_no,4) <> 'ZZZ-' -- v1.8
	AND		a.location = @location
	GROUP BY a.location, a.group_code, a.bin_no, b.part_no, d.qty, b.replenish_max_lvl
	-- v1.6 End

	-- v1.5 Start
	DELETE	#bins_to_include
	WHERE	in_stock >= max_level
	
	DELETE	#bins_to_include
	WHERE	((in_stock * 50.00) / 100.00) > allocated
	-- v1.5 End
	-- v1.2 End


	-- Retrieve info from the replenishment group config
	SET @last_replen_group = ''

	SELECT	TOP 1 @curr_replen_group = replen_group,
			@curr_replen_id = replen_id,
			@curr_perc_to_min = perc_to_min,
			@from_bin_group = from_bin_group,
			@to_bin_group = to_bin_group,
			@curr_instock_option = in_stock_option,
			@curr_instock_qty = in_stock_qty,
			@curr_available_option = available_option,
			@curr_available_qty = available_qty,
			@curr_part_type = part_type
	FROM	dbo.replenishment_groups (NOLOCK)
	WHERE	Inactive = 0
	AND		replen_group > @last_replen_group
	AND		(replen_group = @replen_group OR @replen_group = '-- ALL --')
	AND		location = @location
	ORDER BY replen_group

	WHILE @@ROWCOUNT <> 0
	BEGIN

		IF (@review = 1)
		BEGIN

			INSERT INTO #temp_repl_display (replen_id, replen_group, selected, location, group_code, bin_no, part_no, qty, replenish_min_lvl, replenish_max_lvl, replenish_qty, isforced) -- v1.2
			-- Where no stock exists in bin to be replenished
			SELECT	@curr_replen_id, @curr_replen_group, 0, 
					a.location, 
					a.group_code, 
					a.bin_no, 
					b.part_no, 
					0, 
					CONVERT(VARCHAR(20), b.replenish_min_lvl) ,  
					CONVERT(VARCHAR(20), b.replenish_max_lvl), 
					CONVERT(VARCHAR(20), b.replenish_qty),
					0 -- v1.2  
			FROM	tdc_bin_master a (NOLOCK)
			JOIN	tdc_bin_replenishment b (NOLOCK)
			ON		a.location = b.location 
			AND		a.bin_no = b.bin_no
			LEFT JOIN #temp_repl_display c
			ON		b.bin_no = c.bin_no
			AND		b.part_no = c.part_no	
			WHERE	a.usage_type_code IN ('REPLENISH', 'OPEN')
			AND		LEFT(a.bin_no,4) <> 'ZZZ-' -- v1.8
			AND NOT EXISTS (SELECT	* FROM lot_bin_stock c (nolock)
							WHERE	b.location = c.location 
							AND		b.bin_no = c.bin_no and b.part_no = c.part_no) 
-- v1.1		AND		ISNULL(a.bm_udef_e,'') <> '1' 
			AND		a.location = @location
			AND		a.group_code = @to_bin_group		
			AND		c.bin_no IS NULL
			AND		c.part_no IS NULL
			UNION
			-- Where stock exists in bin to be replenished
			SELECT	@curr_replen_id, @curr_replen_group, 0, 
					a.location, 
					a.group_code, 
					a.bin_no, 
					b.part_no, 
					SUM(c.qty), 
					CONVERT(VARCHAR(20), b.replenish_min_lvl) , 
					CONVERT(VARCHAR(20), b.replenish_max_lvl), 
					CONVERT(VARCHAR(20), b.replenish_qty),
					0 -- v1.2   
			FROM	tdc_bin_master a (NOLOCK)
			JOIN	tdc_bin_replenishment b (NOLOCK)
			ON		a.location = b.location 
			AND		a.bin_no = b.bin_no 
			JOIN	lot_bin_stock c (NOLOCK) 
			ON		b.location = c.location 
			AND		b.part_no = c.part_no 
			AND		b.bin_no = c.bin_no 
			LEFT JOIN #temp_repl_display d
			ON		b.bin_no = d.bin_no
			AND		b.part_no = d.part_no	
			WHERE	a.usage_type_code IN ('REPLENISH', 'OPEN')
			AND		LEFT(a.bin_no,4) <> 'ZZZ-' -- v1.8
-- v1.1		AND		ISNULL(a.bm_udef_e,'') <> '1' 
			AND		a.location = @location
			AND		a.group_code = @to_bin_group
			AND		d.bin_no IS NULL
			AND		d.part_no IS NULL
			GROUP BY a.location, a.group_code, a.bin_no, b.part_no, b.replenish_min_lvl, b.replenish_max_lvl, b.replenish_qty  
-- v1.2 Start
			INSERT INTO #temp_repl_display (replen_id, replen_group, selected, location, group_code, bin_no, part_no, qty, replenish_min_lvl, replenish_max_lvl, replenish_qty, isforced) -- v1.2
			SELECT	@curr_replen_id, @curr_replen_group, 0, 
					a.location, 
					a.group_code, 
					a.bin_no, 
					b.part_no, 
					SUM(c.qty), 
					CONVERT(VARCHAR(20), b.replenish_min_lvl) , 
					CONVERT(VARCHAR(20), b.replenish_max_lvl), 
					CONVERT(VARCHAR(20), b.replenish_qty),
					1 -- v1.2   
			FROM	tdc_bin_master a (NOLOCK)
			JOIN	tdc_bin_replenishment b (NOLOCK)
			ON		a.location = b.location 
			AND		a.bin_no = b.bin_no 
			JOIN	lot_bin_stock c (NOLOCK) 
			ON		b.location = c.location 
			AND		b.part_no = c.part_no 
			AND		b.bin_no = c.bin_no
			JOIN	#bins_to_include e
			ON		b.location = e.location 
			AND		b.part_no = e.part_no 
			AND		b.bin_no = e.bin_no 
			LEFT JOIN #temp_repl_display d
			ON		b.bin_no = d.bin_no
			AND		b.part_no = d.part_no	
			WHERE	a.usage_type_code IN ('REPLENISH', 'OPEN')
			AND		LEFT(a.bin_no,4) <> 'ZZZ-' -- v1.8
			AND		a.location = @location
			AND		a.group_code = @to_bin_group
			AND		d.bin_no IS NULL
			AND		d.part_no IS NULL
			GROUP BY a.location, a.group_code, a.bin_no, b.part_no, b.replenish_min_lvl, b.replenish_max_lvl, b.replenish_qty  

			UPDATE	#temp_repl_display
			SET		isforced = 1
			FROM	#temp_repl_display a
			JOIN	#bins_to_include b
			ON		a.location = b.location
			AND		a.bin_no = b.bin_no
			AND		a.part_no = b.part_no

-- v1.2 End

			-- Get the in queue figures for picks
			UPDATE	#temp_repl_display 
			SET		inqueue = inqueue + qty_to_process 
			FROM	#temp_repl_display a
			JOIN	tdc_pick_queue b (NOLOCK)
			ON		a.location = b.location 
			AND		a.part_no = b.part_no
			WHERE	(a.bin_no = b.bin_no and a.bin_no != b.next_op)
			AND		a.location = @location
			AND		b.trans <> 'MGTB2B'
			AND		a.replen_group = @curr_replen_group

			UPDATE	#temp_repl_display 
			SET		inqueue = inqueue + qty_to_process 
			FROM	#temp_repl_display a
			JOIN	tdc_pick_queue b (NOLOCK)
			ON		a.location = b.location 
			AND		a.part_no = b.part_no 
			WHERE	(a.bin_no = b.next_op and a.bin_no != b.bin_no)
			AND		a.location = @location
			AND		b.trans <> 'MGTB2B'
			AND		a.replen_group = @curr_replen_group

			UPDATE	#temp_repl_display 
			SET		inqueue = inqueue + qty_to_process 
			FROM	#temp_repl_display a
			JOIN	tdc_pick_queue b (NOLOCK)
			ON		a.location = b.location 
			AND		a.part_no = b.part_no 
			WHERE	(a.bin_no = b.bin_no and a.bin_no = b.next_op)
			AND		a.location = @location
			AND		b.trans <> 'MGTB2B'
			AND		a.replen_group = @curr_replen_group

			-- Get the in queue figures for MGTB2B
			UPDATE	#temp_repl_display 
			SET		inqueue_b2b = inqueue_b2b + qty_to_process 
			FROM	#temp_repl_display a
			JOIN	tdc_pick_queue b (NOLOCK)
			ON		a.location = b.location 
			AND		a.part_no = b.part_no
			WHERE	(a.bin_no = b.bin_no and a.bin_no != b.next_op)
			AND		a.location = @location
			AND		b.trans = 'MGTB2B'
			AND		a.replen_group = @curr_replen_group

			UPDATE	#temp_repl_display 
			SET		inqueue_b2b = inqueue_b2b + qty_to_process 
			FROM	#temp_repl_display a
			JOIN	tdc_pick_queue b (NOLOCK)
			ON		a.location = b.location 
			AND		a.part_no = b.part_no 
			WHERE	(a.bin_no = b.next_op and a.bin_no != b.bin_no)
			AND		a.location = @location
			AND		b.trans = 'MGTB2B'
			AND		a.replen_group = @curr_replen_group

			UPDATE	#temp_repl_display 
			SET		inqueue_b2b = inqueue_b2b + qty_to_process 
			FROM	#temp_repl_display a
			JOIN	tdc_pick_queue b (NOLOCK)
			ON		a.location = b.location 
			AND		a.part_no = b.part_no 
			WHERE	(a.bin_no = b.bin_no and a.bin_no = b.next_op)
			AND		a.location = @location
			AND		b.trans = 'MGTB2B'
			AND		a.replen_group = @curr_replen_group

			-- Set the available qty
			SET	@last_part_no = ''

			SELECT	TOP 1 @part_no = part_no
			FROM	#temp_repl_display
			WHERE	part_no > @last_part_no
			AND		replen_group = @curr_replen_group
			ORDER BY part_no

			WHILE @@ROWCOUNT <> 0
			BEGIN

				EXEC @qty = CVO_CheckAvailabilityInBinGroup_sp @part_no, @location, @from_bin_group

				UPDATE	#temp_repl_display
				SET		available_qty = @qty - (inqueue + inqueue_b2b)
				WHERE	replen_group = @curr_replen_group
				AND		location = @location
				AND		part_no = @part_no

				SET	@last_part_no = @part_no

				SELECT	TOP 1 @part_no = part_no
				FROM	#temp_repl_display
				WHERE	part_no > @last_part_no
				AND		replen_group = @curr_replen_group
				ORDER BY part_no
			END

--			UPDATE	a
--			SET		available_qty = b.in_stock
--			FROM	#temp_repl_display a
--			JOIN	inventory b (NOLOCK)
--			ON		a.location = b.location
--			AND		a.part_no = b.part_no
--			WHERE	a.replen_group = @curr_replen_group
--
--			-- Remove any allocated
--			UPDATE	#temp_repl_display
--			SET		available_qty = available_qty -  (inqueue + inqueue_b2b)
--			WHERE	replen_group = @curr_replen_group

			-- if part_type passed in then override template
			IF (@part_type > '')
				SET @curr_part_type = @part_type
			ELSE
				SET @curr_part_type = ''

			-- v1.4 Start
			IF (@debug = 1)
			BEGIN
				INSERT	cvo_replenishment_audit (entry_date, location, replen_group, part_no, from_bin_group, from_bin_avail, to_bin, to_bin_qty, to_bin_avail, min_level, max_level, result)
				SELECT	GETDATE(), @location, @curr_replen_group, part_no, group_code, available_qty, bin_no, qty, (qty - (inqueue_b2b + inqueue)), replenish_min_lvl, replenish_max_lvl, 
						CASE WHEN isforced = 1 THEN 'Forced Replenishment: Over 50% of bin allocated' ELSE '' END
				FROM	#temp_repl_display
				WHERE	replen_group = @curr_replen_group 
			END
			-- v1.4 End

			-- Filter based on parameters
			IF (ISNULL(@curr_part_type,'') > '')
			BEGIN
				IF @curr_part_type = 'FRAME/SUN'
				BEGIN

					-- v1.4 Start
					IF (@debug = 1)
					BEGIN
						UPDATE	a
						SET		result = 'Removed From Replenishment: Type Not FRAME or SUN'
						FROM	cvo_replenishment_audit a
						JOIN	inv_master b (NOLOCK)
						ON		a.part_no = b.part_no
						JOIN	#temp_repl_display c (NOLOCK)
						ON		a.location = c.location
						AND		a.part_no = c.part_no
						AND		a.to_bin = c.bin_no
						WHERE	b.type_code NOT IN ('FRAME','SUN')
						AND		a.replen_group = @curr_replen_group
						AND		c.isforced = 0 -- v1.2			
					END
					-- v1.4 End		

					DELETE	a
					FROM	#temp_repl_display a
					JOIN	inv_master b (NOLOCK)
					ON		a.part_no = b.part_no
					WHERE	b.type_code NOT IN ('FRAME','SUN')
					AND		a.replen_group = @curr_replen_group
					AND		a.isforced = 0 -- v1.2			

				END
				ELSE
				BEGIN
					-- v1.4 Start
					IF (@debug = 1)
					BEGIN
						UPDATE	a
						SET		result = 'Removed From Replenishment: Type Not ' + @curr_part_type
						FROM	cvo_replenishment_audit a
						JOIN	inv_master b (NOLOCK)
						ON		a.part_no = b.part_no
						JOIN	#temp_repl_display c (NOLOCK)
						ON		a.location = c.location
						AND		a.part_no = c.part_no
						AND		a.to_bin = c.bin_no
						WHERE	b.type_code <> @curr_part_type
						AND		a.replen_group = @curr_replen_group
						-- v1.9 AND		c.isforced = 0 -- v1.2			
					END
					-- v1.4 End

					DELETE	a
					FROM	#temp_repl_display a
					JOIN	inv_master b (NOLOCK)
					ON		a.part_no = b.part_no
					WHERE	b.type_code <> @curr_part_type
					AND		a.replen_group = @curr_replen_group
					-- v1.9 AND		a.isforced = 0 -- v1.2
				END
			END

			-- Filter on % to min
			IF (@perc_to_min > -1)
			BEGIN
-- v1.3 Start
				-- v1.4 Start
				IF (@debug = 1)
				BEGIN
					UPDATE	a
					SET		result = 'Removed From Replenishment: Qty > % To Min (' + CAST(@perc_to_min AS varchar(20)) + ')',
							to_bin_qty = b.qty -- v1.7
					FROM	cvo_replenishment_audit a
					JOIN	#temp_repl_display b (NOLOCK)
					ON		a.location = b.location
					AND		a.part_no = b.part_no
					AND		a.to_bin = b.bin_no
					WHERE	CAST(b.replenish_max_lvl as decimal (24,8)) > cast(b.replenish_min_lvl as decimal (24,8))      
					AND		b.qty > (CAST(b.replenish_min_lvl as decimal (24,8)) + (CAST(b.replenish_min_lvl as decimal (24,8)) * CAST(@perc_to_min AS decimal(24,8)) / 100.00))
					AND		b.replen_group = @curr_replen_group
					AND		b.isforced = 0 -- v1.2		
				END
				-- v1.4 End

				DELETE	#temp_repl_display
				WHERE	CAST(replenish_max_lvl as decimal (24,8)) > cast(replenish_min_lvl as decimal (24,8))      
				AND		qty > (CAST(replenish_min_lvl as decimal (24,8)) + (CAST(replenish_min_lvl as decimal (24,8)) * CAST(@perc_to_min AS decimal(24,8)) / 100.00))
				AND		replen_group = @curr_replen_group
				AND		isforced = 0 -- v1.2

--				DELETE	#temp_repl_display
--				WHERE	CAST(replenish_max_lvl as decimal (24,8)) > cast(replenish_min_lvl as decimal (24,8))      
--				AND		ABS (100 * (qty - CAST(replenish_min_lvl as decimal (24,8))) /
--										(CAST(replenish_max_lvl as decimal (24,8)) - 
--										CAST(replenish_min_lvl as decimal (24,8)))) > CAST(@perc_to_min AS decimal(24,8))
--				AND		replen_group = @curr_replen_group
--				AND		isforced = 0 -- v1.2
-- v1.3 End
			END

			-- POM Dates

			-- v1.4 Start
			IF (@debug = 1)
			BEGIN
				UPDATE	a
				SET		result = 'Removed From Replenishment: Outside of POM Dates'
				FROM	cvo_replenishment_audit a
				JOIN	inv_master_add b (NOLOCK)
				ON		a.part_no = b.part_no
				JOIN	#temp_repl_display c (NOLOCK)
				ON		a.location = c.location
				AND		a.part_no = c.part_no
				AND		a.to_bin = c.bin_no
				WHERE	b.field_28 < @pom_from OR b.field_28 > @pom_to
				AND		b.field_28 IS NOT NULL
				AND		a.replen_group = @curr_replen_group
				AND		c.isforced = 0 -- v1.2		
			END
			-- v1.4 End

			DELETE	a
			FROM	#temp_repl_display a
			JOIN	inv_master_add b (NOLOCK)
			ON		a.part_no = b.part_no
			WHERE	b.field_28 < @pom_from OR b.field_28 > @pom_to
			AND		b.field_28 IS NOT NULL
			AND		a.replen_group = @curr_replen_group
			AND		a.isforced = 0 -- v1.2

			-- In Stock Qty
			IF (@instock_qty > -1)
			BEGIN
				IF (@instock_option = 0) -- less than
				BEGIN
					-- v1.4 Start
					IF (@debug = 1)
					BEGIN
						UPDATE	a
						SET		result = 'Removed From Replenishment: Qty Less Than In Stock (' + CAST(@instock_qty AS varchar(20)) + ')'
						FROM	cvo_replenishment_audit a
						JOIN	#temp_repl_display b (NOLOCK)
						ON		a.location = b.location
						AND		a.part_no = b.part_no
						AND		a.to_bin = b.bin_no
						WHERE	b.qty >= @instock_qty
						AND		b.replen_group = @curr_replen_group
						AND		b.isforced = 0 -- v1.2	
					END
					-- v1.4 End

					DELETE	#temp_repl_display 
					WHERE	qty >= @instock_qty
					AND		replen_group = @curr_replen_group
					AND		isforced = 0 -- v1.2
				END
				IF (@instock_option = 1) -- equals
				BEGIN

					-- v1.4 Start
					IF (@debug = 1)
					BEGIN
						UPDATE	a
						SET		result = 'Removed From Replenishment: Qty <> In Stock (' + CAST(@instock_qty AS varchar(20)) + ')'
						FROM	cvo_replenishment_audit a
						JOIN	#temp_repl_display b (NOLOCK)
						ON		a.location = b.location
						AND		a.part_no = b.part_no
						AND		a.to_bin = b.bin_no
						WHERE	b.qty <> @instock_qty
						AND		b.replen_group = @curr_replen_group
						AND		b.isforced = 0 -- v1.2	
					END
					-- v1.4 

					DELETE	#temp_repl_display 
					WHERE	qty <> @instock_qty
					AND		replen_group = @curr_replen_group
					AND		isforced = 0 -- v1.2
				END
				IF (@instock_option = 2) -- greater than
				BEGIN
					-- v1.4 Start
					IF (@debug = 1)
					BEGIN
						UPDATE	a
						SET		result = 'Removed From Replenishment: Qty Greater Than In Stock (' + CAST(@instock_qty AS varchar(20)) + ')'
						FROM	cvo_replenishment_audit a
						JOIN	#temp_repl_display b (NOLOCK)
						ON		a.location = b.location
						AND		a.part_no = b.part_no
						AND		a.to_bin = b.bin_no
						WHERE	b.qty <= @instock_qty
						AND		b.replen_group = @curr_replen_group
						AND		b.isforced = 0 -- v1.2	
					END
					-- v1.4 End

					DELETE	#temp_repl_display 
					WHERE	qty <= @instock_qty
					AND		replen_group = @curr_replen_group
					AND		isforced = 0 -- v1.2
				END
			END
			
			-- Available Qty
			IF (@available_qty > -1)
			BEGIN
				IF (@available_option = 0) -- less than
				BEGIN

					-- v1.4 Start
					IF (@debug = 1)
					BEGIN
						UPDATE	a
						SET		result = 'Removed From Replenishment: Qty Less Than Available (' + CAST(@available_qty AS varchar(20)) + ')'
						FROM	cvo_replenishment_audit a
						JOIN	#temp_repl_display b (NOLOCK)
						ON		a.location = b.location
						AND		a.part_no = b.part_no
						AND		a.to_bin = b.bin_no
						WHERE	b.available_qty >= @available_qty
						AND		b.replen_group = @curr_replen_group
						AND		b.isforced = 0 -- v1.2	
					END
					-- v1.4 End

					DELETE	#temp_repl_display 
					WHERE	available_qty >= @available_qty
					AND		replen_group = @curr_replen_group
					AND		isforced = 0 -- v1.2
				END
				IF (@available_option = 1) -- equals
				BEGIN
					-- v1.4 Start
					IF (@debug = 1)
					BEGIN
						UPDATE	a
						SET		result = 'Removed From Replenishment: Qty <> Available (' + CAST(@available_qty AS varchar(20)) + ')'
						FROM	cvo_replenishment_audit a
						JOIN	#temp_repl_display b (NOLOCK)
						ON		a.location = b.location
						AND		a.part_no = b.part_no
						AND		a.to_bin = b.bin_no
						WHERE	b.available_qty <> @available_qty
						AND		b.replen_group = @curr_replen_group
						AND		b.isforced = 0 -- v1.2	
					END
					-- v1.4 End

					DELETE	#temp_repl_display 
					WHERE	available_qty <> @available_qty
					AND		replen_group = @curr_replen_group
					AND		isforced = 0 -- v1.2
				END
				IF (@available_option = 2) -- greater than
				BEGIN

					-- v1.4 Start
					IF (@debug = 1)
					BEGIN
						UPDATE	a
						SET		result = 'Removed From Replenishment: Qty Greater Than Available (' + CAST(@available_qty AS varchar(20)) + ')'
						FROM	cvo_replenishment_audit a
						JOIN	#temp_repl_display b (NOLOCK)
						ON		a.location = b.location
						AND		a.part_no = b.part_no
						AND		a.to_bin = b.bin_no
						WHERE	b.available_qty <= @available_qty
						AND		b.replen_group = @curr_replen_group
						AND		b.isforced = 0 -- v1.2	
					END
					-- v1.4 End

					DELETE	#temp_repl_display 
					WHERE	available_qty <= @available_qty
					AND		replen_group = @curr_replen_group
					AND		isforced = 0 -- v1.2
				END
			END
								
		END

		SET @last_replen_group = @curr_replen_group

		SELECT	TOP 1 @curr_replen_group = replen_group,
				@curr_replen_id = replen_id,
				@curr_perc_to_min = perc_to_min,
				@from_bin_group = from_bin_group,
				@to_bin_group = to_bin_group,
				@curr_instock_option = in_stock_option,
				@curr_instock_qty = in_stock_qty,
				@curr_available_option = available_option,
				@curr_available_qty = available_qty,
				@curr_part_type = part_type
		FROM	dbo.replenishment_groups (NOLOCK)
		WHERE	Inactive = 0
		AND		replen_group > @last_replen_group
		AND		(replen_group = @replen_group OR @replen_group = '-- ALL --')
		AND		location = @location
		ORDER BY replen_group

	END

	-- Result returned
	IF (@results_returned > 0)
	BEGIN
		IF ((SELECT COUNT(1) FROM #temp_repl_display) > @results_returned)
		BEGIN
			SET ROWCOUNT @results_returned
			UPDATE	#temp_repl_display
			SET		selected = -99
			SET ROWCOUNT 0

			-- v1.4 Start
			IF (@debug = 1)
			BEGIN
				UPDATE	a
				SET		result = 'Removed From Replenishment: Results Greater Than Requested (' + CAST(@results_returned AS varchar(20)) + ')'
				FROM	cvo_replenishment_audit a
				JOIN	#temp_repl_display b (NOLOCK)
				ON		a.location = b.location
				AND		a.part_no = b.part_no
				AND		a.to_bin = b.bin_no
				WHERE	selected <> -99
			END
			-- v1.4 End

			DELETE	#temp_repl_display
			WHERE	selected <> -99

			UPDATE	#temp_repl_display
			SET		selected = 0
		END
	END	

	-- v1.4 Start
	IF (@debug = 1)
	BEGIN
		UPDATE	cvo_replenishment_audit
		SET		result = 'Included in Replenishment List'
		WHERE	result = ''
	END
	-- v1.4
END
GO
GRANT EXECUTE ON  [dbo].[cvo_replenish_retrieve_sp] TO [public]
GO
