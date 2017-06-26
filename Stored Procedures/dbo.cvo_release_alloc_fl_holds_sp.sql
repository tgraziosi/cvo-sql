SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[cvo_release_alloc_fl_holds_sp]
AS
BEGIN

-- exec cvo_release_alloc_fl_holds_sp

	-- DIRECTIVES
	SET NOCOUNT ON

	-- DECLARATIONS
	DECLARE @row_id			int,
			@last_row_id	int,
			@soft_alloc_no	int,
			@order_no		int,
			@order_ext		int,
			@rc				int,
			@prior_hold		varchar(20), -- v1.2
			@msg			varchar(50), -- v1.2
			@fill_rate		decimal(20,8), -- v1.3
			@fill_rate_s	varchar(20), -- v1.3
			@ship_complete	smallint, -- v1.3
			@alloc_qty		decimal(20,8), -- v1.4
			@sa_qty			decimal(20,8), -- v1.4
			@new_soft_alloc_no int, -- v1.4
			@location		varchar(10), -- v1.4
			@release_only	int, -- v1.5
			@prec_avail		varchar(30), -- v1.7
			@perc			decimal(20,8), -- v1.8
			@prec_avail_str varchar(50) -- v1.9

	-- WORKING TABLES
	CREATE TABLE #fl_orders (
		row_id			int IDENTITY(1,1),
		soft_alloc_no	int,
		order_no		int,
		order_ext		int,
		process			int,
		prior_hold		varchar(20), -- v1.2
		ship_complete	int, -- v1.3
		release_only	int) -- v1.5

	CREATE TABLE #cf_check (
		result	varchar(10))

	CREATE TABLE #exclusions (
		order_no		int,
		order_ext		int,
		has_line_exc	int NULL,
		perc_available	decimal(20,8)) -- v1.3

	-- v1.4 Start
	CREATE TABLE #tmp_alloc (
			line_no		int,
			qty			decimal(20,8))
	-- v1.4 End


	-- v1.3 Start
	SELECT	@fill_rate_s = value_str 
	FROM	dbo.config (NOLOCK) 
	WHERE	flag = 'ST_ORDER_FILL_RATE'

	IF (@fill_rate_s IS NULL OR @fill_rate_s = '')
		SET @fill_rate = 0	
	ELSE
		SET @fill_rate = CAST(@fill_rate_s AS decimal(20,8))
	-- v1.3 End

	-- Insert working data
	INSERT	#fl_orders (soft_alloc_no, order_no, order_ext, process, prior_hold, ship_complete, release_only) -- v1.3 v1.5
	SELECT	c.soft_alloc_no,
			a.order_no, 
			a.ext,
			0,
			ISNULL(b.prior_hold,''), -- v1.2
			CASE WHEN a.back_ord_flag = 1 THEN 1 ELSE 0 END, -- v1.3
			0 -- v1.5
	FROM	orders_all a (NOLOCK)
	JOIN	cvo_orders_all b (NOLOCK)
	ON		a.order_no = b.order_no
	AND		a.ext = b.ext
	JOIN	cvo_soft_alloc_hdr c (NOLOCK)
	ON		a.order_no = c.order_no
	AND		a.ext = c.order_ext
	WHERE	a.type = 'I'
	AND		a.status = 'A'
	AND		a.hold_reason = 'FL'
-- v1.2	AND		ISNULL(b.prior_hold,'') = ''
	AND		a.order_no > 1420973
	ORDER BY a.order_no, a.ext	

	-- v1.5 Start - for already allocated orders just release the hold and don't do anything else
	INSERT	#fl_orders (soft_alloc_no, order_no, order_ext, process, prior_hold, ship_complete, release_only) -- v1.3 v1.5
	SELECT	DISTINCT 0,
			a.order_no, 
			a.ext,
			0,
			ISNULL(b.prior_hold,''), -- v1.2
			CASE WHEN a.back_ord_flag = 1 THEN 1 ELSE 0 END, -- v1.3
			1 -- v1.5
	FROM	orders_all a (NOLOCK)
	JOIN	cvo_orders_all b (NOLOCK)
	ON		a.order_no = b.order_no
	AND		a.ext = b.ext
	JOIN	tdc_soft_alloc_tbl c (NOLOCK)
	ON		a.order_no = c.order_no
	AND		a.ext = c.order_ext
	LEFT JOIN #fl_orders d
	ON		a.order_no = d.order_no
	AND		a.ext = d.order_ext
	WHERE	a.type = 'I'
	AND		a.status = 'A'
	AND		a.hold_reason = 'FL'
