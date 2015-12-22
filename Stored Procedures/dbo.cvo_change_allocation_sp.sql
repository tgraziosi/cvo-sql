SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[cvo_change_allocation_sp]	@order_no	int,
											@order_ext	int
AS
BEGIN
	-- DIRECTIVES
	SET NOCOUNT ON
	SET QUOTED_IDENTIFIER OFF
	
	-- DECLARATIONS
	DECLARE	@ret					int,
			@message				varchar(255),
			@status					char(1),
			@line_no				int,
			@last_line_no			int,
			@part_no				varchar(30),
			@cons_no				int,
			@cur_order_no			int,
			@cur_order_ext			int,
			@st_cons_no				int,
			@row_id					int,
			@last_row_id			int
	
	-- INITIALIZE
	SET	@ret = 0 
	SET @message = ''
	SET @st_cons_no = -1

	-- v1.3 Start
	IF NOT EXISTS (SELECT 1 FROM orders_all (NOLOCK) WHERE order_no = @order_no AND ext = @order_ext AND status = 'N')
	BEGIN
		SELECT	@ret, ''
		RETURN	
	END

	IF NOT EXISTS (SELECT 1 FROM tdc_soft_alloc_tbl (NOLOCK) WHERE order_no = @order_no AND order_ext = @order_ext AND order_type = 'S')
	BEGIN
		SELECT	@ret, ''
		RETURN	
	END

	IF NOT EXISTS (SELECT 1 FROM cvo_soft_alloc_det (NOLOCK) WHERE order_no = @order_no AND order_ext = @order_ext AND change = 2)
	BEGIN
		SELECT	@ret, ''
		RETURN	
	END
	-- v1.3 End
	
	-- WORKING TABLE
	CREATE TABLE #cvo_unalloc_orders (
		row_id			int IDENTITY(1,1),
		order_no		int,
		order_ext		int,
		line_no			int,
		part_no			varchar(30))

	-- v1.1 Start
	CREATE TABLE #cvo_sa_orders (
		row_id			int IDENTITY(1,1),
		order_no		int,
		order_ext		int)
	-- v1.1 End

	-- PROCESSING
	IF EXISTS(SELECT 1 FROM cvo_masterpack_consolidation_det (NOLOCK) WHERE order_no = @order_no AND order_ext = @order_ext)
	BEGIN
		-- Get the consolidation number
		SELECT	@st_cons_no = consolidation_no
		FROM	cvo_masterpack_consolidation_det (NOLOCK) 
		WHERE	order_no = @order_no 
		AND		order_ext = @order_ext

		IF EXISTS (SELECT 1 FROM cvo_masterpack_consolidation_det a (NOLOCK) JOIN cvo_soft_alloc_det d (NOLOCK)
					ON a.order_no = d.order_no AND a.order_ext = d.order_ext WHERE d.change > 0 AND a.consolidation_no = @st_cons_no)
		BEGIN

			INSERT	#cvo_unalloc_orders (order_no, order_ext, line_no, part_no)
			SELECT	DISTINCT a.order_no,
					a.order_ext,
					a.line_no,
					a.part_no
			FROM	ord_list a (NOLOCK)
			JOIN	cvo_masterpack_consolidation_det b (NOLOCK)
			ON		a.order_no = b.order_no
			AND		a.order_ext = b.order_ext
			JOIN	tdc_soft_alloc_tbl c (NOLOCK)
			ON		a.order_no = c.order_no
			AND		a.order_ext = c.order_ext
			WHERE	b.consolidation_no = @st_cons_no
			AND		NOT (a.status = 'P' OR a.status >= 'R')
			AND		c.order_type = 'S'

			IF (@@ROWCOUNT = 0)
			BEGIN
				SELECT	@ret, ''
				RETURN
			END

		END	
	END
	ELSE
	BEGIN

		-- Get the status from the order
		SELECT	@status = status
		FROM	orders_all (NOLOCK)
		WHERE	order_no = @order_no
		AND		ext = @order_ext

		-- Do not do anything if picked or greater
		IF (@status = 'P' OR @status >= 'R')
		BEGIN
			SELECT	@ret, ''
			RETURN
		END

		INSERT	#cvo_unalloc_orders (order_no, order_ext, line_no, part_no)
		SELECT	DISTINCT a.order_no,
				a.order_ext,
				a.line_no,
				a.part_no
		FROM	ord_list a (NOLOCK)
		JOIN	tdc_soft_alloc_tbl c (NOLOCK)
		ON		a.order_no = c.order_no
		AND		a.order_ext = c.order_ext
		JOIN	cvo_soft_alloc_det d (NOLOCK)
		ON		a.order_no = d.order_no
		AND		a.order_ext = d.order_ext
		WHERE	a.order_no = @order_no 
		AND		a.order_ext = @order_ext
		AND		c.order_type = 'S'
		AND		d.change > 0

	END


	-- Unallocate any lines that are allocated 
	SET @last_row_id = 0

	SELECT	TOP 1 @row_id = row_id,
			@cur_order_no = order_no,
			@cur_order_ext = order_ext,
			@line_no = line_no,
			@part_no = part_no
	FROM	#cvo_unalloc_orders
	WHERE	row_id > @last_row_id
	ORDER BY row_id ASC


	WHILE @@ROWCOUNT <> 0
	BEGIN

		-- Call the unallocate line routine
		EXEC dbo.cvo_sa_plw_so_unallocate_sp @cur_order_no, @cur_order_ext, @line_no, @part_no, @message OUTPUT, @cons_no OUTPUT

		IF (@@ERROR <> 0)
		BEGIN
			SET @ret = -1
			SET @message = 'UnAllocation Allocation Failed.'
			SELECT	@ret, @message
			RETURN
		END

		IF (@message <> '')
		BEGIN
			SET @ret = -1
			SELECT	@ret, @message
			RETURN
		END

		SET @last_row_id = @row_id

		SELECT	TOP 1 @row_id = row_id,
				@cur_order_no = order_no,
				@cur_order_ext = order_ext,
				@line_no = line_no,
				@part_no = part_no
		FROM	#cvo_unalloc_orders
		WHERE	row_id > @last_row_id
		ORDER BY row_id ASC
	END	

	IF (@st_cons_no > 0)
	BEGIN
		DELETE	tdc_pick_queue
		WHERE	mp_consolidation_no = @st_cons_no

		DELETE	cvo_masterpack_consolidation_picks
		WHERE	consolidation_no = @st_cons_no
	END

	-- v1.1 Start
	INSERT	#cvo_sa_orders (order_no, order_ext)
	SELECT	DISTINCT order_no, order_ext
	FROM	#cvo_unalloc_orders

	SET @last_row_id = 0

	SELECT	TOP 1 @row_id = row_id,
			@cur_order_no = order_no,
			@cur_order_ext = order_ext
	FROM	#cvo_sa_orders
	WHERE	row_id > @last_row_id
	ORDER BY row_id ASC


	WHILE @@ROWCOUNT <> 0
	BEGIN

		DELETE	cvo_soft_alloc_hdr where order_no = @cur_order_no AND order_ext = @cur_order_ext
		DELETE	cvo_soft_alloc_det where order_no = @cur_order_no AND order_ext = @cur_order_ext

		EXEC dbo.cvo_recreate_sa_sp	@cur_order_no, @cur_order_ext

		SET @last_row_id = @row_id

		SELECT	TOP 1 @row_id = row_id,
				@cur_order_no = order_no,
				@cur_order_ext = order_ext
		FROM	#cvo_sa_orders
		WHERE	row_id > @last_row_id
		ORDER BY row_id ASC

	END
	-- v1.1 End

	-- v1.2 Start
	EXEC dbo.cvo_change_allocation_realloc_sp @order_no, @order_ext, @ret OUTPUT, @message OUTPUT
	-- v1.2 End


	-- return 
	SELECT	@ret, @message
	RETURN
 
END
GO
GRANT EXECUTE ON  [dbo].[cvo_change_allocation_sp] TO [public]
GO
