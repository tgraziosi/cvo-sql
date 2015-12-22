SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[tdc_plw_wo_alloc_management_sp] 
	@where_clause1 		varchar(255), 
	@where_clause2 		varchar(255), 
	@where_clause3 		varchar(255), 
	@where_clause4 		varchar(255), 
	@order_by_clause	varchar(255),
	@pct_filter 		decimal(15,2),
	@user_id		varchar(50)

AS

DECLARE @insert_clause		varchar (255),
	@select_clause 		varchar (255),
	@from_clause 		varchar (255),
	@where_clause 		varchar (255),
	@groupby_clause 	varchar (255),
	@declare_clause 	varchar (255)

DECLARE @prod_no 		int,
	@prod_ext 		int,
	@location 		varchar(10),
	@rm_part		varchar(30),
	@fg_part		varchar(30),
	@line_no    		int,
	@lb_tracking		char(1)	

DECLARE	@qty_in_stock			decimal(20,8),
	@qty_plan_for_part_line_no	decimal(24,8),
	@qty_used_for_part_line_no	decimal(20,8),
	@qty_alloc_for_part_total	decimal(20,8),	
	@qty_alloc_for_part_line_no	decimal(20,8),
	@qty_avail_for_part_total	decimal(20,8),
	@qty_avail_for_part_line_no	decimal(24,8),
	@qty_pre_allocated_total  	decimal(20,8),
	@qty_pre_alloc_for_part_on_wo  	decimal(20,8),
	@qty_picked_for_part_line_no	decimal(24,8),
	@qty_needed_for_part_line_no 	decimal(24,8),
	@qty_picked_for_wo		decimal(24,8)

DECLARE	@alloc_pct_for_wo		decimal(24,8),
	@alloc_pct_for_part_line_no	decimal(24,8),
	@cur_fill_pct_for_wo		decimal(24,8),
	@avail_pct_for_part_line_no 	decimal(24,8)

DECLARE @temp_all_qty			decimal(24,8),
	@temp_alloc_qty			decimal(24,8),
	@temp_plan_qty			decimal(24,8)

TRUNCATE TABLE #wo_allocation_detail_view
TRUNCATE TABLE #wo_alloc_management
TRUNCATE TABLE #wo_pre_allocation_table

------------------------------------------------------------------------------------------------------------------------------------

-- First we get all the data we can get for the #wo_alloc_management table.
-- Later we'll update the the feilds that have to be calculated

SELECT @insert_clause   = 'INSERT INTO #wo_alloc_management
				  (sel_flg, sel_flg2, prev_alloc_pct, curr_alloc_pct, curr_fill_pct, 
    			 	   prod_no, prod_ext, location, fg_part, fg_desc, wo_status, sch_date, staging_area, shift) '
SELECT @select_clause   = 'SELECT 0, 0, 0, 0, 0, prod_no, prod_ext, location, part_no, ISNULL([description], ''''),
				  status, sch_date, ISNULL(staging_area, ''''), ISNULL(shift, '''')'
SELECT @from_clause	= '  FROM produce a (NOLOCK)'
SELECT @where_clause	= ' WHERE prod_type = ''R'''
SELECT @groupby_clause	= ' GROUP BY prod_no, prod_ext, location, part_no, [description], status, sch_date, staging_area, shift'

--  INSERT INTO #wo_alloc_management
EXEC (@insert_clause + 
      @select_clause + 
      @from_clause   + 
      @where_clause  + @where_clause1 + @where_clause2 + @where_clause3 + @where_clause4 +
      @groupby_clause)

-- Update previously allocated percentage field
UPDATE #wo_alloc_management
   SET prev_alloc_pct = ISNULL(fill_pct, 0)
  FROM #wo_alloc_management  a,
       tdc_alloc_history_tbl b (NOLOCK)
 WHERE prod_no    = order_no 
   AND prod_ext   = order_ext 
   AND order_type = 'W'
   AND a.location = b.location 
   
----------------------------------------------------------

-- Now we'll loop through the Work Orders and populate the #wo_allocation_detail_view,
-- and calculate all the data we need for the #wo_alloc_management table

