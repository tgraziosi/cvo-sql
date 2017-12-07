SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


-- v1.0 CT 24/03/2014 - Issue #1459 - Automate the allocation and pick ticket print of past orders
-- v1.1 CB 07/11/2017 - Add process info for tdc_log

-- EXEC dbo.cvo_allocate_and_print_past_orders_sp 
CREATE PROC [dbo].[cvo_allocate_and_print_past_orders_sp]  

AS
BEGIN

	SET NOCOUNT ON

	EXEC dbo.cvo_auto_alloc_process_sp 1, 'cvo_allocate_and_print_past_orders_sp' -- v1.1

	-- Allocate orders
	EXEC dbo.cvo_auto_alloc_past_orders_sp 'ZZ'

	-- Print pick tickets
	EXEC dbo.cvo_auto_print_pick_tickets_sp 'ZZ'

	EXEC dbo.cvo_auto_alloc_process_sp 0 -- v1.1

END

GO
GRANT EXECUTE ON  [dbo].[cvo_allocate_and_print_past_orders_sp] TO [public]
GO
