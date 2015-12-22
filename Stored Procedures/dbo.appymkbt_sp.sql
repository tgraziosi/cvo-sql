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
































































































  



					  

























































 
































































































































































































































































































































































































































































































































































































































































































                       























































































		
CREATE PROCEDURE	[dbo].[appymkbt_sp] 
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
			@org_id 			varchar(30)
	

	IF (@debug > 0)
	   SELECT "Entering appymkbt_sp"


	



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
		date_applied,
		trx_type,
		org_id
	INTO	#apbatches
	FROM	apinppyt
	WHERE	process_group_num = @process_ctrl_num
	
	BEGIN TRAN

	WHILE 1=1
	BEGIN
		SELECT	@date_applied = NULL
		
		SELECT	@date_applied = MIN( date_applied ),
		        @trx_type     = MIN(trx_type),					
				@org_id		  = MIN(org_id)
		FROM	#apbatches
		GROUP BY date_applied, trx_type, org_id
		
		IF ( @date_applied IS NULL )
			break
			

		


		IF (@batch_proc_flag = 1 AND @trx_type != 4112)
		BEGIN
			UPDATE	batchctl
			SET	process_group_num = @process_ctrl_num,
				posted_flag = -1
			FROM batchctl a, apinppyt b
			WHERE	a.batch_ctrl_num = b.batch_code
			AND b.process_group_num = @process_ctrl_num
	
			DELETE	#apbatches
			WHERE	date_applied = @date_applied
			AND org_id = @org_id
	
			CONTINUE
		END




		if (@trx_type IN (4111,4011))
		    SELECT @batch_type = 4040
		else if (@trx_type = 4112)
		    SELECT @batch_type = 4060

	
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
		



		SET ROWCOUNT 250
		UPDATE	apinppyt
		SET	batch_code = @batch_code
		WHERE	date_applied = @date_applied
		AND 	org_id = @org_id	
		AND	process_group_num = @process_ctrl_num
		AND ( LTRIM(batch_code) IS NULL OR LTRIM(batch_code) = " " )

		IF ( @@error != 0 )
			goto rollback_tran
		SET ROWCOUNT 0

		IF EXISTS (	SELECT	1
				FROM	apinppyt
				WHERE	date_applied = @date_applied
				AND 	org_id = @org_id	
				AND	process_group_num = @process_ctrl_num
				AND	( LTRIM(batch_code) IS NULL OR LTRIM(batch_code) = " " ))
		BEGIN
			SELECT	@date_applied = @date_applied
		END
		ELSE
		BEGIN
			DELETE	#apbatches
			WHERE	date_applied = @date_applied
			AND 	org_id = @org_id	
		END
		
		
	END
	
	COMMIT TRAN

	DROP TABLE	#apbatches
	
	IF (@debug > 0)
	   SELECT "Exiting appymkbt_sp"

	RETURN 0
	
	rollback_tran:
	ROLLBACK TRAN
	SET ROWCOUNT 0
	RETURN	-1
END
/**/                                              
GO
GRANT EXECUTE ON  [dbo].[appymkbt_sp] TO [public]
GO
