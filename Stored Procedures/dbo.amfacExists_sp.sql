SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amfacExists_sp] 
( 
	@company_id			smCompanyID, 
	@fac_mask			smAccountCode, 
	@valid 				int OUTPUT 
) 
AS 

IF EXISTS (SELECT 	1 
			FROM 	amfac 
			WHERE 	company_id	= @company_id
			AND	 	fac_mask	= @fac_mask)
 SELECT @valid = 1 
ELSE 
 SELECT @valid = 0
 
RETURN @@error 
GO
GRANT EXECUTE ON  [dbo].[amfacExists_sp] TO [public]
GO
