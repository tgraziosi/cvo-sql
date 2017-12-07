SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- v1.0 CB 26/04/2012 - Exclude from allocation bin setting
-- v1.1 CT 19/06/2012 - Only use bin setting to exclude from auto allocation
-- v1.2 CB 23/07/2012 - Revert back to v1.0
-- v1.3 CB 24/07/2012 - Do not allow allocation from no allocatable bins - or associated cases
-- v1.4 CB 08/10/2012 - If override qty is less than the ordered qty then use ordered qty for frame and suns
-- v1.5 CB 17/10/2012 - If the order is allocated manually in any way then remove pending soft allocation (status = 0 or -3)
-- v1.6 CB 13/12/2012 - Issue #1024 - Deal with pre-soft allocation orders
-- v1.7 CB 21/12/2012 - When allocating by line update cvo_soft_alloc just for the lines affected
-- v1.8 CB 01/05/2013 - Replace cursor
-- v1.9 CB 07/06/2013 - Issue #1289 - Frame/case relationship at order entry
-- v2.0 CB 10/06/2013 - Fix issue when manual cases are added and associated cases do not allocate
-- v2.1 CT 14/06/2013 - Issue #695 - allocation for PO ringfenced stock
-- v2.2 CB 18/06/2013 - Fix Issue when case are partially picked
-- v2.3 CB 27/06/2013 - Issue #1330 - If lines are deleted from an order and the order is then manually allocated in PWB then soft alloc is never processed
-- v2.4 CB 11/02/2015 - Issue #  - Check shipped qty when allocating
-- v2.5 CB 26/01/2016 - #1581 2nd Polarized Option
-- v2.6 CB 04/10/2016 - #1606 - Direct Putaway & Fast Track Cart
-- v2.7 CB 13/10/2017 - #1644 - Backorder Processing Reserve
-- v2.8 CB 07/11/2017 - Add process info for tdc_log

CREATE PROC [dbo].[tdc_plw_so_allocate_line_sp]            
 @user_id   varchar(50),             
 @template_code  varchar(20),            
 @order_no   int,             
 @order_ext   int,             
 @line_no   int,             
 @part_no    varchar(30),            
 @one_for_one_flg  char(1),            
 @bin_group  varchar(30),             
 @search_sort  varchar(30),             
 @alloc_type  varchar(30),             
 @pkg_code  varchar(10),            
 @replen_group  varchar(12),            
 @multiple_parts  char(1),            
 @bin_first_option varchar(10),             
 @priority  int,            
 @user_hold  char(1),             
 @cdock_flg  char(1),               
 @pass_bin  varchar(12),              
 @assigned_user  varchar(25),                
 @lbs_order_by  varchar(5000),            
 @max_qty_to_alloc decimal(20, 8) = 0           
--BEGIN SED003 -- Case Part        
--JVM 04/05/2010        
-- ,@called_by_WMS INT = 0        
--END   SED003 -- Case Part        
AS            
                    
DECLARE @dist_cust_pick  char(1),            
 @lb_tracking   char(1),            
 @qty_needed  decimal(20, 8),            
 @qty_ordered   decimal(20, 8),            
 @qty_shipped   decimal(20, 8),            
 @qty_alloc  decimal(20, 8),             
 @qty_avail  decimal(20, 8),            
 @qty_bin_will_hold decimal(20, 8),            
 @qty_mgtb2b  decimal(20, 8),             
 @qty_to_alloc    decimal(20, 8),            
 @qty_in_stock    decimal(20, 8),            
 @target_bin_qty  decimal(20, 8),            
 @ret   int,            
 @location      varchar(10),            
 @conv_factor     decimal(20, 8),            
 @lot_ser  varchar(25),            
 @bin_no   varchar(12),            
 @lb_cursor_clause  varchar(5000),            
 @stop_flg  char(1),            
 @usage_type_code  varchar(10),            
 @target_bin  varchar(12),            
 @msg    varchar(255),            
 @seq_no   int,            
 @bin_type  varchar(10),            
 @one4one_or_cons varchar(7),            
 @search_type  varchar(10),            
 @data   varchar(1000),
 @from_line_no int,
 @new_qty decimal(20,8), -- v1.3           
 @alloc_qty decimal(20,8), -- v1.3
 @polarized_part	varchar(30), -- v1.3
 @cross_dock SMALLINT, -- v2.1
 @c_bin_no VARCHAR(12), -- v2.1
 @rx_reserve int -- v2.7
    
 -- v1.8 Start
 DECLARE @row_id		int,
		 @last_row_id	int
 -- v1.8 End 

-- v2.6 Start
DECLARE @fasttrack int

SET @fasttrack = 0
IF (@bin_group = 'FASTTRACK')
BEGIN
	SET @bin_group = 'PICKAREA'
	SET @fasttrack = 1
END
-- v2.6 End
     
-- Make sure the order has not been voided            
IF EXISTS(SELECT * FROM orders (NOLOCK) WHERE order_no = @order_no AND ext = @order_ext AND status > 'Q') return            
         
-- v1.3 Start 
-- v2.5SELECT	@polarized_part = value_str FROM tdc_config (NOLOCK) WHERE [function] = 'DEF_RES_TYPE_POLARIZED'
-- v2.5IF @polarized_part IS NULL
-- v2.5	SET @polarized_part = 'CVZDEMRM'   
-- v1.3 End

-- v2.3 Start
-- Check if any line items exist in the queue that do not exist on the order
IF EXISTS (SELECT 1 FROM tdc_pick_queue a (NOLOCK) LEFT JOIN ord_list b (NOLOCK) ON a.trans_type_no = b.order_no AND a.trans_type_ext = b.order_ext
			AND	a.line_no = b.line_no WHERE a.trans_type_no = @order_no AND a.trans_type_ext = @order_ext AND a.trans = 'STDPICK' AND b.line_no IS NULL)
BEGIN
	-- Need to unallocate the lines that do not exist on the order
	DELETE	a
	FROM	tdc_soft_alloc_tbl a
	LEFT JOIN	ord_list b (NOLOCK)
	ON		a.order_no = b.order_no 
	AND		a.order_ext = b.order_ext
	AND		a.line_no = b.line_no 
	WHERE	a.order_no = @order_no 
	AND		a.order_ext = @order_ext 
	AND		b.line_no IS NULL
	AND		a.order_type = 'S'

	DELETE	a
	FROM	tdc_pick_queue a
	LEFT JOIN	ord_list b (NOLOCK)
	ON		a.trans_type_no = b.order_no 
	AND		a.trans_type_ext = b.order_ext
	AND		a.line_no = b.line_no 
	WHERE	a.trans_type_no = @order_no 
	AND		a.trans_type_ext = @order_ext 
	AND		b.line_no IS NULL
	AND		a.trans IN ('STDPICK','MGTB2B')

