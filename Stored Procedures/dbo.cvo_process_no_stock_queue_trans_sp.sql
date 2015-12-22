SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[cvo_process_no_stock_queue_trans_sp] @parent_tran_id INT, @child_tran_id INT  -- pass in child_tran_id of -1 to only remove the parent soft alloc record
AS
BEGIN
	SET NOCOUNT ON

	DECLARE @qty_remaining DECIMAL(20,8), 
			@qty_processed DECIMAL(20,8)

	IF @parent_tran_id = @child_tran_id
	BEGIN
		IF NOT EXISTS (SELECT 1 FROM dbo.tdc_pick_queue (NOLOCK) WHERE tran_id = @child_tran_id)
		BEGIN
			DELETE FROM CVO_no_stock_linked_pick_trans WHERE tran_id = @child_tran_id AND parent_tran_id = @parent_tran_id
		END

		RETURN
	END

-- v1.1 Start
	-- If parent soft alloc record exists (and parent doesn't exist as child record), delete it
--	IF NOT EXISTS (SELECT 1 FROM CVO_no_stock_linked_pick_trans WHERE tran_id = @parent_tran_id AND parent_tran_id = @parent_tran_id)
--	BEGIN
--		DELETE
--			a
--		FROM
--			dbo.tdc_soft_alloc_tbl a
--		INNER JOIN
--			dbo.tdc_pick_queue b (NOLOCK)
--		ON
--			a.location = b.location
--			AND a.part_no = b.part_no
--			AND a.bin_no = b.bin_no
--			AND a.lot_ser = b.lot
--		WHERE
--			b.tran_id = @parent_tran_id
--			AND a.order_type = 'S'
--			AND a.order_no <> 0
--	END
-- v1.1 End
	IF @child_tran_id = -1
	BEGIN
		RETURN
	END

	-- Delete relationship record
	DELETE FROM CVO_no_stock_linked_pick_trans WHERE tran_id = @child_tran_id AND parent_tran_id = @parent_tran_id

	-- Get qty left to pick
	SELECT
		@qty_remaining = SUM(a.qty_to_process)
	FROM
		dbo.tdc_pick_queue a (NOLOCK)
	INNER JOIN
		dbo.CVO_no_stock_linked_pick_trans b (NOLOCK)
	ON
		a.tran_id = b.tran_id
	WHERE
		b.parent_tran_id = @parent_tran_id
	
	IF ISNULL(@qty_remaining,0) > 0 
	BEGIN
		SELECT 
			@qty_processed = qty_to_process - @qty_remaining
		FROM
			dbo.tdc_pick_queue (NOLOCK)
		WHERE
			tran_id = @parent_tran_id

		-- Update parent
		UPDATE
			dbo.tdc_pick_queue
		SET
			qty_to_process = @qty_remaining,
			qty_processed = qty_processed + @qty_processed
		WHERE
			tran_id = @parent_tran_id
	END
	ELSE
	BEGIN
		-- Delete parent if no more child records exist
		DELETE FROM
			dbo.tdc_pick_queue 
		WHERE
			tran_id = @parent_tran_id
	END
END
GO
GRANT EXECUTE ON  [dbo].[cvo_process_no_stock_queue_trans_sp] TO [public]
GO