----------------------------------------------------------------------------------------------------------
-- selected_detail_cursor declaration is being executed as a string so the order by clause that is sent by  --
-- the VB app can be applied this process is important in that it will determine what orders get rights --
-- to the inventory first.                                                                              --
----------------------------------------------------------------------------------------------------------
SELECT @declare_clause = 'DECLARE selected_detail_cursor CURSOR FOR SELECT prod_no, prod_ext, location FROM #wo_alloc_management '

EXEC (@declare_clause + @order_by_clause)	

OPEN selected_detail_cursor
FETCH NEXT FROM selected_detail_cursor INTO @prod_no, @prod_ext, @location

WHILE (@@FETCH_STATUS = 0)
BEGIN

------------------------------------------------------------------------------------------------------------------------------------
	-- Now we'll get all the data we can get for the #wo_allocation_detail_view table.
	-- Later we'll update the the feilds that have to be calculated.

	INSERT INTO #wo_allocation_detail_view (prod_no, prod_ext, location, line_no, seq_no, rm_part, rm_desc, lb_tracking, 
						qty_plan, qty_avail, qty_picked, qty_used, qty_alloc, avail_pct, alloc_pct)
	SELECT prod_no, prod_ext, location, line_no, seq_no, part_no, ISNULL([description], ''), lb_tracking, plan_qty, 0, 0, used_qty, 0, 0, 0
	  FROM prod_list (NOLOCK)
	 WHERE prod_no  = @prod_no
	   AND prod_ext = @prod_ext
	   AND line_no  > 1
	   AND location = @location
	   AND part_type IN ('M','P')
	   AND direction <> 1

	DECLARE detail_cursor CURSOR FOR	
		SELECT rm_part, line_no, qty_plan, qty_used, lb_tracking 
		  FROM #wo_allocation_detail_view 
		 WHERE prod_no  = @prod_no
		   AND prod_ext = @prod_ext
		   AND location = @location
		 ORDER BY line_no
	
	OPEN detail_cursor 
	
	SELECT @qty_plan_for_part_line_no = 0, @qty_used_for_part_line_no = 0
	FETCH NEXT FROM detail_cursor INTO @rm_part, @line_no, @qty_plan_for_part_line_no, @qty_used_for_part_line_no, @lb_tracking
	
	WHILE (@@FETCH_STATUS = 0)
	BEGIN
		------------------------------------------------------------------------------------------------------------------
		--		Get allocated qty and qty to be allocated for the part / line_no				--
		------------------------------------------------------------------------------------------------------------------

		--  Get allocated qty for the rm_part/line_no on the order remove any reference to cross dock bins 					 
		SELECT @qty_alloc_for_part_line_no = 0
		SELECT @qty_alloc_for_part_line_no = SUM(qty)
		  FROM tdc_soft_alloc_tbl (NOLOCK)
		 WHERE order_no   = @prod_no
		   AND order_ext  = @prod_ext
	   	   AND order_type = 'W'
		   AND location   = @location
		   AND line_no    = @line_no
		   AND part_no    = @rm_part
		   AND ((lot_ser != 'CDOCK' AND bin_no != 'CDOCK') OR (lot_ser IS NULL AND bin_no IS NULL))								
		
		SELECT @qty_alloc_for_part_line_no = ISNULL(@qty_alloc_for_part_line_no, 0)

		--  Get Picked Qty for the rm_part/line_no on the order
		SELECT @qty_picked_for_part_line_no = 0
		SELECT @qty_picked_for_part_line_no = SUM(pick_qty) - SUM(used_qty)
		  FROM tdc_wo_pick (NOLOCK)
		 WHERE prod_no  = @prod_no
		   AND prod_ext = @prod_ext
		   AND location = @location
		   AND line_no  = @line_no
		   AND part_no  = @rm_part

		SELECT @qty_picked_for_part_line_no = ISNULL(@qty_picked_for_part_line_no,0)

		------------------------------------------------------------------------------------------------------------------
		--		Get qty that is needed for the rm_part/line_no on the order					--
		------------------------------------------------------------------------------------------------------------------
		SELECT @qty_needed_for_part_line_no = 0

		SELECT @qty_needed_for_part_line_no = (@qty_plan_for_part_line_no - @qty_used_for_part_line_no) - @qty_alloc_for_part_line_no - @qty_picked_for_part_line_no

		--------------------------------------------------------------------------------------------------------------------------

		-- Get In Stock qty for the rm_part from all the BINs except the receipt BINs
		SELECT @qty_in_stock = 0

		IF @lb_tracking = 'N' 
		BEGIN
			-- Get picked qty for all the WOs
			SELECT @qty_picked_for_wo = 0
			SELECT @qty_picked_for_wo = SUM(pick_qty) - SUM(used_qty)
  			  FROM tdc_wo_pick (NOLOCK)
			 WHERE part_no  = @rm_part 
			   AND location = @location
			 GROUP BY location

			SELECT @qty_picked_for_wo = ISNULL(@qty_picked_for_wo,0)

			SELECT @qty_in_stock = (in_stock - @qty_picked_for_wo)
  			  FROM inventory (NOLOCK)
			 WHERE part_no  = @rm_part 
			   AND location = @location
		END
		ELSE  	
		BEGIN
			SELECT @qty_in_stock = SUM(qty) 
	  	          FROM lot_bin_stock a (NOLOCK), tdc_bin_master b (NOLOCK) 
	                 WHERE a.location = @location 
	   	           AND a.part_no  = @rm_part
	   		   AND a.bin_no   = b.bin_no 
	   		   AND a.location = b.location 
	   		   AND b.usage_type_code IN ('OPEN', 'REPLENISH')
		         GROUP BY a.part_no

		END

		SELECT @qty_in_stock = ISNULL(@qty_in_stock,0)

		--  Get allocated qty for the rm_part for all the orders. Remove any reference to cross dock BINs. 					 
		SELECT @qty_alloc_for_part_total  = 0
		SELECT @qty_alloc_for_part_total  = SUM(qty)
		  FROM tdc_soft_alloc_tbl (NOLOCK)
		 WHERE location   = @location
		   AND part_no    = @rm_part
		   AND ((lot_ser != 'CDOCK' AND bin_no != 'CDOCK') OR (lot_ser IS NULL AND bin_no IS NULL))								
		 GROUP BY location

		SELECT @qty_alloc_for_part_total  = ISNULL( @qty_alloc_for_part_total,0)

		-- Get pre-allocated qty for the part on all the Work Orders
		SELECT @qty_pre_allocated_total   = 0
		SELECT @qty_pre_allocated_total   = isnull(SUM(pre_allocated_qty),0)
		  FROM #wo_pre_allocation_table                   
		 WHERE rm_part  = @rm_part
		   AND location = @location
		
		SELECT @qty_pre_allocated_total   = ISNULL( @qty_pre_allocated_total ,0)

		------------------------------------------------------------------------------------------------------------------
		--		Calculate total available qty for the part 							--
		------------------------------------------------------------------------------------------------------------------
		SELECT @qty_avail_for_part_total = 0
		SELECT @qty_avail_for_part_total = @qty_in_stock - @qty_alloc_for_part_total - @qty_pre_allocated_total  
				
		-- Get pre-allocated qty for the part on the current order
		SELECT @qty_pre_alloc_for_part_on_wo = 0
		SELECT @qty_pre_alloc_for_part_on_wo = SUM(pre_allocated_qty)
		  FROM #wo_pre_allocation_table 
		 WHERE prod_no  = @prod_no
		   AND prod_ext = @prod_ext
		   AND location = @location
		   AND rm_part  = @rm_part
		 GROUP BY location

		SELECT @qty_pre_alloc_for_part_on_wo = ISNULL(@qty_pre_alloc_for_part_on_wo, 0)
		------------------------------------------------------------------------------------------------------------------
		--		Calculate available qty for the part / line_no on the order					--
		------------------------------------------------------------------------------------------------------------------
		SELECT @qty_avail_for_part_line_no = 0

		IF @qty_avail_for_part_total < @qty_needed_for_part_line_no
			SELECT @qty_avail_for_part_line_no = @qty_avail_for_part_total
		ELSE
			SELECT @qty_avail_for_part_line_no = @qty_needed_for_part_line_no

		IF (ISNULL(@qty_avail_for_part_line_no, 0) <= 0)
		BEGIN
			------------------------------------
			-- For Non Quantity Bearing parts --
			------------------------------------
			
			IF (SELECT status FROM inv_master (NOLOCK) WHERE part_no = @rm_part) = 'V'
				SELECT @qty_avail_for_part_line_no = @qty_needed_for_part_line_no
		END

		------------------------------------------------------------------------------------------------------------------
		--		Calculate current allocated % for the rm_part / line_no on the order				--
		------------------------------------------------------------------------------------------------------------------
		SELECT @alloc_pct_for_part_line_no = 0

		IF @qty_plan_for_part_line_no > 0
			SELECT @alloc_pct_for_part_line_no = 100 * (@qty_used_for_part_line_no + @qty_alloc_for_part_line_no + @qty_picked_for_part_line_no)
							     / @qty_plan_for_part_line_no 

		------------------------------------------------------------------------------------------------------------------
		--		Calculate currently available % for the rm_part/line_no on the order				--
		------------------------------------------------------------------------------------------------------------------
		SELECT @avail_pct_for_part_line_no = 0

		IF @qty_avail_for_part_line_no > 0 
		BEGIN
			SELECT @avail_pct_for_part_line_no = 100
			
			IF @qty_needed_for_part_line_no > 0
				SELECT @avail_pct_for_part_line_no = 100 * @qty_avail_for_part_line_no / @qty_needed_for_part_line_no 
		END
		ELSE
			SELECT @avail_pct_for_part_line_no = @alloc_pct_for_part_line_no

		------------------------------------------------------------------------------------------------------------------
		--		Make final update to the #wo_allocation_detail_view table					--
		------------------------------------------------------------------------------------------------------------------
		UPDATE #wo_allocation_detail_view
		   SET qty_avail  = CASE WHEN @qty_avail_for_part_line_no < 0
					 THEN 0
					 ELSE @qty_avail_for_part_line_no
				    END,
		       qty_picked = @qty_picked_for_part_line_no,
		       qty_alloc  = @qty_alloc_for_part_line_no,
		       avail_pct  = CASE WHEN @avail_pct_for_part_line_no > 100
					 THEN 100
                                         ELSE @avail_pct_for_part_line_no
				    END ,
		       alloc_pct  = CASE WHEN @alloc_pct_for_part_line_no > 100
					 THEN 100
					 ELSE @alloc_pct_for_part_line_no
				    END
		 WHERE prod_no    = @prod_no 
		   AND prod_ext   = @prod_ext
		   AND location   = @location
		   AND rm_part    = @rm_part
		   AND line_no	  = @line_no

