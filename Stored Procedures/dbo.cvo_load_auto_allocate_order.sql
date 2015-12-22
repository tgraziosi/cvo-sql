SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[cvo_load_auto_allocate_order] ( @order_no INT, @order_ext INT)
AS
BEGIN
 DECLARE @rc INT
  BEGIN
	EXEC @rc = tdc_order_after_save @order_no, @order_ext
  END
  SELECT @rc
END
GO
GRANT EXECUTE ON  [dbo].[cvo_load_auto_allocate_order] TO [public]
GO
