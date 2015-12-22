SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

--SCR37080 by Jim on 5/9/07
--I rollbacked this change by putting back the station id. The correct sp need to be changed is tdc_unstage_multiple_cartons_sp.
CREATE PROCEDURE [dbo].[tdc_unstage_carton_or_mp_sp]
	@carton_or_pack	int,
	@station_id	varchar(20),
	@user_id	varchar(50),
	@cube_active 	int,
	@err_msg	varchar(255) OUTPUT
AS    

DECLARE @new_status char(1)

	IF EXISTS(SELECT * FROM tdc_config (NOLOCK)
		   WHERE [function] = 'manifest_type'
		     AND active = 'Y')
	BEGIN
		SELECT @new_status = 'F'
	END
	ELSE
		SELECT @new_status = 'C'

	IF NOT EXISTS(SELECT carton_no FROM tdc_carton_tx (NOLOCK) 
		       WHERE Carton_No = @carton_or_pack
		       UNION 
		      SELECT pack_no FROM tdc_master_pack_tbl(NOLOCK)
		       WHERE pack_no = @carton_or_pack)
	BEGIN
		SELECT @err_msg = 'Invalid Carton/Pack Number'
		RETURN -1
	END

	--CARTON PROCESSING
	IF NOT EXISTS(SELECT * FROM tdc_master_pack_tbl(NOLOCK)
		       WHERE pack_no = @carton_or_pack)
	BEGIN
		--CARTON
		--Make sure carton is not in stage to load   
		IF (SELECT active FROM tdc_config(NOLOCK) WHERE [function] = 'stage_to_load_flag') = 'Y' 
		BEGIN
			IF EXISTS(SELECT * FROM tdc_carton_tx (NOLOCK)  
		                        WHERE carton_no = @carton_or_pack
					AND ISNULL(stlbin_no,'') <> '')
			BEGIN
				SELECT @err_msg = 'Cannot unstage a carton in a Stage To Load bin.'
				RETURN -2
			END
		END
		--CARTON
		--check to see if there are cartons shipped from tdc system
		IF EXISTS(SELECT * FROM tdc_carton_tx
			  WHERE carton_no = @carton_or_pack
			    AND status != 'S')
		BEGIN
			SELECT @err_msg = 'Carton must be status ''Staged'''
			RETURN -4
		END

        
		UPDATE tdc_carton_tx SET status = @new_status
	        	WHERE carton_no = @carton_or_pack
		IF (@@ERROR <> 0)
			BEGIN
				SELECT @err_msg = 'Critical error during unstage'
				RETURN -1
			END
	
		UPDATE tdc_carton_detail_tx  
	        	SET status = @new_status 
	        	WHERE carton_no = @carton_or_pack
	
		IF (@@ERROR <> 0)
			BEGIN
				SELECT @err_msg = 'Critical error during unstage'
				RETURN -1
			END
	
		UPDATE tdc_dist_group  
	        	SET status = @new_status 
	        	WHERE parent_serial_no = @carton_or_pack
	
		IF (@@ERROR <> 0)
			BEGIN
				SELECT @err_msg = 'Critical error during unstage'
				RETURN -1
			END
	
	
		DELETE FROM tdc_stage_carton  
	        	WHERE carton_no = @carton_or_pack
		
--		IF @cube_active = 1
--		BEGIN
			-- added 8-20-01 by Trevor Emond.  Analysis Services Logging
--			INSERT INTO tdc_ei_performance_log (stationid, userid, trans_source, module, trans, beginning, carton_no, tran_no, tran_ext) 
--										SELECT @station_id, @user_id, 'VB', 	'PPS', 'UnStage Carton', 1, @carton_or_pack, order_no, order_ext 
--										  FROM tdc_carton_tx (NOLOCK)
--										 WHERE carton_No = @carton_or_pack
--		END
	END
	ELSE --MASTER PACK PROCESSING
	BEGIN

		--MASTER PACK
		--Make sure carton is not in stage to load   
		IF (SELECT active FROM tdc_config(NOLOCK) WHERE [function] = 'stage_to_load_flag') = 'Y' 
		BEGIN
			--USE THE CARTON_OR_PACK TO GET THE CARTONS ASSIGNED TO THE MASTERPACK
			IF EXISTS(SELECT * FROM tdc_carton_tx (NOLOCK)  
		                        WHERE carton_no IN (SELECT carton_no FROM tdc_master_pack_ctn_tbl WHERE pack_no = @carton_or_pack)
					AND ISNULL(stlbin_no,'') <> '')
			BEGIN
				SELECT @err_msg = 'Cannot unstage a Master Pack in a Stage To Load bin.'
				RETURN -2
			END
		END

		--MASTER PACK
		--check to see if there are cartons shipped from tdc system
		IF EXISTS(SELECT * FROM tdc_carton_tx
			  WHERE carton_no IN(SELECT carton_no 
					      FROM tdc_master_pack_ctn_tbl(NOLOCK)
					     WHERE pack_no = @carton_or_pack)
			    AND status != 'S')
		BEGIN
			SELECT @err_msg = 'Master Pack must be status ''Staged'''
			RETURN -4
		END

		--** NOTE TO DEVELOPER **
		--RECORDS IN THE FOLLOWING TABLES DON'T EXIST FOR MASTER_PACKS, THEY ARE ONLY FOR CARTON'S
			--tdc_carton_detail_tx
			--tdc_dist_group

		UPDATE tdc_master_pack_tbl 
		   SET status = @new_status
		 WHERE pack_no = @carton_or_pack

		UPDATE tdc_carton_tx 
		   SET status = @new_status
		 WHERE carton_no IN(SELECT carton_no 
				      FROM tdc_master_pack_ctn_tbl(NOLOCK)
				     WHERE pack_no = @carton_or_pack)

		DELETE FROM tdc_stage_carton  
	        	WHERE carton_no IN(SELECT carton_no FROM tdc_master_pack_ctn_tbl(NOLOCK)
					    WHERE pack_no = @carton_or_pack)

--		IF @cube_active = 1
--		BEGIN
			-- added 8-20-01 by Trevor Emond.  Analysis Services Logging
--			INSERT INTO tdc_ei_performance_log (stationid, userid, trans_source, module, trans, beginning,  carton_no, tran_no, tran_ext) 
--									SELECT distinct @station_id, @user_id, 'VB', 	'PPS', 'UnStage Carton', 1, @carton_or_pack, order_no, order_ext				 
--									  FROM tdc_carton_tx (NOLOCK)
--									 WHERE carton_no in (SELECT carton_no FROM tdc_master_pack_ctn_tbl (nolock) WHERE pack_no = @carton_or_pack)
--		END
	END
	       
RETURN 0

GO
GRANT EXECUTE ON  [dbo].[tdc_unstage_carton_or_mp_sp] TO [public]
GO
