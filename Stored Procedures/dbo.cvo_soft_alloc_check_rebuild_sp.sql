SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- EXEC cvo_soft_alloc_check_rebuild_sp

CREATE PROC [dbo].[cvo_soft_alloc_check_rebuild_sp]
AS
BEGIN
	-- DIRECTIVES
	SET NOCOUNT ON

	-- DECLARATIONS
	DECLARE @row_id			int,
			@order_no		int,
			@order_ext		int,
			@line_no		int,
			@status			char(1),
			@hold_reason	varchar(20),
			@has_custom		int,
			@alloc_date		datetime,
			@soft_alloc_no	int,
			@location		varchar(10),
			@new_stat		int

	-- WORKING TABLES
	CREATE TABLE #liveorders (
		row_id		int IDENTITY(1,1),
		order_no	int,
		order_ext	int,
		line_no		int,
		location	varchar(10),
		status		char(1),
		hold_reason	varchar(20),
		alloc_date	datetime,
		has_custom	int,
		in_sa		int,
		in_al		int,
		new_stat	int)

	CREATE TABLE #exclusions (
		order_no		int,
		order_ext		int,
		has_line_exc	int NULL)

	CREATE TABLE #case_adjust (
		row_id			int IDENTITY(1,1),
		soft_alloc_no	int,
		order_no		int,
		order_ext		int)

	CREATE TABLE #case_raw (
		soft_alloc_no	int,
		order_no		int,
		order_ext		int)

	-- PROCESSING
	INSERT	#liveorders
	SELECT	a.order_no, 
			a.order_ext, 
			a.line_no,
			b.location,
			b.status, 
			b.hold_reason,
			c.allocation_date,
			0, 0, 0, 0
	FROM	ord_list a (NOLOCK) 
	JOIN	orders_all b (NOLOCK) 
	ON		a.order_no = b.order_no 
	AND		a.order_ext = b.ext
	JOIN	cvo_orders_all c (NOLOCK)
	ON		a.order_no = c.order_no 
	AND		a.order_ext = c.ext
	WHERE	a.status < 'R' 
	AND		a.shipped < a.ordered
	AND		a.lb_tracking = 'Y'
	AND		a.part_type = 'P'
	AND		b.type = 'I'

	UPDATE	a
	SET		has_custom = 1
	FROM	#liveorders a
	JOIN	cvo_ord_list b (NOLOCK)
	ON		a.order_no = b.order_no
	AND		a.order_ext = b.order_ext
	AND		a.line_no = b.line_no
	WHERE	b.is_customized = 'S'

	UPDATE	a
	SET		in_sa = 1
	FROM	#liveorders a
	JOIN	cvo_soft_alloc_det b (NOLOCK)
	ON		a.order_no = b.order_no
	AND		a.order_ext = b.order_ext
	AND		a.line_no = b.line_no

	UPDATE	a
	SET		in_al = 1
	FROM	#liveorders a
	JOIN	tdc_soft_alloc_tbl b (NOLOCK)
	ON		a.order_no = b.order_no
	AND		a.order_ext = b.order_ext
	AND		a.line_no = b.line_no
	WHERE	b.order_type = 'S'

	DELETE	#liveorders
	WHERE	in_sa = 1 OR in_al = 1

	SET @row_id = 0

	WHILE (1 = 1)
	BEGIN
		SELECT	TOP 1 @row_id = row_id,
				@order_no = order_no,
				@order_ext = order_ext,
				@line_no = line_no,
				@location = location,
				@status = status,
				@hold_reason = hold_reason,
				@has_custom = has_custom,
				@alloc_date	= alloc_date
		FROM	#liveorders
		WHERE	row_id > @row_id
		ORDER BY row_id

		IF (@@ROWCOUNT = 0)
			BREAK

		SET @soft_alloc_no = NULL
	
		SELECT	@soft_alloc_no = soft_alloc_no
		FROM	cvo_soft_alloc_no_assign (NOLOCK)
		WHERE	order_no = @order_no
		AND		order_ext = @order_ext

		IF (@soft_alloc_no IS NULL)
		BEGIN
			UPDATE	dbo.cvo_soft_alloc_next_no
			SET		next_no = next_no + 1

			SELECT	@soft_alloc_no = next_no
			FROM	dbo.cvo_soft_alloc_next_no
		END

		SET @new_stat = 0
		IF (@alloc_date > GETDATE())
		BEGIN
			SET @new_stat = -3
		END
		BEGIN
			IF ((@status = 'A' AND NOT EXISTS ( SELECT 1 FROM cvo_alloc_hold_values_tbl (NOLOCK) WHERE hold_code = @hold_reason))
				OR (@status = 'C'))
			BEGIN
				SET @new_stat = -3
			END
		END		

		IF (@has_custom = 1)
		BEGIN
			TRUNCATE TABLE #exclusions
			
			EXEC cvo_soft_alloc_CF_BO_check_sp @soft_alloc_no, @order_no, @order_ext

			IF EXISTS (SELECT 1 FROM #exclusions WHERE order_no = @order_no AND order_ext = @order_ext)
			BEGIN
				SET @new_stat = -4
			END
		END

		IF NOT EXISTS (SELECT 1 FROM cvo_soft_alloc_hdr (NOLOCK) WHERE order_no = @order_no AND order_ext = @order_ext)
		BEGIN
			INSERT	INTO cvo_soft_alloc_hdr (soft_alloc_no, order_no, order_ext, location, bo_hold, status)
			SELECT	@soft_alloc_no, @order_no, @order_ext, @location, 0, @new_stat
		END

		INSERT INTO	dbo.cvo_soft_alloc_det (soft_alloc_no, order_no, order_ext, line_no, location, part_no, quantity,  
							kit_part, change, deleted, is_case, is_pattern, is_pop_gift, status, add_case_flag) 
		SELECT	@soft_alloc_no, @order_no, @order_ext, @line_no, @location, a.part_no, (a.ordered - a.shipped), 
				0, 0, 0, b.is_case, b.is_pattern, b.is_pop_gif, @new_stat, b.add_case 
		FROM	ord_list a (NOLOCK)
		JOIN	cvo_ord_list b (NOLOCK)
		ON		a.order_no = b.order_no
		AND		a.order_ext = b.order_ext
		AND		a.line_no = b.line_no
		WHERE	a.order_no = @order_no
		AND		a.order_ext = @order_ext
		AND		a.line_no = @line_no

		INSERT INTO	dbo.cvo_soft_alloc_det (soft_alloc_no, order_no, order_ext, line_no, location, part_no, quantity,  
								kit_part, change, deleted, is_case, is_pattern, is_pop_gift, status)			
		SELECT	@soft_alloc_no, @order_no, @order_ext, @line_no, @location, b.part_no, a.ordered,
				1, 0, 0, 0, 0, 0, @new_stat
		FROM	ord_list a (NOLOCK)
		JOIN	cvo_ord_list_kit b (NOLOCK)
		ON		a.order_no = b.order_no
		AND		a.order_ext = b.order_ext
		AND		a.line_no = b.line_no
		WHERE	a.order_no = @order_no
		AND		a.order_ext = @order_ext	
		AND		a.line_no = @line_no
		AND		b.replaced = 'S'			


		INSERT	#case_raw (soft_alloc_no, order_no, order_ext)
		SELECT	@soft_alloc_no, @order_no, @order_ext	

	END

	INSERT	#case_adjust (soft_alloc_no, order_no, order_ext)
	SELECT	DISTINCT soft_alloc_no, order_no, order_ext
	FROM	#case_raw

	SET @row_id = 0

	WHILE (1 = 1)
	BEGIN
		SELECT	TOP 1 @row_id = row_id,
				@order_no = order_no,
				@order_ext = order_ext
		FROM	#case_adjust
		WHERE	row_id > @row_id
		ORDER BY row_id

		IF (@@ROWCOUNT = 0)
			BREAK

		EXEC dbo.cvo_update_soft_alloc_case_adjust_sp @soft_alloc_no, @order_no, @order_ext

	END

	DROP TABLE #liveorders
	DROP TABLE #case_raw
	DROP TABLE #case_adjust
	DROP TABLE #exclusions

END
GO
GRANT EXECUTE ON  [dbo].[cvo_soft_alloc_check_rebuild_sp] TO [public]
GO