-------------------------------------------------------------------------------------------------------------------------------

		INSERT INTO #wo_pre_allocation_table (prod_no, prod_ext, location, rm_part, line_no, pre_allocated_qty)
		VALUES(@prod_no, @prod_ext, @location, @rm_part, @line_no, ISNULL(@qty_avail_for_part_line_no,0))

		FETCH NEXT FROM detail_cursor INTO @rm_part, @line_no, @qty_plan_for_part_line_no, @qty_used_for_part_line_no, @lb_tracking
	END
	
	CLOSE      detail_cursor 
	DEALLOCATE detail_cursor 

-------------------------------------------------------------------------------------------------------------------------------
	SET @temp_all_qty   = 0
	SET @temp_alloc_qty = 0
	SET @temp_plan_qty  = 0

	SELECT @temp_all_qty   = AVG(qty_avail + qty_picked + qty_used + qty_alloc),
	       @temp_alloc_qty = AVG(qty_alloc + qty_picked + qty_used),
	       @temp_plan_qty  = AVG(qty_plan)
          FROM #wo_allocation_detail_view
	 WHERE prod_no  = @prod_no
           AND prod_ext = @prod_ext
	   AND location = @location

	------------------------------------------------------------------------------------------------------------------
	--		Calculate current fill percentage for the order							--
	------------------------------------------------------------------------------------------------------------------
	SELECT @cur_fill_pct_for_wo = 0


	IF @temp_plan_qty > 0 SELECT @cur_fill_pct_for_wo = 100 * @temp_all_qty / @temp_plan_qty
	ELSE		      SELECT @cur_fill_pct_for_wo = 100


	------------------------------------------------------------------------------------------------------------------
	--		Calculate current allocated percentage for the order						--
	------------------------------------------------------------------------------------------------------------------
	SELECT @alloc_pct_for_wo = 0

	IF @temp_plan_qty > 0 SELECT @alloc_pct_for_wo = 100 * @temp_alloc_qty / @temp_plan_qty
	ELSE		      SELECT @alloc_pct_for_wo = 100

	IF @cur_fill_pct_for_wo IS NULL SET @cur_fill_pct_for_wo = 0
	IF @alloc_pct_for_wo    IS NULL SET @alloc_pct_for_wo = 0

	UPDATE #wo_alloc_management
	   SET curr_fill_pct  = CASE WHEN @cur_fill_pct_for_wo > 100
         			     THEN 100
				     ELSE @cur_fill_pct_for_wo 
				END,
	       curr_alloc_pct = CASE WHEN @alloc_pct_for_wo > 100
         			     THEN 100
				     ELSE @alloc_pct_for_wo 
				END
         WHERE prod_no    = @prod_no 
	   AND prod_ext   = @prod_ext 
	   AND location   = @location 

