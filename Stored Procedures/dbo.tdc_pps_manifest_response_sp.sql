SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- v1.0 CB 05/08/2014 - Issue #572 - Masterpack - Polarized Labs - Do not update the tracking number of the underlying carton for ship via lab  
-- v1.1 CB 19/06/2014 - Fix issue with tracking number not written back to masterpack table - Seems to be std bug and remove v1.0
-- v1.2 CB 15/07/2014 - If -PL orders then update carton and masterpack seperately
CREATE PROCEDURE [dbo].[tdc_pps_manifest_response_sp]  
 @is_freighting  char(1), --FREIGHT/UNFREIGHT FLAG  
 @carton_no  int,  
 @stage_no  varchar(20),  
 @user_id  varchar(50),  
 @err_msg  varchar(255) OUTPUT  
AS   
  
DECLARE @Response  varchar(1000),  
 @SendString varchar(1000),  
 @Pos   INT,  
 @Length  INT,  
 @FreightType varchar(255),  
 @FreightAmt DECIMAL,  
 @Cnt  INT,  
 @language varchar(10),  
 @order_no int,  
 @order_ext int,  
 @pack_no int,  
 @is_master_pack char(1),  
 @pl_order int, -- v1.2
   
 --Manifest Fields  
 @ORDER  varchar(255),  
 @CARTON  varchar(255),  
 @PUB_RATE varchar(255),  
 @DISC_RATE varchar(255),  
 @DIM_WEIGHT varchar(255),  
 @TRACKING_NO varchar(255),  
 @IMPERRMSSG varchar(255),  
 @ESTFRGT varchar(255),  
 @TRANSACT varchar(255),  
 @ZONE  varchar(255),  
 @OTHER  varchar(255),  
 @OVERSIZE varchar(255),  
 @CALLTAG varchar(255),  
 @AIRBILL varchar(255),  
 @PICKUP  varchar(255),  
 @SHIPDATE varchar(255),  
 @SHIPTIME varchar(255),  
 @TRANSACTION varchar(255),  
 @STATUS  varchar(255)   
  
