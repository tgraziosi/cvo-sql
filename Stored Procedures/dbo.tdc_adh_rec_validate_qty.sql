SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROC [dbo].[tdc_adh_rec_validate_qty]
AS

DECLARE @tran_type   	char(1),
	@tran_no     	varchar(20),
	@tran_ext    	varchar(15),
	@ordered_qty	decimal(24,8),
	@proc_qty	decimal(24,8),
	@ret		int

SELECT @ret = 0
TRUNCATE TABLE #temp_rec_orders_not_filled

DECLARE validate_cur
CURSOR FOR 
	SELECT DISTINCT tran_type, tran_no, tran_ext
	  FROM #temp_adhoc_receipts
	 WHERE error_code IS NULL
	   AND upd_flg != 0    
	   AND tran_type  != 'A'
	 ORDER BY tran_type, tran_no, tran_ext

OPEN validate_cur
FETCH NEXT FROM validate_cur INTO @tran_type, @tran_no, @tran_ext

WHILE @@FETCH_STATUS = 0
BEGIN
	IF @tran_type = 'C'
	BEGIN
		SELECT @ordered_qty = SUM(cr_ordered)
		  FROM ord_list(NOLOCK)
		 WHERE order_no = CAST(@tran_no AS INT)
		   AND order_ext = CAST(@tran_ext AS INT)
		 GROUP BY order_no, order_ext
	END
	ELSE IF @tran_type = 'T'
	BEGIN
		SELECT @ordered_qty = SUM(ordered)
		  FROM xfer_list(NOLOCK)
		 WHERE xfer_no = CAST(@tran_no AS INT)
		 GROUP BY xfer_no


	END	

	SELECT @proc_qty = SUM(qty)
	  FROM #temp_adhoc_receipts 
	 WHERE error_code IS NULL
	   AND upd_flg != 0    
	   AND tran_type = @tran_type
	   AND tran_no = @tran_no
	   AND ISNULL(tran_ext, 0) = ISNULL(@tran_ext, 0)
	 GROUP BY tran_type, tran_no, tran_ext

 
	IF @proc_qty < @ordered_qty
	BEGIN
		SELECT @ret = -1
		INSERT INTO #temp_rec_orders_not_filled (tran_type, tran_no, tran_ext)
		SELECT @tran_type, @tran_no, @tran_ext
	END

	FETCH NEXT FROM validate_cur INTO @tran_type, @tran_no, @tran_ext
END

CLOSE validate_cur
DEALLOCATE validate_cur

RETURN @ret

GO
GRANT EXECUTE ON  [dbo].[tdc_adh_rec_validate_qty] TO [public]
GO
