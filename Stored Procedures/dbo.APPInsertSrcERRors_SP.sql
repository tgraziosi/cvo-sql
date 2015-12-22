SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/* PVCS Revision or Version:Revision              
I:\vcs\APPCORE\PROCS\appiserr.SPv - e7.2.2 : 1.3
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1996 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1996 Epicor Software Corporation, 1996  
                 All Rights Reserved                    
*/                                                









 



					 










































 







































































































































































































































































































CREATE PROCEDURE [dbo].[APPInsertSrcERRors_SP]
						@process_ctrl_num 	varchar(16), 
						@batch_code 		varchar(16),
						@module_id		int,
						@debug_level		smallint,
						@perf_level		smallint

AS
DECLARE
	@result	int
	
BEGIN

	IF ( @debug_level > 0 )
	BEGIN
		SELECT "@process_ctrl_num=" + @process_ctrl_num +
			"@batch_code="+ @batch_code	+
			"@module_id="+ STR(@module_id, 8)
	END

	IF ( @module_id = 6000 )
	BEGIN
		EXEC @result = APPInsertGLERRors_SP @process_ctrl_num,
							 @batch_code,
							 @debug_level,
							 @perf_level
		IF( @result != 0 )
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/appiserr.sp" + ", line " + STR( 53, 5 ) + " -- EXIT: "
			RETURN @result
		END
	END
	
	RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[APPInsertSrcERRors_SP] TO [public]
GO
