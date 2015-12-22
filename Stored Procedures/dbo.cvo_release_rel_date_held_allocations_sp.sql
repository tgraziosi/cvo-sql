SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[cvo_release_rel_date_held_allocations_sp]	@order_no int,
															@order_ext int
AS
BEGIN
	SET NOCOUNT ON

	EXEC dbo.cvo_hold_rel_date_allocations_sp @order_no, @order_ext

END
GO
GRANT EXECUTE ON  [dbo].[cvo_release_rel_date_held_allocations_sp] TO [public]
GO
