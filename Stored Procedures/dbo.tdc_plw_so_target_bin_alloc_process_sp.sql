SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[tdc_plw_so_target_bin_alloc_process_sp]
	@template_code	varchar(20),
	@con_no 	int,
	@user_id 	varchar(50)
AS

DECLARE	@location 	varchar(10),
	@part_no	varchar(30),
	@lot_ser	varchar(25),
	@bin_no		varchar(12),
	@qty_to_process	decimal(24,8),
	@qty_avail	decimal(24,8),
	@qty_to_alloc	decimal(24,8),
	@order_no	int,
	@order_ext	int,
	@line_no	int,
	@last_location  varchar(10),
	@pre_pack_flg	char(1),
	@needed_qty	decimal(20, 8),
	@conv_factor	decimal(20, 8)

SELECT @last_location = ''

DECLARE target_alloc_cur
 CURSOR FOR 
	SELECT a.location, a.part_no, a.lot_ser, a.bin_no, SUM(a.qty_to_process)
	  FROM #so_target_bin_alloc_lot_bin a,
	       #so_target_bin_alloc_parts   b
	 WHERE a.location       = b.location
	   AND a.part_no        = b.part_no
	   AND a.qty_to_process > 0
	 GROUP BY a.location, a.part_no, a.lot_ser, a.bin_no
	 ORDER BY a.location, a.part_no, a.lot_ser, a.bin_no

OPEN target_alloc_cur
FETCH NEXT FROM target_alloc_cur INTO @location, @part_no, @lot_ser, @bin_no, @qty_to_process

