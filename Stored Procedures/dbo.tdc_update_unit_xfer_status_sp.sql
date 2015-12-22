SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*                        						*/
/* This SP is used to set the status of an order / extension in ADM	*/
/*									*/
/* Given the order / extension / new_type it will call			*/
/* tdc_set_status						        */
/*									*/
/*									*/
/* 10/07/1998	Initial		HTL					*/
/*									*/

CREATE PROCEDURE [dbo].[tdc_update_unit_xfer_status_sp]
AS
	DECLARE @err int, @new_type varchar (3), @xfer_no int, @xfer_ext int

	/* Initialize the error code to no errors */
	SELECT @err = 0

	/* Get new type */
	SELECT @xfer_no = (SELECT order_no FROM #dist_unit_status)
	SELECT @xfer_ext = (SELECT order_ext FROM #dist_unit_status)
	SELECT @new_type = (SELECT new_type FROM #dist_unit_status)

	EXEC tdc_set_xfer_status @xfer_no, @new_type
	
RETURN @err
GO
GRANT EXECUTE ON  [dbo].[tdc_update_unit_xfer_status_sp] TO [public]
GO
