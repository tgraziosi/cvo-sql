SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/* PVCS Revision or Version:Revision              
I:\vcs\AR\PROCS\argnc.SPv - e7.2.2 : 1.2
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1996 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1996 Epicor Software Corporation, 1996  
                 All Rights Reserved                    
*/                                                

 








 



					 










































 








































































































































































































































































































































































































































































































CREATE PROCEDURE [dbo].[ARGetNextControl_SP] 	@num_type 		int, 
										@masked 		varchar(35) output, 
										@num 			int OUTPUT, 
										@debug_level 	int = 0
										
AS
DECLARE @mask 		char(35),
		@result		smallint,
		@tran_start	int

BEGIN

	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/argnc.sp" + ", line " + STR( 44, 5 ) + " -- ENTRY: "



	IF (@@trancount = 0)
	BEGIN
		SELECT @tran_start = 1
		BEGIN TRANSACTION
	END
	ELSE
		SELECT @tran_start = 0



	UPDATE 	ewnumber
	SET 	next_num = next_num + 1
	WHERE 	num_type = @num_type



	IF (@@error != 0)
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/argnc.sp" + ", line " + STR( 72, 5 ) + " -- EXIT: "
		IF (@tran_start = 1)
			ROLLBACK TRANSACTION
		RETURN -1
	END



	SELECT 	@num = next_num - 1,
			@mask = rtrim(mask)
	FROM 	ewnumber
	WHERE 	num_type = @num_type



	IF (@@error != 0)
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/argnc.sp" + ", line " + STR( 93, 5 ) + " -- EXIT: "
		IF (@tran_start = 1)
			ROLLBACK TRANSACTION
		RETURN -1
	END



	IF (@tran_start = 1)
		COMMIT TRANSACTION
	


	EXEC fmtctlnm_sp	@num,
						@mask,
						@masked output,
						@result output

	IF (@result != 0)
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/argnc.sp" + ", line " + STR( 117, 5 ) + " -- EXIT: "
		RETURN -1
	END

	IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/argnc.sp" + ", line " + STR( 121, 5 ) + " -- MSG: " + "This is the masked number " + @masked



	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/argnc.sp" + ", line " + STR( 127, 5 ) + " -- EXIT: "	

	RETURN 0

END 

GO
GRANT EXECUTE ON  [dbo].[ARGetNextControl_SP] TO [public]
GO
