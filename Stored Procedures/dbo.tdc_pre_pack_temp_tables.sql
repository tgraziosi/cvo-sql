SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[tdc_pre_pack_temp_tables]
	@con_no		int  --(If con_no = -1, load only consolidation temp table
			     -- Else, load everything EXCEPT consolidation temp table)
AS

DECLARE 
	@order_no	int, 
	@order_ext	int, 
	@location	varchar(30),
	@line_no	int,
	@part_no	varchar(30), 
	@description	varchar(255),
	@qty_ordered	decimal(24,8),
	@qty_picked	decimal(24,8),
	@qty_packed	decimal(24,8),
	@qty_in_cartons decimal(24,8),
	@pre_pack_qty	decimal(24,8),
	@qty_alloc	decimal(24,8),
	@qty_to_pack    decimal(24,8),
	@qty_to_move	decimal(24,8),
	@qty_avail	decimal(24,8),
	@fill_pct	decimal(24,8),
	@status		varchar(50),
	@part_status	char(1),
	@carton_no	int,
	@queue_b2b_qty  decimal(24,8),
	@ship_to_name	varchar(10)

IF @con_no = -1
	TRUNCATE TABLE #pre_pack_plan_cons_sel
ELSE
BEGIN
	TRUNCATE TABLE #pre_pack_plan_part_view
	TRUNCATE TABLE #pre_pack_plan_order_sel
END

---------------------------------------------------------------------------------------------------------
--  Fill the consolidation number temp table
---------------------------------------------------------------------------------------------------------
IF @con_no = -1
BEGIN
	INSERT INTO #pre_pack_plan_cons_sel       
	       (sel_flg, con_no, con_name, no_orders, status,   
	       [description], created_by, date_created, ordered	)
		SELECT DISTINCT 0 sel_flg, a.consolidation_no, a.consolidation_name,
                   no_orders = (SELECT COUNT(*) 
                                          FROM tdc_cons_ords(NOLOCK)
                             WHERE consolidation_no = a.consolidation_no),
                   a.status, a.[description],a.created_by, a.creation_date ,
		 ordered =  ISNULL((SELECT SUM(ordered) 
				      FROM ord_list d(NOLOCK), tdc_cons_ords e (NOLOCK)
				     WHERE d.order_no = e.order_no 
				       AND d.order_ext = e.order_ext
				       AND d.location = e.location
				       AND e.consolidation_no = a.consolidation_no), 0)
              FROM tdc_main            a (NOLOCK),
                   tdc_cons_ords          b (NOLOCK),
                   orders                      c (NOLOCK)           
             WHERE b.consolidation_no = a.consolidation_no
               AND a.pre_pack           = 'Y'
               AND c.order_no            = b.order_no
               AND c.ext                    = b.order_ext
               AND c.status   IN ('N', 'P', 'Q')	
