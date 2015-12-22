SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

/* PVCS Revision or Version:Revision              
I:\vcs\GL\PROCS\glnxttrx.SPv - e7.2.2 : 1.0
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1996 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1996 Epicor Software Corporation, 1996  
                 All Rights Reserved                    
*/                                                



CREATE PROCEDURE [dbo].[glnxttrx_sp]
 	@next_jcn		varchar(16) OUTPUT


AS DECLARE 

		@E_CANT_GEN_TRX_NUM	int,
 	@mask			varchar(16), 
		@next_number		int,
		@result			smallint,
		@tran_started		tinyint


SELECT	@E_CANT_GEN_TRX_NUM = e_code
FROM	glerrdef
WHERE	e_sdesc = "E_CANT_GEN_TRX_NUM"



SELECT	@mask=jrnl_ctrl_code_mask, 
	@next_number=next_jrnl_ctrl_code
FROM	glnumber

IF ( @@trancount = 0 )
BEGIN
	BEGIN TRAN
	SELECT	@tran_started = 1
END


WHILE 1=1
BEGIN
	
	UPDATE	glnumber 
	SET	next_jrnl_ctrl_code=@next_number+1

	
	EXEC	fmtctlnm_sp	@next_number, 
				@mask, 
				@next_jcn	OUTPUT, 
				@result		OUTPUT

	IF ( @result != 0 )
	BEGIN
		IF ( @tran_started = 1 )
			ROLLBACK TRAN

		SELECT	@next_jcn = NULL

		return @E_CANT_GEN_TRX_NUM
	END

	IF NOT EXISTS(	SELECT	1
		 	FROM 	gltrx
		 	WHERE	journal_ctrl_num = @next_jcn )
	BREAK

	SELECT	@next_number=@next_number + 1
END

IF ( @tran_started = 1 )
	COMMIT TRAN

RETURN 0




/**/                                              
GO
GRANT EXECUTE ON  [dbo].[glnxttrx_sp] TO [public]
GO
