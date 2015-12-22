SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
													

CREATE PROCEDURE [dbo].[tdc_update_target_bin_sp] 
	@con_no 		INT, 
	@passed_in_order_no 	INT, 
	@passed_in_order_ext 	INT,
	@passed_in_location 	VARCHAR(10),
	@passed_in_part_no 	VARCHAR(30)
AS

DECLARE 
	@target_bin 		VARCHAR(50),
	@pass_bin 		VARCHAR(12),
	@avail_qty		DECIMAL(24,8),
	@alloc_qty		DECIMAL(24,8),
	@repl_bin		VARCHAR(15),
	@repl_max_qty		DECIMAL(24,8),
	@repl_qty_in_stock	DECIMAL(24,8),
	@qty_in_stock		DECIMAL(24,8),
	@seq_no 		INT,
	@order_no 		INT,
	@order_ext 		INT,
	@location 		VARCHAR(30),
	@part_no 		VARCHAR(30),
	@line_no 		INT,
	@lot_ser 		VARCHAR(25),
	@bin_no 		VARCHAR(12),
	@qty 			DECIMAL(20,8),
	@filled_flg 		CHAR(1),
	@lb_loc 		VARCHAR(10),
	@lb_bin 		VARCHAR(12),
	@lbmax_qty 		DECIMAL(20,8),
	@lb_qty 		DECIMAL(20,8),
	@prev_alloc_qty 	DECIMAL(20,8),
	@err_msg 		VARCHAR(255),
	@AllocType		VARCHAR(2),
	@q_priority		int
 
TRUNCATE TABLE #upd_target_bin_working_tbl

SELECT @q_priority = 5
SELECT @q_priority = CAST(value_str AS INT) FROM tdc_config(NOLOCK) where [function] = 'Pick_Q_Priority'
IF @q_priority IN ('', 0)
	SELECT @q_priority = 5
UPDATE tdc_main
   SET pre_pack = 'Y'
 WHERE consolidation_no IN( SELECT DISTINCT a.consolidation_no
			      FROM tdc_main a,
			           tdc_cons_ords b,
			           tdc_soft_alloc_tbl c
			     WHERE a.consolidation_no = b.consolidation_no
			       AND b.order_no = c.order_no
			       AND b.order_ext = c.order_ext
			       AND b.location = c.location
			       AND c.alloc_type = 'PR')
-----------------------------------------------------------------------------------------------------------------------
--  Populate a working temp TABLE to determine which records need to be updated
-----------------------------------------------------------------------------------------------------------------------

