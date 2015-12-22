SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
  
/*======================================================================*/  
/*   This procedure is called by a trigger on the      */  
/*      xfers table.  The procedure takes @xfer_no (xfer_no) as an input*/        
/*======================================================================*/  
-- v1.1 CT 08/11/2012 - Allow transfers to be autoshipped via SQL job

CREATE PROC [dbo].[tdc_xfer_hdr_change] (@xfer_no int)  
AS  
  
DECLARE @errmsg  VARCHAR(255), @language VARCHAR(20),  
 @Adr1  VARCHAR(100), @Adr2  VARCHAR(100),  
 @Adr3  VARCHAR(100), @Adr4  VARCHAR(100),  
 @Adr5  VARCHAR(100), @City  VARCHAR(40),  
 @State   VARCHAR(40),   @Zip  VARCHAR(10),  
 @Country VARCHAR(40),  @status  CHAR(1),
 @valid_shipper SMALLINT -- v1.1   
  
SET NOCOUNT ON  
  
SELECT @language = @@language -- Get system language  
  
SELECT  @language =   
 CASE   
  WHEN @language = 'Español' THEN 'Spanish'  
  ELSE 'us_english'  
 END  
  
-- START v1.1 - check for existence of #temp_who table
IF (SELECT OBJECT_ID('tempdb..#temp_who')) IS NOT NULL 
BEGIN
	SET @valid_shipper = 1
END
ELSE
BEGIN
	SET @valid_shipper = 0
END
-- END v1.1


SELECT @status = status FROM xfers (nolock) WHERE xfer_no = @xfer_no  
  
-- insert condition, do nothing  
IF (@status = 'N')  
BEGIN  
 IF NOT EXISTS( SELECT * FROM tdc_xfers (nolock) WHERE xfer_no = @xfer_no )  
 BEGIN  
  SELECT @Adr1 = to_loc_addr1, @Adr2 = to_loc_addr2, @Adr3 = to_loc_addr3,  
         @Adr4 = to_loc_addr4, @Adr5 = to_loc_addr5  
    FROM xfers (NOLOCK)  
   WHERE xfer_no = @xfer_no  
  
  INSERT INTO tdc_xfers (xfer_no, tdc_status, total_cartons, city, state, zip, country)   
    VALUES(@xfer_no, 'Q1', NULL, @City, @State, @Zip, @Country)   
 END  
 RETURN 0  
END  
  
IF (@status = 'V')   
BEGIN  
 IF EXISTS (SELECT * FROM tdc_soft_alloc_tbl (nolock) WHERE order_no = @xfer_no AND order_ext = 0 AND order_type = 'T')  
 OR EXISTS (SELECT * FROM tdc_pick_queue (nolock) WHERE trans_type_no = @xfer_no AND trans = 'XFERPICK')  
 BEGIN   
  IF @@TRANCOUNT > 0 ROLLBACK TRAN  
  
  RAISERROR('Must unallocate inventory before voiding order %d.', 16, -1, @xfer_no)  
  RETURN 0    
 END  
  
 DELETE FROM tdc_xfers WHERE xfer_no = @xfer_no  
 DELETE FROM tdc_dist_item_list WHERE order_no = @xfer_no AND [function] = 'T'  
  
 RETURN 0  
END  
  
IF (@status > 'Q')  
BEGIN  
 -- warehouse to warehouse move  
 IF EXISTS (SELECT * FROM tdc_xfers (nolock) WHERE xfer_no = @xfer_no AND tdc_status = 'W1')  
 BEGIN  
  INSERT INTO tdc_bkp_dist_item_list  
   SELECT *, 'C', GETDATE()   
     FROM tdc_dist_item_list (nolock)  
    WHERE order_no = @xfer_no   
      AND [function] = 'T'    
  
  DELETE FROM tdc_dist_item_list WHERE order_no = @xfer_no AND [function] = 'T'  
  RETURN 0  
 END  
  
 IF NOT EXISTS (SELECT * FROM tdc_xfers (nolock) WHERE xfer_no = @xfer_no AND tdc_status = 'R1')  
 BEGIN  
  IF NOT EXISTS (SELECT * FROM tdc_dist_item_pick (nolock) WHERE order_no = @xfer_no AND order_ext = 0 AND [function] = 'T')  
  BEGIN  
   DELETE FROM tdc_xfers WHERE xfer_no = @xfer_no  
   DELETE FROM tdc_dist_item_list WHERE order_no = @xfer_no AND [function] = 'T'  
   RETURN 0  
  END  
  
  UPDATE tdc_xfers SET tdc_status = 'R1' WHERE xfer_no = @xfer_no  
 END  
  
 -- START v1.1
 IF(SYSTEM_USER <> 'tdcsql') AND @valid_shipper = 0
 -- IF(SYSTEM_USER <> 'tdcsql')
 -- END v1.1
 BEGIN  
  
  IF EXISTS (SELECT * FROM tdc_dist_item_pick (nolock) WHERE order_no = @xfer_no AND order_ext = 0 AND [function] = 'T')  
  BEGIN  
   IF @@TRANCOUNT > 0 ROLLBACK TRAN  
   
   RAISERROR('Order %d is controlled by Supply Chain Execution system.', 16, 1, @xfer_no)  
   RETURN 0   
  END  
  
  IF EXISTS (SELECT * FROM tdc_soft_alloc_tbl (nolock) WHERE order_no = @xfer_no AND order_ext = 0 AND order_type = 'T')  
  OR EXISTS (SELECT * FROM tdc_pick_queue (nolock) WHERE trans_type_no = @xfer_no AND trans_type_ext = 0 AND trans = 'XFERPICK')  
  BEGIN  
   IF @@TRANCOUNT > 0 ROLLBACK TRAN  
   
   RAISERROR('Order %d must be unallocated', 16, 1, @xfer_no)  
   RETURN 0   
  END  
 END  
END  
  
RETURN 0  
GO
GRANT EXECUTE ON  [dbo].[tdc_xfer_hdr_change] TO [public]
GO
