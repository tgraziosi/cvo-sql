SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

 
CREATE PROCEDURE [dbo].[amasttypAll_sp] 
AS 

SELECT 
	timestamp,
	asset_type_code,
	asset_type_description,
	asset_gl_override,
	accum_depr_gl_override,
	depr_exp_gl_override,
	last_modified_date,
	modified_by
FROM 
	amasttyp 
ORDER BY 
	asset_type_code 

RETURN @@error 
GO
GRANT EXECUTE ON  [dbo].[amasttypAll_sp] TO [public]
GO
