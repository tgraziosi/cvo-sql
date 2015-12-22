SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

 
CREATE PROCEDURE [dbo].[amfacAll_sp] 
AS 

SELECT 
	timestamp,
	company_id,
	fac_mask,
	fac_mask_description,
	last_modified_date = CONVERT(char(8), last_modified_date, 112),
	modified_by 
FROM 
	amfac 
ORDER BY 
	company_id, fac_mask 

RETURN @@error 
GO
GRANT EXECUTE ON  [dbo].[amfacAll_sp] TO [public]
GO
