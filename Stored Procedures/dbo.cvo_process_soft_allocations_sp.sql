SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[cvo_process_soft_allocations_sp]
AS
BEGIN
	-- Directives
	SET NOCOUNT ON
	SET ANSI_WARNINGS OFF

	-- Declarations
	DECLARE	@row_id			int,
			@last_row_id	int,
			@soft_alloc_no	int,
			@order_no		int,
			@order_ext		int,
			@location		varchar(10),
			@change			int,
			@has_kit		int,
			@has_change		int,
			@has_delete		int,
			@line_row		int,
			@last_line_row	int,
			@line_no		int,
			@part_no		varchar(30),
			@quantity		decimal(20,8),
			@error_messages	varchar(500),
			@cons_no		int,
			@rc				int,
			@curr_alloc_pct	decimal(20,8),
			@curr_ordered	decimal(20,8), -- v3.0
			@curr_alloc		decimal(20,8), -- v3.0
			@new_soft_alloc	int, -- v1.3
			@back_ord_flag	int, -- v1.3
			@hold_code		varchar(10), -- v2.9
			@hold_reason	varchar(40), -- v2.9
			@start_date		varchar(19), -- v4.3
			@notifications	SMALLINT,	-- v4.4
			@ns_line_no		int,		-- v4.6
			@rec_id			SMALLINT,	-- v5.4
			@stcons_no		int, -- v5.9
			@last_stcons_no int, -- v5.9
			@prior_hold		varchar(10) -- v7.3

	-- v6.3 Start
	DECLARE	@cur_con_no		int,
			@cur_con_count	int,
			@cur_con_count2	int,
			@cur_con_count3	int -- v7.0
	-- v6.3 End

	SET @start_date = CONVERT(varchar(19),GETDATE(),121) -- v4.3

	-- v4.2 Start
	DELETE	a
	FROM	cvo_soft_alloc_hdr a
	JOIN	orders_all b (NOLOCK)
	ON		a.order_no = b.order_no
	AND		a.order_ext = b.ext
	WHERE	b.status = 'V'

	DELETE	a
	FROM	cvo_soft_alloc_det a
	JOIN	orders_all b (NOLOCK)
	ON		a.order_no = b.order_no
	AND		a.order_ext = b.ext
	WHERE	b.status = 'V'
	-- v4.2 End

	-- v4.9 Start
	DELETE	dbo.cvo_process_soft_allocations_audit WHERE error_messages = 'ALLOCATING' -- Unlock all records
	-- v4.9 End

	-- START v3.9
	CREATE TABLE #snapshot (
		soft_alloc_no	int,
		order_no		int,
		order_ext		int)

	INSERT	#snapshot (soft_alloc_no, order_no, order_ext)
	SELECT	soft_alloc_no, order_no, order_ext
	FROM	dbo.cvo_soft_alloc_hdr (NOLOCK)
	WHERE	[status] IN (0,-3) --include future allocations which may be changed to 0 in this run
--	AND		order_no = 2840031 --CRAIG
	-- END v3.9

	-- v2.5 Start
	-- Any soft alloc record over 4 hrs that have not been completed will be removed
	DELETE	a
	FROM	cvo_soft_alloc_det a
	JOIN	cvo_soft_alloc_ctl b (NOLOCK)
	ON		a.soft_alloc_no = b.soft_alloc_no
	WHERE	a.order_no = 0
	AND		DATEDIFF(hh, b.date_entered, getdate()) > 4

	DELETE	a
	FROM	cvo_soft_alloc_hdr a
	JOIN	cvo_soft_alloc_ctl b (NOLOCK)
	ON		a.soft_alloc_no = b.soft_alloc_no
	WHERE	a.order_no = 0
	AND		DATEDIFF(hh, b.date_entered, getdate()) > 4

	-- v2.5 End

	-- Create working table
	CREATE TABLE #process_alloc (
		row_id			int IDENTITY(1,1),
		soft_alloc_no	int,
		order_no		int,
		order_ext		int,
		location		varchar(10),
		has_change		int,
		has_kit			int,
		has_delete		int)

	-- Create table for exclusions - v1.1
	CREATE TABLE #exclusions (
		order_no		int,
		order_ext		int,
		has_line_exc	int NULL) -- v2.0

	-- v2.0 Start
	CREATE TABLE #line_exclusions (
		order_no		int,
		order_ext		int,
		line_no			int)
	-- v2.0 End

	-- v2.9 Start
	CREATE TABLE #no_stock_orders (
		order_no		int,
		order_ext		int,
		line_no			int,
		no_stock		int)	
	-- v2.9 End

	-- v5.9 Start
	CREATE TABLE #orders_to_consolidate(  
		consolidation_no	int,  
		order_no			int,  
		ext					int)  		

	-- v7.2 Start
--	CREATE TABLE #consolidate_picks(  
--		consolidation_no	int,  
--		order_no			int,  
--		ext					int)  		
	-- v7.2 End
	-- v5.9 End

	-- v6.0 Start
	CREATE TABLE #global_ship_print (
		order_no		int,
		order_ext		int,
		global_ship		varchar(10))
	-- v6.0 End

	-- v6.1 Start
	CREATE TABLE #forced_orders (
		order_no		int,
		order_ext		int,
		status			char(1),
		hold_reason		varchar(10))
	-- v6.1 End

	-- v6.5 Start
	CREATE TABLE #future_orders (
		order_no		int,
		order_ext		int,
		status			char(1),
		hold_reason		varchar(10),
		alloc_status	int)
	-- v6.5 End

	-- v1.1 Insert the exclusions
	-- v1.2 And customer type is customer
	-- 1. ST Orders on Credit Hold
	INSERT	#exclusions (order_no, order_ext)
	SELECT	a.order_no,
			a.ext
	FROM	orders_all a (NOLOCK)
	JOIN	arcust b (NOLOCK)
	ON		a.cust_code = b.customer_code
	WHERE	LEFT(a.user_category,2) = 'ST'
	AND		a.status = 'C'	
	AND		b.address_type = 0
	AND		UPPER(b.addr_sort1) = 'CUSTOMER'
	
	-- 2. ST Orders on Hard hold for accounting
	INSERT	#exclusions (order_no, order_ext)
	SELECT	a.order_no,
			a.ext
	FROM	orders_all a (NOLOCK)
	JOIN	arcust b (NOLOCK)
	ON		a.cust_code = b.customer_code
	WHERE	LEFT(a.user_category,2) = 'ST'
	AND		a.status = 'A'	
	AND		a.hold_reason = 'H'
	AND		b.address_type = 0
	AND		UPPER(b.addr_sort1) = 'CUSTOMER'

	-- 3. Orders with 'NA' hold
	INSERT	#exclusions (order_no, order_ext)
	SELECT	order_no,
			ext
	FROM	orders_all (NOLOCK)
	WHERE	status = 'A'
	AND		hold_reason = 'H'

	INSERT	#exclusions (order_no, order_ext)
	SELECT	order_no,
			ext
	FROM	cvo_orders_all (NOLOCK)
	WHERE	ISNULL(prior_hold,'') = 'NA'

	-- 4. -- v2.1 & v2.2
	INSERT	#exclusions (order_no, order_ext)
	SELECT	a.order_no,
			a.ext
	FROM	orders_all a (NOLOCK)
	JOIN	arcust b (NOLOCK)
	ON		a.cust_code = b.customer_code
	WHERE	LEFT(a.user_category,2) = 'ST'
	AND		a.status = 'A'	
	AND		b.address_type = 0
	AND		UPPER(b.addr_sort1) = 'CUSTOMER'	
	AND		a.hold_reason IN (SELECT hold_code FROM cvo_hold_reason_no_autoalloc (NOLOCK))


	-- v5.9 Start
	INSERT	#exclusions (order_no, order_ext)
	SELECT	b.order_no,
			b.order_ext
	FROM	cvo_masterpack_consolidation_hdr a (NOLOCK)
	JOIN	cvo_masterpack_consolidation_det b (NOLOCK)
	ON		a.consolidation_no = b.consolidation_no
	JOIN	cvo_st_consolidate_release c (NOLOCK)
	ON		a.consolidation_no = c.consolidation_no
	WHERE	a.type = 'OE'
	AND		a.closed = 0
	AND		a.shipped = 0
	AND		c.released = 0
	-- v5.9 End

	-- 5. Custom Frame Breaks with missing stock
	EXEC	cvo_soft_alloc_CF_check_sp -- v1.6

	-- v3.7 Start
	-- Mark custom frames with exclusions
	UPDATE	a
	SET		status = -4
	FROM	cvo_soft_alloc_hdr a WITH (ROWLOCK)
	JOIN	#exclusions b
	ON		a.order_no = b.order_no
	AND		a.order_ext = b.order_ext
	JOIN	cvo_ord_list c (NOLOCK)
	ON		a.order_no = c.order_no
	AND		a.order_ext = c.order_ext
	WHERE	c.is_customized = 'S'

	UPDATE	a
	SET		status = -4
	FROM	cvo_soft_alloc_det a WITH (ROWLOCK)
	JOIN	cvo_soft_alloc_hdr b (NOLOCK)
	ON		a.soft_alloc_no = b.soft_alloc_no
	WHERE	b.status = -4

	-- v3.7 End

	-- v5.3 Start -3 flag also utilized for non soft alloc of hold orders
	CREATE TABLE #no_soft_alloc_orders (
		order_no	int,
		order_ext	int)

	INSERT	#no_soft_alloc_orders (order_no, order_ext)
	SELECT	a.order_no,
			a.ext
	FROM	orders_all a (NOLOCK)
	LEFT JOIN cvo_alloc_hold_values_tbl b (NOLOCK)
	ON		a.hold_reason = b.hold_code
	WHERE	(b.hold_code IS NULL
	AND		a.status = 'A')
	OR		a.status = 'C'


	INSERT	#exclusions (order_no, order_ext)
	SELECT	a.order_no,
			a.ext
	FROM	orders_all a (NOLOCK)
	JOIN	cvo_alloc_hold_values_tbl b (NOLOCK)
	ON		a.hold_reason = b.hold_code
	WHERE	(a.status = 'A'
	OR		a.status = 'C')
	-- v5.3 End

	-- v6.7 Start
	INSERT	#exclusions (order_no, order_ext)
	SELECT	a.order_no,
			a.ext
	FROM	cvo_orders_all a (NOLOCK)
	LEFT JOIN cvo_alloc_hold_values_tbl b (NOLOCK)
	ON		a.prior_hold = b.hold_code
	WHERE	b.hold_code IS NULL
	AND		ISNULL(a.prior_hold,'') > ''
	-- v6.7 End

	-- Future Allocations - Update the status on the soft allocations where the future allocation is now due
	UPDATE	a
	SET		status = 0
	FROM	dbo.cvo_soft_alloc_hdr a WITH (ROWLOCK)
	JOIN	cvo_orders_all b (NOLOCK)
	ON		a.order_no = b.order_no
	AND		a.order_ext = b.ext
