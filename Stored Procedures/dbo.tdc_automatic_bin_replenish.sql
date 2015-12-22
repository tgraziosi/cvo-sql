SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- v1.0 CB 12/11/2012 - Issue #953 Exclude non allocatable bins  
--exec tdc_automatic_bin_replenish '001', 'BCDELAUB5217', 'F01B-01-09',1.00000000,24.00000000  
  
CREATE PROCEDURE [dbo].[tdc_automatic_bin_replenish]  
 @in_location   varchar(10),  
 @in_part_no  varchar(30),  
 @in_bin_no     varchar(12),  
 @in_delta_qty       decimal (20,8),  
 @in_qty_from_lbs  decimal (20,8)  
   
AS  
/* This sp was written to handle automatic bin replenishment based on the type of bin it is etc.  */  
  
DECLARE @location   varchar(10),  
 @bin_no     varchar(12),  
 @part_no  varchar(30),  
 @repl_max   decimal(20,8),  
 @repl_min   decimal(20,8),  
 @repl_qty   decimal(20,8),  
        @pending_mgtb2b_qty     decimal(20,8),  
 @order_by_value  varchar(255),  
 @order_by_clause  varchar(255),  
 @insert_lbclause1  varchar(255),  
 @insert_lbclause2  varchar(255),  
 @lb_loc   varchar(10),  
 @lb_part   varchar(30),  
 @lb_lot   varchar(25),  
 @lb_bin   varchar(12),  
 @lb_qty   decimal(20,8),  
 @current_bin_qty decimal(20,8),  
 @qty_to_move  decimal(20,8),  
 @Priority  int,  
 @SeqNo   int,  
 @TranId   int,  
 @Bin2BinGroupId  varchar(25),  
 @declare_stmt1  varchar(255),  
 @declare_stmt2  varchar(255),  
 @declare_stmt3  varchar(255),  
 @holdsqlid  int,  
 @q_priority  int  
  
  
BEGIN  

-- v1.0 Start - Exclude if bin is marked as unallocatable
IF EXISTS (SELECT 1 FROM tdc_bin_master (NOLOCK) WHERE location = @in_location AND bin_no = @in_bin_no AND ISNULL(bm_udef_e,'') = '1')
	RETURN