-- v1.2	AND		ISNULL(b.prior_hold,'') = ''
	AND		c.order_type = 'S'
	AND		a.order_no > 1420973
	AND		d.order_no IS NULL
	AND		d.order_ext IS NULL
	ORDER BY a.order_no, a.ext	
	-- v1.5 End

	-- tag 05/24/2017 - include other fl hold orders with no allocation records.

	INSERT	#fl_orders (soft_alloc_no, order_no, order_ext, process, prior_hold, ship_complete, release_only) -- v1.3 v1.5
	SELECT	DISTINCT 0,
			a.order_no, 
			a.ext,
			0,
			ISNULL(b.prior_hold,''), -- v1.2
			CASE WHEN a.back_ord_flag = 1 THEN 1 ELSE 0 END, -- v1.3
			0 -- v1.5
	FROM	orders_all a (NOLOCK)
	JOIN	cvo_orders_all b (NOLOCK)
	ON		a.order_no = b.order_no
	AND		a.ext = b.ext
	JOIN	cvo_soft_alloc_no_assign c (NOLOCK)
	ON		a.order_no = c.order_no
	AND		a.ext = c.order_ext
	LEFT JOIN #fl_orders d
	ON		a.order_no = d.order_no
	AND		a.ext = d.order_ext
	WHERE	a.type = 'I'
	AND		a.status = 'A'
	AND		a.hold_reason = 'FL'
