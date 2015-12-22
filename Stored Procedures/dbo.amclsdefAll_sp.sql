SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

 
CREATE PROCEDURE [dbo].[amclsdefAll_sp]
( 
	@company_id smCompanyID
)
 
AS 

SELECT 
	timestamp,
	company_id,
	classification_id,
	classification_name,
	acct_level,
	start_col,
	length,
	override_default
FROM 
	amclshdr
WHERE
	company_id = @company_id
ORDER BY 
	classification_name 

RETURN @@error 
GO
GRANT EXECUTE ON  [dbo].[amclsdefAll_sp] TO [public]
GO
