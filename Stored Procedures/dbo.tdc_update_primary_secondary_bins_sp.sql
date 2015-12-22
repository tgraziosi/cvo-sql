SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[tdc_update_primary_secondary_bins_sp]
AS

DECLARE	@location	varchar(12),
	@part_no	varchar(30)

	DECLARE update_cursor CURSOR FOR
	  SELECT DISTINCT location, part_no FROM #tdc_bin_part_qty
	OPEN update_cursor
	FETCH NEXT FROM update_cursor INTO @location, @part_no
	WHILE @@FETCH_STATUS = 0
	BEGIN
		DELETE FROM tdc_bin_part_qty
		  WHERE location = @location AND part_no = @part_no
	
		FETCH NEXT FROM update_cursor INTO @location, @part_no
	END
	CLOSE update_cursor
	DEALLOCATE update_cursor
	
	INSERT INTO tdc_bin_part_qty (location, part_no, bin_no, qty, [primary], seq_no)
		SELECT location, part_no, bin_no, qty, [primary], seq_no
		  FROM #tdc_bin_part_qty

	TRUNCATE TABLE #tdc_bin_part_qty
	TRUNCATE TABLE #tdc_error_tbl
	TRUNCATE TABLE #used_bins
	TRUNCATE TABLE #inv_class_temp_parts
RETURN 0
GO
GRANT EXECUTE ON  [dbo].[tdc_update_primary_secondary_bins_sp] TO [public]
GO
