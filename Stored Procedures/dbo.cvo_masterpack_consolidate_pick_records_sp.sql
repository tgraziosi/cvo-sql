SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*
CREATE TABLE #consolidate_picks(
		consolidation_no	INT,
		order_no			INT,
		ext					INT)

-- Populate table with orders to be consolidated
*/

-- v1.0 CT 02/04/2014 - Issue #572 - Masterpack consolidation of pick records
-- v1.1 CB 15/01/2015 - Stop duplicate parent records being created
-- v1.2 CB 31/07/2015 - If orders in set are printed then reset
-- v1.3 CB 08/06/2016 - Split out manual case qty
-- v1.4 CB 15/06/2016 - Fix issue with multiple case lines
-- v1.5 CB 11/07/2016 - Fix issue when order has manual case quantities
-- v1.6 CB 24/08/2016 - CVO-CF-49 - Dynamic Custom Frames

CREATE PROC [dbo].[cvo_masterpack_consolidate_pick_records_sp] @consolidation_no INT
AS
BEGIN
	SET NOCOUNT ON

	DECLARE @rec_id				INT,
			@tran_id			INT,
			@priority			INT, 
			@seq_no				INT,
			@row_id				int, -- v1.3
			@c_order_no			int, -- v1.3
			@c_ext				int, -- v1.3
			@location			varchar(10), -- v1.3
			@part_no			varchar(30), -- v1.3
			@alloc_qty			decimal(20,8), -- v1.3
			@man_qty			decimal(20,8), -- v1.3
			@man_line			int, -- v1.3
			@row_id2			int -- v1.3

	IF NOT EXISTS(SELECT 1 FROM #consolidate_picks)
	BEGIN
		RETURN
	END

	-- Create temporary tables
	CREATE TABLE #picks(
		tran_id				INT,
		order_no			INT,
		ext					INT,
		location			VARCHAR(10),
		part_no				VARCHAR(30),
		lot					VARCHAR(25),
		bin_no				VARCHAR(12),
		priority			INT,
		pcsn				INT,
		qty_to_process		DECIMAL(20,8),
		is_case				INT,
		line_no				int, -- v1.3
		man_line			int) -- v1.3

	CREATE TABLE #pick_group(
		rec_id				INT IDENTITY(1,1),
		location			VARCHAR(10),
		part_no				VARCHAR(30),
		lot					VARCHAR(25),
		bin_no				VARCHAR(12),
		priority			INT,
		pcsn				INT,
		qty_to_process		DECIMAL(20,8),
		tran_id				INT,
		man_qty				decimal(20,8), -- v1.3
		man_line			int) -- v1.3

	-- Get picks for these orders
	INSERT INTO #picks(
		tran_id,
		order_no,
		ext,
		location,
		part_no,
		lot,
		bin_no,
		priority,
		pcsn,
		qty_to_process,
		is_case,
		line_no) -- v1.3
	SELECT
		a.tran_id,
		a.trans_type_no,
		a.trans_type_ext,
		a.location,
		a.part_no,
		a.lot,
		a.bin_no,
		a.priority,
		a.pcsn,
		a.qty_to_process,
		ISNULL(c.is_case,0),
		a.line_no -- v1.3
	FROM
		dbo.tdc_pick_queue a (NOLOCK)
	INNER JOIN
		#consolidate_picks b (NOLOCK)
	ON
		a.trans_type_no = b.order_no
		AND a.trans_type_ext = b.ext
	INNER JOIN
		dbo.cvo_ord_list c (NOLOCK)
	ON
		a.trans_type_no = c.order_no
		AND a.trans_type_ext = c.order_ext
		AND a.line_no = c.line_no
	WHERE
		a.trans = 'STDPICK'

	-- v1.6 Start
	DELETE	a
	FROM	#picks a
	JOIN	ord_list b (NOLOCK)
	ON		a.order_no = b.order_no
	AND		a.ext = b.order_ext
	AND		a.line_no = b.line_no
	WHERE	b.part_type = 'C'

	IF NOT EXISTS(SELECT 1 FROM #picks)
	BEGIN
		RETURN
	END
	-- v1.6 End

	-- v1.3 Start
	IF OBJECT_ID('tempdb..#cvo_ord_list') IS NOT NULL
		DROP TABLE #cvo_ord_list

	-- Create working table for autopick cases
	CREATE TABLE #cvo_ord_list (
		order_no		int,
		order_ext		int,
		line_no			int,
		add_case		varchar(1),
		add_pattern		varchar(1),
		from_line_no	int,
		is_case			int,
		is_pattern		int,
		add_polarized	varchar(1),
		is_polarized	int,
		is_pop_gif		int,
		is_amt_disc		varchar(1),
		amt_disc		decimal(20,8),
		is_customized	varchar(1),
		promo_item		varchar(1),
		list_price		decimal(20,8),
		orig_list_price	decimal(20,8),
		ordered			decimal(20,8), 
		man_qty			decimal(20,8),
		location		varchar(10), 
		part_no			varchar(30),
		alloc_qty		decimal(20,8)) 	


	-- Call routine to populate #cvo_ord_list with the frame/case relationship for each order in consolidation set
	SET @row_id = 0
	WHILE 1=1 
	BEGIN
		
		SELECT	TOP 1 @row_id = row_id,
				@c_order_no = order_no,
				@c_ext = order_ext
		FROM	dbo.cvo_masterpack_consolidation_det (NOLOCK)
		WHERE	row_id > @row_id
		AND		consolidation_no = @consolidation_no -- v10.2
		ORDER BY row_id

		IF @@ROWCOUNT = 0
			BREAK

		EXEC CVO_create_fc_relationship_sp @c_order_no, @c_ext
	END


	UPDATE	a
	SET		ordered = b.ordered,
			location = b.location,
			part_no = b.part_no
	FROM	#cvo_ord_list a
	JOIN	ord_list b (NOLOCK) 
	ON		a.order_no = b.order_no 
	AND		a.order_ext = b.order_ext 
	AND		a.line_no = b.line_no


	-- v1.4 Start
	CREATE TABLE #man_sum(
		order_no	int,
		order_ext	int,
		line_no		int,
		man_qty		decimal(20,8),
		from_line_no int) -- v1.5

	INSERT	#man_sum
	SELECT	a.order_no, a.order_ext, a.line_no, a.ordered - SUM(b.ordered), MAX(a.from_line_no) -- v1.5
	FROM	#cvo_ord_list a
	JOIN	#cvo_ord_list b
	ON		a.order_no = b.order_no 
	AND		a.order_ext = b.order_ext 
	AND		a.from_line_no = b.line_no
	GROUP BY a.order_no, a.order_ext, a.line_no, a.ordered
	
	UPDATE	a
	SET		man_qty = b.man_qty
	FROM	#cvo_ord_list a
	JOIN	#man_sum b
	ON		a.order_no = b.order_no
	AND		a.order_ext = b.order_ext
	AND		a.line_no = b.line_no
	AND		a.from_line_no = b.from_line_no -- v1.5

