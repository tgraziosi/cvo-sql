SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- EXEC dbo.cvo_update_bo_processing_sp 'A', 1421062, 0

CREATE PROCEDURE [dbo].[cvo_update_bo_processing_sp]	@upd_type	char(1), -- A = Allocate, P = Printing
													@order_no	int,
													@order_ext	int
AS
BEGIN
	--DIRECTIVES
	SET NOCOUNT ON

	-- PROCESSING
	IF (@upd_type = 'A')
	BEGIN
		-- #1 - Allocating - Check what has allocated and update and mark records in the cvo_backorder_processing_orders_ringfenced_stock table
		IF EXISTS (SELECT 1 FROM tdc_soft_alloc_tbl (NOLOCK) WHERE order_no = @order_no AND order_ext = @order_ext AND order_type = 'S')
		BEGIN
			UPDATE	cvo_backorder_processing_orders_ringfenced_stock
			SET		qty_processed = qty_ringfenced,
					status = 2
			WHERE	order_no = @order_no
			AND		ext = @order_ext
		END	
		
	END

	-- #2 - Printing - Update the cvo_backorder_processing_pick_tickets table and mark as printed
	IF (@upd_type = 'P')
	BEGIN
		UPDATE	cvo_backorder_processing_pick_tickets
		SET		printed = 1,
				printed_date = GETDATE(),
				reason = 'Manually Printed'
		WHERE	order_no = @order_no
		AND		ext = @order_ext
		AND		is_transfer = 0	
		AND		printed = 0	
	END

END
GO
GRANT EXECUTE ON  [dbo].[cvo_update_bo_processing_sp] TO [public]
GO
