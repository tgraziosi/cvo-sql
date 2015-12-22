SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- v1.0 CB 23/04/2015 - Performance Changes  
CREATE PROC [dbo].[tdc_do_ship_order_sp]	@order_type  char(1),  
									@order_no   int,  
									@order_ext  int,  
									@stage_no  varchar(50),  
									@eBackOfficeShip char(1),  
									@user_id  varchar(50),  
									@alter_by  int,  
									@order_shipped  char(1) OUTPUT    
AS  
BEGIN
  
	DECLARE @ret   int,  
			@carton_no  int,  
			@ship_order_flg   char(1),  
			@pack_no  int,  
			@valid_carton  char(1)  

	-- v1.0 Start
	DECLARE	@row_id			int,
			@last_row_id	int
	-- v1.0 End  
  
	--Log the transaction  
	INSERT INTO tdc_log (trans_source, tran_date, trans, tran_no, tran_ext, data, UserID)   
	VALUES ('VB', GETDATE(),'AdmShipOrder', @order_no, @order_ext,'Stage: ' + @stage_no, @user_id)  
	
	-- v1.0 Start
	CREATE TABLE #tdc_update_ship_cnfrm_cur (
		row_id			int IDENTITY(1,1),
		carton_no		int)

	INSERT	#tdc_update_ship_cnfrm_cur (carton_no)
	--Update our staging table for all cartons associated with this order  
	-- v1.0 DECLARE tdc_update_ship_cnfrm_cur CURSOR FOR  
	SELECT	a.carton_no  
	FROM	tdc_carton_tx a (NOLOCK),  
			tdc_stage_carton b (NOLOCK) 
	WHERE	a.order_no   = @order_no  
    AND		a.order_ext  = @order_ext  
    AND		a.order_type = @order_type  
    AND		a.carton_no  = b.carton_no  
    AND		b.stage_no   = @stage_no  
    AND		b.tdc_ship_flag <> 'Y'  
    AND		a.carton_no IN (SELECT carton_no   
							FROM #temp_ship_confirm_cartons)           
	
	-- v1.0 OPEN tdc_update_ship_cnfrm_cur   
	-- v1.0 FETCH NEXT FROM tdc_update_ship_cnfrm_cur INTO @carton_no  
	-- v1.0 WHILE(@@FETCH_STATUS = 0)  

	SET @last_row_id = 0
	
	SELECT	TOP 1 @row_id = row_id,
			@carton_no = carton_no
	FROM	#tdc_update_ship_cnfrm_cur
	WHERE	row_id > @last_row_id
	ORDER BY row_id ASC

	WHILE @@ROWCOUNT <> 0
	BEGIN  
		SELECT @valid_carton = 'Y'  
  
		IF (SELECT active FROM TDC_CONFIG (NOLOCK) WHERE [function] = 'stage_to_load_flag') = 'Y'   
		BEGIN  
			IF EXISTS(SELECT * FROM tdc_carton_tx (NOLOCK) WHERE carton_no = @carton_no AND stl_status = 'N')   
			BEGIN  
				SELECT @valid_carton = 'N'  
			END    
		END  
  
		IF @valid_carton = 'Y'  
		BEGIN  
			--Set tdc_stage_carton TDC shipped flag to 'Y' and TDC ship date  
			UPDATE	tdc_stage_carton    
			SET		tdc_ship_flag = 'Y', 
					tdc_ship_date = GETDATE() - @alter_by  
			WHERE	carton_no = @carton_no  
			
			IF @@ERROR <> 0   
			BEGIN  
				-- v1.0 CLOSE tdc_update_ship_cnfrm_cur  
				-- v1.0 DEALLOCATE tdc_update_ship_cnfrm_cur  
				RAISERROR('update tdc_stage_carton failed', 16, 1)   
				RETURN -1  
			END  
   
			--Set tdc_carton_tx status to 'X' to indicate shipped  
			UPDATE	tdc_carton_tx    
			SET		status = 'X', 
					date_shipped = GETDATE() - @alter_by  
			WHERE	carton_no = @carton_no  
   
			IF @@ERROR <> 0   
			BEGIN  
				-- v1.0 CLOSE tdc_update_ship_cnfrm_cur  
				-- v1.0 DEALLOCATE tdc_update_ship_cnfrm_cur  
				RAISERROR('update tdc_carton_tx failed', 16, 1)   
				RETURN -2  
			END  
   
			--Set tdc_carton_detail_tx status to 'X' to indicate shipped  
			UPDATE	tdc_carton_detail_tx    
			SET		status = 'X'    
			WHERE	carton_no = @carton_no  
   
			IF @@ERROR <> 0   
			BEGIN  
				-- v1.0 CLOSE tdc_update_ship_cnfrm_cur  
				-- v1.0 DEALLOCATE tdc_update_ship_cnfrm_cur  
				RAISERROR('update tdc_carton_detail_tx failed', 16, 1)   
				RETURN -3  
			END  
   
			--Set tdc_dist_group status to 'X' to indicate shipped  
			UPDATE	tdc_dist_group    
			SET		status = 'X'    
			WHERE	parent_serial_no = @carton_no  
   
			IF @@ERROR <> 0   
			BEGIN  
				-- v1.0 CLOSE tdc_update_ship_cnfrm_cur  
				-- v1.0 DEALLOCATE tdc_update_ship_cnfrm_cur  
				RAISERROR('update tdc_dist_group failed', 16, 1)   
				RETURN -4  
			END  
  
		END  
  
		SET @last_row_id = @row_id
		
		SELECT	TOP 1 @row_id = row_id,
				@carton_no = carton_no
		FROM	#tdc_update_ship_cnfrm_cur
		WHERE	row_id > @last_row_id
		ORDER BY row_id ASC
		-- v1.0 FETCH NEXT FROM tdc_update_ship_cnfrm_cur INTO @carton_no  
	END  

	-- v1.0 CLOSE tdc_update_ship_cnfrm_cur  
	-- v1.0 DEALLOCATE tdc_update_ship_cnfrm_cur  
   
	UPDATE	tdc_master_pack_tbl  
	SET		status = 'X'  
	WHERE	pack_no IN (SELECT DISTINCT pack_no FROM tdc_master_pack_ctn_tbl(NOLOCK) WHERE carton_no IN (SELECT carton_no   
																										FROM #temp_ship_confirm_cartons))  
	AND		pack_no NOT IN(SELECT DISTINCT pack_no FROM tdc_master_pack_ctn_tbl a (NOLOCK), tdc_carton_tx b (NOLOCK) WHERE a.carton_no = b.carton_no AND b.status != 'X')  
  
	IF @eBackOfficeShip = 'Y'  
	BEGIN  
		IF NOT EXISTS(SELECT * FROM load_list(NOLOCK) WHERE order_no = @order_no AND order_ext = @order_ext)  
		BEGIN  
			EXEC @ret = tdc_validate_order_to_ship_sp @stage_no, @order_no, @order_ext, @order_type  
    
			IF @ret = 1   
				SELECT @ship_order_flg = 'Y'  
			ELSE  
				SELECT @ship_order_flg = 'N'  
   
			IF @ship_order_flg = 'Y'  
			BEGIN   
				--Set tdc_stage_carton ADM shipped flag to 'Y' and ADM ship date  
				UPDATE	tdc_stage_carton    
				SET		adm_ship_flag = 'Y', 
						adm_ship_date = GETDATE() - @alter_by  
				WHERE	carton_no IN(SELECT a.carton_no  
									FROM	tdc_stage_carton a (NOLOCK),  
											tdc_carton_tx b (NOLOCK) 
				WHERE	a.carton_no = b.carton_no  
				AND		b.order_no  = @order_no  
				AND		b.order_ext = @order_ext  
				AND		a.tdc_ship_flag = 'Y')  
     
				IF @@ERROR <> 0   
				BEGIN  
					-- v1.0 CLOSE tdc_update_ship_cnfrm_cur  
					-- v1.0 DEALLOCATE tdc_update_ship_cnfrm_cur  
					RAISERROR('update tdc_stage_carton failed', 16, 1)   
					RETURN -5  
				END     
    
				--Call the ship_order procedure  
				IF @order_type = 'S'  
				BEGIN  
		    
					TRUNCATE TABLE #adm_ship_order  
	    
					INSERT INTO #adm_ship_order (order_no, ext, who, err_msg)  
					VALUES (@order_no, @order_ext, @user_id, NULL)   
	     
					EXEC @ret = tdc_adm_ship_order @alter_by  
	  
					DELETE FROM tdc_pack_queue WHERE order_no = @order_no AND order_ext = @order_ext  
	    
				END  
				ELSE IF @order_type = 'T'  
				BEGIN  
					CREATE TABLE #dist_ship_verify_x (  
						xfer_no int NOT NULL,   
						method char (2) NOT NULL,   
						who varchar(50) NOT NULL,  
						err_msg varchar(255) NULL)  
		     
					TRUNCATE TABLE #dist_ship_verify_x  
	    
					INSERT INTO #dist_ship_verify_x (xfer_no,method, who, err_msg)  
					VALUES (@order_no,'01', @user_id,  NULL)   
		     
					EXEC @ret = tdc_ship_verify_xfer_sp  
	    
					UPDATE	xfer_list 
					SET		to_bin = 'IN TRANSIT'   
					WHERE	xfer_no = @order_no  
				END       
  
				DELETE FROM tdc_soft_alloc_tbl   
				WHERE	order_no = @order_no  
				AND		order_ext = @order_ext  
				AND		order_type = @order_type  
	    
				IF @order_type = 'S'  
				BEGIN  
					DELETE FROM tdc_pick_queue  
					WHERE	trans_type_no = @order_no  
					AND		trans_type_ext = @order_ext  
					AND		trans = 'STDPICK'  
				END  
				ELSE IF @order_type = 'T'  
				BEGIN  
					DELETE FROM tdc_pick_queue  
					WHERE	trans_type_no = @order_no  
					AND		trans_type_ext = 0  
					AND		trans = 'XFERPICK'  
				END  
	     
				--Backup order records  
				EXEC tdc_backup_order_records_sp @order_no, @order_ext     
			END  
		END  
		ELSE  
		BEGIN  
			-- IF order is in load_list, return success  
			SELECT @ship_order_flg = 'Y'  
		END  
	END --@eBackOfficeShip = 'Y'  
  
	--If success shipping, or not attempting to ship the order, return success  
	IF @ship_order_flg = 'Y' OR @eBackOfficeShip = 'N'  
		SELECT @order_shipped = 'Y'  
	ELSE -- return not successful  
		SELECT @order_shipped = 'N'  

	RETURN 0  
END
GO
GRANT EXECUTE ON  [dbo].[tdc_do_ship_order_sp] TO [public]
GO
