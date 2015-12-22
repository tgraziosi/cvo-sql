SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[tdc_get_order_list_status_wrap] @order_no integer, @ext integer,	@line_no integer  AS

BEGIN

DECLARE @msg varchar(100)

Exec tdc_get_order_list_status  @order_no, @ext,  @line_no,  @msg OUTPUT

Select @msg

END



GO
GRANT EXECUTE ON  [dbo].[tdc_get_order_list_status_wrap] TO [public]
GO