--Get the response string from the temp table  
SELECT TOP 1 @Response = response, @SendString = sendstring FROM #tdc_temp_manifest_response  
SELECT @language = ISNULL((SELECT Language FROM tdc_sec (nolock) WHERE userid = (SELECT who FROM #temp_who)), 'us_english')  
  
IF EXISTS(SELECT * FROM tdc_master_pack_ctn_tbl(NOLOCK)  
    WHERE carton_no = @carton_no)  
BEGIN  
 SELECT @is_master_pack = 'Y'  
 SELECT @pack_no = pack_no   
   FROM tdc_master_pack_ctn_tbl(NOLOCK)  
  WHERE carton_no = @carton_no  
END  
ELSE  
 SELECT @is_master_pack = 'N'  
  
--#####################################################################################  
--Parse the response  
--#####################################################################################  
IF (@is_freighting = 'Y')  
BEGIN  
 --ORDER  
 SELECT  @Length = (endpos - startpos+1) ,  
     @Pos = startpos  
     FROM tdc_mis_msg_layout_tbl(NOLOCK)  
         WHERE message = 'CARTONRESPONSE'  
         AND fieldname = 'ORDER'  
 SELECT @ORDER = SUBSTRING(@Response, @Pos, @Length)  
   
 --CARTON  
 SELECT  @Length = (endpos - startpos+1) ,  
     @Pos = startpos  
     FROM tdc_mis_msg_layout_tbl(NOLOCK)  
         WHERE message = 'CARTONRESPONSE'  
         AND fieldname = 'CARTON'  
 SELECT @CARTON = SUBSTRING(@Response, @Pos, @Length)  
   
 --PUB_RATE  
 SELECT  @Length = (endpos - startpos+1) ,  
     @Pos = startpos  
     FROM tdc_mis_msg_layout_tbl(NOLOCK)  
         WHERE message = 'CARTONRESPONSE'  
         AND fieldname = 'PUB_RATE'  
 SELECT @PUB_RATE = SUBSTRING(@Response, @Pos, @Length)  
   
 --DISC_RATE  
 SELECT  @Length = (endpos - startpos+1) ,  
     @Pos = startpos  
     FROM tdc_mis_msg_layout_tbl(NOLOCK)  
         WHERE message = 'CARTONRESPONSE'  
         AND fieldname = 'DISC_RATE'  
 SELECT @DISC_RATE = SUBSTRING(@Response, @Pos, @Length)  
   
 --DIM_WEIGHT  
 SELECT  @Length = (endpos - startpos+1) ,  
     @Pos = startpos  
     FROM tdc_mis_msg_layout_tbl(NOLOCK)  
         WHERE message = 'CARTONRESPONSE'  
         AND fieldname = 'DIM_WEIGHT'  
 SELECT @DIM_WEIGHT = SUBSTRING(@Response, @Pos, @Length)  
   
 --TRACKING_NO  
 SELECT  @Length = (endpos - startpos+1) ,  
     @Pos = startpos  
     FROM tdc_mis_msg_layout_tbl(NOLOCK)  
         WHERE message = 'CARTONRESPONSE'  
         AND fieldname = 'TRACKING_NO'  
 SELECT @TRACKING_NO = SUBSTRING(@Response, @Pos, @Length)  

IF (@@servername = 'V227230K') -- For debug will only run on CB server
BEGIN
	IF (@is_master_pack = 'N')
		SET @TRACKING_NO = 'TN: ' + CONVERT(varchar(40),GETDATE(),121)
	ELSE
		SET @TRACKING_NO = 'MP: ' + CONVERT(varchar(40),GETDATE(),121)
END
   
 --IMPERRMSSG  
 SELECT  @Length = (endpos - startpos+1) ,  
     @Pos = startpos  
     FROM tdc_mis_msg_layout_tbl(NOLOCK)  
         WHERE message = 'CARTONRESPONSE'  
         AND fieldname = 'IMPERRMSSG'  
 SELECT @IMPERRMSSG = SUBSTRING(@Response, @Pos, @Length)  
   
 IF ISNULL(@IMPERRMSSG, '') <> ''   
 BEGIN  
  RAISERROR(@imperrmssg, 16, 1)  
  RETURN   
 END  
  
 --ESTFRGT  
 SELECT  @Length = (endpos - startpos+1) ,  
     @Pos = startpos  
     FROM tdc_mis_msg_layout_tbl(NOLOCK)  
         WHERE message = 'CARTONRESPONSE'  
         AND fieldname = 'ESTFRGT'  
 SELECT @ESTFRGT = SUBSTRING(@Response, @Pos, @Length)  
   
 --TRANSACT  
 SELECT  @Length = (endpos - startpos+1) ,  
     @Pos = startpos  
     FROM tdc_mis_msg_layout_tbl(NOLOCK)  
         WHERE message = 'CARTONRESPONSE'  
         AND fieldname = 'TRANSACT'  
 SELECT @TRANSACT = SUBSTRING(@Response, @Pos, @Length)  
   
 --ZONE  
 SELECT  @Length = (endpos - startpos+1) ,  
     @Pos = startpos  
     FROM tdc_mis_msg_layout_tbl(NOLOCK)  
         WHERE message = 'CARTONRESPONSE'  
         AND fieldname = 'ZONE'  
 SELECT @ZONE = SUBSTRING(@Response, @Pos, @Length)  
   
 --OTHER  
 SELECT  @Length = (endpos - startpos+1) ,  
     @Pos = startpos  
     FROM tdc_mis_msg_layout_tbl(NOLOCK)  
         WHERE message = 'CARTONRESPONSE'  
         AND fieldname = 'OTHER'  
 SELECT @OTHER = SUBSTRING(@Response, @Pos, @Length)  
   
 --OVERSIZE  
 SELECT  @Length = (endpos - startpos+1) ,  
     @Pos = startpos  
     FROM tdc_mis_msg_layout_tbl(NOLOCK)  
         WHERE message = 'CARTONRESPONSE'  
         AND fieldname = 'OVERSIZE'  
 SELECT @OVERSIZE = SUBSTRING(@Response, @Pos, @Length)  
   
 --CALLTAG  
 SELECT  @Length = (endpos - startpos+1) ,  
     @Pos = startpos  
     FROM tdc_mis_msg_layout_tbl(NOLOCK)  
         WHERE message = 'CARTONRESPONSE'  
         AND fieldname = 'CALLTAG'  
 SELECT @CALLTAG = SUBSTRING(@Response, @Pos, @Length)  
   
 --AIRBILL  
 SELECT  @Length = (endpos - startpos+1) ,  
     @Pos = startpos  
     FROM tdc_mis_msg_layout_tbl(NOLOCK)  
         WHERE message = 'CARTONRESPONSE'  
         AND fieldname = 'AIRBILL'  
 SELECT @AIRBILL = SUBSTRING(@Response, @Pos, @Length)  
   
 --PICKUP  
 SELECT  @Length = (endpos - startpos+1) ,  
     @Pos = startpos  
     FROM tdc_mis_msg_layout_tbl(NOLOCK)  
         WHERE message = 'CARTONRESPONSE'  
         AND fieldname = 'PICKUP'  
 SELECT @PICKUP = SUBSTRING(@Response, @Pos, @Length)  
   
 --SHIPDATE  
 SELECT  @Length = (endpos - startpos+1) ,  
     @Pos = startpos  
     FROM tdc_mis_msg_layout_tbl(NOLOCK)  
         WHERE message = 'CARTONRESPONSE'  
         AND fieldname = 'SHIPDATE'  
 SELECT @SHIPDATE = SUBSTRING(@Response, @Pos, @Length)  
   
 --SHIPTIME  
 SELECT  @Length = (endpos - startpos + 1) ,  
      @Pos = startpos  
  FROM tdc_mis_msg_layout_tbl(NOLOCK)  
         WHERE message = 'CARTONRESPONSE'  
         AND fieldname = 'SHIPTIME'  
 SELECT @SHIPTIME = SUBSTRING(@Response, @Pos, @Length)  
  
  
  
  
END    
ELSE -- Unfreighting  
BEGIN  
 --@TRANSACTION  
 SELECT  @Length = (endpos - startpos + 1) ,  
      @Pos = startpos  
  FROM tdc_mis_msg_layout_tbl(NOLOCK)  
         WHERE message = 'UNFREIGHTSTATUS'  
         AND fieldname = 'TRANSACTION'  
 SELECT @TRANSACTION = SUBSTRING(@Response, @Pos, @Length)  
  
 IF (@TRANSACTION <> 'UNFREIGHT')  
 BEGIN  
  -- 'Error receiving unfreight response from manifest system'  
  SELECT @err_msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_pps_manifest_response_sp' AND err_no = -101 AND language = @language   
  RETURN -1  
 END  
  
 --@TRANSACTION  
 SELECT  @Length = (endpos - startpos + 1) ,  
      @Pos = startpos  
  FROM tdc_mis_msg_layout_tbl(NOLOCK)  
         WHERE message = 'UNFREIGHTSTATUS'  
         AND fieldname = 'STATUS'  
 SELECT @STATUS = SUBSTRING(@Response, @Pos, @Length)  
  
 IF(LTRIM(RTRIM(@STATUS)) <> '')  
 BEGIN  
  -- 'Manifest error: '  
  SELECT @err_msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_pps_manifest_response_sp' AND err_no = -102 AND language = @language   
  SELECT @err_msg = @err_msg + @STATUS  
  RETURN -2  
 END  
END  
--#####################################################################################  
--Begin the updates with the parsed information  
--#####################################################################################  
  
BEGIN TRAN  
  
--Log the response  
INSERT INTO tdc_log (tran_no, tran_ext, tran_date, data, trans, UserID)   
SELECT order_no, order_ext, GETDATE(), 'Carton = ' + CAST(@carton_no AS VARCHAR) + ', Data: ' + @SendString + ', ' + @Response, 'DataArrival', @user_id   
  FROM tdc_carton_tx (NOLOCK)  
 WHERE carton_no = @carton_no  
  
IF @@ERROR <> 0   
BEGIN  
 ROLLBACK TRAN  
 -- 'Critical error encountered during update'  
 SELECT @err_msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_pps_manifest_response_sp' AND err_no = -103 AND language = @language   
 RETURN -3  
END  
  
   
IF @is_freighting = 'Y'  
BEGIN  
 IF @is_master_pack = 'N'  
 BEGIN   
  --If carton does not match, error out of procedure  
  IF (CAST(@carton_no AS varchar(255)) <> CAST(@CARTON AS varchar(255)))  
  BEGIN  
   
   ROLLBACK TRAN  
   -- 'Carton received from manifest system does not match carton sent to manifest system'  
   SELECT @err_msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_pps_manifest_response_sp' AND err_no = -104 AND language = @language   
   RETURN -4  
  END  
 END  
 ELSE  
 BEGIN  
  IF NOT EXISTS(SELECT * FROM tdc_master_pack_ctn_tbl  
          WHERE pack_no = @CARTON   
     AND carton_no = @carton_no)  
  BEGIN  
   ROLLBACK TRAN  
   SELECT @err_msg = 'Carton number not included in masterpack from manifest system.'  
   RETURN -45  
  END  
 END  
END  
  
--If freighting carton  
IF (@is_freighting = 'Y' )  
BEGIN  
	-- v1.2 Start
	SET @pl_order = 0
	SELECT	@pl_order = COUNT(1)
	FROM	tdc_carton_detail_tx a (NOLOCK)
	JOIN	orders_all b (NOLOCK)
	ON		a.order_no = b.order_no
	AND		a.order_ext = b.ext
	WHERE	a.carton_no = @carton_no
	AND		ISNULL(b.sold_to,'') > ''
	AND		RIGHT(b.user_category,2) = 'PL'

	IF @pl_order > 0
	BEGIN
		IF (@is_master_pack = 'N')
		BEGIN
			UPDATE tdc_carton_tx    
			 SET cs_tx_no = @TRANSACT,  
						cs_tracking_no = CAST(@TRACKING_NO AS varchar(25)),  
						cs_zone = CAST(@ZONE AS varchar(10)),  
						cs_oversize = CAST(@OVERSIZE AS CHAR(255)),  
						cs_call_tag_no = CAST(@CALLTAG AS varchar(10)),  
						cs_airbill_no = CAST(@AIRBILL AS varchar(18)),  
						cs_other = CAST(@OTHER AS MONEY),  
						cs_pickup_no = CAST(@PICKUP AS varchar(10)),  
						cs_dim_weight = CAST(@DIM_WEIGHT AS DECIMAL(20,8)),  
						cs_published_freight = CAST(@PUB_RATE AS DECIMAL(20,8)),   
						cs_disc_freight = CAST(@DISC_RATE AS DECIMAL(20,8)),  
						cs_estimated_freight = CAST(@ESTFRGT AS CHAR(13)),  
					   date_shipped = CAST(@SHIPDATE  + ' ' + @SHIPTIME AS DATETIME),  
						status = 'C'  
					WHERE carton_no = @carton_no  			

		END
		ELSE
		BEGIN
			UPDATE tdc_master_pack_tbl   
			SET cs_tracking_no = CAST(@TRACKING_NO AS varchar(25)) 
			WHERE pack_no = @pack_no 		
		END
	END
	ELSE
	BEGIN

		--Update Carton Header Table with Manifest System data values.  
		UPDATE tdc_carton_tx    
        SET cs_tx_no = @TRANSACT,  
			cs_tracking_no = CAST(@TRACKING_NO AS varchar(25)),  
			cs_zone = CAST(@ZONE AS varchar(10)),  
			cs_oversize = CAST(@OVERSIZE AS CHAR(255)),  
			cs_call_tag_no = CAST(@CALLTAG AS varchar(10)),  
			cs_airbill_no = CAST(@AIRBILL AS varchar(18)),  
			cs_other = CAST(@OTHER AS MONEY),  
			cs_pickup_no = CAST(@PICKUP AS varchar(10)),  
			cs_dim_weight = CAST(@DIM_WEIGHT AS DECIMAL(20,8)),  
			cs_published_freight = CAST(@PUB_RATE AS DECIMAL(20,8)),   
			cs_disc_freight = CAST(@DISC_RATE AS DECIMAL(20,8)),  
			cs_estimated_freight = CAST(@ESTFRGT AS CHAR(13)),  
		   date_shipped = CAST(@SHIPDATE  + ' ' + @SHIPTIME AS DATETIME),  
			status = 'C'  
		WHERE carton_no = @carton_no  

 	  UPDATE tdc_master_pack_tbl   
		  SET cs_tracking_no = CAST(@TRACKING_NO AS varchar(25)) 
		WHERE pack_no = @pack_no 		 

	END
	-- v1.2 End

  
 IF @@ERROR <> 0   
 BEGIN  
  ROLLBACK TRAN  
  -- 'Critical error encountered during update'  
  SELECT @err_msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_pps_manifest_response_sp' AND err_no = -103 AND language = @language   
  RETURN -5  
 END  
   
  
 --IF @stage_no IS NOT NULL  
 IF (LEN(RTRIM(ISNULL(@stage_no, ''))) > 0)  
 BEGIN  
  --After closing the carton, set the status to 'S' for triggers  
  UPDATE tdc_carton_tx SET status = 'S' WHERE carton_no = @carton_no  
  IF @@ERROR <> 0   
  BEGIN  
   ROLLBACK TRAN  
   -- 'Critical error encountered during update'  
   SELECT @err_msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_pps_manifest_response_sp' AND err_no = -103 AND language = @language   
   RETURN -6  
  END  
     
  IF @is_master_pack = 'Y'  
  BEGIN  
   UPDATE tdc_master_pack_tbl   
      SET status = 'S'  
    WHERE pack_no = @pack_no  
  END   
  
  UPDATE tdc_carton_detail_tx SET status = 'S' WHERE carton_no = @carton_no  
  IF @@ERROR <> 0   
  BEGIN  
   ROLLBACK TRAN  
   -- 'Critical error encountered during update'  
   SELECT @err_msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_pps_manifest_response_sp' AND err_no = -103 AND language = @language   
   RETURN -7  
  END  
   
    
  UPDATE tdc_dist_group  SET status = 'S' WHERE parent_serial_no = @carton_no  
  IF @@ERROR <> 0   
  BEGIN  
   ROLLBACK TRAN  
   -- 'Critical error encountered during update'  
   SELECT @err_msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_pps_manifest_response_sp' AND err_no = -103 AND language = @language   
   RETURN -8  
  END  
   
  --Assign stage number  
  INSERT INTO tdc_stage_carton(carton_no, stage_no, tdc_ship_flag, adm_ship_flag, tdc_ship_date, adm_ship_date, master_pack)    
         VALUES (@carton_no, @stage_no, 'N', 'N', NULL, NULL, @is_master_pack)   
   
  IF @@ERROR <> 0   
  BEGIN  
   ROLLBACK TRAN  
   -- 'Critical error encountered during update'  
   SELECT @err_msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_pps_manifest_response_sp' AND err_no = -103 AND language = @language   
   RETURN -9  
  END  
   
  IF NOT EXISTS(SELECT * FROM tdc_stage_numbers_tbl(NOLOCK)  
          WHERE stage_no = @stage_no)  
  BEGIN  
   INSERT INTO tdc_stage_numbers_tbl(stage_no, active, creation_date)  
   SELECT @stage_no, 'Y', GETDATE()  
  END  
  ELSE  
  BEGIN  
   UPDATE tdc_stage_numbers_tbl SET active = 'Y' WHERE stage_no = @stage_no  
  END  
 END  
 ELSE  
 BEGIN  
  
  IF @is_master_pack = 'Y'  
  BEGIN  
   UPDATE tdc_master_pack_tbl   
      SET status = 'F'  
    WHERE pack_no = @pack_no  
  END   
  
  --After closing the carton, set the status to 'S' for triggers  
  UPDATE tdc_carton_tx SET status = 'F' WHERE carton_no = @carton_no  
  IF @@ERROR <> 0   
  BEGIN  
   ROLLBACK TRAN  
   -- 'Critical error encountered during update'  
   SELECT @err_msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_pps_manifest_response_sp' AND err_no = -103 AND language = @language   
   RETURN -6  
  END  
     
  
  UPDATE tdc_carton_detail_tx SET status = 'F' WHERE carton_no = @carton_no  
  IF @@ERROR <> 0   
  BEGIN  
   ROLLBACK TRAN  
   -- 'Critical error encountered during update'  
   SELECT @err_msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_pps_manifest_response_sp' AND err_no = -103 AND language = @language   
   RETURN -7  
  END  
   
    
  UPDATE tdc_dist_group  SET status = 'F' WHERE parent_serial_no = @carton_no  
  IF @@ERROR <> 0   
  BEGIN  
   ROLLBACK TRAN  
   -- 'Critical error encountered during update'  
   SELECT @err_msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_pps_manifest_response_sp' AND err_no = -103 AND language = @language   
   RETURN -8  
  END   
 END  
     
  
                      
END  
ELSE --Unfreighting  
BEGIN  
  
  
 UPDATE tdc_carton_tx    
  SET cs_tx_no = '', cs_tracking_no = '', cs_zone = '',    
                cs_oversize = '', cs_call_tag_no = '', cs_airbill_no = '',    
                cs_other = 0, cs_pickup_no = '', cs_dim_weight = 0, cs_published_freight = 0,   
                cs_disc_freight = 0, cs_estimated_freight = '', date_shipped = getdate(), status = 'C'   
                WHERE carton_no = @carton_no  
  
 IF @@ERROR <> 0   
 BEGIN  
  ROLLBACK TRAN  
  -- 'Critical error encountered during update'  
  SELECT @err_msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_pps_manifest_response_sp' AND err_no = -103 AND language = @language   
  RETURN -10  
 END  
  
 -- Unstage carton to closed status  
        UPDATE tdc_carton_tx    
                SET status = 'C'   
                WHERE carton_no = @carton_no  
  
 IF @is_master_pack = 'Y'  
 BEGIN  
  UPDATE tdc_master_pack_tbl   
     SET status = 'C'  
   WHERE pack_no = @pack_no  
 END  
  
 IF @@ERROR <> 0   
 BEGIN  
  ROLLBACK TRAN  
  -- 'Critical error encountered during update'  
  SELECT @err_msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_pps_manifest_response_sp' AND err_no = -103 AND language = @language   
  RETURN -11  
 END  
            
 UPDATE tdc_carton_detail_tx    
         SET status = 'C'   
         WHERE carton_no = @carton_no  
  
 IF @@ERROR <> 0   
 BEGIN  
  ROLLBACK TRAN  
  -- 'Critical error encountered during update'  
  SELECT @err_msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_pps_manifest_response_sp' AND err_no = -103 AND language = @language   
  RETURN -12  
 END  
        
        UPDATE tdc_dist_group    
         SET status = 'C'   
         WHERE parent_serial_no = @carton_no  
  
 IF @@ERROR <> 0   
 BEGIN  
  ROLLBACK TRAN  
  -- 'Critical error encountered during update'  
  SELECT @err_msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_pps_manifest_response_sp' AND err_no = -103 AND language = @language   
  RETURN -13  
 END  
  
        DELETE FROM tdc_stage_carton    
         WHERE carton_no = @carton_no  
  
 -- If master pack, and removing all the cartons for the master pack,  
 -- remove the master pack record.  
 IF @is_master_pack = 'Y'  
 BEGIN  
  SELECT @pack_no = pack_no   
    FROM tdc_master_pack_ctn_tbl(NOLOCK)  
   WHERE carton_no = @carton_no  
  
  IF NOT EXISTS(SELECT * FROM tdc_stage_carton(NOLOCK)  
          WHERE carton_no IN(SELECT carton_no FROM tdc_master_pack_ctn_tbl(NOLOCK)  
         WHERE pack_no = @pack_no))  
  BEGIN  
   DELETE FROM tdc_stage_carton  
    WHERE carton_no = @pack_no  
  END  
  
  UPDATE tdc_master_pack_tbl  
     SET status = 'O'   
   WHERE pack_no = @pack_no  
 END  
  
 IF @@ERROR <> 0   
 BEGIN  
  ROLLBACK TRAN  
  -- 'Critical error encountered during update'  
  SELECT @err_msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_pps_manifest_response_sp' AND err_no = -103 AND language = @language   
  RETURN -14  
 END  
                         
  
END  
  
DECLARE cur CURSOR FOR  
SELECT order_no, order_ext  
  FROM tdc_carton_tx (NOLOCK)  
 WHERE carton_no = @carton_no  
   AND order_type = 'S'  
  
OPEN cur  
FETCH NEXT FROM cur INTO @order_no, @order_ext  
WHILE @@FETCH_STATUS = 0  
BEGIN  
 EXEC tdc_upd_ord_tots @order_no, @order_ext   
 FETCH NEXT FROM cur INTO @order_no, @order_ext  
END  
CLOSE cur  
DEALLOCATE cur  
  
IF @@ERROR <> 0   
BEGIN  
 ROLLBACK TRAN  
 -- 'Critical error encountered during update'  
 SELECT @err_msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_pps_manifest_response_sp' AND err_no = -103 AND language = @language   
 RETURN -15  
END  
  
COMMIT TRAN  
RETURN 0  
  
GO
GRANT EXECUTE ON  [dbo].[tdc_pps_manifest_response_sp] TO [public]
GO
