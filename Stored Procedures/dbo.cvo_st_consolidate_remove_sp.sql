SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- EXEC dbo.cvo_st_consolidate_remove_sp 87

CREATE PROC [dbo].[cvo_st_consolidate_remove_sp] @consolidation_no int
AS
BEGIN
	-- DIRECTIVES
	SET NOCOUNT ON

	UPDATE	a
	SET		assign_user_id = NULL
	FROM	tdc_pick_queue a
	JOIN	cvo_masterpack_consolidation_det b (NOLOCK)
	ON		a.trans_type_no = b.order_no
	AND		a.trans_type_ext = b.order_ext
	WHERE	a.trans = 'STDPICK'
	AND		a.assign_user_id = 'HIDDEN'
	AND		b.consolidation_no = @consolidation_no

	DELETE	tdc_pick_queue
	WHERE	mp_consolidation_no = @consolidation_no

	DELETE	cvo_masterpack_consolidation_picks
	WHERE	consolidation_no = @consolidation_no

	UPDATE	a
	SET		st_consolidate = NULL
	FROM	cvo_orders_all a
	JOIN	cvo_masterpack_consolidation_det b (NOLOCK)
	ON		a.order_no = b.order_no
	AND		a.ext = b.order_ext
	WHERE	b.consolidation_no = @consolidation_no

	DELETE	cvo_masterpack_consolidation_det
	WHERE	consolidation_no = @consolidation_no

	DELETE	cvo_masterpack_consolidation_hdr
	WHERE	consolidation_no = @consolidation_no

	DELETE	cvo_st_consolidate_release
	WHERE	consolidation_no = @consolidation_no


END
GO
GRANT EXECUTE ON  [dbo].[cvo_st_consolidate_remove_sp] TO [public]
GO
