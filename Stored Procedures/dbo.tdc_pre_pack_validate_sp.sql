SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
CREATE PROC [dbo].[tdc_pre_pack_validate_sp]
	@pkg_code	varchar(10),
	@pack_type	varchar(50),
	@adh_qty	decimal(24,8),
	@err_msg	varchar(255) OUTPUT
AS 

DECLARE @part_no  	varchar(30),
	@location	varchar(10)


--------------------------------------------------------------------------------------------------
-- Make sure valid pack type is entered
--------------------------------------------------------------------------------------------------
IF @pkg_code = '[DEFAULT]'
BEGIN
	IF ISNULL(@pack_type, '') = ''
	BEGIN
		SELECT @err_msg = 'Pack Type is required'
		RETURN -1
	END
	
	IF @pack_type NOT IN ('CASE', 'MAX-PACK', 'PALLET', 'ADHOC')
	BEGIN
		SELECT @err_msg = 'Invalid Pack Type'
		RETURN -1
	END
END
--------------------------------------------------------------------------------------------------
-- Make sure adhoc qty is entered
--------------------------------------------------------------------------------------------------
IF @pack_type = 'ADHOC'	AND @adh_qty <= 0
BEGIN
	SELECT @err_msg = 'Adhoc Quantity is required'
	RETURN -2
END

--------------------------------------------------------------------------------------------------
-- Make sure something is selected
--------------------------------------------------------------------------------------------------
IF NOT EXISTS(SELECT * 
		FROM #pre_pack_plan_order_sel
	       WHERE sel_flg != 0)
BEGIN
	SELECT @err_msg = 'No consolidation sets or orders are selected'
	RETURN -3
END

IF @pack_type != 'ADHOC' AND @pkg_code = '[DEFAULT]'
BEGIN
	--------------------------------------------------------------------------------------------------
	-- Make sure part is in inv_list
	--------------------------------------------------------------------------------------------------
	SELECT @part_no = NULL
	SELECT TOP 1 @part_no = b.part_no  
	  FROM #pre_pack_plan_order_sel a,
	       tdc_soft_alloc_tbl	b (NOLOCK)
	WHERE a.sel_flg != 0
	  AND b.order_no   = a.order_no
	  AND b.order_ext  = a.order_ext
	  AND b.order_type = 'S'
	  AND b.part_no    NOT IN (SELECT part_no 
		 		     FROM tdc_inv_list (NOLOCK))
	
	IF ISNULL(@part_no, '') <> '' 
	BEGIN
		SELECT @err_msg = 'Part not setup in Inventory Maintenance: ' + @part_no
		RETURN -3
	END
	
	--------------------------------------------------------------------------------------------------
	-- Make sure part is in inv_list AT LOCATION
	--------------------------------------------------------------------------------------------------
	SELECT @location = NULL,
	       @part_no  = NULL
	
	SELECT TOP 1 @location = b.location,
		     @part_no  = b.part_no
	  FROM #pre_pack_plan_order_sel a,
	       tdc_soft_alloc_tbl	b (NOLOCK)
	WHERE a.sel_flg != 0
	  AND b.order_no   = a.order_no
	  AND b.order_ext  = a.order_ext
	  AND b.location   = a.location
	  AND b.order_type = 'S'
	  AND b.location    NOT IN (SELECT location 
				    FROM tdc_inv_list (NOLOCK)
				   WHERE part_no = b.part_no) 
	
	IF ISNULL(@location, '') <> '' 
	BEGIN
		SELECT @err_msg = 'Part not setup in Inventory Maintenance at location.' + CHAR(13) +  
				  'Part No: ' + @part_no + CHAR(13) + 
				  'Location: ' + @location
		RETURN -3
	END
	
	--------------------------------------------------------------------------------------------------
	-- Make sure part's quantities are setup
	--------------------------------------------------------------------------------------------------
	SELECT @part_no = NULL
	SELECT TOP 1 @part_no = b.part_no  
	  FROM #pre_pack_plan_order_sel a,
	       tdc_soft_alloc_tbl	b (NOLOCK),
	       tdc_inv_list		c (NOLOCK) 
	WHERE a.sel_flg != 0
	  AND b.order_no   = a.order_no
	  AND b.order_ext  = a.order_ext
	  AND b.order_type = 'S'
	  AND c.location   = b.location
	  AND c.part_no    = b.part_no
	  AND (      (@pack_type = 'CASE'     AND ISNULL(c.case_qty,   0)   = 0)
	         OR  (@pack_type = 'MAX-PACK' AND ISNULL(c.pack_qty,   0)   = 0)
	         OR  (@pack_type = 'PALLET'   AND ISNULL(c.pallet_qty, 0)   = 0)
	       )
  
	IF ISNULL(@part_no, '') <> '' 
	BEGIN
		SELECT @err_msg = 'Pre Pack quantities not setup for part number.' + CHAR(13) + 
				  'Part No: ' + @part_no + CHAR(13) + 
				  'Pack Type: ' + @pack_type
		RETURN -3
	END

