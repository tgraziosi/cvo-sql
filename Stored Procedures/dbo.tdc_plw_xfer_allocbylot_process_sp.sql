SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[tdc_plw_xfer_allocbylot_process_sp]
			@from_loc      varchar(10),
			@part_no       varchar(30),
			@line_no       int,
			@xfer_no       int,
			@user_id       varchar(50),
			@template_code varchar(15)
AS

DECLARE	@lot_ser          varchar(25),
        @bin_no           varchar(12),
	@name 		  varchar(100),
	@desc 		  varchar(100),
	@pack_group    	  varchar(12),
	@qty_to_alloc     decimal(20, 8),
	@qty_to_unalloc   decimal(20, 8),
	@allocated_qty    decimal(20, 8),
	@in_stock_qty     decimal(20, 8),
	@needed_qty       decimal(20, 8),
	@conv_factor	  decimal(20,8),
	@q_priority	  int,
	@assigned_user	  varchar(50),
	@on_hold          char(1),
	@data		  varchar(1000)

BEGIN TRAN

-- Change the prev alloc %
IF EXISTS(SELECT * FROM tdc_alloc_history_tbl(NOLOCK)
	   WHERE order_no   = @xfer_no
	     AND order_ext  = 0
	     AND order_type = 'T'
	     AND location   = @from_loc)
BEGIN
	UPDATE tdc_alloc_history_tbl 
	   SET fill_pct = a.curr_alloc_pct
	  FROM #xfer_alloc_management a, tdc_alloc_history_tbl b(NOLOCK)
	 WHERE b.order_no   = @xfer_no
	   AND b.order_ext  = 0
	   AND b.order_type = 'T'
	   AND b.location   = @from_loc
	   AND a.xfer_no    = b.order_no
	   AND a.from_loc   = b.location
END
ELSE
BEGIN
	INSERT INTO tdc_alloc_history_tbl (order_no, order_ext, location, fill_pct, alloc_date, alloc_by, order_type)
	VALUES (@xfer_no, 0, @from_loc, 0, GETDATE(), @user_id, 'T')
END

-- Get conv_factor for the part
SELECT @conv_factor = conv_factor
  FROM xfer_list (NOLOCK)
 WHERE xfer_no  = @xfer_no
   AND part_no  = @part_no
   AND line_no  = @line_no

--*********************************** Do unallocate first ************************************************

-- Loop through all the records with delta_alloc < 0
DECLARE unallocate_cursor CURSOR FOR 
	SELECT lot_ser, bin_no, qty FROM #plw_alloc_by_lot_bin WHERE sel_flg2 <> 0 AND qty > 0

OPEN unallocate_cursor
FETCH NEXT FROM unallocate_cursor INTO @lot_ser, @bin_no, @qty_to_unalloc

