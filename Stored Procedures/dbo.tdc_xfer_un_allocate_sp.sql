SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[tdc_xfer_un_allocate_sp] @order_no int
AS
	/* Determine if any of the transactions on the queue are being processed.  If so, then rollback the update. */
	/* Otherwise, continue on and update the queue by deleting all the applicable pick transactions for the order being unallocated */
	if exists (select * from tdc_pick_queue (nolock)
				where trans = 'XFERPICK'
				and trans_type_no = @order_no
				and trans_type_ext = 0
				and tx_lock != 'R')
	BEGIN
		RAISERROR ('Pick transaction is locked on the Queue.  Unable to unallocate.', 16, 1)
		RETURN -101
	END

	BEGIN TRANSACTION
	
	delete from tdc_pick_queue 
	where trans = 'XFERPICK'
	and trans_type_no = @order_no
	and trans_type_ext = 0
	
	if (@@error <> 0)  
	begin
		if (@@trancount > 0)
			rollback
		RETURN -102
	end

	DELETE FROM tdc_soft_alloc_tbl
	WHERE order_no = @order_no
	and order_ext = 0
	AND order_type = 'T'

	if (@@error <> 0)  
	begin
		if (@@trancount > 0)
			rollback
		RETURN -103
	end

	DELETE FROM tdc_pick_queue
	WHERE qty_to_process <= 0

	if (@@error <> 0)  
	begin
		if (@@trancount > 0)
			rollback
		RETURN -104
	end

	DELETE FROM tdc_cons_ords
	WHERE order_no = @order_no
	and order_ext = 0
	AND order_type = 'T'

	if (@@error <> 0)  
	begin
		if (@@trancount > 0)
			rollback
		RETURN -105
	end

	DELETE tdc_cons_filter_set 
	WHERE tdc_cons_filter_set.consolidation_no NOT IN (SELECT consolidation_no FROM tdc_cons_ords (NOLOCK) )

	if (@@error <> 0)  
	begin
		if (@@trancount > 0)
			rollback
		RETURN -106
	end

	DELETE tdc_main 
	WHERE tdc_main.consolidation_no NOT IN (SELECT consolidation_no FROM tdc_cons_ords (NOLOCK) )

	if (@@error <> 0)  
	begin
		if (@@trancount > 0)
			rollback
		RETURN -107
	end

	COMMIT TRANSACTION
	
	RETURN 0

GO
GRANT EXECUTE ON  [dbo].[tdc_xfer_un_allocate_sp] TO [public]
GO
