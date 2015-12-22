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





























CREATE PROC [dbo].[sm_set_current_organization_sp] 
		@name 		sysname, 
		@org_id 	varchar(30),
		@debug_flag 	int
AS

DELETE sm_current_organization WHERE name = @name

IF EXISTS ( SELECT 1 FROM IB_Organization_vw WHERE org_id = @org_id)
BEGIN
	



	INSERT INTO sm_current_organization (name, org_id, asof, organization_name)  
	SELECT 	@name, @org_id, GETDATE(), OrganizationName
	FROM 	IB_Organization_vw
	WHERE 	org_id = @org_id 
END
ELSE
BEGIN	
	


	RETURN -100
END
RETURN 0


/**/                                              
GO
GRANT EXECUTE ON  [dbo].[sm_set_current_organization_sp] TO [public]
GO
