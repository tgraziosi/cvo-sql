SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

/* PVCS Revision or Version:Revision              
I:\vcs\GL\PROCS\glerrdef.SPv - e7.2.2 : 1.0
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1996 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1996 Epicor Software Corporation, 1996  
                 All Rights Reserved                    
*/                                                



CREATE PROCEDURE [dbo].[glerrdef_sp]
			@error_code	int,
			@error_level	int OUTPUT
			
AS

BEGIN

SELECT 	@error_level = e_level
FROM 	glerrdef
WHERE 	client_id = "EDITLST"
AND 	e_code = @error_code

END

GO
GRANT EXECUTE ON  [dbo].[glerrdef_sp] TO [public]
GO
