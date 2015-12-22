SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- v1.1 CB 12/20/2010 - Exclude RDOCK from the availability
-- v1.2 CB 29/03/2011 - 18.RDOCK Inventory - Exclude RDOCK and CUSTOM from the availability
-- v1.3 CB 19/10/2011 - Performance - Use base tables instead of inventory view
-- v1.4	CT 02/07/2012 - Subtract qty on replenishment moves from available qty	
-- v1.5 CT 09/07/2012 - Cater for NULL replen qty
-- v1.6 CT 20/07/2012 - For excluded bin qty, changed to use function f_get_excluded_bins
-- v1.7 CB 20/03/2015 - Performance Changes    
-- v1.8 CB 13/04/2015 - The in_stock returned from cvo_inventory has already deducted non allocatable bins
-- exec [dbo].[CVO_CheckAvailabilityInStock_sp] 'FPCOTBRZ4215','001', 1


CREATE PROCEDURE  [dbo].[CVO_CheckAvailabilityInStock_sp]   @part_no VARCHAR(30), @location VARCHAR(10), @from_pb INT = 0 AS
BEGIN
	SET NOCOUNT ON

	DECLARE @in_stock DECIMAL(20,8), 
			@alloc DECIMAL(20,8),
			@quarantined DECIMAL(20,8),
			@available DECIMAL(20,8),
			@RDock DECIMAL(20,8), -- v1.1
			@exc_bin_qty decimal(20,8) -- v1.3
			-- @config_str varchar(100) -- v1.3	-- v1.6

	-- START v1.6
	-- v1.3
	/*
	SELECT @config_str = ISNULL(value_str,'') FROM dbo.tdc_config (NOLOCK) WHERE [function] = 'INV_EXCLUDED_BINS'

	SELECT	@exc_bin_qty = ISNULL(SUM(qty),0) 
	FROM	dbo.lot_bin_stock (NOLOCK)
	WHERE	bin_no IN (SELECT * FROM fs_cParsing(@config_str))
	AND		location = @location
	AND		part_no = @part_no
	*/

	/* v1.8 Start
	SELECT @exc_bin_qty = ISNULL(qty,0)   
	FROM dbo.f_get_excluded_bins(1) 
	WHERE  location = @location  
	AND  part_no = @part_no  
	v1.8 End */
	-- END v1.6

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

	-- v1.7 Start
	SELECT	@in_stock = in_stock -- v1.8 - ISNULL(@exc_bin_qty,0)
	FROM	dbo.cvo_inventory2
	WHERE	location = @location
	AND		part_no = @part_no

	/*

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
	*/
	-- v1.7 End


	/* v1.3 Original
	SELECT @in_stock = in_stock FROM inventory (NOLOCK) -- v1.2
	WHERE part_no  = @part_no AND location = @location */

	-- v1.1
--	SELECT	@RDock = ISNULL(sum(qty),0.00) 
--	FROM	lot_bin_stock (NOLOCK)
--	WHERE	location = @location
--	AND		part_no = @part_no
--	AND		bin_no = 'RDOCK'

	SELECT @alloc = allocated_amt, @quarantined = quarantined_amt
	FROM #tbl_AvailableQtyLocation
	WHERE location = @location


	SET @available = ISNULL(@in_stock - ISNULL(@alloc,0.0) - ISNULL(@quarantined,0.0), 0.0)-- - @RDock -- v1.1
	
	IF @available < 0
		SET @available = 0

	--Return available = in stock - alloc - quarantined

	IF @from_pb = 1
		SELECT @available
	ELSE
		RETURN @available
END
GO
GRANT EXECUTE ON  [dbo].[CVO_CheckAvailabilityInStock_sp] TO [public]
GO
