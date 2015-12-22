SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- Epicor Software (UK) Ltd (c)2013
-- For ClearVision Optical - 68668
-- v1.0 CT 12/06/2013	Returns whether a part is obsolete and out of stock
-- v1.1 CT 19/06/2013	Issue #1317 - Stop double counting of change soft alloc records, use exiting SP to return SA figure
-- Returns 0 = OK, 1 = Obsolete
/*	DECLARE @retval SMALLINT
	EXEC @retval = dbo.cvo_promo_obsolete_check_sp 'CVWAAGOL5619','001',1,0,0,1,9
	SELECT @retval
*/

CREATE PROC [dbo].[cvo_promo_obsolete_check_sp](@part_no		VARCHAR(30),
											@location		VARCHAR(10),
											@qty			DECIMAL(20,8),
											@order_no		INT,
											@ext			INT,
											@line_no		INT,
											@soft_alloc_no	INT)

AS
BEGIN
	DECLARE @alloc_qty		DECIMAL(20,8),
			@quar_qty		DECIMAL(20,8),
			@sa_qty			DECIMAL(20,8),
			@in_stock		DECIMAL(20,8),
			@this_order		DECIMAL(20,8)
			
	 --Create temp table to store alloc and quarantine qty for location and part no        
	 CREATE TABLE #tbl_AvailableQtyLocation(        
	  location VARCHAR(10),        
	  part_no VARCHAR(30),        
	  allocated_amt DECIMAL(20,8),        
	  quarantined_amt DECIMAL(20,8),        
	  apptype VARCHAR(30) NULL        
	 )  
	
	-- Create temp table for soft alloc qty
	CREATE TABLE #soft_alloc_qty (qty decimal(20,8))        

	-- Check if it's obsolete
	IF NOT EXISTS (SELECT 1 FROM dbo.inv_master WHERE part_no = @part_no AND ISNULL(obsolete,0) = 1)
	BEGIN
		RETURN 0
	END

	-- If line_no = -1 then this is a promo pop gift, if it's already on the order then there's no need to check again
	IF @line_no = -1
	BEGIN
		IF EXISTS (SELECT 1 FROM dbo.cvo_soft_alloc_det (NOLOCK) WHERE soft_alloc_no = @soft_alloc_no AND order_no = @order_no AND order_ext = @ext 
							AND	part_no = @part_no AND is_pop_gift = 1)
		BEGIN
			RETURN 0
		END
	END

	-- Get in stock
	SELECT 
		@in_stock = in_stock 
	FROM 
		dbo.inventory (NOLOCK)
	WHERE 
		location = @location 
		AND part_no = @part_no
	
	-- Get soft alloc qty
	-- START v1.1
	INSERT #soft_alloc_qty    
    EXEC dbo.cvo_get_available_stock_sp @soft_alloc_no, @location, @part_no    
  
    SELECT @sa_qty = qty FROM #soft_alloc_qty    
  
    DELETE #soft_alloc_qty 
	SET @this_order = @qty
	/*
	SELECT 
		@sa_qty = SUM(quantity) 
	FROM 
		dbo.cvo_soft_alloc_det (NOLOCK) 
	WHERE 
		part_no = @part_no 
		AND location = @location 
		AND soft_alloc_no < @soft_alloc_no 
		AND status IN (0,-1)

	-- Get qty already assigned to this order (and soft alloc no)
	SELECT 
		@this_order = SUM(quantity)
	FROM 
		dbo.cvo_soft_alloc_det (NOLOCK) 
	WHERE part_no = @part_no 
		AND location = @location 
		AND soft_alloc_no = @soft_alloc_no  
		AND line_no <> @line_no
	
	SET @this_order = ISNULL(@this_order,0) + @qty
	*/
	
	
	INSERT INTO #tbl_AvailableQtyLocation EXEC tdc_get_alloc_qntd_sp @location, @part_no 

	SELECT 
		@alloc_qty = allocated_amt,
		@quar_qty = quarantined_amt
	FROM
		#tbl_AvailableQtyLocation

	IF (ISNULL(@in_stock,0) - ISNULL(@alloc_qty,0) - ISNULL(@quar_qty,0) - ISNULL(@sa_qty,0) <= 0) 
	BEGIN
		RETURN 1
	END

	IF (ISNULL(@in_stock,0) - ISNULL(@alloc_qty,0) - ISNULL(@quar_qty,0) - ISNULL(@sa_qty,0) - ISNULL(@this_order,0) <= 0) 
	BEGIN	
		RETURN 1
	END
	
	RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[cvo_promo_obsolete_check_sp] TO [public]
GO
