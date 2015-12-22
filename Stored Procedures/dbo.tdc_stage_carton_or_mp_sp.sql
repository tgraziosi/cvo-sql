SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- v1.1 CT 11/07/12 - Write tdc_log record
-- v1.2 CT 17/07/12 - Add order number to stage carton
-- v1.3	CT 18/07/12 - Store order number in tran_no field

CREATE PROC [dbo].[tdc_stage_carton_or_mp_sp]
	@carton_or_pack int,
	@stage_no  	varchar(11),
	@cube_active	int,
	@station_id	varchar(3),
	@user_id	varchar(50),	
	@err_msg	varchar(255) OUTPUT
AS

	DECLARE @IsMasterPack	SMALLINT,	-- v1.1
			@Order_No		VARCHAR(10),-- v1.3
			@Order_Ext		VARCHAR(3)	-- v1.3

	-- v1.1
	SET @IsMasterPack = 0 -- False

	IF NOT EXISTS(SELECT carton_no FROM tdc_carton_tx (NOLOCK) 
		       WHERE Carton_No = @carton_or_pack
		       UNION 
		      SELECT pack_no FROM tdc_master_pack_tbl(NOLOCK)
		       WHERE pack_no = @carton_or_pack)
	BEGIN
		SELECT @err_msg = 'Invalid Carton/Pack Number'
		RETURN -1
	END

	--Make sure carton is not in stage to load   
	IF (SELECT active FROM tdc_config(NOLOCK) WHERE [function] = 'stage_to_load_flag') = 'Y' 
	BEGIN
		IF EXISTS(SELECT * FROM tdc_carton_tx (NOLOCK)  
	                        WHERE carton_no = @carton_or_pack
				AND ISNULL(stlbin_no,'') <> '')
		BEGIN
			SELECT @err_msg = 'Cannot stage a carton in a Stage To Load bin.'
			RETURN -2
		END
	END

	IF EXISTS(SELECT * FROM tdc_master_pack_ctn_tbl(NOLOCK)
		   WHERE carton_no = @carton_or_pack)
	BEGIN
		SELECT @err_msg = 'Cannot stage a carton in a master-pack'
		RETURN -3
	END

	IF EXISTS(SELECT * FROM tdc_config WHERE [function] = 'manifest_type' AND active = 'Y')
	AND EXISTS(SELECT * FROM tdc_pack_station_tbl(NOLOCK) WHERE station_id = @station_id AND manifest_enabled = 'Y')
	BEGIN
		--check to see if there are cartons shipped from tdc system
		IF EXISTS(SELECT * FROM tdc_carton_tx
			  WHERE carton_no = @carton_or_pack
			    AND status != 'F')
		BEGIN
			SELECT @err_msg = 'Carton must be status ''Freighted'''
			RETURN -4
		END
	END
	ELSE
	BEGIN
		--check to see if there are cartons shipped from tdc system
		IF EXISTS(SELECT * FROM tdc_carton_tx
			  WHERE carton_no = @carton_or_pack
			    AND status NOT IN ('C', 'F'))
		BEGIN
			SELECT @err_msg = 'Carton must be status ''Closed'''
			RETURN -5
		END
	END

	IF NOT EXISTS(SELECT * FROM tdc_master_pack_tbl(NOLOCK)
		       WHERE pack_no = @carton_or_pack)
	BEGIN
        
		UPDATE tdc_carton_tx SET status = 'S'
	        	WHERE carton_no = @carton_or_pack
		IF (@@ERROR <> 0)
			BEGIN
				SELECT @err_msg = 'Critical error during unstage'
				RETURN -1
			END
	
		UPDATE tdc_carton_detail_tx  
	        	SET status = 'S' 
	        	WHERE carton_no = @carton_or_pack
	
		IF (@@ERROR <> 0)
			BEGIN
				SELECT @err_msg = 'Critical error during unstage'
				RETURN -1
			END
	
		UPDATE tdc_dist_group  
	        	SET status = 'S' 
	        	WHERE parent_serial_no = @carton_or_pack
	
		IF (@@ERROR <> 0)
			BEGIN
				SELECT @err_msg = 'Critical error during unstage'
				RETURN -1
			END
	
	
		INSERT INTO tdc_stage_carton(carton_no, stage_no, tdc_ship_flag, adm_ship_flag, tdc_ship_date, adm_ship_date, stage_error, master_pack)
		VALUES(@carton_or_pack, @stage_no, 'N', 'N', NULL, NULL, NULL, 'N')

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

		
--		if @cube_active = 1
--		BEGIN
			-- added 8-20-01 by Trevor Emond.  Analysis Services Logging