-------------------------------------------------------------------------------------------------------------------------------

	FETCH NEXT FROM selected_detail_cursor INTO @prod_no, @prod_ext, @location
END

CLOSE	   selected_detail_cursor
DEALLOCATE selected_detail_cursor

-------------------------------------------------------------------------------------------------------------------------------

-- Remove all records from #wo_alloc_management with fill percentages below what was passed-in by the VB app 
DELETE FROM #wo_alloc_management WHERE curr_fill_pct <  @pct_filter


IF EXISTS (SELECT * FROM tdc_part_filter_tbl (NOLOCK)    -- If the user used a Finish Goods filter
	    WHERE alloc_filter = 'N'
	      AND order_type   = 'W'
	      AND part_type    = 'F'
	      AND userid       = @user_id)
BEGIN							-- and the @prod_no hasn't any Fg parts that are in the tdc_part_filter_tbl,
	DELETE FROM #wo_alloc_management	-- delete this WO from the #wo_allocation_detail_view table 
	 WHERE CAST (prod_no AS varchar(10)) + '-' + CAST (prod_ext AS varchar(10)) NOT IN 
		(
			 SELECT CAST (prod_no AS varchar(10)) + '-' + CAST (prod_ext AS varchar(10))
		  	  FROM #wo_alloc_management
			 GROUP BY prod_no, prod_ext, fg_part, location
			HAVING (fg_part + '+' + location)  IN (SELECT (part_no + '+' + location) 
								    FROM tdc_part_filter_tbl (NOLOCK)
							           WHERE alloc_filter = 'N'
							             AND order_type   = 'W'
							             AND part_type    = 'F'
							             AND userid       = @user_id)
		)

	DELETE FROM #wo_alloc_management
	WHERE CAST (prod_no AS varchar(10)) + '-' + CAST (prod_ext AS varchar(10)) NOT IN 
		(
			SELECT CAST (prod_no AS varchar(10)) + '-' + CAST (prod_ext AS varchar(10))
		  	  FROM #wo_allocation_detail_view
		)
