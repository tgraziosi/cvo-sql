SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- v1.0	TM	9/8/2011	No Longer need email sent to salesrep

CREATE PROC [dbo].[tdc_rec_xfer]   
AS  
  
SET NOCOUNT ON  
  
DECLARE @recid int,   
 @xfer_no int,   
 @line_no int,  
 @from_bin varchar(12),  
 @to_bin varchar(12),  
 @lot varchar(25),  
        @part_no varchar(30),    
 @who varchar(50),  
 @loc varchar(10),  
 @qty decimal(20,8),  
 @bin_qty decimal(20,8),  
 @msg varchar(255),  
 @count int,  
 @language varchar(10)  
  
SELECT @recid = 0, @msg = 'Error message not found'  
SELECT @language = ISNULL((SELECT Language FROM tdc_sec (nolock) WHERE userid = (SELECT MIN(who) FROM #adm_rec_xfer)), 'us_english')  
  
SELECT @xfer_no = isnull(min(xfer_no), 0), @who = min(who) FROM #adm_rec_xfer  
  
SELECT @who = login_id FROM #temp_who   
  
/* Make sure transfer number exists */  
IF NOT EXISTS ( SELECT * FROM xfers (nolock) WHERE xfer_no = @xfer_no )  
BEGIN  
 -- Error: Transfer number %d is not valid.  
 SELECT @msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_rec_xfer' AND err_no = -101 AND language = @language  
 RAISERROR (@msg, 16, 1, @xfer_no)  
   RETURN -101  
END  
  
/* Make sure the transfer hasn't already been received */  
IF EXISTS (SELECT * FROM xfers (nolock) WHERE status >= 'S' AND xfer_no = @xfer_no)  
BEGIN  
 -- Error: Transfer %d has already been received.  
 SELECT @msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_rec_xfer' AND err_no = -102 AND language = @language  
 RAISERROR (@msg, 16, 1, @xfer_no)  
       RETURN -102  
END  
  
BEGIN TRAN  
  
/*moved updates to xfer and xfer_list after the updates to lot_bin_xfer to comply with the changes in eBO for lot serial costing KMH */  
  
/* Look at each record... */  
WHILE (@recid >= 0)  
BEGIN  
       SELECT @recid = ISNULL((SELECT min(row_id) FROM #adm_rec_xfer WHERE row_id > @recid), -1)  
       IF @recid = -1 BREAK          
  
 SELECT @part_no = part_no, @to_bin = to_bin, @lot = lot_ser, @loc = location, @line_no = line_no, @qty = qty  
   FROM #adm_rec_xfer   
  WHERE row_id = @recid  
  
 /* Make sure the part number exists */  
 IF NOT EXISTS (SELECT * FROM inv_master (nolock) WHERE part_no = @part_no)  
 OR NOT EXISTS (SELECT * FROM inv_list (nolock) WHERE location = @loc AND part_no = @part_no)  
 BEGIN  
  ROLLBACK TRAN  
  
  -- Error: The part number %s does not exist.  
   SELECT @msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_rec_xfer' AND err_no = -103 AND language = @language  
  RAISERROR (@msg, 16, 1, @part_no)  
                RETURN -103  
 END  
  
 /* Make sure the part number is on the transfer */  
 IF NOT EXISTS (SELECT * FROM xfer_list (nolock) WHERE part_no = @part_no and xfer_no = @xfer_no)  
 BEGIN  
  ROLLBACK TRAN  
  
  -- Error: The part number %s is not in the transfer.  
  SELECT @msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_rec_xfer' AND err_no = -104 AND language = @language  
  RAISERROR (@msg, 16, 1, @part_no)  
  RETURN -104  
 END  
  
 SELECT @count = count(*) FROM lot_bin_xfer (nolock) WHERE tran_no = @xfer_no AND line_no = @line_no AND part_no = @part_no AND lot_ser = @lot  
  
 IF (@count = 1)  
 BEGIN  
  UPDATE lot_bin_xfer   
     SET tran_code = 'S', date_tran = getdate(), to_bin = @to_bin, qty_received = @qty / conv_factor  
   WHERE tran_no = @xfer_no   
     AND part_no = @part_no   
     AND lot_ser = @lot   
     AND line_no = @line_no  
 END  
   
 ELSE IF (@count > 1)  
 BEGIN  
  DECLARE line_cursor CURSOR FOR   
   SELECT bin_no, qty   
     FROM lot_bin_xfer   
    WHERE tran_no = @xfer_no  
      AND line_no = @line_no  
         AND part_no = @part_no   
         AND lot_ser = @lot   
          
  OPEN line_cursor  
  FETCH NEXT FROM line_cursor INTO @from_bin, @bin_qty  
  
  WHILE (@@FETCH_STATUS = 0)  
  BEGIN  
   IF (@qty <= @bin_qty)  
   BEGIN  
    UPDATE lot_bin_xfer   
       SET tran_code = 'S', date_tran = getdate(), to_bin = @to_bin, qty_received = @qty / conv_factor  
     WHERE CURRENT OF line_cursor  
  
    SELECT @qty = 0  
   END  
   ELSE  
   BEGIN  
    IF (@count = 1)  
     SELECT @bin_qty = @qty  
    ELSE  
     SELECT @qty = @qty - @bin_qty  
  
    UPDATE lot_bin_xfer   
       SET tran_code = 'S', date_tran = getdate(), to_bin = @to_bin, qty_received = @bin_qty / conv_factor  
     WHERE CURRENT OF line_cursor  
   END  
     
   SELECT @count = @count - 1  
   FETCH NEXT FROM line_cursor INTO @from_bin, @bin_qty  
  END  
  DEALLOCATE line_cursor  
 END  
  
END -- End while loop  
  
SELECT @line_no = 0  
  
WHILE (@line_no >= 0)  
BEGIN  
       SELECT @line_no = ISNULL((SELECT min(line_no) FROM #adm_rec_xfer WHERE line_no > @line_no), -1)  
       IF @line_no = -1 BREAK          
  
 SELECT @qty = sum(qty) FROM #adm_rec_xfer WHERE line_no = @line_no  
  
/*moved updates to xfer and xfer_list after the updates to lot_bin_xfer to comply with the changes in eBO for lot serial costing KMH */  
 UPDATE xfer_list   
    SET amt_variance = shipped - (@qty/conv_factor), qty_rcvd = (@qty/conv_factor)   
  WHERE xfer_no = @xfer_no   
    AND line_no = @line_no   
END -- End while loop  
  
UPDATE xfers   
   SET status = 'S', who_recvd = @who, date_recvd = getdate()   
 WHERE xfer_no = @xfer_no   
   AND status = 'R'  
  
COMMIT TRAN  

--v1.0		EXEC CVO_send_xfer_notification_sp @xfer_no, 3		-- No Longer Needed
    
RETURN 0  


GO
GRANT EXECUTE ON  [dbo].[tdc_rec_xfer] TO [public]
GO