--	UPDATE	a
--	SET		man_qty = a.ordered - b.ordered
--	FROM	#cvo_ord_list a
--	JOIN	#cvo_ord_list b
--	ON		a.order_no = b.order_no 
--	AND		a.order_ext = b.order_ext 
--	AND		a.from_line_no = b.line_no
	-- v1.4 End

	UPDATE	a
	SET		man_line = 1
	FROM	#picks a
	JOIN	#cvo_ord_list b
	ON		a.order_no = b.order_no
	AND		a.ext = b.order_ext
	AND		a.line_no = b.line_no
	WHERE	ISNULL(b.man_qty,0) > 0


	IF OBJECT_ID('tempdb..#pick_sum') IS NOT NULL
		DROP TABLE #pick_sum

	CREATE TABLE #pick_sum (
		order_no		int,
		order_ext		int,
		location		varchar(10),
		part_no			varchar(30),
		line_no			int,
		alloc_qty		decimal(20,8))

	INSERT	#pick_sum
	SELECT	order_no,
			ext,
			location,
			part_no,
			line_no,
			SUM(qty_to_process)
	FROM	#picks
	GROUP BY order_no,
			ext,
			location,
			part_no,
			line_no

	UPDATE	a
	SET		alloc_qty = b.alloc_qty
	FROM	#cvo_ord_list a
	JOIN	#pick_sum b
	ON		a.order_no = b.order_no
	AND		a.order_ext = b.order_ext
	AND		a.line_no = b.line_no

	-- v1.4 Start
	TRUNCATE TABLE #man_sum
	
	INSERT	#man_sum
	SELECT	a.order_no, a.order_ext, a.line_no, a.alloc_qty - SUM(b.alloc_qty), MAX(a.from_line_no) -- v1.5
	FROM	#cvo_ord_list a
	JOIN	#cvo_ord_list b
	ON		a.order_no = b.order_no 
	AND		a.order_ext = b.order_ext 
	AND		a.from_line_no = b.line_no
	GROUP BY a.order_no, a.order_ext, a.line_no, a.alloc_qty

	UPDATE	a
	SET		man_qty = b.man_qty
	FROM	#cvo_ord_list a
	JOIN	#man_sum b
	ON		a.order_no = b.order_no 
	AND		a.order_ext = b.order_ext 
	AND		a.line_no = b.line_no
	AND		a.from_line_no = b.from_line_no

