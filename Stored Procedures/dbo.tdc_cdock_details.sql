SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[tdc_cdock_details] 
	@tran_no		varchar(16),
	@tran_ext		varchar(10),
	@tran_type		varchar(15),
	@location 		varchar(10), 
	@part_no 		varchar(30),
	@line_no         	int,
	@from_tran_type		char(1),
	@from_date		datetime,
	@to_date		datetime
AS
DECLARE @row_id int,
	@qty_already_saved decimal(20, 8),
	@qty_in_temp_table decimal(20, 8),
	@qty_in_grid decimal(20, 8),
	@changed decimal(20, 8)

TRUNCATE TABLE #xdock_supply
  

IF @from_tran_type = 'A' OR @from_tran_type = 'P'
BEGIN
	INSERT INTO #xdock_supply (tran_no, tran_ext, tran_type, release_date, location, vendor_code, vendor_name, part_no, qty_avail, qty_on_order, qty_to_commit ) 
	SELECT a.po_no, NULL, 'P', b.release_date, a.location, a.vendor_no, c.vendor_name, b.part_no, 
	       qty_avail = SUM(ISNULL(quantity, 0) - ISNULL(received, 0)),
	       qty_on_order = SUM(quantity - received),
	       qty_to_commit = ISNULL ((SELECT CAST(SUM(qty) AS VARCHAR)
		                                 FROM #tmp_cdock_mgt    
		                                WHERE tran_no = @tran_no
						  AND tran_ext = @tran_ext
						  AND tran_type = @tran_type
						  AND from_tran_no = CAST(a.po_no AS VARCHAR)
	                                          AND part_no      = @part_no 
						  AND location	   = @location
						  AND from_tran_type = 'P'
						  --AND DATEDIFF(day, release_date, b.release_date) = 0 
					       ), '')  
	  FROM purchase       a (NOLOCK),                                                        
	       releases       b (NOLOCK),                                                        
	       apvend         c (NOLOCK)                                                 
	 WHERE a.po_no        = b.po_no                                                          
	   AND a.vendor_no    = c.vendor_code                                                    
	   AND b.quantity     > b.received                                                       
	   AND b.part_no      = @part_no
	   AND b.location     = @location  
	   AND release_date BETWEEN CONVERT(DATETIME, @from_date) AND CONVERT(DATETIME, @to_date + ' 23:59:59.998') 
	 GROUP BY a.po_no, b.release_date, a.location, a.vendor_no, c.vendor_name, b.part_no
END

IF @from_tran_type = 'A' OR @from_tran_type = 'T'
BEGIN
	INSERT INTO #xdock_supply (tran_no, tran_ext, tran_type, release_date, location, vendor_code, vendor_name, part_no, qty_avail, qty_on_order, qty_to_commit ) 
	SELECT b.xfer_no, NULL, 'X', a.sch_ship_date, a.to_loc, NULL, NULL, b.part_no, 
	       qty_avail = SUM(ordered),
	       qty_on_order = SUM(ordered), 
	       qty_to_commit = ISNULL ((SELECT CAST(SUM(qty) AS VARCHAR)
		                         FROM #tmp_cdock_mgt    
		                        WHERE tran_no = @tran_no
					  AND tran_ext = @tran_ext
					  AND tran_type = @tran_type
					  AND from_tran_no = CAST(b.xfer_no AS VARCHAR)
		                          AND part_no      = @part_no 
					  AND location     = @location
					  AND from_tran_type = 'X'
				       ), '')  
	  FROM xfers a (NOLOCK),
	       xfer_list b (NOLOCK)
	 WHERE a.xfer_no = b.xfer_no
	   AND a.status < 'S'
	   AND a.to_loc = @location
	   AND b.part_no = @part_no	   
	   AND sch_ship_date BETWEEN CONVERT(DATETIME, @from_date) AND CONVERT(DATETIME, @to_date + ' 23:59:59.998')
	 GROUP BY b.xfer_no, a.sch_ship_date, a.to_loc, b.part_no	 