END
ELSE IF @pkg_code != '[DEFAULT]'
BEGIN
		--------------------------------------------------------------------------------------------------
	-- Make sure part is in pkg_master
	--------------------------------------------------------------------------------------------------
	SELECT @part_no = NULL
	SELECT TOP 1 @part_no = b.part_no  
	  FROM #pre_pack_plan_order_sel a,
	       tdc_soft_alloc_tbl	b (NOLOCK)
	WHERE a.sel_flg != 0
	  AND b.order_no   = a.order_no
	  AND b.order_ext  = a.order_ext
	  AND b.order_type = 'S'
	  AND b.part_no    NOT IN (SELECT part_no 
		 		     FROM tdc_pkg_master (NOLOCK))
	
	IF ISNULL(@part_no, '') <> '' 
	BEGIN
		SELECT @err_msg = 'Part not setup in Package Maintenance: ' + @part_no
		RETURN -3
	END
	
	--------------------------------------------------------------------------------------------------
	-- Make sure part is in inv_list AT LOCATION
	--------------------------------------------------------------------------------------------------
	SELECT @location = NULL,
	       @part_no  = NULL
	
	SELECT TOP 1 @location = b.location,
		     @part_no  = b.part_no
	  FROM #pre_pack_plan_order_sel a,
	       tdc_soft_alloc_tbl	b (NOLOCK)
	WHERE a.sel_flg != 0
	  AND b.order_no   = a.order_no
	  AND b.order_ext  = a.order_ext
	  AND b.location   = a.location
	  AND b.order_type = 'S'
	  AND b.location    NOT IN (SELECT location 
				    FROM tdc_package_part (NOLOCK)
				   WHERE part_no = b.part_no) 
	
	IF ISNULL(@location, '') <> '' 
	BEGIN
		SELECT @err_msg = 'Part not setup in Package Maintenance at location.' + CHAR(13) +  
				  'Part No: ' + @part_no + CHAR(13) + 
				  'Location: ' + @location
		RETURN -3
	END
	
	--------------------------------------------------------------------------------------------------
	-- Make sure part's quantities are setup
	--------------------------------------------------------------------------------------------------
	SELECT @part_no = NULL
	SELECT TOP 1 @part_no = b.part_no  
	  FROM #pre_pack_plan_order_sel a,
	       tdc_soft_alloc_tbl	b (NOLOCK),
	       tdc_package_part		c (NOLOCK) 
	WHERE a.sel_flg != 0
	  AND b.order_no   = a.order_no
	  AND b.order_ext  = a.order_ext
	  AND b.order_type = 'S'
	  AND c.location   = b.location
	  AND c.part_no    = b.part_no
	  AND ISNULL(c.pack_qty, 0)   = 0 
  
	IF ISNULL(@part_no, '') <> '' 
	BEGIN
		SELECT @err_msg = 'Pre Pack quantities not setup for part number: ' + @part_no 
		RETURN -3
	END
END --IF @pkg_code != '[DEFAULT]'
 
RETURN 1

GO
GRANT EXECUTE ON  [dbo].[tdc_pre_pack_validate_sp] TO [public]
GO
