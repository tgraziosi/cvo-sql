SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*                        						*/
/* This SP is used to set the status of an order / extension in ADM	*/
/*									*/
/* Given the order / extension / new_type it will call			*/
/* tdc_set_status						*/
/*									*/
/*									*/
/* 06/26/1998	Initial		GCJ					*/
/*									*/

CREATE PROCEDURE [dbo].[tdc_update_unit_status_sp]
AS
	DECLARE @err int, @new_type varchar (3), @order_no int, @order_ext int

	/* Initialize the error code to no errors */
	SELECT @err = 0

	/* Get new type */
	SELECT @order_no = (SELECT order_no FROM #dist_unit_status)
	SELECT @order_ext = (SELECT order_ext FROM #dist_unit_status)
	SELECT @new_type = (SELECT new_type FROM #dist_unit_status)

	EXEC tdc_set_status @order_no, @order_ext, @new_type
	
RETURN @err
GO
GRANT EXECUTE ON  [dbo].[tdc_update_unit_status_sp] TO [public]
GO