END

IF EXISTS (SELECT * FROM tdc_part_filter_tbl (NOLOCK)    -- If the user used a Raw Materials filter
	    WHERE alloc_filter = 'N'
	      AND order_type   = 'W'
	      AND part_type    = 'R'
	      AND userid       = @user_id)
BEGIN							-- and the @prod_no hasn't any RM parts that are in the tdc_part_filter_tbl,
	DELETE FROM #wo_allocation_detail_view	-- delete this WO from the #wo_allocation_detail_view table 
	 WHERE CAST (prod_no AS varchar(10)) + '-' + CAST (prod_ext AS varchar(10)) NOT IN 
		(
			 SELECT CAST (prod_no AS varchar(10)) + '-' + CAST (prod_ext AS varchar(10))
		  	  FROM #wo_allocation_detail_view
			 GROUP BY prod_no, prod_ext, rm_part, location
			HAVING (rm_part + '+' + location)  IN (SELECT (part_no + '+' + location) 
								    FROM tdc_part_filter_tbl (NOLOCK)
							           WHERE alloc_filter = 'N'
							             AND order_type   = 'W'
							             AND part_type    = 'R'
							             AND userid       = @user_id)
		)

	DELETE FROM #wo_alloc_management
	WHERE CAST (prod_no AS varchar(10)) + '-' + CAST (prod_ext AS varchar(10)) NOT IN 
		(
			SELECT CAST (prod_no AS varchar(10)) + '-' + CAST (prod_ext AS varchar(10))
		  	  FROM #wo_allocation_detail_view
		)
END

TRUNCATE TABLE #wo_pre_allocation_table

RETURN
GO
GRANT EXECUTE ON  [dbo].[tdc_plw_wo_alloc_management_sp] TO [public]
GO
