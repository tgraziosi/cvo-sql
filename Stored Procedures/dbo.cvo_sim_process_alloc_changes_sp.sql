SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[cvo_sim_process_alloc_changes_sp]	@order_no		int,
													@order_ext		int,
													@line_no		int,
													@new_quantity	decimal(20,8)
AS
BEGIN
	-- NOTE: Based on cvo_process_alloc_changes_sp v1.0 - All changes must be kept in sync 
	-- Directives
	SET NOCOUNT ON
	SET ANSI_WARNINGS OFF

	-- Declarations
	DECLARE	@alloc_qty	decimal(20,8),
			@diff		decimal(20,8),
			@row_id		int,
			@last_row	int,
			@bin_no		varchar(20),
			@qty		decimal(20,8)

	SET @alloc_qty = 0

	SELECT	@alloc_qty = SUM(qty)
	FROM	#sim_tdc_soft_alloc_tbl (NOLOCK) 
	WHERE	order_no = @order_no 
	AND		order_ext = @order_ext
	AND		line_no = @line_no 
	AND		order_type = 'S'

	IF (@alloc_qty = 0 OR @alloc_qty IS NULL) -- Not allocated - then exit
		RETURN

	IF (@alloc_qty <= @new_quantity) -- Order qty greater than alloc - then exit
		RETURN

	CREATE TABLE #AllocatedLines (
		row_id		int IDENTITY(1,1),
		bin_no		varchar(20),
		qty			decimal(20,8))

	INSERT	#AllocatedLines (bin_no, qty)
	SELECT	bin_no, qty
	FROM	#sim_tdc_soft_alloc_tbl (NOLOCK) 
	WHERE	order_no = @order_no 
	AND		order_ext = @order_ext
	AND		line_no = @line_no 
	AND		order_type = 'S'
	ORDER BY qty desc

	SET @diff = @alloc_qty - @new_quantity

	SET @last_row = 0

	SELECT	TOP 1 @row_id = row_id,
			@bin_no = bin_no,
			@qty = qty
	FROM	#AllocatedLines
	WHERE	row_id > @last_row
	ORDER BY row_id ASC
	
	WHILE (@@ROWCOUNT <> 0)
	BEGIN

		IF (@qty > @diff)
		BEGIN

			INSERT	#deleted
			SELECT	*
			FROM	#sim_tdc_soft_alloc_tbl
			WHERE	order_no = @order_no
			AND		order_ext = @order_ext
			AND		line_no = @line_no
			AND		order_type = 'S'
			AND		bin_no = @bin_no

			INSERT	#inserted
			SELECT	*
			FROM	#sim_tdc_soft_alloc_tbl
			WHERE	order_no = @order_no
			AND		order_ext = @order_ext
			AND		line_no = @line_no
			AND		order_type = 'S'
			AND		bin_no = @bin_no			

			UPDATE	#inserted
			SET		qty = qty - @diff,
					trg_off = 1
			WHERE	order_no = @order_no
			AND		order_ext = @order_ext
			AND		line_no = @line_no
			AND		order_type = 'S'
			AND		bin_no = @bin_no

			UPDATE	#sim_tdc_soft_alloc_tbl
			SET		qty = qty - @diff,
					trg_off = 1
			WHERE	order_no = @order_no
			AND		order_ext = @order_ext
			AND		line_no = @line_no
			AND		order_type = 'S'
			AND		bin_no = @bin_no

			EXEC dbo.cvo_sim_tdc_soft_alloc_tbl_trg_sp 'UPDATE','','qty'
			TRUNCATE TABLE #inserted			
			TRUNCATE TABLE #deleted		

			INSERT	#deleted
			SELECT	*
			FROM	#sim_tdc_soft_alloc_tbl
			WHERE	order_no = @order_no
			AND		order_ext = @order_ext
			AND		line_no = @line_no
			AND		order_type = 'S'
			AND		bin_no = @bin_no

			INSERT	#inserted
			SELECT	*
			FROM	#sim_tdc_soft_alloc_tbl
			WHERE	order_no = @order_no
			AND		order_ext = @order_ext
			AND		line_no = @line_no
			AND		order_type = 'S'
			AND		bin_no = @bin_no

			UPDATE	#inserted
			SET		trg_off = 0
			WHERE	order_no = @order_no
			AND		order_ext = @order_ext
			AND		line_no = @line_no
			AND		order_type = 'S'
			AND		bin_no = @bin_no

			UPDATE	#sim_tdc_soft_alloc_tbl
			SET		trg_off = 0
			WHERE	order_no = @order_no
			AND		order_ext = @order_ext
			AND		line_no = @line_no
			AND		order_type = 'S'
			AND		bin_no = @bin_no

			EXEC dbo.cvo_sim_tdc_soft_alloc_tbl_trg_sp 'UPDATE','',''
			TRUNCATE TABLE #inserted			
			TRUNCATE TABLE #deleted	

			UPDATE	#sim_tdc_pick_queue
			SET		qty_to_process = qty_to_process - @diff
			WHERE	trans_type_no = @order_no
			AND		trans_type_ext = @order_ext
			AND		line_no = @line_no
			AND		trans_source = 'PLW'
			AND		trans = 'STDPICK'
			AND		bin_no = @bin_no			

			DROP TABLE #AllocatedLines

			RETURN
		END

		IF (@qty <= @diff)
		BEGIN
			DELETE	#sim_tdc_soft_alloc_tbl
			WHERE	order_no = @order_no
			AND		order_ext = @order_ext
			AND		line_no = @line_no
			AND		order_type = 'S'
			AND		bin_no = @bin_no

			SET @diff = @diff - @qty
		END

		IF (@diff = 0)
		BEGIN
			DROP TABLE #AllocatedLines
			RETURN
		END

		SET @last_row = @row_id

		SELECT	TOP 1 @row_id = row_id,
				@bin_no = bin_no,
				@qty = qty
		FROM	#AllocatedLines
		WHERE	row_id > @last_row
		ORDER BY row_id ASC
	END

	DROP TABLE #AllocatedLines

END
GO
GRANT EXECUTE ON  [dbo].[cvo_sim_process_alloc_changes_sp] TO [public]
GO
