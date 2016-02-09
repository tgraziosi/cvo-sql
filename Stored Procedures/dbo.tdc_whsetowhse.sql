
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
  
/****************************************************************************************************************/  
/* Note : Not responsible if called from vb         */  
/* Since tdc core whsetowhse Xfer only takes one item at a time, line_no is hard-coded (line_no = 1)  */  
/****************************************************************************************************************/  
-- v1.1 CT 17/09/2012 - Allow moves from bins marked as non allocating

CREATE PROCEDURE [dbo].[tdc_whsetowhse]  
AS  
 SET NOCOUNT ON  
	SET ANSI_WARNINGS OFF -- tag 01/27/16
  
 TRUNCATE TABLE #adm_req_xfer  
 TRUNCATE TABLE #adm_pick_xfer  
 TRUNCATE TABLE #adm_ship_xfer  
 TRUNCATE TABLE #adm_rec_xfer  
   
/* Variable declaration */  
DECLARE @err int,  
 @from_bin varchar(12),  
 @to_bin varchar (12),  
 @from_loc varchar(10),  
 @to_loc varchar (10),  
 @lot varchar (25),  
 @item varchar(30),  
 @xfer_no int,  
 @qty decimal(20,8),  
 @uom char(2),  
 @conv_factor decimal(20,8),  
 @lb_track varchar(1),  
 @who_entered varchar (50),  
 @msg varchar(255),  
 @language varchar(10),  
 @serial_flag smallint,  
 @totalQty decimal(20,8)  
  
 /* Initialize variables */  
 SELECT  @from_loc = from_loc, @to_loc = to_loc, @from_bin = from_bin, @to_bin = to_bin, @item = part_no,  
  @lot = lot_ser, @qty = qty, @uom = uom, @conv_factor = conv_factor, @who_entered = who  
   FROM #tdc_whsetowhse  
  WHERE row_id = 1  
  
 SELECT @xfer_no = 0, @err = 0, @msg = 'Error message not found'  
 SELECT @lb_track = lb_tracking, @serial_flag = serial_flag FROM inv_master (nolock) WHERE part_no = @item  
 SELECT @language = ISNULL((SELECT Language FROM tdc_sec (nolock) WHERE userid = @who_entered), 'us_english')   
  
 IF NOT EXISTS( SELECT * FROM inventory (nolock) WHERE location = @to_loc AND part_no = @item)  
 BEGIN  
  -- Error: Part number %s does not exist at destination %s  
    SELECT @msg = err_msg   
    FROM tdc_lookup_error (nolock)   
   WHERE module = 'SPR' AND trans = 'WH2WH' AND err_no = -101 AND language = @language  
  RAISERROR (@msg, 16, 1, @item, @to_loc)  
  RETURN -101  
 END  
  
 SELECT @totalQty = @qty * @conv_factor  
  
 IF(@serial_flag = 1)   
 BEGIN  
  -- reset total quantity if item is serial tracked part  
  SELECT @qty = sum(qty), @totalQty = sum(qty) FROM #tdc_whsetowhse  
  IF EXISTS (SELECT *   
        FROM #tdc_whsetowhse   
       WHERE lot_ser NOT IN (SELECT lot_ser   
                 FROM lot_bin_stock (nolock)   
                WHERE location = @from_loc  
                  AND part_no = @item  
                  AND bin_no = @from_bin))  
  BEGIN  
   -- Error: There is not enough of item %s in that Lot/Bin.  
   RAISERROR ('Some serial lot does not exist in lot bin stock!', 16, 1)  
   RETURN -104  
  END  
 END  
 ELSE IF (@lb_track = 'Y')  
 BEGIN  
  IF EXISTS ( SELECT *   
         FROM lot_bin_stock (nolock)   
        WHERE location = @from_loc   
          AND part_no = @item  
          AND lot_ser = @lot   
          AND bin_no = @from_bin   
          AND qty < @totalQty)  
  BEGIN  
   -- Error: There is not enough of item %s in that Lot/Bin.  
     SELECT @msg = err_msg   
     FROM tdc_lookup_error (nolock)   
    WHERE module = 'SPR' AND trans = 'WH2WH' AND err_no = -104 AND language = @language  
   RAISERROR (@msg, 16, 1, @item)  
   RETURN -104  
  END  
 END  
 
-- START v1.1 
 IF EXISTS( SELECT * FROM inventory (nolock) WHERE location = @from_loc AND part_no = @item AND in_stock_inc_non_allocating < @totalQty)  
 -- IF EXISTS( SELECT * FROM inventory (nolock) WHERE location = @from_loc AND part_no = @item AND in_stock < @totalQty)  