--	UPDATE	a
--	SET		man_qty = a.alloc_qty - b.alloc_qty
--	FROM	#cvo_ord_list a
--	JOIN	#cvo_ord_list b
--	ON		a.order_no = b.order_no 
--	AND		a.order_ext = b.order_ext 
--	AND		a.from_line_no = b.line_no

	DROP TABLE #man_sum
	-- v1.4 End

	IF OBJECT_ID('tempdb..#man_pick') IS NOT NULL
		DROP TABLE #man_pick	

	CREATE TABLE #man_pick (
		row_id		int IDENTITY(1,1),
		location	varchar(10),
		part_no		varchar(30),
		man_qty		decimal(20,8))

	INSERT	#man_pick (location, part_no, man_qty)
	SELECT	location,
			part_no,
			SUM(ISNULL(man_qty,0))
	FROM	#cvo_ord_list
	WHERE	ISNULL(man_qty,0) > 0
	GROUP BY location,
			part_no
	-- v1.3 End

	-- v1.1 Start
	DELETE	a
	FROM	#picks a
	JOIN	cvo_masterpack_consolidation_picks b (NOLOCK)
	ON		a.tran_id = b.child_tran_id	
	-- v1.1 End

	IF NOT EXISTS(SELECT 1 FROM #picks)
	BEGIN
		RETURN
	END

	-- Consolidate the picks
	INSERT INTO #pick_group(
		location,
		part_no,
		lot,
		bin_no,
		priority,
		pcsn,
		qty_to_process,
		tran_id)
	SELECT
		location,
		part_no,
		lot,
		bin_no,
		MIN(priority),
		pcsn,
		SUM(qty_to_process),
		MIN(tran_id)
	FROM
		#picks
	GROUP BY
		location,
		part_no,
		lot,
		bin_no,
		pcsn,
		is_case

	IF NOT EXISTS(SELECT 1 FROM #pick_group)
	BEGIN
		RETURN
	END

	-- v1.3 Start
	IF EXISTS (SELECT 1 FROM #man_pick)
	BEGIN

		CREATE TABLE #man_sort (
			row_id		int IDENTITY(1,1),
			tran_id		int,
			location	varchar(10),
			part_no		varchar(30))

		SET @row_id = 0		

		WHILE 1=1 
		BEGIN
		
			SELECT	TOP 1 @row_id = row_id,
					@location = location,
					@part_no = part_no,
					@man_qty = man_qty
			FROM	#man_pick
			WHERE	row_id > @row_id
			ORDER BY row_id

			IF @@ROWCOUNT = 0
				BREAK

			SET @tran_id = 9999999
			TRUNCATE TABLE #man_sort

			INSERT	#man_sort (tran_id, location, part_no)
			SELECT	tran_id, location, part_no
			FROM	#pick_group
			WHERE	location = @location
			AND		part_no = @part_no
			ORDER BY qty_to_process DESC

			SET @row_id2 = 0

			WHILE (@man_qty > 0)
			BEGIN	

				SELECT	TOP 1 @row_id2 = row_id,
						@tran_id = tran_id
				FROM	#man_sort
				WHERE	row_id > @row_id2
				ORDER BY row_id ASC
		
				IF (@row_id2 IS NULL)
				BEGIN
					BREAK
				END
				
				SELECT	@alloc_qty = qty_to_process
				FROM	#pick_group 
				WHERE	tran_id = @tran_id

				IF (@alloc_qty > @man_qty)
				BEGIN
					UPDATE	#pick_group
					SET		man_qty = @man_qty
					WHERE	tran_id = @tran_id

					SET @man_qty = 0

				END
				ELSE
				BEGIN
					UPDATE	#pick_group
					SET		man_qty = @alloc_qty
					WHERE	tran_id = @tran_id

					SET @man_qty = @man_qty - @alloc_qty

				END

			END

		END

		DROP TABLE #man_sort

		INSERT INTO #pick_group(location, part_no, lot, bin_no, priority, pcsn, qty_to_process, tran_id, man_line)
		SELECT	location, part_no, lot, bin_no, priority, pcsn, man_qty, tran_id, 1
		FROM	#pick_group
		WHERE	ISNULL(man_qty,0) <> 0

	END
	-- v1.3 End

	-- Loop through groups
	SET @rec_id = 0
	SET @tran_id = 0 -- v1.3
	WHILE 1=1
	BEGIN
		SELECT TOP 1
			@rec_id = rec_id,
			@priority = priority,
			@man_line = ISNULL(man_line,0) -- v1.3
		FROM
			#pick_group
		WHERE
			rec_id > @rec_id
		ORDER BY
			rec_id
	
		IF @@ROWCOUNT = 0
			BREAK


		-- Create new pick queue record
		EXEC @seq_no = tdc_queue_get_next_seq_num 'tdc_pick_queue', @priority 

		INSERT INTO tdc_pick_queue (
			trans_source, 
			trans, 
			priority, 
			seq_no, 
			location, 
			trans_type_no, 
			trans_type_ext, 
			line_no, 
			part_no,   
			lot,
			qty_to_process, 
			qty_processed, 
			qty_short,
			next_op, 
			bin_no,
			pcsn, 
			date_time, 
			assign_group, 
			tx_control, 
			tx_lock,
			mp_consolidation_no,
			company_no) -- v1.3  
		SELECT 
			b.trans_source, 
			b.trans, 
			@priority, 
			@seq_no, 
			b.location, 
			NULL, 
			NULL, 
			NULL, 
			a.part_no,   
			a.lot,
			CASE WHEN a.qty_to_process - ISNULL(a.man_qty,0) = 0 THEN a.qty_to_process ELSE a.qty_to_process - ISNULL(a.man_qty,0) END, -- v1.3 
			0, 
			0,
			b.next_op, 
			a.bin_no,
			a.pcsn, 
			b.date_time, 
			b.assign_group, 
			'M', 
			'R',
			@consolidation_no,
			CASE WHEN a.man_line = 1 THEN '1' ELSE NULL END -- v1.3
		FROM
			#pick_group a
		INNER JOIN
			dbo.tdc_pick_queue b (NOLOCK)
		ON
			a.tran_id = b.tran_id
		WHERE
			a.rec_id = @rec_id

		SET @tran_id = @@IDENTITY

		-- Load details into cross reference table
		IF (@man_line = 0) -- v1.3 
		BEGIN
			INSERT INTO dbo.cvo_masterpack_consolidation_picks(
				consolidation_no,
				parent_tran_id,
				child_tran_id)
			SELECT
				@consolidation_no,
				@tran_id,
				b.tran_id
			FROM
				#pick_group a
			INNER JOIN
				#picks b
			ON
				a.location = b.location
				AND a.part_no = b.part_no
				AND a.lot = b.lot
				AND a.bin_no = b.bin_no
			WHERE
				a.rec_id = @rec_id
		END
		ELSE
		BEGIN -- v1.3 Start
			INSERT INTO dbo.cvo_masterpack_consolidation_picks(
				consolidation_no,
				parent_tran_id,
				child_tran_id)
			SELECT
				@consolidation_no,
				@tran_id,
				b.tran_id
			FROM
				#pick_group a
			INNER JOIN
				#picks b
			ON
				a.location = b.location
				AND a.part_no = b.part_no
				AND a.lot = b.lot
				AND a.bin_no = b.bin_no
				AND	a.man_line = b.man_line
			WHERE
				a.rec_id = @rec_id
			AND
				a.man_line = @man_line
		END
		-- v1.3 End


		-- Mark child records as being hidden
		UPDATE
			a
		SET
			assign_user_id = 'HIDDEN'
		FROM
			dbo.tdc_pick_queue a
		INNER JOIN
			dbo.cvo_masterpack_consolidation_picks b (NOLOCK)
		ON
			a.tran_id = b.child_tran_id
		WHERE
			b.consolidation_no = @consolidation_no
			AND b.parent_tran_id = @tran_id

		-- v1.6 Start
		UPDATE	a
		SET		mp_consolidation_no = @consolidation_no
		FROM	tdc_pick_queue a
		JOIN	cvo_masterpack_consolidation_det b (NOLOCK)
		ON		a.trans_type_no = b.order_no
		AND		a.trans_type_ext = b.order_ext
		JOIN	ord_list c (NOLOCK)
		ON		a.trans_type_no = c.order_no
		AND		a.trans_type_ext = c.order_ext
		AND		a.line_no = c.line_no
		WHERE	b.consolidation_no = @consolidation_no
		AND		a.trans = 'STDPICK'
		AND		a.mp_consolidation_no IS NULL
		AND		ISNULL(a.assign_user_id,'') <> 'HIDDEN'
		AND		c.part_type = 'C'
		-- v1.6 End

	END


	DROP TABLE #picks
	DROP TABLE #pick_group

	-- v1.2 Start
	UPDATE	a
	SET		status = 'N',
			printed = 'N',
			date_printed = NULL
	FROM	orders_all a WITH (ROWLOCK)
	JOIN	cvo_masterpack_consolidation_det b (NOLOCK)
	ON		a.order_no = b.order_no
	AND		a.ext = b.order_ext
	WHERE	b.consolidation_no = @consolidation_no
	AND		a.status = 'Q'
	-- v1.2 End
	
END

GO
GRANT EXECUTE ON  [dbo].[cvo_masterpack_consolidate_pick_records_sp] TO [public]
GO