WHILE (@@FETCH_STATUS <> -1)
BEGIN		
	/* Determine if any of the transactions on the queue are being processed.  */
	/* If so, then rollback. Otherwise, continue on and change the queue by    */
	/* updating & deleting all the applicable pick transactions for the        */
	/* order / part / lot/ bin being unallocated. 				   */
	IF EXISTS (SELECT * 
		     FROM tdc_pick_queue 
		    WHERE trans          = 'XFERPICK'
		      AND trans_type_no  = @xfer_no
		      AND trans_type_ext = 0
		      AND location       = @from_loc
                      AND part_no        = @part_no
		      AND lot            = @lot_ser
		      AND bin_no         = @bin_no
		      AND tx_lock       != 'R')
	BEGIN
		CLOSE      unallocate_cursor
		DEALLOCATE unallocate_cursor
		ROLLBACK TRANSACTION
		RAISERROR ('Pick transaction is locked on the Queue.  Unable to unallocate.',16, 1)
		RETURN
	END

	UPDATE tdc_soft_alloc_tbl 
	   SET qty = qty  - @qty_to_unalloc
         WHERE order_no   = @xfer_no
           AND order_ext  = 0
	   AND location   = @from_loc
	   AND part_no    = @part_no
	   AND line_no    = @line_no
	   AND lot_ser    = @lot_ser
	   AND bin_no     = @bin_no
           AND order_type = 'T'

	IF @@ERROR <> 0
	BEGIN
		CLOSE      unallocate_cursor
		DEALLOCATE unallocate_cursor
		ROLLBACK TRANSACTION
		RAISERROR ('Update tdc_soft_alloc_tbl table failed.  Unable to unallocate.',16, 1)
		RETURN
	END

	UPDATE tdc_pick_queue 
	   SET qty_to_process = qty_to_process - @qty_to_unalloc
	 WHERE trans          = 'XFERPICK'
	   AND trans_type_no  = @xfer_no
	   AND trans_type_ext = 0
	   AND location       = @from_loc
	   AND part_no        = @part_no
	   AND lot            = @lot_ser
	   AND bin_no         = @bin_no

	IF @@ERROR <> 0
	BEGIN
		CLOSE      unallocate_cursor
		DEALLOCATE unallocate_cursor
		ROLLBACK TRANSACTION
		RAISERROR ('Update tdc_pick_queue table failed.  Unable to unallocate.',16, 1)    		
		RETURN
	END

	DELETE FROM tdc_pick_queue 
	 WHERE trans           = 'XFERPICK'
	   AND trans_type_no   = @xfer_no
	   AND trans_type_ext  = 0
	   AND location        = @from_loc
	   AND part_no         = @part_no
	   AND lot             = @lot_ser
	   AND bin_no          = @bin_no
	   AND qty_to_process <= 0
	


	-- Log the record
	INSERT INTO tdc_log (tran_date, UserID, trans_source, module, trans, tran_no, tran_ext, part_no, 
			     lot_ser, bin_no, location, quantity, data)
	SELECT getdate(), @user_id, 'VB', 'PLWXFER', 'UNALLOCATION', @xfer_no, 0, @part_no, 
	       @lot_ser,  @bin_no, @from_loc, @qty_to_unalloc, 
	       'line number = ' + RTRIM(CAST(@line_no AS varchar(10)))

	FETCH NEXT FROM unallocate_cursor INTO @lot_ser, @bin_no, @qty_to_unalloc
END

CLOSE      unallocate_cursor
DEALLOCATE unallocate_cursor


--************************* Do allocate **********************************************************

-- 1. 
------------------------------------------------------------------------------------------
-- Get the user's settings
------------------------------------------------------------------------------------------
SELECT @q_priority    = tran_priority,
       @on_hold       = on_hold,
       @pack_group    = pass_bin,
       @assigned_user = CASE WHEN user_group = '' OR user_group like '%DEFAULT%' 
			     THEN NULL
			     ELSE user_group
			END
  FROM tdc_plw_process_templates (NOLOCK)
 WHERE template_code  = @template_code
   AND UserID         = @user_id
   AND location       = @from_loc
   AND order_type     = 'T'
   AND type           = 'one4one'

SET @data = 'Line: ' + CAST(@line_no as varchar(3)) + '; Order Type: T'

-- 2. Get needed qty
SELECT @needed_qty = 0
SELECT @needed_qty = ISNULL((SELECT (ordered - shipped) * conv_factor	 			-- Ordered - Shipped
		               FROM xfer_list
		     	      WHERE xfer_no  = @xfer_no
		                AND line_no  = @line_no
		                AND from_loc = @from_loc       
		                AND part_no  = @part_no), 0) 
				- 
					(SELECT	ISNULL( (SELECT SUM(qty)		-- Allocated Qty
						   	   FROM tdc_soft_alloc_tbl
				 			  WHERE order_no   = @xfer_no
							    AND order_ext  = 0
							    AND location   = @from_loc
							    AND part_no    = @part_no
							    AND line_no    = @line_no
							    AND order_type = 'T'
							  GROUP BY location), 0))

IF @conv_factor <> 1					
            SELECT @needed_qty = FLOOR(@needed_qty / @conv_factor) * @conv_factor					

-- Loop through all the records with sel_flg1 <> 0
DECLARE allocate_cursor CURSOR FOR 
	SELECT lot_ser, bin_no, qty FROM #plw_alloc_by_lot_bin WHERE sel_flg1 <> 0 AND qty > 0

