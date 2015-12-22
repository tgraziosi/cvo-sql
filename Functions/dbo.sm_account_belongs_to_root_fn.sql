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


CREATE FUNCTION [dbo].[sm_account_belongs_to_root_fn] ( @account_code varchar(32))
RETURNS smallint
AS
BEGIN
	DECLARE @Result smallint
	DECLARE @org_id varchar(32)
	select @org_id  = dbo.IBOrgbyAcct_fn ( @account_code )

	
	IF EXISTS (	SELECT  organization_id			
			FROM	Organization_all			
			WHERE	organization_id = @org_id
			AND 	outline_num = '1'	
		  )
	SET @Result = 1
	ELSE
	SET @Result = 0

	RETURN @Result
END
/**/                                              
GO
GRANT REFERENCES ON  [dbo].[sm_account_belongs_to_root_fn] TO [public]
GO
GRANT EXECUTE ON  [dbo].[sm_account_belongs_to_root_fn] TO [public]
GO
