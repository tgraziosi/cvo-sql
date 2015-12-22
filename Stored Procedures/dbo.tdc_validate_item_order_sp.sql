SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/*                        					  */
/* Simple Stored Procedure that returns a 1 if the Part Number    */
/* is associated as a line item on the Platinum Ord_list table.   */
/*								  */
/* 04/14/1998	Initial		CAC				  */
/*								  */

CREATE PROCEDURE [dbo].[tdc_validate_item_order_sp] (
  @order_no int, 
  @order_ext int, 
  @part_no varchar(30),
  @line_no int OUTPUT
  )
AS
	/* Declare local variables */
	DECLARE @tline_no int

	SELECT @tline_no = 0

	/*
	 * Check the Platinum Orders Detail Table.
	 * Be careful here.  It's possible to have the same part
	 * on different line items.  Need to be able to handle 
	 * this in the future.
	 */
	SELECT @tline_no=line_no
	  FROM ord_list
         WHERE order_no = @order_no
	   AND order_ext = @order_ext
	   AND part_no = @part_no

	SELECT @line_no = @tline_no
	RETURN @tline_no
GO
GRANT EXECUTE ON  [dbo].[tdc_validate_item_order_sp] TO [public]
GO
