SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/************************************************************************/
/* Name:	tdc_calc_carton_value_sp	        	      	*/
/*									*/
/* Module:	WMS							*/
/*						      			*/
/* Input:	carton_no 				      		*/
/*					      				*/
/*				      					*/
/*							      		*/
/*							      		*/
/* Output:        none					     	 	*/
/*									*/
/*									*/
/* Description:								*/
/*	This SP will be called to calculate the cost of the all items	*/
/*	packed into a carton with a COD freight type. The value is the 	*/
/*	sum of the price of each item after the discounts have been 	*/
/*	applied.							*/
/*									*/
/* Revision History:							*/
/* 	Date		Who	Description				*/
/*	----		---	-----------				*/
/* 	10/01/2000	KMH	Initial					*/
/*									*/
/************************************************************************/
-- v1.1 CB 19/10/2012 - Tax Issue - When closing the carton need to recalc tax and totals incase it is short shipped.
-- v1.2 CB 31/01/2013 - Remove v1.1 at CVO's request
-- v1.3 CB 12/06/2013 - Issue #965 - Tax Calculation
CREATE PROCEDURE [dbo].[tdc_calc_carton_value_sp](
  @carton_no int
)

AS

DECLARE @ord_no  int,
	@ord_ext int,
	@part_no varchar (30),
	@line_no int,
	@qty int,
	@calc_item_price decimal (20, 8),
	@sum_price decimal (20, 8),
	@item_tax decimal (20, 8),
	@order_type char(1)
	
	

BEGIN


SELECT @ord_no = order_no, @ord_ext = order_ext, @order_type = order_type FROM tdc_carton_tx where carton_no = @carton_no
SELECT @sum_price = 0

-- v1.3 Start
IF EXISTS (SELECT 1 FROM orders_all (NOLOCK) WHERE order_no = @ord_no AND ext = @ord_ext AND ISNULL(tax_valid_ind,0) = 0)
BEGIN
	EXEC dbo.fs_calculate_oetax_wrap @ord_no, @ord_ext, 0, -1

	EXEC dbo.fs_updordtots @ord_no, @ord_ext
END


IF @order_type = 'S'
BEGIN
	DECLARE next_item CURSOR FOR
		SELECT DISTINCT part_no, line_no FROM tdc_carton_detail_tx (nolock) WHERE carton_no = @carton_no ORDER BY part_no
	
			OPEN next_item
			FETCH NEXT FROM next_item into @part_no, @line_no
			WHILE(@@FETCH_STATUS = 0)
			BEGIN
	
				SELECT @qty = 0
				SELECT @calc_item_price = 0
				SELECT @item_tax = 0
	
				SELECT @qty = sum(pack_qty) FROM tdc_carton_detail_tx (nolock) WHERE carton_no = @carton_no AND
				part_no = @part_no AND line_no = @line_no
	
				SELECT @calc_item_price = (price * ((100 - discount)/ 100)), @item_tax = (total_tax/shipped)
				FROM ord_list WHERE order_no = @ord_no AND order_ext = @ord_ext AND part_no = @part_no 
				AND line_no = @line_no
				AND shipped > 0					--v3.0  because of cases do not include non shipped items
	
				SELECT @sum_price = (@sum_price + ((@calc_item_price + @item_tax) * @qty))
	
				FETCH NEXT FROM next_item into @part_no, @line_no
			END
	
	CLOSE next_item
	DEALLOCATE next_item

-- v1.2 Start
	-- v1.1 Call the tax routine
--	EXEC dbo.fs_calculate_oetax_wrap @ord_no, @ord_ext, 0, -1

	-- -- v1.1 Update the order totals
--	EXEC dbo.fs_updordtots @ord_no, @ord_ext
-- v1.2 End
END

UPDATE tdc_carton_tx SET carton_content_value = @sum_price WHERE carton_no = @carton_no

END
GO
GRANT EXECUTE ON  [dbo].[tdc_calc_carton_value_sp] TO [public]
GO
