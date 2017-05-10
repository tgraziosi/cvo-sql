SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- v1.0 CB Issue #953 - Exclude non allocatable bins  
-- v1.1 CB 03/01/2013 - Issue #834 - Replenishment
-- v1.2 CB 13/12/2013 - Check for non numeric data - Issue caused by Dave Moon customisation
-- v1.3 CB 03/02/2014 - Issue #834 - Replenishment - Additional
-- v1.4 CB 28/02/2014 - Fix issue with wrong qty being passed to label
-- v1.5 CB 03/03/2014 - Std code including pick trans

CREATE PROCEDURE [dbo].[tdc_adhoc_bin_replenish_sp]  
  @in_location   varchar(10),  
  @in_repl_group  varchar(20), -- v1.1 extend from varchar(10)
  @in_repl_bin  varchar(12),  
  @fill_to_max_ind char(1),  
  @commit   int  
  
/* This sp was written to handle bin replenishment based on allocations etc.    
   Each type should yield a mgtb2b type on the pick queue.      */    
--   
AS  
  
DECLARE @location			varchar(10),  
		@bin_no				varchar(12),  
		@part_no			varchar(30),  
		@repl_max			decimal(20,8),  
		@repl_min			decimal(20,8),  
		@repl_qty			decimal(20,8),		
		@pending_mgtb2b_qty	decimal(20,8),  
		@order_by_value		varchar(255),  
		@order_by_clause	varchar(255),  
		@insert_lbclause1	varchar(255),  
		@insert_lbclause2	varchar(255),  
		@lb_loc				varchar(10),  
		@lb_part			varchar(30),  
		@lb_lot				varchar(25),  
		@lb_bin				varchar(12),  
		@lb_qty				decimal(20,8),  
		@current_bin_qty	decimal(20,8),  
		@qty_to_move		decimal(20,8),  
		@Priority			int,  
		@SeqNo				int,  
		@TranId				int,  
		@Bin2BinGroupId		varchar(25),  
		@declare_stmt1		varchar(255),  
		@declare_stmt2		varchar(255),  
		@declare_stmt3		varchar(255),
		@replen_id			int, -- v1.1 
		@from_bin_group		varchar(20) -- v1.1 
  
  
TRUNCATE TABLE #temp_repl_bins  
TRUNCATE TABLE #rep_bin_move_detail  
  
IF NOT EXISTS (SELECT * FROM locations (nolock) WHERE location = @in_location)  
BEGIN  
	RAISERROR ('Invalid Replenishment Location', 16, -1)  
	RETURN   
END  

-- v1.1 Start  
--IF (@in_repl_group != 'ALL')  
--BEGIN  
--	IF NOT EXISTS (SELECT * FROM tdc_bin_group (nolock) WHERE group_code = @in_repl_group)  
--	BEGIN  
--		RAISERROR ('Invalid Replenishment Group', 16, -1)  
--		RETURN   
--	END  
--END  
-- v1.1 End 
 
IF (@fill_to_max_ind != 'Y' AND @fill_to_max_ind != 'N')  
BEGIN  
	RAISERROR 84695 'Error Invalid Fill To Max Type.'  
	RETURN  
END  
  
/* Build select statement for lot-bin-stock query...specifically the order by logic */  
SELECT	@order_by_value = value_str  
FROM	tdc_config (NOLOCK)  
WHERE	[function] = 'dist_cust_pick'  
  
SELECT @order_by_clause =   
	CASE  
		WHEN @order_by_value = '1'	THEN  ' order by date_expires DESC '  
		WHEN @order_by_value = '2'  THEN  ' order by date_expires ASC '  
		WHEN @order_by_value = '3'  THEN  ' order by lot_bin_stock.lot_ser, lot_bin_stock.bin_no '  
		WHEN @order_by_value = '4'  THEN  ' order by lot_bin_stock.lot_ser DESC, lot_bin_stock.bin_no DESC '  
		WHEN @order_by_value = '5'  THEN  ' order by qty '  
		WHEN @order_by_value = '6'  THEN  ' order by qty DESC '  
		ELSE ' order by date_expires ASC '  
	END  
  
/* build the generic lot-bin-stock statement for finding available inventory to replenish from */  
SELECT @insert_lbclause1 = 'INSERT into #temp_lb_stock (location, part_no , lot_ser, bin_no, qty)  SELECT location, part_no, lot_ser, bin_no, qty FROM lot_bin_stock (NOLOCK) '  
  
