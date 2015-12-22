SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2007 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2007 Epicor Software Corporation, 2007    
                  All Rights Reserved                    
*/                                                




















CREATE PROCEDURE        [dbo].[glerrdef1_sp]
			@error_code	int,
			@error_level	int OUTPUT
			
AS

BEGIN

SELECT 	@error_level = e_level
FROM   	glerrdef
WHERE  	--client_id = "EDITLST"
    	e_code = @error_code

END

GO
GRANT EXECUTE ON  [dbo].[glerrdef1_sp] TO [public]
GO
