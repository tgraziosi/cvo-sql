SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amasset_amastcls_vwChildAll_sp] 
( 
	@co_asset_id smSurrogateKey 
) 
AS 

SELECT 
 ac.timestamp,
 ac.company_id,
 ac.classification_id, 
 ac.co_asset_id, 
 ac.classification_code, 
 ac.classification_description, 
 last_modified_date = convert(char(8), ac.last_modified_date,112), 
 ac.modified_by 
FROM 
	amastcls_vw ac,
	amclshdr cd 
WHERE 
 ac.co_asset_id 			= @co_asset_id
AND	ac.company_id 			= cd.company_id 
AND	ac.classification_id 	= cd.classification_id
ORDER BY 
 cd.classification_name

GO
GRANT EXECUTE ON  [dbo].[amasset_amastcls_vwChildAll_sp] TO [public]
GO
