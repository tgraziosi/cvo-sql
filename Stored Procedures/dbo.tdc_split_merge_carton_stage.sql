SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- v1.0 CB 25/01/2012 Fix issue in standard product
CREATE PROC [dbo].[tdc_split_merge_carton_stage]   
AS  
  
DECLARE @carton_no int,  
 @err_msg varchar(255),  
 @new_stage_no varchar(11)   
  
DECLARE split_cur   
CURSOR FOR   
 SELECT carton_no, new_stage_no   
   FROM #split_merge_carton_stage  
  WHERE new_stage_no != stage_no  
    AND mp = 'N'  
  UNION  
 SELECT b.carton_no, a.new_stage_no  
   FROM #split_merge_carton_stage a,  
        tdc_master_pack_ctn_tbl b(NOLOCK)  
  WHERE a.carton_no = b.pack_no  
    AND a.mp = 'Y' 
	AND new_stage_no != stage_no -- v1.0 Without this it selects all records
     
OPEN split_cur  
FETCH NEXT FROM split_cur INTO @carton_no, @new_stage_no   
WHILE @@FETCH_STATUS = 0  
BEGIN  
 IF EXISTS(SELECT *   
      FROM tdc_stage_carton  
     WHERE carton_no = @carton_no  
       AND (tdc_ship_flag = 'Y'  OR adm_ship_flag = 'Y'))  
 BEGIN  
  CLOSE split_cur  
  DEALLOCATE split_cur  
  SELECT @err_msg = 'Cannot update stage for shipped carton: ' + CAST(@carton_no AS VARCHAR)  
  RAISERROR(@err_msg, 16, 1)  
  RETURN -1  
    
 END  
  
 IF EXISTS(SELECT * FROM tdc_carton_tx  
     WHERE carton_no = @carton_no  
       AND status != 'S')  
 BEGIN  
  CLOSE split_cur  
  DEALLOCATE split_cur  
  SELECT @err_msg = 'Carton must be staged: ' + CAST(@carton_no AS VARCHAR)  
  RAISERROR(@err_msg, 16, 1)  
  RETURN -2  
    
 END  
  
 UPDATE tdc_stage_carton  
    SET stage_no = @new_stage_no  
  WHERE carton_no = @carton_no  
  
 IF @@ERROR != 0  
 BEGIN  
  CLOSE split_cur  
  DEALLOCATE split_cur  
  RAISERROR('Update tdc_stage_carton failed', 16, 1)  
  RETURN -4  
 END  
   
 FETCH NEXT FROM split_cur INTO @carton_no, @new_stage_no   
    
END --WHILE  
CLOSE split_cur  
DEALLOCATE split_cur  
  
GO
GRANT EXECUTE ON  [dbo].[tdc_split_merge_carton_stage] TO [public]
GO
