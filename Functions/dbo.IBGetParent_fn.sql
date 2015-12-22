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


























CREATE FUNCTION [dbo].[IBGetParent_fn] (@org_id varchar(30))
RETURNS varchar(30)
AS
BEGIN
	
	DECLARE @parent_org_id varchar(30)
	
	SELECT  @parent_org_id = parent_org_id
	FROM	IBDirectChilds
	WHERE	child_org_id = @org_id
		
	RETURN ISNULL(@parent_org_id, (SELECT organization_id FROM Organization_all WHERE outline_num = '1')) 

END

GO
GRANT REFERENCES ON  [dbo].[IBGetParent_fn] TO [public]
GO
GRANT EXECUTE ON  [dbo].[IBGetParent_fn] TO [public]
GO
