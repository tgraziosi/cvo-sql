SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
  
/*======================================================================*/  
/*   This procedure is called by a trigger on the      */  
/*      ord_list table upon being inserted, updated, and deleted.  The  */  
/* procedure takes @tran_no, @tran_ext, @tran_line, @part, @qty  */  
/* and inserts order information into the tdc_dist_item_list       */  
/*======================================================================*/  
-- v10.0 CB 22/05/2012 - Soft Allocation  
-- v10.1 CT 18/10/2012 - Allow auto receiving of credit returns
CREATE PROC [dbo].[tdc_order_list_change] (  
  @tran_no INT,   
  @tran_ext INT,   
  @tran_line INT,   
  @part VARCHAR(30),   
  @qty DECIMAL(20,8),  
  @stat VARCHAR(10)  
)  
AS  
  
DECLARE @errmsg VARCHAR(255),   
 @language VARCHAR(20),  
 @ordered DECIMAL(20,8),   
 @shipped DECIMAL(20,8),  
 @tdc_ordered DECIMAL(20,8),   
 @tdc_shipped DECIMAL(20,8),  
 @tdc_loc VARCHAR(10),  
 @location VARCHAR(10),   
 @tdc_part VARCHAR(30),  
 @status CHAR(1),  
 @type CHAR(1)  
  
SET NOCOUNT ON  
  
SELECT @language = @@language -- Get system language  
  
SELECT  @language =   
 CASE   
  WHEN @language = 'Español' THEN 'Spanish'  
  ELSE 'us_english'  
 END  
  
IF(@tran_ext = 0)  
BEGIN  
 -- blanket order for extension zero  
 -- multiple ship to order for extension zero  
 IF EXISTS (SELECT * FROM orders (nolock) WHERE order_no = @tran_no AND ext = 0 AND (blanket = 'Y' OR multiple_flag = 'Y'))  
  RETURN 0       
END  
   
--=====================================================================================  
-- Delete condition  
IF( @stat = 'ORDL_DEL')   
BEGIN  
 IF EXISTS (SELECT * FROM tdc_soft_alloc_tbl (nolock) WHERE order_no = @tran_no AND order_ext = @tran_ext AND order_type = 'S' AND line_no = @tran_line)  
        --SCR 36574 052406 ToddR  
 --AND (SELECT active FROM tdc_config (NOLOCK) WHERE [function] = 'so_auto_allocate') != 'Y'   
 BEGIN  
	-- v10.0 If there is a soft allocation delete then allow the delete to proceed
	IF NOT EXISTS (SELECT 1 FROM dbo.cvo_soft_alloc_det (NOLOCK) WHERE order_no = @tran_no AND order_ext = @tran_ext 
					AND line_no = @tran_line AND status > -1)
					--AND line_no = @tran_line AND deleted = 1 AND status > -1)
	BEGIN
		IF @@TRANCOUNT > 0 ROLLBACK TRAN  
	
	  -- Error message: Must unallocate inventory before delete item %s.    
	  SELECT @errmsg = err_msg FROM tdc_lookup_error (nolock) WHERE language = @language AND module = 'SPR' AND trans = 'ORDLISTCHG' AND err_no = -101  
	  RAISERROR(@errmsg, 16, -1, @part)  
	  RETURN 0  
	END
 END  
  
 DELETE FROM tdc_dist_item_list   
 WHERE order_no = @tran_no AND order_ext = @tran_ext AND line_no = @tran_line AND [function] = 'S'  
  
 RETURN 0   
END  
  
--========================================================================================  
  
SELECT @type = type FROM orders (nolock) WHERE order_no = @tran_no AND ext = @tran_ext  
  
IF (@type = 'C')  
BEGIN  
 SELECT @ordered = cr_ordered * conv_factor, @shipped = cr_shipped * conv_factor, @status = status, @location = location  
   FROM ord_list (nolock)  
  WHERE order_no = @tran_no AND order_ext = @tran_ext AND line_no = @tran_line  
  
 IF(@status >= 'S')  
 BEGIN  
  -- ?? tdc_inventory_update_sp  
  UPDATE tdc_serial_no_track  
     SET last_control_type = '0', date_time = getdate()  
   WHERE last_trans = 'CRRETN' AND last_control_type = 'H' AND last_tx_control_no = @tran_no  
  
  RETURN 0  
 END  
