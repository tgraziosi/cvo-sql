SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[tdc_get_order_hdr_status_wrap]  @order_no integer,@ext integer  AS
BEGIN

DECLARE @msg  varchar(100)

exec  dbo.tdc_get_order_hdr_status	@order_no, @ext, @msg OUTPUT

SELECT @msg

END


GO
GRANT EXECUTE ON  [dbo].[tdc_get_order_hdr_status_wrap] TO [public]
GO