END
IF @from_tran_type = 'A' or @FROM_TRAN_TYPE = 'W'
BEGIN
	INSERT INTO #xdock_supply (tran_no, tran_ext, tran_type, release_date, location, vendor_code, vendor_name, part_no, qty_avail, qty_on_order, qty_to_commit ) 
	SELECT a.prod_no, a.prod_ext, 'W', a.prod_date, a.location, NULL, NULL, a.part_no, 
		qty_avail = qty_scheduled,
	       qty_on_order = qty_scheduled,
	       qty_to_commit = ISNULL ((SELECT CAST(SUM(qty) AS VARCHAR)
		                         FROM #tmp_cdock_mgt    
		                        WHERE tran_no = @tran_no
					  AND tran_ext = @tran_ext
					  AND tran_type = @tran_type
					  AND from_tran_no   = CAST(a.prod_no AS VARCHAR)
					  AND from_tran_ext  = a.prod_ext 
					  AND location       = @location
		                          AND part_no        = @part_no 
					  AND from_tran_type = 'W'
				       ), '')  
	  FROM produce a (NOLOCK), 
	       prod_list b (NOLOCK)
	 WHERE a.prod_no = b.prod_no
	   AND a.prod_ext = b.prod_ext 
	   AND a.location = @location
	   AND a.part_no = @part_no
	   AND a.status < 'S'
	   AND prod_date BETWEEN CONVERT(DATETIME, @from_date) AND CONVERT(DATETIME, @to_date + ' 23:59:59.998')
	 GROUP BY a.prod_no, a.prod_ext, a.prod_date, a.location, a.part_no, qty_scheduled
END
 
UPDATE #xdock_supply SET qty_to_commit = CAST(qty AS VARCHAR)
  FROM #xdock_supply, 
       tdc_cdock_mgt (NOLOCK)
 WHERE tdc_cdock_mgt.tran_type = @tran_type
   AND tdc_cdock_mgt.tran_no = @tran_no
   AND tdc_cdock_mgt.tran_ext = @tran_ext   
   AND #xdock_supply.tran_no = tdc_cdock_mgt.from_tran_no
   AND ISNULL(#xdock_supply.tran_ext, 0) = ISNULL(tdc_cdock_mgt.from_tran_ext, 0)
   AND #xdock_supply.tran_type = tdc_cdock_mgt.from_tran_type
   AND DATEDIFF(DAY, #xdock_supply.release_date, tdc_cdock_mgt.release_date) = 0
   AND #xdock_supply.location = tdc_cdock_mgt.location
   AND #xdock_supply.part_no = tdc_cdock_mgt.part_no
   AND qty_to_commit = '' 

DECLARE cur CURSOR FOR
	SELECT row_id FROM #xdock_supply


OPEN cur
FETCH NEXT FROM cur INTO @row_id
WHILE @@FETCH_STATUS = 0
BEGIN

	SELECT @qty_already_saved = SUM(a.qty) 
	  FROM tdc_cdock_mgt a(NOLOCK),
	       #xdock_supply b
	 WHERE a.from_tran_type = b.tran_type
	   AND a.from_tran_no = b.tran_no
	   AND ISNULL(a.from_tran_ext, 0) = ISNULL(b.tran_ext, 0)
	   AND b.row_id = @row_id
	   AND DATEDIFF(day, a.release_date, b.release_date) = 0 
	   AND a.part_no = b.part_no
	   AND a.location = b.location
 

	SELECT @changed = sum(qty) from (
			select qty = qty - isnull((select sum(qty) from tdc_cdock_mgt a (NOLOCK)
		       where a.tran_type = b.tran_type
			 and a.tran_no = b.tran_no
			 and isnull(a.tran_ext, 0) = isnull(b.tran_ext, 0)
		  	 and a.location = b.location
			 and a.part_no = b.part_no
			 and a.line_no = b.line_no
			 and a.from_tran_no = b.from_tran_no
			 and isnull(a.from_tran_ext, 0) = isnull(b.from_tran_ext, 0)
			 and DATEDIFF(day, a.release_date, b.release_date) = 0 ), 0)
		from #tmp_cdock_mgt b
		)qty_select



 
 
 
	SELECT @qty_already_saved = ISNULL(@qty_already_saved, 0)
	SELECT @qty_in_temp_table = ISNULL(@qty_in_temp_table, 0)
	SELECT @qty_in_grid = ISNULL(@qty_in_grid, 0)
	SELECT @changed = ISNULL(@changed, 0)
 
	UPDATE #xdock_supply
	   SET qty_avail = qty_avail - @qty_already_saved - @changed
	WHERE row_id = @row_id
	
	FETCH NEXT FROM cur INTO @row_id
END
CLOSE cur
DEALLOCATE cur
 
RETURN
GO
GRANT EXECUTE ON  [dbo].[tdc_cdock_details] TO [public]
GO