DECLARE lot_bin_cursor CURSOR FOR  
SELECT  location, part_no, lot_ser, bin_no, qty  
FROM	#temp_lb_stock  
  
/* select the default priority for this management bin2bin */  
SELECT	@priority = value_str FROM tdc_config where [function] = 'Pick_Q_Priority'  
IF @priority IN ('', '0')  
	SELECT @priority = '5'  
  
SELECT @Bin2BinGroupId = group_id FROM tdc_group (NOLOCK) WHERE trans_type = 'MGTB2B'   

-- v1.1 Start
-- As the filtering is now done on the form just get the data from the temp table
INSERT	INTO #temp_repl_bins (replen_id, location, bin_no, part_no, repl_max_lvl, repl_min_lvl, repl_qty, priority) -- v1.3 add priority
SELECT	c.replen_id, a.location, a.bin_no, b.part_no, b.replenish_max_lvl, b.replenish_min_lvl, b.replenish_qty, c.priority -- v1.3 add priority
FROM	tdc_bin_master a (nolock) 
JOIN	tdc_bin_replenishment b (nolock)  
ON		a.location = b.location 
AND		a.bin_no = b.bin_no 
JOIN	#temp_bin_list c
ON		b.bin_no = c.bin_no
AND		b.part_no = c.part_no
WHERE	a.location = @in_location
ORDER BY c.priority DESC -- v1.3 

