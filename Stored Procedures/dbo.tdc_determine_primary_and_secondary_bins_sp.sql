SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[tdc_determine_primary_and_secondary_bins_sp]
	@location		varchar(12),
	@start_date		varchar(35),
	@end_date		varchar(35),
	@processing_option	int,
	@part_type		char(5),
	@part_group		varchar(10)

AS
DECLARE
	@part_no		varchar(30),
	@bin_no			varchar(12),
	@abc_ranking		char(1),
	@percentage		decimal(20,8),
	@part_count		decimal(20,8),
	@bin_size_group		varchar(10),
	@max_qty		decimal(20,8),
	@qty_ordered		decimal(20,8),
	@total_qty		decimal(20,8),
	@allowed_qty		decimal(20,8),
	@needed_qty		decimal(20,8),
	@done			bit,
	@start_date_val		datetime,
	@end_date_val		datetime

DECLARE	@bin_cur		varchar(12),
	@bin_size_group_cur	varchar(10),
	@upd_qty		decimal(20,8),
	@part_group_defined 	bit,
	@part_defined		bit

TRUNCATE TABLE #inv_class_parts
TRUNCATE TABLE #inv_class_temp_parts
TRUNCATE TABLE #avail_bins
TRUNCATE TABLE #used_bins
TRUNCATE TABLE #tdc_error_tbl
TRUNCATE TABLE #tdc_bin_part_qty

EXEC tdc_determine_abc_part_classification_sp 85, 15, @location, @start_date,
	@end_date, @processing_option, @part_type, @part_group

--What parts am I concerned about?
	--parts from the specified location
	--parts that have been ABC classified from the new stored procedure.
	--parts must have been setup in the new table(s)
		--"tdc_bin_size_group_part_values" & "tdc_bin_size_group_part_groups_values"