WHILE @@FETCH_STATUS = 0
BEGIN

	DECLARE target_line_cur CURSOR FOR 
		SELECT a.order_no, a.order_ext, a.line_no 
		  FROM #so_allocation_detail_view a,
		       #so_alloc_management       b
		 WHERE a.order_no  = b.order_no
		   AND a.order_ext = b.order_ext
		   AND a.location  = b.location
		   AND a.location  = @location
		   AND a.part_no   = @part_no
		   AND b.sel_flg  != 0
	
	OPEN target_line_cur
	FETCH NEXT FROM target_line_cur INTO @order_no, @order_ext, @line_no
	WHILE @@FETCH_STATUS = 0 AND @qty_to_process > 0
	BEGIN		
		 SELECT @qty_avail = ( 			 
					 SUM(qty) - 			  	-- Sum of the quantity in lot_bin_stock
					 (SELECT ISNULL((SELECT SUM(qty)   	-- Subtract the quantity allocated
						  	   FROM tdc_soft_alloc_tbl 			
							  WHERE location = lb.location			
							    AND part_no = lb.part_no			
							    AND lot_ser = lb.lot_ser			
							    AND bin_no = lb.bin_no)			
						, 0)))			 
				  FROM lot_bin_stock lb, tdc_bin_master bm    
				 WHERE lb.location   = @location
				   AND lb.part_no    = @part_no
				   AND lb.bin_no     = bm.bin_no	  
				   AND lb.location   = bm.location	
				   AND lb.lot_ser = @lot_ser
				   AND lb.bin_no = @bin_no 
				
				
				 GROUP BY lb.location, lb.part_no, lb.lot_ser, lb.bin_no, 		
				          lb.date_expires, bm.usage_type_code, lb.qty			
				HAVING SUM(qty) > (SELECT ISNULL((SELECT SUM(qty)			 
								     FROM tdc_soft_alloc_tbl 		
								    WHERE location = lb.location	 
								      AND part_no  = lb.part_no		 
								      AND lot_ser  = lb.lot_ser		 
								      AND bin_no   = lb.bin_no), 0)) 

		SELECT @qty_avail = ISNULL(@qty_avail, 0)

	IF EXISTS(SELECT * 
			  FROM ord_list (NOLOCK)
			 WHERE order_no  = @order_no
			   AND order_ext = @order_ext
			   AND line_no   = @line_no
			   AND part_type = 'C')
		BEGIN
			SELECT @conv_factor = conv_factor
			  FROM ord_list_kit (NOLOCK)
			 WHERE order_no  = @order_no
			   AND order_ext = @order_ext
			   AND line_no   = @line_no
			   AND part_no   = @part_no

			SELECT @needed_qty = 0
			SELECT @needed_qty = ISNULL((SELECT ordered - shipped		 		-- Ordered - Shipped
					               FROM ord_list_kit (NOLOCK)
					     	      WHERE order_no  = @order_no
							AND order_ext = @order_ext
					                AND line_no   = @line_no
					                AND location  = @location       
					                AND part_no   = @part_no), 0) 
							- 
							(SELECT ISNULL( (SELECT SUM(qty)		-- Allocated Qty
								           FROM tdc_soft_alloc_tbl
									  WHERE order_no   = @order_no
								            AND order_ext  = @order_ext
								            AND order_type = 'S'
								            AND location   = @location
								            AND line_no    = @line_no
								            AND part_no    = @part_no
								          GROUP BY location), 0))
		END
		ELSE
		BEGIN
			SELECT @conv_factor = conv_factor
			  FROM ord_list (NOLOCK)
			 WHERE order_no  = @order_no
			   AND order_ext = @order_ext
			   AND line_no   = @line_no

			SELECT @needed_qty = 0
			SELECT @needed_qty = ISNULL((SELECT ordered - shipped		 		-- Ordered - Shipped
					               FROM ord_list
					     	      WHERE order_no  = @order_no
							AND order_ext = @order_ext
					                AND line_no   = @line_no
					                AND location  = @location       
					                AND part_no   = @part_no), 0) 
							- 
							(SELECT ISNULL( (SELECT SUM(qty)		-- Allocated Qty
								           FROM tdc_soft_alloc_tbl
									  WHERE order_no   = @order_no
								            AND order_ext  = @order_ext
								            AND order_type = 'S'
								            AND location   = @location
								            AND line_no    = @line_no
								            AND part_no    = @part_no
								          GROUP BY location), 0))
		END
		
		IF @conv_factor <> 1		
	            SELECT @needed_qty = FLOOR(@needed_qty / @conv_factor) * @conv_factor	


		----------------------------------------------------------------------------------------------
		-- Make sure not trying to process more than available
		----------------------------------------------------------------------------------------------
		IF @qty_to_process > @qty_avail
			SELECT @qty_to_alloc = @qty_avail			
		ELSE
			SELECT @qty_to_alloc = @qty_to_process					

		IF @qty_to_alloc > @needed_qty
			SELECT @qty_to_alloc = @needed_qty	

		----------------------------------------------------------------------------------------------
		-- Clear the temp table and insert the necessary data
		----------------------------------------------------------------------------------------------
		TRUNCATE TABLE #plw_alloc_by_lot_bin
		
		INSERT INTO #plw_alloc_by_lot_bin (lot_ser, bin_no, date_expires, cur_alloc, avail_qty, sel_flg1, sel_flg2, qty)
		VALUES (@lot_ser, @bin_no, '', 0, 0, -1, 0, @qty_to_alloc)
	
		----------------------------------------------------------------------------------------------
		-- Execute alloc_by_lot stored procedure
		----------------------------------------------------------------------------------------------	
		EXEC tdc_plw_so_allocbylot_process_sp @location, @part_no, @line_no, @order_no, @order_ext, 
					              @user_id, @con_no, @template_code
		 
		----------------------------------------------------------------------------------------------
		-- Test for error
		----------------------------------------------------------------------------------------------
		IF @@ERROR != 0
		BEGIN
			CLOSE 	   target_line_cur
			DEALLOCATE target_line_cur

			CLOSE 	   target_alloc_cur
			DEALLOCATE target_alloc_cur

			RETURN -1
		END

		----------------------------------------------------------------------------------------------
		-- Decrement qty to process
		----------------------------------------------------------------------------------------------
		SELECT @qty_to_process = @qty_to_process - @qty_to_alloc

		FETCH NEXT FROM target_line_cur INTO @order_no, @order_ext, @line_no
	END
	
	CLOSE 	   target_line_cur
	DEALLOCATE target_line_cur

	IF @last_location != @location
	BEGIN
		SELECT @last_location = @location

		SELECT @pre_pack_flg     = CASE dist_type WHEN 'PrePack' THEN 'Y' ELSE 'N' END 
		  FROM tdc_plw_process_templates (NOLOCK)
		 WHERE template_code  = @template_code
		   AND UserID         = @user_id
		   AND location       = @location
		   AND order_type     = 'S'
		   AND type           = 'cons'

		UPDATE tdc_main SET pre_pack = @pre_pack_flg
		WHERE consolidation_no = @con_no		
	END	


	FETCH NEXT FROM target_alloc_cur INTO @location, @part_no, @lot_ser, @bin_no, @qty_to_process 
END

CLOSE 	   target_alloc_cur
DEALLOCATE target_alloc_cur





----------------------------------------------------------------------------------------------
-- Clear the records in the main allocation table, so that they aren't allocated after this.
----------------------------------------------------------------------------------------------
UPDATE #so_alloc_management SET sel_flg = 0


RETURN 0
GO
GRANT EXECUTE ON  [dbo].[tdc_plw_so_target_bin_alloc_process_sp] TO [public]
GO
