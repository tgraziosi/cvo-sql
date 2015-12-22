SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*
Simple function to allow users enter #indexNumber in the kit item field on 
Packout similar to #lineNum in the part field.
*/

CREATE PROCEDURE [dbo].[tdc_get_kitItem_at_Index_sp] (
  @order_no int, 
  @order_ext int, 
  @line_no int,
  @PartIndex int,
  @Part varchar(30) OUTPUT
  )
AS
	DECLARE @Min_Row_ID int
	SELECT @Min_Row_ID = min(row_id) from ord_list_kit where order_no = @order_no and order_ext = @order_ext and line_no = @line_no
	SELECT @Part = part_no FROM ord_list_kit WHERE  order_no = @order_no and order_ext = @order_ext 
		and line_no = @line_no and row_id = @Min_Row_ID + @PartIndex-1
select @Part 
return
GO
GRANT EXECUTE ON  [dbo].[tdc_get_kitItem_at_Index_sp] TO [public]
GO
