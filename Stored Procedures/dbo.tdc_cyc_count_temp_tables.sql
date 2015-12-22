SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- v1.0 CB 12/10/2011 - Issue with standard product - null values

CREATE PROCEDURE [dbo].[tdc_cyc_count_temp_tables]
			@user_id varchar(50)
AS

DECLARE @insert_clause         	varchar(500),
	@main_select_clause	varchar(50),
	@select_clause        	varchar(500),
	@where_clause        	varchar(8000),
	@order_by_clause	varchar(500),
	@SQL		        varchar(8000)

DECLARE @team_id		varchar(50),
	@counted_user		varchar(50),
	@location    		varchar(10),
        @lot_ser     		varchar(25), 
	@order_by_1		varchar(35),
	@order_by_2		varchar(35),
	@order_by_3		varchar(35),
	@order_by_4		varchar(35),
	@part_tracking_type	varchar(25),
	@no_display_rec		int,
	@update_method		int,
	@no_qty_matches		int

DECLARE	@part_no     		varchar(30),
	@bin_no      		varchar(12),
	@post_qty    		decimal(20, 8),
	@post_ver   		int,
	@lb_tracking 		char(1),
	@erp_current_qty	decimal(20, 8),
	@erp_qty_at_count	decimal(20, 8),
	@inv_cost_method	varchar(1),
	@amount			decimal(20,2),
	@difference             decimal(20,0),
	@curr_key		varchar(4),
	@record_found		int,
	@qty_mismatch		int,
	@count_qty		decimal(20,8)

UPDATE tdc_phy_cyc_count
   SET post_qty = 0,
       post_ver = 0
 WHERE adm_actual_qty <> count_qty 
   AND userid         IS NOT NULL 
   AND post_ver       IS NULL

----------------------------------------------------------------------------------------
-- Build the insert into the master temp table clause based on the user filter settings
----------------------------------------------------------------------------------------
SELECT @team_id            = team_id,                       
       @counted_user       = user_id_filter,
       @location           = location,
       @lot_ser            = lot_ser,
       @no_display_rec     = no_display_rec, 
       @update_method      = update_method,
       @no_qty_matches 	   = no_qty_matches,
       @part_tracking_type = part_tracking_type,
       @order_by_1         = order_by_1,
       @order_by_2         = order_by_2,
       @order_by_3         = order_by_3,
       @order_by_4         = order_by_4
  FROM tdc_cyc_count_user_filter_set (NOLOCK)
 WHERE userid = @user_id

SET @insert_clause = 'INSERT INTO #tdc_cyc_master (location, part_no, lb_tracking, lot_ser, bin_no) '

IF @no_display_rec > 0 
BEGIN
	SET @main_select_clause = 'SELECT TOP ' + CAST(@no_display_rec AS varchar(20)) + ' * FROM ( '
END
ELSE
BEGIN
	SET @main_select_clause = 'SELECT  * FROM ( '
END

SET @select_clause = ' SELECT DISTINCT a.location, a.part_no, b.lb_tracking, a.lot_ser, a.bin_no
		         FROM tdc_phy_cyc_count a (NOLOCK),
			      inv_master        b (NOLOCK) '


SET @where_clause = ' WHERE a.part_no = b.part_no '

SET @order_by_clause  = ') main_select ORDER BY ' + @order_by_1 + ', ' + @order_by_2 + ', ' + @order_by_3 + ', ' + @order_by_4 

IF @team_id NOT IN ('<ALL>', '')
BEGIN
	SET @where_clause = @where_clause + ' AND team_id  = ' + CHAR(39) + @team_id + CHAR(39)
END

IF @counted_user NOT IN ('<ALL>', '')
BEGIN
	SET @where_clause = @where_clause + ' AND userid   = ' + CHAR(39) + @counted_user + CHAR(39)
END

IF @location NOT IN ('<ALL>', '')
BEGIN
	SET @where_clause = @where_clause + ' AND location = ' + CHAR(39) + @location + CHAR(39)
END

IF EXISTS(SELECT * FROM tdc_cyc_count_part_filter (NOLOCK) WHERE userid = @user_id)
BEGIN
	SET @where_clause = @where_clause + ' AND a.location + ' + CHAR(39) + '<->' + CHAR(39) + '+ a.part_no IN (
					     SELECT location + ' + CHAR(39) + '<->' + CHAR(39) + '+   part_no 
	                                       FROM tdc_cyc_count_part_filter (NOLOCK) 
	                                      WHERE userid = ' + CHAR(39) + @user_id + CHAR(39) + ')'
END


