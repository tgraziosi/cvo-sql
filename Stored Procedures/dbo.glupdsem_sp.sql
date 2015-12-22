SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

/* PVCS Revision or Version:Revision              
I:\vcs\GL\PROCS\glupdsem.SPv - e7.2.2 : 1.0
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1996 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1996 Epicor Software Corporation, 1996  
                 All Rights Reserved                    
*/                                                


CREATE PROCEDURE	[dbo].[glupdsem_sp]
			@sem_name	varchar(30)
AS

DECLARE		@result		smallint,
		@msg		varchar(40)

SELECT	@result = 0

IF ( UPPER( @sem_name ) = "GL_COA_CHANGED" )
	UPDATE	glappsem
	SET	gl_coa_changed = 1

ELSE
	UPDATE	glappsem
	SET	gl_coa_changed = -1

SELECT @msg = " Result from glupdsem = "+STR(@result)
PRINT @msg
RETURN	@result


/**/                                              
GO
GRANT EXECUTE ON  [dbo].[glupdsem_sp] TO [public]
GO
