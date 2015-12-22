SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[cvo_hold_ship_complete_xfer_allocations_sp]	@xfer_no	int
AS
BEGIN

	-- Is the transfer set to ship complete
	IF EXISTS (SELECT 1 FROM dbo.xfers_all (NOLOCK) 
				WHERE xfer_no = @xfer_no AND back_ord_flag = 1)
	BEGIN
		-- Are there any items that have not been allocated
		IF EXISTS (SELECT 1 FROM dbo.xfer_list a (NOLOCK) LEFT JOIN dbo.tdc_pick_queue b (NOLOCK) 
					ON a.xfer_no = b.trans_type_no AND a.line_no = b.line_no AND a.part_no = b.part_no
					WHERE b.line_no IS NULL AND b.part_no IS NULL
					AND a.xfer_no = @xfer_no AND a.shipped < a.ordered)
		BEGIN
			-- Update the pick queue records and place them on hold

			-- If record on manual hold then flag
			UPDATE	tdc_pick_queue
			SET		mfg_lot = CASE WHEN mfg_lot IS NULL THEN 1 ELSE mfg_lot END
			WHERE	trans_type_no = @xfer_no
			AND		trans = 'XFERPICK'
			AND		tx_lock = 'H'
			AND		PATINDEX('%SHIP_COMP%',ISNULL(mfg_batch,'')) = 0

			-- update with the ship complete hold when not on a manual hold
			UPDATE	tdc_pick_queue
			SET		tx_lock = 'H',
					mfg_batch =	CASE WHEN mfg_batch IS NULL THEN 'SHIP_COMP'
									 WHEN (PATINDEX('%SHIP_COMP%',ISNULL(mfg_batch,'')) > 0) THEN mfg_batch END 
			WHERE	trans_type_no = @xfer_no
			AND		trans = 'XFERPICK'
			AND		mfg_lot IS NULL
			AND		PATINDEX('%HOLD%',ISNULL(mfg_batch,'')) = 0

			-- update with the ship complete hold when it is on a manual hold
			UPDATE	tdc_pick_queue
			SET		tx_lock = 'H',
					mfg_lot = CASE WHEN mfg_lot IS NULL THEN 1 ELSE mfg_lot END,
					mfg_batch =	CASE WHEN mfg_batch IS NULL THEN 'SHIP_COMP,HOLD'
									 WHEN (PATINDEX('%SHIP_COMP%',ISNULL(mfg_batch,'')) > 0) THEN mfg_batch + ',HOLD' END 
			WHERE	trans_type_no = @xfer_no
			AND		trans = 'XFERPICK'
			AND		mfg_lot IS NOT NULL
			AND		PATINDEX('%HOLD%',ISNULL(mfg_batch,'')) = 0

			-- update with the ship complete hold when it is on a previous manual hold
			UPDATE	tdc_pick_queue
			SET		tx_lock = 'H',
					mfg_lot = CASE WHEN mfg_lot IS NULL THEN 1 ELSE mfg_lot END,
					mfg_batch =	CASE WHEN mfg_batch IS NULL THEN 'SHIP_COMP'
									 WHEN (PATINDEX('%SHIP_COMP%',ISNULL(mfg_batch,'')) > 0) THEN mfg_batch
									 WHEN (PATINDEX('%SHIP_COMP%',ISNULL(mfg_batch,'')) = 0) THEN mfg_batch + ',SHIP_COMP' END 
			WHERE	trans_type_no = @xfer_no
			AND		trans = 'XFERPICK'
			AND		PATINDEX('%HOLD%',ISNULL(mfg_batch,'')) > 0
			

			RETURN -1 -- So that the pick ticket does not print

		END
	END

	-- if processing has reached here then either the order is not set to ship complete or it has been taken
	-- off ship complete in which case we check if the queue records have SHIP_COMP set and remove it or
	-- the allocation is fully available

	UPDATE	a
	SET		tx_lock = 'R', 
			mfg_batch = NULL
	FROM	dbo.tdc_pick_queue a 
	WHERE	a.trans = 'XFERPICK'
	AND		a.trans_type_no = @xfer_no
	AND		PATINDEX('%SHIP_COMP%',mfg_batch) > 0
	AND		PATINDEX('%HOLD%',mfg_batch) = 0
	AND		ISNULL(mfg_lot, 0) <> 2

	UPDATE	a
	SET		mfg_batch = NULL
	FROM	dbo.tdc_pick_queue a 
	WHERE	a.trans = 'XFERPICK'
	AND		a.trans_type_no = @xfer_no
	AND		PATINDEX('%SHIP_COMP%',mfg_batch) > 0
	AND		PATINDEX('%HOLD%',mfg_batch) = 0
	AND		ISNULL(mfg_lot, 0) = 2

	UPDATE	a
	SET		mfg_batch = REPLACE(mfg_batch,',SHIP_COMP', '')
	FROM	dbo.tdc_pick_queue a 
	WHERE	a.trans = 'XFERPICK'
	AND		a.trans_type_no = @xfer_no
	AND		PATINDEX('%,SHIP_COMP%',mfg_batch) > 0


	UPDATE	a
	SET		mfg_batch = NULL
	FROM	dbo.tdc_pick_queue a 
	WHERE	a.trans = 'XFERPICK'
	AND		a.trans_type_no = @xfer_no
	AND		PATINDEX('%SHIP_COMP%',mfg_batch) > 0
	AND		PATINDEX('%HOLD%',mfg_batch) > 0


	UPDATE	a
	SET		tx_lock = 'H', 
			mfg_batch = NULL
	FROM	dbo.tdc_pick_queue a 
	WHERE	a.trans = 'XFERPICK'
	AND		a.trans_type_no = @xfer_no
	AND		PATINDEX('%SHIP_COMP%',mfg_batch) > 0
	AND		PATINDEX('%HOLD%',mfg_batch) = 0
	AND		ISNULL(mfg_lot,0) = 2


	RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[cvo_hold_ship_complete_xfer_allocations_sp] TO [public]
GO
