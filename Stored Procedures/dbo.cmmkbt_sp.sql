SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2001 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2001 Epicor Software Corporation, 2001    
                  All Rights Reserved                    
*/                                                































































  



					  

























































 













































































































































































































































































































































































































































































































































































































































































































                       









































		
CREATE PROCEDURE	[dbo].[cmmkbt_sp] 
			@process_ctrl_num	varchar(16),
			@company_code		varchar(8),
   			@debug			smallint = 0
AS

BEGIN
	DECLARE		@process_user_id	smallint,
			@process_parent_app	smallint,
			@date_applied		int,
			@process_user_name	varchar(30),
			@source_batch_code	varchar(16),
			@result			int,
			@batch_code		varchar(16),
			@trx_type       smallint,
			@batch_type     smallint,
			@batch_proc_flag smallint,
			@org_id			varchar(30)
	

	IF (@debug > 0)
	   SELECT "Entering cmmkbt_sp"

	


	SELECT @batch_proc_flag = batch_proc_flag 
	FROM cmco



	



	IF ( @@trancount > 0 )
	BEGIN
		return -1
	END
	


	SELECT	@process_parent_app = process_parent_app,
		@process_user_id = process_user_id
	FROM	pcontrol_vw
	WHERE	process_ctrl_num = @process_ctrl_num
	
	
	



	SELECT	DISTINCT
		date_applied,
		trx_type,
		org_id
	INTO	#cmbatches
	FROM	cmmanhdr
	WHERE	process_group_num = @process_ctrl_num
	
	BEGIN TRAN

	WHILE 1=1
	BEGIN
		SELECT	@date_applied = NULL
		
		SELECT	@date_applied = MIN( date_applied ),
		        @trx_type     = MIN(trx_type),					
				@org_id		  = MIN(org_id)
		FROM	#cmbatches
		GROUP BY date_applied, trx_type, org_id 


		IF ( @date_applied IS NULL )
			break
		

		


		IF (@batch_proc_flag = 1)
		BEGIN
			UPDATE	batchctl
			SET	process_group_num = @process_ctrl_num,
			    posted_flag = -1
			FROM batchctl a, cmmanhdr b
			WHERE	a.batch_ctrl_num = b.batch_code
			AND b.process_group_num = @process_ctrl_num

			DELETE	#cmbatches
			WHERE	date_applied = @date_applied
			AND 	org_id = @org_id
	
			CONTINUE
		END



			
	    SELECT @batch_type = 7000
	
	
		SELECT @batch_code = NULL

		EXEC	@result = cmnxtbat_sp	
		                7000,
		                "",
						@batch_type,
						@process_user_id,
						@date_applied,
						@company_code,
						@batch_code	OUTPUT,
						@org_id 

		IF ( @result != 0 )
			goto rollback_tran


	IF (@debug > 0)
	   SELECT "Batch "+@batch_code+" created."

		



		UPDATE	batchctl
		SET	process_group_num = @process_ctrl_num,
		    posted_flag = -1
		WHERE	batch_ctrl_num = @batch_code

		IF ( @@error != 0 )
			goto rollback_tran
		



		SET ROWCOUNT 250
		UPDATE	cmmanhdr
		SET	batch_code = @batch_code
		WHERE	date_applied = @date_applied
		AND org_id = @org_id
		AND	process_group_num = @process_ctrl_num
		AND (LTRIM(batch_code) IS NULL
			 OR LTRIM(batch_code) = "")

		IF ( @@error != 0 )
			goto rollback_tran
		SET ROWCOUNT 0
			
		IF EXISTS (	SELECT	1
				FROM	cmmanhdr
				WHERE	date_applied = @date_applied
				AND org_id = @org_id
				AND	process_group_num = @process_ctrl_num
				AND (LTRIM(batch_code) IS NULL
					 OR LTRIM(batch_code) = ""))
		BEGIN
			SELECT	@date_applied = @date_applied
		END
		ELSE
		BEGIN
			DELETE	#cmbatches
			WHERE	date_applied = @date_applied
			AND 	org_id = @org_id
		END
		
	END
	
	COMMIT TRAN

	DROP TABLE	#cmbatches
	
    IF (@debug > 0)
	   SELECT "Exiting cmmkbt_sp"

	RETURN 0
	
	rollback_tran:
	ROLLBACK TRAN
	SET ROWCOUNT 0
	RETURN	-1
END
/**/                                              
GO
GRANT EXECUTE ON  [dbo].[cmmkbt_sp] TO [public]
GO