END
ELSE --Con_no <> -1
BEGIN
	---------------------------------------------------------------------------------------------------------
	--  Fill the order selection temp table
	---------------------------------------------------------------------------------------------------------	
	DECLARE order_sel_cur CURSOR FOR 
		SELECT DISTINCT a.consolidation_no, a.order_no, a.order_ext, C.location, c.ship_to_name
		  FROM tdc_cons_ords 	       a (NOLOCK),
		       #pre_pack_plan_cons_sel b,
		       orders		       c (NOLOCK)
		 WHERE a.consolidation_no = b.con_no
		   AND a.consolidation_no = @con_no
		   AND c.order_no  	  = a.order_no
		   AND c.ext	          = a.order_ext
		   AND c.location         = a.location
		   AND a.alloc_type       = 'PR'

	OPEN order_sel_cur
	FETCH NEXT FROM order_sel_cur INTO @con_no, @order_no, @order_ext, @location, @ship_to_name 

	WHILE @@FETCH_STATUS = 0
	BEGIN
		SELECT @qty_ordered = SUM(ordered),	
		       @qty_picked  = SUM(shipped)	      
		  FROM ord_list (NOLOCK)
		 WHERE order_no  = @order_no
		   AND order_ext = @order_ext
		   AND location  = @location
		 GROUP BY order_no, order_ext, location

		SELECT @qty_alloc = SUM(qty)
		  FROM tdc_soft_alloc_tbl (NOLOCK)
		 WHERE order_no  = @order_no
		   AND order_ext = @order_ext
		   AND location  = @location
		 GROUP BY order_no, order_ext, location

		IF (ISNULL(@qty_alloc,0) + ISNULL(@qty_picked,0)) = 0
			SELECT @fill_pct = 0
		ELSE
			SELECT @fill_pct = ((ISNULL(@qty_alloc,0) + ISNULL(@qty_picked,0)) / @qty_ordered) * 100

		INSERT INTO #pre_pack_plan_order_sel      
		       (sel_flg, con_no, order_no, order_ext, location, ship_to_name, fill_pct, ordered)
		VALUES (0, @con_no, @order_no, @order_ext, @location, @ship_to_name, @fill_pct, @qty_ordered)

		FETCH NEXT FROM order_sel_cur INTO @con_no, @order_no, @order_ext, @location, @ship_to_name 
	END
	CLOSE order_sel_cur
	DEALLOCATE order_sel_cur
 	
	---------------------------------------------------------------------------------------------------------
	--  Fill the item view temp table
	---------------------------------------------------------------------------------------------------------
	DECLARE parts_cur
	CURSOR FOR
		SELECT DISTINCT a.order_no, a.order_ext, a.location, NULL, a.line_no, a.part_no
		  FROM tdc_soft_alloc_tbl a (NOLOCK),
		       tdc_cons_ords      b (NOLOCK)
		 WHERE a.order_no  	  = b.order_no
		   AND a.order_ext   	  = b.order_ext
		   AND a.location  	  = b.location
		   AND a.order_type 	  = 'S'
		   AND b.consolidation_no = @con_no
		   AND b.alloc_type       = 'PR'
		UNION
		SELECT DISTINCT a.order_no, a.order_ext, b.location, c.status, a.line_No, a.part_no
		  FROM tdc_carton_detail_tx a (NOLOCK),
		       tdc_cons_ords        b (NOLOCK),
		       tdc_carton_tx 	    c (NOLOCK)		 
		 WHERE a.order_no         = b.order_no
		   AND a.order_ext        = b.order_ext
		   AND b.consolidation_no = @con_no
		   AND c.carton_no        = a.carton_no
		   AND c.order_type       = 'S'
		   AND b.alloc_type       = 'PR'
		   AND NOT EXISTS(SELECT * FROM tdc_soft_alloc_tbl d
				   WHERE d.order_no = a.order_no
				     AND d.order_ext = a.order_ext
				     AND d.line_no = a.line_no
				     AND d.part_no = a.part_no)

 
 
		 ORDER BY a.order_no, a.order_ext, a.location, a.line_no, a.part_no

	OPEN parts_cur		
	FETCH NEXT FROM parts_cur INTO @order_no, @order_ext, @location, @status, @line_no, @part_no

	WHILE @@FETCH_STATUS = 0
	BEGIN
		SELECT @description = [description],
		       @part_status = status
		  FROM inv_master(NOLOCK)
		 WHERE part_no = @part_no
 
		INSERT INTO #pre_pack_plan_part_view     
			(con_no, order_no, order_ext, location, carton_no, line_no, part_no,
			[description], qty_to_move, qty_avail, qty_to_pack, status) 
		SELECT @con_no, @order_no, @order_ext, @location, a.carton_no, @line_no, 
		       @part_no, @description, 0, 0, CASE WHEN ISNULL(a.status, 'A') < 'S' THEN SUM(b.qty_to_pack - b.pack_qty)
								   ELSE 0 END,
		       status = CASE a.status WHEN 'P' THEN 'Pre-Pack'
					      WHEN 'Q' THEN 'Pack Ready'
					      WHEN 'C' THEN 'Closed'
					      WHEN 'S' THEN 'Staged'
					      WHEN 'O' THEN 'Open'
					      WHEN 'F' THEN 'Freighted'
					      WHEN 'X' THEN 'Shipped'
					               ELSE 'N/A'
				END
		  FROM tdc_carton_tx 	    a(NOLOCK),
		       tdc_carton_detail_tx b(NOLOCK)
		 WHERE a.order_no   = @order_no
		   AND a.order_ext  = @order_ext
		   AND a.order_type = 'S'
		   AND b.carton_no  = a.carton_no
		   AND b.line_no    = @line_no
		 GROUP BY a.carton_no, a.status

		IF ISNULL(@status, 'A') < 'S'
		BEGIN
		SELECT @qty_in_cartons = ISNULL((SELECT SUM(qty_to_pack) 
		  				  FROM #pre_pack_plan_part_view
						 WHERE order_no = @order_no
						   AND order_ext = @order_ext
						   AND location  = @location
						   AND line_no   = @line_no), 0)
	 	END
		ELSE
		BEGIN
			SELECT @qty_in_cartons =0
		END

		SELECT @qty_to_move = 0
		SELECT @qty_to_move = SUM(qty) 
		  FROM tdc_soft_alloc_tbl (NOLOCK)
		 WHERE order_no   = @order_no
		   AND order_ext  = @order_ext
		   AND order_type = 'S'
		   AND location   = @location
		   AND line_no    = @line_no
		   AND bin_no    != target_bin 
		   AND bin_no IS NOT NULL	
  		 GROUP BY order_no, order_ext, order_type, location, line_no

		INSERT INTO #pre_pack_plan_part_view     
			(con_no, order_no, order_ext, location, carton_no, line_no, part_no,
			[description], qty_to_move, qty_avail, qty_to_pack, status) 
		SELECT @con_no, @order_no, @order_ext, @location, NULL, @line_no, 
		       @part_no, @description, @qty_to_move, 
		       qty_avail = ISNULL((SELECT SUM(qty) 
		  				FROM tdc_soft_alloc_tbl (NOLOCK)
		 				WHERE order_no   = @order_no
		  				 AND order_ext  = @order_ext
		 				 AND order_type = 'S'
		 				 AND location   = @location
						 AND line_no    = @line_no
						 AND bin_no    = target_bin 
						 AND bin_no IS NOT NULL	
  						 GROUP BY order_no, order_ext, order_type, location, line_no),0),  
		       0, 'N/A'
		  FROM tdc_soft_alloc_tbl a (NOLOCK)
		 WHERE a.order_no   = @order_no
		   AND a.order_ext  = @order_ext
		   AND a.order_type = 'S'
		   AND location     = @location
		   AND a.line_no    = @line_no		   
		 GROUP BY a.order_no, a.order_ext, a.order_ext, a.order_type, a.line_no	
		HAVING SUM(a.qty) > @qty_in_cartons	

		FETCH NEXT FROM parts_cur INTO @order_no, @order_ext, @location, @status, @line_no, @part_no
	END

	CLOSE parts_cur
	DEALLOCATE parts_cur

END

RETURN
GO
GRANT EXECUTE ON  [dbo].[tdc_pre_pack_temp_tables] TO [public]
GO
