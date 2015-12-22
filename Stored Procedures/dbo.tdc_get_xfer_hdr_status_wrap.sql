SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[tdc_get_xfer_hdr_status_wrap] @xfer_no integer   AS
BEGIN

DECLARE 	@msg varchar(100)

Exec  tdc_get_xfer_hdr_status  @xfer_no, @msg OUTPUT

SELECT @msg

END

GO
GRANT EXECUTE ON  [dbo].[tdc_get_xfer_hdr_status_wrap] TO [public]
GO