END  
ELSE  
BEGIN  
 SELECT @ordered = ordered * conv_factor, @shipped = shipped * conv_factor, @status = status, @location = location  
   FROM ord_list (nolock)  
  WHERE order_no = @tran_no AND order_ext = @tran_ext AND line_no = @tran_line  
END  
  
----------------------------------------------------------------------------------------------------  
  
-- Insert condition  
IF( @stat = 'ORDL_INS' )  
BEGIN  
 -- should not happen.  
 IF EXISTS (SELECT * FROM ord_list (nolock) WHERE order_no = @tran_no AND order_ext = @tran_ext AND line_no = @tran_line AND lb_tracking = 'Y' AND part_type = 'V')  
 BEGIN  
  RAISERROR 84903 'A lot bin tracked part with non-quantity bearing type has been found on this order!'  
  ROLLBACK TRAN  
 END   
  
 IF (@status NOT IN ('P', 'Q'))  
 BEGIN  
  IF EXISTS (SELECT * FROM tdc_dist_item_pick (nolock) WHERE order_no = @tran_no AND order_ext = @tran_ext AND [function] = 'S')  
  OR EXISTS (SELECT * FROM ord_list_kit (nolock) WHERE order_no = @tran_no AND order_ext = @tran_ext AND shipped > 0 )  
  BEGIN  
   IF (@@TRANCOUNT > 0) ROLLBACK TRAN  
   RAISERROR ('Order %d-%d is controlled by Supply Chain Execution system.', 16, -1, @tran_no, @tran_ext)  
   RETURN 0  
  END  
 END  
  
 -- We insert a credit return order into tdc_order table here   
 -- because for some reasons the sp tdc_order_hr_change does not be called  
 -- we use it to prevent users from changing the order data  
 -- which had been received in with a PCS pallet  
 IF(@status < 'R') -- price hold, user hold and credit return order  
 BEGIN  
  IF NOT EXISTS (SELECT * FROM tdc_order (nolock) WHERE order_no = @tran_no AND order_ext = @tran_ext)  
   INSERT INTO tdc_order VALUES(@tran_no, @tran_ext, 'Q1', 1)  
  
  IF NOT EXISTS (SELECT *   
     FROM tdc_dist_item_list (nolock)   
    WHERE order_no = @tran_no   
      AND order_ext = @tran_ext   
      AND line_no = @tran_line   
      AND [function] = 'S')  
  BEGIN    
   IF (@type = 'C')  
   BEGIN  
    INSERT INTO tdc_dist_item_list    
    SELECT @tran_no, @tran_ext, @tran_line, part_no, cr_ordered * conv_factor, 0, 'S'  
      FROM ord_list (nolock)  
     WHERE order_no = @tran_no AND order_ext = @tran_ext AND line_no = @tran_line   
   END  
   ELSE  
   BEGIN      
    INSERT INTO tdc_dist_item_list    
    SELECT @tran_no, @tran_ext, @tran_line, part_no, ordered * conv_factor, 0, 'S'  
      FROM ord_list (nolock)  
     WHERE order_no = @tran_no AND order_ext = @tran_ext AND line_no = @tran_line   
   END  
  END  
 END  
  
 RETURN 0  
END  
  
-----------------------------------------------------------------------------------------  
IF EXISTS (SELECT * FROM tdc_dist_item_list (nolock) WHERE order_no = @tran_no AND order_ext = @tran_ext AND line_no = @tran_line AND [function] = 'S')  
BEGIN   
 SELECT @tdc_ordered = quantity, @tdc_shipped = shipped, @tdc_part = part_no  
   FROM tdc_dist_item_list (nolock)  
  WHERE order_no = @tran_no   
    AND order_ext = @tran_ext   
    AND line_no = @tran_line   
    AND [function] = 'S'  