END
-- v2.3 End

-- START v2.1
SET @cross_dock = 0
IF (@bin_group = 'CROSSDOCK') AND (OBJECT_ID('tempdb..#backorder_processing_po_allocation') IS NOT NULL)
BEGIN
	IF EXISTS (SELECT 1 FROM #backorder_processing_po_allocation WHERE order_no = @order_no AND ext = @order_ext AND line_no = @line_no
																	AND part_no = @part_no AND bin_no = @pass_bin)
	BEGIN
		SET @cross_dock = 1
		SET @c_bin_no = @pass_bin
	END
END
-- END v2.1

-- v2.7 Start
SET @rx_reserve = 0
IF (@bin_group = 'RXRESERVE') AND (OBJECT_ID('tempdb..#backorder_processing_rx_reserve') IS NOT NULL)
BEGIN
	SET @rx_reserve = 1
	SET @c_bin_no = @pass_bin
	SET @bin_group = 'PICKAREA'
END
-- v2.7 End


------------------------------------------------------------------------------------------            
-- Get the values for the part            
------------------------------------------------------------------------------------------            
IF (SELECT part_type            
      FROM ord_list(NOLOCK)            
     WHERE order_no  = @order_no            
       AND order_ext = @order_ext            
       AND line_no   = @line_no) = 'P'            
BEGIN            
 ------------------------------------------------------------------------------------------            
 -- Not a custom kit            
 ------------------------------------------------------------------------------------------            
    SELECT @qty_ordered = a.ordered * a.conv_factor,            
   @qty_shipped = a.shipped * a.conv_factor,            
   @lb_tracking = b.lb_tracking,            
   @location    = location,            
   @conv_factor = a.conv_factor            
    FROM ord_list   a (NOLOCK),            
   inv_master b (NOLOCK)            
   WHERE a.order_no  = @order_no            
  AND a.order_ext = @order_ext            
  AND a.line_no   = @line_no            
  AND a.part_no   = @part_no            
  AND b.part_no   = a.part_no         
        
  --BEGIN SED003 -- Case Part        
  --JVM 04/05/2010        
 DECLARE @override_qty_ordered INT        
  --IF @called_by_WMS = 1        
  --BEGIN        
  SELECT  @override_qty_ordered = qty_to_alloc        
  FROM    CVO_qty_to_alloc_tbl (NOLOCK)         
  WHERE   order_no  = @order_no  AND        
    order_ext = @order_ext AND           
    line_no   = @line_no   AND         
    part_no   = @part_no        

	-- v1.4
	IF @override_qty_ordered < @qty_ordered
		SET @override_qty_ordered = @qty_ordered - @qty_shipped -- v2.4 add @qty_shipped

-- v1.3 Start
	IF OBJECT_ID('tempdb..#splits') IS NOT NULL
		DROP TABLE #splits

	CREATE TABLE #splits (
		order_no		int,
		order_ext		int,
		line_no			int,
		location		varchar(10),
		part_no			varchar(30),
		has_case		int,
		has_pattern		int,
		has_polarized	int,
		case_part		varchar(30),
		pattern_part	varchar(30),
		polarized_part	varchar(30),
		quantity		decimal(20,8),
		material		smallint,
		part_type		varchar(20),
		new_ext			int)

	INSERT	#splits (order_no, order_ext, line_no, location, part_no, has_case, has_pattern, has_polarized, case_part, 
						pattern_part, polarized_part, quantity, material, part_type, new_ext)
	SELECT	a.order_no,
			a.order_ext,
			a.line_no,
			a.location,
			a.part_no,
			CASE WHEN ISNULL(b.add_case,'N') = 'Y' THEN 1 ELSE 0 END,
			CASE WHEN ISNULL(b.add_pattern,'N') = 'Y' THEN 1 ELSE 0 END,
			CASE WHEN ISNULL(b.add_polarized,'N') = 'Y' THEN 1 ELSE 0 END,
-- v1.9		CASE WHEN ISNULL(b.add_case,'N') = 'Y' THEN c.field_1 ELSE '' END,
			CASE WHEN ISNULL(b.add_case,'N') = 'Y' THEN fc.case_part ELSE '' END, -- v1.9
-- v1.9		CASE WHEN ISNULL(b.add_pattern,'N') = 'Y' THEN c.field_4 ELSE '' END,
			CASE WHEN ISNULL(b.add_pattern,'N') = 'Y' THEN fc.pattern_part ELSE '' END, -- v1.9
