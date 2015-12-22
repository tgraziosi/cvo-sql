SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- v1.0 CB 17/06/2011 - Create backorder if not allocated  
-- v1.1 CB 14/11/2011 - Stop the routine calling the allocation routine this is no dealt with elsewhere
-- v1.2 CB 16/11/2011 - Remove v1.1
-- v1.3 CB 22/11/2011 - Add back in v1.1
/*======================================================================*/  
/*   This procedure is called by a trigger on the      */  
/*      table.  The procedure takes @xlp (order_no), @xle (order_ext)   */  
/*  as inputs      */  
/*======================================================================*/  
CREATE PROC [dbo].[tdc_order_hdr_change] (@xlp int, @xle int)  
AS  
  
DECLARE @errmsg VARCHAR(255), @language VARCHAR(20), @status CHAR(1)  
  
SET NOCOUNT ON  
  
SELECT @language = @@language -- Get system language  
  
SELECT  @language =   
 CASE   
  WHEN @language = 'Español' THEN 'Spanish'  
  ELSE 'us_english'  
 END  

-- v1.0 IF this table exists then this has been fired by the backorder creation script which has been
-- called from WMS, we don't want this to fire the auto allocation as it causes problems  
IF OBJECT_ID('tempdb..#temp_so') IS NOT NULL
	RETURN 0

SELECT @status = status FROM orders (nolock) WHERE order_no = @xlp AND ext = @xle  
--
IF EXISTS (SELECT * FROM tdc_order (nolock) WHERE order_no = @xlp AND order_ext = @xle AND TDC_status = 'R1')  
 IF (@status < 'R')  
 BEGIN  
  IF @@TRANCOUNT > 0 ROLLBACK TRAN  
  -- Error message: Cannot update order %d-%d that has already been shipped  
  SELECT @errmsg = err_msg FROM tdc_lookup_error (nolock) WHERE language = @language AND module = 'SPR' AND trans = 'ORDHDRCHG' AND err_no = -103  
  RAISERROR(@errmsg, 16, -1, @xlp, @xle)  
  RETURN 0  
 END  
--
-- insert condition, do nothing  
IF (@status < 'P')  
BEGIN  
 IF NOT EXISTS(SELECT * FROM tdc_order (nolock) WHERE order_no = @xlp AND order_ext = @xle )  
 BEGIN  
  INSERT INTO tdc_order VALUES( @xlp, @xle, 'Q1', NULL)  
 END  
 
-- v1.1 Start
-- IF (@status = 'N')  
-- BEGIN  
--	EXEC tdc_order_after_save @xlp, @xle  
-- END  
-- v1.1 End
END  
ELSE IF (@status = 'R')  
BEGIN  
 IF(SYSTEM_USER <> 'tdcsql')   
 BEGIN  
 --  move these codes to tdc_order_list_change_sp.  so that users can change order price.....  
 -- IF EXISTS (SELECT * FROM tdc_ord_list_kit (nolock) WHERE order_no = @xlp AND order_ext = @xle AND kit_picked > 0 )  
 -- OR EXISTS (SELECT * FROM tdc_dist_item_pick (nolock) WHERE order_no = @xlp AND order_ext = @xle AND [function] = 'S')  
 -- BEGIN  
 --  IF (@@TRANCOUNT > 0) ROLLBACK TRAN  
   
 --  RAISERROR ('Order %d-%d is controlled by Supply Chain Execution system.', 16, -1, @xlp, @xle)  
 --  RETURN 0  
 -- END  
   
  IF EXISTS (SELECT * FROM tdc_soft_alloc_tbl (nolock) WHERE order_no = @xlp AND order_ext = @xle AND order_type = 'S')  
  OR EXISTS (SELECT * FROM tdc_pick_queue (nolock) WHERE trans_type_no = @xlp AND trans_type_ext = @xle AND trans = 'STDPICK')  
  BEGIN  
   IF (@@TRANCOUNT > 0) ROLLBACK TRAN  
   
   RAISERROR ('Order %d-%d must be unallocated', 16, -1, @xlp, @xle)  
   RETURN 0  
  END  
 END  
END  
ELSE IF (@status = 'V')   
BEGIN  
 IF EXISTS (SELECT * FROM ord_list     (nolock) WHERE order_no = @xlp AND order_ext = @xle AND shipped > 0)  
 OR EXISTS (SELECT * FROM ord_list_kit (nolock) WHERE order_no = @xlp AND order_ext = @xle AND shipped > 0)  
 BEGIN   
  IF @@TRANCOUNT > 0 ROLLBACK TRAN  
  
  -- Error message: Order %d-%d need to be unpicked before voided  
  SELECT @errmsg = err_msg FROM tdc_lookup_error (nolock) WHERE language = @language AND module = 'SPR' AND trans = 'ORDHDRCHG' AND err_no = -101  
  RAISERROR(@errmsg, 16, -1, @xlp, @xle)  
  RETURN 0   
 END  
       
 IF (EXISTS (SELECT * FROM tdc_soft_alloc_tbl (nolock) WHERE order_no = @xlp      AND order_ext      = @xle AND order_type = 'S')  
 OR  EXISTS (SELECT * FROM tdc_pick_queue     (nolock) WHERE trans_type_no = @xlp AND trans_type_ext = @xle AND trans      = 'STDPICK'))  
        --SCR 36574 052406 ToddR  
 --AND (SELECT active FROM tdc_config (NOLOCK) WHERE [function] = 'so_auto_allocate') != 'Y'   
 BEGIN  
  IF @@TRANCOUNT > 0 ROLLBACK TRAN  
  
  -- Error message: Must unallocate inventory before voiding order.  
  SELECT @errmsg = err_msg FROM tdc_lookup_error (nolock) WHERE language = @language AND module = 'SPR' AND trans = 'ORDHDRCHG' AND err_no = -102  
  RAISERROR(@errmsg, 16, -1, @xlp, @xle)  
  RETURN 0  
 END  
   
 IF EXISTS (SELECT * FROM orders (nolock) WHERE order_no = @xlp AND ext = @xle AND type = 'C')  
 BEGIN  
  DELETE FROM tdc_put_queue WHERE trans_type_no = @xlp AND trans_type_ext = @xle AND trans = 'CRPTWY'  
 END  
  
 DELETE FROM tdc_dist_item_list WHERE order_no = @xlp AND order_ext = @xle AND [function] = 'S'  
 DELETE FROM tdc_ord_list_kit WHERE order_no = @xlp AND order_ext = @xle   
 DELETE FROM tdc_order WHERE order_no = @xlp AND order_ext = @xle    
END  
ELSE IF (@status = 'T')  
BEGIN  
 IF NOT EXISTS (SELECT * FROM tdc_order (nolock) WHERE order_no = @xlp AND order_ext = @xle AND TDC_status = 'R1')  
 BEGIN  
  DELETE FROM tdc_dist_item_list WHERE order_no = @xlp AND order_ext = @xle AND [function] = 'S'  
  DELETE FROM tdc_ord_list_kit WHERE order_no = @xlp AND order_ext = @xle  
  DELETE FROM tdc_order WHERE order_no = @xlp AND order_ext = @xle  
  DELETE FROM tdc_soft_alloc_tbl WHERE order_no = @xlp AND order_ext = @xle   
 END  
END  
  
RETURN 0  
GO
GRANT EXECUTE ON  [dbo].[tdc_order_hdr_change] TO [public]
GO
