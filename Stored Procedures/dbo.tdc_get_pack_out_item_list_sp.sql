SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[tdc_get_pack_out_item_list_sp] 
	@dist_method 	char(2), 
	@order_no 	int, 
	@order_ext 	int, 
	@carton_no 	int, 
	@order_type 	char(1)
AS

DECLARE @line_no      int,
	@cur_packed   decimal(20,8),
	@total_packed decimal(20,8)

-----------------------------------------------------------------------------------------------------------------------------
-- Sales Orders
-----------------------------------------------------------------------------------------------------------------------------
IF @order_type = 'S' 
BEGIN
	-- Clear the temp table
	TRUNCATE TABLE #tdc_pack_out_item

	-- Do the insert 
	INSERT INTO #tdc_pack_out_item (line_no, display_line, part_no, [description], ordered, picked, carton, cum_packed, cur_packed, status)
	SELECT a.line_no, a.display_line, a.part_no, a.[description], a.ordered, a.shipped, @carton_no,
		total_packed = ISNULL((SELECT SUM(b.pack_qty)
				  FROM tdc_carton_detail_tx b,
				       tdc_carton_tx c
				 WHERE b.order_no = a.order_no
				   AND b.order_ext = a.order_ext
				   AND b.line_no = a.line_no
				   AND b.part_no = a.part_no
				   AND c.carton_no = b.carton_no
				   AND c.order_type = @order_type
				 GROUP BY b.order_no, b.order_ext, b.line_no, b.part_no), 0),
	
		cur_packed = CASE WHEN @carton_no = 0
				  THEN 0
				  ELSE
					ISNULL((SELECT SUM(d.pack_qty)
					   FROM tdc_carton_detail_tx d,
				                tdc_carton_tx e
					  WHERE d.carton_no = @carton_no
					    AND d.order_no = a.order_no
					    AND d.order_ext = a.order_ext
					    AND d.line_no = a.line_no
					    AND d.part_no = a.part_no
					    AND e.carton_no = d.carton_no
					    AND e.order_type = @order_type
				          GROUP BY d.order_no, d.order_ext, d.line_no, d.part_no), 0)
			     END,
		a.status
	  FROM ord_list a 
	 WHERE a.order_no =  @order_no
	   AND a.order_ext = @order_ext

	-----------------------------------------------------------------------------------------------------------------------------
	-- Logic for kits
	-----------------------------------------------------------------------------------------------------------------------------
	DECLARE kits_packed_cur CURSOR FOR 
		SELECT line_no 
		  FROM #tdc_pack_out_item
		 WHERE line_no IN(SELECT line_no 
				    FROM ord_list_kit
				   WHERE order_no = @order_no
				     AND order_ext = @order_ext)
	OPEN kits_packed_cur
	FETCH NEXT FROM kits_packed_cur INTO @line_no
	
	WHILE @@FETCH_STATUS = 0
	BEGIN
		SELECT @total_packed = 0, @cur_packed = 0

		-- Get the total packed for the line
		EXEC   @total_packed = tdc_cust_kit_units_packed_sp @order_no, @order_ext, 0, @line_no

		-- Get the current total for the carton
		IF @carton_no != 0 EXEC   @cur_packed = tdc_cust_kit_units_packed_sp @order_no, @order_ext, @carton_no, @line_no

		UPDATE #tdc_pack_out_item 
		   SET cum_packed = @total_packed,
		       cur_packed = @cur_packed
		 WHERE line_no    = @line_no 

		FETCH NEXT FROM kits_packed_cur INTO @line_no
	END

	CLOSE kits_packed_cur
	DEALLOCATE kits_packed_cur


END
-----------------------------------------------------------------------------------------------------------------------------
-- Transfers
-----------------------------------------------------------------------------------------------------------------------------
ELSE IF @order_type = 'T' 
BEGIN
	-- Clear the temp table
	TRUNCATE TABLE #tdc_pack_out_item_xfer

	-- Do the insert 
	INSERT INTO #tdc_pack_out_item_xfer (line_no, part_no, [description], ordered, picked, carton, cum_packed, cur_packed, status)
	SELECT a.line_no, a.part_no, a.[description], a.ordered, a.shipped, @carton_no,
		total_packed = ISNULL((SELECT SUM(b.pack_qty)
				  FROM tdc_carton_detail_tx b,
				       tdc_carton_tx c
				 WHERE b.order_no = a.xfer_no
				   AND b.order_ext = 0
				   AND b.line_no = a.line_no
				   AND b.part_no = a.part_no
				   AND c.carton_no = b.carton_no
				   AND c.order_type = @order_type
				 GROUP BY b.order_no, b.order_ext, b.line_no, b.part_no), 0),	
	
		cur_packed = CASE WHEN @carton_no = 0
				  THEN 0
				  ELSE
					ISNULL((SELECT SUM(d.pack_qty)
					   FROM tdc_carton_detail_tx d,
				                tdc_carton_tx e
					  WHERE d.carton_no = @carton_no
					    AND d.order_no = a.xfer_no
					    AND d.order_ext = 0
					    AND d.line_no = a.line_no
					    AND d.part_no = a.part_no
					    AND e.carton_no = d.carton_no
					    AND e.order_type = @order_type
				          GROUP BY d.order_no, d.order_ext, d.line_no, d.part_no), 0)
			     END,
		a.status
	  FROM xfer_list a 
	 WHERE a.xfer_no =  @order_no
END

RETURN 0

GO
GRANT EXECUTE ON  [dbo].[tdc_get_pack_out_item_list_sp] TO [public]
GO
