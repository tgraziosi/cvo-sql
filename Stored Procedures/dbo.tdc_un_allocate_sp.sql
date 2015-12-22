SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[tdc_un_allocate_sp]
AS
	DECLARE @order_no INT
	DECLARE @order_ext INT
	DECLARE @part_no VARCHAR(35)
	DECLARE @bin_no VARCHAR(12)
	DECLARE @location VARCHAR(10)
--	DECLARE @who VARCHAR(50)

--	SELECT @who = who FROM #temp_who
	SELECT @order_no = order_no, @order_ext = order_ext FROM #temp_un_allocate

	DECLARE item_unallocate_cursor CURSOR FOR
		SELECT part_no, bin_no, location
			FROM tdc_soft_alloc_tbl (NOLOCK)
				WHERE order_no = @order_no 
				AND order_ext = @order_ext
				AND order_type = 'S'

	OPEN item_unallocate_cursor
	FETCH NEXT FROM item_unallocate_cursor INTO @part_no, @bin_no, @location

--BEGIN TRANSACTION

	WHILE (@@FETCH_STATUS = 0)
	BEGIN
		/* Determine if any of the transactions on the queue are being processed.  If so, then rollback the update. */
		/* Otherwise, continue on AND update the queue by deleting all the applicable pick transactions for the order being unallocated */
		IF EXISTS (SELECT * FROM tdc_pick_queue (NOLOCK)
					WHERE trans = 'STDPICK'
					AND trans_type_no = @order_no
					AND trans_type_ext = @order_ext
					AND location = @location
					AND tx_lock NOT IN ('R', '3'))
		BEGIN
			DEALLOCATE item_unallocate_cursor
			RAISERROR ('Pick transaction is locked on the Queue.  Unable to unallocate.',16, 1)
--    			ROLLBACK TRANSACTION
			RETURN -101
		END
	
		DELETE FROM tdc_pick_queue 
		WHERE trans = 'STDPICK'
		AND trans_type_no = @order_no
		AND trans_type_ext = @order_ext
		AND location = @location
	
		/* Determine if any of the transactions on the queue are being processed.  If so, then rollback the update. */
		/* Otherwise, continue on AND update the queue by deleting all the applicable pick transactions for the order being unallocated */
		IF EXISTS (SELECT * FROM tdc_pick_queue (NOLOCK)
					WHERE trans = 'PLWB2B'
					AND trans_type_no = @order_no
					AND trans_type_ext = @order_ext
					AND location = @location
					AND part_no = @part_no
					AND bin_no = @bin_no
					AND tx_lock NOT IN ('R', '3')
					AND trans_type_no in (SELECT consolidation_no 
								FROM tdc_cons_ords (NOLOCK)
								WHERE order_no = @order_no
								AND order_ext = @order_ext
								AND location = @location
								AND order_type = 'S'))
		BEGIN
			DEALLOCATE item_unallocate_cursor
			RAISERROR ('PLW Bin to Bin transaction is locked on the Queue.  Unable to unallocate.',16, 1)
    	--		ROLLBACK TRANSACTION
			RETURN -102
		END
	
		UPDATE tdc_pick_queue
		SET qty_to_process = qty_to_process - ISNULL((SELECT SUM(qty)
								FROM tdc_soft_alloc_tbl
								WHERE order_no = @order_no
								AND order_ext = @order_ext
								AND location = @location
								AND part_no = @part_no
								AND order_type = 'S'
								AND bin_no = @bin_no), 0)
		WHERE trans = 'PLWB2B'
		AND EXISTS (SELECT * FROM tdc_cons_ords (NOLOCK)
					WHERE order_no = @order_no
					AND order_ext = @order_ext
					AND location = @location
					AND order_type = 'S')

		FETCH NEXT FROM item_unallocate_cursor INTO @part_no, @bin_no, @location
	END

	DEALLOCATE item_unallocate_cursor

	DELETE FROM tdc_soft_alloc_tbl
	WHERE order_no = @order_no
	AND order_ext = @order_ext
	AND order_type = 'S'

	DELETE FROM tdc_pick_queue
	WHERE qty_to_process <= 0

	INSERT INTO tdc_cons_ords_arch 
	SELECT * FROM tdc_cons_ords  
	WHERE order_no = @order_no
	AND order_ext = @order_ext
	AND order_type = 'S'

	DELETE FROM tdc_cons_ords
	WHERE order_no = @order_no
	AND order_ext = @order_ext
	AND order_type = 'S'

	DELETE tdc_cons_filter_set 
	WHERE tdc_cons_filter_set.consolidation_no NOT IN (SELECT consolidation_no FROM tdc_cons_ords (NOLOCK) )

	DELETE tdc_main 
	WHERE tdc_main.consolidation_no NOT IN (SELECT consolidation_no FROM tdc_cons_ords (NOLOCK) )

	DELETE FROM tdc_tote_bin_tbl
	WHERE order_no = @order_no
	AND order_ext = @order_ext
	AND order_type = 'S'

--	COMMIT TRANSACTION
	
	RETURN

GO
GRANT EXECUTE ON  [dbo].[tdc_un_allocate_sp] TO [public]
GO