--			INSERT INTO tdc_ei_performance_log (stationid, userid, trans_source, module, trans, beginning,  carton_no, tran_no, tran_ext) 
--										SELECT @station_id, @user_id, 'VB', 	'PPS', 'Stage Carton', 1, @carton_or_pack, order_no, order_ext				 
--										  FROM tdc_carton_tx (NOLOCK)
--										 WHERE carton_No = @carton_or_pack
--		END
	END
	ELSE --Master pack
	BEGIN
		-- v1.1
		SET @IsMasterPack = 1 -- True

		UPDATE tdc_master_pack_tbl 
		   SET status = 'S'
		 WHERE pack_no = @carton_or_pack

		INSERT INTO tdc_stage_carton(carton_no, stage_no, tdc_ship_flag, adm_ship_flag, tdc_ship_date, adm_ship_date, stage_error, master_pack)
		SELECT carton_no, @stage_no, 'N', 'N', NULL, NULL, NULL, 'Y'
		  FROM tdc_master_pack_ctn_tbl(NOLOCK)
		 WHERE pack_no = @carton_or_pack

		UPDATE tdc_carton_tx 
		   SET status = 'S'
		 WHERE carton_no IN(SELECT carton_no 
				      FROM tdc_master_pack_ctn_tbl(NOLOCK)
				     WHERE pack_no = @carton_or_pack)
		
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


--		if @cube_active = 1
--		BEGIN
			-- added 8-20-01 by Trevor Emond.  Analysis Services Logging
--			INSERT INTO tdc_ei_performance_log (stationid, userid, trans_source, module, trans, beginning,  carton_no, tran_no, tran_ext) 
--									SELECT distinct @station_id, @user_id, 'VB', 	'PPS', 'Stage Carton', 1, @carton_or_pack, order_no, order_ext				 
--									  FROM tdc_carton_tx (NOLOCK)
--									 WHERE carton_no in (SELECT carton_no FROM tdc_master_pack_ctn_tbl (nolock) WHERE pack_no = @carton_or_pack )
--		END
	END

	-- v1.2 - Get order number
	IF @IsMasterPack = 0
	BEGIN
		SELECT TOP 1
			@Order_No = CAST(order_no AS VARCHAR(10)),
			@Order_Ext = CAST(order_ext AS VARCHAR(3))
		FROM
			dbo.tdc_carton_tx
		WHERE 
			carton_no = @carton_or_pack
		ORDER BY 
			order_no, order_ext
	END

	-- v1.1 - Write to tdc_log
	INSERT INTO tdc_log (
		tran_date, 
		trans, 
		UserID, 
		trans_source, 
		module, 
		data, 
		tran_no,
		tran_ext, 
		part_no, 
		lot_ser, 
		bin_no,
		quantity,
		location )
	SELECT 
		getdate(),  
		CASE @IsMasterPack WHEN  1 THEN 'Stage MasterPack' ELSE 'Stage Carton' END,  
		@user_id,
		'VB',
		'PPS',
		'Carton: ' + ISNULL(CAST(@carton_or_pack AS VARCHAR(10)),'') + '; Station: ' + ISNULL(@station_id,''), 
		ISNULL(@Order_No,''),	-- v1.3
		ISNULL(@Order_Ext,''),	-- v1.3
		'', 
		'', 
		'', 
		'', 
		''
	       
RETURN 0

GO
GRANT EXECUTE ON  [dbo].[tdc_stage_carton_or_mp_sp] TO [public]
GO