-- v5.5	LEFT JOIN #exclusions c
-- v5.5	ON		b.order_no = c.order_no
-- v5.5	AND		b.ext = c.order_ext
	LEFT JOIN #no_soft_alloc_orders d -- v5.3
	ON		a.order_no = d.order_no -- v5.3
	AND		a.order_ext = d.order_ext -- v5.3
	WHERE	b.allocation_date <= getdate()
	AND		a.status = -3
-- v5.5	AND		c.order_no IS NULL
-- v5.5	AND		c.order_ext IS NULL
	AND		d.order_no IS NULL -- v5.3
	AND		d.order_ext IS NULL -- v5.3

	UPDATE	a
	SET		status = 0
	FROM	dbo.cvo_soft_alloc_det a WITH (ROWLOCK)
	JOIN	cvo_orders_all b (NOLOCK)
	ON		a.order_no = b.order_no
	AND		a.order_ext = b.ext
-- v5.5	LEFT JOIN #exclusions c
-- v5.5	ON		b.order_no = c.order_no
-- v5.5	AND		b.ext = c.order_ext
	LEFT JOIN #no_soft_alloc_orders d -- v5.3
	ON		a.order_no = d.order_no -- v5.3
	AND		a.order_ext = d.order_ext -- v5.3
	WHERE	b.allocation_date <= getdate()
	AND		a.status = -3
