SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
  
CREATE PROCEDURE  [dbo].[CVO_AvailabilityInStock_sp]   @part_no VARCHAR(30), @location VARCHAR(10), @available_out DECIMAL(20,8) OUTPUT
AS  
BEGIN  
 SET NOCOUNT ON  
  
 DECLARE @in_stock DECIMAL(20,8),   
   @alloc DECIMAL(20,8),  
   @quarantined DECIMAL(20,8),  
   @available DECIMAL(20,8),
   @exc_bin_qty decimal(20,8) -- v1.0

	SELECT @exc_bin_qty = ISNULL(qty,0)   
	FROM dbo.f_get_excluded_bins(1) 
	WHERE  location = @location  
	AND  part_no = @part_no  
  
 if object_id('#tbl_AvailableQtyLocation') IS NOT NULL DROP TABLE #tbl_AvailableQtyLocation  
   
 --Create temp table to store alloc and quarantine qty for location and part no  
 CREATE TABLE #tbl_AvailableQtyLocation(  
  location VARCHAR(10),  
  part_no VARCHAR(30),  
  allocated_amt DECIMAL(20,8),  
  quarantined_amt DECIMAL(20,8),  
  apptype VARCHAR(30) NULL  
 )  
  
 --Using core stored procedure to get alloc and quarantine ( tdc_get_alloc_qntd_sp )  
 INSERT INTO #tbl_AvailableQtyLocation (location, part_no, allocated_amt, quarantined_amt, apptype )  
 EXEC tdc_get_alloc_qntd_sp @location, @part_no  
   
	-- v1.3
	SELECT @in_stock = case when (m.status='C' or m.status='V') then 0 else (l.in_stock + l.issued_mtd + p.produced_mtd - p.usage_mtd - s.sales_qty_mtd + r.recv_mtd + x.xfer_mtd - isnull(@exc_bin_qty,0) - ISNULL(replen.qty,0))end	-- v1.4 & v1.5
	FROM	inv_master m (NOLOCK)
	JOIN	inv_list l (NOLOCK) ON m.part_no = l.part_no
	JOIN	inv_sales s (NOLOCK) ON l.location = s.location AND l.part_no = s.part_no
	JOIN	inv_produce p (NOLOCK) ON l.location = p.location AND l.part_no = p.part_no
	JOIN	inv_recv r (NOLOCK) ON l.location = r.location AND l.part_no = r.part_no
	JOIN	inv_xfer x (NOLOCK) ON l.location = x.location AND l.part_no = x.part_no
	-- START v1.4
	LEFT JOIN  cvo_replenishment_qty (NOLOCK) replen
	ON			l.part_no = replen.part_no  
	AND			l.location = replen.location
	-- END v1.4
	WHERE	l.part_no  = @part_no 
	AND		l.location = @location
  
 SELECT @alloc = ISNULL(allocated_amt, 0), @quarantined = ISNULL(quarantined_amt, 0)  
 FROM #tbl_AvailableQtyLocation  
 WHERE location = @location  
  
 SET @available = ISNULL(@in_stock - @alloc - @quarantined, 0.0) 
   
 IF @available < 0  
  SET @available = 0  
  
 --Return available = in stock - alloc - quarantined  
 SELECT @available_out = @available  
END  
GO
GRANT EXECUTE ON  [dbo].[CVO_AvailabilityInStock_sp] TO [public]
GO
