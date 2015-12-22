SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[tdc_cust_kit_units_packed_sp] 
	@order_no 	int, 
	@order_ext 	int, 
	@carton_no 	int,
	@line_no 	int 

 
AS

DECLARE @qty int, 
	@ret int

SELECT @ret = -1


-- Loop through the minimum number of kit components packed that are enough to make a complete kit.
-- For instance, if qty_per is 5 for part 'A' and 11 are packed, 
-- The cursor will return 2
DECLARE item_pack_cur
CURSOR FOR
	SELECT (SELECT FLOOR((SELECT SUM(pack_qty) 
		  	FROM tdc_carton_detail_tx (NOLOCK)
		       WHERE ((ISNULL(@carton_no, 0) = 0) OR carton_no = @carton_no)
			 AND order_no  = a.order_no
		   	 AND order_ext = a.order_ext
		   	 AND line_no   = a.line_no
		   	 AND (part_no = a.kit_part_no OR part_no IN(SELECT sub_kit_part_no 
								      FROM tdc_ord_list_kit c(NOLOCK) 
		   						     WHERE c.order_no = a.order_no 
								       AND c.order_ext = a.order_ext 
								       AND c.line_no = a.line_no 
								       AND c.kit_part_no = a.kit_part_no))))
		/ a.qty_per_kit) 
	  FROM tdc_ord_list_kit a(NOLOCK)
	 WHERE a.order_no  = @order_no
	   AND a.order_ext = @order_ext
	   AND a.line_no   = @line_no
	   AND a.sub_kit_part_no IS NULL
OPEN item_pack_cur

FETCH NEXT FROM item_pack_cur INTO @qty
WHILE @@FETCH_STATUS = 0
BEGIN
	-- If the qty packed < all other quantities, set the return value
	IF @ret > ISNULL(@qty, 0) SELECT @ret = ISNULL(@qty, 0)
 
	-- If the return value not initalized to a positive value, initialize it
	IF @ret = -1 SELECT @ret = ISNULL(@qty, 0)

	FETCH NEXT FROM item_pack_cur INTO @qty
END
CLOSE item_pack_cur
DEALLOCATE item_pack_cur
 
RETURN @ret

GO
GRANT EXECUTE ON  [dbo].[tdc_cust_kit_units_packed_sp] TO [public]
GO
