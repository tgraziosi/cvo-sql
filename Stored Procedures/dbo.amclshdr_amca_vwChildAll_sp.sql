SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

 
CREATE PROCEDURE [dbo].[amclshdr_amca_vwChildAll_sp]
(
	@company_id 	smCompanyID,
	@classification_id 	smSurrogateKey

)
AS
 
SELECT timestamp, company_id, classification_id, account_type, override_account_flag, account_type_name, display_order, income_account, updated_by
FROM	amca_vw
WHERE	company_id	= @company_id
AND	classification_id	= @classification_id
ORDER BY	company_id, classification_id, display_order
 
RETURN 0
GO
GRANT EXECUTE ON  [dbo].[amclshdr_amca_vwChildAll_sp] TO [public]
GO