IF @part_tracking_type = 'Not Lot/Bin Tracked Parts'
BEGIN
	SET @where_clause = @where_clause + ' AND b.lb_tracking = ''N'' '

	-------------------------------------------
	-- Final statement
	-------------------------------------------
	SET @SQL = @insert_clause + @main_select_clause + @select_clause + @where_clause + @order_by_clause
END

IF @part_tracking_type = 'Lot/Bin Tracked Parts'
BEGIN
	SET @where_clause = @where_clause + ' AND b.lb_tracking = ''Y'' '

	IF @lot_ser NOT IN ('<ALL>', '')
	BEGIN
		SET @where_clause = @where_clause + ' AND lot_ser = ' + CHAR(39) + @lot_ser + CHAR(39)
	END

	IF EXISTS(SELECT * FROM tdc_cyc_count_bin_filter (NOLOCK) WHERE userid = @user_id)
	BEGIN
		SET @where_clause = @where_clause + ' AND a.location + ' + CHAR(39) + '<->' + CHAR(39) + '+ a.bin_no IN (
						     SELECT location + ' + CHAR(39) + '<->' + CHAR(39) + '+   bin_no 
		                                       FROM tdc_cyc_count_bin_filter (NOLOCK) 
		                                      WHERE userid = ' + CHAR(39) + @user_id + CHAR(39) + ')'
	END

	-------------------------------------------
	-- Final statement
	-------------------------------------------
	SET @SQL = @insert_clause + @main_select_clause + @select_clause + @where_clause + @order_by_clause
END

IF @part_tracking_type IN ('<ALL>', '')	-- Both
BEGIN
	-------------------------------------------
	-- Final statement
	-------------------------------------------
	SET @SQL = @insert_clause + @main_select_clause 
	
	-- Not L/B tracked parts
	SET @SQL = @SQL + @select_clause + @where_clause + ' AND b.lb_tracking = ''N'' '
	SET @SQL = @SQL + ' UNION '

	-- L/B tracked parts
	SET @where_clause = @where_clause + ' AND b.lb_tracking = ''Y'' '

	IF @lot_ser NOT IN ('<ALL>', '')
	BEGIN
		SET @where_clause = @where_clause + ' AND lot_ser = ' + CHAR(39) + @lot_ser + CHAR(39)
	END

	IF EXISTS(SELECT * FROM tdc_cyc_count_bin_filter (NOLOCK) WHERE userid = @user_id)
	BEGIN
		SET @where_clause = @where_clause + ' AND a.location + ' + CHAR(39) + '<->' + CHAR(39) + '+ a.bin_no IN (
						     SELECT location + ' + CHAR(39) + '<->' + CHAR(39) + '+   bin_no 
		                                       FROM tdc_cyc_count_bin_filter (NOLOCK) 
		                                      WHERE userid = ' + CHAR(39) + @user_id + CHAR(39) + ')'
	END

	SET @SQL = @SQL + @select_clause + @where_clause + @order_by_clause
END

---------------------------------------------
-- Fill the temp table for Master view
---------------------------------------------
EXEC (@SQL)

--======================================================================================================================

---------------------------------------------
-- Fill the temp table for Detail view
---------------------------------------------
TRUNCATE TABLE #tmp_phy_cyc_count

INSERT INTO #tmp_phy_cyc_count (team_id, userid, cyc_code, location, part_no, lot_ser, bin_no, adm_actual_qty,  count_date, count_qty, post_qty, post_ver) 
     SELECT DISTINCT a.team_id, a.userid, cyc_code, a.location, a.part_no, a.lot_ser, a.bin_no, adm_actual_qty, count_date, count_qty, a.post_qty, a.post_ver        
       FROM tdc_phy_cyc_count a (NOLOCK),                              
            #tdc_cyc_master   b
      WHERE a.location = b.location
        AND a.part_no  = b.part_no
        AND ISNULL(a.lot_ser, '') = ISNULL(b.lot_ser, '')
        AND ISNULL(a.bin_no,  '') = ISNULL(b.bin_no,  '')

---------------------------------------------
-- UPDATE #tdc_cyc_master
---------------------------------------------
DECLARE cyc_count_cursor CURSOR FOR 
	SELECT location, part_no, lb_tracking, lot_ser, bin_no FROM #tdc_cyc_master 

OPEN cyc_count_cursor	
FETCH NEXT FROM cyc_count_cursor INTO @location, @part_no, @lb_tracking, @lot_ser, @bin_no