-- v2.5		CASE WHEN ISNULL(b.add_polarized,'N') = 'Y' THEN @polarized_part ELSE '' END,
			CASE WHEN ISNULL(b.add_polarized,'N') = 'Y' THEN fc.polarized_part ELSE '' END, -- v2.5
			a.ordered,
			CASE WHEN LEFT(c.field_10,5) = 'metal' THEN 1 ELSE CASE WHEN LEFT(c.field_10,7) = 'plastic' THEN 2 ELSE 0 END END,
			d.type_code,
			0
	FROM	ord_list a (NOLOCK)
	JOIN	cvo_ord_list b (NOLOCK)
	ON		a.order_no = b.order_no
	AND		a.order_ext = b.order_ext
	AND		a.line_no = b.line_no
	JOIN	inv_master_add c (NOLOCK)
	ON		a.part_no = c.part_no
	LEFT JOIN cvo_ord_list_fc fc (NOLOCK) -- v1.9
	ON		a.order_no = fc.order_no -- v1.9
	AND		a.order_ext = fc.order_ext -- v1.9
	AND		a.line_no = fc.line_no -- v1.9
	JOIN	inv_master d (NOLOCK)
	ON		a.part_no = d.part_no
	WHERE	a.order_no = @order_no
	AND		a.order_ext = @order_ext
	ORDER BY a.line_no

	-- v1.6 Start
	-- if the data is an order since soft allocation was added then the #splits table is correct
	-- if the data is from a prior order then we need to update te splits table to mimic the new data
	IF EXISTS (SELECT 1 FROM cvo_ord_list (NOLOCK) WHERE order_no = @order_no AND order_ext = @order_ext AND ISNULL(from_line_no,0) <> 0)
	BEGIN
		UPDATE	a
		SET		case_part = c.part_no,
				has_case = 1
		FROM	#splits a	
		JOIN	cvo_ord_list b (NOLOCK)
		ON		a.order_no = b.order_no
		AND		a.order_ext = b.order_ext
		AND		a.line_no = b.from_line_no
		JOIN	ord_list c (NOLOCK)
		ON		b.order_no = c.order_no
		AND		b.order_ext = c.order_ext
		AND		b.line_no = c.line_no
		WHERE	a.order_no = @order_no
		AND		a.order_ext = @order_ext
		AND		b.is_case = 1

		UPDATE	a
		SET		pattern_part = c.part_no,
				has_pattern = 1
		FROM	#splits a	
		JOIN	cvo_ord_list b (NOLOCK)
		ON		a.order_no = b.order_no
		AND		a.order_ext = b.order_ext
		AND		a.line_no = b.from_line_no
		JOIN	ord_list c (NOLOCK)
		ON		b.order_no = c.order_no
		AND		b.order_ext = c.order_ext
		AND		b.line_no = c.line_no
		WHERE	a.order_no = @order_no
		AND		a.order_ext = @order_ext
		AND		b.is_pattern = 1

		UPDATE	a
		SET		polarized_part = c.part_no,
				has_polarized = 1
		FROM	#splits a	
		JOIN	cvo_ord_list b (NOLOCK)
		ON		a.order_no = b.order_no
		AND		a.order_ext = b.order_ext
		AND		a.line_no = b.from_line_no
		JOIN	ord_list c (NOLOCK)
		ON		b.order_no = c.order_no
		AND		b.order_ext = c.order_ext
		AND		b.line_no = c.line_no
		WHERE	a.order_no = @order_no
		AND		a.order_ext = @order_ext
		AND		b.is_polarized = 1

		SELECT  @override_qty_ordered = qty_to_alloc        
		FROM    CVO_qty_to_alloc_tbl (NOLOCK)         
		WHERE   order_no  = @order_no  AND        
		order_ext = @order_ext AND           
		line_no   = @line_no   AND         
		part_no   = @part_no        


	END
	ELSE
	BEGIN

		-- Case
		IF EXISTS (SELECT 1 FROM inv_master (NOLOCK) WHERE part_no = @part_no AND type_code = 'CASE')
			AND EXISTS (SELECT 1 FROM #splits WHERE line_no = @line_no AND part_no = @part_no AND has_case = 0) -- v2.0 Only associated cases
		BEGIN




			SELECT	@new_qty = ISNULL(SUM(ISNULL(quantity,0)),0)
			FROM	#splits
			WHERE	case_part = @part_no

			IF @new_qty IS NULL
				SET @new_qty = 0


			SELECT	@alloc_qty = ISNULL(SUM(ISNULL(a.qty,0)),0)
			FROM	tdc_soft_alloc_tbl a (NOLOCK)
			JOIN	#splits b
			ON		a.order_no = b.order_no
			AND		a.order_ext = b.order_ext
			AND		a.line_no = b.line_no
			WHERE	a.order_no = @order_no
			AND		a.order_ext = @order_ext
			AND		b.case_part = @part_no



			IF @alloc_qty IS NULL
				SET @alloc_qty = 0

			IF (@alloc_qty < @new_qty)
				SET @override_qty_ordered = @alloc_qty


		END
			
		-- Pattern
		IF EXISTS (SELECT 1 FROM inv_master (NOLOCK) WHERE part_no = @part_no AND type_code = 'PATTERN')
		BEGIN
			SELECT	@new_qty = ISNULL(SUM(ISNULL(quantity,0)),0)
			FROM	#splits
			WHERE	pattern_part = @part_no

			IF @new_qty IS NULL
				SET @new_qty = 0

			SELECT	@alloc_qty = ISNULL(SUM(ISNULL(a.qty,0)),0)
			FROM	tdc_soft_alloc_tbl a (NOLOCK)
			JOIN	#splits b
			ON		a.order_no = b.order_no
			AND		a.order_ext = b.order_ext
			AND		a.line_no = b.line_no
			WHERE	a.order_no = @order_no
			AND		a.order_ext = @order_ext
			AND		b.pattern_part = @part_no

			IF @alloc_qty IS NULL
				SET @alloc_qty = 0

			IF (@alloc_qty < @new_qty)
				SET @override_qty_ordered = @alloc_qty
		END

		-- Polarized
		IF (@part_no = @polarized_part )
		BEGIN
			SELECT	@new_qty = ISNULL(SUM(ISNULL(quantity,0)),0)
			FROM	#splits
			WHERE	polarized_part = @part_no

			IF @new_qty IS NULL
				SET @new_qty = 0

			SELECT	@alloc_qty = ISNULL(SUM(ISNULL(a.qty,0)),0)
			FROM	tdc_soft_alloc_tbl a (NOLOCK)
			JOIN	#splits b
			ON		a.order_no = b.order_no
			AND		a.order_ext = b.order_ext
			AND		a.line_no = b.line_no
			WHERE	a.order_no = @order_no
			AND		a.order_ext = @order_ext
			AND		b.polarized_part = @part_no

			IF @alloc_qty IS NULL
				SET @alloc_qty = 0

			IF (@alloc_qty < @new_qty)
				SET @override_qty_ordered = @alloc_qty
		END
	END
	-- v1.6 End

-- v1.3 End
            
 
  SELECT @qty_ordered = @override_qty_ordered * a.conv_factor            
  FROM   ord_list a (NOLOCK) , inv_master b (NOLOCK)            
  WHERE  a.order_no  = @order_no AND           
    a.order_ext = @order_ext AND           
    a.line_no   = @line_no   AND         
    a.part_no   = @part_no   AND         
    b.part_no   = a.part_no         
  --END         
    
 --END   SED003 -- Case Part        
END            
ELSE            
BEGIN            
 ------------------------------------------------------------------------------------------            
 -- Custom kit            
 ------------------------------------------------------------------------------------------            
 SELECT @qty_ordered = a.ordered * a.qty_per_kit * c.conv_factor,   -- rollback version 36.  SCR38244 Jim 10/25/07            
        @qty_shipped = a.kit_picked * c.conv_factor,     -- rollback version 36.  SCR38244            
        @lb_tracking = b.lb_tracking,            
        @location    = a.location,            
        @conv_factor = c.conv_factor            
   FROM tdc_ord_list_kit a (NOLOCK),            
        inv_master   b (NOLOCK),            
        ord_list_kit c (NOLOCK)            
  WHERE a.order_no   = @order_no            
    AND a.order_ext  = @order_ext            
    AND a.line_no    = @line_no            
    AND a.kit_part_no    = @part_no            
    AND b.part_no    = a.kit_part_no            
    AND c.order_no   = a.order_no            
    AND c.order_ext  = a.order_ext            
    AND c.part_no    = a.kit_part_no            
END            
            
------------------------------------------------------------------------------------------            
-- If the lbs_order_by clause is not passed and            
-- alloc type is one4one or cons only if Automatic Alloc Search was selectedin, get it.            
------------------------------------------------------------------------------------------         
IF ISNULL(@lbs_order_by, '') = ''             
   AND ((@one_for_one_flg = 'Y') OR (@one_for_one_flg = 'N' AND ISNULL(@bin_type, '') = ''))            
BEGIN            
 SET @one4one_or_cons = CASE WHEN @one_for_one_flg = 'Y' THEN 'one4one' ELSE 'cons' END            
            
 ------------------------------------------------------------------------------------------            
 -- Get the user's settings            
 ------------------------------------------------------------------------------------------            
--BEGIN SED009 -- AutoAllocation      
--JVM 07/09/2010   
--do not get bin_group again instead of use value passed as param  
--SELECT @bin_group        = bin_group,            
--END   SED009 -- AutoAllocation      
 SELECT @search_sort      = search_sort,            
        @priority         = tran_priority,            
        @user_hold        = on_hold,            
        @cdock_flg        = cdock,            
        @pass_bin         = pass_bin,            
        @bin_first_option = bin_first,            
        @bin_type  = bin_type,            
        @replen_group  = replen_group,            
        @pkg_code  = pkg_code,            
        @multiple_parts   = multiple_parts,            
        @assigned_user    = CASE WHEN user_group = ''             
              OR user_group LIKE '%DEFAULT%'             
               THEN NULL            
            ELSE         user_group            
       END,             
        @alloc_type       = CASE dist_type             
            WHEN 'PrePack'   THEN 'PR'            
            WHEN 'ConsolePick'  THEN 'PT'            
            WHEN 'PickPack'  THEN 'PP'            
            WHEN 'PackageBuilder'  THEN 'PB'            
              END,            
        @search_type      = CASE ISNULL(bin_type, '')            
     WHEN ''   THEN 'AUTOMATIC'            
     ELSE        'MANUAL'            
       END            
   FROM tdc_plw_process_templates (NOLOCK)            
  WHERE template_code  = @template_code            
    AND UserID         = @user_id            
    AND location       = @location            
 AND order_type     = 'S'            
    AND type           = @one4one_or_cons            
            
 --------------------------------------------------------------------------------------------------------------            
 -- Get the bin sort by based on the bin first option and user selected Bin Sort creteria            
 -- Used for one4one and for cons only if Automatic Alloc Search was selected            
 --------------------------------------------------------------------------------------------------------------             
 IF (@one4one_or_cons = 'one4one') OR (@one4one_or_cons = 'cons' AND @search_type = 'AUTOMATIC')            
 BEGIN            
  EXEC dbo.tdc_plw_so_get_bin_sort @search_sort, @bin_first_option,  @lbs_order_by OUTPUT            
 END            
            
 IF @alloc_type = 'PB'            
 BEGIN            
  IF EXISTS (SELECT * FROM tdc_config (NOLOCK) WHERE [function] = 'pallet_loadseq_nullable' AND value_str = 'Epicor')            
  BEGIN            
   IF NOT EXISTS (SELECT * FROM load_list (NOLOCK) WHERE order_no = @order_no AND order_ext = @order_ext)            
   BEGIN            
    SET @user_hold = 'Y'            
   END            
  END            
 END            
            
END            
            
            
----------------            
-- Set defaults            
----------------            
IF ISNULL(@bin_group,    '') = '' SET @bin_group    = '[ALL]'            
IF ISNULL(@replen_group, '') = '' SET @replen_group = '[ALL]'            
IF @pkg_code                 = '' SET @pkg_code     =  NULL            
SELECT @search_type = CASE ISNULL(@bin_type, '') WHEN '' THEN 'AUTOMATIC' ELSE 'MANUAL' END            
            
SET @data = 'Line: ' + CAST(@line_no as varchar(3)) + '; Order Type: S; ' + 'Alloc Type: ' + @alloc_type +  '; Alloc Template Code: ' + @template_code + '; One4One/Con: ' + CASE WHEN @one_for_one_flg = 'Y' THEN 'one4one' ELSE 'cons' END            

-- v2.8 Start
DECLARE @process_info varchar(255)

SELECT	@process_info = process_name
FROM	dbo.cvo_auto_alloc_process (NOLOCK)
WHERE	process_id = @@SPID

SET @data = @data + ' - Process: ' + ISNULL(@process_info,'No Info')
-- v2.8 End
            
-- Get the allocated quantity            
SET @qty_alloc = 0            
SELECT @qty_alloc = SUM(qty)            
  FROM tdc_soft_alloc_tbl       (NOLOCK) --jvm        
 WHERE order_no   = @order_no            
   AND order_ext  = @order_ext            
   AND location   = @location            
   AND part_no    = @part_no            
   AND line_no    = @line_no            
 GROUP BY location, part_no            
            
-- Determine the quantity need to allocate            
SELECT @qty_needed = @qty_ordered - @qty_alloc -- v2.2 - @qty_shipped qty override deals with this            


IF @max_qty_to_alloc > 0            
BEGIN            
 IF @qty_needed > @max_qty_to_alloc            
  SELECT @qty_needed = @max_qty_to_alloc            
END            
  
          
IF @qty_needed > 0            
BEGIN            
 ------------------------------------------------------------------------------------------            
 -- Non Lot/Bin tracked Parts            
 ------------------------------------------------------------------------------------------            
 IF @lb_tracking = 'N'            
 BEGIN             
  SET @qty_alloc = 0            
  SELECT @qty_alloc = SUM(qty)            
    FROM tdc_soft_alloc_tbl      (NOLOCK) --jvm        
   WHERE location   = @location            
     AND part_no    = @part_no            
   GROUP BY location, part_no            
    -- Get available qty = total amount of inventory in stock minus what has been allocated             
  SELECT @qty_avail = 0            
  SELECT @qty_avail = in_stock - @qty_alloc            
    FROM inventory              
   WHERE location = @location            
     AND part_no  = @part_no            
             
  SELECT @qty_avail = @qty_avail -             
   ISNULL((SELECT SUM(tp.pick_qty - tp.used_qty)             
             FROM tdc_wo_pick tp (NOLOCK),             
                  prod_list pl  (NOLOCK)             
            WHERE tp.prod_no     = pl.prod_no             
       AND tp.prod_ext    = pl.prod_ext            
              AND tp.location    = pl.location             
       AND tp.part_no     = pl.part_no             
       AND pl.status      < 'S'             
              AND pl.lb_tracking = 'N'             
              AND pl.location    = @location             
       AND pl.part_no     = @part_no), 0)            
             
  /* determine IF we have enough quantity to allocate AND SET a common UPDATE variable */            
  IF (@qty_avail >= @qty_needed)            
  BEGIN            
   IF @conv_factor <> 1            
    SELECT @qty_to_alloc = FLOOR(@qty_needed / @conv_factor) * @conv_factor            
   ELSE            
    SELECT @qty_to_alloc = @qty_needed            
  END            
  ELSE            
  BEGIN            
   IF @conv_factor <> 1            
    SELECT @qty_to_alloc = FLOOR(@qty_avail / @conv_factor) * @conv_factor            
   ELSE            
    SELECT @qty_to_alloc = @qty_avail            
  END            
             
  IF(@qty_to_alloc > 0)            
  BEGIN            
   IF EXISTS (SELECT * FROM tdc_soft_alloc_tbl       (NOLOCK) --jvm        
        WHERE order_no   = @order_no            
          AND order_ext  = @order_ext            
          AND order_type = 'S'            
     AND location   = @location             
          AND line_no    = @line_no             
          AND part_no    = @part_no)            
            
    UPDATE tdc_soft_alloc_tbl            
       SET qty           = qty  + @qty_to_alloc,            
           dest_bin      = @pass_bin,            
           q_priority    = @priority,            
           assigned_user = @assigned_user,            
           user_hold     = @user_hold,            
           pkg_code      = @pkg_code            
            WHERE order_no      = @order_no             
       AND order_ext     = @order_ext            
              AND order_type    = 'S'            
              AND location      = @location             
              AND line_no       = @line_no            
              AND part_no       = @part_no             
   ELSE            
   BEGIN                
    INSERT INTO tdc_soft_alloc_tbl(order_no, order_ext, location, line_no, part_no,lot_ser, bin_no, qty, order_type,             
         target_bin, dest_bin, alloc_type, q_priority, assigned_user, user_hold, pkg_code)            
    VALUES  (@order_no, @order_ext, @location, @line_no, @part_no, NULL, NULL, @qty_to_alloc, 'S', NULL, @pass_bin,          
      @alloc_type, @priority, @assigned_user, @user_hold, @pkg_code)            
   END             
            
   INSERT INTO tdc_log (tran_date, UserID, trans_source, module, trans, tran_no, tran_ext, part_no, lot_ser, bin_no, location, quantity, data)            
   VALUES(GETDATE(), @user_id, 'VB', 'PLW', 'ALLOCATION', @order_no, @order_ext, @part_no, NULL, NULL, @location, @qty_to_alloc, @data)            
  END            
 END -- @lb_tracking = 'N'            
 ------------------------------------------------------------------------------------------            
 -- Lot/Bin tracked Parts            
 ------------------------------------------------------------------------------------------            
 ELSE            
BEGIN               
	-- This flag will become 'Y' when we allocated a part            
	SET @stop_flg = 'N'             
            
	WHILE @stop_flg = 'N'            
	BEGIN              
   -- Declare cursor as a string so we can dynamically change ORDER BY clause            
         
--BEGIN SED009 -- AutoAllocation      
--JVM 07/09/2010         
   /*SELECT @lb_cursor_clause = 'DECLARE lb_cur CURSOR FOR     ' +            
    ' SELECT TOP 1 lb.lot_ser, lb.bin_no, bm.usage_type_code,  ' +            
    '        qty_avail = (        ' +            
    '  SUM(qty) -        ' + -- Sum of the quantity in lot_bin_stock            
    '  (SELECT ISNULL((SELECT SUM(qty)     ' + -- Subtract the quantity allocated            
    '        FROM tdc_soft_alloc_tbl (NOLOCK)     ' +            
    '     WHERE location = lb.location   ' +            
    '       AND part_no = lb.part_no   ' +       
    '       AND lot_ser = lb.lot_ser   ' +            
    '       AND bin_no = lb.bin_no)   ' +            
    '  , 0)))       ' +            
    '  FROM lot_bin_stock lb, tdc_bin_master bm      ' +            
    ' WHERE lb.location   = ''' + @location + '''    ' +             
    '   AND lb.part_no    = ''' + @part_no + '''    ' +             
    '   AND lb.bin_no     = bm.bin_no     ' +            
    '   AND lb.location   = bm.location     ' */      
      
   --do not include custom bin as available bin_no  
   -- DMoon removed F01-KEY Bin and TRANSFER bin     
   -- v1.8 Start  
--   SELECT @lb_cursor_clause = 'DECLARE lb_cur CURSOR FOR     ' +            
--    ' SELECT TOP 1 lb.lot_ser, lb.bin_no, bm.usage_type_code,  ' +            
--    '        qty_avail = (        ' +            
--    '  SUM(qty) -        ' + -- Sum of the quantity in lot_bin_stock            
--    '  (SELECT ISNULL((SELECT SUM(qty)     ' + -- Subtract the quantity allocated            
--    '        FROM tdc_soft_alloc_tbl (NOLOCK)     ' +            
--    '     WHERE location = lb.location   ' +            
--    '       AND part_no = lb.part_no   ' +            
--    '       AND lot_ser = lb.lot_ser   ' +            
--    '       AND bin_no = lb.bin_no)   ' +            
--    '  , 0)))       ' +            
--    '  FROM lot_bin_stock lb (NOLOCK), tdc_bin_master bm (NOLOCK)     ' +            
--    ' WHERE lb.location   = ''' + @location + '''    ' +             
--    '   AND lb.part_no    = ''' + @part_no + '''    ' +             
--    '   AND lb.bin_no     = bm.bin_no     ' + 
--	-- v1.2 START
--	-- START v1.1           
--    '   AND lb.location   = bm.location     ' -- +


	SELECT @lb_cursor_clause = 'INSERT #lb_cur (lot_ser,	bin_no, usage_type_code, qty_avail)     ' +            
    ' SELECT TOP 1 lb.lot_ser, lb.bin_no, bm.usage_type_code,  ' +            
    '        qty_avail = (        ' +            
    '  SUM(qty) -        ' + -- Sum of the quantity in lot_bin_stock            
    '  (SELECT ISNULL((SELECT SUM(qty)     ' + -- Subtract the quantity allocated            
    '        FROM tdc_soft_alloc_tbl (NOLOCK)     ' +            
    '     WHERE location = lb.location   ' +            
    '       AND part_no = lb.part_no   ' +            
    '       AND lot_ser = lb.lot_ser   ' +            
    '       AND bin_no = lb.bin_no)   ' +            
    '  , 0)))       ' +            
    '  FROM lot_bin_stock lb (NOLOCK), tdc_bin_master bm (NOLOCK)     ' +            
    ' WHERE lb.location   = ''' + @location + '''    ' +             
    '   AND lb.part_no    = ''' + @part_no + '''    ' +             
    '   AND lb.bin_no     = bm.bin_no     ' + 
    '   AND lb.location   = bm.location     ' 
-- v1.8 End

	-- START v2.1
	-- v2.7 IF @cross_dock = 0
	IF (@cross_dock = 0 AND @rx_reserve = 0) -- v2.7
	BEGIN

--	IF @user_id = 'AUTO_ALLOC'
--	BEGIN
		SELECT @lb_cursor_clause = @lb_cursor_clause + '   AND ISNULL(bm.bm_udef_e,'''') = '''' '     -- v1.0                
--	END
    -- END v1.1  
	-- v1.2 END       
	
--END   SED009 -- AutoAllocation         
      
		IF @bin_group <> '[ALL]'            
		BEGIN 	           
			SELECT @lb_cursor_clause = @lb_cursor_clause + ' AND bm.group_code = ''' + @bin_group + ''''             
		END            
	            
		IF @search_type = 'AUTOMATIC'            
			SELECT @lb_cursor_clause = @lb_cursor_clause + ' AND bm.usage_type_code IN (''OPEN'', ''REPLENISH'') '            
		ELSE         -- MANUAL            
		BEGIN            
			SELECT @lb_cursor_clause = @lb_cursor_clause + ' AND bm.usage_type_code = ' + @bin_type            
			SET @lbs_order_by = ''            
		END   

		-- v2.6 Start
		IF (@fasttrack = 0)
		BEGIN
			SELECT @lb_cursor_clause = @lb_cursor_clause + ' AND LEFT(bm.bin_no,4) <> ''ZZZ-'''             
		END         
		ELSE
		BEGIN
			SELECT @lb_cursor_clause = @lb_cursor_clause + ' AND LEFT(bm.bin_no,4) = ''ZZZ-'''             
		END         
    END
	ELSE	
	BEGIN
		SELECT @lb_cursor_clause = @lb_cursor_clause + '   AND lb.bin_no = ''' + @c_bin_no + ''' '     -- v1.0   
	END
	-- END v2.1         
	SELECT @lb_cursor_clause = @lb_cursor_clause +            
    ' GROUP BY lb.location, lb.part_no, lb.lot_ser, lb.bin_no,   ' +            
    '          lb.date_expires, bm.usage_type_code, lb.qty   ' +            
    'HAVING SUM(qty) > (SELECT ISNULL((SELECT SUM(qty)   ' +             
    '         FROM tdc_soft_alloc_tbl    (NOLOCK) ' +            
    '        WHERE location = lb.location ' +             
    '          AND part_no  = lb.part_no  ' +             
    '          AND lot_ser  = lb.lot_ser  ' +             
    '          AND bin_no   = lb.bin_no)  ' +             
    '    , 0))       ' +            
     @lbs_order_by            

   -- v1.8 Start
	CREATE TABLE #lb_cur (
		row_id			int IDENTITY(1,1),
		lot_ser			varchar(25),
		bin_no			varchar(30),
		usage_type_code	varchar(10),
		qty_avail		decimal(20,8))
   
	EXEC (@lb_cursor_clause)    

	CREATE INDEX #lb_cur_ind0 ON #lb_cur ( row_id)
                 
--   OPEN lb_cur            
--   FETCH NEXT FROM lb_cur INTO @lot_ser, @bin_no, @usage_type_code, @qty_avail            
            
   -- If no bins are found, exit the outer while loop              

	IF NOT EXISTS (SELECT 1 FROM #lb_cur)
	BEGIN
		SELECT @stop_flg = 'Y'            
            
		-----------------------            
		-- Cross Docking            
		-----------------------            
		IF @qty_needed > 0 AND @cdock_flg = 'Y'            
		BEGIN            
		 INSERT INTO tdc_soft_alloc_tbl(order_no, order_ext, location, line_no, part_no,lot_ser, bin_no, qty, order_type,             
			  target_bin, dest_bin, alloc_type, q_priority, assigned_user, user_hold, pkg_code)            
		 VALUES  (@order_no, @order_ext, @location, @line_no, @part_no, 'CDOCK', 'CDOCK', @qty_needed, 'S', NULL,             
		   @pass_bin, @alloc_type, @priority, @assigned_user, @user_hold, @pkg_code)            
	            
		 EXEC @seq_no = tdc_queue_get_next_seq_num 'tdc_pick_queue', @priority            
	            
		 INSERT INTO tdc_pick_queue (trans_source, trans,  priority,  seq_no, company_no, location, warehouse_no, trans_type_no, trans_type_ext,             
				tran_receipt_no, line_no, pcsn, part_no, eco_no, lot, mfg_lot, mfg_batch, serial_no, bin_no, qty_to_process,             
				qty_processed, qty_short, next_op, tran_id_link, date_time, assign_group, assign_user_id, [user_id], status, tx_status, tx_control, tx_lock)            
		 VALUES ('PLW', 'SO-CDOCK', @priority, @seq_no, NULL, @location, NULL, @order_no, @order_ext, NULL, @line_no, NULL, @part_no, NULL, 'CDOCK', NULL, NULL, NULL, 'CDOCK',            
		  @qty_needed, 0, 0, NULL, NULL, GETDATE(), NULL, @assigned_user, NULL, NULL, NULL, 'M', 'V')            
	            
		 INSERT INTO tdc_log (tran_date, UserID, trans_source, module, trans, tran_no, tran_ext, part_no, lot_ser, bin_no, location, quantity, data)            
		 VALUES(GETDATE(), @user_id, 'VB', 'PLW', 'ALLOCATION', @order_no, @order_ext, @part_no, 'CDOCK', 'CDOCK', @location, @qty_needed, @data)            
		END            
	END       
	ELSE
	BEGIN

		SET @last_row_id = 0

		SELECT	TOP 1 @row_id = row_id,
				@lot_ser = lot_ser,	
				@bin_no = bin_no, 
				@usage_type_code = usage_type_code, 
				@qty_avail = qty_avail
		FROM	#lb_cur
		WHERE	row_id > @last_row_id
		ORDER BY row_id ASC

		WHILE (@@ROWCOUNT <> 0 AND @stop_flg = 'N')     -- v1.8
-- v1.8   WHILE (@@FETCH_STATUS = 0 AND @stop_flg = 'N')            
		BEGIN            
    ------------------------------------------------------------------------------------------            
    -- If no bin to bin move, just insert/update the quantities            
    ------------------------------------------------------------------------------------------              
			IF @usage_type_code = 'REPLENISH' OR @one_for_one_flg = 'Y'             
			BEGIN            
             
     -- No bin to bin move, the target bin IS the bin number            
			    SELECT @target_bin = @bin_no            
             
     ------------------------------------------------------------------------------------------            
     -- Enough stock in the bin to fill the line            
     ------------------------------------------------------------------------------------------            
				IF @qty_avail >= @qty_needed            
				BEGIN            
					IF EXISTS (SELECT * FROM tdc_soft_alloc_tbl       (NOLOCK) --jvm        
						WHERE order_no   = @order_no             
						 AND order_ext  = @order_ext            
						 AND order_type = 'S'            
						 AND location   = @location             
						 AND line_no    = @line_no            
						 AND part_no    = @part_no             
						 AND lot_ser    = @lot_ser             
						 AND bin_no     = @bin_no)            
					BEGIN            
		              
						UPDATE tdc_soft_alloc_tbl            
							SET qty           = qty  + @qty_needed,            
							dest_bin      = @pass_bin,            
						  q_priority    = @priority,            
						  assigned_user = @assigned_user,            
								 user_hold     = @user_hold,            
						  pkg_code      = @pkg_code            
						   WHERE order_no      = @order_no             
					  AND order_ext     = @order_ext            
							 AND order_type    = 'S'            
							 AND location      = @location             
							 AND line_no       = @line_no            
							 AND part_no       = @part_no             
							 AND lot_ser       = @lot_ser             
							 AND bin_no        = @bin_no            
					END            
					ELSE            
					BEGIN           
		  
					   INSERT INTO tdc_soft_alloc_tbl            
						(order_no, order_ext, location, line_no, part_no,lot_ser, bin_no, qty, order_type,             
						 target_bin, dest_bin, alloc_type, q_priority, assigned_user, user_hold, pkg_code)            
					   VALUES  (@order_no, @order_ext, @location, @line_no, @part_no, @lot_ser, @bin_no, @qty_needed,             
						 'S', @target_bin, @pass_bin, @alloc_type, @priority, @assigned_user, @user_hold, @pkg_code)            
					  END                
				              
					  SELECT @stop_flg = 'Y'            
			            
					  INSERT INTO tdc_log (tran_date, UserID, trans_source, module, trans, tran_no, tran_ext, part_no, lot_ser, bin_no, location, quantity, data)            
					  VALUES(GETDATE(), @user_id, 'VB', 'PLW', 'ALLOCATION', @order_no, @order_ext, @part_no, @lot_ser, @bin_no, @location, @qty_needed, @data)  

		          
					END            
					------------------------------------------------------------------------------------------            
					-- Less in the bin than needed            
					------------------------------------------------------------------------------------------            
					ELSE             
					BEGIN            
						IF EXISTS (SELECT * FROM tdc_soft_alloc_tbl       (NOLOCK) --jvm        
						   WHERE order_no   = @order_no             
							 AND order_ext  = @order_ext            
							 AND order_type = 'S'            
							 AND location   = @location             
							 AND line_no    = @line_no            
							 AND part_no    = @part_no             
							 AND lot_ser    = @lot_ser             
							 AND bin_no     = @bin_no)            
						BEGIN            
						   UPDATE tdc_soft_alloc_tbl            
							  SET qty           = qty  + @qty_avail,            
								  dest_bin      = @pass_bin,            
								  q_priority    = @priority,            
								  assigned_user = @assigned_user,            
										 user_hold     = @user_hold,            
								  pkg_code      = @pkg_code            
								   WHERE order_no      = @order_no             
							  AND order_ext     = @order_ext            
									 AND order_type    = 'S'            
									 AND location      = @location             
									 AND line_no       = @line_no            
									 AND part_no       = @part_no             
									 AND lot_ser       = @lot_ser             
									 AND bin_no        = @bin_no            
						END            
						ELSE            
						BEGIN            
		            
						   INSERT INTO tdc_soft_alloc_tbl            
							(order_no, order_ext, location, line_no, part_no,lot_ser, bin_no, qty, order_type, target_bin,             
							 dest_bin, alloc_type, q_priority, assigned_user, user_hold, pkg_code)            
						   VALUES  (@order_no, @order_ext, @location, @line_no, @part_no, @lot_ser, @bin_no, @qty_avail, 'S',             
							 @target_bin, @pass_bin, @alloc_type, @priority, @assigned_user, @user_hold, @pkg_code)                 
						END               
		              
						SELECT @qty_needed = @qty_needed - @qty_avail            

						INSERT INTO tdc_log (tran_date, UserID, trans_source, module, trans, tran_no, tran_ext, part_no, lot_ser, bin_no, location, quantity, data)            
						VALUES(GETDATE(), @user_id, 'VB', 'PLW', 'ALLOCATION', @order_no, @order_ext, @part_no, @lot_ser, @bin_no, @location, @qty_avail, @data)            


					END  
		             
				END            
				ELSE             
				------------------------------------------------------------------------------------------            
				-- Needing a bin to bin move             
				------------------------------------------------------------------------------------------             
				BEGIN             
					WHILE @qty_avail > 0 AND @qty_needed > 0 AND @stop_flg = 'N'            
					BEGIN            
					  -- Find the next bin to move to            
						EXEC @ret = tdc_plw_so_get_b2b @location, @part_no, @replen_group, @multiple_parts, @target_bin OUTPUT, @target_bin_qty OUTPUT            
		            
						-- If no replenish bins were found, exit both loops            
						IF @ret != 0            
						BEGIN             
							SELECT @stop_flg = 'Y'       
						   INSERT INTO #so_alloc_err(order_no, order_ext, line_no, part_no, err_msg)            
						   VALUES(@order_no, @order_ext, @line_no, @part_no, 'There are no target bins available')            
						END            
						ELSE -- Replenish bin was found, use it.            
						BEGIN            
							-- if the bin will hold more than available to move, SET them equal.            
							IF @target_bin_qty > @qty_avail  SELECT @target_bin_qty = @qty_avail            
							IF @target_bin_qty > @qty_needed SELECT @target_bin_qty = @qty_needed            
		               
						   ------------------------------------------------------------------------------------------            
							-- Enough stock in the bin to fill the line            
							------------------------------------------------------------------------------------------            
							IF @target_bin_qty >= @qty_needed            
							BEGIN            
								IF EXISTS (SELECT * FROM tdc_soft_alloc_tbl       (NOLOCK) --jvm        
											WHERE order_no   = @order_no             
										   AND order_ext  = @order_ext            
										   AND order_type = 'S'            
										   AND location   = @location             
										   AND line_no    = @line_no            
										   AND part_no    = @part_no             
										   AND lot_ser    = @lot_ser             
										   AND bin_no     = @bin_no              
										   AND target_bin = @target_bin)            
								BEGIN              
		                 
									 UPDATE tdc_soft_alloc_tbl            
										SET qty           = qty  + @qty_needed,            
											dest_bin      = @pass_bin,            
											q_priority    = @priority,            
											assigned_user = @assigned_user,            
												   user_hold     = @user_hold,            
											pkg_code      = @pkg_code            
											 WHERE order_no      = @order_no             
										AND order_ext     = @order_ext            
											   AND order_type    = 'S'            
											   AND location      = @location             
											   AND line_no       = @line_no            
											   AND part_no       = @part_no             
											   AND lot_ser       = @lot_ser             
											   AND bin_no        = @bin_no              
										AND target_bin    = @target_bin            
								END            
								ELSE            
								BEGIN            
									 INSERT INTO tdc_soft_alloc_tbl            
									  (order_no, order_ext, location, line_no, part_no,lot_ser, bin_no, qty, order_type,            
									   target_bin, dest_bin, alloc_type, q_priority, assigned_user, user_hold, pkg_code)            
									 VALUES  (@order_no, @order_ext, @location, @line_no, @part_no, @lot_ser, @bin_no, @qty_needed,             
									   'S', @target_bin, @pass_bin, @alloc_type, @priority, @assigned_user, @user_hold, @pkg_code)            
		                   
								END              
		            
								INSERT INTO tdc_log (tran_date, UserID, trans_source, module, trans, tran_no, tran_ext, part_no, lot_ser, bin_no, location, quantity, data)            
								VALUES(GETDATE(), @user_id, 'VB', 'PLW', 'ALLOCATION', @order_no, @order_ext, @part_no, @lot_ser, @bin_no, @location, @qty_needed, @data)  

							END            
		            
						   ------------------------------------------------------------------------------------------            
						   -- Less in the bin than needed            
						   ------------------------------------------------------------------------------------------            
						   ELSE IF @target_bin_qty < @qty_needed            
						   BEGIN            
								IF EXISTS (SELECT * FROM tdc_soft_alloc_tbl      (NOLOCK) --jvm        
									WHERE order_no   = @order_no             
									   AND order_ext  = @order_ext            
									   AND order_type = 'S'            
									   AND location   = @location             
									   AND line_no    = @line_no            
									   AND part_no    = @part_no             
									   AND lot_ser    = @lot_ser             
									   AND bin_no     = @bin_no                  AND target_bin = @target_bin)            
								BEGIN              
		                 
									 UPDATE tdc_soft_alloc_tbl             
								   SET qty           = qty  + @target_bin_qty,            
											dest_bin      = @pass_bin,            
											q_priority    = @priority,            
											assigned_user = @assigned_user,            
												   user_hold     = @user_hold,            
											pkg_code      = @pkg_code            
											 WHERE order_no      = @order_no             
										AND order_ext     = @order_ext            
											   AND order_type    = 'S'            
											   AND location      = @location             
											   AND line_no       = @line_no            
											   AND part_no       = @part_no             
											   AND lot_ser       = @lot_ser             
											   AND bin_no        = @bin_no              
										AND target_bin    = @target_bin            
								END            
								ELSE            
								BEGIN            
									 INSERT INTO tdc_soft_alloc_tbl            
									  (order_no, order_ext, location, line_no, part_no,lot_ser, bin_no, qty, order_type,             
									   target_bin, dest_bin, alloc_type, q_priority, assigned_user, user_hold, pkg_code)            
										VALUES  (@order_no, @order_ext, @location, @line_no, @part_no, @lot_ser, @bin_no,            
									   @target_bin_qty, 'S', @target_bin, @pass_bin, @alloc_type, @priority,             
										   @assigned_user, @user_hold, @pkg_code)            
								END               
		                       
								INSERT INTO tdc_log (tran_date, UserID, trans_source, module, trans, tran_no, tran_ext, part_no, lot_ser, bin_no, location, quantity, data)            
								VALUES(GETDATE(), @user_id, 'VB', 'PLW', 'ALLOCATION', @order_no, @order_ext, @part_no, @lot_ser, @bin_no, @location, @target_bin_qty, @data)         

							END             
		             
							SELECT @qty_needed = @qty_needed - @target_bin_qty            
							SELECT @qty_avail  = @qty_avail  - @target_bin_qty            
		            
							IF @qty_needed = 0 SELECT @stop_flg = 'Y'            
						END            
					END            
				END            


				IF @qty_needed <= 0 SELECT @stop_flg = 'Y'            
		               
			-- Get the next bin record 
		-- v1.8 Start   
			SET @last_row_id = @row_id

			SELECT	TOP 1 @row_id = row_id,
					@lot_ser = lot_ser,	
					@bin_no = bin_no, 
					@usage_type_code = usage_type_code, 
					@qty_avail = qty_avail
			FROM	#lb_cur
			WHERE	row_id > @last_row_id
			ORDER BY row_id ASC            
		--    FETCH NEXT FROM lb_cur INTO @lot_ser, @bin_no, @usage_type_code, @qty_avail             
		END        

		DROP TABLE #lb_cur 
	END            
              
--   CLOSE      lb_cur            
--   DEALLOCATE lb_cur            

-- v1.8 End
	END            
 END            
END   
  
GO

GRANT EXECUTE ON  [dbo].[tdc_plw_so_allocate_line_sp] TO [public]
GO
