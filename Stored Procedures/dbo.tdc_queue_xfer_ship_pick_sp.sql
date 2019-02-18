SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- v1.0 CB 19/10/2011 Performance Enhancements
-- v1.1 CT 08/11/2012 Autopack for transfers
-- v1.2 CB 19/12/2018 Performance
-- v1.3 CB 11/02/2019 - Add logging
CREATE PROCEDURE [dbo].[tdc_queue_xfer_ship_pick_sp]   
 @queue_id int,   
 @tote_bin varchar(12),   
 @xfer_ship char(1),  
 @stationid int,  
 @pallet int = 0   
  
AS

SET NOCOUNT ON -- v1.2  
  
DECLARE @lb_tracking char(1),  
 @part_no varchar(30),  
 @kit_item varchar(30),  
 @line_no int,  
 @lot_ser varchar(25),  
 @bin_no varchar(12),  
 @order_no int,  
 @order_ext int,  
 @qty decimal(20,8),  
 @weight decimal(20,8),  
 @who varchar(50),  
 @counter int,  
 @child_no int,   
 @loc varchar(10),  
 @to_loc varchar(10),  
 @return int,  
 @mask_code varchar(15),  
 @trans varchar(10),  
 @serial_no varchar(40),  
 @serial_raw varchar(40),  
 @part_type char(1),  
 @carton_code varchar(10),  
 @pack_type varchar(10),  
 @err_msg varchar(255)  
  
  
--BEGIN SED009 -- Order Pick to Auto Pack Out     
--JVM 09/01/2010
	DECLARE @trans_type_no INT, @trans_type_ext INT 
	 
	SELECT	@trans_type_no = trans_type_no   
	FROM	tdc_pick_queue (NOLOCK) -- v1.0
	WHERE	tran_id = @queue_id

	SELECT	@trans_type_ext = trans_type_ext  
	FROM	tdc_pick_queue (NOLOCK) -- v1.0
	WHERE	tran_id = @queue_id	
--END   SED009 -- Order Pick to Auto Pack Out       

  
SELECT @part_type = 'P'  
SELECT @kit_item = ''  
SELECT @counter = 0, @child_no = 0, @return = 0, @order_ext = 0  
SELECT @who = who FROM #temp_who  
SELECT @err_msg = 'OK'  
  
IF (@xfer_ship = 'T')  
BEGIN  
 SELECT  @part_no = part_no,  
  @line_no = line_no,  
  @lot_ser = lot_ser,  
  @bin_no  = bin_no,  
  @order_no = xfer_no,  
  @qty = qty,  
  @loc = from_loc  
 FROM #adm_pick_xfer  
 WHERE row_id = 1  
   
 SELECT @lb_tracking = lb_tracking, @to_loc = to_loc   
   FROM xfer_list (nolock)   
  WHERE xfer_no = @order_no AND line_no = @line_no  