-- v1.2	AND		ISNULL(b.prior_hold,'') = ''
	-- AND		c.order_type = 'S'
	AND		a.order_no > 1420973
	AND		d.order_no IS NULL
	AND		d.order_ext IS NULL
	ORDER BY a.order_no, a.ext	


	-- Step 1 - Check stock
	SET @last_row_id = 0

	SELECT	TOP 1 @row_id = row_id,
			@soft_alloc_no = soft_alloc_no,
			@order_no = order_no,
			@order_ext = order_ext,
			@ship_complete = ship_complete -- v1.3
	FROM	#fl_orders
	WHERE	row_id > @last_row_id
	AND		release_only = 0 -- v1.5
	ORDER BY row_id ASC
			
	WHILE (@@ROWCOUNT <> 0)
	BEGIN
	
		-- Custom Frame Check
		-- v2.0 TRUNCATE TABLE #exclusions

		EXEC cvo_soft_alloc_CF_BO_check_sp @soft_alloc_no, @order_no, @order_ext

		IF EXISTS (SELECT 1 FROM #exclusions WHERE order_no = @order_no AND order_ext = @order_ext)
		BEGIN
			UPDATE	#fl_orders
			SET		process = -1
			WHERE	row_id = @row_id

			SET @last_row_id = @row_id

			SELECT	TOP 1 @row_id = row_id,
					@soft_alloc_no = soft_alloc_no,
					@order_no = order_no,
					@order_ext = order_ext,
					@ship_complete = ship_complete -- v1.3
			FROM	#fl_orders
			WHERE	row_id > @last_row_id
			AND		release_only = 0 -- v1.5
			ORDER BY row_id ASC

			CONTINUE
		END
		
		-- v2.0 TRUNCATE TABLE #exclusions
		
		EXEC cvo_check_fl_stock_pre_allocation_sp @order_no, @order_ext
		
		IF EXISTS (SELECT 1 FROM #exclusions WHERE order_no = @order_no AND order_ext = @order_ext AND perc_available < @fill_rate) -- v1.3
		BEGIN
			UPDATE	#fl_orders
			SET		process = -1
			WHERE	row_id = @row_id

			SET @last_row_id = @row_id

			SELECT	TOP 1 @row_id = row_id,
					@soft_alloc_no = soft_alloc_no,
					@order_no = order_no,
					@order_ext = order_ext,
					@ship_complete = ship_complete -- v1.3
			FROM	#fl_orders
			WHERE	row_id > @last_row_id
			AND		release_only = 0 -- v1.5
			ORDER BY row_id ASC

			CONTINUE
		END
		ELSE -- v1.3 Start
		BEGIN
			-- v1.7 Start
			SET @prec_avail = '100' -- v1.9
			SELECT	@prec_avail = CAST(CAST(perc_available as int) as varchar(10))
			FROM	#exclusions
			WHERE	order_no = @order_no 
			AND		order_ext = @order_ext

			IF (@prec_avail IS NULL) 
				SET @prec_avail_str = '' -- v1.9
			ELSE
				SET @prec_avail_str = '; PERC AVAILABLE: ' + @prec_avail -- v1.9
			-- v1.7 End

			IF EXISTS (SELECT 1 FROM #exclusions WHERE order_no = @order_no AND order_ext = @order_ext AND perc_available >= @fill_rate
						AND perc_available < 100 AND @ship_complete = 1) 
			BEGIN
				UPDATE	#fl_orders
				SET		process = -1
				WHERE	row_id = @row_id

				INSERT INTO tdc_log WITH (ROWLOCK) ( tran_date , userid , trans_source , module , trans , tran_no , tran_ext , part_no , lot_ser , bin_no , location , quantity , data ) 
				SELECT	GETDATE() , 'FL HOLD RELEASE' , 'VB' , 'PLW' , 'ORDER UPDATE' , a.order_no , a.ext , '' , '' , '' , a.location , '' ,
						'STATUS:N/RELEASE FL USER HOLD; HOLD REASON:' + @prec_avail_str -- v1.7 v1.9
				FROM	orders_all a (NOLOCK)
				WHERE	a.order_no = @order_no
				AND		a.ext = @order_ext

				UPDATE	orders_all
				SET		hold_reason = 'SC'
				WHERE	order_no = @order_no
				AND		ext = @order_ext

-- v1.4 Start
--				UPDATE	cvo_orders_all
--				SET		prior_hold = NULL
--				WHERE	order_no = @order_no
--				AND		ext = @order_ext
-- v1.4 End

				SET @msg = 'STATUS:A/SHIP COMPLETE; HOLD REASON:SC'
		
				INSERT INTO tdc_log WITH (ROWLOCK) ( tran_date , userid , trans_source , module , trans , tran_no , tran_ext , part_no , lot_ser , bin_no , location , quantity , data ) 
				SELECT	GETDATE() , 'FL HOLD RELEASE' , 'VB' , 'PLW' , 'ORDER UPDATE' , a.order_no , a.ext , '' , '' , '' , a.location , '' , @msg
				FROM	orders_all a (NOLOCK)
				WHERE	a.order_no = @order_no
				AND		a.ext = @order_ext

				SET @last_row_id = @row_id

				SELECT	TOP 1 @row_id = row_id,
						@soft_alloc_no = soft_alloc_no,
						@order_no = order_no,
						@order_ext = order_ext,
						@ship_complete = ship_complete -- v1.3
				FROM	#fl_orders
				WHERE	row_id > @last_row_id
				AND		release_only = 0 -- v1.5
				ORDER BY row_id ASC

				CONTINUE
			END
		END
		-- v1.3 End

		SET @last_row_id = @row_id

		SELECT	TOP 1 @row_id = row_id,
				@soft_alloc_no = soft_alloc_no,
				@order_no = order_no,
				@order_ext = order_ext,
				@ship_complete = ship_complete -- v1.3
		FROM	#fl_orders
		WHERE	row_id > @last_row_id
		AND		release_only = 0 -- v1.5
		ORDER BY row_id ASC
	END

	DELETE	#fl_orders
	WHERE	process = -1

	-- Step 2 - Release Hold & Allocate
	SET @last_row_id = 0

	SELECT	TOP 1 @row_id = row_id,
			@order_no = order_no,
			@order_ext = order_ext,
			@prior_hold = prior_hold, -- v1.2
			@release_only = release_only -- v1.5
	FROM	#fl_orders
	WHERE	row_id > @last_row_id
	ORDER BY row_id ASC
			
	WHILE (@@ROWCOUNT <> 0)
	BEGIN

		-- v1.6 Start
		SET @prior_hold = ''

		SELECT	@prior_hold = hold_reason
		FROM	cvo_next_so_hold_vw (NOLOCK)
		WHERE	order_no = @order_no
		AND		order_ext = @order_ext
		-- v1.6 End	

		-- v1.2 Start
		IF (@prior_hold <> '')
		BEGIN
			-- v1.7 Start
			SET @prec_avail = '100' -- v1.9
			SELECT	@prec_avail = CAST(CAST(perc_available as int) as varchar(10)),
					@perc = perc_available -- v1.8
			FROM	#exclusions
			WHERE	order_no = @order_no 
			AND		order_ext = @order_ext
			IF (@prec_avail IS NULL) 
				SET @prec_avail_str = '' -- v1.9
			ELSE
				SET @prec_avail_str = '; PERC AVAILABLE: ' + @prec_avail -- v1.9
			-- v1.7 End

			INSERT INTO tdc_log WITH (ROWLOCK) ( tran_date , userid , trans_source , module , trans , tran_no , tran_ext , part_no , lot_ser , bin_no , location , quantity , data ) 
			SELECT	GETDATE() , 'FL HOLD RELEASE' , 'VB' , 'PLW' , 'ORDER UPDATE' , a.order_no , a.ext , '' , '' , '' , a.location , '' ,
					'STATUS:N/RELEASE FL USER HOLD; HOLD REASON:' + @prec_avail_str -- v1.7 v1.9
			FROM	orders_all a (NOLOCK)
			WHERE	a.order_no = @order_no
			AND		a.ext = @order_ext

			UPDATE	orders_all
			SET		hold_reason = @prior_hold
			WHERE	order_no = @order_no
			AND		ext = @order_ext

			-- v1.6 Start
			DELETE	cvo_so_holds
			WHERE	order_no = @order_no
			AND		order_ext = @order_ext
			AND		hold_reason = @prior_hold
		
			--UPDATE	cvo_orders_all
			--SET		prior_hold = NULL
			--WHERE	order_no = @order_no
			--AND		ext = @order_ext
			
			SET @msg = 'STATUS:A/PROMOTE USER HOLD; HOLD REASON:' + @prior_hold
			-- v1.6 End
	
			INSERT INTO tdc_log WITH (ROWLOCK) ( tran_date , userid , trans_source , module , trans , tran_no , tran_ext , part_no , lot_ser , bin_no , location , quantity , data ) 
			SELECT	GETDATE() , 'FL HOLD RELEASE' , 'VB' , 'PLW' , 'ORDER UPDATE' , a.order_no , a.ext , '' , '' , '' , a.location , '' , @msg
			FROM	orders_all a (NOLOCK)
			WHERE	a.order_no = @order_no
			AND		a.ext = @order_ext

			UPDATE	#fl_orders
			SET		process = -4
			WHERE	row_id = @row_id

			EXEC dbo.cvo_fl_holds_snapshot_sp @order_no, @order_ext, @perc


			SET @last_row_id = @row_id

			SELECT	TOP 1 @row_id = row_id,
					@order_no = order_no,
					@order_ext = order_ext,
					@prior_hold = prior_hold, -- v1.2
					@release_only = release_only -- v1.5
			FROM	#fl_orders
			WHERE	row_id > @last_row_id
			ORDER BY row_id ASC

			CONTINUE
		END
		-- v1.2 End

		UPDATE	orders_all
		SET		status = 'N',
				hold_reason = ''
		WHERE	order_no = @order_no
		AND		ext = @order_ext

		-- v1.7 Start
		SET @prec_avail = '100' -- v1.9
		SELECT	@prec_avail = CAST(CAST(perc_available as int) as varchar(10)),
				@perc = perc_available -- v1.8
		FROM	#exclusions
		WHERE	order_no = @order_no 
		AND		order_ext = @order_ext
		IF (@prec_avail IS NULL) 
			SET @prec_avail_str = '' -- v1.9
		ELSE
			SET @prec_avail_str = '; PERC AVAILABLE: ' + @prec_avail -- v1.9
		-- v1.7 End

		-- v1.1 Start
		INSERT INTO tdc_log WITH (ROWLOCK) ( tran_date , userid , trans_source , module , trans , tran_no , tran_ext , part_no , lot_ser , bin_no , location , quantity , data ) 
		SELECT	GETDATE() , 'FL HOLD RELEASE' , 'VB' , 'PLW' , 'ORDER UPDATE' , a.order_no , a.ext , '' , '' , '' , a.location , '' ,
				'STATUS:N/RELEASE FL USER HOLD; HOLD REASON:' + @prec_avail_str -- v1.7 v1.9
		FROM	orders_all a (NOLOCK)
		WHERE	a.order_no = @order_no
		AND		a.ext = @order_ext
		-- v1.1 End

		EXEC dbo.cvo_fl_holds_snapshot_sp @order_no, @order_ext, @perc

		IF EXISTS(SELECT 1 FROM dbo.cvo_soft_alloc_hdr a (NOLOCK) JOIN cvo_orders_all b (NOLOCK) ON a.order_no = b.order_no AND a.order_ext = b.ext
						WHERE a.order_no = @order_no AND a.order_ext = @order_ext AND b.allocation_date > getdate() AND a.status = -3)
		BEGIN

			UPDATE	#fl_orders
			SET		process = -2
			WHERE	row_id = @row_id

			SET @last_row_id = @row_id

			SELECT	TOP 1 @row_id = row_id,
					@order_no = order_no,
					@order_ext = order_ext,
					@prior_hold = prior_hold, -- v1.2
					@release_only = release_only -- v1.5
			FROM	#fl_orders
			WHERE	row_id > @last_row_id
			ORDER BY row_id ASC

			CONTINUE
		END

		IF EXISTS (SELECT 1 FROM dbo.orders_all a (NOLOCK) INNER JOIN dbo.cvo_soft_alloc_hdr b (NOLOCK) ON a.order_no = b.order_no
					AND a.ext = b.order_ext WHERE a.order_no = @order_no AND a.ext = @order_ext AND b.status = 0 
					AND CONVERT(varchar(10),ISNULL(a.sch_ship_date,GETDATE()),121) > CONVERT(varchar(10),GETDATE(),121)) 
		BEGIN

			UPDATE	#fl_orders
			SET		process = -3
			WHERE	row_id = @row_id

			SET @last_row_id = @row_id

			SELECT	TOP 1 @row_id = row_id,
					@order_no = order_no,
					@order_ext = order_ext,
					@prior_hold = prior_hold, -- v1.2
					@release_only = release_only -- v1.5
			FROM	#fl_orders
			WHERE	row_id > @last_row_id
			ORDER BY row_id ASC

			CONTINUE
		END
		
		IF (@release_only = 0) -- v1.5 
			EXEC @rc = tdc_order_after_save @order_no, @order_ext   

		-- v1.4 Start
		TRUNCATE TABLE #tmp_alloc
	
		SELECT	@alloc_qty = SUM(qty) 
		FROM	tdc_soft_alloc_tbl (NOLOCK)
		WHERE	order_no = @order_no
		AND		order_ext= @order_ext

		IF (@alloc_qty IS NULL)
			SET @alloc_qty = 0

		INSERT	#tmp_alloc
		SELECT	line_no, SUM(qty)
		FROM	tdc_soft_alloc_tbl (NOLOCK)
		WHERE	order_no = @order_no
		AND		order_ext= @order_ext
		GROUP BY line_no

		SELECT	@sa_qty = SUM(ordered),
				@location = location
		FROM	ord_list (NOLOCK)
		WHERE	order_no = @order_no
		AND		order_ext= @order_ext
		GROUP BY location

		IF	(@sa_qty = @alloc_qty) -- Line Fully allocated
		BEGIN

			UPDATE	cvo_soft_alloc_det
			SET		status = -2
			WHERE	order_no = @order_no
			AND		order_ext= @order_ext
			AND		status IN (0,-1,-3)
		
			IF NOT EXISTS (SELECT 1 FROM cvo_soft_alloc_det (NOLOCK) WHERE order_no = @order_no AND order_ext= @order_ext AND status IN (0,-1,-3))
			BEGIN
				UPDATE	cvo_soft_alloc_hdr
				SET		status = -2
				WHERE	order_no = @order_no
				AND		order_ext= @order_ext
				AND		status IN (0,-1,-3)
			END

			DELETE	cvo_soft_alloc_hdr 
			WHERE	order_no = @order_no
			AND		order_ext = @order_ext
			AND		status = -2 

			DELETE	cvo_soft_alloc_det
			WHERE	order_no = @order_no
			AND		order_ext = @order_ext
			AND		status = -2 
		
		END
		ELSE
		BEGIN
			IF (@alloc_qty > 0) -- Lines partially allocated
			BEGIN

				UPDATE	cvo_soft_alloc_hdr
				SET		status = -2
				WHERE	order_no = @order_no
				AND		order_ext= @order_ext
				AND		status IN (0,-1,-3)

				UPDATE	cvo_soft_alloc_det
				SET		status = -2
				WHERE	order_no = @order_no
				AND		order_ext= @order_ext				
				AND		status IN (0,-1,-3)

				DELETE	cvo_soft_alloc_hdr 
				WHERE	order_no = @order_no
				AND		order_ext = @order_ext
				AND		status = -2 

				DELETE	cvo_soft_alloc_det
				WHERE	order_no = @order_no
				AND		order_ext = @order_ext
				AND		status = -2 
		
				SET	@new_soft_alloc_no = NULL

				SELECT	@new_soft_alloc_no = soft_alloc_no
				FROM	cvo_soft_alloc_no_assign (NOLOCK)
				WHERE	order_no = @order_no
				AND		order_ext = @order_ext

				IF (@new_soft_alloc_no IS NULL)
				BEGIN
					BEGIN TRAN
						UPDATE	dbo.cvo_soft_alloc_next_no
						SET		next_no = next_no + 1
					COMMIT TRAN	
					SELECT	@new_soft_alloc_no = next_no
					FROM	dbo.cvo_soft_alloc_next_no

					INSERT cvo_soft_alloc_no_assign (order_no, order_ext, soft_alloc_no)
					SELECT @order_no, @order_ext, @new_soft_alloc_no
				
				END
	
				IF NOT EXISTS (SELECT 1 FROM cvo_soft_alloc_hdr (NOLOCK) WHERE order_no = @order_no AND order_ext = @order_ext)
				BEGIN
					INSERT INTO cvo_soft_alloc_hdr (soft_alloc_no, order_no, order_ext, location, bo_hold, status)
					VALUES (@new_soft_alloc_no, @order_no, @order_ext, @location, 0, 0)		
				END

				DELETE	cvo_soft_alloc_det WHERE order_no = @order_no AND order_ext = @order_ext
		
				INSERT INTO	dbo.cvo_soft_alloc_det (soft_alloc_no, order_no, order_ext, line_no, location, part_no, quantity,  
											kit_part, change, deleted, is_case, is_pattern, is_pop_gift, status, add_case_flag)	-- 10.5		
				SELECT	@new_soft_alloc_no, @order_no, @order_ext, a.line_no, a.location, a.part_no, (a.ordered - ISNULL(c.qty,0)),
						0, 0, 0, b.is_case, b.is_pattern, b.is_pop_gif, 0, b.add_case -- v10.5
				FROM	ord_list a (NOLOCK)
				JOIN	cvo_ord_list b (NOLOCK)
				ON		a.order_no = b.order_no
				AND		a.order_ext = b.order_ext
				AND		a.line_no = b.line_no
				LEFT JOIN
						#tmp_alloc c (NOLOCK)
				ON		a.line_no = c.line_no			
				WHERE	a.order_no = @order_no
				AND		a.order_ext = @order_ext
				AND		(a.ordered - ISNULL(c.qty,0)) > 0

				EXEC dbo.cvo_update_soft_alloc_case_adjust_sp @new_soft_alloc_no, @order_no, @order_ext

				INSERT INTO	dbo.cvo_soft_alloc_det (soft_alloc_no, order_no, order_ext, line_no, location, part_no, quantity,  
											kit_part, change, deleted, is_case, is_pattern, is_pop_gift, status)			
				SELECT	@new_soft_alloc_no, @order_no, @order_ext, a.line_no, a.location, b.part_no, (a.ordered - ISNULL(c.qty,0)),
						1, 0, 0, 0, 0, 0, 0
				FROM	ord_list a (NOLOCK)
				JOIN	cvo_ord_list_kit b (NOLOCK)
				ON		a.order_no = b.order_no
				AND		a.order_ext = b.order_ext
				AND		a.line_no = b.line_no
				LEFT JOIN
						#tmp_alloc c (NOLOCK)
				ON		a.line_no = c.line_no
				WHERE	a.order_no = @order_no
				AND		a.order_ext = @order_ext	
				AND		b.replaced = 'S'	
				AND		(a.ordered - ISNULL(c.qty,0)) > 0	
			END

		END
		-- v1.4 End

		SET @last_row_id = @row_id

		SELECT	TOP 1 @row_id = row_id,
				@order_no = order_no,
				@order_ext = order_ext,
				@prior_hold = prior_hold, -- v1.2
				@release_only = release_only -- v1.5
		FROM	#fl_orders
		WHERE	row_id > @last_row_id
		ORDER BY row_id ASC
			
	END

	-- Clean up
	DROP TABLE #fl_orders
	DROP TABLE #cf_check
	DROP TABLE #exclusions
	DROP TABLE #tmp_alloc -- v1.4
	

END


GO
GRANT EXECUTE ON  [dbo].[cvo_release_alloc_fl_holds_sp] TO [public]
GO
