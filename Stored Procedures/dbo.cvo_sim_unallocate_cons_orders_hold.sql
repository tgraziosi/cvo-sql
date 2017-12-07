SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[cvo_sim_unallocate_cons_orders_hold] @soft_alloc_no int,
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

		IF EXISTS (SELECT 1 FROM #sim_tdc_soft_alloc_tbl (NOLOCK) WHERE order_no = @order_no AND order_ext = @order_ext AND order_type = 'S')
		BEGIN
			EXEC CVO_sim_UnAllocate_sp @order_no, @order_ext, 0, 'AUTO_ALLOC'
		END

		IF (@status = 'Q')
		BEGIN
			IF (@back_ord_flag = 1)
			BEGIN
				-- Reset the soft allocation
				UPDATE	#sim_cvo_soft_alloc_hdr
				SET		status = 0
				WHERE	soft_alloc_no = @soft_alloc_no

				UPDATE	#sim_cvo_soft_alloc_det
				SET		status = 0
				WHERE	soft_alloc_no = @soft_alloc_no

			END
			ELSE
			BEGIN
				UPDATE	#sim_cvo_soft_alloc_hdr WITH (ROWLOCK)
				SET		status = 0
				WHERE	soft_alloc_no = @soft_alloc_no

				UPDATE	#sim_cvo_soft_alloc_det WITH (ROWLOCK)
				SET		status = 0
				WHERE	soft_alloc_no = @soft_alloc_no

			END
		END
	END

	DROP TABLE #cons

END
GO
GRANT EXECUTE ON  [dbo].[cvo_sim_unallocate_cons_orders_hold] TO [public]
GO
