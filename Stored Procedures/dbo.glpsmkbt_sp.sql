SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2006 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2006 Epicor Software Corporation, 2006    
                  All Rights Reserved                    
*/                                                





















































































































  



					  

























































 














































































































































































































































































































                       

















































































































































































































































		
CREATE PROCEDURE	[dbo].[glpsmkbt_sp] 
			@process_ctrl_num	varchar(16),
			@company_code		varchar(8),
			@debug_level		smallint = 0
AS

BEGIN
	DECLARE		@process_user_id	smallint,
			@process_parent_app	smallint,
			@date_applied		int,
			@process_user_name	varchar(30),
			@source_batch_code	varchar(16),
			@result			int,
			@batch_code		varchar(16),
			@work_time		datetime,
			@org_id			varchar(30) 
	
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "glpsmkbt.cpp" + ", line " + STR( 88, 5 ) + " -- ENTRY: "
	SELECT	@work_time = getdate()
	



	IF ( @@trancount > 0 )
	BEGIN
		IF ( @debug_level > 0 )
			SELECT "*** ERROR: Transaction already started: "+
			       "@@trancount = "+convert( char(10), @@trancount )
		return 1052
	END
	


	SELECT	@process_parent_app = process_parent_app,
		@process_user_id = process_user_id
	FROM	pcontrol_vw
	WHERE	process_ctrl_num = @process_ctrl_num
	
	IF ( @process_parent_app IS NULL )
	BEGIN
		IF ( @debug_level > 0 )
			SELECT "*** ERROR: Parent application is invalid"
		RETURN	1053
	END
	
	


	IF NOT EXISTS(	SELECT	*
			FROM	glcomp_vw
			WHERE	company_code = @company_code )
	BEGIN
		IF ( @debug_level > 0 )
			SELECT "*** ERROR: Company code is invalid"
		RETURN		1005
	END
	
	



	SELECT	DISTINCT
		date_applied,
		source_batch_code,
		org_id 
	INTO	#batches
	FROM	gltrx
	WHERE	process_group_num = @process_ctrl_num
	AND	company_code = @company_code
	AND	posted_flag = -1
	
	BEGIN TRAN

	WHILE 1=1
	BEGIN
		SELECT	@date_applied = NULL
		
		SELECT	@date_applied = MIN( date_applied )
		FROM	#batches
		
		IF ( @date_applied IS NULL )
			break		
		
		
		SELECT  @source_batch_code = MIN( source_batch_code )
		FROM   #batches
		WHERE  date_applied = @date_applied

		SELECT @org_id = MIN(org_id)
		FROM   #batches
		WHERE  date_applied = @date_applied
		AND    source_batch_code = @source_batch_code		
		
		
		EXEC	@result = gltrxbat_sp	@batch_code	OUTPUT,
						@source_batch_code,
						6010,
						@process_user_id,
						@date_applied,
						@company_code,
						@org_id 
						
		IF ( @result != 0 )
			goto rollback_tran
			
		IF ( @debug_level > 3 )
		BEGIN
			SELECT	"*** glpsmkbt_sp - Created batch: "+@batch_code+
				" for process: "+@process_ctrl_num+
				" for company: "+@company_code+
				" for source batch: "+@source_batch_code+
				" for date_applied: "+convert(char(10), @date_applied)
		END
		



		UPDATE	batchctl
		SET	process_group_num = @process_ctrl_num
		WHERE	batch_ctrl_num = @batch_code

		IF ( @@error != 0 )
		BEGIN
			SELECT	@result = 1039
			goto rollback_tran
		END
		



		UPDATE	gltrx
		SET	batch_code = @batch_code
		WHERE	date_applied = @date_applied
		AND	source_batch_code = @source_batch_code
		AND	process_group_num = @process_ctrl_num
		AND	company_code = @company_code
		AND 	org_id	= @org_id

		IF ( @@error != 0 )
		BEGIN
			SELECT	@result = 1039
			goto rollback_tran
		END
		
		IF ( @debug_level > 4 )
		BEGIN
			SELECT	"*** glpsmkbt_sp - Transactions updated"
			SELECT	"journal_ctrl_num"
			SELECT	journal_ctrl_num
			FROM	gltrx
			WHERE	batch_code = @batch_code
		END
			
		DELETE	#batches
		WHERE	date_applied = @date_applied
		AND	source_batch_code = @source_batch_code
		AND     org_id = @org_id 
		
	END
	
	COMMIT TRAN

	DROP TABLE	#batches
	
	IF ( @debug_level > 1 ) SELECT "glpsmkbt.cpp" + ", line " + STR( 234, 5 ) + " -- MSG: " + CONVERT(char,@work_time,100) + "Exiting"
	RETURN 0
	
	rollback_tran:
	ROLLBACK TRAN

	IF ( @debug_level > 1 ) SELECT "glpsmkbt.cpp" + ", line " + STR( 240, 5 ) + " -- MSG: " + CONVERT(char,@work_time,100) + "Exiting - ERROR"
	RETURN	@result
END
/**/                                              
GO
GRANT EXECUTE ON  [dbo].[glpsmkbt_sp] TO [public]
GO