OPEN allocate_cursor
FETCH NEXT FROM allocate_cursor INTO @lot_ser, @bin_no, @qty_to_alloc

WHILE (@@FETCH_STATUS <> -1)
BEGIN
	-- 3. Check if we still need to allocate for the part_no / line_no
	IF @needed_qty < @qty_to_alloc	
	BEGIN
		DEALLOCATE allocate_cursor
		ROLLBACK TRANSACTION
		RAISERROR ('Cannot over allocate part: %s on location: %s.  Unable to allocate.',16, 1, @part_no, @from_loc)
		RETURN
	END

	-- 4. Check if we have enough in stock qty
	SELECT @in_stock_qty = 0
	SELECT @in_stock_qty = qty
	  FROM lot_bin_stock (NOLOCK)
	 WHERE location  = @from_loc
	   AND part_no   = @part_no
	   AND lot_ser   = @lot_ser	
	   AND bin_no    = @bin_no

	SELECT @allocated_qty = 0
	SELECT @allocated_qty = SUM(qty) 		 
          FROM tdc_soft_alloc_tbl (NOLOCK)
         WHERE location   = @from_loc
           AND lot_ser    = @lot_ser	
           AND bin_no     = @bin_no
           AND part_no    = @part_no
        GROUP BY location

	IF (@in_stock_qty - @allocated_qty) < @qty_to_alloc

	BEGIN
		CLOSE      allocate_cursor
		DEALLOCATE allocate_cursor
		ROLLBACK TRANSACTION
		RAISERROR ('Not enough qty of part : %s in LOT: %s; BIN: %s; Location: %s. Unable to allocate.',16, 1, @part_no, @lot_ser, @bin_no, @from_loc)
		RETURN
	END

	-- 5. Insert into tdc_soft_alloc_tbl
	IF EXISTS(SELECT * FROM tdc_soft_alloc_tbl (NOLOCK)
		   WHERE order_no   = @xfer_no
		     AND order_ext  = 0
		     AND order_type = 'T'
		     AND location   = @from_loc
		     AND part_no    = @part_no
		     AND line_no    = @line_no
		     AND lot_ser    = @lot_ser
                     AND bin_no     = @bin_no)
	BEGIN
		UPDATE tdc_soft_alloc_tbl
		   SET qty           = qty + @qty_to_alloc,
		       dest_bin      = @pack_group,
		       q_priority    = @q_priority,
		       assigned_user = @assigned_user,
		       user_hold     = @on_hold
		 WHERE order_no      = @xfer_no
		   AND order_ext     = 0
		   AND order_type    = 'T'
		   AND location      = @from_loc
		   AND part_no       = @part_no
		   AND line_no       = @line_no
		   AND lot_ser       = @lot_ser
                   AND bin_no        = @bin_no
	END
	ELSE
	BEGIN
		INSERT INTO tdc_soft_alloc_tbl(order_no, order_ext, location, line_no, part_no, lot_ser, bin_no, qty, 
		                               target_bin, dest_bin, trg_off, order_type, assigned_user, q_priority, user_hold, alloc_type)  
		VALUES(@xfer_no, 0, @from_loc, @line_no, @part_no, @lot_ser,  @bin_no, @qty_to_alloc,
		       @bin_no, @pack_group, NULL, 'T', @assigned_user, @q_priority, @on_hold, 'XF')
	END

	INSERT INTO tdc_log (tran_date, UserID, trans_source, module, trans, tran_no, tran_ext, part_no, lot_ser, bin_no, location, quantity, data)
	VALUES(GETDATE(), @user_id, 'VB', 'PLW', 'ALLOCATION', @xfer_no, 0, @part_no, @lot_ser, @bin_no, @from_loc, @qty_to_alloc, @data)

	FETCH NEXT FROM allocate_cursor INTO @lot_ser, @bin_no, @qty_to_alloc
END

CLOSE      allocate_cursor
DEALLOCATE allocate_cursor

COMMIT TRAN

RETURN 
GO
GRANT EXECUTE ON  [dbo].[tdc_plw_xfer_allocbylot_process_sp] TO [public]
GO
