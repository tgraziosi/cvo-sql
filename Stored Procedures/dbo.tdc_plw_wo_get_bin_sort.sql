SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROC [dbo].[tdc_plw_wo_get_bin_sort]
	@search_sort	varchar(100),
	@bin_first	varchar(10),	-- '[DEFAULT]', 'OPEN', or 'REPLENISH'
	@lbs_order_by	varchar(5000) OUTPUT
AS

DECLARE @wop_inv_pick char(1),
	@bin_sort     varchar(50)

--============================================================================================================================
------------------------------------------------------------------------------------------------------------------------------
-- STEP 1:  Determine which bin type to allocate first
--============================================================================================================================
------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------
-- REPLENISH FIRST
------------------------------------------------------------------------------------------------------------------------------
IF @bin_first = 'REPLENISH' 
BEGIN
	SELECT @lbs_order_by = ' ORDER BY bm.usage_type_code DESC '	
END
------------------------------------------------------------------------------------------------------------------------------
-- OPEN FIRST
------------------------------------------------------------------------------------------------------------------------------
ELSE IF @bin_first = 'OPEN'
BEGIN
	SELECT @lbs_order_by = ' ORDER BY bm.usage_type_code '	
END
------------------------------------------------------------------------------------------------------------------------------
-- DEFAULT
------------------------------------------------------------------------------------------------------------------------------
ELSE IF (EXISTS (SELECT * FROM tdc_config   
	    	  WHERE [function] = 'alloc_bin_sort_wo' 
	      	    AND active     = 'Y' 
	      	    AND value_str != 'REPLENISH'))
BEGIN
	SELECT @lbs_order_by = ' ORDER BY bm.usage_type_code '
END
ELSE
BEGIN
	SELECT @lbs_order_by = ' ORDER BY bm.usage_type_code DESC '
END

--============================================================================================================================
-- STEP 2:  Determine how to pull from those bins
--============================================================================================================================

-- User didn't passed in a bin sort
IF ISNULL(@search_sort, '') = '' OR @search_sort LIKE '%DEFAULT%'
BEGIN
	SELECT @wop_inv_pick = value_str FROM tdc_config (NOLOCK) WHERE [function] = 'wop_inv_pick'

	SELECT @bin_sort = CASE	@wop_inv_pick				 
				WHEN '1' THEN 'LIFO' 
				WHEN '2' THEN 'FIFO'
				WHEN '3' THEN 'LOT/BIN ASC'
				WHEN '4' THEN 'LOT/BIN DESC'
				WHEN '5' THEN 'QTY ASC'
				WHEN '6' THEN 'QTY DESC'
				         ELSE 'LIFO' 
			   END

END
ELSE
BEGIN
	SELECT @bin_sort = @search_sort
END

------------------------------------------------------------------------------------------------------------------------------
-- Append the bin sort to the order by clause
------------------------------------------------------------------------------------------------------------------------------
SELECT @lbs_order_by = @lbs_order_by + CASE @bin_sort
						WHEN 'LIFO' 		THEN ' , lb.date_expires DESC '
						WHEN 'FIFO'  		THEN ' , lb.date_expires '
						WHEN 'LOT/BIN ASC' 	THEN ' , lb.lot_ser, lb.bin_no '
						WHEN 'LOT/BIN DESC' 	THEN ' , lb.lot_ser DESC, lb.bin_no DESC '
						WHEN 'QTY ASC' 		THEN ' , lb.qty '
						WHEN 'QTY DESC' 	THEN ' , lb.qty DESC '
									ELSE ' , lb.date_expires ASC ' 
					END

RETURN						 
GO
GRANT EXECUTE ON  [dbo].[tdc_plw_wo_get_bin_sort] TO [public]
GO
