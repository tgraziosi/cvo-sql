SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- EXEC dbo.cvo_st_consolidate_remove_sp 87

CREATE PROC [dbo].[cvo_st_consolidate_remove_sp] @consolidation_no int,
											 @order_no int, -- v1.1
											 @order_ext int -- v1.1
AS
BEGIN

	-- DECLARATIONS
	DECLARE	@back_ord_flag int, -- v1.1
			@status char(1), -- v1.1
			@picked decimal(20,8), -- v1.1
			@carton_no int, -- v1.1
			@new_carton_no int -- v1.1

	-- DIRECTIVES
	SET NOCOUNT ON


	-- v1.1 Start
	SELECT	@back_ord_flag = back_ord_flag,
			@status = status
	FROM	orders_all (NOLOCK)
	WHERE	order_no = @order_no
	AND		ext = @order_ext

	IF (@back_ord_flag = 1) -- If Ship Complete
	BEGIN
		
		-- Unhide the remaining queue trans
		UPDATE	a
		SET		assign_user_id = NULL
		FROM	tdc_pick_queue a
		WHERE	a.trans = 'STDPICK'
		AND		a.assign_user_id = 'HIDDEN'
		AND		a.trans_type_no = @order_no
		AND		a.trans_type_ext = @order_ext

		-- Remove Consolidated Picks from the queue
		DELETE	a 
		FROM	tdc_pick_queue a 
		JOIN	cvo_masterpack_consolidation_picks b (NOLOCK)
		ON		a.tran_id = b.parent_tran_id
		JOIN	tdc_pick_queue c (NOLOCK)
		ON		b.child_tran_id = c.tran_id
		WHERE	b.consolidation_no = @consolidation_no
		AND		c.trans_type_no = @order_no
		AND		c.trans_type_ext = @order_ext

		-- Remove records from consolidated picks table
		DELETE	a
		FROM	cvo_masterpack_consolidation_picks a
		JOIN	tdc_pick_queue b (NOLOCK)
		ON		a.child_tran_id = b.tran_id
		WHERE	b.trans = 'STDPICK'
		AND		a.consolidation_no = @consolidation_no
		AND		b.trans_type_no = @order_no
		AND		b.trans_type_ext = @order_ext

		-- Remove order from consolidation
		UPDATE	a
		SET		st_consolidate = NULL
		FROM	cvo_orders_all a
		JOIN	cvo_masterpack_consolidation_det b (NOLOCK)
		ON		a.order_no = b.order_no
		AND		a.ext = b.order_ext
		WHERE	b.consolidation_no = @consolidation_no
		AND		a.order_no = @order_no
		AND		a.ext = @order_ext

		DELETE	cvo_masterpack_consolidation_det
		WHERE	consolidation_no = @consolidation_no
		AND		order_no = @order_no
		AND		order_ext = @order_ext

		IF (@status = 'P') -- If partially picked then move to a new carton
		BEGIN
			SET @carton_no = NULL

			SELECT	@carton_no = carton_no
			FROM	tdc_carton_tx (NOLOCK)
			WHERE	order_no = @order_no
			AND		order_ext = @order_ext

			IF (@carton_no IS NOT NULL)
			BEGIN				
				EXEC @new_carton_no = tdc_get_serialno

				UPDATE	tdc_carton_tx
				SET		carton_no = @new_carton_no
				WHERE	order_no = @order_no
				AND		order_ext = @order_ext

				UPDATE	tdc_carton_detail_tx
				SET		carton_no = @new_carton_no
				WHERE	order_no = @order_no
				AND		order_ext = @order_ext
			END
		END
	END
	ELSE
	BEGIN
		IF (@status <> 'P')
		BEGIN
			IF NOT EXISTS (SELECT 1 FROM tdc_pick_queue (NOLOCK) WHERE trans_type_no = @order_no AND trans_type_ext = @order_ext AND trans = 'STDPICK')
			BEGIN
				UPDATE	a
				SET		st_consolidate = NULL
				FROM	cvo_orders_all a
				JOIN	cvo_masterpack_consolidation_det b (NOLOCK)
				ON		a.order_no = b.order_no
				AND		a.ext = b.order_ext
				WHERE	b.consolidation_no = @consolidation_no
				AND		a.order_no = @order_no
				AND		a.ext = @order_ext

				DELETE	cvo_masterpack_consolidation_det
				WHERE	consolidation_no = @consolidation_no
				AND		order_no = @order_no
				AND		order_ext = @order_ext
			END
		END
	END
-- v1.1 End

END
GO
GRANT EXECUTE ON  [dbo].[cvo_st_consolidate_remove_sp] TO [public]
GO