-- Remove any existing replenishment transactions for the replen groups being processed
-- Decrement the tdc_soft_alloc qty by the amount on the replenishment
IF (@commit > 0)
BEGIN
/*
	-- Remove any existing replenishment moves
	IF (@in_repl_group != 'ALL')
	BEGIN
		DELETE	a
		FROM	tdc_soft_alloc_tbl a
		JOIN	tdc_pick_queue b (NOLOCK)
		ON		a.location = b.location
		AND		a.part_no = b.part_no
		AND		a.lot_ser = b.lot
		AND		a.bin_no = b.bin_no
		AND		a.target_bin = b.next_op
		WHERE	b.eco_no IN (SELECT CAST(replen_id AS varchar(25))
							FROM #temp_repl_bins)
		AND		b.qty_processed = 0

		DELETE	tdc_pick_queue
		WHERE	eco_no IN (SELECT CAST(replen_id AS varchar(25))
							FROM #temp_repl_bins)
		AND		qty_processed = 0
	END
	ELSE
	BEGIN
		DELETE	a
		FROM	tdc_soft_alloc_tbl a
		JOIN	tdc_pick_queue b (NOLOCK)
		ON		a.location = b.location
		AND		a.part_no = b.part_no
		AND		a.lot_ser = b.lot
		AND		a.bin_no = b.bin_no
		AND		a.target_bin = b.next_op
		WHERE	ISNULL(b.eco_no,'') <> ''
		AND		b.qty_processed = 0

		DELETE	tdc_pick_queue
		WHERE	ISNULL(eco_no,'') <> ''
		AND		qty_processed = 0

	END
*/

	CREATE TABLE #trans_to_remove (
		replen_id	int,
		location	varchar(10),
		part_no		varchar(30),
		bin_no		varchar(20),
		lot_ser		varchar(25),
		target_bin	varchar(20),
		qty			decimal(20,8))

	INSERT	#trans_to_remove
	SELECT	c.replen_id, a.location, a.part_no, a.bin_no, a.lot_ser, a.target_bin, SUM(a.qty)
	FROM	tdc_soft_alloc_tbl a (NOLOCK)
	JOIN	tdc_pick_queue b (NOLOCK)
	ON		a.location = b.location
	AND		a.part_no = b.part_no
	AND		a.lot_ser = b.lot
	AND		a.bin_no = b.bin_no
	AND		a.target_bin = b.next_op
	JOIN	#temp_repl_bins c
	ON		b.location = c.location
	AND		b.part_no = c.part_no
	AND		b.next_op = c.bin_no
	AND		b.eco_no = CAST(c.replen_id AS varchar(25))
	WHERE	a.order_no = 0
	AND		a.order_ext = 0
	AND		a.line_no = 0
	AND		a.order_type = 'S'
	GROUP BY c.replen_id, a.location, a.part_no, a.bin_no, a.lot_ser, a.target_bin

	INSERT	#trans_to_remove
	SELECT	b.eco_no, a.location, a.part_no, a.bin_no, a.lot_ser, a.target_bin, SUM(a.qty)
	FROM	tdc_soft_alloc_tbl a (NOLOCK)
	JOIN	tdc_pick_queue b (NOLOCK)
	ON		a.location = b.location
	AND		a.part_no = b.part_no
	AND		a.lot_ser = b.lot
	AND		a.bin_no = b.bin_no
	AND		a.target_bin = b.next_op
	LEFT JOIN #temp_repl_bins c
	ON		b.location = c.location
	AND		b.part_no = c.part_no
	AND		b.next_op = c.bin_no
	WHERE	a.order_no = 0
	AND		a.order_ext = 0
	AND		a.line_no = 0
	AND		a.order_type = 'S'
    AND		ISNUMERIC(b.eco_no) = 1 -- v1.2
	AND		CAST(b.eco_no AS int) IN (SELECT replen_id FROM #temp_repl_bins)
	AND		ISNULL(b.eco_no,0) <> 0
	AND		c.part_no IS NULL
	GROUP BY b.eco_no, a.location, a.part_no, a.bin_no, a.lot_ser, a.target_bin

	UPDATE	a
	SET		qty = a.qty - b.qty
	FROM	tdc_soft_alloc_tbl a
	JOIN	#trans_to_remove b
	ON		a.location = b.location
	AND		a.part_no = b.part_no
	AND		a.bin_no = b.bin_no
	AND		a.lot_ser = b.lot_ser
	AND		a.target_bin = b.target_bin
	WHERE	a.order_no = 0
	AND		a.order_ext = 0
	AND		a.line_no = 0
	AND		a.order_type = 'S'

	DELETE	a
	FROM	tdc_soft_alloc_tbl a
	JOIN	#trans_to_remove b
	ON		a.location = b.location
	AND		a.part_no = b.part_no
	AND		a.bin_no = b.bin_no
	AND		a.lot_ser = b.lot_ser
	AND		a.target_bin = b.target_bin
	WHERE	a.order_no = 0
	AND		a.order_ext = 0
	AND		a.line_no = 0
	AND		a.order_type = 'S'
	AND		a.qty <= 0

	DELETE	a
	FROM	tdc_pick_queue a
	JOIN	#trans_to_remove b
	ON		a.location = b.location
	AND		a.part_no = b.part_no
	AND		a.bin_no = b.bin_no
	AND		a.lot = b.lot_ser
	AND		a.next_op = b.target_bin
	WHERE	a.trans = 'MGTB2B'
	AND		a.trans_type_no = 0
	AND		a.trans_type_ext = 0
	AND		a.line_no = 0
	AND		a.eco_no = CAST(b.replen_id AS varchar(25))

	DROP TABLE #trans_to_remove

END

/*  
IF (@in_repl_group != 'ALL')  
BEGIN  
	DELETE FROM #temp_repl_bins  
	WHERE	NOT EXISTS (SELECT	* FROM tdc_bin_master (nolock)  
						WHERE	tdc_bin_master.location = #temp_repl_bins.location and  
								tdc_bin_master.bin_no = #temp_repl_bins.bin_no and  
								tdc_bin_master.group_code = @in_repl_group)  
END  
  
IF (@in_repl_bin != 'ALL')  
BEGIN  
	DELETE FROM #temp_repl_bins  
	WHERE NOT EXISTS (	SELECT * FROM #temp_bin_list  
						WHERE #temp_bin_list.bin_no = #temp_repl_bins.bin_no   
						AND #temp_bin_list.part_no = #temp_repl_bins.part_no)  
END   
*/
-- v1.1 End
  
-- don't include the quantity that has already been allocated  
IF (@fill_to_max_ind = 'N')  
BEGIN  
	UPDATE	#temp_repl_bins  
	SET		repl_qty = repl_qty - b.qty_to_process  
	FROM	#temp_repl_bins a, tdc_pick_queue b (nolock)  
	WHERE	a.location = b.location AND a.part_no = b.part_no AND (a.bin_no = b.bin_no OR a.bin_no = b.next_op) AND ISNULL(eco_no,'') = ''
	AND		b.trans_type_no = 0 AND b.trans = 'MGTB2B' -- v1.5
END  
  
DECLARE repl_cursor CURSOR FOR  
SELECT  replen_id, location, bin_no, part_no, repl_max_lvl, repl_min_lvl, repl_qty  
FROM	#temp_repl_bins  
ORDER BY priority DESC -- v1.3 order by priority
  
OPEN repl_cursor  
FETCH NEXT FROM repl_cursor INTO  @replen_id, @location, @bin_no, @part_no, @repl_max, @repl_min, @repl_qty  
   
IF @commit > 0 BEGIN TRAN  
  
WHILE (@@FETCH_STATUS = 0)  
BEGIN  
	/* Get existing quantity for this part in the replenishment bin */  
	SELECT @current_bin_qty = ISNULL((	SELECT sum(qty) FROM lot_bin_stock (nolock)  
										WHERE location = @location   
										AND   bin_no = @bin_no  
										AND   part_no = @part_no),0)  
  
	/* We need to take in consideration any existing moves (Mgtb2b) on the queue already */   
	SELECT @pending_mgtb2b_qty = ISNULL((	SELECT sum(qty_to_process) FROM tdc_pick_queue (nolock)  
											WHERE trans_source = 'MGT'  
											AND   trans = 'MGTB2B'  
											AND   location = @location  
											AND   trans_type_no = 0  
											AND   trans_type_ext = 0  
											AND   line_no = 0   
											AND   next_op = @bin_no  
											AND   part_no = @part_no AND eco_no <> CAST(@replen_id AS varchar(25))), 0)  
    
	 /* set the current_bin_qty = our current total + what is pending on the queue */  
	SELECT @current_bin_qty = @current_bin_qty + @pending_mgtb2b_qty  
  
	/* Determine the quantity required to fill the bin.  If fill_to_max is set, then we ignore   
    the replenishment quantity and just fill the bins to the max level.  Otherwise we utilize  
    this quantity as a replenishment qty */  
	IF (@fill_to_max_ind = 'Y')  
	BEGIN  
		SELECT @qty_to_move = @repl_max - @current_bin_qty  
	END  
	ELSE  
	BEGIN  
		IF ((@repl_qty + @current_bin_qty) > @repl_max)  
		BEGIN  
			SELECT @qty_to_move = @repl_max - @current_bin_qty  
		END  
		ELSE  
		BEGIN		 
			SELECT @qty_to_move = @repl_qty  
		END   
	END  
  
	IF (@qty_to_move > 0) /*ONLY NEED TO PROCESS QUANTITIES THAT ARE GREATER THAN 0 */  
	BEGIN  

		/* Refresh temp table */  
		TRUNCATE TABLE #temp_lb_stock  
  
		/* Build the temp table from lot_bin_stock to determine which bins hold inventory */  
		SELECT @insert_lbclause2 = ' WHERE location = ' + CHAR(39) + @location + CHAR(39)  
				+ ' AND part_no = ' + CHAR(39) + @part_no + CHAR(39)  
    
		EXEC (@insert_lbclause1 + @insert_lbclause2 + @order_by_clause)  
  
		/* remove all inventory from the protected bin types */  
		DELETE FROM #temp_lb_stock   
		FROM  #temp_lb_stock , tdc_bin_master (nolock)    
		WHERE #temp_lb_stock.bin_no = tdc_bin_master.bin_no AND   
		#temp_lb_stock.location = tdc_bin_master.location AND  
		(tdc_bin_master.usage_type_code =  'RECEIPT' OR   
		tdc_bin_master.usage_type_code = 'QUARANTINE' OR  
		tdc_bin_master.usage_type_code = 'PRODIN'  OR   
		tdc_bin_master.usage_type_code = 'PRODOUT') --OR  
		--tdc_bin_master.usage_type_code = 'REPLENISH')  
  
		-- v1.1 Start
		SET @from_bin_group = ''
		SELECT	@from_bin_group = from_bin_group
		FROM	replenishment_groups (NOLOCK)
		WHERE	replen_id = @replen_id

		DELETE	a
		FROM	#temp_lb_stock a 
		JOIN	tdc_bin_master b (nolock)    
		ON		a.bin_no = b.bin_no 
		AND		a.location = b.location 
		WHERE	b.group_code <> @from_bin_group 
		-- v1.1 End

		/* remove all inventory that have allocations already being held against the qty in the bin */  
		UPDATE #temp_lb_stock  
		SET qty = qty - ISNULL((SELECT sum(qty) FROM tdc_soft_alloc_tbl (nolock)  
		WHERE tdc_soft_alloc_tbl.order_type = 'S'  
		AND   #temp_lb_stock.location = tdc_soft_alloc_tbl.location  
		AND   #temp_lb_stock.part_no = tdc_soft_alloc_tbl.part_no  
		AND   #temp_lb_stock.bin_no = tdc_soft_alloc_tbl.bin_no), 0)  
   
		UPDATE #temp_lb_stock   
		set qty = qty - ISNULL((SELECT sum(qty) FROM #rep_bin_move_detail (nolock)  
		WHERE #temp_lb_stock.lot_ser = #rep_bin_move_detail.lot_ser  
		AND   #temp_lb_stock.part_no = #rep_bin_move_detail.part_no  
		AND   #temp_lb_stock.bin_no = #rep_bin_move_detail.bin_no), 0)  
  
		DELETE FROM #temp_lb_stock  
		WHERE qty <= 0  
  
		/* loop through all the records in the temp table trying to find available inventory to move  
		to the replenishment bins */  
		OPEN lot_bin_cursor  
		FETCH NEXT FROM lot_bin_cursor   
		INTO @lb_loc, @lb_part, @lb_lot, @lb_bin, @lb_qty  
  
		WHILE (@@FETCH_STATUS = 0)   
		BEGIN  
			/* determine if there is enough qty from this bin to move to the applicable repl bin */  
			IF (@lb_qty >= @qty_to_move)  
			BEGIN  
				IF EXISTS (SELECT * FROM tdc_soft_alloc_tbl (nolock)  
							WHERE  order_no = 0 and  
							order_ext = 0 and   
							order_type = 'S' and  
							location = @lb_loc and  
							line_no = 0 and  
							part_no = @lb_part and  
							lot_ser = @lb_lot and  
							bin_no = @lb_bin and  
							target_bin = @bin_no)  
				BEGIN  
					IF @commit = 0  
					BEGIN
						-- v1.3 Start
						INSERT #rep_bin_move_detail (part_no, lot_ser, bin_no, to_bin, qty, isforced, replen_id)   
						VALUES(@lb_part, @lb_lot, @lb_bin, @bin_no, @qty_to_move, 0, 0) 

						UPDATE	#rep_bin_move_detail
						SET		isforced = CASE WHEN b.isforced = 1 THEN 1 ELSE 0 END,
								replen_id = b.replen_id
						FROM	#rep_bin_move_detail a
						JOIN	#temp_repl_display b
						ON		a.part_no = b.part_no
						AND		a.to_bin = b.bin_no
						WHERE	b.location = @lb_loc
						AND		b.part_no = @lb_part
						AND		a.bin_no = @lb_bin
						-- v1.3 End 
					END
					ELSE  
						UPDATE tdc_soft_alloc_tbl  
						SET qty = qty + @qty_to_move  
						WHERE   order_no = 0 and  
						order_ext = 0 and   
						order_type = 'S' and  
						location = @lb_loc and  
						line_no = 0 and  
						part_no = @lb_part and  
						lot_ser = @lb_lot and  
						bin_no = @lb_bin and   
						target_bin = @bin_no  
				END  
				ELSE  
				BEGIN  
					IF @commit = 0  
					BEGIN
						-- v1.3 Start
						INSERT #rep_bin_move_detail (part_no, lot_ser, bin_no, to_bin, qty, isforced, replen_id)   
						VALUES(@part_no, @lb_lot, @lb_bin, @bin_no, @qty_to_move, 0, 0)  

						UPDATE	#rep_bin_move_detail
						SET		isforced = CASE WHEN b.isforced = 1 THEN 1 ELSE 0 END,
								replen_id = b.replen_id
						FROM	#rep_bin_move_detail a
						JOIN	#temp_repl_display b
						ON		a.part_no = b.part_no
						AND		a.to_bin = b.bin_no
						WHERE	b.location = @lb_loc
						AND		b.part_no = @lb_part
						AND		a.bin_no = @lb_bin

						-- v1.3 End 
					END
					ELSE  
					BEGIN  
						INSERT INTO tdc_soft_alloc_tbl  
						(order_type, order_no, order_ext, location, line_no, part_no,  
						lot_ser, bin_no, qty, target_bin, dest_bin,q_priority)  
						VALUES ('S',0, 0, @location, 0, @part_no,   
						@lb_lot, @lb_bin, @qty_to_move, @bin_no, @bin_no,@Priority)  
  
						EXEC @SeqNo = tdc_queue_get_next_seq_num 'tdc_pick_queue' , @Priority    
  
						IF (@SeqNo = 0 OR @TranId = 0)   
						BEGIN  
							DEALLOCATE lot_bin_cursor         
							DEALLOCATE repl_cursor  
  
							IF @@TRANCOUNT > 0 ROLLBACK TRAN  
							RAISERROR 84695 'Error Invalid Sequence or Trans Id or Priority .'  
							RETURN  
						END  
    
						INSERT INTO tdc_pick_queue (trans_source, trans, priority, seq_no,  
							location, trans_type_no, trans_type_ext, line_no, part_no, eco_no, lot,qty_to_process,   
							qty_processed, qty_short,next_op, bin_no, date_time,assign_group, tx_control, tx_lock)  
						VALUES ('MGT', 'MGTB2B', @Priority ,  @SeqNo  , @location ,  0 ,  0  , 0,   
						@part_no , CAST(@replen_id AS varchar(25)), @lb_lot,  @qty_to_move , 0, 0, @bin_no, @lb_bin  , GETDATE(),@Bin2BinGroupId , 'M'  , 'R' )   
  
						IF @@ERROR <> 0   
						BEGIN  
							DEALLOCATE lot_bin_cursor         
							DEALLOCATE repl_cursor  
  
							IF @@TRANCOUNT > 0 ROLLBACK TRAN  
								RAISERROR 84691 'Error Inserting into Pick_queue table.'  
							RETURN  
						END  
			
						-- Insert data for printing
						INSERT	#cvo_replenishment (replen_group, location, queue_id, part_no, part_desc, from_bin, to_bin, qty)
						SELECT	@replen_id, @location, @@identity, @part_no, description, @lb_bin, @bin_no, @qty_to_move
						FROM	inv_master (NOLOCK)
						WHERE	part_no = @part_no

					END  
				END  
        
				BREAK  
			END  
			ELSE  
			BEGIN
				/* determine if there is any quantity available to move from this bin */  
				IF (@lb_qty > 0)  
				BEGIN  
					IF EXISTS (SELECT * FROM tdc_soft_alloc_tbl (nolock)  
								WHERE  order_no = 0 and  
								order_ext = 0 and   
								order_type = 'S' and  
								location = @lb_loc and  
								line_no = 0 and  
								part_no = @lb_part and  
								lot_ser = @lb_lot and  
								bin_no = @lb_bin and  
								target_bin = @bin_no)  
					BEGIN  
						IF @commit = 0  
						BEGIN
							-- v1.3 Start
							INSERT #rep_bin_move_detail (part_no, lot_ser, bin_no, to_bin, qty, isforced, replen_id)   
							VALUES(@lb_part, @lb_lot, @lb_bin, @bin_no, @lb_qty, 0, 0)  

							UPDATE	#rep_bin_move_detail
							SET		isforced = CASE WHEN b.isforced = 1 THEN 1 ELSE 0 END,
									replen_id = b.replen_id
							FROM	#rep_bin_move_detail a
							JOIN	#temp_repl_display b
							ON		a.part_no = b.part_no
							AND		a.to_bin = b.bin_no
							WHERE	b.location = @lb_loc
							AND		b.part_no = @lb_part
							AND		a.bin_no = @lb_bin
							-- v1.3 End 
						END
						ELSE  
							UPDATE tdc_soft_alloc_tbl  
							SET qty = qty + @lb_qty  
							WHERE  order_no = 0 and  
							order_ext = 0 and   
							order_type = 'S' and  
							location = @lb_loc and  
							line_no = 0 and  
							part_no = @lb_part and  
							lot_ser = @lb_lot and  
							bin_no = @lb_bin and  
							target_bin = @bin_no  
					END  
					ELSE  
					BEGIN  
						IF @commit = 0  
						BEGIN
							-- v1.3 Start
							INSERT #rep_bin_move_detail (part_no, lot_ser, bin_no, to_bin, qty, isforced, replen_id)   
							VALUES(@part_no, @lb_lot, @lb_bin, @bin_no, @lb_qty, 0, 0)  
							
							UPDATE	#rep_bin_move_detail
							SET		isforced = CASE WHEN b.isforced = 1 THEN 1 ELSE 0 END,
									replen_id = b.replen_id
							FROM	#rep_bin_move_detail a
							JOIN	#temp_repl_display b
							ON		a.part_no = b.part_no
							AND		a.to_bin = b.bin_no
							WHERE	b.location = @lb_loc
							AND		b.part_no = @lb_part
							AND		a.bin_no = @lb_bin
							-- v1.3 End 
						END
						ELSE  
						BEGIN  
							/* Allocate the inv to move and put an entry on the queue */  
							INSERT INTO tdc_soft_alloc_tbl  
							(order_type,order_no, order_ext, location, line_no, part_no,  
							lot_ser, bin_no, qty, target_bin, dest_bin,q_priority)  
							VALUES ('S',0, 0, @location, 0, @part_no,   
							@lb_lot, @lb_bin, @lb_qty, @bin_no, @bin_no,@Priority)  
       
							EXEC @SeqNo = tdc_queue_get_next_seq_num 'tdc_pick_queue' , @Priority    
  
							IF (@SeqNo = 0 OR @TranId = 0)   
							BEGIN  
								DEALLOCATE lot_bin_cursor         
								DEALLOCATE repl_cursor  
  
								IF @@TRANCOUNT > 0 ROLLBACK TRAN  
								RAISERROR 84695 'Error Invalid Sequence or Trans Id or Priority .'  
								RETURN  
							END  
    
							INSERT INTO tdc_pick_queue (trans_source, trans, priority, seq_no,  
								location, trans_type_no, trans_type_ext, line_no, part_no, eco_no,lot,qty_to_process,   
								qty_processed, qty_short,next_op, bin_no, date_time,assign_group, tx_control, tx_lock)  
							VALUES ('MGT', 'MGTB2B', @Priority ,  @SeqNo  , @location ,  0 ,  0  , 0,   
								@part_no , CAST(@replen_id AS varchar(25)),@lb_lot,  @lb_qty , 0, 0, @bin_no, @lb_bin  , GETDATE(),@Bin2BinGroupId , 'M'  , 'R' )   
  
							IF @@ERROR <> 0   
							BEGIN  
								DEALLOCATE lot_bin_cursor         
								DEALLOCATE repl_cursor  
  
								IF @@TRANCOUNT > 0 ROLLBACK TRAN  
								RAISERROR 84691 'Error Inserting into Pick_queue table.'  
								RETURN  
							END 

							-- Insert data for printing
							INSERT	#cvo_replenishment (replen_group, location, queue_id, part_no, part_desc, from_bin, to_bin, qty)
							SELECT	@replen_id, @location, @@identity, @part_no, description, @lb_bin, @bin_no, @lb_qty -- v1.4 @qty_to_move
							FROM	inv_master (NOLOCK)
							WHERE	part_no = @part_no 
							END  
					END  
				END

				SELECT @qty_to_move = @qty_to_move - @lb_qty   
			END  
  
			FETCH NEXT FROM lot_bin_cursor    
			INTO @lb_loc, @lb_part, @lb_lot, @lb_bin, @lb_qty  
  
		END /*end while loop*/  
  
		CLOSE lot_bin_cursor  
	END /* if qty > 0 check */  
  
	FETCH NEXT FROM repl_cursor INTO  @replen_id, @location, @bin_no, @part_no, @repl_max, @repl_min, @repl_qty  
      
END /*end outer while loop*/  
  
DEALLOCATE lot_bin_cursor  
DEALLOCATE repl_cursor  

IF @@TRANCOUNT > 0 COMMIT TRAN  

-- tag 050917
INSERT cvo_replenishment_log
SELECT replen_group, location, queue_id, part_no, part_desc, from_bin, to_bin, qty, GETDATE(), @in_repl_group
 FROM #cvo_replenishment ORDER BY row_id

RETURN 0  

GO
GRANT EXECUTE ON  [dbo].[tdc_adhoc_bin_replenish_sp] TO [public]
GO
