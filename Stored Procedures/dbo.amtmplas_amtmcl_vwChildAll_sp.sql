SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amtmplas_amtmcl_vwChildAll_sp] 
( 
	@company_id			smCompanyID,
	@template_code		smTemplateCode 
) 
AS 

SELECT 
 tc.timestamp,
 tc.company_id,
 tc.classification_id, 
 tc.template_code, 
 tc.classification_code, 
 tc.classification_description, 
 last_modified_date = CONVERT(char(8), tc.last_modified_date,112), 
 tc.modified_by 
FROM 	amtmcl_vw 	tc,
		amclshdr 	cd 
WHERE tc.company_id 			= @company_id
AND		tc.template_code 		= @template_code
AND 	tc.company_id 			= cd.company_id 
AND		tc.classification_id 	= cd.classification_id
ORDER BY 
 cd.classification_name

GO
GRANT EXECUTE ON  [dbo].[amtmplas_amtmcl_vwChildAll_sp] TO [public]
GO
