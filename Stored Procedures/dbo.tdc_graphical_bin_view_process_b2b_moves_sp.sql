SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- v1.0 CB 11/10/2012 Issue #904 After breakout on clipboard just move single part if passed in
  
CREATE PROCEDURE [dbo].[tdc_graphical_bin_view_process_b2b_moves_sp]  
 @template_id  int,  
 @userid   varchar(50),  
 @from_bin  varchar(12),  
 @to_bin_input  varchar(12), --THIS PARAMETER SHOULD BE AN EMPTY STRING IF WE ARE PROCESSING MULTIPLE MOVES  
 @cb_part_no varchar(30) = '' -- v1.0
  
AS  
DECLARE   
 @location  varchar(10),  
 @to_bin   varchar(12),  
 @avail_qty  decimal(20,8),  
 @qty_to_move  decimal(20,8),  
 @date_expires  datetime,  
 @part_no  varchar(25),  
 @lot_ser  varchar(25),  
 @priority  varchar(1),  
 @user_or_group  varchar(25),  
 @SeqNo   int,  
 @ret   int,  
 @err_msg  varchar(255),  
 @language  varchar(10)  
  
 SELECT @language = ISNULL(language, 'us_english') FROM tdc_sec (NOLOCK) WHERE userid = @userid  
  
 --Get the location from the template  
 SELECT @location = location FROM tdc_graphical_bin_template (NOLOCK) WHERE template_id = @template_id  
  
 --WE ARE PROCESSING MULTIPLE MGTB2B MOVES HERE  
 IF @to_bin_input = ''  
 BEGIN  
  --REMOVE ALL OF THE PARTS THAT ARE NOT GOING TO BE MOVED VIA A MGTB2B MOVE  
  DELETE FROM #tdc_gbv_b2b_data WHERE qty_to_move = 0  
 END  
 ELSE --WE ARE PROCESSING A SINGLE MGTB2B MOVE AND MOVING ALL AVAILABLE PARTS HERE  
 BEGIN  
  /* build data that we need to move */  
  EXEC @ret = tdc_gbv_build_b2b_data_sp @template_id, @userid, @from_bin, @err_msg OUTPUT  
  IF @ret < 0  
  BEGIN  
   IF @@TRANCOUNT > 0 ROLLBACK TRAN  
   --'Error Inserting into Pick_queue table.'  
   SELECT @err_msg = err_msg FROM tdc_lookup_error (NOLOCK) WHERE language = @language AND module = 'GBV' AND trans = 'GBV_MGTB2B' AND  err_no = 3  
   RAISERROR 84691 @err_msg  
   RETURN -3  
  END 

  -- v1.0 Start 
  IF @cb_part_no <> ''
	DELETE #tdc_gbv_b2b_data WHERE part_no <> @cb_part_no
  -- v1.0 End

  IF NOT EXISTS(SELECT TOP 1 part_no FROM #tdc_gbv_b2b_data (NOLOCK))  
  BEGIN  
   RETURN -99  --THIS SPECIAL RETURN CODE IS USED TO TELL THE USER THAT NOTHING WAS MOVED DURING THE TRANSACTION  
  END  
  
  /* select the default priority for this management bin2bin */  
  SELECT @priority = value_str FROM tdc_config where [function] = 'Pick_Q_Priority'  
  /* select the default user_group for MGTB2B moves*/    
  SELECT @user_or_group = group_id FROM tdc_group (NOLOCK) WHERE trans_type = 'MGTB2B'  
  /* update all remaining values*/  
  UPDATE #tdc_gbv_b2b_data   
   SET  qty_to_move = avail_qty,   
    priority = @priority,   
    user_or_group = @user_or_group,   
    to_bin = @to_bin_input  
 END  
 --CURSOR THROUGH ALL RECORDS IN THE TABLE  
 DECLARE gbv_data_cursor CURSOR FOR  
  SELECT  part_no, lot_ser, date_expires, avail_qty, qty_to_move,   
   priority, user_or_group, to_bin   
  FROM #tdc_gbv_b2b_data  
 OPEN gbv_data_cursor  
 FETCH NEXT FROM gbv_data_cursor INTO   
  @part_no, @lot_ser, @date_expires, @avail_qty, @qty_to_move,   
  @priority, @user_or_group, @to_bin  
 WHILE @@FETCH_STATUS = 0  
 BEGIN  
  
  IF @priority = 0 OR @priority = '' OR @priority IS NULL  
  BEGIN  
   SELECT @priority = value_str FROM tdc_config where [function] = 'Pick_Q_Priority'  
  END  
  
  IF @user_or_group = '' OR @user_or_group IS NULL  
  BEGIN  
   SELECT @user_or_group = group_id FROM tdc_group (NOLOCK) WHERE trans_type = 'MGTB2B'  
  END  
  /******************************************/  
  --LOOK FOR ANY EXISTING MGTB2B MOVES COMING FROM THE "FROM BIN"  
   --IF FOUND UPDATE  
   --OTHERWISE INSERT NEW RECORDS  
  IF EXISTS (SELECT * FROM tdc_soft_alloc_tbl (nolock)  
       WHERE  order_no = 0 and  
     order_ext = 0 and   
     order_type = 'S' and  
     location = @location and  
     line_no = 0 and  
     part_no = @part_no and  
     lot_ser = @lot_ser and  
     bin_no = @from_bin and  
     target_bin = @to_bin)  
  BEGIN  
   UPDATE tdc_soft_alloc_tbl  
   SET qty = qty + @qty_to_move  
   WHERE   order_no = 0 and  
    order_ext = 0 and   
    order_type = 'S' and  
    location = @location and  
    line_no = 0 and  
    part_no = @part_no and  
    lot_ser = @lot_ser and  
    bin_no = @from_bin and   
    target_bin = @to_bin  
  END  
  ELSE  
  BEGIN  
   INSERT INTO tdc_soft_alloc_tbl  
    (order_type, order_no, order_ext, location, line_no, part_no, lot_ser, bin_no, qty, target_bin, dest_bin,q_priority)  
   VALUES  ('S',0, 0, @location, 0, @part_no, @lot_ser, @from_bin, @qty_to_move, @to_bin, @to_bin, @Priority)  
  
   EXEC @SeqNo = tdc_queue_get_next_seq_num 'tdc_pick_queue' , @Priority    
  
   IF (@SeqNo = 0)   
   BEGIN  
    DEALLOCATE gbv_data_cursor         
  
    IF @@TRANCOUNT > 0 ROLLBACK TRAN  
    SELECT @err_msg = err_msg FROM tdc_lookup_error (NOLOCK) WHERE language = @language AND module = 'GBV' AND trans = 'GBV_MGTB2B' AND  err_no = 4  
    RAISERROR 84695 @err_msg--'Error Invalid Sequence or Trans Id or Priority .'  
    RETURN -1  
   END  
  
   INSERT INTO tdc_pick_queue (trans_source, trans, priority, seq_no,  
    location, trans_type_no, trans_type_ext, line_no, part_no, lot,qty_to_process,   
    qty_processed, qty_short,next_op, bin_no, date_time,assign_group, tx_control, tx_lock)  
   VALUES ('MGT', 'MGTB2B', @Priority ,  @SeqNo  , @location ,  0 ,  0  , 0,   
    @part_no ,@lot_ser,  @qty_to_move , 0, 0, @to_bin, @from_bin  , GETDATE(),@user_or_group , 'M'  , 'R' )   
  
   IF @@ERROR <> 0   
   BEGIN  
    DEALLOCATE gbv_data_cursor         
  
    IF @@TRANCOUNT > 0 ROLLBACK TRAN  
    SELECT @err_msg = err_msg FROM tdc_lookup_error (NOLOCK) WHERE language = @language AND module = 'GBV' AND trans = 'GBV_MGTB2B' AND  err_no = 3  
    RAISERROR 84691 @err_msg--'Error Inserting into Pick_queue table.'  
    RETURN -2  
   END  
  
  END  
  /*****************************************/  
  FETCH NEXT FROM gbv_data_cursor INTO   
   @part_no, @lot_ser, @date_expires, @avail_qty, @qty_to_move,   
   @priority, @user_or_group, @to_bin  
 END  
 CLOSE gbv_data_cursor  
 DEALLOCATE gbv_data_cursor  
  
RETURN 0  
GO
GRANT EXECUTE ON  [dbo].[tdc_graphical_bin_view_process_b2b_moves_sp] TO [public]
GO
