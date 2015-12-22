SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/*                        					  */
/* JVC Pack Verification Order Inquiry - This sp will take as     */
/* input the sales order and extension and return the number of   */
/* cartons packed for this order and the calculated weight.       */
/*								  */
/* 10/15/1998	Initial		CAC				  */
/*								  */

CREATE PROCEDURE [dbo].[tdc_get_order_weight] (
  @order_type char(1),
  @in_order_no int, 
  @in_order_ext int, 
  @out_carton_cnt int OUTPUT,
  @out_order_weight decimal(20, 8) OUTPUT
  )
AS
	/* Declare local variables */
	DECLARE @err int
	DECLARE @tmpcnt int
	DECLARE @tmpwt decimal(20, 8)

	SELECT @err = 0
	SELECT @tmpcnt = 0
	SELECT @tmpwt = 0.0

	/*
	 * Count the number of unique carton's associate with this order.
	 */
	SELECT @tmpcnt=count(distinct carton_no)
	  FROM tdc_carton_tx
         WHERE order_no = @in_order_no
	   AND order_ext = @in_order_ext
	   AND order_type = @order_type

	/*
	 * Assign output parameter.
	 */
	SELECT @out_carton_cnt = @tmpcnt


	/*
	 * Calculate the weight associated with the cartons.
	 */
	SELECT @tmpwt=convert(decimal(20,8), sum(weight))
	  FROM tdc_carton_tx
	 WHERE order_no = @in_order_no
	   AND order_ext = @in_order_ext
	   AND order_type = @order_type

	/*
	 * Assign output parameter
	 */
	SELECT @out_order_weight = @tmpwt

RETURN @err
GO
GRANT EXECUTE ON  [dbo].[tdc_get_order_weight] TO [public]
GO
