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

CREATE PROC [dbo].[cvo_masterpack_consolidate_pick_records_sp] @consolidation_no INT
AS
BEGIN
	SET NOCOUNT ON

	DECLARE @rec_id				INT,
			@tran_id			INT,
			@priority			INT, 
			@seq_no				INT

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
		is_case				INT)

	CREATE TABLE #pick_group(
		rec_id				INT IDENTITY(1,1),
		location			VARCHAR(10),
		part_no				VARCHAR(30),
		lot					VARCHAR(25),
		bin_no				VARCHAR(12),
		priority			INT,
		pcsn				INT,
		qty_to_process		DECIMAL(20,8),
		tran_id				INT)

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
		is_case)
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
		ISNULL(c.is_case,0)
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
		
	-- Loop through groups
	SET @rec_id = 0
	WHILE 1=1
	BEGIN
		SELECT TOP 1
			@rec_id = rec_id,
			@priority = priority
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
			mp_consolidation_no)  
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
			a.qty_to_process, 
			0, 
			0,
			b.next_op, 
			a.bin_no,
			a.pcsn, 
			b.date_time, 
			b.assign_group, 
			'M', 
			'R',
			@consolidation_no
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