-- v5.5	AND		c.order_no IS NULL
-- v5.5	AND		c.order_ext IS NULL
	AND		d.order_no IS NULL -- v5.3
	AND		d.order_ext IS NULL -- v5.3

	-- v6.5 Start
	INSERT	#future_orders (order_no, order_ext, status, hold_reason, alloc_status)
	SELECT	DISTINCT a.order_no,
			a.ext,
			a.status,
			a.hold_reason,
			d.status
	FROM	orders_all a (NOLOCK)
	JOIN	cvo_orders_all b (NOLOCK)
	ON		a.order_no = b.order_no
	AND		a.ext = b.ext
	JOIN	cvo_soft_alloc_det d (NOLOCK)
	ON		a.order_no = d.order_no
	AND		a.ext = d.order_ext
	WHERE	(b.allocation_date > getdate() 
		OR	CONVERT(varchar(10),ISNULL(a.sch_ship_date,GETDATE()),121) > CONVERT(varchar(10),GETDATE(),121))
	AND		d.status = -3
	AND		d.change <> 0
	-- v6.5 End

	-- START v1.9
	-- 5. Exclude Orders which haven't reached their delivery date
	INSERT	#exclusions (order_no, order_ext)
	SELECT	
			a.order_no,
			a.ext
	FROM	
		dbo.orders_all  a (NOLOCK)
	INNER JOIN
		dbo.cvo_soft_alloc_hdr b (NOLOCK)
	ON
		a.order_no = b.order_no
		AND a.ext = b.order_ext
	WHERE
		b.status = 0
		AND CONVERT(varchar(10),ISNULL(a.sch_ship_date,GETDATE()),121) > CONVERT(varchar(10),GETDATE(),121) -- v4.1
	-- END v1.9

	-- v3.3 Start
	-- If a split order is marked as do not allocate
	INSERT	#exclusions (order_no, order_ext)
	SELECT	
			a.order_no,
			a.ext
	FROM	
		dbo.cvo_orders_all  a (NOLOCK)
	INNER JOIN
		dbo.cvo_soft_alloc_hdr b (NOLOCK)
	ON
		a.order_no = b.order_no
	AND a.ext = b.order_ext
	WHERE	
		b.status = 0
	AND	
		a.split_order = 'A'
	-- v3.3 End

	-- v4.5 Start
	-- If the order is picked then exclude from allocation
	INSERT	#exclusions (order_no, order_ext)
	SELECT	a.order_no,
			a.ext
	FROM	orders_all a (NOLOCK)
	JOIN	dbo.cvo_soft_alloc_hdr b (NOLOCK)
	ON		a.order_no = b.order_no
	AND		a.ext = b.order_ext	
	WHERE	a.status = 'P'
	AND		b.status = 0
	-- v4.5 End

	-- v5.0 Start
	-- Remove soft allocation record for order lines that now do not exist and are not allocated
	DELETE	a
	FROM	cvo_soft_alloc_det a
	JOIN	#snapshot b
	ON		a.order_no = b.order_no
	AND		a.order_ext = b.order_ext
	LEFT JOIN ord_list c (NOLOCK)
	ON		a.order_no = c.order_no
	AND		a.order_ext = c.order_ext
	AND		a.line_no = c.line_no
	LEFT JOIN tdc_soft_alloc_tbl d (NOLOCK)
	ON		a.order_no = d.order_no
	AND		a.order_ext = d.order_ext
	AND		a.line_no = d.line_no
	WHERE	c.order_no IS NULL 
	AND		c.order_ext IS NULL 
	AND		c.line_no IS NULL
	AND		d.order_no IS NULL 
	AND		d.order_ext IS NULL 
	AND		d.line_no is null
	AND		a.status <> 1

	DELETE	a
	FROM	cvo_soft_alloc_hdr a
	JOIN	#snapshot b
	ON		a.order_no = b.order_no
	AND		a.order_ext = b.order_ext
	LEFT JOIN cvo_soft_alloc_det c (NOLOCK)
	ON		a.order_no = c.order_no
	AND		a.order_ext = c.order_ext
	WHERE	a.status <> 1
	AND		c.order_no IS NULL
	AND		c.order_ext IS NULL

	-- v5.0 End

	-- v3.8
	EXEC cvo_check_stock_pre_allocation_sp


	-- v5.1 Start
	DELETE	a
	FROM	#exclusions a
	JOIN	cvo_soft_alloc_det b (NOLOCK)
	ON		a.order_no = b.order_no
	AND		a.order_ext = b.order_ext
	WHERE	b.deleted = 1
	-- v5.1 End

	-- v6.1 Start
	INSERT	#forced_orders (order_no, order_ext, status, hold_reason)
	SELECT	DISTINCT o.order_no, o.ext, o.status, o.hold_reason
	FROM	orders_all o (NOLOCK)
	JOIN	cvo_soft_alloc_det a (NOLOCK)
	ON		o.order_no = a.order_no
	AND		o.ext = a.order_ext
	JOIN	tdc_soft_alloc_tbl b (NOLOCK)
	ON		a.order_no = b.order_no
	AND		a.order_ext = b.order_ext
	AND		a.line_no = b.line_no
	JOIN	#exclusions c
	ON		a.order_no = c.order_no
	AND		a.order_ext = c.order_ext
	WHERE	o.status < 'Q'
	AND		a.change > 0

	DELETE	a
	FROM	#exclusions a
	JOIN	#forced_orders b
	ON		a.order_no = b.order_no
	AND		a.order_ext = b.order_ext
	-- v6.1 End

	-- v6.5 Start
	DELETE	a
	FROM	#exclusions a
	JOIN	#future_orders b
	ON		a.order_no = b.order_no
	AND		a.order_ext = b.order_ext

	UPDATE	a
	SET		status = 0
	FROM	cvo_soft_alloc_hdr a
	JOIN	#future_orders b
	ON		a.order_no = b.order_no
	AND		a.order_ext = b.order_ext

	UPDATE	a
	SET		status = 0
	FROM	cvo_soft_alloc_det a
	JOIN	#future_orders b
	ON		a.order_no = b.order_no
	AND		a.order_ext = b.order_ext
	-- v6.5 End


	-- Mark soft_allocations to process
	BEGIN TRAN -- Use transaction to lock the table
		UPDATE	a
		SET		status = -1
		FROM	dbo.cvo_soft_alloc_hdr a WITH (ROWLOCK)
		JOIN	dbo.cvo_soft_alloc_det b (NOLOCK)
		ON		a.soft_alloc_no = b.soft_alloc_no
		LEFT JOIN #exclusions c
		ON		a.order_no = c.order_no
		AND		a.order_ext = c.order_ext
		-- START v3.9
		INNER JOIN #snapshot d
		ON		a.order_no = d.order_no
		AND		a.order_ext = d.order_ext
		-- END v3.9		
		-- v4.3 Start
		INNER JOIN orders_all o (NOLOCK)
		ON		a.order_no = o.order_no
		AND		a.order_ext = o.ext
		-- v4.3 End
		WHERE	a.status = 0
		AND		b.status = 0
		AND		a.bo_hold = 0
		AND		c.order_no IS NULL
		AND		c.order_ext IS NULL
		-- v4.3 Start
		AND		(@start_date > CASE WHEN o.user_def_fld3 = '' THEN CONVERT(varchar(19),CONVERT(datetime,LEFT(date_entered,19)),121)
										ELSE CONVERT(varchar(19),CONVERT(datetime,LEFT(o.user_def_fld3,19)),121) END)
