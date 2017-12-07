SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[cvo_release_allocate_print_rx_consolidate_sp]
AS
BEGIN
	-- DIRECTIVES
	SET NOCOUNT ON

	-- DECLARATIONS
	DECLARE	@order_no		int,
			@order_ext		int,
			@status			char(1),
			@iscustom		int,
			@row_id			int,
			@last_row_id	int,
			@prior_hold		varchar(30),
			@soft_alloc_no	int,
			@curr_ordered	decimal(20,8),
			@curr_alloc		decimal(20,8),
			@curr_alloc_pct	decimal(20,8),
			@back_ord_flag	int,
			@cons_no		int,
			@rc				int,
			@pnt_status		char(1) -- v1.5

	-- Working tables
	CREATE TABLE #rx_consolidate (
		row_id			int IDENTITY(1,1),
		order_no		int,
		order_ext		int,
		status			char(1),
		hold_reason		varchar(30),
		iscustom		int,
		processed		int,
		soft_alloc_no	int)

	CREATE TABLE #exclusions (
		order_no		int,
		order_ext		int,
		has_line_exc	int NULL) 

	CREATE TABLE #line_exclusions (
		order_no		int,
		order_ext		int,
		line_no			int)

	EXEC dbo.cvo_auto_alloc_process_sp 1, 'cvo_release_allocate_print_rx_consolidate_sp' -- v1.6

	-- Populate working table
	INSERT	#rx_consolidate (order_no, order_ext, status, hold_reason, iscustom, processed, soft_alloc_no)
	SELECT	a.order_no,
			a.ext,
			a.status,
			ISNULL(a.hold_reason,''),
			0,
			0,
			0
	FROM	orders_all a (NOLOCK)
	JOIN	cvo_armaster_all b (NOLOCK)
	ON		a.cust_code = b.customer_code
	WHERE	a.status <= 'N'
	AND		LEFT(a.user_category,2) = 'RX'
	AND		b.rx_consolidate = 1
	AND		a.who_entered <> 'BACKORDR'

	-- Remove any records where the hold is not RXC (RX Consolidate)
	DELETE	#rx_consolidate
	WHERE	status = 'A'
	AND		hold_reason <> 'RXC'

	-- Remove any records where the status is not N or A
	DELETE	#rx_consolidate
	WHERE	status NOT IN ('A','N')

	-- Remove future allocations
	DELETE	a
	FROM	#rx_consolidate a 
	JOIN	cvo_orders_all b (NOLOCK)
	ON		a.order_no = b.order_no
	AND		a.order_ext = b.ext
	WHERE	CONVERT(varchar(10),ISNULL(b.allocation_date,GETDATE()),121) > CONVERT(varchar(10),GETDATE(),121)

	-- Remove future delivery dates
	DELETE	a
	FROM	#rx_consolidate a 
	JOIN	orders_all  b (NOLOCK)
	ON		a.order_no = b.order_no
	AND		a.order_ext = b.ext
	WHERE	CONVERT(varchar(10),ISNULL(b.sch_ship_date,GETDATE()),121) > CONVERT(varchar(10),GETDATE(),121)

	-- Mark any records that have custom frames
	UPDATE	a
	SET		iscustom = 1
	FROM	#rx_consolidate a
	JOIN	cvo_ord_list b (NOLOCK)
	ON		a.order_no = b.order_no
	AND		a.order_ext = b.order_ext
	WHERE	b.is_customized = 'S'

	-- Set the soft alloc number
	UPDATE	a
	SET		soft_alloc_no = b.soft_alloc_no
	FROM	#rx_consolidate a
	JOIN	cvo_soft_alloc_no_assign b (NOLOCK)
	ON		a.order_no = b.order_no
	AND		a.order_ext = b.order_ext

	-- Process Records
	SET @last_row_id = 0

	SELECT	TOP 1 @row_id = row_id,
			@order_no = order_no,
			@order_ext = order_ext,
			@status = status,
			@iscustom = iscustom,
			@soft_alloc_no = soft_alloc_no
	FROM	#rx_consolidate
	WHERE	row_id > @last_row_id
	ORDER BY row_id ASC

	WHILE (@@ROWCOUNT > 0)
	BEGIN

		-- If the order is on hold then it needs to be released
		IF (@status = 'A')
		BEGIN
				-- Check if the order has a prior hold
				-- v1.4 Start
				SET @prior_hold = ''

				SELECT	@prior_hold = hold_reason
				FROM	cvo_next_so_hold_vw (NOLOCK)
				WHERE	order_no = @order_no
				AND		order_ext = @order_ext				

				--SELECT	@prior_hold = ISNULL(prior_hold,'') 
				--FROM	cvo_orders_all (NOLOCK)
				--WHERE	order_no = @order_no
				--AND		ext = @order_ext
				-- v1.4 End
		
				-- If prior hold set then release RXC hold and set it to the prior hold
				IF (@prior_hold > '')
				BEGIN
					UPDATE	orders_all
					SET		hold_reason = @prior_hold
					WHERE	order_no = @order_no
					AND		ext = @order_ext
				
					-- v1.4 Start
					DELETE	cvo_so_holds
					WHERE	order_no = @order_no
					AND		order_ext = @order_ext
					AND		hold_reason = @prior_hold

					--UPDATE	cvo_orders_all
					--SET		prior_hold = ''
					--WHERE	order_no = @order_no
					--AND		ext = @order_ext
					-- v1.4 End

					INSERT INTO tdc_log WITH (ROWLOCK) ( tran_date , userid , trans_source , module , trans , tran_no , tran_ext , part_no , lot_ser , bin_no , location , quantity , data ) 
					SELECT	GETDATE() , 'RX_CONSOLIDATE' , 'VB' , 'PLW' , 'ORDER UPDATE' , a.order_no , a.ext , '' , '' , '' , a.location , '' ,
							'STATUS:N/RELEASE RXC USER HOLD; HOLD REASON:' 
					FROM	orders_all a (NOLOCK)
					WHERE	a.order_no = @order_no
					AND		a.ext = @order_ext

					INSERT INTO tdc_log WITH (ROWLOCK) ( tran_date , userid , trans_source , module , trans , tran_no , tran_ext , part_no , lot_ser , bin_no , location , quantity , data ) 
					SELECT	GETDATE() , 'RX_CONSOLIDATE' , 'VB' , 'PLW' , 'ORDER UPDATE' , a.order_no , a.ext , '' , '' , '' , a.location , '' ,
							'STATUS:A/PROMOTE USER HOLD; HOLD REASON:' + @prior_hold -- v1.4
					FROM	orders_all a (NOLOCK)
					WHERE	a.order_no = @order_no
					AND		a.ext = @order_ext

					SET @last_row_id = @row_id

					SELECT	TOP 1 @row_id = row_id,
							@order_no = order_no,
							@order_ext = order_ext,
							@status = status,
							@iscustom = iscustom,
							@soft_alloc_no = soft_alloc_no
					FROM	#rx_consolidate
					WHERE	row_id > @last_row_id

					CONTINUE

				END
				ELSE
				BEGIN
					-- Release the order from RXC hold
					UPDATE	orders_all
					SET		hold_reason = '',
							status = 'N'
					WHERE	order_no = @order_no
					AND		ext = @order_ext

					INSERT INTO tdc_log WITH (ROWLOCK) ( tran_date , userid , trans_source , module , trans , tran_no , tran_ext , part_no , lot_ser , bin_no , location , quantity , data ) 
					SELECT	GETDATE() , 'RX_CONSOLIDATE' , 'VB' , 'PLW' , 'ORDER UPDATE' , a.order_no , a.ext , '' , '' , '' , a.location , '' ,
							'STATUS:N/RELEASE RXC USER HOLD; HOLD REASON:' 
					FROM	orders_all a (NOLOCK)
					WHERE	a.order_no = @order_no
					AND		a.ext = @order_ext
				END
		END	

		-- If the order is a custom frame then check it will allocate
		IF (@iscustom = 1)
		BEGIN
			DELETE	#exclusions 
			DELETE	#line_exclusions
	
			EXEC dbo.cvo_soft_alloc_CF_BO_check_sp	@soft_alloc_no, @order_no, @order_ext
		
			-- If not fully available then do not process
			IF EXISTS (SELECT 1 FROM #exclusions WHERE order_no = @order_no AND order_ext = @order_ext)
			BEGIN
					SET @last_row_id = @row_id

					SELECT	TOP 1 @row_id = row_id,
							@order_no = order_no,
							@order_ext = order_ext,
							@status = status,
							@iscustom = iscustom,
							@soft_alloc_no = soft_alloc_no
					FROM	#rx_consolidate
					WHERE	row_id > @last_row_id

					CONTINUE			
			END
			
			-- Allocate the order
			UPDATE	cvo_soft_alloc_hdr
			SET		status = -1
			WHERE	soft_alloc_no = @soft_alloc_no

			UPDATE	cvo_soft_alloc_det
			SET		status = -1
			WHERE	soft_alloc_no = @soft_alloc_no

			-- Insert audit record, this is checked by the client and stops them changing the order while begin allocated
			INSERT	dbo.cvo_process_soft_allocations_audit (allocation_date, cons_no, order_no, order_ext, perc_allocated, error_messages)
			SELECT	GETDATE(), 0, @order_no, @order_ext, 0, 'ALLOCATING'

			EXEC @rc = tdc_order_after_save @order_no, @order_ext   

			IF (@rc = 0)
			BEGIN

				-- v1.2 Start
				IF EXISTS (SELECT 1 FROM tdc_soft_alloc_tbl (NOLOCK) WHERE order_no = @order_no AND order_ext = @order_ext AND order_type = 'S')
				BEGIN

					IF (OBJECT_ID('tempdb..#PrintData') IS NOT NULL) 
						DROP TABLE #PrintData

					CREATE TABLE #PrintData 
					(row_id			INT IDENTITY (1,1)	NOT NULL
					,data_field		VARCHAR(300)		NOT NULL
					,data_value		VARCHAR(300)			NULL)
					
					EXEC CVO_disassembled_frame_sp @order_no, @order_ext
					
					EXEC CVO_disassembled_inv_adjust_sp @order_no, @order_ext
						
					EXEC CVO_disassembled_print_inv_adjust_sp @order_no, @order_ext		
						
					UPDATE	cvo_orders_all 
					SET		flag_print = 2 
					WHERE	order_no = @order_no 
					AND		 ext = @order_ext

					INSERT INTO tdc_log WITH (ROWLOCK) ( tran_date , userid , trans_source , module , trans , tran_no , tran_ext , part_no , lot_ser , bin_no , location , quantity , data ) 
					SELECT	GETDATE() , 'RX_CONSOLIDATE' , 'VB' , 'PLW' , 'ORDER UPDATE' , a.order_no , a.ext , '' , '' , '' , a.location , '' ,
							'STATUS:N/PRINT WORKS ORDER'
					FROM	orders_all a (NOLOCK)
					JOIN	cvo_orders_all b (NOLOCK)
					ON		a.order_no = b.order_no
					AND		a.ext = b.ext
					WHERE	a.order_no = @order_no
					AND		a.ext = @order_ext

					EXEC dbo.cvo_print_pick_ticket_sp @order_no, @order_ext

					INSERT INTO tdc_log WITH (ROWLOCK) ( tran_date , userid , trans_source , module , trans , tran_no , tran_ext , part_no , lot_ser , bin_no , location , quantity , data ) 
					SELECT	GETDATE() , 'RX_CONSOLIDATE' , 'VB' , 'PLW' , 'PICK TICKET' , a.order_no , a.ext , '' , '' , '' , a.location , '' ,
							'STATUS:Q;'
					FROM	orders_all a (NOLOCK)
					JOIN	cvo_orders_all b (NOLOCK)
					ON		a.order_no = b.order_no
					AND		a.ext = b.ext
					WHERE	a.order_no = @order_no
					AND		a.ext = @order_ext

					UPDATE	dbo.cvo_soft_alloc_hdr WITH (ROWLOCK)
					SET		status = -2
					WHERE	order_no = @order_no
					AND		order_ext = @order_ext
					AND		status = -1	

					UPDATE	dbo.cvo_soft_alloc_det WITH (ROWLOCK)
					SET		status = -2
					WHERE	order_no = @order_no
					AND		order_ext = @order_ext
					AND		status = -1	

					DELETE	dbo.cvo_soft_alloc_hdr
					WHERE	order_no = @order_no
					AND		order_ext = @order_ext
					AND		status = -2

					DELETE	dbo.cvo_soft_alloc_det
					WHERE	order_no = @order_no
					AND		order_ext = @order_ext
					AND		status = -2

					DELETE	dbo.cvo_process_soft_allocations_audit WHERE order_no = @order_no AND order_ext = @order_ext AND error_messages = 'ALLOCATING' 

					SELECT	@cons_no = consolidation_no 
					FROM	tdc_cons_ords (NOLOCK)
					WHERE	order_no = @order_no
					AND		order_ext = @order_ext

					IF (@cons_no IS NULL)
						SET @cons_no = 0

					INSERT	dbo.cvo_process_soft_allocations_audit (allocation_date, cons_no, order_no, order_ext, perc_allocated, error_messages)
					SELECT	GETDATE(), @cons_no, @order_no, @order_ext, 100, ''
				END
				-- v1.2 End
			END
			ELSE
			BEGIN

				UPDATE	dbo.cvo_soft_alloc_hdr WITH (ROWLOCK)
				SET		status = 0
				WHERE	soft_alloc_no = @soft_alloc_no
				AND		status = -1	

				UPDATE	dbo.cvo_soft_alloc_det WITH (ROWLOCK)
				SET		status = 0
				WHERE	soft_alloc_no = @soft_alloc_no
				AND		status = -1	
		
				DELETE	dbo.cvo_process_soft_allocations_audit WHERE order_no = @order_no AND order_ext = @order_ext AND error_messages = 'ALLOCATING'

			END

			SET @last_row_id = @row_id
			
			SELECT	TOP 1 @row_id = row_id,
					@order_no = order_no,
					@order_ext = order_ext,
					@status = status,
					@iscustom = iscustom,
					@soft_alloc_no = soft_alloc_no
			FROM	#rx_consolidate
			WHERE	row_id > @last_row_id

			CONTINUE			

		END
		ELSE
		BEGIN -- Non Custom Frame
			-- Allocate the order
			UPDATE	cvo_soft_alloc_hdr
			SET		status = -1
			WHERE	soft_alloc_no = @soft_alloc_no

			UPDATE	cvo_soft_alloc_det
			SET		status = -1
			WHERE	soft_alloc_no = @soft_alloc_no

			-- Insert audit record, this is checked by the client and stops them changing the order while begin allocated
			INSERT	dbo.cvo_process_soft_allocations_audit (allocation_date, cons_no, order_no, order_ext, perc_allocated, error_messages)
			SELECT	GETDATE(), 0, @order_no, @order_ext, 0, 'ALLOCATING'

			EXEC @rc = tdc_order_after_save @order_no, @order_ext   

			IF (@rc = 0)
			BEGIN
				-- v1.3 Start
				IF NOT EXISTS (SELECT 1 FROM orders_all (NOLOCK) WHERE order_no = @order_no AND ext = @order_ext AND status IN ('Q','P'))
				BEGIN

					EXEC dbo.cvo_print_pick_ticket_sp @order_no, @order_ext

					-- v1.5 Start
					SELECT	@pnt_status = status
					FROM	orders_all (NOLOCK)
					WHERE	order_no = @order_no
					AND		ext = @order_ext

					IF (@pnt_status = 'Q')
					BEGIN
						INSERT INTO tdc_log WITH (ROWLOCK) ( tran_date , userid , trans_source , module , trans , tran_no , tran_ext , part_no , lot_ser , bin_no , location , quantity , data ) 
						SELECT	GETDATE() , 'RX_CONSOLIDATE' , 'VB' , 'PLW' , 'PICK TICKET' , a.order_no , a.ext , '' , '' , '' , a.location , '' ,
								'STATUS:Q;'
						FROM	orders_all a (NOLOCK)
						JOIN	cvo_orders_all b (NOLOCK)
						ON		a.order_no = b.order_no
						AND		a.ext = b.ext
						WHERE	a.order_no = @order_no
						AND		a.ext = @order_ext
					END
					-- v1.5 End
				END -- v1.3 End
			END
			ELSE
			BEGIN
				UPDATE	dbo.cvo_soft_alloc_hdr WITH (ROWLOCK)
				SET		status = 0
				WHERE	soft_alloc_no = @soft_alloc_no
				AND		status = -1	

				UPDATE	dbo.cvo_soft_alloc_det WITH (ROWLOCK)
				SET		status = 0
				WHERE	soft_alloc_no = @soft_alloc_no
				AND		status = -1	
		
				DELETE	dbo.cvo_process_soft_allocations_audit WHERE order_no = @order_no AND order_ext = @order_ext AND error_messages = 'ALLOCATING'

				SET @last_row_id = @row_id
				
				SELECT	TOP 1 @row_id = row_id,
						@order_no = order_no,
						@order_ext = order_ext,
						@status = status,
						@iscustom = iscustom,
						@soft_alloc_no = soft_alloc_no
				FROM	#rx_consolidate
				WHERE	row_id > @last_row_id

				CONTINUE	

			END
		END

		-- Check the allocate status
		IF EXISTS (SELECT 1 FROM tdc_soft_alloc_tbl (NOLOCK) WHERE order_no = @order_no AND order_ext = @order_ext AND order_type = 'S') 
		BEGIN

			SELECT	@curr_ordered = SUM(a.ordered)
			FROM	ord_list a (NOLOCK)
			WHERE	a.order_no = @order_no
			AND		a.order_ext = @order_ext

			SELECT	@curr_alloc = SUM(qty)
			FROM	tdc_soft_alloc_tbl (NOLOCK)
			WHERE	order_no = @order_no
			AND		order_ext = @order_ext
			AND		order_type = 'S'

			SELECT	@curr_alloc_pct = (@curr_alloc / @curr_ordered) * 100
	
			IF (@curr_alloc_pct IS NULL)
				SET @curr_alloc_pct = 0

			SELECT	@back_ord_flag = back_ord_flag
			FROM	orders_all (NOLOCK)
			WHERE	order_no = @order_no
			AND		ext = @order_ext

			IF (@curr_alloc_pct < 100)
			BEGIN

				IF (@back_ord_flag = 1)
				BEGIN
					-- UnAllocate any item that did allocate
					EXEC CVO_UnAllocate_sp @order_no, @order_ext, 0, 'RX_CONSOLIDATE'
	
					-- Set the order on hold
					UPDATE	orders_all WITH (ROWLOCK)
					SET		status = 'A',
							hold_reason = 'SC'
					WHERE	order_no = @order_no
					AND		ext = @order_ext

					-- Reset the soft allocation
					UPDATE	cvo_soft_alloc_hdr WITH (ROWLOCK)
					SET		status = 0
					WHERE	soft_alloc_no = @soft_alloc_no

					UPDATE	cvo_soft_alloc_det WITH (ROWLOCK)
					SET		status = 0
					WHERE	soft_alloc_no = @soft_alloc_no

					-- Insert a tdc_log record for the order going on hold
					INSERT INTO tdc_log WITH (ROWLOCK) ( tran_date , userid , trans_source , module , trans , tran_no , tran_ext , part_no , lot_ser , bin_no , location , quantity , data ) 
					SELECT	GETDATE() , 'RX_CONSOLIDATE' , 'VB' , 'PLW' , 'ORDER UPDATE' , a.order_no , a.ext , '' , '' , '' , a.location , '' ,
							'STATUS:A/SHIP COMPLETE; HOLD REASON: SC' -- v1.4
					FROM	orders_all a (NOLOCK)
					WHERE	a.order_no = @order_no
					AND		a.ext = @order_ext		

					DELETE	dbo.cvo_process_soft_allocations_audit WHERE order_no = @order_no AND order_ext = @order_ext AND error_messages = 'ALLOCATING'
				
				END
				ELSE
				BEGIN

					UPDATE	dbo.cvo_soft_alloc_hdr WITH (ROWLOCK)
					SET		status = -2
					WHERE	order_no = @order_no
					AND		order_ext = @order_ext
					AND		status = -1	

					UPDATE	dbo.cvo_soft_alloc_det WITH (ROWLOCK)
					SET		status = -2
					WHERE	order_no = @order_no
					AND		order_ext = @order_ext
					AND		status = -1	

					-- Create table to work out the back orders
					CREATE TABLE #sa_backorder (
						line_no		int,
						part_no		varchar(30),
						quantity	decimal(20,8))

					INSERT	#sa_backorder (line_no, part_no, quantity)
					SELECT	a.line_no,
							a.part_no,
							SUM(a.ordered) - ISNULL(CASE WHEN SUM(b.qty) IS NULL THEN 0 ELSE SUM(b.qty) END,0)
					FROM	ord_list a (NOLOCK)
					LEFT JOIN
							(SELECT SUM(qty) qty, order_no, order_ext, order_type, line_no FROM tdc_soft_alloc_tbl (NOLOCK) GROUP BY order_no, order_ext, order_type, line_no) b 
					ON		a.order_no = b.order_no
					AND		a.order_ext = b.order_ext
					AND		a.line_no = b.line_no
					WHERE	a.order_no = @order_no
					AND		a.order_ext = @order_ext
					AND		ISNULL(b.order_type,'S') = 'S'
					GROUP BY a.line_no, a.part_no

					IF NOT EXISTS (SELECT 1 FROM cvo_soft_alloc_hdr WHERE soft_alloc_no = @soft_alloc_no AND status = 0)
					BEGIN
						INSERT	cvo_soft_alloc_hdr WITH (ROWLOCK) (soft_alloc_no, order_no, order_ext, location, bo_hold, status)
						SELECT	@soft_alloc_no, order_no, order_ext, location, CASE WHEN @back_ord_flag = 1 THEN 0 ELSE 1 END, 0
						FROM	cvo_soft_alloc_hdr (NOLOCK)
						WHERE	soft_alloc_no = @soft_alloc_no
					END

					INSERT	cvo_soft_alloc_det WITH (ROWLOCK)(soft_alloc_no, order_no, order_ext, line_no, location, part_no, quantity,  
															kit_part, change, deleted, is_case, is_pattern, is_pop_gift, status, add_case_flag, case_adjust)
					SELECT	DISTINCT @soft_alloc_no, a.order_no, a.order_ext, a.line_no, a.location, a.part_no, b.quantity,  
															a.kit_part, 0, a.deleted, a.is_case, a.is_pattern, a.is_pop_gift, 0, a.add_case_flag, a.case_adjust 

					FROM	cvo_soft_alloc_det a (NOLOCK)
					JOIN	#sa_backorder b
					ON		a.line_no = b.line_no
					AND		a.part_no = b.part_no
					WHERE	b.quantity > 0
					AND		soft_alloc_no = @soft_alloc_no
					
					DROP TABLE #sa_backorder

					DELETE	dbo.cvo_soft_alloc_hdr
					WHERE	order_no = @order_no
					AND		order_ext = @order_ext
					AND		status = -2

					DELETE	dbo.cvo_soft_alloc_det
					WHERE	order_no = @order_no
					AND		order_ext = @order_ext
					AND		status = -2

					EXEC dbo.cvo_update_soft_alloc_case_adjust_sp @soft_alloc_no, @order_no, @order_ext
				END

				DELETE	dbo.cvo_process_soft_allocations_audit WHERE order_no = @order_no AND order_ext = @order_ext AND error_messages = 'ALLOCATING' 

				SELECT	@cons_no = consolidation_no 
				FROM	tdc_cons_ords (NOLOCK)
				WHERE	order_no = @order_no
				AND		order_ext = @order_ext

				IF (@cons_no IS NULL)
					SET @cons_no = 0

				INSERT	dbo.cvo_process_soft_allocations_audit (allocation_date, cons_no, order_no, order_ext, perc_allocated, error_messages)
				SELECT	GETDATE(), @cons_no, @order_no, @order_ext, @curr_alloc_pct, ''

			END
			ELSE
			BEGIN
				UPDATE	dbo.cvo_soft_alloc_hdr WITH (ROWLOCK)
				SET		status = -2
				WHERE	order_no = @order_no
				AND		order_ext = @order_ext
				AND		status = -1	

				UPDATE	dbo.cvo_soft_alloc_det WITH (ROWLOCK)
				SET		status = -2
				WHERE	order_no = @order_no
				AND		order_ext = @order_ext
				AND		status = -1	

				DELETE	dbo.cvo_soft_alloc_hdr
				WHERE	order_no = @order_no
				AND		order_ext = @order_ext
				AND		status = -2

				DELETE	dbo.cvo_soft_alloc_det
				WHERE	order_no = @order_no
				AND		order_ext = @order_ext
				AND		status = -2

				DELETE	dbo.cvo_process_soft_allocations_audit WHERE order_no = @order_no AND order_ext = @order_ext AND error_messages = 'ALLOCATING' 

				SELECT	@cons_no = consolidation_no 
				FROM	tdc_cons_ords (NOLOCK)
				WHERE	order_no = @order_no
				AND		order_ext = @order_ext

				IF (@cons_no IS NULL)
					SET @cons_no = 0

				INSERT	dbo.cvo_process_soft_allocations_audit (allocation_date, cons_no, order_no, order_ext, perc_allocated, error_messages)
				SELECT	GETDATE(), @cons_no, @order_no, @order_ext, @curr_alloc_pct, ''

			END			
		END
		ELSE
		BEGIN -- If no allocation has been done then reset the order
			UPDATE	dbo.cvo_soft_alloc_hdr WITH (ROWLOCK)
			SET		status = 0
			WHERE	soft_alloc_no = @soft_alloc_no
			AND		status = -1	

			UPDATE	dbo.cvo_soft_alloc_det WITH (ROWLOCK)
			SET		status = 0
			WHERE	soft_alloc_no = @soft_alloc_no
			AND		status = -1	
	
			DELETE	dbo.cvo_process_soft_allocations_audit WHERE order_no = @order_no AND order_ext = @order_ext AND error_messages = 'ALLOCATING'

		END

		SET @last_row_id = @row_id

		SELECT	TOP 1 @row_id = row_id,
				@order_no = order_no,
				@order_ext = order_ext,
				@status = status,
				@iscustom = iscustom,
				@soft_alloc_no = soft_alloc_no
		FROM	#rx_consolidate
		WHERE	row_id > @last_row_id
		ORDER BY row_id ASC
	END	

	EXEC dbo.cvo_auto_alloc_process_sp 0 -- v1.6

	DROP TABLE #exclusions
	DROP TABLE #line_exclusions
	DROP TABLE #rx_consolidate
END
GO
GRANT EXECUTE ON  [dbo].[cvo_release_allocate_print_rx_consolidate_sp] TO [public]
GO
