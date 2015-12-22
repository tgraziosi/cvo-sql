SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[tdc_get_xfer_list_status_wrap]   @xfer_no integer, @line_no integer   AS


BEGIN

DECLARE @msg varchar(100)

Exec dbo.tdc_get_xfer_list_status @xfer_no, 	@line_no, @msg  OUTPUT 

Select @msg

END
GO
GRANT EXECUTE ON  [dbo].[tdc_get_xfer_list_status_wrap] TO [public]
GO