-- v1.0 End

 /* select the default priority for this management bin2bin */  
 SELECT @priority = ISNULL((SELECT value_str   
         FROM tdc_config (nolock)    
        WHERE [function] = 'MGT_Pick_Q_Priority' AND active = 'Y'), 0)  
  
 IF @Priority = 0  
 BEGIN  
  RAISERROR 84695 'Error Invalid Priority.'  
  RETURN  
 END  
  
 SELECT @q_priority = cast(value_str as int) FROM tdc_config WHERE [function] = 'Pick_Q_Priority'  
  
 IF (@q_priority IS NULL) OR (@q_priority = 0)  
  SELECT @q_priority = 5  
  
 /* Clear any records that are left behind with a 0 qty and an order number of 0 */  
 DELETE FROM tdc_soft_alloc_tbl WHERE order_no = 0 AND order_ext = 0 AND qty = 0  
  
 /* we need to clear out the table before doing anything. */  
 SELECT @holdsqlid = @@spid  
 DELETE FROM tdc_temp_lb_stock_replen WHERE sqlid = @holdsqlid  
  
 /* Build select statement for lot-bin-stock query...specifically the order by logic */  
 SELECT @order_by_value = value_str   
   FROM tdc_config (nolock)  
  WHERE [function] = 'dist_cust_pick'  
  
 SELECT @order_by_clause =   
  CASE  
   WHEN @order_by_value = '1'  
    THEN  ' order by date_expires DESC '  
   WHEN @order_by_value = '2'  
    THEN  ' order by date_expires ASC '  
   WHEN @order_by_value = '3'  
    THEN  ' order by lot_bin_stock.lot_ser, lot_bin_stock.bin_no '  
   WHEN @order_by_value = '4'  
    THEN  ' order by lot_bin_stock.lot_ser DESC, lot_bin_stock.bin_no DESC '  
   WHEN @order_by_value = '5'  
    THEN  ' order by qty '  
   WHEN @order_by_value = '6'  
    THEN  ' order by qty DESC '  
   ELSE ' order by date_expires ASC '  
  END  
  
 SELECT @Bin2BinGroupId = (SELECT group_id FROM tdc_group (NOLOCK) WHERE trans_type = 'MGTB2B')   
   
 SELECT @repl_max = replenish_max_lvl, @repl_qty = replenish_qty, @repl_min = replenish_min_lvl  
   FROM tdc_bin_replenishment   
  WHERE location = @in_location   
    AND bin_no   = @in_bin_no    -- replenish bin  
    AND part_no  = @in_part_no     
    AND auto_replen = 1  
    
 /* Get existing quantity for this part in the replenishment bin */    
 SELECT @current_bin_qty = @in_qty_from_lbs  
  
 /* We need to take in consideration any existing moves (Mgtb2b) on the queue already */   
 SELECT @pending_mgtb2b_qty = ISNULL((SELECT sum(qty_to_process)   
            FROM tdc_pick_queue (nolock)  
           WHERE trans_source = 'MGT'  
      AND trans = 'MGTB2B'  
      AND location = @in_location  
      AND trans_type_no = 0  
      AND trans_type_ext = 0  
      AND line_no = 0   
      AND next_op = @in_bin_no  
      AND part_no = @in_part_no), 0)  
    
 /* set the current_bin_qty = our current total + what is pending on the queue */  
 SELECT @current_bin_qty = @current_bin_qty + @pending_mgtb2b_qty  
  
 IF @current_bin_qty >= @repl_min  
 BEGIN  
  --until those moves are completed we wont put more moves on the queue    
	RETURN  
 END  
  
 /* Determine the quantity required to fill the bin.  If there are pending moves we need to take  
    them into consideration and subtract what is left to move from the repl_qty so we don't over fill */  
   
 /* The following code was inserted for user error */  
 /* incase the user doesn't set the bins correctly we don't want negatives and so forth*/  
 IF (@current_bin_qty + @repl_qty) <= @repl_max  
 BEGIN           
  SELECT @qty_to_move = @repl_qty   
 END  
 ELSE  
 BEGIN  
  SELECT @qty_to_move = @repl_max - @repl_qty  
 END  
  
 IF (@qty_to_move > 0) /*ONLY NEED TO PROCESS QUANTITIES THAT ARE GREATER THAN 0 */  
 BEGIN  
  /* Refresh temp table */  
  DELETE FROM tdc_temp_lb_stock_replen WHERE sqlid = @holdsqlid  
  
  /* build the generic lot-bin-stock statement for finding available inventory to replenish from */  
  SELECT @insert_lbclause1 = 'INSERT INTO tdc_temp_lb_stock_replen ( sqlid,location, part_no , lot_ser, bin_no, qty)  
         SELECT ' + convert(varchar(5), @holdsqlid) + ', location, part_no, lot_ser, bin_no, qty  
           FROM lot_bin_stock (NOLOCK) '  
  
  /* Build the temp table from lot_bin_stock to determine which bins hold inventory */  
  SELECT @insert_lbclause2 = ' WHERE location = ' + CHAR(39) + @in_location + CHAR(39)+  
        '   AND part_no = ' + CHAR(39) + @in_part_no + CHAR(39)  
  
  EXEC (@insert_lbclause1 + @insert_lbclause2 + @order_by_clause)  
  
  /* remove all inventory from the protected bin types */  
  DELETE FROM tdc_temp_lb_stock_replen   
    FROM tdc_temp_lb_stock_replen, tdc_bin_master (NOLOCK)   
   WHERE tdc_temp_lb_stock_replen.sqlid = @holdsqlid  
     AND tdc_temp_lb_stock_replen.bin_no = tdc_bin_master.bin_no   
     AND tdc_temp_lb_stock_replen.location = tdc_bin_master.location  
     AND (tdc_bin_master.usage_type_code IN ('RECEIPT', 'QUARANTINE', 'PRODIN', 'PRODOUT', 'REPLENISH') 
	 OR ISNULL(tdc_bin_master.bm_udef_e,'') = '1') -- v1.0 Do not include bins marked as unallocatable
       
   
  DELETE FROM tdc_temp_lb_stock_replen where bin_no in ('F01-KEY', 'CUSTOM', 'TRANSFER')  
  
  /* remove all inventory that have allocations already being held against the qty in the bin */  
  UPDATE tdc_temp_lb_stock_replen  
     SET qty = qty - ISNULL((SELECT sum(qty)   
          FROM tdc_soft_alloc_tbl (nolock)  
         WHERE tdc_temp_lb_stock_replen.sqlid = @holdsqlid  
           AND tdc_temp_lb_stock_replen.location = tdc_soft_alloc_tbl.location  
           AND tdc_temp_lb_stock_replen.part_no = tdc_soft_alloc_tbl.part_no  
           AND tdc_temp_lb_stock_replen.bin_no = tdc_soft_alloc_tbl.bin_no), 0)  
  
  DELETE FROM tdc_temp_lb_stock_replen  
   WHERE sqlid = @holdsqlid  
     AND qty <= 0  
