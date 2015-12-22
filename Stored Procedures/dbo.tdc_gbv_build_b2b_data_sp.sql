SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- v1.0 CB 05/09/2012 - Issue #709 - Add clipboard to allow bins to be copied across templates and to resolve the scrolling issue  
CREATE PROCEDURE [dbo].[tdc_gbv_build_b2b_data_sp]  
 @template_id  int,  
 @userid   varchar(50),  
 @from_bin  varchar(12),  
 @err_msg  varchar(255) OUTPUT  
AS   
  
DECLARE  
 @location  varchar(10),  
 @to_bin   varchar(12),  
 @avail_qty  decimal(20,8),  
 @qty_to_move  decimal(20,8),  
 @date_expires  datetime,  
 @part_no  varchar(25),  
 @lot_ser  varchar(25),  
 @current_bin_qty decimal(20,8),  
 @pending_alloc_qty decimal(20,8),  
 @priority  varchar(1),  
 @user_or_group  varchar(25),  
 @language  varchar(10)  
  
 SELECT @language = ISNULL(Language, 'us_english') FROM tdc_sec (nolock) WHERE userid = @userid  
--MAKE SURE IT'S A VALID TEMPLATE  
 IF NOT EXISTS(SELECT * FROM tdc_graphical_bin_template (NOLOCK) WHERE template_id = @template_id)  
 BEGIN  
  --'Entered template is invalid.'  
  SELECT @err_msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'GBV' AND trans = 'GBV_MGTB2B' AND err_no = 1 AND language = @language  
  RETURN -1  
 END  
   
--MAKE SURE THE BIN IS DEFINED ON THIS TEMPLATE  
-- v1.0 Start - Comment out
-- IF NOT EXISTS(SELECT * FROM tdc_graphical_bin_store (NOLOCK) WHERE template_id = @template_id AND bin_no = @from_bin)  
-- BEGIN  
--  --'Invalid bin, the bin [%s1] is not defined in template #%s2.'  
--  SELECT @err_msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'GBV' AND trans = 'GBV_MGTB2B' AND err_no = 2 AND language = @language  
--  SELECT @err_msg = REPLACE(REPLACE(@err_msg,'%s2',cast(@template_id as varchar)), '%s1', @from_bin)  
--  RETURN -2  
-- END  
-- v1.0 End 

--Get the location from the template  
 SELECT @location = location FROM tdc_graphical_bin_template (NOLOCK) WHERE template_id = @template_id  
  
/* TABLES THAT ARE BEING POPULATED WITHIN THIS STORED PROCEDURE  
 #tdc_to_bins  - DESTINATION BINS  
 #tdc_groups_users - USERS AND GROUPS  
 #tdc_gbv_b2b_data - VB GRID DATA   
*/  
  
--POPULATE TABLE USED TO STORE THE 'TO BINS' OR DESTINATION BINS FOR THE MGTB2B MOVES  
 TRUNCATE TABLE #tdc_to_bins  
 INSERT INTO #tdc_to_bins (bin_no)  
  SELECT bin_no FROM tdc_graphical_bin_store (NOLOCK)   
   WHERE template_id = @template_id   
       AND bin_no <> @from_bin   
     AND bin_no IS NOT NULL  
     AND bin_no NOT LIKE '<%>'  
   ORDER BY bin_no  
  
--POPULATE TABLE USED TO STORE THE USERS AND GROUPS  
 TRUNCATE TABLE #tdc_groups_users  
 INSERT INTO #tdc_groups_users (user_group_id, type)  
  VALUES(' ', 'S')  
 INSERT INTO #tdc_groups_users (user_group_id, type)  
  VALUES('-- Users --', '1')  
 INSERT INTO #tdc_groups_users (user_group_id, type)  
  SELECT UserID, 'U' from tdc_sec (NOLOCK) WHERE group_flag IS NULL  
 IF EXISTS(SELECT TOP 1 UserID FROM tdc_sec (NOLOCK) WHERE group_flag = 1)  
 BEGIN  
  INSERT INTO #tdc_groups_users (user_group_id, type)  
   VALUES('-- Groups --', '2')  
  INSERT INTO #tdc_groups_users (user_group_id, type)  
   SELECT UserID, 'G' from tdc_sec (NOLOCK) WHERE group_flag = 1  
 END  
  
--SET DEFAULT VALUES  
 SELECT  @qty_to_move = 0, @to_bin = '', @priority = '', @user_or_group = ''  
  
--POPULATE TABLE FOR GRID  
 TRUNCATE TABLE #tdc_gbv_b2b_data  
 DECLARE bin_cursor CURSOR FAST_FORWARD FOR  
 SELECT part_no, lot_ser, date_expires  
  FROM lot_bin_stock (NOLOCK)  
  WHERE bin_no = @from_bin  
 OPEN bin_cursor  
 FETCH NEXT FROM bin_cursor   
  INTO @part_no, @lot_ser, @date_expires  
 WHILE @@FETCH_STATUS = 0  
 BEGIN  
  -- Get existing quantity for this part in the bin  
  SELECT @current_bin_qty = ISNULL((SELECT sum(qty) FROM lot_bin_stock (nolock)  
       WHERE location = @location   
       AND   bin_no = @from_bin  
       AND   part_no = @part_no  
       AND   lot_ser = @lot_ser),0)  
  
  
  -- Get any allocated and mgtb2b quantities from the table on this location, part, lot, bin  
  SELECT @pending_alloc_qty = ISNULL(SUM(qty),0) FROM tdc_soft_alloc_tbl (NOLOCK)   
       WHERE location = @location   
       AND part_no = @part_no   
       AND lot_ser = @lot_ser   
       AND bin_no = @from_bin  
  --Get the total available qty  
  SELECT @avail_qty = @current_bin_qty - @pending_alloc_qty  
  --Insert new record  
  IF @avail_qty > 0  
  INSERT INTO #tdc_gbv_b2b_data (part_no, lot_ser, date_expires, avail_qty, qty_to_move, priority, user_or_group ,to_bin)  
   VALUES(@part_no, @lot_ser, @date_expires, @avail_qty, @qty_to_move, @priority, @user_or_group, @to_bin)  
  FETCH NEXT FROM bin_cursor   
   INTO @part_no, @lot_ser, @date_expires  
 END  
 CLOSE bin_cursor  
 DEALLOCATE bin_cursor  
  
RETURN 0  
GO
GRANT EXECUTE ON  [dbo].[tdc_gbv_build_b2b_data_sp] TO [public]
GO
