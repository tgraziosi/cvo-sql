SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2001 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2001 Epicor Software Corporation, 2001    
                  All Rights Reserved 
                    
*/                                                


Create proc [dbo].[SQLAuditConnectionhst] 
		 @where nvarchar(4000)
as
	 


IF EXISTS (SELECT *  FROM   master..sysdatabases  WHERE  name = N'SQLAudit74')
BEGIN
	EXEC SQLAudit74..SQLAuditConnectionhstExplorerEBO  @where
END
ELSE
BEGIN
	Select 'DBAudit Not Installed' as Message
END


GO
GRANT EXECUTE ON  [dbo].[SQLAuditConnectionhst] TO [public]
GO
