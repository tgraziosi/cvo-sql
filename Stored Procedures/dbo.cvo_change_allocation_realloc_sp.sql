SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[cvo_change_allocation_realloc_sp]	@order_no	int,
													@order_ext	int,
													@ret		int OUTPUT,
													@message	varchar(255) OUTPUT
AS
BEGIN
	-- DIRECTIVES
	SET NOCOUNT ON
	SET QUOTED_IDENTIFIER OFF
	
	-- DECLARATIONS
	DECLARE	@cur_order_no			int,
			@cur_order_ext			int,
			@st_cons_no				int,
			@row_id					int,
			@last_row_id			int,
			@soft_alloc_no			int,
			@curr_ordered			decimal(20,8),
			@curr_alloc				decimal(20,8),
			@curr_alloc_pct			decimal(20,8),
			@back_ord_flag			int

	-- INITIALIZE
	SET	@ret = 0 
	SET @message = ''
	SET @st_cons_no = -1
	
	-- WORKING TABLE
	CREATE TABLE #cvo_alloc_orders (
		row_id			int IDENTITY(1,1),
		order_no		int,
		order_ext		int)

	CREATE TABLE #global_ship_print (
		order_no		int,
		order_ext		int,
		global_ship		varchar(10))

	CREATE TABLE #cf_check (
		ret		char(1))

	-- PROCESSING
	IF EXISTS(SELECT 1 FROM cvo_masterpack_consolidation_det (NOLOCK) WHERE order_no = @order_no AND order_ext = @order_ext)
	BEGIN
		-- Get the consolidation number
		SELECT	@st_cons_no = consolidation_no
		FROM	cvo_masterpack_consolidation_det (NOLOCK) 
		WHERE	order_no = @order_no 
		AND		order_ext = @order_ext

		INSERT	#cvo_alloc_orders (order_no, order_ext)
		SELECT	a.order_no,
				a.ext
		FROM	orders_all a (NOLOCK)
		JOIN	cvo_masterpack_consolidation_det b (NOLOCK)
		ON		a.order_no = b.order_no
		AND		a.ext = b.order_ext
		WHERE	b.consolidation_no = @st_cons_no

		IF (@@ROWCOUNT = 0)
		BEGIN
			SET	@ret = 0 
			SET @message = ''
			RETURN
		END

	END
	ELSE
	BEGIN

		INSERT	#cvo_alloc_orders (order_no, order_ext)
		SELECT	@order_no, @order_ext

	END


	IF EXISTS (SELECT 1 FROM tdc_plw_orders_being_allocated a (NOLOCK) JOIN #cvo_alloc_orders b ON a.order_no = b.order_no AND a.order_ext = b.order_ext)
	BEGIN
		SET	@ret = 0
		SET @message = ''
		RETURN
	END

	-- Mark soft alloc hdr records
	UPDATE	a
	SET		status = -1
	FROM	dbo.cvo_soft_alloc_hdr a WITH (ROWLOCK)
	JOIN	dbo.cvo_soft_alloc_det b (NOLOCK)
	ON		a.soft_alloc_no = b.soft_alloc_no
	JOIN	#cvo_alloc_orders o 
	ON		a.order_no = o.order_no
	AND		a.order_ext = o.order_ext
	WHERE	a.status = 0
	AND		b.status = 0
	AND		a.bo_hold = 0

	-- Mark the detail records
	UPDATE	a
	SET		status = -1
	FROM	dbo.cvo_soft_alloc_det a WITH (ROWLOCK)
	JOIN	dbo.cvo_soft_alloc_hdr b (NOLOCK)
	ON		a.soft_alloc_no = b.soft_alloc_no
	JOIN	#cvo_alloc_orders o 
	ON		a.order_no = o.order_no
	AND		a.order_ext = o.order_ext
	WHERE	a.status = 0
	AND		b.status = -1

	-- Unallocate any lines that are allocated 
	SET @last_row_id = 0

	SELECT	TOP 1 @row_id = row_id,
			@cur_order_no = order_no,
			@cur_order_ext = order_ext
	FROM	#cvo_alloc_orders
	WHERE	row_id > @last_row_id
	ORDER BY row_id ASC


	WHILE @@ROWCOUNT <> 0
	BEGIN

		-- Call the allocate routine
		EXEC @ret = tdc_order_after_save @cur_order_no, @cur_order_ext 

		IF NOT(@@ERROR = 0 AND @ret = 0)
		BEGIN
			SET @ret = -1
			SET @message = 'Allocation Failed.'
			RETURN
		END

		INSERT	#global_ship_print (order_no, order_ext, global_ship)
		SELECT	order_no, ext, sold_to
		FROM	orders_all (NOLOCK)
		WHERE	order_no = @cur_order_no
		AND		ext = @cur_order_ext
		AND		ISNULL(sold_to,'') > ''

		SELECT	@soft_alloc_no = soft_alloc_no
		FROM	cvo_soft_alloc_hdr (NOLOCK)
		WHERE	order_no = @cur_order_no
		AND		order_ext = @cur_order_ext

		-- RX Order Consolidation - If the customer is marked as RX consolidate and it is not a custom frame order then print the pick ticket
		IF EXISTS (SELECT 1 FROM orders_all a (NOLOCK) JOIN cvo_armaster_all b (NOLOCK) ON a.cust_code = b.customer_code WHERE a.order_no = @cur_order_no
					AND	a.ext = @cur_order_ext AND b.rx_consolidate = 1 AND LEFT(a.user_category,2) = 'RX') 
		BEGIN
 			IF NOT EXISTS (SELECT 1 FROM CVO_ord_list (NOLOCK) WHERE order_no = @cur_order_no AND order_ext = @cur_order_ext AND is_customized = 'S')
			BEGIN	
				IF EXISTS (SELECT 1 FROM tdc_soft_alloc_tbl (NOLOCK) WHERE order_no = @cur_order_no AND order_ext = @cur_order_ext AND order_type = 'S')
				BEGIN
					IF NOT EXISTS (SELECT 1 FROM orders_all (NOLOCK) WHERE order_no = @cur_order_no AND ext = @cur_order_ext AND status IN ('Q','P'))
					BEGIN

						EXEC dbo.cvo_print_pick_ticket_sp @cur_order_no, @cur_order_ext

						DELETE	#global_ship_print
						WHERE	order_no = @cur_order_no
						AND		order_ext = @cur_order_ext

						INSERT INTO tdc_log WITH (ROWLOCK) ( tran_date , userid , trans_source , module , trans , tran_no , tran_ext , part_no , lot_ser , bin_no , location , quantity , data ) 
						SELECT	GETDATE() , 'AUTO_ALLOC' , 'VB' , 'PLW' , 'PICK TICKET' , a.order_no , a.ext , '' , '' , '' , a.location , '' ,
								'STATUS:Q;'
						FROM	orders_all a (NOLOCK)
						JOIN	cvo_orders_all b (NOLOCK)
						ON		a.order_no = b.order_no
						AND		a.ext = b.ext
						WHERE	a.order_no = @cur_order_no
						AND		a.ext = @cur_order_ext
					END 
				END 
			END
		END

		-- Custom Frames
		IF EXISTS(SELECT 1 FROM orders_all (NOLOCK) WHERE order_no = @cur_order_no AND ext = @cur_order_ext AND status = 'N')
		BEGIN
			IF EXISTS(SELECT 1 FROM CVO_ord_list (NOLOCK) WHERE order_no = @cur_order_no AND order_ext = @cur_order_ext AND is_customized = 'S') 
			BEGIN
				IF EXISTS (SELECT 1 FROM tdc_soft_alloc_tbl (NOLOCK) WHERE order_no = @cur_order_no AND order_ext = @cur_order_ext AND order_type = 'S')
				BEGIN

					TRUNCATE TABLE #cf_check
					INSERT	#cf_check
					EXEC	cvo_soft_alloc_CF_BO_check_sp @soft_alloc_no, @cur_order_no, @cur_order_ext 

					IF NOT EXISTS (SELECT 1 FROM #cf_check WHERE ret = '-1')
					BEGIN

						IF (OBJECT_ID('tempdb..#PrintData') IS NOT NULL) 
							DROP TABLE #PrintData

						CREATE TABLE #PrintData 
						(row_id			INT IDENTITY (1,1)	NOT NULL
						,data_field		VARCHAR(300)		NOT NULL
						,data_value		VARCHAR(300)			NULL)
						
						EXEC CVO_disassembled_frame_sp @cur_order_no, @cur_order_ext
						
						EXEC CVO_disassembled_inv_adjust_sp @cur_order_no, @cur_order_ext
							
						EXEC CVO_disassembled_print_inv_adjust_sp @cur_order_no, @cur_order_ext		
							
						UPDATE	cvo_orders_all 
						SET		flag_print = 2 
						WHERE	order_no = @cur_order_no 
						AND		 ext = @cur_order_ext

						INSERT INTO tdc_log WITH (ROWLOCK) ( tran_date , userid , trans_source , module , trans , tran_no , tran_ext , part_no , lot_ser , bin_no , location , quantity , data ) 
						SELECT	GETDATE() , 'AUTO_ALLOC' , 'VB' , 'PLW' , 'ORDER UPDATE' , a.order_no , a.ext , '' , '' , '' , a.location , '' ,
								'STATUS:N/PRINT WORKS ORDER'
						FROM	orders_all a (NOLOCK)
						JOIN	cvo_orders_all b (NOLOCK)
						ON		a.order_no = b.order_no
						AND		a.ext = b.ext
						WHERE	a.order_no = @cur_order_no					
						
						EXEC dbo.cvo_print_pick_ticket_sp @cur_order_no, @cur_order_ext

						INSERT INTO tdc_log WITH (ROWLOCK) ( tran_date , userid , trans_source , module , trans , tran_no , tran_ext , part_no , lot_ser , bin_no , location , quantity , data ) 
						SELECT	GETDATE() , 'AUTO_ALLOC' , 'VB' , 'PLW' , 'PICK TICKET' , a.order_no , a.ext , '' , '' , '' , a.location , '' ,
								'STATUS:Q;'
						FROM	orders_all a (NOLOCK)
						JOIN	cvo_orders_all b (NOLOCK)
						ON		a.order_no = b.order_no
						AND		a.ext = b.ext
						WHERE	a.order_no = @cur_order_no
						AND		a.ext = @cur_order_ext

						DELETE	#global_ship_print
						WHERE	order_no = @cur_order_no
						AND		order_ext = @cur_order_ext

					END
				END
			END
		END

		IF EXISTS (SELECT 1 FROM tdc_soft_alloc_tbl (NOLOCK) WHERE order_no = @cur_order_no AND order_ext = @cur_order_ext AND order_type = 'S') 
		BEGIN

			SELECT	@curr_ordered = SUM(a.ordered)
			FROM	ord_list a (NOLOCK)
			WHERE	a.order_no = @cur_order_no
			AND		a.order_ext = @cur_order_ext

			SELECT	@curr_alloc = SUM(qty)
			FROM	tdc_soft_alloc_tbl (NOLOCK)
			WHERE	order_no = @cur_order_no
			AND		order_ext = @cur_order_ext
			AND		order_type = 'S'

			SELECT	@curr_alloc_pct = (@curr_alloc / @curr_ordered) * 100

			SELECT	@back_ord_flag = back_ord_flag
			FROM	orders_all (NOLOCK)
			WHERE	order_no = @cur_order_no
			AND		ext = @cur_order_ext

			IF (@curr_alloc_pct < 100)
			BEGIN

				IF (@back_ord_flag = 1)
				BEGIN
					-- UnAllocate any item that did allocate
					EXEC CVO_UnAllocate_sp @cur_order_no, @cur_order_ext, 0, 'AUTO_ALLOC'

					-- Set the order on hold
					UPDATE	orders_all WITH (ROWLOCK)
					SET		status = 'A',
							hold_reason = 'SC'
					WHERE	order_no = @cur_order_no
					AND		ext = @cur_order_ext

					-- Reset the soft allocation
					UPDATE	cvo_soft_alloc_hdr WITH (ROWLOCK)
					SET		status = 0
					WHERE	soft_alloc_no = @soft_alloc_no

					UPDATE	cvo_soft_alloc_det WITH (ROWLOCK)
					SET		status = 0
					WHERE	soft_alloc_no = @soft_alloc_no

					-- Insert a tdc_log record for the order going on hold
					INSERT INTO tdc_log WITH (ROWLOCK) ( tran_date , userid , trans_source , module , trans , tran_no , tran_ext , part_no , lot_ser , bin_no , location , quantity , data ) 
					SELECT	GETDATE() , 'AUTO_ALLOC' , 'VB' , 'PLW' , 'ORDER UPDATE' , a.order_no , a.ext , '' , '' , '' , a.location , '' ,
							'STATUS:A; HOLD REASON: SC'
					FROM	orders_all a (NOLOCK)
					WHERE	a.order_no = @cur_order_no
					AND		a.ext = @cur_order_ext					

				END
				ELSE
				BEGIN

					UPDATE	dbo.cvo_soft_alloc_hdr WITH (ROWLOCK)
					SET		status = -2
					WHERE	order_no = @cur_order_no
					AND		order_ext = @cur_order_ext
					AND		status = -1	

					UPDATE	dbo.cvo_soft_alloc_det WITH (ROWLOCK)
					SET		status = -2
					WHERE	order_no = @cur_order_no
					AND		order_ext = @cur_order_ext
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
					WHERE	a.order_no = @cur_order_no
					AND		a.order_ext = @cur_order_ext
					AND		ISNULL(b.order_type,'S') = 'S'
					GROUP BY a.line_no, a.part_no

					-- Create the new soft allocation records
					-- v4.7 Start
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
					WHERE	order_no = @cur_order_no
					AND		order_ext = @cur_order_ext
					AND		status = -2

					DELETE	dbo.cvo_soft_alloc_det
					WHERE	order_no = @cur_order_no
					AND		order_ext = @cur_order_ext
					AND		status = -2

					EXEC dbo.cvo_update_soft_alloc_case_adjust_sp @soft_alloc_no, @cur_order_no, @cur_order_ext
				END
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
		END
		
		SET @last_row_id = @row_id

		SELECT	TOP 1 @row_id = row_id,
				@cur_order_no = order_no,
				@cur_order_ext = order_ext
		FROM	#cvo_alloc_orders
		WHERE	row_id > @last_row_id
		ORDER BY row_id ASC
	END	

	IF EXISTS (SELECT 1 FROM #global_ship_print)
	BEGIN
		EXEC dbo.cvo_release_GST_Held_Orders_sp 1
	END

	CREATE TABLE #consolidate_picks(  
		consolidation_no	int,  
		order_no			int,  
		ext					int)  		

	IF (@st_cons_no > 0)
	BEGIN
		INSERT	#consolidate_picks
		SELECT	@st_cons_no, order_no, order_ext
		FROM	#cvo_alloc_orders

		EXEC dbo.cvo_masterpack_consolidate_pick_records_sp @st_cons_no

	END

	-- Clean Up
	DROP TABLE #global_ship_print
	DROP TABLE #cf_check
	DROP TABLE #consolidate_picks

	-- return 	
	RETURN
 
END
GO
GRANT EXECUTE ON  [dbo].[cvo_change_allocation_realloc_sp] TO [public]
GO