--AND		a.order_no = 2840031 --CRAIG
		-- v4.3 End

	COMMIT TRAN


	-- Mark the detail records
	UPDATE	a
	SET		status = -1
	FROM	dbo.cvo_soft_alloc_det a WITH (ROWLOCK)
	JOIN	dbo.cvo_soft_alloc_hdr b (NOLOCK)
	ON		a.soft_alloc_no = b.soft_alloc_no
	WHERE	a.status = 0
	AND		b.status = -1

	-- v4.9 Start
	-- Validate the details
	/*
	CREATE TABLE #validate_lines (
		soft_alloc_no	int,
		lines			int,
		marked_lines	int)

	INSERT	#validate_lines
	SELECT	a.soft_alloc_no,
			COUNT(a.line_no), 0
	FROM	dbo.cvo_soft_alloc_det a (NOLOCK)
	JOIN	dbo.cvo_soft_alloc_hdr b (NOLOCK)
	ON		a.soft_alloc_no = b.soft_alloc_no
	WHERE	b.status = -1
	GROUP BY a.soft_alloc_no

	UPDATE	a
	SET		marked_lines = (SELECT COUNT(b.line_no) FROM dbo.cvo_soft_alloc_det b (NOLOCK) WHERE b.soft_alloc_no = a.soft_alloc_no AND status = -1)
	FROM	#validate_lines a
	
	-- if an records exist where the details line count is not equal to the marked records then release them
	UPDATE	a
	SET		status = 0
	FROM	dbo.cvo_soft_alloc_det a
	JOIN	#validate_lines b
	ON		a.soft_alloc_no = b.soft_alloc_no
	WHERE	b.lines <> b.marked_lines

	BEGIN TRAN
		UPDATE	a
		SET		status = 0
		FROM	dbo.cvo_soft_alloc_hdr a
		JOIN	#validate_lines b
		ON		a.soft_alloc_no = b.soft_alloc_no
		WHERE	b.lines <> b.marked_lines
	COMMIT TRAN

	DROP TABLE #validate_lines
	*/
	-- v4.9 End

	-- Are there any records to process
	IF NOT EXISTS (SELECT 1 FROM dbo.cvo_soft_alloc_hdr (NOLOCK) WHERE status = -1)
		RETURN 0

	-- Populate the working table with the soft allocation to process
	INSERT	#process_alloc (soft_alloc_no, order_no, order_ext, location)
	SELECT	DISTINCT soft_alloc_no, order_no, order_ext, location
	FROM	dbo.cvo_soft_alloc_hdr (NOLOCK)
	WHERE	status = -1
	ORDER BY soft_alloc_no ASC

	-- Mark which records are changes or custom frames
	UPDATE	a
	-- START v3.2
	SET		has_change = (SELECT MAX(CASE change WHEN 2 THEN 1 ELSE change END) FROM dbo.cvo_soft_alloc_det b (NOLOCK) WHERE b.soft_alloc_no = a.soft_alloc_no),
	-- SET	has_change = (SELECT MAX(change) FROM dbo.cvo_soft_alloc_det b (NOLOCK) WHERE b.soft_alloc_no = a.soft_alloc_no),
	-- ENE v3.2
			has_kit = (SELECT MAX(kit_part) FROM dbo.cvo_soft_alloc_det b (NOLOCK) WHERE b.soft_alloc_no = a.soft_alloc_no),
			has_delete = (SELECT MAX(deleted) FROM dbo.cvo_soft_alloc_det b (NOLOCK) WHERE b.soft_alloc_no = a.soft_alloc_no)
	FROM	#process_alloc a


	SET	@last_row_id = 0

	SELECT	TOP 1 @row_id = row_id,
			@soft_alloc_no = soft_alloc_no,
			@order_no = order_no,
			@order_ext = order_ext,
			@location = location,
			@has_kit = has_kit,
			@has_change = has_change, 
			@has_delete = has_delete	
	FROM	#process_alloc
	WHERE	row_id > @last_row_id
	ORDER BY row_id ASC

	WHILE @@ROWCOUNT <> 0
	BEGIN

		SET @error_messages = ''

		-- v6.2 Start
		-- If being processed
		IF EXISTS (SELECT 1 FROM tdc_plw_orders_being_allocated (NOLOCK) WHERE order_no = @order_no AND order_ext = @order_ext)
		BEGIN
			-- v7.1 Start
			UPDATE	dbo.cvo_soft_alloc_hdr WITH (ROWLOCK)
			SET		status = 0
			WHERE	soft_alloc_no = @soft_alloc_no
			AND		status = -1	

			UPDATE	dbo.cvo_soft_alloc_det WITH (ROWLOCK)
			SET		status = 0
			WHERE	soft_alloc_no = @soft_alloc_no
			AND		status = -1	
			-- v7.1 End

			SET	@last_row_id = @row_id

			SELECT	TOP 1 @row_id = row_id,
					@soft_alloc_no = soft_alloc_no,
					@order_no = order_no,
					@order_ext = order_ext,
					@location = location,
					@has_kit = has_kit,
					@has_change = has_change, 
					@has_delete = has_delete	
			FROM	#process_alloc
			WHERE	row_id > @last_row_id
			ORDER BY row_id ASC

			CONTINUE
		END
		-- v6.2 End

		-- Before calling the allocation routine we need to deal with any changes or deletes
		IF NOT (@has_change = 0 AND @has_delete = 0)
		BEGIN		
			SET @last_line_row = 0

			SELECT	TOP 1 @line_row = row_id,
					@line_no = line_no,
					@part_no = part_no,
					@quantity = quantity
			FROM	dbo.cvo_soft_alloc_det (NOLOCK)
			WHERE	soft_alloc_no = @soft_alloc_no
			-- START v3.2
			AND		(change >= 1 OR deleted = 1)
			-- AND	(change = 1 OR deleted = 1)
			-- END v3.2
			AND		kit_part = 0
			AND		status = -1
			AND		row_id > @last_line_row
			ORDER BY row_id ASC

			WHILE @@ROWCOUNT <> 0
			BEGIN

				-- v6.4 Start
				IF EXISTS(SELECT 1 FROM #forced_orders WHERE order_no = @order_no AND order_ext = @order_ext)
				BEGIN
					IF (@has_delete = 1)
					BEGIN
						SET @error_messages = ''				
						EXEC dbo.cvo_sa_plw_so_unallocate_sp @order_no, @order_ext, @line_no, @part_no, @error_messages OUTPUT, @cons_no OUTPUT	
					END
					ELSE
					BEGIN
						EXEC dbo.cvo_process_alloc_changes_sp @order_no, @order_ext, @line_no, @quantity
					END
				END
				ELSE
				BEGIN
					SET @error_messages = ''				
					EXEC dbo.cvo_sa_plw_so_unallocate_sp @order_no, @order_ext, @line_no, @part_no, @error_messages OUTPUT, @cons_no OUTPUT
				END
				-- v6.4 End

				-- Check for errors
				IF (@error_messages != '')
				BEGIN
					INSERT	dbo.cvo_process_soft_allocations_audit (allocation_date, cons_no, order_no, order_ext, perc_allocated, error_messages)
					SELECT	GETDATE(), @cons_no, @order_no, @order_ext, 0, @error_messages
					BREAK
				END

				SET @last_line_row = @line_row

				SELECT	TOP 1 @line_row = row_id,
						@line_no = line_no,
						@part_no = part_no,
						@quantity = quantity
				FROM	dbo.cvo_soft_alloc_det (NOLOCK)
				WHERE	soft_alloc_no = @soft_alloc_no
				-- START v3.2
				AND		(change >= 1 OR deleted = 1)
				-- AND	(change = 1 OR deleted = 1)
				-- END v3.2
				AND		kit_part = 0
				AND		status = -1
				AND		row_id > @last_line_row
				ORDER BY row_id ASC
			END
		END

		-- If an error occured then update the status of the allocation and move to the next record
		IF (@error_messages != '')
		BEGIN
			UPDATE	dbo.cvo_soft_alloc_hdr WITH (ROWLOCK)
			SET		status = 0
			WHERE	soft_alloc_no = @soft_alloc_no
			AND		status = -1	

			UPDATE	dbo.cvo_soft_alloc_det WITH (ROWLOCK)
			SET		status = 0
			WHERE	soft_alloc_no = @soft_alloc_no
			AND		status = -1	
	
			SET @error_messages = ''

			SET	@last_row_id = @row_id

			SELECT	TOP 1 @row_id = row_id,
					@soft_alloc_no = soft_alloc_no,
					@order_no = order_no,
					@order_ext = order_ext,
					@location = location,
					@has_kit = has_kit,
					@has_change = has_change, 
					@has_delete = has_delete	
			FROM	#process_alloc
			WHERE	row_id > @last_row_id
			ORDER BY row_id ASC

			CONTINUE
		END


		DELETE #no_stock_orders -- v2.9

		-- The changes and deletes have been dealt with so now call the main allocation routine
		-- v4.9 Start
		IF NOT EXISTS (SELECT 1 FROM cvo_soft_alloc_hdr (NOLOCK) WHERE soft_alloc_no = @soft_alloc_no AND status = -1)
		BEGIN
			-- Move onto the next order
			SET	@last_row_id = @row_id

			SELECT	TOP 1 @row_id = row_id,
					@soft_alloc_no = soft_alloc_no,
					@order_no = order_no,
					@order_ext = order_ext,
					@location = location,
					@has_kit = has_kit,
					@has_change = has_change, 
					@has_delete = has_delete	
			FROM	#process_alloc
			WHERE	row_id > @last_row_id
			ORDER BY row_id ASC

			CONTINUE
		END
	
		-- v5.0 Start
		-- Remove soft allocation record for order lines that now do not exist and are not allocated
		DELETE	a
		FROM	cvo_soft_alloc_det a
		JOIN	#snapshot b
		ON		a.order_no = b.order_no
		AND		a.order_ext = b.order_ext
		LEFT JOIN ord_list c (NOLOCK)
		ON		a.order_no = c.order_no
		AND		a.order_ext = c.order_ext
		AND		a.line_no = c.line_no
		LEFT JOIN tdc_soft_alloc_tbl d (NOLOCK)
		ON		a.order_no = d.order_no
		AND		a.order_ext = d.order_ext
		AND		a.line_no = d.line_no
		WHERE	c.order_no IS NULL 
		AND		c.order_ext IS NULL 
		AND		c.line_no IS NULL
		AND		d.order_no IS NULL 
		AND		d.order_ext IS NULL 
		AND		d.line_no is null
		AND		a.status <> 1
		AND		a.order_no = @order_no
		AND		a.order_ext = @order_ext

		DELETE	a
		FROM	cvo_soft_alloc_hdr a
		JOIN	#snapshot b
		ON		a.order_no = b.order_no
		AND		a.order_ext = b.order_ext
		LEFT JOIN cvo_soft_alloc_det c (NOLOCK)
		ON		a.order_no = c.order_no
		AND		a.order_ext = c.order_ext
		WHERE	a.status <> 1
		AND		c.order_no IS NULL
		AND		c.order_ext IS NULL
		AND		a.order_no = @order_no
		AND		a.order_ext = @order_ext


		-- v5.0 End


		-- v6.2 Start
		-- If being processed
		IF EXISTS (SELECT 1 FROM tdc_plw_orders_being_allocated (NOLOCK) WHERE order_no = @order_no AND order_ext = @order_ext)
		BEGIN
			-- v7.1 Start
			UPDATE	dbo.cvo_soft_alloc_hdr WITH (ROWLOCK)
			SET		status = 0
			WHERE	soft_alloc_no = @soft_alloc_no
			AND		status = -1	

			UPDATE	dbo.cvo_soft_alloc_det WITH (ROWLOCK)
			SET		status = 0
			WHERE	soft_alloc_no = @soft_alloc_no
			AND		status = -1	
			-- v7.1 End

			SET	@last_row_id = @row_id

			SELECT	TOP 1 @row_id = row_id,
					@soft_alloc_no = soft_alloc_no,
					@order_no = order_no,
					@order_ext = order_ext,
					@location = location,
					@has_kit = has_kit,
					@has_change = has_change, 
					@has_delete = has_delete	
			FROM	#process_alloc
			WHERE	row_id > @last_row_id
			ORDER BY row_id ASC

			CONTINUE
		END
		-- v6.2 End

		-- v6.3 Start
		SET @cur_con_no = NULL
		SELECT	@cur_con_no = consolidation_no
		FROM	cvo_masterpack_consolidation_det (NOLOCK)
		WHERE	order_no = @order_no
		AND		order_ext = @order_ext

		IF (@cur_con_no IS NOT NULL)
		BEGIN
			SELECT	@cur_con_count = COUNT(1)
			FROM	cvo_masterpack_consolidation_det (NOLOCK)
			WHERE	consolidation_no = @cur_con_no

			SELECT	@cur_con_count2 = COUNT(1)
			FROM	cvo_masterpack_consolidation_det a (NOLOCK)
			JOIN	#process_alloc b
			ON		a.order_no = b.order_no
			AND		a.order_ext = b.order_ext
			WHERE	a.consolidation_no = @cur_con_no

			-- v7.0 Start
			CREATE TABLE #cons_alloc_count (
				order_no	int,
				order_ext	int)

			INSERT	#cons_alloc_count
			SELECT	DISTINCT a.order_no, a.order_ext
			FROM	tdc_soft_alloc_tbl a (NOLOCK)
			JOIN	cvo_masterpack_consolidation_det b (NOLOCK)
			ON		a.order_no = b.order_no
			AND		a.order_ext = b.order_ext
			LEFT JOIN #process_alloc c
			ON		a.order_no = c.order_no
			AND		a.order_ext = c.order_ext
			WHERE	b.consolidation_no = @cur_con_no

			SELECT	@cur_con_count3 = COUNT(1)
			FROM	#cons_alloc_count

			DROP TABLE #cons_alloc_count

			SET @cur_con_count2 = @cur_con_count2 + ISNULL(@cur_con_count3,0)
			-- v7.0 End

			IF (@cur_con_count > @cur_con_count2) -- v7.1
			BEGIN
				-- v7.1 Start
				UPDATE	dbo.cvo_soft_alloc_hdr WITH (ROWLOCK)
				SET		status = 0
				WHERE	soft_alloc_no = @soft_alloc_no
				AND		status = -1	

				UPDATE	dbo.cvo_soft_alloc_det WITH (ROWLOCK)
				SET		status = 0
				WHERE	soft_alloc_no = @soft_alloc_no
				AND		status = -1	
				-- v7.1 End

				SET	@last_row_id = @row_id

				SELECT	TOP 1 @row_id = row_id,
						@soft_alloc_no = soft_alloc_no,
						@order_no = order_no,
						@order_ext = order_ext,
						@location = location,
						@has_kit = has_kit,
						@has_change = has_change, 
						@has_delete = has_delete	
				FROM	#process_alloc
				WHERE	row_id > @last_row_id
				ORDER BY row_id ASC

				CONTINUE
			
			END
		END
		-- v6.3 End

		-- Insert audit record, this is checked by the client and stops them changing the order while begin allocated
		INSERT	dbo.cvo_process_soft_allocations_audit (allocation_date, cons_no, order_no, order_ext, perc_allocated, error_messages)
		SELECT	GETDATE(), 0, @order_no, @order_ext, 0, 'ALLOCATING'
		-- v4.9 End

		-- v6.1 Start
		IF EXISTS (SELECT 1 FROM #forced_orders WHERE order_no = @order_no AND order_ext = @order_ext)
		BEGIN
			UPDATE	orders_all WITH (ROWLOCK)
			SET		status = 'N',
					hold_reason = ''
			WHERE	order_no = @order_no
			AND		ext = @order_ext
		END
		-- v6.1 End

		EXEC @rc = tdc_order_after_save @order_no, @order_ext   

		-- v6.1 Start
		IF EXISTS (SELECT 1 FROM #forced_orders WHERE order_no = @order_no AND order_ext = @order_ext)
		BEGIN
			UPDATE	a
			SET		status = b.status,
					hold_reason = b.hold_reason
			FROM	orders_all a WITH (ROWLOCK)
			JOIN	#forced_orders b
			ON		a.order_no = b.order_no
			AND		a.ext = b.order_ext
			WHERE	a.order_no = @order_no
			AND		a.ext = @order_ext
		END
		-- v6.1 End

			
		-- Allocation was successful
		if (@rc = 0) 
		BEGIN

			-- v6.0 Start
			INSERT	#global_ship_print (order_no, order_ext, global_ship)
			SELECT	order_no, ext, sold_to
			FROM	orders_all (NOLOCK)
			WHERE	order_no = @order_no
			AND		ext = @order_ext
			AND		status = 'N' -- v6.6
			AND		ISNULL(sold_to,'') > ''
			-- v6.0 End 

			-- v5.9 Start
			INSERT	#orders_to_consolidate (consolidation_no, order_no, ext)
			SELECT	a.consolidation_no,
					b.order_no,
					b.order_ext
			FROM	cvo_masterpack_consolidation_hdr a (NOLOCK)
			JOIN	cvo_masterpack_consolidation_det b (NOLOCK)
			ON		a.consolidation_no = b.consolidation_no
			JOIN	cvo_st_consolidate_release c (NOLOCK)
			ON		a.consolidation_no = c.consolidation_no
			WHERE	b.order_no = @order_no
			AND		b.order_ext = @order_ext
			AND		a.type = 'OE'
			AND		a.closed = 0
			AND		a.shipped = 0
			AND		c.released = 1
			-- v5.9 End

-- START v4.4 - add back in code removed in v3.1
-- v3.1 Start
			-- v2.9 Start
			-- If the order has not fully or only partially allocated and the order type is marked as no stock notification then 
			-- check the soft alloc record to see if it was fully available
			IF EXISTS (	SELECT	1 
						FROM	#no_stock_orders a 
						JOIN	cvo_soft_alloc_det b (NOLOCK)
						ON		a.order_no = b.order_no 
						AND		a.order_ext = b.order_ext 
						AND		a.line_no = b.line_no
						JOIN	orders_all c (NOLOCK)
						ON		a.order_no = c.order_no
						AND		a.order_ext = c.ext
						JOIN	so_usrcateg d (NOLOCK)
						ON		c.user_category = d.category_code
						WHERE	b.soft_alloc_no = @soft_alloc_no
						AND		d.no_stock_flag = 1
						AND		ISNULL(no_stock_hold,'') > '')
			BEGIN
				-- Check the soft allocation record
				IF EXISTS (SELECT 1 FROM cvo_soft_alloc_det a (NOLOCK) JOIN #no_stock_orders b ON a.order_no = b.order_no AND a.order_ext = b.order_ext
								AND a.line_no = b.line_no WHERE a.inv_avail = 1 AND b.no_stock = 1)
				BEGIN

					-- START v4.6 - get first no stock line for email
					SELECT 
						@ns_line_no = MIN(a.line_no) 
					FROM 
						cvo_soft_alloc_det a (NOLOCK) 
					JOIN 
						#no_stock_orders b 
					ON 
						a.order_no = b.order_no 
						AND a.order_ext = b.order_ext
						AND a.line_no = b.line_no 
					WHERE 
						a.inv_avail = 1 
						AND b.no_stock = 1
					-- END v4.6

					-- Update the soft alloc lines to mark as inv not available
					UPDATE	a
					SET		inv_avail = NULL
					FROM	cvo_soft_alloc_det a WITH (ROWLOCK)
					JOIN	#no_stock_orders b 
					ON		a.order_no = b.order_no 
					AND		a.order_ext = b.order_ext
					AND		a.line_no = b.line_no
					WHERE	a.inv_avail = 1 
					AND		b.no_stock = 1

					-- Get the hold code and reason for the order type
					SELECT	@hold_code = a.hold_code,
							@hold_reason = a.hold_reason,
							@notifications = b.notifications -- v4.4
					FROM	adm_oehold a (NOLOCK)
					JOIN	so_usrcateg b (NOLOCK)
					ON		a.hold_code = b.no_stock_hold
					JOIN	orders_all c (NOLOCK)
					ON		b.category_code = c.user_category
					WHERE	c.order_no = @order_no
					AND		c.ext = @order_ext	

					-- UnAllocate any item that did allocate
					EXEC CVO_UnAllocate_sp @order_no, @order_ext, 0, 'AUTO_ALLOC'

					-- Set the order on hold
					UPDATE	orders_all WITH (ROWLOCK)
					SET		status = 'A',
							hold_reason = @hold_code
					WHERE	order_no = @order_no
					AND		ext = @order_ext

					-- v5.7 Start
					UPDATE	a
					SET		prior_hold = 'SC'
					FROM	cvo_orders_all a WITH (ROWLOCK)
					JOIN	orders_all b (NOLOCK)
					ON		a.order_no = b.order_no
					AND		a.ext = b.ext
					WHERE	a.order_no = @order_no
					AND		a.ext = @order_ext
					AND		b.back_ord_flag = 1
					-- v5.7 End

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
							'STATUS:A/NO STOCK NOTIFICATION; HOLD REASON:' + @hold_reason
					FROM	orders_all a (NOLOCK)
					WHERE	a.order_no = @order_no
					AND		a.ext = @order_ext

					-- Sent the email notification
					-- START v4.4 - only send email if notifications are enabled for this order type
					IF ISNULL(@notifications,0) = 1
					BEGIN
						-- START v4.6						
						EXEC dbo.CVO_no_stock_email_sp	@order_no = @order_no, @order_ext = @order_ext, @line_no = @ns_line_no, @type = 0
						--EXEC dbo.CVO_no_stock_email_sp @order_no, @order_ext
						-- END v4.6
					END
					-- END v4.4

					DELETE	dbo.cvo_process_soft_allocations_audit WHERE order_no = @order_no AND order_ext = @order_ext AND error_messages = 'ALLOCATING' -- v4.9 Unlock records

					-- Move onto the next order
					SET	@last_row_id = @row_id

					SELECT	TOP 1 @row_id = row_id,
							@soft_alloc_no = soft_alloc_no,
							@order_no = order_no,
							@order_ext = order_ext,
							@location = location,
							@has_kit = has_kit,
							@has_change = has_change, 
							@has_delete = has_delete	
					FROM	#process_alloc
					WHERE	row_id > @last_row_id
					ORDER BY row_id ASC

					CONTINUE

				END

			END
			-- v2.9 End
-- v3.1 End
-- END v4.4

			-- v5.8 Start
			-- RX Order Consolidation - If the customer is marked as RX consolidate and it is not a custom frame order then print the pick ticket
			IF EXISTS (SELECT 1 FROM orders_all a (NOLOCK) JOIN cvo_armaster_all b (NOLOCK) ON a.cust_code = b.customer_code WHERE a.order_no = @order_no
						AND	a.ext = @order_ext AND b.rx_consolidate = 1 AND LEFT(a.user_category,2) = 'RX') 
			BEGIN
	 			IF NOT EXISTS (SELECT 1 FROM CVO_ord_list (NOLOCK) WHERE order_no = @order_no AND order_ext = @order_ext AND is_customized = 'S')
				BEGIN	

					-- v6.6 Start
					IF EXISTS (SELECT 1 FROM tdc_soft_alloc_tbl (NOLOCK) WHERE order_no = @order_no AND order_ext = @order_ext AND order_type = 'S')
					BEGIN
						-- v6.9 Start
						IF NOT EXISTS (SELECT 1 FROM orders_all (NOLOCK) WHERE order_no = @order_no AND ext = @order_ext AND status IN ('Q','P'))
						BEGIN

							EXEC dbo.cvo_print_pick_ticket_sp @order_no, @order_ext
							-- v1.5 End 

							-- v6.3 Start
							-- Remove the order from the global ship to print table otherwise it will print twice
							DELETE	#global_ship_print
							WHERE	order_no = @order_no
							AND		order_ext = @order_ext
							-- v6.3 End

							-- v2.8 Start
							INSERT INTO tdc_log WITH (ROWLOCK) ( tran_date , userid , trans_source , module , trans , tran_no , tran_ext , part_no , lot_ser , bin_no , location , quantity , data ) 
							SELECT	GETDATE() , 'AUTO_ALLOC' , 'VB' , 'PLW' , 'PICK TICKET' , a.order_no , a.ext , '' , '' , '' , a.location , '' ,
									'STATUS:Q;'
							FROM	orders_all a (NOLOCK)
							JOIN	cvo_orders_all b (NOLOCK)
							ON		a.order_no = b.order_no
							AND		a.ext = b.ext
							WHERE	a.order_no = @order_no
							AND		a.ext = @order_ext
						END -- v6.9
					END -- v6.6 End						
				END
			END
			-- v5.8 End

			-- v2.3 Start
			EXEC dbo.CVO_build_autopack_carton_sp @order_no, @order_ext 
			-- v2.3 End
			IF EXISTS(SELECT 1 FROM orders_all (NOLOCK) WHERE order_no = @order_no AND ext = @order_ext AND status = 'N')
			BEGIN
				IF EXISTS(SELECT * FROM CVO_ord_list (NOLOCK) WHERE order_no = @order_no AND order_ext = @order_ext AND is_customized = 'S') 
				BEGIN
					-- v1.4
					IF EXISTS (SELECT 1 FROM tdc_soft_alloc_tbl (NOLOCK) WHERE order_no = @order_no AND order_ext = @order_ext AND order_type = 'S')
					BEGIN
						IF NOT EXISTS (SELECT 1 FROM #line_exclusions WHERE order_no = @order_no AND order_ext = @order_ext) -- v2.0 Stop WO print as queue trans will be on hold
						BEGIN
							-- START v1.8
							/*
							IF NOT EXISTS (SELECT * FROM dbo.tdc_config WHERE [function] = 'mod_ebo_inv')
									INSERT INTO tdc_config ([function],mod_owner, description, active) VALUES ('mod_ebo_inv','EBO','Allow modify inventory from eBO','Y')	
							*/
							-- END v1.8

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

							-- v2.8 Start
							INSERT INTO tdc_log WITH (ROWLOCK) ( tran_date , userid , trans_source , module , trans , tran_no , tran_ext , part_no , lot_ser , bin_no , location , quantity , data ) 
							SELECT	GETDATE() , 'AUTO_ALLOC' , 'VB' , 'PLW' , 'ORDER UPDATE' , a.order_no , a.ext , '' , '' , '' , a.location , '' ,
									'STATUS:N/PRINT WORKS ORDER'
							FROM	orders_all a (NOLOCK)
							JOIN	cvo_orders_all b (NOLOCK)
							ON		a.order_no = b.order_no
							AND		a.ext = b.ext
							WHERE	a.order_no = @order_no
							AND		a.ext = @order_ext
							-- v2.8 End

							-- START v1.8
							--DELETE FROM dbo.tdc_config WHERE [function] = 'mod_ebo_inv'
							-- END v1.8
							
							
							-- v1.5 Start
							EXEC dbo.cvo_print_pick_ticket_sp @order_no, @order_ext
							-- v1.5 End 

							-- v2.8 Start
							INSERT INTO tdc_log WITH (ROWLOCK) ( tran_date , userid , trans_source , module , trans , tran_no , tran_ext , part_no , lot_ser , bin_no , location , quantity , data ) 
							SELECT	GETDATE() , 'AUTO_ALLOC' , 'VB' , 'PLW' , 'PICK TICKET' , a.order_no , a.ext , '' , '' , '' , a.location , '' ,
									'STATUS:Q;'
							FROM	orders_all a (NOLOCK)
							JOIN	cvo_orders_all b (NOLOCK)
							ON		a.order_no = b.order_no
							AND		a.ext = b.ext
							WHERE	a.order_no = @order_no
							AND		a.ext = @order_ext
							-- v2.8 End

						END -- v2.0
					END -- v1.4					
				END
			END

			-- v1.7
			--IF EXISTS (SELECT 1 FROM dbo.orders_all (NOLOCK) WHERE order_no = @order_no AND ext = @order_ext AND status = 'C')
			--BEGIN
			--	EXEC dbo.CVO_email_credithold_sp @order_no
			--END

			-- START v5.2
			/*
			UPDATE orders SET freight_allow_type = 'COLLECT' WHERE order_no = @order_no AND ext = @order_ext AND routing LIKE '3%' 
					AND status <> 'V' AND freight_allow_type != 'COLLECT'
			*/
			-- END v5.2

			-- START v2.7
			/*
			IF EXISTS (SELECT 1 FROM dbo.orders (NOLOCK) WHERE order_no = @order_no AND ext = @order_ext AND status <> 'V'
				AND location >= '100' AND location <= '999')
			BEGIN
				EXEC dbo.CVO_Ship_Rep_Orders_sp @order_no, @order_ext

				-- START v2.6
				IF EXISTS (SELECT 1 FROM dbo.orders (NOLOCK) WHERE order_no = @order_no AND ext = @order_ext AND status = 'R')
				BEGIN
					UPDATE	dbo.cvo_soft_alloc_hdr
					SET		status = -2
					WHERE	soft_alloc_no = @soft_alloc_no
					AND		status = -1	

					UPDATE	dbo.cvo_soft_alloc_det
					SET		status = -2
					WHERE	soft_alloc_no = @soft_alloc_no
					AND		status = -1	
				END
				-- END v2.6
			END
			*/
			-- END v2.7
		END
		
		IF EXISTS (SELECT 1 FROM tdc_soft_alloc_tbl (NOLOCK) WHERE order_no = @order_no AND order_ext = @order_ext AND location = @location AND order_type = 'S') 
		BEGIN

			-- v2.4 Add sub query to deal with multiple lines from tdc soft alloc
			/* v3.0
			SELECT	@curr_alloc_pct = ((SUM(b.qty) / SUM(a.ordered)) * 100)
			FROM	ord_list a (NOLOCK)
			JOIN	(SELECT SUM(qty) qty, order_no, order_ext, order_type, line_no FROM tdc_soft_alloc_tbl (NOLOCK) GROUP BY order_no, order_ext, order_type, line_no) b
			ON		a.order_no = b.order_no
			AND		a.order_ext = b.order_ext
			AND		a.line_no = b.line_no
			WHERE	a.order_no = @order_no
			AND		a.order_ext = @order_ext
			AND		b.order_type = 'S'
			*/
			-- v3.0 Start
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
			-- v3.0 End

			SELECT	@back_ord_flag = back_ord_flag
			FROM	orders_all (NOLOCK)
			WHERE	order_no = @order_no
			AND		ext = @order_ext

			-- v1.3 Start
			IF (@curr_alloc_pct < 100) -- v3.6  AND @back_ord_flag IN (0,2))
			BEGIN

				-- v5.7 Start
				IF (@back_ord_flag = 1)
				BEGIN
					-- UnAllocate any item that did allocate
					EXEC CVO_UnAllocate_sp @order_no, @order_ext, 0, 'AUTO_ALLOC'

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
					SELECT	GETDATE() , 'AUTO_ALLOC' , 'VB' , 'PLW' , 'ORDER UPDATE' , a.order_no , a.ext , '' , '' , '' , a.location , '' ,
							'STATUS:A; HOLD REASON: SC'
					FROM	orders_all a (NOLOCK)
					WHERE	a.order_no = @order_no
					AND		a.ext = @order_ext					

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

					-- v4.0 Start
					-- Get new soft alloc number
	--				BEGIN TRAN
	--					UPDATE	dbo.cvo_soft_alloc_next_no
	--					SET		next_no = next_no + 1
	--				COMMIT TRAN	
					
	--				SELECT	@new_soft_alloc = next_no
	--				FROM	dbo.cvo_soft_alloc_next_no

					SET	@new_soft_alloc = @soft_alloc_no
					-- v4.0 End

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
							(SELECT SUM(qty) qty, order_no, order_ext, order_type, line_no FROM tdc_soft_alloc_tbl (NOLOCK) GROUP BY order_no, order_ext, order_type, line_no) b -- v2.4
					ON		a.order_no = b.order_no
					AND		a.order_ext = b.order_ext
					AND		a.line_no = b.line_no
					WHERE	a.order_no = @order_no
					AND		a.order_ext = @order_ext
					AND		ISNULL(b.order_type,'S') = 'S'
					GROUP BY a.line_no, a.part_no

					-- Create the new soft allocation records
					-- v4.7 Start
					IF NOT EXISTS (SELECT 1 FROM cvo_soft_alloc_hdr WHERE soft_alloc_no = @soft_alloc_no AND status = 0)
					BEGIN
						INSERT	cvo_soft_alloc_hdr WITH (ROWLOCK) (soft_alloc_no, order_no, order_ext, location, bo_hold, status)
		-- v3.6				SELECT	@new_soft_alloc, order_no, order_ext, location, 1, 0
						SELECT	@new_soft_alloc, order_no, order_ext, location, CASE WHEN @back_ord_flag = 1 THEN 0 ELSE 1 END, 0 -- v3.6
						FROM	cvo_soft_alloc_hdr (NOLOCK)
						WHERE	soft_alloc_no = @soft_alloc_no
					END

					INSERT	cvo_soft_alloc_det WITH (ROWLOCK)(soft_alloc_no, order_no, order_ext, line_no, location, part_no, quantity,  
															kit_part, change, deleted, is_case, is_pattern, is_pop_gift, status, add_case_flag, case_adjust) -- v3.4 v3.5
					SELECT	DISTINCT @new_soft_alloc, a.order_no, a.order_ext, a.line_no, a.location, a.part_no, b.quantity,  
															a.kit_part, 0, a.deleted, a.is_case, a.is_pattern, a.is_pop_gift, 0, a.add_case_flag, a.case_adjust -- v3.4 v3.5

					FROM	cvo_soft_alloc_det a (NOLOCK)
					JOIN	#sa_backorder b
					ON		a.line_no = b.line_no
					AND		a.part_no = b.part_no
					WHERE	b.quantity > 0
					AND		soft_alloc_no = @soft_alloc_no
					-- v4.7 End
					
					DROP TABLE #sa_backorder

					-- v3.8 Start
					DELETE	dbo.cvo_soft_alloc_hdr
					WHERE	order_no = @order_no
					AND		order_ext = @order_ext
					AND		status = -2

					DELETE	dbo.cvo_soft_alloc_det
					WHERE	order_no = @order_no
					AND		order_ext = @order_ext
					AND		status = -2
					-- v3.8

					EXEC dbo.cvo_update_soft_alloc_case_adjust_sp @new_soft_alloc, @order_no, @order_ext
				END
				-- v5.7 End					
			END
			-- v1.3 End
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
	
			DELETE	dbo.cvo_process_soft_allocations_audit WHERE order_no = @order_no AND order_ext = @order_ext AND error_messages = 'ALLOCATING' -- v4.9 Unlock records

			SET @error_messages = ''

			SET	@last_row_id = @row_id

			SELECT	TOP 1 @row_id = row_id,
					@soft_alloc_no = soft_alloc_no,
					@order_no = order_no,
					@order_ext = order_ext,
					@location = location,
					@has_kit = has_kit,
					@has_change = has_change, 
					@has_delete = has_delete	
			FROM	#process_alloc
			WHERE	row_id > @last_row_id
			ORDER BY row_id ASC

			CONTINUE

		END

		IF (@curr_alloc_pct IS NULL)
			SET @curr_alloc_pct = 0

		SELECT	@cons_no = consolidation_no 
		FROM	tdc_cons_ords (NOLOCK)
		WHERE	order_no = @order_no
		AND		order_ext = @order_ext

		IF (@cons_no IS NULL)
			SET @cons_no = 0


		INSERT	dbo.cvo_process_soft_allocations_audit (allocation_date, cons_no, order_no, order_ext, perc_allocated, error_messages)
		SELECT	GETDATE(), @cons_no, @order_no, @order_ext, @curr_alloc_pct, @error_messages

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

		-- v3.8 Start
		DELETE	dbo.cvo_soft_alloc_hdr
		WHERE	order_no = @order_no
		AND		order_ext = @order_ext
		AND		status = -2

		DELETE	dbo.cvo_soft_alloc_det
		WHERE	order_no = @order_no
		AND		order_ext = @order_ext
		AND		status = -2
		-- v3.8

		DELETE	dbo.cvo_process_soft_allocations_audit WHERE order_no = @order_no AND order_ext = @order_ext AND error_messages = 'ALLOCATING' -- v4.9 Unlock records

		SET	@last_row_id = @row_id

		SELECT	TOP 1 @row_id = row_id,
				@soft_alloc_no = soft_alloc_no,
				@order_no = order_no,
				@order_ext = order_ext,
				@location = location,
				@has_kit = has_kit,
				@has_change = has_change, 
				@has_delete = has_delete	
		FROM	#process_alloc
		WHERE	row_id > @last_row_id
		ORDER BY row_id ASC
	END

	-- START v5.4
	CREATE TABLE #bo_holds (
		rec_id INT IDENTITY (1,1),
		order_no INT,
		order_ext INT)

	INSERT INTO #bo_holds(
		order_no,
		order_ext)
	SELECT DISTINCT 	
		a.order_no,
		a.order_ext
	FROM
		dbo.cvo_soft_alloc_hdr a (NOLOCK)
	INNER JOIN
		dbo.cvo_soft_alloc_det b (NOLOCK)
	ON
		a.soft_alloc_no = b.soft_alloc_no
	WHERE
		ISNULL(a.bo_hold,0) = 1
		AND a.status NOT IN (1,-1)
		AND (b.deleted = 1 OR b.change > 0)
	ORDER BY
		a.order_no, 
		a.order_ext

	SET @rec_id = 0
	WHILE 1=1
	BEGIN
		
		SELECT TOP 1
			@rec_id = rec_id,
			@order_no = order_no,
			@order_ext = order_ext
		FROM
			#bo_holds
		WHERE
			rec_id > @rec_id
		ORDER BY
			rec_id

		IF @@ROWCOUNT = 0
			BREAK

		-- Check it hasn't been picked up for processing
		IF EXISTS(SELECT 1 FROM dbo.cvo_soft_alloc_hdr (NOLOCK) WHERE order_no = @order_no AND order_ext = @order_ext AND status NOT IN (-1,1))
		BEGIN
			EXEC dbo.cvo_process_soft_alloc_changes_sp @order_no, @order_ext
		END
	END
	-- END v5.4

	-- v6.0 Start
	IF EXISTS (SELECT 1 FROM #global_ship_print)
	BEGIN
		EXEC dbo.cvo_release_GST_Held_Orders_sp 1
	END
	DROP TABLE #global_ship_print
	-- v6.0 End

	-- v7.3 Start
	IF EXISTS (SELECT 1 FROM #orders_to_consolidate)
	BEGIN
		SET @last_stcons_no = 0

		SELECT	TOP 1 @stcons_no = consolidation_no
		FROM	#orders_to_consolidate
		WHERE	consolidation_no > @last_stcons_no
		ORDER BY consolidation_no ASC	

		WHILE (@@ROWCOUNT <> 0)
		BEGIN

			IF EXISTS (SELECT 1 FROM orders_all a (NOLOCK) JOIN cvo_masterpack_consolidation_det b (NOLOCK) ON a.order_no = b.order_no AND a.ext = b.order_ext
						WHERE b.consolidation_no = @stcons_no AND a.status = 'A')
			BEGIN

				SET @order_no = 0

				WHILE (1 = 1)
				BEGIN
					SELECT	TOP 1 @order_no = order_no,
							@order_ext = order_ext
					FROM	cvo_masterpack_consolidation_det (NOLOCK)
					WHERE	consolidation_no = @stcons_no
					AND		order_no > @order_no
					ORDER BY order_no ASC

					IF (@@ROWCOUNT = 0)
						BREAK

					EXEC dbo.cvo_UnAllocate_sp @order_no, @order_ext, 0, 'AUTO_ALLOC', 1

					SELECT	@hold_reason = hold_reason
					FROM	orders_all (NOLOCK)
					WHERE	order_no = @order_no
					AND		ext = @order_ext

					IF (ISNULL(@hold_reason,'') <> '')
					BEGIN
						UPDATE	cvo_orders_all
						SET		prior_hold = 'STC'
						WHERE	order_no = @order_no
						AND		ext = @order_ext
					END
					ELSE
					BEGIN
						UPDATE	orders_all
						SET		status = 'A',
								hold_reason = 'STC'
						WHERE	order_no = @order_no
						AND		ext = @order_ext					
					END					
				END
			
				UPDATE	cvo_masterpack_consolidation_hdr
				SET		closed = 0
				WHERE	consolidation_no = @stcons_no

				UPDATE	cvo_st_consolidate_release
				SET		released = 0,
						release_date = NULL,
						release_user = NULL
				WHERE	consolidation_no = @stcons_no

			END

			SET @last_stcons_no = @stcons_no

			SELECT	TOP 1 @stcons_no = consolidation_no
			FROM	#orders_to_consolidate
			WHERE	consolidation_no > @last_stcons_no
			ORDER BY consolidation_no ASC

		END
		
	END
	-- v7.3 End

	-- v7.2 Start
	IF OBJECT_ID('tempdb..#consolidate_picks') IS NOT NULL  
		DROP TABLE #consolidate_picks  

	CREATE TABLE #consolidate_picks(  
		consolidation_no	int,  
		order_no			int,  
		ext					int)  	
	-- v7.2 End

	-- v5.9 Start
	IF EXISTS (SELECT 1 FROM #orders_to_consolidate)
	BEGIN
		SET @last_stcons_no = 0

		SELECT	TOP 1 @stcons_no = consolidation_no
		FROM	#orders_to_consolidate
		WHERE	consolidation_no > @last_stcons_no
		ORDER BY consolidation_no ASC

		WHILE (@@ROWCOUNT <> 0)
		BEGIN

			DELETE	#consolidate_picks

			INSERT	#consolidate_picks
			SELECT	consolidation_no, order_no, ext
			FROM	#orders_to_consolidate
			WHERE	consolidation_no = @stcons_no

			EXEC dbo.cvo_masterpack_consolidate_pick_records_sp @stcons_no

			SET @last_stcons_no = @stcons_no

			SELECT	TOP 1 @stcons_no = consolidation_no
			FROM	#orders_to_consolidate
			WHERE	consolidation_no > @last_stcons_no
			ORDER BY consolidation_no ASC

		END
		
	END

	DROP TABLE #orders_to_consolidate
	DROP TABLE #consolidate_picks
	-- v5.9 End

	-- v6.5 Start
	UPDATE	a
	SET		status = b.alloc_status
	FROM	cvo_soft_alloc_hdr a
	JOIN	#future_orders b
	ON		a.order_no = b.order_no
	AND		a.order_ext = b.order_ext

	UPDATE	a
	SET		status = b.alloc_status
	FROM	cvo_soft_alloc_det a
	JOIN	#future_orders b
	ON		a.order_no = b.order_no
	AND		a.order_ext = b.order_ext
	-- v6.5 End

	DROP TABLE #forced_orders -- v6.1
	DROP TABLE #future_orders -- v6.5	
	
END
GO
GRANT EXECUTE ON  [dbo].[cvo_process_soft_allocations_sp] TO [public]
GO
