SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- v1.1 CT	06/08/2012 - When checking qty available in stock, include stock in bins marked as exclude from allocation (but not bins in config)
-- v1.2 CB 11/06/2013 - Issue #965 - Tax Calculation
-- v1.3 CB 12/05/2014 - Attempting to fix deadlock issue -  Remove statement as this replicates what the trigger on orders_all already does
-- v1.4 CB 19/06/2014 - Performance
-- v1.5 CB 21/04/2015 - Performance Changes
CREATE PROC [dbo].[tdc_adm_pick_ship]   
AS   
  
DECLARE @order_no int, @ext int, @line_no int, @recid int, @cnt int, @err int  
DECLARE @bin varchar(12), @lot varchar(25), @part_no varchar(30)  
DECLARE @location varchar(10), @msg varchar(255), @who varchar(50), @tracking_no varchar(30)  
DECLARE @qty decimal (20,8), @conv_factor decimal(20,8), @language varchar(10)  
DECLARE @date datetime, @lbtrack char(1), @status char(1), @part_type char(1)  
DECLARE @err_ret int, @in_stock decimal(20,8), @login_id varchar(50)  
   
SET NOCOUNT ON  
  
/* Find the first record */  
SELECT @recid = 0, @err = 0, @msg = 'Error message not found'  
SELECT @login_id = who, @who = login_id FROM #temp_who  
SELECT @language = Language FROM tdc_sec (nolock) WHERE userid = @login_id  
SELECT @language = ISNULL(@language, 'us_english')  
  
IF OBJECT_ID('tempdb..#adm_taxinfo') IS NOT NULL 
 TRUNCATE TABLE #adm_taxinfo  
  
IF OBJECT_ID('tempdb..#adm_taxtype') IS NOT NULL   
 TRUNCATE TABLE #adm_taxtype  
  
IF OBJECT_ID('tempdb..#adm_taxtyperec') IS NOT NULL   
 TRUNCATE TABLE #adm_taxtyperec  
  
IF OBJECT_ID('tempdb..#adm_taxcode') IS NOT NULL   
 TRUNCATE TABLE #adm_taxcode  
  
IF OBJECT_ID('tempdb..#cents') IS NOT NULL   
 TRUNCATE TABLE #cents  
  
