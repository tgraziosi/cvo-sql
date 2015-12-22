SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

/* PVCS Revision or Version:Revision              
I:\vcs\GL\PROCS\glgetmsg.SPv - e7.2.2 : 1.1
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1996 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1996 Epicor Software Corporation, 1996  
                 All Rights Reserved                    
*/                                                

	 

CREATE PROCEDURE	[dbo].[glgetmsg_sp]	
			@e_code		int,
			@e_msg		varchar(100)	OUTPUT
AS

BEGIN
	SELECT	@e_msg = e_ldesc
	FROM	glerrdef
	WHERE	e_code = @e_code

	IF ( @e_msg IS NULL )
	BEGIN
		SELECT	@e_msg = " "
		RETURN	1
	END

	RETURN	0
END


/**/                                              
GO
GRANT EXECUTE ON  [dbo].[glgetmsg_sp] TO [public]
GO
