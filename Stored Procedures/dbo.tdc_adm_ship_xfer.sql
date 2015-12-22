SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/************************************************************************************************/  
/* This procedure ships out a picked transfer to another location           */  
/* A negative quantity unpicks that much of the line item.                  */  
/* ERA70 : when shipped, the status is updated to 'R'      */  
/************************************************************************************************/  
CREATE PROC [dbo].[tdc_adm_ship_xfer]   
AS  
  
DECLARE @xfer_no int,   
 @recid int,   
 @bin varchar(12),   
 @lot varchar(25),  
 @part_no varchar(30),   
 @qty decimal(20,8),  
 @tot_shipped_for_part decimal(20,8),  
 @date datetime,   
 @status char(1),  
 @lb_tracking char(1),  
 @who varchar(50),  
 @msg varchar(255),  
 @line_no int,  
 @loc varchar(10),  
 @language varchar(10)  
  
/* Find the first record */  
SELECT @xfer_no = ISNULL((SELECT MIN(xfer_no) FROM #adm_ship_xfer), -1)  
SELECT @who = ISNULL((SELECT MIN(who) FROM #adm_ship_xfer), null)  
SELECT @part_no = '', @msg = 'Error message not found'  
SELECT @language = ISNULL((SELECT Language FROM tdc_sec (nolock) WHERE userid = @who), 'us_english')  
SELECT @who = login_id FROM #temp_who  
  
BEGIN TRAN  
  
/* Look at each record... */  
WHILE (@xfer_no >= 0)  
BEGIN  
 SELECT @part_no = (SELECT MIN(part_no) FROM #adm_ship_xfer WHERE xfer_no = @xfer_no AND part_no > @part_no)  
  
 IF @part_no IS NULL  
 BEGIN  
  /* Ship the transfer IF there were no errors */  
  IF NOT EXISTS (SELECT * FROM #adm_ship_xfer WHERE xfer_no = @xfer_no AND err_msg IS NOT NULL)  
  BEGIN  
   UPDATE xfers SET date_shipped = getdate(), status = 'R', who_shipped = @who WHERE xfer_no = @xfer_no  
   UPDATE xfer_list SET status = 'R' WHERE xfer_no = @xfer_no AND lb_tracking = 'Y'  
   UPDATE xfer_list SET status = 'R', to_bin = 'N/A' WHERE xfer_no = @xfer_no AND lb_tracking = 'N'   
    
   -- lot_bin_xfer table need to be updated individually. using one line with different lot and bin to test this  
   DECLARE line_cursor CURSOR FOR   
    SELECT line_no, bin_no, lot_ser  
      FROM lot_bin_xfer   
     WHERE tran_no = @xfer_no  
   OPEN line_cursor     
   FETCH NEXT FROM line_cursor INTO @line_no, @bin, @lot  
  
   WHILE (@@FETCH_STATUS = 0)  
   BEGIN  
    UPDATE lot_bin_xfer   
       SET tran_code = 'R', date_tran = getdate()  
     WHERE tran_no = @xfer_no  
       AND line_no = @line_no   
       AND bin_no = @bin   
       AND lot_ser = @lot  
          
    FETCH NEXT FROM line_cursor INTO @line_no, @bin, @lot  
   END  
   DEALLOCATE line_cursor 
 
  END  

  /* Get the next transfer number */  
  SELECT @xfer_no = ISNULL((SELECT MIN(xfer_no) FROM #adm_ship_xfer WHERE xfer_no > @xfer_no), -1)  
  SELECT @part_no = ''  
  SELECT @who = ISNULL((SELECT MIN(who) FROM #adm_ship_xfer WHERE xfer_no > @xfer_no), null)  
 END  
 /* if there are more than one record in the table */  
 ELSE  
 BEGIN  
  SELECT @lb_tracking = lb_tracking FROM inv_master (nolock) WHERE part_no = @part_no  
  
  /* If lb_tracked... */  
  IF (@lb_tracking = 'Y')  
  BEGIN  
   SELECT @recid = 0  
  
   WHILE (@recid >= 0)  
   BEGIN  
    SELECT @recid = ISNULL((SELECT MIN(row_id)   
         FROM #adm_ship_xfer   
        WHERE xfer_no = @xfer_no AND part_no = @part_no AND row_id > @recid), -1)     
    IF @recid = -1 BREAK  
  
    SELECT @lot = lot_ser, @bin = bin_no, @date = date_exp  
      FROM #adm_ship_xfer   
     WHERE row_id = @recid  
      
    SELECT @status = status FROM xfers (nolock) WHERE xfer_no = @xfer_no  
  
    /* Verify part_no */  
    IF NOT EXISTS (SELECT * FROM lot_bin_xfer (nolock) WHERE tran_no = @xfer_no AND part_no = @part_no)  
    BEGIN  
     ROLLBACK TRAN  
  
     -- Message: Item %s is not on the transfer.  
       SELECT @msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_ship_xfer' AND err_no = -101 AND language = @language  
     RAISERROR (@msg, 16, 1, @part_no)       
     RETURN -101  
    END  
  
    DECLARE get_line CURSOR FOR  
     SELECT line_no  
       FROM xfer_list  
      WHERE xfer_no = @xfer_no AND part_no = @part_no  
  
    OPEN get_line  
  
    FETCH NEXT FROM get_line INTO @line_no  
    SELECT @tot_shipped_for_part = 0  
    WHILE (@@FETCH_STATUS = 0)   
    BEGIN  
     SELECT @tot_shipped_for_part = @tot_shipped_for_part + ( SELECT ISNULL(sum(qty), 0) FROM lot_bin_xfer WHERE tran_no = @xfer_no AND line_no = @line_no )  
     FETCH NEXT FROM get_line INTO @line_no  
    END  
  
    DEALLOCATE get_line  
  
    /* Verify qty */  
    IF (SELECT SUM(qty) FROM #adm_ship_xfer WHERE xfer_no = @xfer_no AND part_no = @part_no) <> @tot_shipped_for_part  
    BEGIN  

	
     ROLLBACK TRAN  
  
     -- Message: The shipping quantity must match the picked quantity.  
       SELECT @msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_ship_xfer' AND err_no = -102 AND language = @language  
     RAISERROR (@msg, 16, 1)       
     RETURN -102  
    END  
  
    /* Verify bin */  
    IF NOT EXISTS (SELECT * FROM lot_bin_xfer (nolock) WHERE tran_no = @xfer_no AND part_no = @part_no AND lot_ser = @lot AND bin_no = @bin)  
    BEGIN  
     ROLLBACK TRAN  
  
     -- Message: The bin number %s does not match the picked bin number.  
       SELECT @msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_ship_xfer' AND err_no = -104 AND language = @language  
     RAISERROR (@msg, 16, 1, @bin)  
     RETURN -104  
    END  
  
    /* Verify Date Expires */  
    IF NOT EXISTS (SELECT *   
       FROM lot_bin_xfer (nolock)   
      WHERE tran_no = @xfer_no   
        AND part_no = @part_no   
        AND lot_ser = @lot   
        AND bin_no = @bin  
        AND datepart(dy,date_expires) = datepart(dy,@date)  
        AND datepart(yy,date_expires) = datepart(yy,@date))  
    BEGIN  
     ROLLBACK TRAN  
  
     -- Message: The expiration date does not match the picked expiration date.  
       SELECT @msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_ship_xfer' AND err_no = -105 AND language = @language  
     RAISERROR (@msg, 16, 1)       
     RETURN -105  
    END  
  
    /* Verify status (P or Q) */  
    IF @status <> 'Q'  
    BEGIN  
     ROLLBACK TRAN  
  
     -- Message: The item must be picked before shipping.  
       SELECT @msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_ship_xfer' AND err_no = -106 AND language = @language  
     RAISERROR (@msg, 16, 1)  
     RETURN -106  
    END  
    /* It was good */  
   END  
  END  
  /* NON L / B Tracked Part */  
  ELSE  
  BEGIN  
   /* Verify part_no */  
   IF NOT EXISTS (SELECT * FROM xfer_list (nolock) WHERE xfer_no = @xfer_no AND part_no = @part_no)  
   BEGIN  
    ROLLBACK TRAN  
  
    -- Message: The item %s is not on the transfer.  
      SELECT @msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_ship_xfer' AND err_no = -101 AND language = @language  
    RAISERROR (@msg, 16, 1, @part_no)  
    RETURN -101  
   END  
  
   /* Verify qty */  
   IF NOT (SELECT SUM(shipped*conv_factor) FROM xfer_list WHERE xfer_no = @xfer_no AND part_no = @part_no)  
        = (SELECT SUM(qty) FROM #adm_ship_xfer WHERE xfer_no = @xfer_no AND part_no = @part_no)  
   BEGIN  
    ROLLBACK TRAN  
  
    -- Message: The shipping quantity must match the picked quantity  
      SELECT @msg = err_msg FROM tdc_lookup_error (nolock)WHERE module = 'SPR' AND trans = 'tdc_ship_xfer' AND err_no = -102 AND language = @language  
    RAISERROR (@msg, 16, 1)  
    RETURN -102  
   END  
  
   /* Verify status (P or Q) */  
   IF NOT EXISTS (SELECT * FROM xfer_list (nolock) WHERE xfer_no = @xfer_no AND part_no = @part_no AND status = 'Q')  
   BEGIN     
    ROLLBACK TRAN  
   
    -- Message: The item must be picked before shipping.  
      SELECT @msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_ship_xfer' AND err_no = -106 AND language = @language  
    RAISERROR (@msg, 16, 1)      
    RETURN -106  
   END  
   /* It was good */  
  END  
 END  
END  
  
COMMIT TRAN  
  
RETURN 0  
GO
GRANT EXECUTE ON  [dbo].[tdc_adm_ship_xfer] TO [public]
GO