WHILE (@@FETCH_STATUS = 0)
BEGIN
	SET @erp_qty_at_count = NULL
	SET @post_qty         = NULL
	SET @post_ver         = 0

	---------------------------------------------------------------
	-- Get the system qty
	---------------------------------------------------------------
	IF EXISTS(SELECT *
		    FROM #tmp_phy_cyc_count (NOLOCK)
	           WHERE location = @location
		     AND part_no  = @part_no
                     AND ISNULL(bin_no,  '') = ISNULL(@bin_no,  '')
                     AND ISNULL(lot_ser, '') = ISNULL(@lot_ser, '')
		     AND adm_actual_qty IS NOT NULL)
	BEGIN
--		SELECT @erp_qty_at_count = (SELECT adm_actual_qty
--					      FROM #tmp_phy_cyc_count (NOLOCK)
--	       				     WHERE location = @location
--					       AND part_no  = @part_no
--		                               AND ISNULL(bin_no,  '') = ISNULL(@bin_no,  '')
--		                               AND ISNULL(lot_ser, '') = ISNULL(@lot_ser, '')
--					       AND count_date = (SELECT MAX(count_date)
--						  	           FROM #tmp_phy_cyc_count (NOLOCK)
--			       					  WHERE location = @location
--							            AND part_no  = @part_no
--				                                    AND ISNULL(bin_no,  '') = ISNULL(@bin_no,  '')
--				                                    AND ISNULL(lot_ser, '') = ISNULL(@lot_ser, '')
--							        )) 

		SELECT @erp_qty_at_count = ISNULL((SELECT adm_actual_qty
					      FROM #tmp_phy_cyc_count (NOLOCK)
	       				     WHERE location = @location
					       AND part_no  = @part_no
		                               AND ISNULL(bin_no,  '') = ISNULL(@bin_no,  '')
		                               AND ISNULL(lot_ser, '') = ISNULL(@lot_ser, '')
					       AND count_date = ISNULL((SELECT MAX(count_date)
						  	           FROM #tmp_phy_cyc_count (NOLOCK)
			       					  WHERE location = @location
							            AND part_no  = @part_no
				                                    AND ISNULL(bin_no,  '') = ISNULL(@bin_no,  '')
				                                    AND ISNULL(lot_ser, '') = ISNULL(@lot_ser, '') -- v1.0
							        ),GETDATE())),0) -- v1.0

	END

	SELECT @post_ver = AVG(post_ver),
	       @post_qty = AVG(post_qty)
	  FROM #tmp_phy_cyc_count
         WHERE location = @location
	   AND part_no  = @part_no
           AND ISNULL(lot_ser, '') = ISNULL(@lot_ser, '')
	   AND ISNULL(bin_no,  '') = ISNULL(@bin_no,  '')
	   AND count_qty IS NOT NULL
	   
	     IF @post_ver IS NULL SET @post_ver = 0

	----------------------------------------------------------------------------------
	-- If qty hasn't been posted,
	-- automaticaly mark records for update based on the selected update method
	----------------------------------------------------------------------------------
	IF @post_ver <> 1 AND @erp_qty_at_count IS NOT NULL
	BEGIN
		-----------------------------------------------------------------------------------
		-- All count qty match the system qty
		-----------------------------------------------------------------------------------
		IF @update_method = 0	
		BEGIN
			-- If there are no counted records with the counted qty mismatch the system qty,
			-- mark the part for update with the post qty = system qty
			IF NOT EXISTS (SELECT *
				         FROM #tmp_phy_cyc_count
				        WHERE location = @location
				          AND part_no  = @part_no
		                          AND ISNULL(lot_ser, '') = ISNULL(@lot_ser, '')
				          AND ISNULL(bin_no,  '') = ISNULL(@bin_no,  '')
				          AND count_qty IS NOT NULL
				          AND count_qty <> @erp_qty_at_count)
			BEGIN
				SET @post_ver = 1
				SET @post_qty = @erp_qty_at_count
			END
			ELSE
			BEGIN
				SET @post_ver = 0
				SET @post_qty = NULL
			END
		END
	
		-----------------------------------------------------------------------------------
		-- All count quantities match regardless of the system qty
		-----------------------------------------------------------------------------------
		IF @update_method = 1	 
		BEGIN
			IF (SELECT COUNT (DISTINCT count_qty)
			      FROM #tmp_phy_cyc_count
			     WHERE location = @location
			       AND part_no  = @part_no
	                       AND ISNULL(lot_ser, '') = ISNULL(@lot_ser, '')
			       AND ISNULL(bin_no,  '') = ISNULL(@bin_no,  '')
			       AND count_qty IS NOT NULL) = 1
			BEGIN
				SET @post_ver = 1