DECLARE part_cursor CURSOR FOR
	SELECT part_no, new_rank, percentage 
	  FROM 	#inv_class_temp_parts
	WHERE part_no IN (SELECT DISTINCT part_no FROM tdc_bin_size_group_part_values WHERE max_qty > 0)
	  OR part_no IN (SELECT part_no FROM inv_master WHERE category IN (SELECT DISTINCT part_group FROM tdc_bin_size_group_part_group_values (NOLOCK) WHERE max_qty > 0 AND part_no IN (SELECT part_no FROM #inv_class_temp_parts (NOLOCK))))
	ORDER BY percentage DESC
OPEN part_cursor
FETCH NEXT FROM part_cursor INTO @part_no, @abc_ranking, @percentage
WHILE @@FETCH_STATUS = 0
BEGIN
	SELECT @part_count = 0, @done = 0, @needed_qty = 0, @bin_no = ''
	SELECT @part_group_defined = 0, @part_defined = 0

	TRUNCATE TABLE #avail_bins

	--GET all of the available bins
	INSERT INTO #avail_bins (bin_no, bin_group, bm_seq_no, max_qty_allowed)
		SELECT 	bin_no, size_group_code, seq_no, 0
		  FROM 	tdc_bin_master (NOLOCK)
		WHERE location = @location
		  AND ISNULL(seq_no,'') <> ''
		  AND usage_type_code IN ('OPEN', 'REPLENISH')
		  AND bin_no NOT IN (SELECT bin_no FROM #used_bins (NOLOCK))
		ORDER BY seq_no

	--GET part group
	SELECT @part_group = category 
	  FROM inv_master (NOLOCK) WHERE part_no = @part_no
	
	--SEE IF PART IS DEFINED IN THE BIN SIZE GROUP PART TABLE
	IF EXISTS(SELECT * FROM tdc_bin_size_group_part_values (NOLOCK) WHERE part_no =  @part_no)
	BEGIN
		SELECT @part_defined = 1
	END
	
	--SEE IF PART GROUP IS DEFINED IN BIN SIZE GROUP PART GROUP TABLE
	IF EXISTS(SELECT * FROM tdc_bin_size_group_part_group_values (NOLOCK) WHERE part_group =  @part_group)
	BEGIN
		SELECT @part_group_defined = 1
	END

	--UPDATE QTY APPROPRIATELY
	DECLARE update_cursor CURSOR FOR
		SELECT bin_no 
		  FROM #avail_bins
		ORDER BY bin_no
	OPEN update_cursor
	FETCH NEXT FROM update_cursor INTO @bin_cur
	WHILE @@FETCH_STATUS = 0
	BEGIN
		SELECT @bin_size_group_cur = size_group_code 
		  FROM tdc_bin_master (NOLOCK) 
		WHERE location = @location AND bin_no = @bin_cur
	
		IF @part_defined = 1
		BEGIN
			SELECT @upd_qty = ISNULL(max_qty, 0)
	                   FROM	tdc_bin_size_group_part_values (NOLOCK)  
	                 WHERE part_no = @part_no
			   AND bin_size_group = @bin_size_group_cur
	
			UPDATE #avail_bins
			  SET max_qty_allowed = @upd_qty
			WHERE bin_no = @bin_cur
		END
		ELSE
		BEGIN
			IF @part_group_defined = 1
			BEGIN
				 SELECT @upd_qty = ISNULL(a.max_qty, 0)
		                   FROM  tdc_bin_size_group_part_group_values a (NOLOCK)  
		                 WHERE a.bin_size_group = @bin_size_group_cur
		                   AND a.part_group =  @part_group 
	
				UPDATE #avail_bins
				  SET max_qty_allowed = @upd_qty
				WHERE bin_no = @bin_cur
			END
		END
	
		FETCH NEXT FROM update_cursor INTO @bin_cur
	END
	CLOSE update_cursor
	DEALLOCATE update_cursor

	DELETE FROM #avail_bins WHERE max_qty_allowed = 0

	--SET default value
	SELECT @total_qty = 0

	--Ordered Qty
	IF @processing_option = 4
	BEGIN
		SELECT @start_date_val = CONVERT(datetime, @start_date)
		SELECT @end_date_val = CONVERT(datetime, @end_date)

		SELECT @qty_ordered = 0
		--Parts on orders
		SELECT @qty_ordered = ISNULL(SUM(b.ordered), 0)
		  FROM 	orders a (NOLOCK),
			ord_list b (NOLOCK)
		WHERE a.status < 'R'
		  AND a.order_no = b.order_no
		  AND a.ext = b.order_ext
		  AND b.location = @location
		  AND b.part_type <> 'M'
		  AND b.part_no = @part_no
		  AND CONVERT(varchar(20), a.sch_ship_date, 101) BETWEEN CONVERT(varchar(20), @start_date_val, 101) AND CONVERT(varchar(20), @end_date_val, 101)
		GROUP BY b.part_no

		SELECT @total_qty = @qty_ordered
	END
	ELSE
	BEGIN
		--How many parts do we currently have in inventory?
		SELECT @part_count = ISNULL(SUM(qty),0) 
		  FROM lot_bin_stock 
		WHERE location = @location 
		  AND part_no = @part_no

		SELECT @qty_ordered = 0
		SELECT @total_qty = @part_count
	END

	--Calculate the number of needed bins based on the TOTAL QTY OF PARTS
	--Get the primary bin
	--This bin will always be the first bin in the temp table
	IF EXISTS(SELECT * FROM #avail_bins (NOLOCK))
	BEGIN
		SELECT TOP 1 @bin_no = bin_no, @allowed_qty = max_qty_allowed FROM #avail_bins ORDER BY bm_seq_no
	
		INSERT INTO #used_bins (bin_no, bin_group, bm_seq_no, max_qty_allowed, part_no, location)
			SELECT bin_no, bin_group, bm_seq_no, max_qty_allowed, @part_no, @location
			  FROM #avail_bins
			WHERE bin_no = @bin_no
	
		INSERT INTO #tdc_bin_part_qty (location, part_no, bin_no, qty, [primary], seq_no)
			SELECT @location, @part_no, @bin_no, @allowed_qty, 'Y', 0
	
		DELETE FROM #avail_bins WHERE bin_no = @bin_no
	
		IF (@allowed_qty < @total_qty)
		BEGIN
			--GET the needed qty Minus the qty used for the Primary bin
			SELECT @needed_qty = @total_qty - @allowed_qty
			--Get the secondary bin(s)
			DECLARE secondary_bins CURSOR FOR
				SELECT bin_no, max_qty_allowed
				  FROM #avail_bins
				ORDER BY bm_seq_no
			OPEN secondary_bins
			FETCH NEXT FROM secondary_bins INTO @bin_no, @allowed_qty
			WHILE (@@FETCH_STATUS = 0) AND (@done = 0)
			BEGIN
				IF (@allowed_qty >= @needed_qty)
				BEGIN
					SELECT @needed_qty = 0
					SELECT @done = 1
				END
				ELSE
				BEGIN
					SELECT @needed_qty = @needed_qty - @allowed_qty
				END
	
				INSERT INTO #used_bins (bin_no, bin_group, bm_seq_no, max_qty_allowed, part_no, location)
					SELECT bin_no, bin_group, bm_seq_no, max_qty_allowed, @part_no, @location
					  FROM #avail_bins
					WHERE bin_no = @bin_no
			
				INSERT INTO #tdc_bin_part_qty (location, part_no, bin_no, qty, [primary], seq_no)
					SELECT @location, @part_no, @bin_no, @allowed_qty, 'N', (SELECT ISNULL(MAX(seq_no)+1,1) FROM #tdc_bin_part_qty WHERE location = @location AND part_no = @part_no AND [primary] = 'N')
	
				DELETE FROM #avail_bins WHERE bin_no = @bin_no		
	
				FETCH NEXT FROM secondary_bins INTO @bin_no, @allowed_qty
			END
			CLOSE secondary_bins
			DEALLOCATE secondary_bins
		END
	END
	ELSE
	BEGIN
		SELECT @needed_qty = @total_qty
	END
	
	IF @needed_qty > 0
	BEGIN
		INSERT INTO #tdc_error_tbl (location, part_no, qty, err_msg)
		SELECT @location, @part_no, @needed_qty, 'Insufficient space for moving part(s)'
	END

	FETCH NEXT FROM part_cursor INTO @part_no, @abc_ranking, @percentage
END
CLOSE part_cursor
DEALLOCATE part_cursor

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[tdc_determine_primary_and_secondary_bins_sp] TO [public]
GO