/* Look at each record... */  
WHILE (@recid >= 0)  
BEGIN  
 SELECT @recid = ISNULL((SELECT MIN(row_id) FROM #adm_pick_ship WHERE row_id > @recid), -1)  
 IF @recid = -1 BREAK  
  
 SELECT @order_no = order_no, @ext = ext, @line_no = line_no, @part_no = part_no, @tracking_no = tracking_no,  
        @qty = ISNULL(qty, 0), @lot = lot_ser, @bin = bin_no, @location = location, @date = date_exp  
   FROM #adm_pick_ship   
  WHERE row_id = @recid  
  
 /* Make sure order number exists */  
 IF NOT EXISTS (SELECT * FROM ord_list (nolock) WHERE order_no = @order_no AND order_ext = @ext)  
 BEGIN  
  -- Error: Order %d-%d is not valid.  
  SELECT @msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_pick_ship' AND err_no = -101 AND language = @language  
  RAISERROR (@msg, 16, 1, @order_no, @ext)                             
  RETURN -101  
 END  
  
 --BEGIN SED009 -- AutoAllocation    
 --JVM 07/09/2010 
 --IF NOT EXISTS (SELECT * FROM orders (nolock) WHERE order_no = @order_no AND ext = @ext AND status IN ('N', 'P', 'Q'))   
 IF NOT EXISTS (SELECT * FROM orders (nolock) WHERE order_no = @order_no AND ext = @ext AND status IN ('N', 'P', 'Q', 'A'))  
 --END   SED009 -- AutoAllocation    
 BEGIN  
  -- Error: Order %d-%d must be new or printed.  
  SELECT @msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_pick_ship' AND err_no = -105 AND language = @language  
  RAISERROR (@msg, 16, 1, @order_no, @ext)               
  RETURN -105  
 END  
   
 /* Make sure part number is on order */  
 IF NOT EXISTS (SELECT * FROM ord_list (nolock) WHERE order_no = @order_no AND order_ext = @ext AND part_no = @part_no )  
 BEGIN  
  -- Error: Part number %s is not on order %d-%d.  
  SELECT @msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_pick_ship' AND err_no = -103 AND language = @language  
  RAISERROR (@msg, 16, 1, @part_no, @order_no, @ext)               
  RETURN -103  
 END  
  
 /* Make sure the part number belongs on the line item */  
 SELECT @conv_factor = conv_factor, @lbtrack = lb_tracking, @part_type = part_type   
   FROM ord_list (nolock)   
  WHERE order_no = @order_no AND order_ext = @ext  AND line_no = @line_no AND part_no = @part_no  
  
 IF (@@ROWCOUNT = 0)  
 BEGIN  
  -- Error: Item not on this line number %d  
  SELECT @msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_pick_ship' AND err_no = -106 AND language = @language  
  RAISERROR (@msg, 16, 1, @line_no)        
  RETURN -106  
 END  
  
 /* If quantity is negative (unpicking), don't unpick more than was picked */     
 IF EXISTS (SELECT * FROM ord_list (nolock) WHERE order_no = @order_no AND order_ext = @ext AND line_no = @line_no AND (shipped + (@qty/@conv_factor) < 0))  
 BEGIN  
  -- Error: Cannot unpick more than was picked.  
  SELECT @msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_pick_ship' AND err_no = -104 AND language = @language  
  RAISERROR (@msg, 16, 1)               
  RETURN -104  
 END  
  
 /* if this order has been picked from ADM we can not pick it */  
 IF (@qty > 0)  
 BEGIN  
  IF EXISTS (SELECT * FROM ord_list (nolock) WHERE order_no = @order_no AND order_ext = @ext AND shipped > 0)  
   IF NOT EXISTS (SELECT * FROM tdc_dist_item_pick (nolock) WHERE order_no = @order_no AND order_ext = @ext AND [function] = 'S')  
   BEGIN   
    -- UPDATE #adm_pick_ship SET err_msg = 'Order %d-%d is controlled by ERP'  
    SELECT @msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_pick_ship' AND err_no = -107 AND language = @language    
    RAISERROR (@msg, 16, 1, @order_no, @ext)  
    RETURN -107  
   END  
   
  IF EXISTS (SELECT * FROM ord_list_kit (nolock) WHERE order_no = @order_no AND order_ext = @ext AND shipped > 0)  
   IF NOT EXISTS (SELECT * FROM tdc_ord_list_kit (nolock) WHERE order_no = @order_no AND order_ext = @ext AND kit_picked > 0)  
   BEGIN   
    -- UPDATE #adm_pick_ship SET err_msg = 'Order %d-%d is controlled by ERP'  
    SELECT @msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_pick_ship' AND err_no = -107 AND language = @language    
    RAISERROR (@msg, 16, 1, @order_no, @ext)  
    RETURN -107  
   END  
 END  
  
 IF(@part_type != 'M') AND (@part_type != 'J') -- M for miscellaneous.  J for job production  
 BEGIN  
  /* Make sure part number exists */  
  SELECT @status = status FROM inv_master (nolock) WHERE part_no = @part_no  
   
  IF @@ROWCOUNT = 0  
  BEGIN  
   -- Error: Part number %s is not valid.  
   SELECT @msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_pick_ship' AND err_no = -102 AND language = @language  
   RAISERROR (@msg, 16, 1, @part_no)                             
   RETURN -102  
  END  
   
  -- For Auto Kit Part part type in ord_list table is 'P'.  Reset it to 'K' to avoid checking inventory  
  IF @status = 'K' SELECT @part_type = 'K'  
 END  
  
 /* Make sure there is enough of qty in inventory. regardless of lb tracked or not lb tracked part.  */  
 /* Reference: TRIGGER t602updinvs ON dbo.inv_sales Update. Item exists in lot bin stock before released QC. */  
 /* For custom kit, auto kit, miscellaneous, non quantity bearing item we do not check inventory   */  
 /* For auto kit item its qty or components qty can be negative        */  
 IF(@qty > 0)  
 BEGIN  
  -- START v1.1
  --SELECT @in_stock = ISNULL((SELECT in_stock FROM inventory (nolock) WHERE location = @location AND part_no = @part_no), 0)  
  SELECT @in_stock = ISNULL((SELECT in_stock_inc_non_allocating FROM cvo_inventory2 (nolock) WHERE location = @location AND part_no = @part_no), 0) -- v  
  -- END v1.1
  IF(@part_type = 'P')  
  BEGIN  
   IF (@qty > @in_stock)  
   BEGIN  
    -- Error: There is not enough of item %s in stock.  
    SELECT @msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_pick_ship' AND err_no = -108 AND language = @language  
    RAISERROR (@msg, 16, 1, @part_no)                     
    RETURN -108  
   END  
  END  
  
  IF(@part_type = 'K')  
  BEGIN  
   SELECT @in_stock = @qty - @in_stock  
     
   IF(@in_stock > 0)  
   BEGIN  
    IF EXISTS (SELECT *   
               FROM cvo_inventory2 i (NOLOCK), what_part p (nolock)  -- v1.5
             WHERE i.part_no = p.part_no   
                 AND p.asm_no = @part_no   
                 AND i.location = @location  
                 AND p.location in (@location, 'ALL')  
                 AND (@in_stock * p.qty) > i.in_stock)  
    BEGIN  
     -- Error: There is not enough of item %s in stock.  
     SELECT @msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_pick_ship' AND err_no = -108 AND language = @language  
     RAISERROR (@msg, 16, 1, @part_no)                     
     RETURN -108  
    END  
   END  
  END  
 END  
  
 /* For lot/bin tracked items... */  
 IF (@lbtrack = 'Y')   
 BEGIN  
  /* Make sure all the information is there */  
  IF (@lot IS NULL) OR (@bin IS NULL) OR (@date IS NULL)  
      BEGIN  
   -- Error: Lot/bin information is required for item %s.  
   SELECT @msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_pick_ship' AND err_no = -109 AND language = @language  
   RAISERROR (@msg, 16, 1, @part_no)                   
   RETURN -109  
  END  
  
  IF (@qty >= 0) -- pick  
  BEGIN  
   /* Make sure the item exists in the bin for picking */  
   IF NOT EXISTS ( SELECT * FROM lot_bin_stock (nolock) WHERE location = @location AND part_no = @part_no AND bin_no = @bin AND lot_ser = @lot)  
       BEGIN  
    -- Error: Specified item %s does not appear in lot/bin stock.  
    SELECT @msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_pick_ship' AND err_no = -110 AND language = @language  
    RAISERROR (@msg, 16, 1, @part_no)             
          RETURN -110  
   END  
   
   /* Make sure there is enough in the bin */  
   IF ((SELECT qty FROM lot_bin_stock (nolock) WHERE location = @location AND part_no = @part_no AND bin_no = @bin AND lot_ser = @lot) < @qty)  
       BEGIN  
    -- Error: There is not enough of item %s in stock.  
    SELECT @msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_pick_ship' AND err_no = -108 AND language = @language  
    RAISERROR (@msg, 16, 1, @part_no)     
          RETURN -108  
       END     
  END    
  ELSE -- unpick  
  BEGIN  
   IF NOT EXISTS ( SELECT * FROM lot_bin_ship (nolock) WHERE tran_no = @order_no AND tran_ext = @ext AND line_no = @line_no AND location = @location  AND part_no = @part_no AND bin_no = @bin AND lot_ser = @lot)  
       BEGIN  
    -- Error: Specified item %s has not been picked.  
    SELECT @msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_pick_ship' AND err_no = -112 AND language = @language  
    RAISERROR (@msg, 16, 1, @part_no)              
          RETURN -112  
   END  
  
   IF (( SELECT sum(qty) FROM lot_bin_ship (nolock) WHERE tran_no = @order_no AND tran_ext = @ext AND line_no = @line_no AND location = @location AND lot_ser = @lot AND bin_no = @bin ) < -@qty)  
       BEGIN  
    -- Error: Cannot unpick more than was picked.  
    SELECT @msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_pick_ship' AND err_no = -104 AND language = @language  
    RAISERROR (@msg, 16, 1)                                 
          RETURN -104  
   END  
  END           
 END  /* End if lb track */  
  
  
 UPDATE tdc_dist_item_list WITH (ROWLOCK) 
    SET shipped = shipped + @qty   
  WHERE order_no = @order_no AND order_ext = @ext AND line_no = @line_no AND [function] = 'S'   
  
 UPDATE ord_list WITH (ROWLOCK)  
     SET shipped = shipped + (@qty/@conv_factor), status = 'P'  
         WHERE order_no = @order_no AND order_ext = @ext AND line_no = @line_no  
  
 IF (@lbtrack = 'Y')   
 BEGIN    
  SELECT @cnt = COUNT(*)   
    FROM lot_bin_ship (nolock)   
    WHERE tran_no = @order_no AND tran_ext = @ext  AND line_no = @line_no AND bin_no = @bin AND lot_ser = @lot  
   
  IF (@cnt > 0)  
  BEGIN  
   /* ADM use part_no instead of line_no for the following update and delete statement ??? */  
   UPDATE lot_bin_ship   WITH (ROWLOCK)
       SET qty = qty + @qty, uom_qty = uom_qty + (@qty/@conv_factor)  
             WHERE tran_no = @order_no AND tran_ext = @ext  
                   AND line_no = @line_no AND location = @location AND bin_no = @bin AND lot_ser = @lot   
   
   /* Clear out records in lot_bin_ship table when quantities are 0. */  
   DELETE FROM lot_bin_ship WHERE tran_no = @order_no AND tran_ext = @ext AND line_no = @line_no AND qty <= 0  
  END  
  ELSE  
  BEGIN  
   INSERT lot_bin_ship WITH (ROWLOCK)(location, part_no, bin_no, lot_ser, tran_code, tran_no, tran_ext, date_tran, date_expires,  
          qty, direction, cost, uom, uom_qty, conv_factor, line_no, who, qc_flag)  
   SELECT @location, @part_no, @bin, @lot, 'P', @order_no, @ext, getdate(), @date,  
                        @qty, -1, cost, uom, (@qty/@conv_factor), conv_factor, @line_no, @who, qc_flag  
            FROM ord_list (NOLOCK)  
           WHERE order_no = @order_no AND order_ext = @ext AND line_no = @line_no   
  END   
 END /* End if lbtrack */          
END /* end while loop for recid */  
  
SELECT @status = 'P'   
  
-- v1.3 Start -  Comment Out
-- UPDATE ord_list   
-- SET status = @status  
-- WHERE order_no = @order_no AND order_ext = @ext AND status <> @status  
-- v1.3 End
  
UPDATE orders   WITH (ROWLOCK)
   SET status = @status, printed = @status, who_picked = @who, date_shipped = NULL, freight = tot_ord_freight  
 WHERE order_no = @order_no AND ext = @ext AND status <> @status  
  
  

-- v1.2 Start
/*
IF NOT EXISTS (SELECT 1 FROM tdc_config WHERE [function] = 'delay_so_update' AND active = 'Y')  
BEGIN  
 --EXEC dbo.fs_calculate_oetax_wrap @order_no, @ext  
 EXEC dbo.fs_calculate_oetax @order_no, @ext, @err_ret OUT  
 IF @err_ret <> 1   
 BEGIN  
  RAISERROR ('SP fs_calculate_oetax failed', 16, 1)  
  RETURN -111  
 END  
   
   
 EXEC dbo.fs_updordtots @order_no, @ext     
 IF @@ERROR <> 0   
 BEGIN  
  RAISERROR ('SP fs_updordtots failed', 16, 1)  
  RETURN -112  
 END  
END  
*/
-- v1.2 End  
  
RETURN 0  
GO
GRANT EXECUTE ON  [dbo].[tdc_adm_pick_ship] TO [public]
GO