END  
ELSE  
BEGIN  
 IF EXISTS (SELECT * FROM #adm_pick_ship)  
 BEGIN  
  SELECT  @part_no = part_no,  
   @line_no = line_no,  
   @lot_ser = lot_ser,  
   @bin_no  = bin_no,  
   @order_no  = order_no,  
   @order_ext = ext,  
   @qty = qty,  
   @loc = location  
  FROM #adm_pick_ship  
  WHERE row_id = 1  
    
  SELECT @lb_tracking = lb_tracking  
    FROM ord_list (nolock)   
   WHERE order_no = @order_no AND order_ext = @order_ext AND line_no = @line_no    
 END  
 ELSE  
 BEGIN  
  SELECT  @part_no = part_no,  
   @line_no = line_no,  
   @lot_ser = lot_ser,  
   @bin_no  = bin_no,  
   @order_no  = order_no,  
   @order_ext = order_ext,  
   @qty = quantity,  
   @loc = location  
  FROM #pick_custom_kit_order  
  WHERE row_id = 1  
  
  SELECT @lb_tracking = lb_tracking  
    FROM ord_list_kit (nolock)   
   WHERE order_no = @order_no AND order_ext = @order_ext AND line_no = @line_no AND part_no = @part_no  
  
  SELECT @part_type = 'C'  
  SELECT @kit_item = @part_no  
 END  
  
 SELECT @to_loc = @loc  
END  

-- v1.3 Start
IF (@xfer_ship = 'T')  
BEGIN
	INSERT	dbo.cvo_transfer_pick_pack_log (log_date, xfer_no, log_message)
	SELECT	GETDATE(), @order_no, 'Calling tdc_adm_pick_ship for @line_no ' + CAST(@line_no as varchar(20)) 
END
-- v1.3 End
  
BEGIN TRAN  
  
IF (@xfer_ship = 'S')  
BEGIN  
 IF @part_type = 'C'  
  EXEC @return = tdc_dist_kit_pick_sp  
 ELSE  
  EXEC @return = tdc_adm_pick_ship  
END  
ELSE  
BEGIN  
 EXEC @return = tdc_pick_xfer  
END  
  
IF (@return < 0)  
BEGIN  
 IF (@@TRANCOUNT > 0) ROLLBACK  

	-- v1.3 Start
	IF (@xfer_ship = 'T')  
	BEGIN
		INSERT	dbo.cvo_transfer_pick_pack_log (log_date, xfer_no, log_message)
		SELECT	GETDATE(), @order_no, 'Error returned from tdc_adm_pick_ship for @line_no ' + CAST(@line_no as varchar(20)) 
	END
	-- v1.3 End

 RETURN -101  
END  
  
IF (@stationid IS NOT NULL) AND (@stationid > 0)  
BEGIN  
 IF EXISTS (SELECT *   
       FROM tdc_pack_queue (NOLOCK) -- v1.0  
      WHERE station_id = @stationid  
        AND order_no  = @order_no   
        AND order_ext = @order_ext   
        AND line_no   = @line_no   
        AND part_no   = @part_no)  
 BEGIN  
  UPDATE tdc_pack_queue  
     SET picked = picked + @qty, last_modified_by = @who, last_modified_date = getdate()  
   WHERE station_id = @stationid  
     AND order_no  = @order_no   
     AND order_ext = @order_ext  
     AND line_no   = @line_no   
     AND part_no   = @part_no  
 END  
 ELSE  
 BEGIN    
  INSERT INTO tdc_pack_queue (order_no, order_ext, line_no, part_no, picked, group_id, station_id, last_modified_by)  
  SELECT @order_no, @order_ext, @line_no, @part_no, @qty, group_id, @stationid, @who  
    FROM tdc_pack_station_tbl (NOLOCK) -- v1.0  
   WHERE station_id = @stationid  
 END  
END  
  
IF @part_type != 'C'  
BEGIN  
 IF (@lb_tracking = 'Y')  
  SELECT @counter = (SELECT count(*)   
       FROM  tdc_dist_item_pick (nolock)  
       WHERE method     = '01'       AND  
           order_no   = @order_no  AND  
      order_ext  = @order_ext AND  
      line_no    = @line_no   AND   
      part_no    = @part_no   AND   
       lot_ser    = @lot_ser   AND   
      bin_no     = @bin_no    AND   
      [function] = @xfer_ship)  
 ELSE  
  SELECT @counter = (SELECT count(*)   
       FROM  tdc_dist_item_pick (nolock)  
       WHERE method     = '01'       AND  
           order_no   = @order_no  AND  
      order_ext  = @order_ext AND  
      line_no    = @line_no   AND   
      part_no    = @part_no   AND  
      [function] = @xfer_ship)   
   
 IF (@counter = 0)  
 BEGIN  
  EXEC @child_no = tdc_get_serialno  
   
  IF (@lb_tracking = 'Y')  
   INSERT tdc_dist_item_pick (method, order_no,  order_ext,  line_no,  part_no,  lot_ser,  bin_no,  quantity, child_serial_no, [function], type)   
         VALUES('01',  @order_no, @order_ext, @line_no, @part_no, @lot_ser, @bin_no, @qty,    @child_no,      @xfer_ship, 'O1')  
  ELSE  
   INSERT tdc_dist_item_pick (method, order_no,  order_ext,  line_no,  part_no,  quantity, child_serial_no, [function], type)   
         VALUES('01',  @order_no, @order_ext, @line_no, @part_no, @qty,     @child_no,        @xfer_ship, 'O1')  
   
  IF (@@ERROR <> 0)  
  BEGIN  
   IF (@@TRANCOUNT > 0) ROLLBACK  

	-- v1.3 Start
	IF (@xfer_ship = 'T')  
	BEGIN
		INSERT	dbo.cvo_transfer_pick_pack_log (log_date, xfer_no, log_message)
		SELECT	GETDATE(), @order_no, 'Error inserting tdc_dist_item_pick for @line_no ' + CAST(@line_no as varchar(20)) 
	END
	-- v1.3 End

   RETURN -101  
  END  
 END  
 ELSE  
 BEGIN  
  IF (@lb_tracking = 'Y')  
   UPDATE tdc_dist_item_pick  
   SET    quantity   = quantity + @qty  
   WHERE  method     = '01'       AND   
          order_no   = @order_no  AND  
          order_ext  = @order_ext AND  
          line_no    = @line_no   AND   
          part_no    = @part_no   AND   
          lot_ser    = @lot_ser   AND   
          bin_no     = @bin_no    AND   
          [function] = @xfer_ship  
  ELSE  
   UPDATE tdc_dist_item_pick  
   SET    quantity   = quantity + @qty  
   WHERE  method     = '01'       AND   
          order_no   = @order_no  AND  
          order_ext  = @order_ext AND  
          line_no    = @line_no   AND   
          part_no    = @part_no   AND      
          [function] = @xfer_ship  
   
  IF (@@ERROR <> 0)  
  BEGIN  
   IF (@@TRANCOUNT > 0) ROLLBACK  

	-- v1.3 Start
	IF (@xfer_ship = 'T')  
	BEGIN
		INSERT	dbo.cvo_transfer_pick_pack_log (log_date, xfer_no, log_message)
		SELECT	GETDATE(), @order_no, 'Error updating tdc_dist_item_pick for @line_no ' + CAST(@line_no as varchar(20)) 
	END
	-- v1.3 End

   RETURN -101  
  END  
 END  
END  
  
IF (@xfer_ship = 'T')  
 UPDATE TDC_xfers   
 SET    tdc_status = 'O1'   
 WHERE  xfer_no = @order_no  
ELSE  
 UPDATE TDC_order   
 SET    tdc_status = 'O1'   
 WHERE  order_no = @order_no AND order_ext = @order_ext  
  
IF (EXISTS (SELECT * FROM tdc_config (nolock) WHERE [function] = 'tote_bin' AND active = 'Y')) AND (LEN(@tote_bin) > 0)  
BEGIN  
 SELECT @counter = 0  
  
 IF (@lb_tracking = 'Y')  
  SELECT @counter = (SELECT count(*)   
       FROM  tdc_tote_bin_tbl (nolock)  
       WHERE location   = @loc       AND  
           order_no   = @order_no  AND  
      order_ext  = @order_ext AND  
      line_no    = @line_no   AND   
      part_no    = @part_no   AND   
       lot_ser    = @lot_ser   AND  
      bin_no     = @tote_bin  AND   
      orig_bin   = @bin_no    AND   
      order_type = @xfer_ship)  
 ELSE  
  SELECT @counter = (SELECT count(*)   
       FROM  tdc_tote_bin_tbl (nolock)  
       WHERE location   = @loc       AND  
           order_no   = @order_no  AND  
      order_ext  = @order_ext AND  
      line_no    = @line_no   AND   
      part_no    = @part_no   AND  
      bin_no     = @tote_bin  AND  
      order_type = @xfer_ship)  
  
 IF (@counter = 0)  
 BEGIN  
  IF (@lb_tracking = 'Y')  
   INSERT tdc_tote_bin_tbl (bin_no,     order_no,  order_ext,  location, line_no,  part_no,  lot_ser,  orig_bin,  quantity, tran_date,  who, order_type)  
       VALUES(@tote_bin, @order_no, @order_ext, @loc,     @line_no, @part_no, @lot_ser, @bin_no,   @qty,      getdate(), @who, @xfer_ship)  
  ELSE  
   INSERT tdc_tote_bin_tbl (bin_no,     order_no,  order_ext,  location, line_no,  part_no,  quantity, tran_date, who,  order_type)  
       VALUES(@tote_bin, @order_no, @order_ext, @loc,     @line_no, @part_no, @qty,      getdate(), @who, @xfer_ship)  
 END  
 ELSE  
 BEGIN    
  IF (@lb_tracking = 'Y')  
   UPDATE tdc_tote_bin_tbl  
   SET    quantity   = quantity + @qty  
   WHERE  bin_no     = @tote_bin  AND   
          order_no   = @order_no  AND  
          order_ext  = @order_ext AND   
          line_no    = @line_no   AND  
          lot_ser    = @lot_ser   AND   
          orig_bin   = @bin_no    AND   
          order_type = @xfer_ship       
  ELSE  
   UPDATE tdc_tote_bin_tbl  
   SET    quantity   = quantity + @qty  
   WHERE  bin_no     = @tote_bin  AND   
          order_no   = @order_no AND   
          order_ext  = @order_ext AND   
          line_no    = @line_no   AND            
          order_type = @xfer_ship    
 END  
  
 IF (@@ERROR <> 0)  
 BEGIN  
  IF (@@TRANCOUNT > 0) ROLLBACK  
  RETURN -101  
 END  
END  
  
IF (@xfer_ship = 'T')  
 SELECT @trans = 'XFERPICK'  
ELSE  
 SELECT @trans = 'STDOPICK'   
  
EXEC @return = tdc_update_queue_sp @queue_id, @qty, @line_no  
  
IF (@return < 0)  
BEGIN  
 IF (@@TRANCOUNT > 0) ROLLBACK  

	-- v1.3 Start
	IF (@xfer_ship = 'T')  
	BEGIN
		INSERT	dbo.cvo_transfer_pick_pack_log (log_date, xfer_no, log_message)
		SELECT	GETDATE(), @order_no, 'Error from tdc_update_queue_sp for @line_no ' + CAST(@line_no as varchar(20)) + ' and tran_id ' + CAST(@queue_id as varchar(20)) 
	END
	-- v1.3 End

 RETURN -101  
END  
  
IF EXISTS (SELECT * FROM tdc_inv_list (nolock) WHERE location = @loc AND part_no = @part_no AND vendor_sn IN ('I', 'O'))  
BEGIN  
 SELECT @mask_code = mask_code FROM tdc_inv_master (nolock) WHERE part_no = @part_no  
  
 DECLARE serial_cursor CURSOR FOR  
  SELECT serial_no, serial_raw  
    FROM #serial_no  
  
 OPEN serial_cursor  
 FETCH NEXT FROM serial_cursor INTO @serial_no, @serial_raw  
  
 WHILE @@FETCH_STATUS = 0  
 BEGIN  
  IF NOT EXISTS (SELECT * FROM tdc_serial_no_track (nolock) WHERE part_no = @part_no AND lot_ser = @lot_ser AND serial_no = @serial_no)  
  BEGIN  
   INSERT tdc_serial_no_track (location, transfer_location, part_no,  lot_ser,  mask_code, serial_no, serial_no_raw, IO_count, init_control_type, init_trans, init_tx_control_no, last_control_type, last_trans, last_tx_control_no, date_time, [User_id], ARBC_No)  
         VALUES( @loc,     @to_loc,   @part_no, @lot_ser, @mask_code,  @serial_no, @serial_raw,    2,      @xfer_ship,       @trans,     @order_no,  @xfer_ship,   @trans,     @order_no,    getdate(), @who,  NULL)  
  END  
  ELSE  
  BEGIN    
   UPDATE tdc_serial_no_track  
      SET IO_Count = IO_count + 1,  
          last_trans = @trans,   
          last_tx_control_no = @order_no,  
          last_control_type  = @xfer_ship,  
          date_time = getdate(),   
          [User_id] = @who,  
          transfer_location = @to_loc  
     FROM tdc_serial_no_track (nolock)  
    WHERE part_no   = @part_no   
      AND lot_ser   = @lot_ser   
      AND serial_no = @serial_no  
  END  
  
  IF (@@ERROR <> 0)  
  BEGIN  
   DEALLOCATE serial_cursor  
   IF (@@TRANCOUNT > 0) ROLLBACK  
   RETURN -101  
  END  
  
  FETCH NEXT FROM serial_cursor INTO @serial_no, @serial_raw  
 END  
   
 CLOSE serial_cursor  
 DEALLOCATE serial_cursor  
   
 IF @pallet != 0  
 BEGIN  
  EXEC tdc_pps_pack_sp 'N', @pallet, '', '', @who, '999', null, @order_no, @order_ext, @serial_no,  
    null, @line_no, @part_no, @kit_item, @loc, @lot_ser, @bin_no, 1, @err_msg OUTPUT  
   
  IF (@err_msg <> 'OK')  
  BEGIN  
   IF (@@TRANCOUNT > 0) ROLLBACK  
   RAISERROR(@err_msg, 16, -1)  
   RETURN -102  
  END  
 END  
END  
ELSE  
BEGIN  
 IF @pallet != 0  
 BEGIN  
  EXEC tdc_pps_pack_sp 'N', @pallet, '', '', @who, '999', null, @order_no, @order_ext, null,  
    null, @line_no, @part_no, @kit_item, @loc, @lot_ser, @bin_no, @qty, @err_msg OUTPUT  
  
  IF (@err_msg <> 'OK')  
  BEGIN  
   IF (@@TRANCOUNT > 0) ROLLBACK  
   RAISERROR(@err_msg, 16, -1)  
   RETURN -102  
  END  
 END  
END  
  
IF @pallet != 0  
BEGIN  
 SELECT @weight = weight_ea FROM inv_master (nolock) WHERE part_no = @part_no  
   
 UPDATE tdc_carton_tx  
    SET weight = weight + @qty * @weight  
  WHERE carton_no = @pallet  
    AND order_no = @order_no  
    AND order_ext = @order_ext  
END  

--BEGIN SED009 -- Order Pick to Auto Pack Out     
--JVM 09/01/2010 
--IF (@@TRANCOUNT > 0) 
IF (@@TRANCOUNT > 0) 
BEGIN
	COMMIT TRAN  
	-- START v1.1
	IF @xfer_ship = 'T'
	BEGIN
		-- v1.3 Start
		INSERT	dbo.cvo_transfer_pick_pack_log (log_date, xfer_no, log_message)
		SELECT	GETDATE(), @trans_type_no, 'Calling CVO_transfer_auto_pack_out_sp'
		-- v1.3 End

		EXEC CVO_transfer_auto_pack_out_sp @trans_type_no, @stationid
	END
	ELSE
	BEGIN
		EXEC CVO_auto_pack_out_sp @trans_type_no, @trans_type_ext, @stationid	
	END
	-- END v1.1
END
--END   SED009 -- Order Pick to Auto Pack Out       
  
RETURN 0  
GO
GRANT EXECUTE ON  [dbo].[tdc_queue_xfer_ship_pick_sp] TO [public]
GO
