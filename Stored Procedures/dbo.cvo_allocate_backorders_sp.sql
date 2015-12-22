SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[cvo_allocate_backorders_sp]	@order_no	int,
											@order_ext	int
AS
BEGIN

	EXEC dbo.tdc_order_after_save_wrap @order_no, @order_ext

END
GO
GRANT EXECUTE ON  [dbo].[cvo_allocate_backorders_sp] TO [public]
GO