INSERT INTO #upd_target_bin_working_tbl (sequence_no, order_no, order_ext,location,part_no)  
SELECT DISTINCT b.seq_no, a.order_no, a.order_ext, a.location, a.part_no
  FROM tdc_soft_alloc_tbl   a (NOLOCK), 
       tdc_cons_ords        b (NOLOCK),
       #so_alloc_management c
 WHERE a.order_no 	    = b.order_no 
   AND a.order_ext 	    = b.order_ext
   AND a.location 	    = b.location 
   AND a.order_type 	    = b.order_type
   AND a.order_type 	    = 'S'
   AND b.consolidation_no   = @con_no 	   
   AND (@passed_in_order_no = 0     OR (a.order_no = @passed_in_order_no AND a.order_ext = @passed_in_order_ext))
   AND (@passed_in_location = 'ALL' OR a.location = @passed_in_location)	   
   AND (@passed_in_part_no  = 'ALL'  OR a.part_no = @passed_in_part_no)
   AND c.order_no  	    = a.order_no
   AND c.order_ext 	    = a.order_ext
   AND c.location  	    = a.location
   AND c.sel_flg  	   != 0
   AND a.location IN (SELECT location FROM #so_target_bin_assign)
 
DECLARE locations_cur CURSOR FOR 
	SELECT location, target_bin, pass_bin FROM #so_target_bin_assign

OPEN locations_cur
FETCH NEXT FROM locations_cur INTO @location, @target_bin, @pass_bin

WHILE @@FETCH_STATUS = 0
BEGIN
 
	-----------------------------------------------------------------------------------------------------------------------
	-- INITIAL ALLOCATION
	-----------------------------------------------------------------------------------------------------------------------
	IF @target_bin = 'INITIAL ALLOCATION' 
	OR @target_bin = 'AUTO REPLENISH FIRST' 
	OR @target_bin = 'AUTO OPEN FIRST'
	BEGIN

		UPDATE tdc_soft_alloc_tbl
		   SET target_bin   = bin_no,
		       dest_bin     = @pass_bin
		  FROM tdc_soft_alloc_tbl a, 
		       #so_alloc_management b,
		       #so_allocation_detail_view c
		 WHERE a.order_no   = b.order_no 
		   AND a.order_ext  = b.order_ext 
		   AND a.order_type = 'S'
		   AND a.location   = b.location 
		   AND a.part_no    = c.part_no 
		   AND a.target_bin   IS NULL 
		   AND a.bin_no       IS NOT NULL
		   AND b.order_no   = c.order_no
		   AND b.order_ext  = c.order_ext
		   AND b.location   = c.location
		   AND b.location   = @location
		   AND b.sel_flg   != 0

		CLOSE locations_cur
		DEALLOCATE locations_cur

		RETURN 1
	END

	-----------------------------------------------------------------------------------------------------------------------
	-- AUTO ALLOCATION
	-----------------------------------------------------------------------------------------------------------------------
	ELSE IF @target_bin = 'AUTO ALLOCATION'
	BEGIN

		-----------------------------------------------------------------------------------------------------------------------
		-- Loop through the replenish bins and put picks on the queue for inventory in them
		-----------------------------------------------------------------------------------------------------------------------
		--Open cursor to loop through all inventory in replenish bins
		DECLARE repl_bins_pick_cur CURSOR FOR 
			SELECT DISTINCT a.part_no, a.bin_no, a.replenish_max_lvl,
			       qty_in_stock = ISNULL((SELECT SUM(qty)
					       FROM lot_bin_stock (NOLOCK)
					      WHERE location = a.location 
						AND bin_no   = a.bin_no
						AND part_no  = a.part_no
					      GROUP BY location, bin_no, part_no),0)
			  FROM tdc_bin_replenishment 	  a(NOLOCK),
			       tdc_soft_alloc_tbl 	  b, 
			       #so_alloc_management       c,
			       #so_allocation_detail_view d			       
			 WHERE a.location     	 = b.location
			   AND a.part_no         = b.part_no		 
			   AND b.order_no        = c.order_no	
			   AND b.order_ext       = c.order_ext
		           AND b.location        = c.location
			   AND b.order_type      = 'S'
			   AND b.target_bin	 IS NULL
			   AND c.order_no        = d.order_no
			   AND c.order_ext	 = d.order_ext
			   AND c.location	 = d.location
			   AND c.location        = @location
			   AND c.sel_flg	!= 0
			   AND d.part_no	 = a.part_no
			 ORDER BY a.bin_no, a.part_no, qty_in_stock DESC

		OPEN repl_bins_pick_cur
		FETCH NEXT FROM repl_bins_pick_cur INTO @part_no, @repl_bin, @repl_max_qty, @repl_qty_in_stock

		WHILE @@FETCH_STATUS = 0
		BEGIN		
			-- Initialize available qty to put into the replenish bins
			SELECT @qty_in_stock = @repl_qty_in_stock 
			
			DECLARE parts_cur CURSOR FOR
				SELECT a.order_no, a.order_ext, a.line_no, a.lot_ser, a.bin_no, a.qty
				  FROM tdc_soft_alloc_tbl   a (NOLOCK),
				       #so_alloc_management b
				 WHERE a.order_no   = b.order_no
			           AND a.order_ext  = b.order_ext
				   AND a.location   = @location
				   AND a.part_no    = @part_no
				   AND a.order_type = 'S'
				   AND a.target_bin IS NULL
				   AND b.location   = a.location
			           AND b.sel_flg   != 0

			OPEN parts_cur
			FETCH NEXT FROM parts_cur INTO @order_no, @order_ext, @line_no, @lot_ser, @bin_no, @alloc_qty
				
			WHILE (@@FETCH_STATUS = 0 AND @qty_in_stock > 0)
			BEGIN
				IF @alloc_qty > @qty_in_stock
				BEGIN						
					UPDATE tdc_soft_alloc_tbl
					   SET qty	  = qty - @qty_in_stock,
					       trg_off	  = 1
					 WHERE order_no   = @order_no
					   AND order_ext  = @order_ext
					   AND location   = @location
					   AND order_type = 'S'
					   AND line_no    = @line_no
				  	   AND lot_ser    = @lot_ser
					   AND bin_no     = @bin_no
					   AND target_bin IS NULL
 					
					UPDATE tdc_soft_alloc_tbl
					   SET trg_off	  = NULL
					 WHERE order_no   = @order_no
					   AND order_ext  = @order_ext
					   AND location   = @location
					   AND order_type = 'S'
					   AND line_no    = @line_no	
				  	   AND lot_ser    = @lot_ser
					   AND bin_no     = @bin_no
					   AND target_bin IS NULL

				        SELECT @AllocType = alloc_type
				          FROM tdc_soft_alloc_tbl (NOLOCK)					  
					 WHERE order_no   = @order_no
					   AND order_ext  = @order_ext
					   AND location   = @location
					   AND order_type = 'S'
					   AND line_no    = @line_no
				  	   AND lot_ser    = @lot_ser
					   AND bin_no     = @bin_no
					   AND target_bin IS NULL

					INSERT INTO tdc_soft_alloc_tbl (order_no, order_ext,location, line_no, part_no,
									lot_ser, bin_no, qty, target_bin, dest_bin, order_type, alloc_type, q_priority)
					VALUES (@order_no, @order_ext, @location, @line_no, @part_no, @lot_ser, @repl_bin,
						@qty_in_stock, @repl_bin, @pass_bin, 'S', @AllocType, @q_priority )	
	
					SELECT @qty_in_stock = 0
			
				END
				ELSE
				BEGIN
					UPDATE tdc_soft_alloc_tbl
					   SET target_bin = @repl_bin,
					       dest_bin   = @pass_bin
					 WHERE order_no   = @order_no
					   AND order_ext  = @order_ext
					   AND location   = @location
					   AND order_type = 'S'
					   AND line_no    = @line_no
				  	   AND lot_ser    = @lot_ser
					   AND bin_no     = @repl_bin
					   AND target_bin IS NULL

					SELECT @qty_in_stock = @qty_in_stock - @alloc_qty
				END
				FETCH NEXT FROM parts_cur INTO @order_no, @order_ext, @line_no, @lot_ser, @bin_no, @alloc_qty
			END
			CLOSE parts_cur
			DEALLOCATE parts_cur

			FETCH NEXT FROM repl_bins_pick_cur INTO @part_no, @repl_bin, @repl_max_qty, @repl_qty_in_stock
		END

		CLOSE repl_bins_pick_cur
		DEALLOCATE repl_bins_pick_cur


		-----------------------------------------------------------------------------------------------------------------------
		-- Loop through the replenish bins and put bin to bin moves on the queue for remaining inventory
		-----------------------------------------------------------------------------------------------------------------------
		--Open cursor to loop through all replenish bins
		DECLARE repl_bins_B2B_cur
		 CURSOR FOR 
			SELECT DISTINCT a.part_no, a.bin_no, a.replenish_max_lvl,
			       qty_in_stock = ISNULL((SELECT SUM(qty)
					       FROM lot_bin_stock (NOLOCK)
					      WHERE location = a.location 
						AND bin_no   = a.bin_no
						AND part_no  = a.part_no
					      GROUP BY location, bin_no, part_no),0)
			  FROM tdc_bin_replenishment 	  a (NOLOCK),
			       tdc_soft_alloc_tbl 	  b, 
			       #so_alloc_management       c,
			       #so_allocation_detail_view d			       
			 WHERE a.location     	 = b.location
			   AND a.part_no         = b.part_no		 
			   AND b.order_no        = c.order_no	
			   AND b.order_ext       = c.order_ext
		           AND b.location        = c.location
			   AND b.order_type      = 'S'
			   AND b.target_bin	 IS NULL
			   AND c.order_no        = d.order_no
			   AND c.order_ext	 = d.order_ext
			   AND c.location	 = d.location
			   AND c.location	 = @location
			   AND c.sel_flg	!= 0
			   AND d.part_no	 = a.part_no

			 UNION
		
			 SELECT DISTINCT b.part_no, a.bin_no, a.maximum_level,
				       qty_in_stock = ISNULL((SELECT SUM(qty)
					       FROM lot_bin_stock (NOLOCK)
					      WHERE location = a.location 
						AND bin_no   = a.bin_no
						AND part_no  = d.part_no
					      GROUP BY location, bin_no, part_no),0) 
			  FROM tdc_bin_master   	  a(NOLOCK),
			       tdc_soft_alloc_tbl 	  b, 
			       #so_alloc_management       c,
			       #so_allocation_detail_view d			       
			 WHERE a.location     	 = b.location 
			   AND a.usage_type_code = 'REPLENISH'			   
			   AND b.order_no        = c.order_no	
			   AND b.order_ext       = c.order_ext
		           AND b.location        = c.location
			   AND b.order_type      = 'S'
			   AND b.target_bin	 IS NULL
			   AND b.lot_ser	 IS NOT NULL
			   AND b.bin_no		 IS NOT NULL
			   AND c.order_no        = d.order_no
			   AND c.order_ext	 = d.order_ext
			   AND c.location	 = d.location
			   AND c.location        = @location
			   AND c.sel_flg	!= 0
			   AND d.part_no	 = b.part_no
			   AND ISNULL(a.maximum_level, 0) > 0
			   AND a.bin_no NOT IN(SELECT bin_no 
						 FROM tdc_bin_replenishment e(NOLOCK)
						WHERE a.location = e.location)
			 ORDER BY a.bin_no, a.part_no, qty_in_stock DESC

		OPEN repl_bins_B2B_cur
		FETCH NEXT FROM repl_bins_B2B_cur INTO @part_no, @repl_bin, @repl_max_qty, @repl_qty_in_stock

		WHILE @@FETCH_STATUS = 0
		BEGIN
			
			-- Initialize available qty to put into the replenish bins
			SELECT @avail_qty = @repl_max_qty - @repl_qty_in_stock 
			
			-- If a different part_no is assigned to this replenish bin, set avail_qty = 0
			IF EXISTS(SELECT * 
				    FROM tdc_soft_alloc_tbl a(NOLOCK)
				   WHERE a.location   = @location
				     AND a.part_no   != @part_no
				     AND a.target_bin = @repl_bin
				     AND a.bin_no NOT IN(SELECT b.bin_no 
							   FROM tdc_bin_replenishment b(NOLOCK)
							  WHERE a.location = b.location) )
			BEGIN
				SELECT @avail_qty = 0				
			END
	
			-- remove any qty that is already assigned to that repl bin but not yet moved.
			-- I.E. plwb2b moves
			IF @avail_qty > 0
			BEGIN
			SELECT @avail_qty = @avail_qty - 
				ISNULL((select sum(qty) 
					FROM tdc_soft_alloc_tbl (NOLOCK)
					WHERE location = @location
					AND part_no = @part_no
					AND target_bin = @repl_bin),0)
			END
 
			DECLARE parts_cur CURSOR FOR
				SELECT a.order_no, a.order_ext, a.line_no, a.lot_ser, a.bin_no, a.qty
				  FROM tdc_soft_alloc_tbl   a (NOLOCK),
				       #so_alloc_management b
				 WHERE a.order_no   = b.order_no
			           AND a.order_ext  = b.order_ext
				   AND a.location   = @location
				   AND a.part_no    = @part_no
				   AND a.order_type = 'S'
				   AND a.target_bin IS NULL
				   AND b.location   = a.location
			           AND b.sel_flg   != 0
			OPEN parts_cur
			FETCH NEXT FROM parts_cur INTO @order_no, @order_ext, @line_no, @lot_ser, @bin_no, @alloc_qty
				
			WHILE (@@FETCH_STATUS = 0 AND @avail_qty > 0)
			BEGIN
				IF @alloc_qty > @avail_qty
				BEGIN		
				
					UPDATE tdc_soft_alloc_tbl
					   SET qty	  = qty - @avail_qty,
					       trg_off	  = 1
					 WHERE order_no   = @order_no
					   AND order_ext  = @order_ext
					   AND location   = @location
					   AND order_type = 'S'
					   AND line_no    = @line_no
				  	   AND lot_ser    = @lot_ser
					   AND bin_no     = @bin_no
					   AND target_bin IS NULL
 					
					UPDATE tdc_soft_alloc_tbl
					   SET trg_off	  = NULL
					 WHERE order_no   = @order_no
					   AND order_ext  = @order_ext
					   AND location   = @location
					   AND order_type = 'S'
					   AND line_no    = @line_no	
				  	   AND lot_ser    = @lot_ser
					   AND bin_no     = @bin_no
					   AND target_bin IS NULL

				        SELECT @AllocType = alloc_type
				          FROM tdc_soft_alloc_tbl (NOLOCK)					  
					 WHERE order_no   = @order_no
					   AND order_ext  = @order_ext
					   AND location   = @location
					   AND order_type = 'S'
					   AND line_no    = @line_no
				  	   AND lot_ser    = @lot_ser
					   AND bin_no     = @bin_no
					   AND target_bin IS NULL

					INSERT INTO tdc_soft_alloc_tbl (order_no, order_ext,location, line_no, part_no,
									lot_ser, bin_no, qty, target_bin,dest_bin, order_type, alloc_type, q_priority)
					VALUES (@order_no, @order_ext, @location, @line_no, @part_no, @lot_ser, @bin_no,
						@avail_qty, @repl_bin, @pass_bin, 'S', @AllocType, @q_priority)	
	
					SELECT @avail_qty = 0
			
				END
				ELSE
				BEGIN
					UPDATE tdc_soft_alloc_tbl
					   SET target_bin = @repl_bin,
					       dest_bin   = @pass_bin
					 WHERE order_no   = @order_no
					   AND order_ext  = @order_ext
					   AND location   = @location
					   AND order_type = 'S'
					   AND line_no    = @line_no
				  	   AND lot_ser    = @lot_ser
					   AND bin_no     = @bin_no
					   AND target_bin IS NULL

					SELECT @avail_qty = @avail_qty - @alloc_qty
				END
				FETCH NEXT FROM parts_cur INTO @order_no, @order_ext, @line_no, @lot_ser, @bin_no, @alloc_qty
			END
			CLOSE parts_cur
			DEALLOCATE parts_cur

			FETCH NEXT FROM repl_bins_B2B_cur INTO @part_no, @repl_bin, @repl_max_qty, @repl_qty_in_stock
		END

		CLOSE repl_bins_B2B_cur
		DEALLOCATE repl_bins_B2B_cur

		-- Test for orders that did not get assigned.
		SELECT @order_no = NULL
		SELECT @order_ext = NULL
		SELECT TOP 1 @order_no  = a.order_no, 
			     @order_ext = a.order_ext
	          FROM tdc_soft_alloc_tbl   a (NOLOCK),
	               #so_alloc_management b,
	               #so_allocation_detail_view c
	         WHERE a.order_no   = b.order_no
                   AND a.order_ext  = b.order_ext
	           AND a.location   = b.location
	           AND a.order_type = 'S'
	           AND a.target_bin IS NULL
		   AND a.bin_no     IS NOT NULL
	           AND b.location   = a.location
	           AND b.sel_flg   != 0 
	           AND c.order_no   = b.order_no
	           AND c.order_ext  = b.order_ext
	           AND c.location   = b.location
		   AND c.location   = @location
	           AND c.line_no    = a.line_no

		IF ISNULL(@order_no, 0) <> 0
		BEGIN

			SELECT @err_msg = 'There are no target bins available for order: ' + 
					CAST(@order_no AS varchar(40)) + '-' + 
					CAST(@order_ext AS VARCHAR(10))
			RAISERROR (@err_msg, 16, 1)
		END


	END -- 'AUTO_ALLOCATION'
	ELSE
	-----------------------------------------------------------------------------------------------------------------------
	-- ALL OTHERS
	-----------------------------------------------------------------------------------------------------------------------
	BEGIN -- All others
	
		IF EXISTS (SELECT * 
			     FROM tdc_cons_ords a (NOLOCK), 
				  #upd_target_bin_working_tbl b, 
				  tdc_pick_queue c (NOLOCK)
			    WHERE a.consolidation_no = @con_no 
			      AND a.order_no 	     = b.order_no 
			      AND a.order_ext        = b.order_ext 
			      AND a.order_no 	     = c.trans_type_no 
			      AND a.order_ext        = c.trans_type_ext   
			      AND b.location 	     = c.location 
			      AND b.location	     = @location
			      AND b.part_no 	     = c.part_no 
			      AND a.order_type       = 'S'
			      AND c.tx_lock         != 'R')
		BEGIN
			SELECT @err_msg = 'ERROR:: Attempting to UPDATE existing Queue transactions'
			RAISERROR (@err_msg, 16, 1)
		END		
	
	 
		UPDATE tdc_soft_alloc_tbl
		   SET target_bin   = @target_bin,
		       dest_bin     = @pass_bin  
		  FROM tdc_soft_alloc_tbl a (NOLOCK), 
		       #upd_target_bin_working_tbl b
		 WHERE a.order_no   = b.order_no 
		   AND a.order_ext  = b.order_ext 
		   AND a.order_type = 'S'
		   AND a.location   = b.location 
		   AND a.location   = @location
		   AND a.part_no    = b.part_no 
		   AND a.bin_no       IS NOT NULL  
		   AND a.bin_no    !=  ISNULL(a.target_bin,'')
	
	END  -- All others


	FETCH NEXT FROM locations_cur INTO @location, @target_bin, @pass_bin
END 

CLOSE locations_cur
DEALLOCATE locations_cur

RETURN 1

GO
GRANT EXECUTE ON  [dbo].[tdc_update_target_bin_sp] TO [public]
GO