-- END v1.1
 BEGIN  
  -- Error: There is not enough of item %s in inventory.  
    SELECT @msg = err_msg   
    FROM tdc_lookup_error (nolock)   
   WHERE module = 'SPR' AND trans = 'WH2WH' AND err_no = -103 AND language = @language  
  RAISERROR (@msg, 16, 1, @item)  
  RETURN -103  
 END  
   
 IF(@serial_flag = 1)  
  INSERT INTO #adm_req_xfer (xfer_no, to_loc, from_loc, line_no, part_no, qty, uom, conv_factor, who, err_msg)  
   VALUES(NULL, @to_loc, @from_loc, 1, @item, @qty/@conv_factor, @uom, @conv_factor, @who_entered, NULL)  
 ELSE  
  INSERT INTO #adm_req_xfer (xfer_no, to_loc, from_loc, line_no, part_no, qty, uom, conv_factor, who, err_msg)  
   VALUES(NULL, @to_loc, @from_loc, 1, @item, @qty, @uom, @conv_factor, @who_entered, NULL)  
  
BEGIN TRAN  
  
 EXEC @err = tdc_req_xfer  
  
 /* if request is not granted( has error), terminate stored procedure */  
 IF (@err < 0)  
 BEGIN  
      IF (@@TRANCOUNT > 0) ROLLBACK TRAN  
      RETURN @err  
 END  
  
 SELECT @xfer_no = (SELECT max(xfer_no) FROM xfers (nolock))  
  
 -- we use this flag 'W1' when we call tdc_pick_xfer.   
 UPDATE tdc_xfers SET tdc_status = 'W1' WHERE xfer_no = @xfer_no  
  
 IF(@serial_flag = 1)  
 BEGIN  
         INSERT INTO #adm_pick_xfer (xfer_no, line_no, from_loc, part_no, bin_no, lot_ser, date_exp, qty, who, err_msg)  
   SELECT @xfer_no, 1, @from_loc, @item, @from_bin, lbs.lot_ser, lbs.date_expires, 1, @who_entered, NULL  
     FROM lot_bin_stock lbs  
    WHERE lbs.location = @from_loc   
      AND lbs.part_no = @item   
      AND lbs.lot_ser IN (SELECT lot_ser FROM #tdc_whsetowhse)  
      AND lbs.bin_no = @from_bin  
 END  
 ELSE IF (@lb_track = 'Y')  
 BEGIN  
         INSERT INTO #adm_pick_xfer (xfer_no, line_no, from_loc, part_no, bin_no, lot_ser, date_exp, qty, who, err_msg)  
   SELECT @xfer_no, 1, @from_loc, @item, @from_bin, @lot, date_expires, @qty, @who_entered, NULL  
     FROM lot_bin_stock   
    WHERE location = @from_loc   
      AND part_no = @item   
      AND lot_ser = @lot   
      AND bin_no = @from_bin  
 END  
 ELSE  
 BEGIN  
  INSERT INTO #adm_pick_xfer (xfer_no, line_no, from_loc, part_no, bin_no, lot_ser, date_exp, qty, who, err_msg)  
   VALUES(@xfer_no, 1, @from_loc, @item, NULL, NULL, NULL, @qty, @who_entered, NULL)  
 END  
  
 SELECT @err = 0  
 EXEC @err = tdc_pick_xfer   
  
 /* Terminate if unable to pick */  
 IF (@err < 0)  
 BEGIN  
      IF (@@TRANCOUNT > 0) ROLLBACK TRAN  
      RETURN @err  
 END  
  
 INSERT INTO #adm_ship_xfer (xfer_no, part_no, bin_no, lot_ser, date_exp, qty, who, err_msg)  
  SELECT xfer_no, part_no, bin_no, lot_ser, date_exp, qty, @who_entered, NULL  
    FROM #adm_pick_xfer  
  
 SELECT @err = 0  
 EXEC @err = tdc_adm_ship_xfer  
  
 /* Terminate if unable to ship */  
 IF (@err < 0)  
 BEGIN  
      IF (@@TRANCOUNT > 0) ROLLBACK TRAN  
      RETURN @err  
 END  
  
 INSERT INTO #adm_rec_xfer (xfer_no, part_no, line_no, from_bin, lot_ser, to_bin, location, qty, who, err_msg)  
  SELECT xfer_no, part_no, 1, bin_no, lot_ser, @to_bin, @from_loc, qty, @who_entered, NULL  
    FROM #adm_ship_xfer  
  
 SELECT @err = 0  
 EXEC @err = tdc_rec_xfer  
  
 IF (@err < 0)  
 BEGIN  
      IF (@@TRANCOUNT > 0) ROLLBACK TRAN  
      RETURN @err  
 END  
  
UPDATE  #tdc_whsetowhse SET xfer_no = @xfer_no  
  
TRUNCATE TABLE #adm_req_xfer  
TRUNCATE TABLE #adm_pick_xfer  
TRUNCATE TABLE #adm_ship_xfer  
TRUNCATE TABLE #adm_rec_xfer  
  
IF @@TRANCOUNT > 0  
 COMMIT TRAN  
  
RETURN @xfer_no  
GO

GRANT EXECUTE ON  [dbo].[tdc_whsetowhse] TO [public]
GO
