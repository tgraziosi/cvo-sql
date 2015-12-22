SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

/* PVCS Revision or Version:Revision              
I:\vcs\GL\PROCS\gltrxnew.SPv - e7.2.2 : 1.2
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1996 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1996 Epicor Software Corporation, 1996  
                 All Rights Reserved                    
*/                                                
















 



					 










































 







































































































































































































































































 










































































































































































CREATE PROCEDURE [dbo].[gltrxnew_sp]
		@company_code		varchar(8),
 	@next_jcn		varchar(16) OUTPUT


AS 

BEGIN

	DECLARE 	@mask			varchar(16), 
			@next_number		int,
			@result			smallint,
			@tran_started		smallint

	SELECT	@mask=jrnl_ctrl_code_mask
	FROM	glnumber


	IF ( @@trancount = 0 )
	BEGIN
		BEGIN TRAN
		SELECT	@tran_started = 1
	END

	
	WHILE 1=1
	BEGIN
		
		UPDATE	glnumber 
		SET	next_jrnl_ctrl_code = next_jrnl_ctrl_code + 1

		
		SELECT	@next_number=next_jrnl_ctrl_code - 1
		FROM	glnumber

		
		EXEC	fmtctlnm_sp	@next_number, 
					@mask, 
					@next_jcn	OUTPUT, 
					@result		OUTPUT

		IF ( @result != 0 )
		BEGIN
			IF ( @tran_started = 1 )
				ROLLBACK TRAN

			SELECT	@next_jcn = NULL

			RETURN	1015
		END

		IF EXISTS(	SELECT	*
			 	FROM 	gltrx
			 	WHERE	journal_ctrl_num = @next_jcn )
			CONTINUE
		ELSE
			BREAK

		SELECT	@next_number=@next_number + 1
	END

	IF ( @tran_started = 1 )
		COMMIT TRAN

	RETURN 0
	
END




/**/                                              
GO
GRANT EXECUTE ON  [dbo].[gltrxnew_sp] TO [public]
GO
