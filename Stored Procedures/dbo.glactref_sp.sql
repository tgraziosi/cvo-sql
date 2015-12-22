SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

/* PVCS Revision or Version:Revision              
I:\vcs\GL\PROCS\glactref.SPv - e7.2.2 : 1.2
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1996 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1996 Epicor Software Corporation, 1996  
                 All Rights Reserved                    
*/                                                


CREATE PROCEDURE [dbo].[glactref_sp]
	@acct_code	varchar(32),
	@form_call	smallint = -1
AS
DECLARE	@valid_flag	smallint


SELECT @valid_flag = 0


IF EXISTS ( SELECT account_mask
 	FROM	glrefact
 	WHERE	@acct_code LIKE account_mask
 	AND	reference_flag = 1 )
		SELECT @valid_flag = 0
ELSE
BEGIN
	
	IF EXISTS ( SELECT account_mask
 		FROM	glrefact
	 	WHERE	@acct_code LIKE account_mask
 		AND	reference_flag = 3 )
			SELECT @valid_flag = 1
	
	
END
IF ( @form_call = -1 )
	SELECT @valid_flag
RETURN	@valid_flag


/**/                                              
GO
GRANT EXECUTE ON  [dbo].[glactref_sp] TO [public]
GO
