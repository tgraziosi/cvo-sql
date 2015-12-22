SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amfacInsert_sp] 
( 
	@company_id				smCompanyID, 
	@fac_mask				smAccountCode, 
	@fac_mask_description	smStdDescription,
	@last_modified_date		smISODate, 
	@modified_by			smUserID 
) 
AS 

INSERT INTO amfac 
( 
	company_id,
	fac_mask,
	fac_mask_description,
	last_modified_date,
	modified_by 
)
VALUES 
( 
	@company_id,
	@fac_mask,
	@fac_mask_description,
	@last_modified_date,
	@modified_by 
)

RETURN @@error 
GO
GRANT EXECUTE ON  [dbo].[amfacInsert_sp] TO [public]
GO