--BEGIN TRAN  
  DECLARE lot_bin_cursor CURSOR FOR  
   SELECT location, part_no, lot_ser, bin_no, qty  
     FROM tdc_temp_lb_stock_replen  
    WHERE sqlid = @holdsqlid  
  
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
    IF EXISTS (SELECT *   
          FROM tdc_soft_alloc_tbl  
         WHERE order_no = 0  
           AND order_ext = 0  
           AND order_type = 'S'  
           AND location = @lb_loc  
           AND line_no = 0  
           AND part_no = @lb_part  
           AND lot_ser = @lb_lot  
           AND bin_no = @lb_bin  
           AND dest_bin = @in_bin_no )  
    BEGIN  
     UPDATE tdc_soft_alloc_tbl  
        SET qty = qty + @qty_to_move  
      WHERE order_no = 0  
        AND order_ext = 0  
        AND order_type = 'S'  
        AND location = @lb_loc  
        AND line_no = 0  
        AND part_no = @lb_part  
        AND lot_ser = @lb_lot  
        AND bin_no = @lb_bin  
        AND dest_bin = @in_bin_no  
    END  
    ELSE  
    BEGIN  
     INSERT INTO tdc_soft_alloc_tbl  
      (order_type, order_no, order_ext, location, line_no, part_no,  
       lot_ser, bin_no, qty, target_bin, dest_bin, q_priority)  
     VALUES ('S', 0, 0, @in_location, 0, @in_part_no,   
      @lb_lot, @lb_bin, @qty_to_move, @in_bin_no, @in_bin_no, @q_priority)  
  
     EXEC @SeqNo = tdc_queue_get_next_seq_num 'tdc_pick_queue', @Priority    
  
     IF (@SeqNo = 0 OR @TranId = 0)  
     BEGIN  
      DEALLOCATE lot_bin_cursor  
      IF @@TRANCOUNT > 0 ROLLBACK TRAN  
      RAISERROR 84695 'Error Invalid Sequence or Trans Id or Priority.'  
      RETURN  
     END  
   
     INSERT INTO tdc_pick_queue (trans_source, trans, priority, seq_no,  
             location, trans_type_no, trans_type_ext, line_no, part_no, eco_no,lot,qty_to_process,   
             qty_processed, qty_short,next_op, bin_no, date_time,assign_group, tx_control, tx_lock)  
     VALUES ('MGT', 'MGTB2B', @Priority, @SeqNo, @in_location,  0,  0, 0,   
      @in_part_no,'2', @lb_lot, @qty_to_move, 0, 0, @in_bin_no, @lb_bin, GETDATE(), @Bin2BinGroupId, 'M', 'R')   
  
     IF @@ERROR <> 0   
     BEGIN  
      DEALLOCATE lot_bin_cursor  
      IF @@TRANCOUNT > 0 ROLLBACK TRAN  
      RAISERROR 84691 'Error Inserting into Pick_queue table.'  
      RETURN  
     END  
    END  
       
    BREAK  
   END  
   ELSE  
   BEGIN  
    IF EXISTS (SELECT *   
          FROM tdc_soft_alloc_tbl  
         WHERE order_no = 0  
           AND order_ext = 0  
           AND order_type = 'S'  
           AND location = @lb_loc  
           AND line_no = 0   
           AND part_no = @lb_part  
           AND lot_ser = @lb_lot  
           AND bin_no = @lb_bin)  
    BEGIN  
     UPDATE tdc_soft_alloc_tbl  
        SET qty = qty + @lb_qty  
      WHERE order_no = 0  
        AND order_ext = 0  
        AND order_type = 'S'  
        AND location = @lb_loc  
        AND line_no = 0   
        AND part_no = @lb_part  
        AND lot_ser = @lb_lot  
        AND bin_no = @lb_bin  
    END  
    ELSE  
    BEGIN  
     /* Allocate the inv to move and put an entry on the queue */  
     INSERT INTO tdc_soft_alloc_tbl  
      (order_type,order_no, order_ext, location, line_no, part_no,  
       lot_ser, bin_no, qty, target_bin, dest_bin, q_priority)  
     VALUES ('S', 0, 0, @in_location, 0, @lb_part,   
      @lb_lot, @lb_bin, @lb_qty, @in_bin_no, @in_bin_no, @q_priority)  
  
            IF @@ERROR <> 0   
     BEGIN  
      DEALLOCATE lot_bin_cursor  
      IF @@TRANCOUNT > 0 ROLLBACK TRAN  
      RAISERROR 84691 'Error Inserting into tdc_soft_alloc_table.'  
      RETURN  
     END  
  
     EXEC @SeqNo = tdc_queue_get_next_seq_num 'tdc_pick_queue', @Priority    
  
     IF (@SeqNo = 0 OR @TranId = 0)   
     BEGIN  
      DEALLOCATE lot_bin_cursor  
      IF @@TRANCOUNT > 0 ROLLBACK TRAN  
      RAISERROR 84695 'Error Invalid Sequence or Trans Id or Priority .'  
      RETURN  
     END  
   
     INSERT INTO tdc_pick_queue (trans_source, trans, priority, seq_no,  
             location, trans_type_no, trans_type_ext, line_no, part_no,eco_no, lot,qty_to_process,   
             qty_processed, qty_short,next_op, bin_no, date_time,assign_group, tx_control, tx_lock)  
     VALUES ('MGT', 'MGTB2B', @Priority,  @SeqNo, @in_location,  0,  0, 0,   
      @in_part_no,'2', @lb_lot, @lb_qty, 0, 0, @in_bin_no, @lb_bin, GETDATE(), @Bin2BinGroupId, 'M', 'R')   
  
     IF @@ERROR <> 0   
     BEGIN  
      DEALLOCATE lot_bin_cursor  
      IF @@TRANCOUNT > 0 ROLLBACK TRAN  
      RAISERROR 84691 'Error Inserting into Pick_queue table.'  
      RETURN  
     END  
    END  
  
    SELECT @qty_to_move = @qty_to_move - @lb_qty   
  
    FETCH NEXT FROM lot_bin_cursor    
     INTO @lb_loc, @lb_part, @lb_lot, @lb_bin, @lb_qty  
   END  
  END /*end while loop*/  
  
  DEALLOCATE lot_bin_cursor  
  
 END /* QTY > 0 CHECK */  
   
--COMMIT TRAN  
   DELETE FROM tdc_temp_lb_stock_replen WHERE sqlid = @holdsqlid  
END  
GO
GRANT EXECUTE ON  [dbo].[tdc_automatic_bin_replenish] TO [public]
GO
