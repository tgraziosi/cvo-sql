SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROC [dbo].[tdc_plw_so_get_b2b]
	@location 		varchar(10),
	@part_no 		varchar(30),
	@bin_group		varchar(10),
	@multiple_parts_per_bin char(1),
	@target_bin		varchar(12) OUTPUT,
	@target_bin_qty 	decimal(20, 8) OUTPUT
 
AS

DECLARE @repl_max_qty 	   decimal(20, 8),
	@repl_qty_in_stock decimal(20, 8),
	@put_queue_qty	   decimal(20, 8),
	@pick_queue_qty	   decimal(20, 8)
	

DECLARE repl_bins_B2B_cur CURSOR FOR

	SELECT DISTINCT a.bin_no, a.replenish_max_lvl,
	       qty_in_stock = ISNULL((SELECT SUM(qty)
			       FROM lot_bin_stock (NOLOCK)
			      WHERE location = a.location 
				AND bin_no   = a.bin_no
			      GROUP BY location, bin_no),0)
	  FROM tdc_bin_replenishment 	  a (NOLOCK),		      
	       tdc_bin_master		  e			       
	 WHERE a.location	 = @location	 
	   AND a.part_no         = @part_no			   
	   AND a.bin_no 	 = e.bin_no
	   AND a.location	 = e.location
	   AND (@bin_group = '[ALL]' OR e.group_code	 = @bin_group)
	   AND a.location 	 = @location
	   AND a.part_no	 = @part_no
	 UNION
	 SELECT DISTINCT a.bin_no, a.maximum_level,
		       qty_in_stock = ISNULL((SELECT SUM(qty)
			       FROM lot_bin_stock (NOLOCK)
			      WHERE location = a.location 
				AND bin_no   = a.bin_no
			      GROUP BY location, bin_no),0) 
	 FROM  tdc_bin_master   	  a(NOLOCK)       
	 WHERE a.location     	 = @location
	   AND a.usage_type_code IN ('REPLENISH','OPEN') -- v1.0 Include OPEN bins
--		AND a.usage_type_code = 'REPLENISH'		
	   AND ISNULL(a.maximum_level, 0) > 0
	   AND a.bin_no NOT IN(SELECT bin_no 
				 FROM tdc_bin_replenishment e(NOLOCK)
				WHERE a.location = e.location)
	  AND(@bin_group = '[ALL]' OR a.group_code	 = @bin_group)
	 ORDER BY a.bin_no, qty_in_stock DESC 

OPEN repl_bins_B2B_cur
FETCH NEXT FROM repl_bins_B2B_cur INTO @target_bin, @repl_max_qty, @repl_qty_in_stock

WHILE @@FETCH_STATUS = 0
BEGIN


	--Get queue qty for the selected target_bin
	SELECT @pick_queue_qty = ISNULL(SUM(qty_to_process), 0) FROM tdc_pick_queue WHERE trans = 'PLWB2B'     AND location = @location AND part_no = @part_no AND bin_no = @target_bin	
	SELECT @put_queue_qty  = ISNULL(SUM(qty_to_process), 0) FROM tdc_put_queue  WHERE trans = 'MGTBIN2BIN' AND location = @location AND part_no = @part_no AND bin_no = @target_bin	

	-- Initialize available qty to put into the replenish bins
	SELECT @target_bin_qty = @repl_max_qty - @repl_qty_in_stock - (@put_queue_qty + @pick_queue_qty)

	IF (@multiple_parts_per_bin = 'N')

	BEGIN
		-- If a different part_no is assigned to this replenish bin, set avail_qty = 0
		IF EXISTS(SELECT * 
			    FROM tdc_soft_alloc_tbl a 
			   WHERE a.location   = @location
			     AND a.part_no   != @part_no
			     AND a.target_bin = @target_bin
			     AND a.bin_no NOT IN(SELECT b.bin_no 
						   FROM tdc_bin_replenishment b 
						  WHERE a.location = b.location) )
		BEGIN
			SELECT @target_bin_qty = 0				
		END
	END

	-- remove any qty that is already assigned to that repl bin but not yet moved.
	-- I.E. plwb2b moves
	IF @target_bin_qty > 0
	BEGIN
	SELECT @target_bin_qty = @target_bin_qty - 
		ISNULL((SELECT sum(qty) 
			FROM tdc_soft_alloc_tbl  
			WHERE location = @location
			AND target_bin = @target_bin),0)
	END

	-- If a bin is found that will hold any items, return it.
	IF @target_bin_qty > 0 
	BEGIN
		CLOSE repl_bins_B2B_cur
		DEALLOCATE repl_bins_B2B_cur
		RETURN 0
	END
	
	FETCH NEXT FROM repl_bins_B2B_cur INTO @target_bin, @repl_max_qty, @repl_qty_in_stock
END

CLOSE      repl_bins_B2B_cur
DEALLOCATE repl_bins_B2B_cur 
 
-- No bin was found; return -1	
RETURN -1
 
GO
GRANT EXECUTE ON  [dbo].[tdc_plw_so_get_b2b] TO [public]
GO
