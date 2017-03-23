SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  StoredProcedure [dbo].[CVO_allocate_by_bin_group_sp]    Script Date: 08/09/2010  *****
SED009 -- AutoAllocation    
Object:      Procedure CVO_CheckAvailabilityInBinGroup_sp  
Source file: CVO_CheckAvailabilityInBinGroup_sp.sql
Author:		 Craig Boston
Created:	 12/08/2010
Function:    Return the stock qty by bin group
Modified:    
Calls:    
Called by:   WMS74 -- Allocation Screen
Copyright:   Epicor Software 2010.  All rights reserved.  
declare @qty decimal(20,8)
exec @qty = CVO_CheckAvailabilityInBinGroup_sp 'TESTBLA5002','001','HIGHBAY'
select @qty

-- v1.0 CB 29/03/2011 - 18.RDOCK Inventory - Exclude specified bins
-- v1.1 CB 13/07/2011 - Fix - Include open and replenish bins
-- v1.2 CB 24/04/2013 - access table directly rather than using function
-- v1.3 CB 07/10/2013	Issue #1385 - non alloc bin qty must exclude what has been allocated
-- v1.4 CB 30/10/2013 - When checking allocated stock in non alloc bins then need to use the bin group
-- v1.5 CB 03/10/2016 - #1606 - Direct Putaway & Fast Track Cart

*/

CREATE PROCEDURE  [dbo].[CVO_CheckAvailabilityInBinGroup_sp]   @part_no VARCHAR(30), @location VARCHAR(10), @bin_group VARCHAR(30), @from_pb INT = 0,
															@fasttrack int = 0 -- v1.5
AS
BEGIN
	SET NOCOUNT ON

	DECLARE @in_stock DECIMAL(20,8), 
			@alloc DECIMAL(20,8),
			@quarantined DECIMAL(20,8),
			@available DECIMAL(20,8),
			@non_alloc decimal(20,8) -- v1.3

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
	EXEC CVO_tdc_get_alloc_qntd_sp @location, @part_no, @bin_group, @fasttrack -- v1.5

--	v1.3 Start	
/*
	SELECT	@in_stock = 	SUM(a.qty) 
	FROM	lot_bin_stock a (NOLOCK) 
	JOIN	tdc_bin_master b (NOLOCK) 
	ON		a.location = b.location 
	AND		a.bin_no = b.bin_no
	LEFT JOIN cvo_lot_bin_stock_exclusions c (NOLOCK) -- v1.2
	ON		a.bin_no = c.bin_no -- v1.2
	AND		a.part_no = c.part_no -- v1.2
	WHERE	a.part_no  = @part_no 
	AND		a.location = @location 
	AND		b.group_code = @bin_group 
	AND		b.usage_type_code IN ('OPEN','REPLENISH') -- v1.2
	AND		c.bin_no IS NULL -- v1.2
-- v1.2	AND		a.bin_no NOT IN (select bins FROM dbo.f_get_excluded_bins(0) WHERE part_no = @part_no) -- v1.0
*/
	-- v1.5 Start
	IF (@fasttrack = 0)
	BEGIN
		SELECT	@in_stock = 	SUM(a.qty) 
		FROM	lot_bin_stock a (NOLOCK) 
		JOIN	tdc_bin_master b (NOLOCK) 
		ON		a.location = b.location 
		AND		a.bin_no = b.bin_no	
		WHERE	a.part_no  = @part_no 
		AND		a.location = @location 
		AND		b.group_code = @bin_group 
		AND		b.usage_type_code IN ('OPEN','REPLENISH') -- v1.2
		AND		LEFT(a.bin_no,4) <> 'ZZZ-' -- v1.5
	END
	ELSE
	BEGIN
		SELECT	@in_stock = 	SUM(a.qty) 
		FROM	lot_bin_stock a (NOLOCK) 
		JOIN	tdc_bin_master b (NOLOCK) 
		ON		a.location = b.location 
		AND		a.bin_no = b.bin_no	
		WHERE	a.part_no  = @part_no 
		AND		a.location = @location 
		AND		b.group_code = @bin_group 
		AND		b.usage_type_code IN ('OPEN','REPLENISH') -- v1.2
		AND		LEFT(a.bin_no,4) = 'ZZZ-' -- v1.5
	END
	-- v1.5 End

	SELECT	@non_alloc = SUM(a.qty) - ISNULL(SUM(b.qty),0.0)   
	FROM	dbo.cvo_lot_bin_stock_exclusions a (NOLOCK)
	LEFT JOIN (SELECT SUM(qty) qty, location, part_no, bin_no FROM tdc_soft_alloc_tbl (NOLOCK) GROUP BY location, part_no, bin_no) b 
	ON		a.location = b.location
	AND		a.part_no = b.part_no
	AND		a.bin_no = b.bin_no
	JOIN	tdc_bin_master c (NOLOCK) -- v1.4
	ON		a.location = c.location -- v1.4
	AND		a.bin_no = c.bin_no	-- v1.4
	WHERE	a.part_no  = @part_no 
	AND		a.location = @location 
	AND		c.group_code = @bin_group -- v1.4

	IF (@non_alloc IS NULL)
		SET @non_alloc = 0
	-- v1.3 End

	SELECT @alloc = allocated_amt, @quarantined = quarantined_amt
	FROM #tbl_AvailableQtyLocation
	WHERE location = @location

	SET @available = ISNULL(@in_stock - ISNULL(@alloc,0.0) - ISNULL(@quarantined,0.0), 0.0) - @non_alloc -- v1.3
	
	IF @available < 0
		SET @available = 0

	--Return available = in stock - alloc - quarantined

	RETURN @available
END

-- Permissions
GO
GRANT EXECUTE ON  [dbo].[CVO_CheckAvailabilityInBinGroup_sp] TO [public]
GO
