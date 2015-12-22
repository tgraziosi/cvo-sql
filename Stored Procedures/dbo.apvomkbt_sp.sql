SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2009 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2009 Epicor Software Corporation, 2009    
                  All Rights Reserved                    
*/                                                







































































































  



					  

























































 














































































































































































































































































































































































































































































































































































































































































































                       


























































































		
CREATE PROCEDURE	[dbo].[apvomkbt_sp] 
			@process_ctrl_num	varchar(16),
			@company_code		varchar(8),
   			@debug			smallint = 0
AS

BEGIN
	DECLARE		@start_user_id	smallint,
			@process_parent_app	smallint,
			@date_applied		int,
			@source_batch_code	varchar(16),
			@result			int,
			@batch_code		varchar(16),
			@trx_type       smallint,
			@batch_type     smallint,
			@batch_proc_flag smallint,
			@org_id			varchar(30),
			@intercompany_flag smallint,	
			@group_num int
	

	IF ( @debug > 0 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvomkbt.cpp" + ", line " + STR( 39, 5 ) + " -- ENTRY: "	

	


	SELECT @batch_proc_flag = batch_proc_flag 
	FROM apco



	



	IF ( @@trancount > 0 )
	BEGIN
		return -1
	END
	


	SELECT	@process_parent_app = process_parent_app
	FROM	pcontrol_vw
	WHERE	process_ctrl_num = @process_ctrl_num
	
	
	CREATE TABLE #apbatches (date_applied	int, trx_type smallint, org_id	varchar(30), intercompany_flag smallint, group_num int)
	CREATE TABLE #trx_group_temp 
		(trx_ctrl_num varchar(16), 
		trx_type smallint,
		date_applied	int,
		hdr_org_id	varchar(30),
		rec_company_code varchar(8),
		det_org_id	varchar(30),
		ind_grp_trx int,
		total_det_trx int,
		total_org_trx int,
		ind_record int,
		group_num int)

	INSERT #apbatches (date_applied, trx_type, org_id, intercompany_flag)
	SELECT	DISTINCT
		date_applied,
		trx_type,
		org_id,
		intercompany_flag									
	FROM	apinpchg
WHERE	process_group_num = @process_ctrl_num
	AND NOT ((trx_type = 4091 AND intercompany_flag = 1)
	OR (trx_type = 4092 AND intercompany_flag = 1)
	OR (trx_type = 4021 AND intercompany_flag = 1))
	
	DECLARE @inter_comp_trx INT
	SET @group_num = 0
	SET @inter_comp_trx = 0

	UPDATE #apbatches 
		SET group_num = @group_num,
		@group_num = @group_num + 1	

	
		
	IF EXISTS (SELECT trx_ctrl_num 
				FROM apinpchg 
				WHERE	process_group_num = @process_ctrl_num 
					--AND trx_type = 4091
					AND intercompany_flag = 1)
	BEGIN

		IF ( @debug > 0 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvomkbt.cpp" + ", line " + STR( 39, 5 ) + " -- ENTRING NEW PROCESS: "

		DECLARE @num_group_temp TABLE 
			(date_applied	int,
			hdr_org_id	varchar(30),
			rec_company_code varchar(8),
			det_org_id	varchar(30),
			group_num int identity(1,1))

		
		SELECT DISTINCT HDR.trx_ctrl_num,
				COUNT(DET.trx_ctrl_num) AS 'count'
		INTO #trx_group_dtl
		FROM	apinpchg HDR
			INNER JOIN apinpcdt DET ON HDR.trx_ctrl_num = DET.trx_ctrl_num
		WHERE	HDR.process_group_num = @process_ctrl_num
				--AND HDR.trx_type = 4091
				AND HDR.intercompany_flag = 1
		GROUP BY HDR.trx_ctrl_num

		
		INSERT #trx_group_temp 	(trx_ctrl_num, trx_type, date_applied, hdr_org_id, rec_company_code, det_org_id, ind_grp_trx, total_det_trx, ind_record)
		SELECT DISTINCT HDR.trx_ctrl_num,
				HDR.trx_type,
				HDR.date_applied,
				HDR.org_id,
				DET.rec_company_code,
				DET.org_id,
				COUNT(DET.trx_ctrl_num),
				CNT.count,
				(CASE WHEN COUNT(DET.trx_ctrl_num) = CNT.count THEN 1 ELSE 0 END)
		FROM	apinpchg HDR
			INNER JOIN apinpcdt DET ON HDR.trx_ctrl_num = DET.trx_ctrl_num
			INNER JOIN #trx_group_dtl CNT ON HDR.trx_ctrl_num = CNT.trx_ctrl_num
		WHERE	HDR.process_group_num = @process_ctrl_num
				--AND HDR.trx_type = 4091
				AND HDR.intercompany_flag = 1
		GROUP BY HDR.trx_ctrl_num, HDR.trx_type, HDR.date_applied, HDR.org_id, DET.rec_company_code, DET.org_id, DET.trx_ctrl_num, CNT.count

		
		UPDATE GRP
			SET GRP.total_org_trx = (SELECT DISTINCT COUNT(CNT.rec_company_code) FROM #trx_group_temp CNT WHERE CNT.trx_ctrl_num = GRP.trx_ctrl_num)
		FROM #trx_group_temp GRP

		
	
		DECLARE @key_table VARCHAR(16)
		SET @key_table = ''

		SELECT  @key_table = MIN(trx_ctrl_num)
		FROM    #trx_group_temp
		WHERE   trx_ctrl_num > @key_table
			AND group_num IS NULL

		DECLARE @group_trx TABLE (trx_ctrl_num_hdr varchar(16), trx_ctrl_num_det varchar(16))
		DECLARE @mismatch_trx TABLE (trx_ctrl_num varchar(16))
		DECLARE	@trx_group_temp_ind TABLE (trx_ctrl_num varchar(16), date_applied int, hdr_org_id varchar(30), rec_company_code varchar(8),	det_org_id	varchar(30), ind_grp_trx int,	total_det_trx int, total_org_trx int, ind_record int, group_num int)

		WHILE @key_table IS NOT NULL
		BEGIN
			DELETE @trx_group_temp_ind
			DELETE @mismatch_trx

			SET @group_num = @group_num + 1

			UPDATE TEMP
				SET group_num = @group_num
			FROM #trx_group_temp TEMP
			WHERE trx_ctrl_num = @key_table

			
			
			INSERT @trx_group_temp_ind (trx_ctrl_num, date_applied, hdr_org_id, rec_company_code, det_org_id, ind_grp_trx,	total_det_trx, total_org_trx, ind_record, group_num)
			SELECT trx_ctrl_num, date_applied, hdr_org_id, rec_company_code, det_org_id, ind_grp_trx, total_det_trx, total_org_trx, ind_record, group_num
			FROM #trx_group_temp
			WHERE trx_ctrl_num = @key_table

			
			WHILE 1=1
			BEGIN 
				DELETE @group_trx

				
				INSERT INTO @group_trx (trx_ctrl_num_hdr, trx_ctrl_num_det)
				SELECT DISTINCT IND.trx_ctrl_num, TEMP.trx_ctrl_num
				FROM @trx_group_temp_ind IND
					LEFT OUTER JOIN #trx_group_temp TEMP ON IND.date_applied = TEMP.date_applied AND IND.hdr_org_id = TEMP.hdr_org_id AND IND.rec_company_code = TEMP.rec_company_code AND IND.det_org_id = TEMP.det_org_id AND IND.total_org_trx = TEMP.total_org_trx AND NOT (IND.trx_ctrl_num = TEMP.trx_ctrl_num)
					LEFT JOIN @mismatch_trx MMT ON NOT TEMP.trx_ctrl_num = MMT.trx_ctrl_num
				WHERE NOT TEMP.trx_ctrl_num IS NULL
					AND MMT.trx_ctrl_num IS NULL
					AND TEMP.group_num IS NULL
				
				
				INSERT @mismatch_trx (trx_ctrl_num)
				SELECT DISTINCT GRP.trx_ctrl_num_det
				FROM @trx_group_temp_ind TEMP
					INNER JOIN @group_trx GRP ON TEMP.trx_ctrl_num = GRP.trx_ctrl_num_hdr
					LEFT JOIN #trx_group_temp TEMP2 ON GRP.trx_ctrl_num_det = TEMP2.trx_ctrl_num AND TEMP.rec_company_code = TEMP2.rec_company_code AND TEMP.det_org_id = TEMP2.det_org_id
				WHERE TEMP2.rec_company_code IS NULL AND TEMP2.det_org_id IS NULL

				IF (@@rowcount = 0)
				BEGIN
					IF ( @debug > 0 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvomkbt.cpp" + ", line " + STR( 39, 5 ) + " -- INTERCOMPANY GROUP GENERATED: " + CAST(@group_num AS VARCHAR)

					
					UPDATE TEMP
						SET group_num = @group_num
					FROM #trx_group_temp TEMP
						INNER JOIN @group_trx GRP ON TEMP.trx_ctrl_num = GRP.trx_ctrl_num_det				

					BREAK
				END

			END

			
			SELECT  @key_table = MIN(trx_ctrl_num)
			FROM    #trx_group_temp
			WHERE   trx_ctrl_num > @key_table
				AND group_num IS NULL
		END
		
		IF ( @debug > 0 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvomkbt.cpp" + ", line " + STR( 39, 5 ) + " -- GENERATING GROUPS FOR LEFT TRANSACTIONS: "

		
		UPDATE TEMP
			SET TEMP.group_num = @group_num,
			@group_num = @group_num + 1
		FROM #trx_group_temp TEMP	
		WHERE group_num IS NULL

		IF ( @debug > 0 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvomkbt.cpp" + ", line " + STR( 39, 5 ) + " -- UPDATING APBATCHES WITH GROUPS GENERATED: "

		INSERT #apbatches (date_applied, trx_type, org_id, intercompany_flag, group_num)
		SELECT DISTINCT date_applied, trx_type, hdr_org_id, 1, group_num
		FROM #trx_group_temp
		GROUP BY group_num, trx_type, date_applied, hdr_org_id
		
		DROP TABLE #trx_group_dtl

		IF ( @debug > 0 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvomkbt.cpp" + ", line " + STR( 39, 5 ) + " -- EXIT NEW PROCESS: "	

	END

	
	

	IF ( @debug > 0 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvomkbt.cpp" + ", line " + STR( 39, 5 ) + " -- START TO GENERATE BATCH RECORDS: "	

	
	BEGIN TRAN

	DECLARE @key_group INT
	SET @key_group = 0

	SELECT  @key_group = MIN(group_num)
	FROM    #apbatches
	WHERE   group_num > @key_group

	WHILE NOT @key_group IS NULL
	BEGIN
	
		IF ( @debug > 0 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvomkbt.cpp" + ", line " + STR( 39, 5 ) + " -- GET BATCH RECORD INFORMATION : "

		SELECT	@group_num			= group_num,
				@date_applied		= date_applied,
		        @trx_type			= trx_type,					
				@org_id 			= org_id,
				@intercompany_flag	= intercompany_flag
		FROM	#apbatches
		WHERE group_num = @key_group

		
		IF ( @debug > 0 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvomkbt.cpp" + ", line " + STR( 39, 5 ) + " -- UPDATE BATCHCTL : "

		


		IF (@batch_proc_flag = 1 AND @trx_type != 4021)
		BEGIN
			UPDATE	batchctl
			SET	process_group_num = @process_ctrl_num,
			    posted_flag = -1
			FROM batchctl a, apinpchg b
			WHERE	a.batch_ctrl_num = b.batch_code
			AND b.process_group_num = @process_ctrl_num

			


			SELECT @start_user_id = b.user_id
			FROM	batchctl a, ewusers_vw b
			WHERE	a.process_group_num = @process_ctrl_num
			AND	a.start_user = b.user_name

			
			DELETE	#apbatches
			WHERE	date_applied = @date_applied
			AND org_id = @org_id
			AND intercompany_flag = @intercompany_flag			
			AND group_num = @group_num	

			SELECT  @key_group = MIN(group_num)
			FROM    #apbatches
			WHERE   group_num > @key_group		

			CONTINUE
		END



			
		if (@trx_type = 4091)
		    SELECT @batch_type = 4010
		else if (@trx_type = 4092)
		    SELECT @batch_type = 4030
		else if (@trx_type = 4021)
		    SELECT @batch_type = 4050
	
	
	
		SELECT @batch_code = NULL

		EXEC	@result = apnxtbat_sp	
		                4000,
		                "",
						@batch_type,
						@start_user_id,
						@date_applied,
						@company_code,
						@batch_code	OUTPUT,
						NULL,
						@org_id 

		IF ( @result != 0 )
			goto rollback_tran


		IF ( @debug > 0 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvomkbt.cpp" + ", line " + STR( 39, 5 ) + " -- BATCH GENERATED : " + @batch_code + "	FOR GROUP : " + CAST(@group_num AS VARCHAR)


		IF ( @debug > 0 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvomkbt.cpp" + ", line " + STR( 39, 5 ) + " -- UPDATE BATCH RECORD WITH PROCESS CONTROL NUM : "

		



		UPDATE	batchctl
		SET	process_group_num = @process_ctrl_num,
		    posted_flag = -1
		WHERE	batch_ctrl_num = @batch_code

		IF ( @@error != 0 )
			goto rollback_tran

		IF ( @debug > 0 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvomkbt.cpp" + ", line " + STR( 39, 5 ) + " -- UPDATE RECORDS WITH NEW BATCH NUMBER GENERATED : "

		



		--SET ROWCOUNT 250
		IF (@intercompany_flag = 0)
		BEGIN
			UPDATE	apinpchg
			SET	batch_code = @batch_code
			WHERE	date_applied = @date_applied
			AND 	org_id = @org_id
			AND     intercompany_flag = @intercompany_flag									
			AND	process_group_num = @process_ctrl_num
			AND ( LTRIM(batch_code) IS NULL OR RTRIM(LTRIM(batch_code)) = '' )
		END
		ELSE
		BEGIN
			UPDATE	HDR
				SET	HDR.batch_code = @batch_code
			FROM apinpchg HDR
				INNER JOIN #trx_group_temp GRP ON HDR.trx_ctrl_num = GRP.trx_ctrl_num
			WHERE	HDR.date_applied = @date_applied
			AND 	HDR.org_id = @org_id
			AND     HDR.intercompany_flag = @intercompany_flag									
			AND	HDR.process_group_num = @process_ctrl_num
			AND ( LTRIM(HDR.batch_code) IS NULL OR RTRIM(LTRIM(HDR.batch_code)) = '' )
			AND GRP.group_num = @group_num
		END

		IF ( @@error != 0 )
			goto rollback_tran
		SET ROWCOUNT 0
			
		SELECT  @key_group = MIN(group_num)
		FROM    #apbatches
		WHERE   group_num > @key_group
		
	END
	
	IF ( @debug > 0 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvomkbt.cpp" + ", line " + STR( 39, 5 ) + " -- END TO GENERATE BATCH RECORDS: "	

	COMMIT TRAN

	DROP TABLE	#apbatches
	DROP TABLE #trx_group_temp
	
	IF ( @debug > 0 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvomkbt.cpp" + ", line " + STR( 39, 5 ) + " -- EXIT: "	


	RETURN 0
	
	rollback_tran:
	ROLLBACK TRAN
	SET ROWCOUNT 0
	RETURN	-1
END
/**/                                              
GO
GRANT EXECUTE ON  [dbo].[apvomkbt_sp] TO [public]
GO
