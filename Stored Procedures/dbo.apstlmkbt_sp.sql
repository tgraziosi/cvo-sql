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











































  



					  

























































 
































































































































































































































































































































































































































































































































































































































































































                       

























































































		
CREATE PROCEDURE	[dbo].[apstlmkbt_sp] 
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
			@settlement_ctrl_num	varchar(16),
			@org_id		varchar(30)
	

	IF (@debug > 0)
	   SELECT "Entering apstlmkbt_sp"


	



	IF ( @@trancount > 0 )
	BEGIN
		return -1
	END


	


	SELECT @batch_proc_flag = batch_proc_flag 
	FROM apco

	


	SELECT	@process_parent_app = process_parent_app,
		@process_user_id = process_user_id
	FROM	pcontrol_vw
	WHERE	process_ctrl_num = @process_ctrl_num
	
	
	


	SELECT	DISTINCT
		settlement_ctrl_num,
		date_applied,
		org_id
	INTO	#apbatches
	FROM	apinpstl
	WHERE	process_group_num = @process_ctrl_num
	
	BEGIN TRAN

	WHILE 1=1
	BEGIN
		SELECT	@settlement_ctrl_num = NULL
		
		SELECT	@settlement_ctrl_num = MIN( settlement_ctrl_num),
			@org_id	= MIN (org_id)
		FROM	#apbatches
		
		IF ( @settlement_ctrl_num IS NULL )
			break
			

		


		IF (@batch_proc_flag = 1)
		BEGIN
			UPDATE	batchctl
			SET	process_group_num = @process_ctrl_num,
				posted_flag = -1
			FROM batchctl a, apinpstl b
			WHERE	a.batch_ctrl_num = b.batch_code
			AND b.process_group_num = @process_ctrl_num

			DELETE	#apbatches
			WHERE	settlement_ctrl_num = @settlement_ctrl_num
			AND org_id = @org_id


			CONTINUE
		END

		


		SELECT @date_applied = date_applied
		FROM	#apbatches
		WHERE	settlement_ctrl_num = @settlement_ctrl_num

		SELECT @batch_type = 4070
		SELECT @batch_code = NULL
	
		EXEC	@result = apnxtbat_sp	
		                4000,
		                "",
				@batch_type,
				@process_user_id,
				@date_applied,
				@company_code,
				@batch_code	OUTPUT,
				NULL,
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

		


		UPDATE	apinpstl
		SET	batch_code = @batch_code
		WHERE	settlement_ctrl_num = @settlement_ctrl_num
		AND	process_group_num = @process_ctrl_num
		AND ( LTRIM(batch_code) IS NULL OR LTRIM(batch_code) = " " )
		AND org_id = @org_id

		



		SET ROWCOUNT 250
		UPDATE	apinppyt
		SET	batch_code = @batch_code
		WHERE	settlement_ctrl_num = @settlement_ctrl_num
		AND	process_group_num = @process_ctrl_num
		AND ( LTRIM(batch_code) IS NULL OR LTRIM(batch_code) = " " )
		AND org_id = @org_id

		IF ( @@error != 0 )
			goto rollback_tran
		SET ROWCOUNT 0

		DELETE	#apbatches
		WHERE	settlement_ctrl_num = @settlement_ctrl_num
		AND org_id = @org_id
		
	END
	
	COMMIT TRAN

	DROP TABLE	#apbatches
	
	IF (@debug > 0)
	   SELECT "Exiting apstlmkbt_sp"

	RETURN 0
	
	rollback_tran:
	ROLLBACK TRAN
	SET ROWCOUNT 0
	RETURN	-1
END
/**/                                              
GO
GRANT EXECUTE ON  [dbo].[apstlmkbt_sp] TO [public]
GO