END  
ELSE  
BEGIN  
 SELECT @tdc_ordered = quantity, @tdc_shipped = shipped, @tdc_part = part_no  
   FROM tdc_bkp_dist_item_list (nolock)  
  WHERE order_no = @tran_no   
    AND order_ext = @tran_ext   
    AND line_no = @tran_line   
    AND [function] = 'S'  
END  
--========================================================================================  
  
-- Update condition  
IF( @stat = 'ORDL_UPD' )  
BEGIN  
 IF NOT EXISTS (SELECT * FROM tdc_order (nolock) WHERE order_no = @tran_no AND order_ext = @tran_ext)  
  RETURN 0  
  
 IF( @ordered = 0 )   
 BEGIN  
	-- v10.0 If there is a soft allocation delete then allow the update to zero 
	IF NOT EXISTS (SELECT 1 FROM dbo.cvo_soft_alloc_det (NOLOCK) WHERE order_no = @tran_no AND order_ext = @tran_ext 
					AND line_no = @tran_line AND deleted = 1 AND status > -1)
	BEGIN
		IF (@@TRANCOUNT > 0) ROLLBACK TRAN  
  
	  -- Error message: Ordered quantity cannot be zero  
	  SELECT @errmsg = err_msg FROM tdc_lookup_error (nolock) WHERE language = @language AND module = 'SPR' AND trans = 'ORDLISTCHG' AND err_no = -103  
	  RAISERROR (@errmsg, 16, -1)  
	  RETURN 0
	END
    
 END  
  
 IF EXISTS (SELECT * FROM ord_list (nolock) WHERE order_no = @tran_no AND order_ext = @tran_ext AND line_no = @tran_line AND create_po_flag = 1)  
 BEGIN  
  DELETE FROM tdc_soft_alloc_tbl WHERE order_no = @tran_no AND order_ext = @tran_ext AND line_no = @tran_line AND order_type = 'S'  
  DELETE FROM tdc_pick_queue WHERE trans_type_no = @tran_no AND trans_type_ext = @tran_ext AND line_no = @tran_line AND trans = 'STDPICK'  
 END  
  
 IF(SYSTEM_USER <> 'tdcsql')   
 BEGIN  
  -- START v10.2
  IF (select object_id('tempdb..#temp_who')) IS NULL	
  BEGIN	
	  IF EXISTS (SELECT * FROM orders (nolock) WHERE order_no = @tran_no AND ext = @tran_ext AND type = 'C' AND status = 'R')  
	  BEGIN  
	   IF EXISTS (SELECT * FROM ord_list (nolock) WHERE order_no = @tran_no AND order_ext = @tran_ext AND part_type = 'P' AND lb_tracking = 'Y')  
	   BEGIN  
		IF (@@TRANCOUNT > 0) ROLLBACK TRAN  
	   
		RAISERROR ('Order %d-%d must be received from Supply Chain Execution system', 16, -1, @tran_no, @tran_ext)  
		RETURN 0  
	   END  
	  END
  END 
  -- END v10.2  
  
  IF ( @tdc_shipped != @shipped ) OR ( @status IN ('V') )  
  BEGIN  
   IF EXISTS (SELECT * FROM tdc_ord_list_kit (nolock) WHERE order_no = @tran_no AND order_ext = @tran_ext AND kit_picked > 0 )  
   OR EXISTS (SELECT * FROM tdc_dist_item_pick (nolock) WHERE order_no = @tran_no AND order_ext = @tran_ext AND [function] = 'S')  
   BEGIN  
    IF (@@TRANCOUNT > 0) ROLLBACK TRAN  
  
    RAISERROR ('Order %d-%d is controlled by Supply Chain Execution system.', 16, -1, @tran_no, @tran_ext)  
    RETURN 0  
   END  
  
   IF (EXISTS (SELECT * FROM tdc_soft_alloc_tbl (nolock) WHERE order_no      = @tran_no AND order_ext      = @tran_ext AND order_type = 'S' and location < '100')  
    OR EXISTS (SELECT * FROM tdc_pick_queue     (nolock) WHERE trans_type_no = @tran_no AND trans_type_ext = @tran_ext AND trans      = 'STDPICK' and location < '100'))  
          --SCR 36574 052406 ToddR  
          --AND (SELECT active FROM tdc_config (NOLOCK) WHERE [function] = 'so_auto_allocate') != 'Y'   
   BEGIN  
    IF (@@TRANCOUNT > 0) ROLLBACK TRAN  
  
    RAISERROR ('Order %d-%d must be unallocated', 16, -1, @tran_no, @tran_ext)  
    RETURN 0  
   END  
  END  
  
  IF (@status NOT IN ('P', 'Q'))  
  BEGIN  
   IF EXISTS (SELECT * FROM tdc_order (nolock) WHERE order_no = @tran_no AND order_ext = @tran_ext AND TDC_status = 'R1')  
   BEGIN  
    IF(@status = 'R')  
    BEGIN         
     IF (@tdc_shipped != @shipped) OR (@ordered != @tdc_ordered)  
     BEGIN  
      IF (@@TRANCOUNT > 0) ROLLBACK TRAN  
  
      RAISERROR ('Order %d-%d is controlled by Supply Chain Execution system.', 16, -1, @tran_no, @tran_ext)  
      RETURN 0   
     END  
    END  
    ELSE IF(@status < 'R')  
    BEGIN  
     IF (@@TRANCOUNT > 0) ROLLBACK TRAN  
  
     -- Error message: Cannot update an order that has already been shipped  
     SELECT @errmsg = err_msg FROM tdc_lookup_error (nolock) WHERE language = @language AND module = 'SPR' AND trans = 'ORDLISTCHG' AND err_no = -104  
     RAISERROR (@errmsg, 16, -1)  
     RETURN 0  
    END  
    ELSE  
    BEGIN  
     IF EXISTS (SELECT * FROM tdc_carton_tx (nolock) WHERE order_no = @tran_no AND order_ext = @tran_ext AND order_type = 'S')  
      RETURN 0  
    END      
   END  
   ELSE  
   BEGIN  
    -- if user try to ship an order that was picked through eWarehouse system  
    IF(@status = 'R')  
    BEGIN  
     --1430321ESC Jim On 12/06/07  
     IF( @tdc_part <> @part ) OR ( @ordered <> @tdc_ordered )  
     IF EXISTS (SELECT * FROM tdc_ord_list_kit (nolock) WHERE order_no = @tran_no AND order_ext = @tran_ext AND kit_picked > 0 )  
     OR EXISTS (SELECT * FROM tdc_dist_item_pick (nolock) WHERE order_no = @tran_no AND order_ext = @tran_ext AND [function] = 'S')  
     BEGIN  
      IF (@@TRANCOUNT > 0) ROLLBACK TRAN  
   
      -- Error message: Order %d-%d is controlled by eWarehouse system  
      SELECT @errmsg = err_msg FROM tdc_lookup_error (nolock) WHERE language = @language AND module = 'SPR' AND trans = 'ORDLISTCHG' AND err_no = -102  
      RAISERROR (@errmsg, 16, -1, @tran_no, @tran_ext)  
      RETURN 0  
     END  
    END  
   END  
  END   
  ELSE  
  BEGIN  
   IF (( @ordered != @tdc_ordered ) AND ( @ordered < @shipped ))  
   BEGIN  
    IF (@@TRANCOUNT > 0) ROLLBACK TRAN  
  
    -- Error message: The updated order qty can not be less than the shippped qty  
    SELECT @errmsg = err_msg FROM tdc_lookup_error (nolock) WHERE language = @language AND module = 'SPR' AND trans = 'ORDLISTCHG' AND err_no = -105  
    RAISERROR (@errmsg, 16, -1)  
    RETURN 0   
   END  
  END  
  
  IF ( @ordered < @tdc_ordered )  
  BEGIN  
   IF ((SELECT sum(qty) FROM tdc_soft_alloc_tbl (NOLOCK) WHERE order_no = @tran_no AND order_ext = @tran_ext AND line_no = @tran_line AND order_type = 'S') + @shipped) > @ordered  
          --SCR 36574 052406 ToddR  
   --AND (SELECT active FROM tdc_config (NOLOCK) WHERE [function] = 'so_auto_allocate') != 'Y'   
   BEGIN  
	IF NOT EXISTS (SELECT 1 FROM dbo.cvo_soft_alloc_det (NOLOCK) WHERE order_no = @tran_no AND order_ext = @tran_ext 
					AND line_no = @tran_line AND change = 1 AND status > -1)
	BEGIN
		IF (@@TRANCOUNT > 0) ROLLBACK TRAN  
	  
		-- 'Must unallocate inventory before changing order quantity'  
		SELECT @errmsg = err_msg FROM tdc_lookup_error (nolock) WHERE language = @language AND module = 'SPR' AND trans = 'ORDLISTCHG' AND err_no = -106  
		RAISERROR (@errmsg, 16, -1)  
		RETURN 0  
	END
   END  
  END  
  
  IF ( @ordered <> @tdc_ordered )    
  BEGIN  
   UPDATE tdc_dist_item_list   
    SET quantity = @ordered  
     WHERE order_no = @tran_no AND order_ext = @tran_ext   
     AND line_no = @tran_line AND [function] = 'S'   
  END  
  
  IF( @tdc_part <> @part )  
  BEGIN  
   IF (EXISTS (SELECT * FROM tdc_soft_alloc_tbl (nolock) WHERE order_no     = @tran_no AND order_ext       = @tran_ext AND order_type = 'S' AND part_no = @tdc_part AND line_no = @tran_line)  
    OR EXISTS (SELECT * FROM tdc_pick_queue     (nolock) WHERE trans_type_no = @tran_no AND trans_type_ext = @tran_ext AND trans = 'STDPICK' AND part_no = @tdc_part AND line_no = @tran_line))  
          --SCR 36574 052406 ToddR  
          --AND (SELECT active FROM tdc_config (NOLOCK) WHERE [function] = 'so_auto_allocate') != 'Y'   
   BEGIN  
    IF @@TRANCOUNT > 0 ROLLBACK TRAN  
    
    -- Error message: Must unallocate inventory before changing the part number %s.  
    SELECT @errmsg = err_msg FROM tdc_lookup_error (nolock) WHERE language = @language AND module = 'SPR' AND trans = 'ORDLISTCHG' AND err_no = -108  
    RAISERROR(@errmsg, 16, -1, @tdc_part)  
    RETURN 0  
   END  
  
   IF NOT EXISTS (SELECT * FROM tdc_ord_list_kit (nolock) WHERE order_no = @tran_no AND order_ext = @tran_ext AND kit_picked > 0 AND line_no = @tran_line )  
   BEGIN  
    UPDATE tdc_dist_item_list   
       SET part_no = @part   
     WHERE order_no = @tran_no   
       AND order_ext = @tran_ext   
       AND line_no = @tran_line   
       AND [function] = 'S'  
  
    RETURN 0  
   END  
     
   IF (@@TRANCOUNT > 0) ROLLBACK TRAN  
  
   -- Error message: This line item has been picked through eWarehouse system  
   SELECT @errmsg = err_msg FROM tdc_lookup_error (nolock) WHERE language = @language AND module = 'SPR' AND trans = 'ORDLISTCHG' AND err_no = -107  
   RAISERROR (@errmsg, 16, -1)     
  END  
    
  SELECT @tdc_loc = location   
    FROM tdc_soft_alloc_tbl (nolock)   
   WHERE order_no = @tran_no   
     AND order_ext = @tran_ext   
     AND order_type = 'S'  
     AND line_no = @tran_line  
  
  IF (@tdc_loc IS NOT NULL) AND (@tdc_loc <> @location)  
  BEGIN  
   IF @@TRANCOUNT > 0 ROLLBACK TRAN  
      
   RAISERROR('Must unallocate inventory in DSF before changing location %s.', 16, -1, @tdc_loc)  
   RETURN 0  
  END    
 END  
END  
  
--==========================================================================================  
  
RETURN 0  
GO
GRANT EXECUTE ON  [dbo].[tdc_order_list_change] TO [public]
GO
