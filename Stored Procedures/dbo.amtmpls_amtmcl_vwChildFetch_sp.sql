SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amtmpls_amtmcl_vwChildFetch_sp]
(
	@rowsrequested			smallint = 1,
	@company_id 			smCompanyID,		
	@template_code 			smTemplateCode,		
	@classification_id 		smSurrogateKey
) 
AS

CREATE TABLE #temp 
(
	timestamp 					varbinary(8) 	null,
	company_id 					smallint 		null,
	classification_id 			int 			null,
	template_code				char(8) 		null,
	classification_code 		char(8) 		null,
	classification_description 	varchar(40) 	null,
	last_modified_date 			datetime 		null,
	modified_by 				int 			null
)

DECLARE @rowsfound 				smallint
DECLARE @MSKclassification_id 	smSurrogateKey

SELECT @rowsfound = 0
SELECT @MSKclassification_id 	= @classification_id

IF EXISTS (SELECT * 
			FROM 	amtmcl_vw 
			WHERE	company_id 			= @company_id 
			AND		template_code 		= @template_code 
			AND		classification_id 	= @MSKclassification_id)
BEGIN
	WHILE @MSKclassification_id IS NOT NULL AND @rowsfound < @rowsrequested
	BEGIN

		INSERT 	INTO #temp 
		SELECT 	 
			timestamp,
			company_id,
			classification_id,
			template_code,
			classification_code,
			classification_description,
			last_modified_date,
			modified_by
		FROM 	amtmcl_vw 
		WHERE	company_id 			= @company_id 
		AND		template_code 		= @template_code 
		AND		classification_id 	= @MSKclassification_id

		SELECT @rowsfound = @rowsfound + @@rowcount
		
		

		SELECT 	@MSKclassification_id = min(classification_id) 
		FROM 	amtmcl_vw 
		WHERE	company_id 			= @company_id 
		AND		template_code 		= @template_code 
		AND		classification_id 	> @MSKclassification_id
	END
END

SELECT
	timestamp,
	company_id,
	classification_id,
	template_code,
	classification_code,
	classification_description,
	last_modified_date = convert(char(8),last_modified_date,112),
	modified_by
FROM #temp 
ORDER BY company_id, template_code, classification_id
DROP TABLE #temp

RETURN @@error
GO
GRANT EXECUTE ON  [dbo].[amtmpls_amtmcl_vwChildFetch_sp] TO [public]
GO
