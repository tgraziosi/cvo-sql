SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

 
CREATE PROCEDURE [dbo].[amclsAll_sp] 
( 
	@company_id smCompanyID, 
	@classification_id smSurrogateKey 
) 
AS 

SELECT 
 timestamp, 
 company_id, 
 classification_id, 
 classification_code, 
 classification_description, 
 gl_override,
 last_modified_date= convert(char(8), last_modified_date, 112),
 modified_by 
FROM 	amcls 
WHERE 	company_id 			= @company_id 
AND 	classification_id 	= @classification_id 
ORDER BY 
		company_id,
		classification_id,
		classification_code 

RETURN @@error 
GO
GRANT EXECUTE ON  [dbo].[amclsAll_sp] TO [public]
GO
