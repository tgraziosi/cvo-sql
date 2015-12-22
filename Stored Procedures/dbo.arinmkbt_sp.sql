SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2001 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2001 Epicor Software Corporation, 2001    
                  All Rights Reserved                    
*/                                                






















































































































  



					  

























































 
































































































































































































































































































































                       























































































































































































































































































































































































		
CREATE PROCEDURE	[dbo].[arinmkbt_sp]	@process_ctrl_num	varchar(16),
								@company_code		varchar(8),
						   		@debug_level		smallint = 0
AS

BEGIN
	DECLARE		@process_user_id	smallint,
				@process_parent_app	smallint,
				@date_applied		int,
				@process_user_name	varchar(30),
				@source_batch_code	varchar(16),
				@result				int,
				@batch_code			varchar(16),
				@trx_type       	smallint,
				@batch_type     	smallint,
				@batch_proc_flag	smallint,
				@org_id 			varchar(30)	
	

	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arinmkbt.cpp" + ", line " + STR( 119, 5 ) + " -- ENTRY: "
	IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + "  " + "arinmkbt.cpp" + ", line " + STR( 120, 5 ) + " -- MSG: " + " Passed parameter: process_control_num = " + @process_ctrl_num
	IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + "  " + "arinmkbt.cpp" + ", line " + STR( 121, 5 ) + " -- MSG: " + " Passed parameter: company_code = " + @company_code

	


	SELECT @batch_proc_flag = batch_proc_flag 
	FROM arco

	IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + "  " + "arinmkbt.cpp" + ", line " + STR( 129, 5 ) + " -- MSG: " + "The batch processing flag is " + convert(char,@batch_proc_flag,5)

	



	IF ( @@trancount > 0 )
	BEGIN
		IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + "  " + "arinmkbt.cpp" + ", line " + STR( 137, 5 ) + " -- MSG: " + "Transaction has already been started"
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arinmkbt.cpp" + ", line " + STR( 138, 5 ) + " -- EXIT: "
		RETURN 32544
	END
	


	SELECT	@process_parent_app = process_parent_app,
			@process_user_id = process_user_id
	FROM	pcontrol_vw
	WHERE	process_ctrl_num = @process_ctrl_num
	
	IF ( @process_parent_app IS NULL )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arinmkbt.cpp" + ", line " + STR( 151, 5 ) + " -- EXIT: "
		RETURN	32545
	END
	
	


	IF NOT EXISTS(	SELECT	*
			FROM	glcomp_vw
			WHERE	company_code = @company_code )
			
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arinmkbt.cpp" + ", line " + STR( 163, 5 ) + " -- EXIT: "
		RETURN	32523
	END
	
	



	SELECT	DISTINCT
		date_applied 
,
		org_id
	INTO	#ar_batches
	FROM	arinpchg
	WHERE	process_group_num = @process_ctrl_num
	
	SELECT DISTINCT @trx_type = trx_type
	FROM	arinpchg
	WHERE	process_group_num = @process_ctrl_num
	
	WHILE 1=1
	BEGIN
		SELECT	@date_applied = NULL
		
		SELECT	@date_applied = MIN(date_applied),
				@org_id		  = MIN(org_id)
		FROM	#ar_batches
		GROUP BY org_id
				
		








		
		IF ( @date_applied IS NULL )
			break

		


		IF (@batch_proc_flag = 1 AND @trx_type != 2051)
		BEGIN
			IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + "  " + "arinmkbt.cpp" + ", line " + STR( 210, 5 ) + " -- MSG: " + "Beginning Transaction"
			BEGIN TRAN

			UPDATE	batchctl
			SET	process_group_num = @process_ctrl_num,
			    posted_flag = -1
			FROM batchctl a, arinpchg b
			WHERE	a.batch_ctrl_num = b.batch_code
			AND b.process_group_num = @process_ctrl_num

			DELETE	#ar_batches
			WHERE	date_applied = @date_applied
			AND		org_id 		 = @org_id
	
			IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + "  " + "arinmkbt.cpp" + ", line " + STR( 224, 5 ) + " -- MSG: " + "Commiting Transaction"
			COMMIT TRAN
			
			CONTINUE
		END

		if (@trx_type = 2031)
		    SELECT @batch_type = 2010
		else if (@trx_type = 2021)
		    SELECT @batch_type = 2020
		else if (@trx_type = 2032)
		    SELECT @batch_type = 2030
		else if (@trx_type = 2051)
		    SELECT @batch_type = 2040
	
	
	
		EXEC @result = arnxtbat_sp	2000,
		                		"",
				  		@batch_type,
				  		@process_user_id,
						@date_applied,
						@company_code,
						@batch_code	OUTPUT,
						0,
						@org_id 

		IF ( @result != 0 )
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arinmkbt.cpp" + ", line " + STR( 253, 5 ) + " -- EXIT: "
			RETURN	32502
		END
		
		IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + "  " + "arinmkbt.cpp" + ", line " + STR( 257, 5 ) + " -- MSG: " + "Beginning Transaction"
		BEGIN TRAN

		



		UPDATE	batchctl
		SET	process_group_num = @process_ctrl_num,
		    	posted_flag = -1
		WHERE	batch_ctrl_num = @batch_code

		



		SET ROWCOUNT 250
		UPDATE	arinpchg
		SET	batch_code = @batch_code
		WHERE	date_applied = @date_applied
		AND org_id = @org_id
		AND	process_group_num = @process_ctrl_num
		AND	( LTRIM(batch_code) IS NULL OR LTRIM(batch_code) = " " )
		
		SET ROWCOUNT 0
		
		IF EXISTS (	SELECT	1
				FROM	arinpchg
				WHERE	date_applied = @date_applied
				AND 	org_id		 = @org_id
				AND	process_group_num = @process_ctrl_num
				AND	( LTRIM(batch_code) IS NULL OR LTRIM(batch_code) = " " ) )
		BEGIN
			SELECT	@date_applied = @date_applied
		END
		ELSE
		BEGIN
			DELETE	#ar_batches
			WHERE	date_applied = @date_applied
			AND		org_id 		 = @org_id
		END
		
		IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + "  " + "arinmkbt.cpp" + ", line " + STR( 299, 5 ) + " -- MSG: " + "Commiting Transaction"
		COMMIT TRAN

	END
	
	DROP TABLE	#ar_batches
	
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arinmkbt.cpp" + ", line " + STR( 306, 5 ) + " -- EXIT: "
	RETURN 0
	
	rollback_tran:
	IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + "  " + "arinmkbt.cpp" + ", line " + STR( 310, 5 ) + " -- MSG: " + "Rolling Back transaction"
	ROLLBACK TRAN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arinmkbt.cpp" + ", line " + STR( 312, 5 ) + " -- EXIT: "
	RETURN	32502
END
/**/                                              
GO
GRANT EXECUTE ON  [dbo].[arinmkbt_sp] TO [public]
GO
