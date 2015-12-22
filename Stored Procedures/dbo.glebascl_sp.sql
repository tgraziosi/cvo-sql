SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2001 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2001 Epicor Software Corporation, 2001    
                  All Rights Reserved                    
*/                                                














create proc [dbo].[glebascl_sp]
		@importDIN		varchar(20)
as

begin


delete glebhold
where 	din = @importDIN		

end
GO
GRANT EXECUTE ON  [dbo].[glebascl_sp] TO [public]
GO
