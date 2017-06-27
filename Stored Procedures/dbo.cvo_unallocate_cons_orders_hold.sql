SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[cvo_unallocate_cons_orders_hold] @soft_alloc_no int,
												@p_order_no int,
												@p_order_ext int,
												@back_ord_flag int
AS
BEGIN
	-- DIRECTIVES
	SET NOCOUNT ON

	-- DECLARTIONS
	DECLARE	@cons_no		int,
			@order_no		int,
			@order_ext		int,
			@row_id			int,
			@status			char(1),
			@hold_reason	varchar(10),
			@hold_priority	int
					
	-- PROCESSING
	SELECT	@cons_no = consolidation_no
	FROM	cvo_masterpack_consolidation_det (NOLOCK)
	WHERE	order_no = @p_order_no
	AND		order_ext = @p_order_ext

	IF (@@ROWCOUNT = 0)
		RETURN

	CREATE TABLE #cons (
		row_id			int IDENTITY(1,1),
		order_no		int,
		order_ext		int, 
		status			char(1),
		hold_reason		varchar(10))

	INSERT	#cons (order_no, order_ext, status, hold_reason)
	SELECT	a.order_no, a.ext, a.status, a.hold_reason
	FROM	orders_all a (NOLOCK)
	JOIN	cvo_masterpack_consolidation_det b (NOLOCK) 
	ON		a.order_no = b.order_no
	AND		a.ext = b.order_ext
	WHERE	consolidation_no = @cons_no

	DELETE	#cons
	WHERE	order_no = @p_order_no
	AND		order_Ext = @p_order_ext

	IF NOT EXISTS (SELECT 1 FROM #cons)
	BEGIN
		DROP TABLE #cons
		RETURN
	END

	SET @row_id = 0

	WHILE (1 = 1)
	BEGIN

		SELECT	@row_id = row_id,
				@order_no = order_no,
				@order_ext = order_ext,
				@status = status,
				@hold_reason = hold_reason
		FROM	#cons
		WHERE	row_id > @row_id
		ORDER BY row_id ASC

		IF (@@ROWCOUNT = 0)
			BREAK

		IF EXISTS (SELECT 1 FROM tdc_soft_alloc_tbl (NOLOCK) WHERE order_no = @order_no AND order_ext = @order_ext AND order_type = 'S')
		BEGIN
			EXEC CVO_UnAllocate_sp @order_no, @order_ext, 0, 'AUTO_ALLOC'
		END

		IF (@status = 'Q')
		BEGIN
			IF (@back_ord_flag = 1)
			BEGIN
				UPDATE	orders_all WITH (ROWLOCK)
				SET		status = 'N',
						hold_reason = ''
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
				SELECT	GETDATE() , 'AUTO_ALLOC' , 'VB' , 'PLW' , 'ORDER UPDATE' , a.order_no , a.ext , '' , '' , '' , a.location , '' ,
						'STATUS:N; ORDER RESET DUE TO SHIP COMPLETE CONSOLIDATION'
				FROM	orders_all a (NOLOCK)
				WHERE	a.order_no = @order_no
				AND		a.ext = @order_ext								
			END
			ELSE
			BEGIN

				UPDATE	orders_all
				SET		status = 'N',
						hold_reason = ''
				WHERE	order_no = @order_no
				AND		ext = @order_ext

				UPDATE	cvo_soft_alloc_hdr WITH (ROWLOCK)
				SET		status = 0
				WHERE	soft_alloc_no = @soft_alloc_no

				UPDATE	cvo_soft_alloc_det WITH (ROWLOCK)
				SET		status = 0
				WHERE	soft_alloc_no = @soft_alloc_no

				INSERT INTO tdc_log WITH (ROWLOCK) ( tran_date , userid , trans_source , module , trans , tran_no , tran_ext , part_no , lot_ser , bin_no , location , quantity , data ) 
				SELECT	GETDATE() , 'ALLOC CHECK' , 'VB' , 'PLW' , 'ORDER UPDATE' , a.order_no , a.ext , '' , '' , '' , a.location , '' ,
						'STATUS:N; ORDER RESET DUE TO FILL LEVEL CONSOLIDATION'
				FROM	orders_all a (NOLOCK)
				WHERE	a.order_no = @order_no
				AND		a.ext = @order_ext

			END
		END
	END

	DROP TABLE #cons

END
GO
GRANT EXECUTE ON  [dbo].[cvo_unallocate_cons_orders_hold] TO [public]
GO
