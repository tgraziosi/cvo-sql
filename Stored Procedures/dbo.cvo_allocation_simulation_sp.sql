SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[cvo_allocation_simulation_sp] @user_spid int
AS
BEGIN
	-- NOTE: Routine based on cvo_process_soft_allocations_sp v8.2 - All changes must be kept in sync

	-- DIRECTIVES
	SET NOCOUNT ON
	SET ANSI_WARNINGS OFF

	-- DECLARATIONS
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
			@curr_ordered	decimal(20,8),
			@curr_alloc		decimal(20,8),
			@new_soft_alloc	int, 
			@back_ord_flag	int, 
			@hold_code		varchar(10),
			@hold_reason	varchar(40),
			@start_date		varchar(19),
			@notifications	SMALLINT,
			@ns_line_no		int,	
			@rec_id			SMALLINT,
			@stcons_no		int,
			@last_stcons_no int,
			@prior_hold		varchar(10),
			@fl_row_id		int, 
			@fill_rate		decimal(20,8), 
			@fill_rate_level decimal(20,8), 
			@sc_flag		int, 
			@hold_priority	int, 
			@user_category	varchar(20), 
			@status			char(1), 
			@fs_ordered		decimal(20,8), 
			@fs_allocated	decimal(20,8),
			@cur_con_no		int,
			@cur_con_count	int,
			@cur_con_count2	int,
			@cur_con_count3	int 

	-- SNAPSHOT TABLES
	CREATE TABLE #sim_cvo_soft_alloc_hdr (
		soft_alloc_no		int,
		order_no			int,
		order_ext			int,
		location			varchar(10),
		bo_hold				int,
		status				smallint)

	CREATE TABLE #sim_cvo_soft_alloc_det (
		soft_alloc_no		int,
		order_no			int,
		order_ext			int,
		line_no				int,
		location			varchar(10),
		part_no				varchar(30),
		quantity			decimal(20,8),
		kit_part			smallint,
		change				smallint,
		deleted				smallint,
		is_case				smallint,
		is_pattern			smallint,
		is_pop_gift			smallint,
		status				smallint,
		row_id				int,
		inv_avail			smallint,
		add_case_flag		char(1),
		case_adjust			decimal(20,8))

	CREATE TABLE #sim_tdc_soft_alloc_tbl (
		order_no		int,
		order_ext		int,
		location		varchar(10),
		line_no			int,
		part_no			varchar(30),
		lot_ser			varchar(25),
		bin_no			varchar(20),
		qty				decimal(20,8),
		target_bin		varchar(20),
		dest_bin		varchar(20),
		trg_off			bit,
		order_type		char(1),
		assigned_user	varchar(50),
		q_priority		int,
		alloc_type		varchar(2),
		pkg_code		varchar(10),
		user_hold		char(1))

	CREATE TABLE #sim_tdc_pick_queue (
		trans_source		varchar(5),
		trans				varchar(10),
		tran_id				int IDENTITY(1,1),
		priority			int,
		seq_no				int,
		company_no			varchar(10),
		location			varchar(10),
		warehouse_no		varchar(10),
		trans_type_no		int,
		trans_type_ext		int,
		tran_receipt_no		int,
		line_no				int,
		pcsn				int,
		part_no				varchar(30),
		eco_no				varchar(25),
		lot					varchar(25),
		mfg_lot				varchar(25),
		mfg_batch			varchar(25),
		serial_no			varchar(40),
		bin_no				varchar(12),
		qty_to_process		decimal(20,8),
		qty_processed		decimal(20,8),
		qty_short			decimal(20,8),
		next_op				varchar(12),
		tran_id_link		int,
		date_time			datetime,
		assign_group		varchar(25),
		assign_user_id		varchar(50),
		user_id				varchar(50),
		status				char(2),
		tx_status			char(2),
		tx_control			varchar(10),
		tx_lock				char(2),
		mp_consolidation_no	int)

	CREATE TABLE #sim_tdc_main (
		consolidation_no	int,
		consolidation_name	varchar(100),
		description			varchar(100),
		order_type			char(1),
		created_by			varchar(50),
		creation_date		datetime,
		filter_name_used	varchar(32),
		status				varchar(3),
		virtual_freight		char(1),
		pre_pack			char(1))
	
	CREATE TABLE #sim_tdc_cons_ords (
		consolidation_no	int,
		order_no			int,
		order_ext			int,
		location			varchar(10),
		status				char(2),
		seq_no				int,
		print_count			int,
		order_type			char(1),
		alloc_type			varchar(2))

	CREATE TABLE #sim_CVO_qty_to_alloc_tbl (
		order_no		int,
		order_ext		int,
		location		varchar(10),
		from_line_no	int,
		line_no			int,
		part_no			varchar(30),
		qty_to_alloc	decimal(20,8))

	-- CREATE WORKING TABLE
	CREATE TABLE #process_alloc (
		row_id			int IDENTITY(1,1),
		soft_alloc_no	int,
		order_no		int,
		order_ext		int,
		location		varchar(10),
		has_change		int,
		has_kit			int,
		has_delete		int)

	CREATE TABLE #exclusions (
		order_no		int,
		order_ext		int,
		has_line_exc	int NULL) 

	CREATE TABLE #line_exclusions (
		order_no		int,
		order_ext		int,
		line_no			int)

	CREATE TABLE #no_stock_orders (
		order_no		int,
		order_ext		int,
		line_no			int,
		no_stock		int)	

	CREATE TABLE #snapshot (
		soft_alloc_no	int,
		order_no		int,
		order_ext		int)

	CREATE TABLE #forced_orders (
		order_no		int,
		order_ext		int,
		status			char(1),
		hold_reason		varchar(10))

	CREATE TABLE #future_orders (
		order_no		int,
		order_ext		int,
		status			char(1),
		hold_reason		varchar(10),
		alloc_status	int)

	CREATE TABLE #no_soft_alloc_orders (
		order_no	int,
		order_ext	int)

	CREATE TABLE #future_fl_check (
		row_id		int IDENTITY(1,1),
		order_no	int,	
		order_ext	int)

	CREATE TABLE #orders_to_consolidate(  
		consolidation_no	int,  
		order_no			int,  
		ext					int)  		

	CREATE TABLE #inserted (
		order_no		int,
		order_ext		int,
		location		varchar(10),
		line_no			int,
		part_no			varchar(30),
		lot_ser			varchar(25),
		bin_no			varchar(20),
		qty				decimal(20,8),
		target_bin		varchar(20),
		dest_bin		varchar(20),
		trg_off			bit,
		order_type		char(1),
		assigned_user	varchar(50),
		q_priority		int,
		alloc_type		varchar(2),
		pkg_code		varchar(10),
		user_hold		char(1))

	CREATE TABLE #deleted (
		order_no		int,
		order_ext		int,
		location		varchar(10),
		line_no			int,
		part_no			varchar(30),
		lot_ser			varchar(25),
		bin_no			varchar(20),
		qty				decimal(20,8),
		target_bin		varchar(20),
		dest_bin		varchar(20),
		trg_off			bit,
		order_type		char(1),
		assigned_user	varchar(50),
		q_priority		int,
		alloc_type		varchar(2),
		pkg_code		varchar(10),
		user_hold		char(1))

	-- PROCESSING
	DELETE	dbo.cvo_allocation_simulation_summary_hdr
	WHERE	user_spid = @user_spid

	DELETE	dbo.cvo_allocation_simulation_summary_det
	WHERE	user_spid = @user_spid

	DELETE	dbo.cvo_allocation_simulation_detail
	WHERE	user_spid = @user_spid

	INSERT	#sim_cvo_soft_alloc_hdr (soft_alloc_no, order_no, order_ext, location, bo_hold, status)
	SELECT	soft_alloc_no, order_no, order_ext, location, bo_hold, status
	FROM	cvo_soft_alloc_hdr (NOLOCK)

	CREATE INDEX #cvo_soft_alloc_hdr_ind0 ON #sim_cvo_soft_alloc_hdr(soft_alloc_no, order_no, order_ext)
	CREATE INDEX #cvo_soft_alloc_hdr_ind1 ON #sim_cvo_soft_alloc_hdr(order_no, order_ext)
	CREATE INDEX #cvo_soft_alloc_hdr_ind2 ON #sim_cvo_soft_alloc_hdr(status)
	CREATE INDEX #cvo_soft_alloc_hdr_ind3 ON #sim_cvo_soft_alloc_hdr(order_no, order_ext, status, bo_hold)
	
	INSERT	#sim_cvo_soft_alloc_det (soft_alloc_no, order_no, order_ext, line_no, location, part_no, quantity, kit_part, 
			change, deleted, is_case, is_pattern, is_pop_gift, status, row_id, inv_avail, add_case_flag, case_adjust)
	SELECT	soft_alloc_no, order_no, order_ext, line_no, location, part_no, quantity, kit_part, 
			change, deleted, is_case, is_pattern, is_pop_gift, status, row_id, inv_avail, add_case_flag, case_adjust
	FROM	cvo_soft_alloc_det (NOLOCK)

	CREATE INDEX #cvo_soft_alloc_det_ind0 ON #sim_cvo_soft_alloc_det(soft_alloc_no)
	CREATE INDEX #cvo_soft_alloc_det_ind1 ON #sim_cvo_soft_alloc_det(order_no, order_ext, line_no)
	CREATE INDEX #cvo_soft_alloc_det_ind2 ON #sim_cvo_soft_alloc_det(row_id)
	CREATE INDEX #cvo_soft_alloc_det_ind3 ON #sim_cvo_soft_alloc_det(soft_alloc_no, location, part_no, status)
	CREATE INDEX #cvo_soft_alloc_det_ind4 ON #sim_cvo_soft_alloc_det(status, soft_alloc_no, line_no, part_no)
	CREATE INDEX #cvo_soft_alloc_det_ind5 ON #sim_cvo_soft_alloc_det(order_no, order_ext, status, soft_alloc_no, line_no, part_no)

	INSERT	#sim_tdc_soft_alloc_tbl (order_no, order_ext, location, line_no, part_no, lot_ser, bin_no, qty, target_bin, dest_bin,
			trg_off, order_type, assigned_user, q_priority, alloc_type, pkg_code, user_hold)
	SELECT	order_no, order_ext, location, line_no, part_no, lot_ser, bin_no, qty, target_bin, dest_bin,
			trg_off, order_type, assigned_user, q_priority, alloc_type, pkg_code, user_hold
	FROM	tdc_soft_alloc_tbl (NOLOCK)
	WHERE	order_type = 'S'

	CREATE INDEX #sim_tdc_soft_alloc_tbl_ind0 ON #sim_tdc_soft_alloc_tbl(part_no, bin_no, location, lot_ser)
	CREATE INDEX #sim_tdc_soft_alloc_tbl_ind1 ON #sim_tdc_soft_alloc_tbl(order_no, order_ext, order_type, location, line_no, part_no, lot_ser, bin_no, target_bin)
	CREATE INDEX #sim_tdc_soft_alloc_tbl_ind2 ON #sim_tdc_soft_alloc_tbl(location, part_no, lot_ser, bin_no, target_bin)
	CREATE INDEX #sim_tdc_soft_alloc_tbl_ind3 ON #sim_tdc_soft_alloc_tbl(order_no, order_ext, qty)

	SET IDENTITY_INSERT #sim_tdc_pick_queue ON

	INSERT	#sim_tdc_pick_queue (trans_source, trans, tran_id, priority, seq_no, company_no, location, warehouse_no, trans_type_no, trans_type_ext, 
			tran_receipt_no, line_no, pcsn, part_no, eco_no, lot, mfg_lot, mfg_batch, serial_no, bin_no, qty_to_process, qty_processed, qty_short, 
			next_op, tran_id_link, date_time, assign_group, assign_user_id, user_id, status, tx_status, tx_control, tx_lock, mp_consolidation_no)
	SELECT	trans_source, trans, tran_id, priority, seq_no, company_no, location, warehouse_no, trans_type_no, trans_type_ext, 
			tran_receipt_no, line_no, pcsn, part_no, eco_no, lot, mfg_lot, mfg_batch, serial_no, bin_no, qty_to_process, qty_processed, qty_short, 
			next_op, tran_id_link, date_time, assign_group, assign_user_id, user_id, status, tx_status, tx_control, tx_lock, mp_consolidation_no
	FROM	tdc_pick_queue (NOLOCK)

	SET IDENTITY_INSERT #sim_tdc_pick_queue OFF

	CREATE INDEX #sim_tdc_pick_queue_ind0 ON #sim_tdc_pick_queue(user_id)
	CREATE INDEX #sim_tdc_pick_queue_ind1 ON #sim_tdc_pick_queue(assign_user_id, tx_lock, tran_id, location, bin_no, part_no)
	CREATE INDEX #sim_tdc_pick_queue_ind2 ON #sim_tdc_pick_queue(assign_group, tx_lock, tran_id, location, bin_no, part_no)
	CREATE INDEX #sim_tdc_pick_queue_ind3 ON #sim_tdc_pick_queue(assign_user_id, assign_group, tx_lock, tran_id, location, bin_no, part_no)
	CREATE INDEX #sim_tdc_pick_queue_ind4 ON #sim_tdc_pick_queue(trans, trans_type_no, trans_type_ext, location, part_no, lot, bin_no, line_no, trans_source)
	CREATE INDEX #sim_tdc_pick_queue_ind5 ON #sim_tdc_pick_queue(location, part_no, lot, bin_no, trans)
	CREATE INDEX #sim_tdc_pick_queue_ind6 ON #sim_tdc_pick_queue(tran_id)

	SELECT	* INTO #tmp_tdc_soft_alloc_tbl 
	FROM	#sim_tdc_soft_alloc_tbl
	SELECT	* INTO #tmp_tdc_pick_queue 
	FROM	#sim_tdc_pick_queue

	INSERT	#sim_tdc_main (consolidation_no, consolidation_name, description, order_type, created_by, creation_date, filter_name_used, 
		status, virtual_freight, pre_pack)
	SELECT	consolidation_no, consolidation_name, description, order_type, created_by, creation_date, filter_name_used, 
			status, virtual_freight, pre_pack
	FROM	tdc_main (NOLOCK)

	CREATE INDEX #sim_tdc_main_ind0 ON #sim_tdc_main(consolidation_no)

	INSERT	#sim_tdc_cons_ords (consolidation_no, order_no, order_ext, location, status, seq_no, print_count, order_type, alloc_type)
	SELECT	consolidation_no, order_no, order_ext, location, status, seq_no, print_count, order_type, alloc_type
	FROM	tdc_cons_ords (NOLOCK)

	CREATE INDEX #sim_tdc_cons_ords_ind0 ON #sim_tdc_cons_ords(consolidation_no, order_no, order_ext)

	INSERT	#sim_CVO_qty_to_alloc_tbl (order_no, order_ext, location, from_line_no, line_no, part_no, qty_to_alloc)
	SELECT	order_no, order_ext, location, from_line_no, line_no, part_no, qty_to_alloc
	FROM	CVO_qty_to_alloc_tbl (NOLOCK)

	CREATE INDEX #sim_CVO_qty_to_alloc_tbl_ind0 ON #sim_CVO_qty_to_alloc_tbl(order_no, order_ext, from_line_no, location, part_no)

	SET @start_date = CONVERT(varchar(19),GETDATE(),121) 

	DELETE	a
	FROM	#sim_cvo_soft_alloc_hdr a
	JOIN	orders_all b (NOLOCK)
	ON		a.order_no = b.order_no
	AND		a.order_ext = b.ext
	WHERE	b.status = 'V'

	DELETE	a
	FROM	#sim_cvo_soft_alloc_det a
	JOIN	orders_all b (NOLOCK)
	ON		a.order_no = b.order_no
	AND		a.order_ext = b.ext
	WHERE	b.status = 'V'

	-- v1.1 Start
	-- Remove records that are already allocated and do have changes
	CREATE TABLE #oa_alloc (
		soft_alloc_no	int,
		order_no		int,
		order_ext		int,
		line_no			int,
		part_no			varchar(30),
		qty				decimal(20,8))

	INSERT	#oa_alloc
	SELECT	a.soft_alloc_no,
			b.order_no,
			b.order_ext,
			b.line_no,
			b.part_no,
			SUM(b.qty)
	FROM	dbo.cvo_soft_alloc_hdr a (NOLOCK)
	JOIN	tdc_soft_alloc_tbl b (NOLOCK)
	ON		a.order_no = b.order_no
	AND		a.order_ext = b.order_ext
	WHERE	a.status IN (0, -3)
	AND		b.order_type = 'S'
	GROUP BY a.soft_alloc_no,
			b.order_no,
			b.order_ext,
			b.line_no,
			b.part_no

	DELETE	a
	FROM	#sim_cvo_soft_alloc_det a
	JOIN	#oa_alloc b
	ON		a.soft_alloc_no = b.soft_alloc_no
	AND		a.line_no = b.line_no
	AND		a.part_no = b.part_no
	WHERE	a.quantity = b.qty

	DELETE	a
	FROM	#sim_cvo_soft_alloc_hdr a
	JOIN	#oa_alloc b
	ON		a.soft_alloc_no = b.soft_alloc_no
	WHERE	a.soft_alloc_no NOT IN (
			SELECT soft_alloc_no FROM #sim_cvo_soft_alloc_det (NOLOCK))

	DROP TABLE #oa_alloc
	-- v1.1 End

	INSERT	#snapshot (soft_alloc_no, order_no, order_ext)
	SELECT	soft_alloc_no, order_no, order_ext
	FROM	#sim_cvo_soft_alloc_det (NOLOCK)
	WHERE	[status] IN (0,-3)

	DELETE	a
	FROM	#sim_cvo_soft_alloc_det a
	JOIN	cvo_soft_alloc_ctl b (NOLOCK)
	ON		a.soft_alloc_no = b.soft_alloc_no
	WHERE	a.order_no = 0
	AND		DATEDIFF(hh, b.date_entered, getdate()) > 4

	DELETE	a
	FROM	#sim_cvo_soft_alloc_hdr a
	JOIN	cvo_soft_alloc_ctl b (NOLOCK)
	ON		a.soft_alloc_no = b.soft_alloc_no
	WHERE	a.order_no = 0
	AND		DATEDIFF(hh, b.date_entered, getdate()) > 4

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

	INSERT	#exclusions (order_no, order_ext)
	SELECT	order_no,
			ext
	FROM	orders_all (NOLOCK)
	WHERE	status = 'A'
	AND		hold_reason = 'H'

	INSERT	#exclusions (order_no, order_ext)
	SELECT	order_no, order_ext
	FROM	cvo_so_holds (NOLOCK)
	WHERE	hold_reason = 'NA'

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

	EXEC	cvo_soft_alloc_CF_check_sp -- v1.6

	UPDATE	a
	SET		status = -4
	FROM	#sim_cvo_soft_alloc_hdr a 
	JOIN	#exclusions b
	ON		a.order_no = b.order_no
	AND		a.order_ext = b.order_ext
	JOIN	cvo_ord_list c (NOLOCK)
	ON		a.order_no = c.order_no
	AND		a.order_ext = c.order_ext
	WHERE	c.is_customized = 'S'

	UPDATE	a
	SET		status = -4
	FROM	#sim_cvo_soft_alloc_det a 
	JOIN	#sim_cvo_soft_alloc_hdr b (NOLOCK)
	ON		a.soft_alloc_no = b.soft_alloc_no
	WHERE	b.status = -4

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

	INSERT	#exclusions (order_no, order_ext)
	SELECT	a.order_no,
			a.order_ext
	FROM	cvo_so_holds a (NOLOCK)
	LEFT JOIN cvo_alloc_hold_values_tbl b (NOLOCK)
	ON		a.hold_reason = b.hold_code
	WHERE	b.hold_code IS NULL

	INSERT	#future_fl_check (order_no, order_ext)
	SELECT	a.order_no, a.order_ext
	FROM	dbo.#sim_cvo_soft_alloc_hdr a 
	JOIN	cvo_orders_all b (NOLOCK)
	ON		a.order_no = b.order_no
	AND		a.order_ext = b.ext
	LEFT JOIN #no_soft_alloc_orders d
	ON		a.order_no = d.order_no
	AND		a.order_ext = d.order_ext
	WHERE	b.allocation_date <= getdate()
	AND		a.status = -3
	AND		d.order_no IS NULL 
	AND		d.order_ext IS NULL

	SELECT	@fill_rate_level = CAST(value_str as decimal(20,8))
	FROM	dbo.config (NOLOCK) 
	WHERE	flag = 'ST_ORDER_FILL_RATE'

	SET @fl_row_id = 0

	WHILE (1 = 1)
	BEGIN

		SELECT	TOP 1 @fl_row_id = row_id,
				@order_no = order_no,
				@order_ext = order_ext
		FROM	#future_fl_check
		WHERE	row_id > @fl_row_id
		ORDER BY row_id ASC

		IF (@@ROWCOUNT = 0)
			BREAK

		SELECT	@soft_alloc_no = soft_alloc_no
		FROM	cvo_soft_alloc_no_assign (NOLOCK)
		WHERE	order_no = @order_no
		AND		order_ext = @order_ext

		SELECT	@sc_flag = back_ord_flag,
				@user_category = user_category,
				@status = status
		FROM	orders_all (NOLOCK)
		WHERE	order_no = @order_no
		AND		ext = @order_ext

		SET @fill_rate = -1
		EXEC dbo.cvo_order_summary_sp @soft_alloc_no, @order_no, @order_ext, 1, NULL, @fill_rate OUTPUT 

		IF (@fill_rate < 100 AND @sc_flag = 1)
		BEGIN
			INSERT	#exclusions (order_no, order_ext)
			SELECT	@order_no, @order_ext
		END

		IF ((@fill_rate < @fill_rate_level AND @sc_flag <> 1) AND LEFT(@user_category,2) = 'ST')
		BEGIN
			INSERT	#exclusions (order_no, order_ext)
			SELECT	@order_no, @order_ext
		END
	END

	UPDATE	a
	SET		status = 0
	FROM	#sim_cvo_soft_alloc_hdr a 
	JOIN	cvo_orders_all b (NOLOCK)
	ON		a.order_no = b.order_no
	AND		a.order_ext = b.ext
	LEFT JOIN #no_soft_alloc_orders d
	ON		a.order_no = d.order_no
	AND		a.order_ext = d.order_ext 
	WHERE	b.allocation_date <= getdate()
	AND		a.status = -3
	AND		d.order_no IS NULL
	AND		d.order_ext IS NULL

	UPDATE	a
	SET		status = 0
	FROM	#sim_cvo_soft_alloc_det a 
	JOIN	cvo_orders_all b (NOLOCK)
	ON		a.order_no = b.order_no
	AND		a.order_ext = b.ext
	LEFT JOIN #no_soft_alloc_orders d
	ON		a.order_no = d.order_no
	AND		a.order_ext = d.order_ext
	WHERE	b.allocation_date <= getdate()
	AND		a.status = -3
	AND		d.order_no IS NULL
	AND		d.order_ext IS NULL

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
	JOIN	#sim_cvo_soft_alloc_det d (NOLOCK)
	ON		a.order_no = d.order_no
	AND		a.ext = d.order_ext
	WHERE	(b.allocation_date > getdate() 
		OR	CONVERT(varchar(10),ISNULL(a.sch_ship_date,GETDATE()),121) > CONVERT(varchar(10),GETDATE(),121))
	AND		d.status = -3
	AND		d.change <> 0

	INSERT	#exclusions (order_no, order_ext)
	SELECT	a.order_no, a.ext
	FROM	dbo.orders_all  a (NOLOCK)
	JOIN	#sim_cvo_soft_alloc_hdr b (NOLOCK)
	ON		a.order_no = b.order_no
	AND		a.ext = b.order_ext
	WHERE	b.status = 0
	AND		CONVERT(varchar(10),ISNULL(a.sch_ship_date,GETDATE()),121) > CONVERT(varchar(10),GETDATE(),121)

	INSERT	#exclusions (order_no, order_ext)
	SELECT	a.order_no, a.ext
	FROM	dbo.cvo_orders_all  a (NOLOCK)
	JOIN	#sim_cvo_soft_alloc_hdr b (NOLOCK)
	ON		a.order_no = b.order_no
	AND		a.ext = b.order_ext
	WHERE	b.status = 0
	AND		a.split_order = 'A'

	INSERT	#exclusions (order_no, order_ext)
	SELECT	a.order_no,
			a.ext
	FROM	orders_all a (NOLOCK)
	JOIN	#sim_cvo_soft_alloc_hdr b (NOLOCK)
	ON		a.order_no = b.order_no
	AND		a.ext = b.order_ext	
	WHERE	a.status = 'P'
	AND		b.status = 0

	DELETE	a
	FROM	#sim_cvo_soft_alloc_det a
	JOIN	#snapshot b
	ON		a.order_no = b.order_no
	AND		a.order_ext = b.order_ext
	LEFT JOIN ord_list c (NOLOCK)
	ON		a.order_no = c.order_no
	AND		a.order_ext = c.order_ext
	AND		a.line_no = c.line_no
	LEFT JOIN #sim_tdc_soft_alloc_tbl d (NOLOCK)
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
	FROM	#sim_cvo_soft_alloc_hdr a
	JOIN	#snapshot b
	ON		a.order_no = b.order_no
	AND		a.order_ext = b.order_ext
	LEFT JOIN #sim_cvo_soft_alloc_det c (NOLOCK)
	ON		a.order_no = c.order_no
	AND		a.order_ext = c.order_ext
	WHERE	a.status <> 1
	AND		c.order_no IS NULL
	AND		c.order_ext IS NULL

	EXEC cvo_check_stock_pre_allocation_sp

	DELETE	a
	FROM	#exclusions a
	JOIN	#sim_cvo_soft_alloc_det b (NOLOCK)
	ON		a.order_no = b.order_no
	AND		a.order_ext = b.order_ext
	WHERE	b.deleted = 1

	INSERT	#forced_orders (order_no, order_ext, status, hold_reason)
	SELECT	DISTINCT o.order_no, o.ext, o.status, o.hold_reason
	FROM	orders_all o (NOLOCK)
	JOIN	#sim_cvo_soft_alloc_det a (NOLOCK)
	ON		o.order_no = a.order_no
	AND		o.ext = a.order_ext
	JOIN	#sim_tdc_soft_alloc_tbl b (NOLOCK)
	ON		a.order_no = b.order_no
	AND		a.order_ext = b.order_ext
	AND		a.line_no = b.line_no
	JOIN	#exclusions c
	ON		a.order_no = c.order_no
	AND		a.order_ext = c.order_ext
	WHERE	o.status < 'Q'
	AND		a.change > 0

	INSERT	#forced_orders (order_no, order_ext, status, hold_reason)
	SELECT	DISTINCT o.order_no, o.ext, o.status, o.hold_reason
	FROM	orders_all o (NOLOCK)
	JOIN	#sim_cvo_soft_alloc_det a (NOLOCK)
	ON		o.order_no = a.order_no
	AND		o.ext = a.order_ext
	WHERE	o.status = 'P'
	AND		a.change = 2

	DELETE	a
	FROM	#exclusions a
	JOIN	#forced_orders b
	ON		a.order_no = b.order_no
	AND		a.order_ext = b.order_ext

	DELETE	a
	FROM	#exclusions a
	JOIN	#future_orders b
	ON		a.order_no = b.order_no
	AND		a.order_ext = b.order_ext

	UPDATE	a
	SET		status = 0
	FROM	#sim_cvo_soft_alloc_hdr a
	JOIN	#future_orders b
	ON		a.order_no = b.order_no
	AND		a.order_ext = b.order_ext

	UPDATE	a
	SET		status = 0
	FROM	#sim_cvo_soft_alloc_det a
	JOIN	#future_orders b
	ON		a.order_no = b.order_no
	AND		a.order_ext = b.order_ext

	UPDATE	a
	SET		status = -1
	FROM	#sim_cvo_soft_alloc_hdr a 
	JOIN	#sim_cvo_soft_alloc_det b (NOLOCK)
	ON		a.soft_alloc_no = b.soft_alloc_no
	LEFT JOIN #exclusions c
	ON		a.order_no = c.order_no
	AND		a.order_ext = c.order_ext
	JOIN	#snapshot d
	ON		a.order_no = d.order_no
	AND		a.order_ext = d.order_ext
	JOIN	orders_all o (NOLOCK)
	ON		a.order_no = o.order_no
	AND		a.order_ext = o.ext
	WHERE	a.status = 0
	AND		b.status = 0
	AND		a.bo_hold = 0
	AND		c.order_no IS NULL
	AND		c.order_ext IS NULL
	AND		(@start_date > CASE WHEN o.user_def_fld3 = '' THEN CONVERT(varchar(19),CONVERT(datetime,LEFT(date_entered,19)),121)
										ELSE CONVERT(varchar(19),CONVERT(datetime,LEFT(o.user_def_fld3,19)),121) END)
	UPDATE	a
	SET		status = -1
	FROM	#sim_cvo_soft_alloc_det a 
	JOIN	#sim_cvo_soft_alloc_hdr b (NOLOCK)
	ON		a.soft_alloc_no = b.soft_alloc_no
	WHERE	a.status = 0
	AND		b.status = -1

	IF NOT EXISTS (SELECT 1 FROM #sim_cvo_soft_alloc_hdr (NOLOCK) WHERE status = -1)
	BEGIN
		GOTO OUTPUT_RESULT
	END

	INSERT	#process_alloc (soft_alloc_no, order_no, order_ext, location)
	SELECT	DISTINCT soft_alloc_no, order_no, order_ext, location
	FROM	#sim_cvo_soft_alloc_hdr (NOLOCK)
	WHERE	status = -1
	ORDER BY soft_alloc_no ASC

	UPDATE	a
	SET		has_change = (SELECT MAX(CASE change WHEN 2 THEN 1 ELSE change END) FROM #sim_cvo_soft_alloc_det b (NOLOCK) WHERE b.soft_alloc_no = a.soft_alloc_no),
			has_kit = (SELECT MAX(kit_part) FROM #sim_cvo_soft_alloc_det b (NOLOCK) WHERE b.soft_alloc_no = a.soft_alloc_no),
			has_delete = (SELECT MAX(deleted) FROM #sim_cvo_soft_alloc_det b (NOLOCK) WHERE b.soft_alloc_no = a.soft_alloc_no)
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

		IF EXISTS (SELECT 1 FROM tdc_plw_orders_being_allocated (NOLOCK) WHERE order_no = @order_no AND order_ext = @order_ext)
		BEGIN
			UPDATE	#sim_cvo_soft_alloc_hdr 
			SET		status = 0
			WHERE	soft_alloc_no = @soft_alloc_no
			AND		status = -1	

			UPDATE	#sim_cvo_soft_alloc_det
			SET		status = 0
			WHERE	soft_alloc_no = @soft_alloc_no
			AND		status = -1	

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

		IF NOT (@has_change = 0 AND @has_delete = 0)
		BEGIN		
			SET @last_line_row = 0

			SELECT	TOP 1 @line_row = row_id,
					@line_no = line_no,
					@part_no = part_no,
					@quantity = quantity
			FROM	#sim_cvo_soft_alloc_det (NOLOCK)
			WHERE	soft_alloc_no = @soft_alloc_no
			AND		(change >= 1 OR deleted = 1)
			AND		kit_part = 0
			AND		status = -1
			AND		row_id > @last_line_row
			ORDER BY row_id ASC

			WHILE @@ROWCOUNT <> 0
			BEGIN
				IF EXISTS(SELECT 1 FROM #forced_orders WHERE order_no = @order_no AND order_ext = @order_ext)
				BEGIN
					IF (@has_delete = 1)
					BEGIN
						SET @error_messages = ''				
						EXEC dbo.cvo_sim_sa_plw_so_unallocate_sp @order_no, @order_ext, @line_no, @part_no, @error_messages OUTPUT, @cons_no OUTPUT	
					END
					ELSE
					BEGIN
						EXEC dbo.cvo_sim_process_alloc_changes_sp @order_no, @order_ext, @line_no, @quantity
					END
				END
				ELSE
				BEGIN
					SET @error_messages = ''				
					EXEC dbo.cvo_sim_sa_plw_so_unallocate_sp @order_no, @order_ext, @line_no, @part_no, @error_messages OUTPUT, @cons_no OUTPUT
				END

				SET @last_line_row = @line_row

				SELECT	TOP 1 @line_row = row_id,
						@line_no = line_no,
						@part_no = part_no,
						@quantity = quantity
				FROM	#sim_cvo_soft_alloc_det (NOLOCK)
				WHERE	soft_alloc_no = @soft_alloc_no
				AND		(change >= 1 OR deleted = 1)
				AND		kit_part = 0
				AND		status = -1
				AND		row_id > @last_line_row
				ORDER BY row_id ASC
			END
		END

		DELETE #no_stock_orders

		IF NOT EXISTS (SELECT 1 FROM #sim_cvo_soft_alloc_hdr (NOLOCK) WHERE soft_alloc_no = @soft_alloc_no AND status = -1)
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
	
		DELETE	a
		FROM	#sim_cvo_soft_alloc_det a
		JOIN	#snapshot b
		ON		a.order_no = b.order_no
		AND		a.order_ext = b.order_ext
		LEFT JOIN ord_list c (NOLOCK)
		ON		a.order_no = c.order_no
		AND		a.order_ext = c.order_ext
		AND		a.line_no = c.line_no
		LEFT JOIN #sim_tdc_soft_alloc_tbl d (NOLOCK)
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
		FROM	#sim_cvo_soft_alloc_hdr a
		JOIN	#snapshot b
		ON		a.order_no = b.order_no
		AND		a.order_ext = b.order_ext
		LEFT JOIN #sim_cvo_soft_alloc_det c (NOLOCK)
		ON		a.order_no = c.order_no
		AND		a.order_ext = c.order_ext
		WHERE	a.status <> 1
		AND		c.order_no IS NULL
		AND		c.order_ext IS NULL
		AND		a.order_no = @order_no
		AND		a.order_ext = @order_ext

		IF EXISTS (SELECT 1 FROM tdc_plw_orders_being_allocated (NOLOCK) WHERE order_no = @order_no AND order_ext = @order_ext)
		BEGIN
			UPDATE	#sim_cvo_soft_alloc_hdr
			SET		status = 0
			WHERE	soft_alloc_no = @soft_alloc_no
			AND		status = -1	

			UPDATE	#sim_cvo_soft_alloc_det
			SET		status = 0
			WHERE	soft_alloc_no = @soft_alloc_no
			AND		status = -1	

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

			CREATE TABLE #cons_alloc_count (
				order_no	int,
				order_ext	int)

			INSERT	#cons_alloc_count
			SELECT	DISTINCT a.order_no, a.order_ext
			FROM	#sim_tdc_soft_alloc_tbl a (NOLOCK)
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

			IF (@cur_con_count > @cur_con_count2) -- v7.1
			BEGIN
				UPDATE	#sim_cvo_soft_alloc_hdr
				SET		status = 0
				WHERE	soft_alloc_no = @soft_alloc_no
				AND		status = -1	

				UPDATE	#sim_cvo_soft_alloc_det
				SET		status = 0
				WHERE	soft_alloc_no = @soft_alloc_no
				AND		status = -1	

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

		EXEC @rc = sim_tdc_order_after_save @order_no, @order_ext   
		
		if (@rc = 0) 
		BEGIN

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

			INSERT	#orders_to_consolidate (consolidation_no, order_no, ext)
			SELECT	a.consolidation_no,
					b.order_no,
					b.order_ext
			FROM	cvo_masterpack_consolidation_hdr a (NOLOCK)
			JOIN	cvo_masterpack_consolidation_det b (NOLOCK)
			ON		a.consolidation_no = b.consolidation_no
			WHERE	b.order_no = @order_no
			AND		b.order_ext = @order_ext
			AND		a.type = 'BO'
			AND		a.shipped = 0

			IF EXISTS (	SELECT	1 
						FROM	#no_stock_orders a 
						JOIN	#sim_cvo_soft_alloc_det b (NOLOCK)
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
				IF EXISTS (SELECT 1 FROM #sim_cvo_soft_alloc_det a (NOLOCK) JOIN #no_stock_orders b ON a.order_no = b.order_no AND a.order_ext = b.order_ext
								AND a.line_no = b.line_no WHERE a.inv_avail = 1 AND b.no_stock = 1)
				BEGIN
					UPDATE	#sim_cvo_soft_alloc_hdr
					SET		status = 0
					WHERE	soft_alloc_no = @soft_alloc_no

					UPDATE	#sim_cvo_soft_alloc_det
					SET		status = 0
					WHERE	soft_alloc_no = @soft_alloc_no

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
		END
		
		IF EXISTS (SELECT 1 FROM #sim_tdc_soft_alloc_tbl (NOLOCK) WHERE order_no = @order_no AND order_ext = @order_ext AND location = @location AND order_type = 'S') 
		BEGIN

			SELECT	@curr_ordered = SUM(a.ordered)
			FROM	ord_list a (NOLOCK)
			WHERE	a.order_no = @order_no
			AND		a.order_ext = @order_ext

			SELECT	@curr_alloc = SUM(qty)
			FROM	#sim_tdc_soft_alloc_tbl (NOLOCK)
			WHERE	order_no = @order_no
			AND		order_ext = @order_ext
			AND		order_type = 'S'

			SELECT	@curr_alloc_pct = (@curr_alloc / @curr_ordered) * 100

			SELECT	@back_ord_flag = back_ord_flag,
					@status = status, 
					@user_category = user_category
			FROM	orders_all (NOLOCK)
			WHERE	order_no = @order_no
			AND		ext = @order_ext

			IF (@curr_alloc_pct < 100) AND (@status < 'Q') 
			BEGIN
				IF (@back_ord_flag = 1)
				BEGIN
					-- UnAllocate any item that did allocate
					EXEC cvo_sim_UnAllocate_sp @order_no, @order_ext, 0, 'AUTO_ALLOC'

					-- Reset the soft allocation
					UPDATE	#sim_cvo_soft_alloc_hdr
					SET		status = 0
					WHERE	soft_alloc_no = @soft_alloc_no

					UPDATE	#sim_cvo_soft_alloc_det
					SET		status = 0
					WHERE	soft_alloc_no = @soft_alloc_no

					EXEC dbo.cvo_sim_unallocate_cons_orders_hold @soft_alloc_no, @order_no, @order_ext, @back_ord_flag

				END
				ELSE
				BEGIN
					SELECT	@fs_ordered = SUM(a.ordered)
					FROM	ord_list a (NOLOCK)
					JOIN	inv_master b (NOLOCK)
					ON		a.part_no = b.part_no
					WHERE	a.order_no = @order_no
					AND		a.order_ext = @order_ext
					AND		b.type_code IN ('FRAME','SUN')

					SELECT	@fs_allocated = SUM(a.qty)
					FROM	#sim_tdc_soft_alloc_tbl a (NOLOCK)
					JOIN	inv_master b (NOLOCK)
					ON		a.part_no = b.part_no
					WHERE	a.order_no = @order_no
					AND		a.order_ext = @order_ext
					AND		a.order_type = 'S'
					AND		b.type_code IN ('FRAME','SUN')

					SET @fill_rate = (@fs_allocated / @fs_ordered) * 100

					IF ((@fill_rate < @fill_rate_level) AND LEFT(@user_category,2) = 'ST') AND @order_ext = 0
					BEGIN
						EXEC dbo.cvo_sim_UnAllocate_sp @order_no, @order_ext, 0, 'AUTO_ALLOC'

						EXEC dbo.cvo_sim_unallocate_cons_orders_hold @soft_alloc_no, @order_no, @order_ext, @back_ord_flag -- v8.1

					END
					ELSE
					BEGIN

						UPDATE	#sim_cvo_soft_alloc_hdr
						SET		status = -2
						WHERE	order_no = @order_no
						AND		order_ext = @order_ext
						AND		status = -1	

						UPDATE	#sim_cvo_soft_alloc_det
						SET		status = -2
						WHERE	order_no = @order_no
						AND		order_ext = @order_ext
						AND		status = -1	

						DELETE	#sim_cvo_soft_alloc_hdr
						WHERE	order_no = @order_no
						AND		order_ext = @order_ext
						AND		status = -2

						DELETE	#sim_cvo_soft_alloc_det
						WHERE	order_no = @order_no
						AND		order_ext = @order_ext
						AND		status = -2

					END
				END
			END
		END
		ELSE
		BEGIN
			UPDATE	#sim_cvo_soft_alloc_hdr
			SET		status = 0
			WHERE	soft_alloc_no = @soft_alloc_no
			AND		status = -1	

			UPDATE	#sim_cvo_soft_alloc_det
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

		UPDATE	#sim_cvo_soft_alloc_hdr
		SET		status = -2
		WHERE	order_no = @order_no
		AND		order_ext = @order_ext
		AND		status = -1	

		UPDATE	#sim_cvo_soft_alloc_det
		SET		status = -2
		WHERE	order_no = @order_no
		AND		order_ext = @order_ext
		AND		status = -1	

		DELETE	#sim_cvo_soft_alloc_hdr
		WHERE	order_no = @order_no
		AND		order_ext = @order_ext
		AND		status = -2

		DELETE	#sim_cvo_soft_alloc_det
		WHERE	order_no = @order_no
		AND		order_ext = @order_ext
		AND		status = -2

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

	CREATE TABLE #bo_holds (
		rec_id		INT IDENTITY (1,1),
		order_no	INT,
		order_ext	INT)

	INSERT	INTO #bo_holds(order_no, order_ext)
	SELECT	DISTINCT a.order_no, a.order_ext
	FROM	#sim_cvo_soft_alloc_hdr a (NOLOCK)
	JOIN	#sim_cvo_soft_alloc_det b (NOLOCK)
	ON		a.soft_alloc_no = b.soft_alloc_no
	WHERE	ISNULL(a.bo_hold,0) = 1
	AND		a.status NOT IN (1,-1)
	AND		(b.deleted = 1 OR b.change > 0)
	ORDER BY a.order_no, a.order_ext

	SET @rec_id = 0
	WHILE 1=1
	BEGIN
		
		SELECT	TOP 1 @rec_id = rec_id,
				@order_no = order_no,
				@order_ext = order_ext
		FROM	#bo_holds
		WHERE	rec_id > @rec_id
		ORDER BY rec_id

		IF @@ROWCOUNT = 0
			BREAK

		IF EXISTS(SELECT 1 FROM #sim_cvo_soft_alloc_hdr (NOLOCK) WHERE order_no = @order_no AND order_ext = @order_ext AND status NOT IN (-1,1))
		BEGIN
			EXEC dbo.cvo_sim_process_alloc_changes_sp @order_no, @order_ext
		END
	END

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

					EXEC dbo.cvo_sim_UnAllocate_sp @order_no, @order_ext, 0, 'AUTO_ALLOC', 1

				END
			END

			SET @last_stcons_no = @stcons_no

			SELECT	TOP 1 @stcons_no = consolidation_no
			FROM	#orders_to_consolidate
			WHERE	consolidation_no > @last_stcons_no
			ORDER BY consolidation_no ASC

		END		
	END

	UPDATE	a
	SET		status = b.alloc_status
	FROM	#sim_cvo_soft_alloc_hdr a
	JOIN	#future_orders b
	ON		a.order_no = b.order_no
	AND		a.order_ext = b.order_ext

	UPDATE	a
	SET		status = b.alloc_status
	FROM	#sim_cvo_soft_alloc_hdr a
	JOIN	#future_orders b
	ON		a.order_no = b.order_no
	AND		a.order_ext = b.order_ext


	INSERT	dbo.cvo_allocation_simulation_summary_hdr (user_spid, bin_group, alloc_qty)
	SELECT	@user_spid, 
			b.group_code,
			SUM(a.qty)
	FROM	#sim_tdc_soft_alloc_tbl a
	JOIN	tdc_bin_master b (NOLOCK)
	ON		a.location = b.location
	AND		a.bin_no = b.bin_no
	LEFT JOIN #tmp_tdc_soft_alloc_tbl c
	ON		a.order_no = c.order_no 
	AND		a.order_ext = c.order_ext 
	AND		a.line_no = c.line_no
	WHERE	c.order_no IS NULL 
	AND		c.order_ext IS NULL 
	AND		c.line_no IS NULL
	GROUP BY b.group_code

	INSERT	dbo.cvo_allocation_simulation_summary_det (user_spid, bin_group, part_no, bin_no, alloc_qty)
	SELECT	@user_spid,
			b.group_code,
			a.part_no,
			a.bin_no,
			SUM(a.qty)
	FROM	#sim_tdc_soft_alloc_tbl a
	JOIN	tdc_bin_master b (NOLOCK)
	ON		a.location = b.location
	AND		a.bin_no = b.bin_no
	LEFT JOIN #tmp_tdc_soft_alloc_tbl c
	ON		a.order_no = c.order_no 
	AND		a.order_ext = c.order_ext 
	AND		a.line_no = c.line_no
	WHERE	c.order_no IS NULL 
	AND		c.order_ext IS NULL 
	AND		c.line_no IS NULL
	GROUP BY b.group_code, a.part_no, a.bin_no
	
	INSERT	dbo.cvo_allocation_simulation_detail (user_spid, order_no, order_ext, order_no_ext, cust_code, cust_name, ship_date, 
		order_type, so_priority, cust_type, promotion, part_no, qty, bin_no, bin_type)
	SELECT	@user_spid,
			a.order_no,
			a.order_ext,
			CAST(a.order_no as varchar(20)) + '-' + CAST(a.order_ext as varchar(10)),
			c.cust_code,
			c.ship_to_name,
			CONVERT(varchar(10),c.sch_ship_date,103),
			c.user_category,
			c.so_priority_code,
			d.addr_sort1,
			ISNULL(f.promo_name,''),
			a.part_no,
			a.qty,
			a.bin_no,
			b.group_code
	FROM	#sim_tdc_soft_alloc_tbl a
	JOIN	tdc_bin_master b (NOLOCK)
	ON		a.location = b.location
	AND		a.bin_no = b.bin_no
	JOIN	orders_all c (NOLOCK)
	ON		a.order_no = c.order_no
	AND		a.order_ext = c.ext
	JOIN	arcust d (NOLOCK)
	ON		c.cust_code = d.customer_code
	JOIN	cvo_orders_all e (NOLOCK)
	ON		a.order_no = e.order_no
	AND		a.order_ext = e.ext	
	LEFT JOIN cvo_promotions f (NOLOCK)
	ON		e.promo_id = f.promo_id
	AND		e.promo_level = f.promo_level
	LEFT JOIN #tmp_tdc_soft_alloc_tbl g
	ON		a.order_no = g.order_no 
	AND		a.order_ext = g.order_ext 
	AND		a.line_no = g.line_no
	WHERE	g.order_no IS NULL 
	AND		g.order_ext IS NULL 
	AND		g.line_no IS NULL

	INSERT	dbo.cvo_allocation_simulation_detail (user_spid, order_no, order_ext, order_no_ext, cust_code, cust_name, ship_date, 
		order_type, so_priority, cust_type, promotion, part_no, qty, bin_no, bin_type)
	SELECT	@user_spid,
			a.trans_type_no,
			a.trans_type_ext,
			CAST(a.trans_type_no as varchar(20)) + '-' + CAST(a.trans_type_ext as varchar(10)),
			c.cust_code,
			c.ship_to_name,
			CONVERT(varchar(10),c.sch_ship_date,103),
			c.user_category,
			c.so_priority_code,
			d.addr_sort1,
			ISNULL(f.promo_name,''),
			a.part_no,
			a.qty_to_process,
			a.bin_no,
			b.group_code
	FROM	#sim_tdc_pick_queue a
	JOIN	tdc_bin_master b (NOLOCK)
	ON		a.location = b.location
	AND		a.bin_no = b.bin_no
	JOIN	orders_all c (NOLOCK)
	ON		a.trans_type_no = c.order_no
	AND		a.trans_type_ext = c.ext
	JOIN	arcust d (NOLOCK)
	ON		c.cust_code = d.customer_code
	JOIN	cvo_orders_all e (NOLOCK)
	ON		a.trans_type_no = e.order_no
	AND		a.trans_type_ext = e.ext	
	LEFT JOIN cvo_promotions f (NOLOCK)
	ON		e.promo_id = f.promo_id
	AND		e.promo_level = f.promo_level
	LEFT JOIN #tmp_tdc_pick_queue g
	ON		a.tran_id = g.tran_id
	WHERE	g.tran_id IS NULL 
	AND		a.trans = 'MGTB2B'
/*
	select a.* from #sim_tdc_soft_alloc_tbl a (NOLOCK)
	left join #tmp_tdc_soft_alloc_tbl b
	on a.order_no = b.order_no and a.order_ext = b.order_ext and a.line_no = b.line_no
	where b.order_no is null and b.order_ext is null and b.line_no is null

	select a.* from #sim_tdc_pick_queue a (NOLOCK)
	left join #tmp_tdc_pick_queue b
	on a.tran_id = b.tran_id 
	where b.tran_id is null
*/
	OUTPUT_RESULT:

	DROP TABLE #forced_orders
	DROP TABLE #future_orders
	DROP TABLE #future_fl_check	
	DROP TABLE #orders_to_consolidate
	DROP TABLE #sim_cvo_soft_alloc_hdr
	DROP TABLE #sim_cvo_soft_alloc_det
	DROP TABLE #process_alloc
	DROP TABLE #exclusions
	DROP TABLE #line_exclusions
	DROP TABLE #no_stock_orders	
	DROP TABLE #snapshot
	DROP TABLE #no_soft_alloc_orders
	DROP TABLE #sim_tdc_soft_alloc_tbl
	DROP TABLE #sim_tdc_pick_queue
	DROP TABLE #sim_tdc_main
	DROP TABLE #sim_tdc_cons_ords
	DROP TABLE #inserted
	DROP TABLE #deleted	
	DROP TABLE #tmp_tdc_soft_alloc_tbl
	DROP TABLE #tmp_tdc_pick_queue
END
GO
GRANT EXECUTE ON  [dbo].[cvo_allocation_simulation_sp] TO [public]
GO
