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


















 
CREATE FUNCTION [dbo].[IBUserPermOrg_fn] (@org_id varchar(30))
RETURNS smallint
AS
BEGIN
DECLARE @return_statement smallint

	IF (	(SELECT COUNT(child_org_id) FROM IBAllChilds_vw  
		WHERE parent_org_id = @org_id) 
		= 
		(SELECT COUNT(child_org_id) FROM IBAllChilds_all_vw  
		WHERE parent_org_id = @org_id)
	    )
		SET @return_statement = 1
	ELSE
		SET @return_statement = 0

	RETURN @return_statement
END
/**/                                              
GO
GRANT REFERENCES ON  [dbo].[IBUserPermOrg_fn] TO [public]
GO
GRANT EXECUTE ON  [dbo].[IBUserPermOrg_fn] TO [public]
GO
