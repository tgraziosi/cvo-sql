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

















CREATE FUNCTION [dbo].[am_get_Org_from_CoAssetId_fn] ( @co_asset_id smSurrogateKey)
RETURNS varchar(30)
AS
BEGIN
	DECLARE @org_id varchar(32)
	
	IF (SELECT ib_flag FROM glco) <> 1
	BEGIN
		SELECT @org_id = ''
	END
	ELSE
	BEGIN	
		SELECT @org_id = org_id FROM amasset
		WHERE co_asset_id = @co_asset_id
	END
	RETURN @org_id
END
GO
GRANT REFERENCES ON  [dbo].[am_get_Org_from_CoAssetId_fn] TO [public]
GO
GRANT EXECUTE ON  [dbo].[am_get_Org_from_CoAssetId_fn] TO [public]
GO