--				SELECT @post_qty = (SELECT DISTINCT count_qty
--						      FROM #tmp_phy_cyc_count
--					             WHERE location = @location
--						       AND part_no  = @part_no
--				                       AND ISNULL(lot_ser, '') = ISNULL(@lot_ser, '')
--	 					       AND ISNULL(bin_no,  '') = ISNULL(@bin_no,  '')
--						       AND count_qty IS NOT NULL) 
				SELECT @post_qty = ISNULL((SELECT DISTINCT count_qty
						      FROM #tmp_phy_cyc_count
					             WHERE location = @location
						       AND part_no  = @part_no
				                       AND ISNULL(lot_ser, '') = ISNULL(@lot_ser, '')
	 					       AND ISNULL(bin_no,  '') = ISNULL(@bin_no,  '')
						       AND count_qty IS NOT NULL),0) -- v1.0


			END
			ELSE
			BEGIN
				SET @post_ver = 0
				SET @post_qty = NULL
			END
		END
	
		-----------------------------------------------------------------------------------
		-- Min X count quantities match the system qty
		-----------------------------------------------------------------------------------
		IF @update_method = 2	
		BEGIN
			IF (SELECT COUNT(*)
			      FROM #tmp_phy_cyc_count
		             WHERE location = @location
			       AND part_no  = @part_no
	                       AND ISNULL(lot_ser, '') = ISNULL(@lot_ser, '')
			       AND ISNULL(bin_no,  '') = ISNULL(@bin_no,  '')
			       AND count_qty = @erp_qty_at_count
			   ) >= @no_qty_matches
			BEGIN
				SET @post_ver = 1
				SET @post_qty = @erp_qty_at_count
			END
			ELSE
			BEGIN
				SET @post_ver = 0
				SET @post_qty = NULL
			END
		END
	END

	-- Get erp_current_qty
	SELECT @erp_current_qty = 0
	
	IF @lb_tracking = 'Y'
	BEGIN
		SELECT @erp_current_qty = qty 
	          FROM lot_bin_stock (NOLOCK)         
	         WHERE location = @location
	           AND part_no  = @part_no            
	           AND lot_ser  = @lot_ser
	           AND bin_no   = @bin_no
	END
	ELSE
	BEGIN
		SELECT @erp_current_qty = in_stock 
	          FROM inventory (NOLOCK)         
	         WHERE location = @location
	           AND part_no  = @part_no            
	END

	SELECT @inv_cost_method = inv_cost_method  FROM inv_master (NOLOCK) WHERE part_no = @part_no

	IF @inv_cost_method <> 'S'
		SELECT @amount = avg_cost FROM inventory (NOLOCK) WHERE part_no = @part_no AND location = @location
	ELSE
		SELECT @amount = std_cost FROM inventory (NOLOCK) WHERE part_no = @part_no AND location = @location

	SELECT @difference = (ISNULL(@erp_current_qty, 0) -ISNULL(@post_qty, 0))
	
	SELECT @amount = @difference * @amount
	
	SELECT @curr_key = curr_key
	  FROM part_price (NOLOCK)
	 WHERE part_no = @part_no

	UPDATE #tdc_cyc_master
 	   SET lb_tracking      = @lb_tracking,
	       post_ver         = -@post_ver,
	       post_qty         = @post_qty,
	       erp_current_qty  = @erp_current_qty,
	       erp_qty_at_count = @erp_qty_at_count,
	       curr_key         = @curr_key,
	       [difference]     = @difference,
	       cost = CASE 
			WHEN @difference < 0 THEN CAST(-@amount AS VARCHAR(20)) + ' ' + @curr_key
			WHEN @difference = 0 THEN '0.00 ' + @curr_key 
			ELSE '(' + cast(@amount AS VARCHAR(20)) + ')' + ' ' + @curr_key
		      END,
	       changed_flag = CASE
				WHEN @post_ver <> 0 THEN 1
				ELSE			 0
		              END
         WHERE location = @location
           AND part_no  = @part_no            
           AND ISNULL(lot_ser, '') = ISNULL(@lot_ser, '')
           AND ISNULL(bin_no , '') = ISNULL(@bin_no,  '')     


	FETCH NEXT FROM cyc_count_cursor INTO  @location, @part_no, @lb_tracking,  @lot_ser, @bin_no
END	

CLOSE	   cyc_count_cursor
DEALLOCATE cyc_count_cursor
   
RETURN
GO
GRANT EXECUTE ON  [dbo].[tdc_cyc_count_temp_tables] TO [public]
GO
