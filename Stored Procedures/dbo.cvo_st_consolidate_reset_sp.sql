SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- EXEC dbo.cvo_st_consolidate_reset_sp 87

CREATE PROC [dbo].[cvo_st_consolidate_reset_sp] @consolidation_no int,
											@voiding int = 0 -- v1.1
AS
BEGIN
	-- DIRECTIVES
	SET NOCOUNT ON

	-- DECLARATIONS
	DECLARE	@row_id			int,
			@last_row_id	int,
			@order_no		int,
			@order_ext		int,
			@status			char(1),
			@hold_reason	varchar(20),
			@prior_hold		varchar(20),
			@is_allocated	int

	-- v1.1 Start
	IF (@voiding = 1)
	BEGIN
		CREATE TABLE #consolidate_picks(  
			consolidation_no	int,  
			order_no			int,  
			ext					int)  		

		DELETE	tdc_pick_queue
		WHERE	mp_consolidation_no = @consolidation_no

		DELETE	cvo_masterpack_consolidation_picks
		WHERE	consolidation_no = @consolidation_no

		INSERT	#consolidate_picks
		SELECT	consolidation_no, order_no, order_ext
		FROM	cvo_masterpack_consolidation_det
		WHERE	consolidation_no = @consolidation_no

		EXEC dbo.cvo_masterpack_consolidate_pick_records_sp @consolidation_no	

		DROP TABLE #consolidate_picks

		RETURN	
	END
	-- v1.1 End


	-- WORKING TABLES
	CREATE TABLE #order_in_set (
		row_id				int IDENTITY(1,1),
		order_no			int,
		order_ext			int,
		ord_status			char(1),
		hold_reason			varchar(30),
		prior_hold			varchar(30) NULL)

	-- PROCESSING
	INSERT	#order_in_set (order_no, order_ext, ord_status, hold_reason, prior_hold)
	SELECT	a.order_no,
			a.ext,
			a.status,
			a.hold_reason,
			ISNULL(b.prior_hold,'')
	FROM	orders_all a (NOLOCK)
	JOIN	cvo_orders_all b (NOLOCK)
	ON		a.order_no = b.order_no
	AND		a.ext = b.ext
	JOIN	cvo_masterpack_consolidation_det c (NOLOCK)
	ON		a.order_no = c.order_no 
	AND		a.ext = c.order_ext
	WHERE	c.consolidation_no = @consolidation_no
	ORDER BY a.order_no, a.ext
	

	SET @last_row_id = 0

	SELECT	TOP 1 @row_id = row_id,
			@order_no = order_no,
			@order_ext = order_ext,
			@status = ord_status,
			@hold_reason = hold_reason,
			@prior_hold = prior_hold
	FROM	#order_in_set
	WHERE	row_id > @last_row_id
	ORDER BY row_id ASC

	WHILE (@@ROWCOUNT <> 0)
	BEGIN

		SET @is_allocated = 0

		SELECT	@is_allocated = COUNT(1)
		FROM	tdc_soft_alloc_tbl (NOLOCK)
		WHERE	order_no = @order_no
		AND		order_ext = @order_ext
		AND		order_type = 'S'

		IF (@is_allocated > 0)
		BEGIN			
			IF (@status = 'Q')
			BEGIN
				UPDATE	orders_all
				SET		printed = 'N',
						status = 'N'
				WHERE	order_no = @order_no
				AND		ext = @order_ext				
			END

			EXEC CVO_UnAllocate_sp @order_no, @order_ext, 0, 'STC Process', 1

		END

		IF (@status = 'C')
		BEGIN
			IF NOT (LEFT(@prior_hold,5) = 'PROMO') 
			BEGIN
				UPDATE	cvo_orders_all
				SET		prior_hold = 'STC'
				WHERE	order_no = @order_no
				AND		ext = @order_ext
			END
		END
		ELSE IF (@status = 'A')
		BEGIN
			-- v1.3 Start
			IF (@hold_reason > '' AND @hold_reason <> 'STC')
			BEGIN
				UPDATE	cvo_orders_all
				SET		prior_hold = 'STC'
				WHERE	order_no = @order_no
				AND		ext = @order_ext
			END
--			IF ((@hold_reason = 'H') OR (LEFT(@hold_reason,5) = 'PROMO') OR @hold_reason = 'FL') -- v1.2
--			BEGIN
--				IF NOT (LEFT(@prior_hold,5) = 'PROMO') 
--				BEGIN
--					UPDATE	cvo_orders_all
--					SET		prior_hold = 'STC'
--					WHERE	order_no = @order_no
--					AND		ext = @order_ext
--				END
--			END
--			ELSE
--			BEGIN
--				IF (@hold_reason > '' AND @hold_reason <> 'STC')
--				BEGIN		
--					UPDATE	cvo_orders_all
--					SET		prior_hold = @hold_reason
--					WHERE	order_no = @order_no
--					AND		ext = @order_ext
--			
--					UPDATE	orders_all
--					SET		hold_reason = 'STC'
--					WHERE	order_no = @order_no
--					AND		ext = @order_ext			
--				END
--			END
			-- v1.3 End
		END
		ELSE
		BEGIN
			UPDATE	orders_all
			SET		printed = 'N',
					status = 'A',
					hold_reason = 'STC'
			WHERE	order_no = @order_no
			AND		ext = @order_ext
		END

		UPDATE	orders_all
		SET		printed = 'N'
		WHERE	order_no = @order_no
		AND		ext = @order_ext

		SET @last_row_id = @row_id

		SELECT	TOP 1 @row_id = row_id,
				@order_no = order_no,
				@order_ext = order_ext,
				@status = ord_status,
				@hold_reason = hold_reason,
				@prior_hold = prior_hold
		FROM	#order_in_set
		WHERE	row_id > @last_row_id
		ORDER BY row_id ASC
	END

	UPDATE	cvo_masterpack_consolidation_hdr
	SET		closed = 0
	WHERE	consolidation_no = @consolidation_no

	UPDATE	cvo_st_consolidate_release 
	SET		released = 0, 
			release_date = NULL, 
			release_user = null 
	WHERE	consolidation_no = @consolidation_no

	DELETE	tdc_pick_queue
	WHERE	mp_consolidation_no = @consolidation_no

	-- v1.1 Start
	DELETE	cvo_masterpack_consolidation_picks
	WHERE	consolidation_no = @consolidation_no
	-- v1.1 End

END
GO
GRANT EXECUTE ON  [dbo].[cvo_st_consolidate_reset_sp] TO [public]
GO
