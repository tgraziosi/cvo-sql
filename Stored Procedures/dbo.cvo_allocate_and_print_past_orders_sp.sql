SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


-- v1.0 CT 24/03/2014 - Issue #1459 - Automate the allocation and pick ticket print of past orders

-- EXEC dbo.cvo_allocate_and_print_past_orders_sp 



CREATE PROC [dbo].[cvo_allocate_and_print_past_orders_sp]  

AS

SET ANSI_WARNINGS OFF;

BEGIN

	SET NOCOUNT ON

	-- Allocate orders
	EXEC dbo.cvo_auto_alloc_past_orders_sp 'ZZ'

	-- Print pick tickets
	EXEC dbo.cvo_auto_print_pick_tickets_sp 'ZZ'

END


GO
GRANT EXECUTE ON  [dbo].[cvo_allocate_and_print_past_orders_sp] TO [public]
GO
