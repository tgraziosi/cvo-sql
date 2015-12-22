SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[amastcls_vwInsert_sp]
(
	@company_id 	smCompanyID,
	@classification_id 	smSurrogateKey,
	@co_asset_id 	smSurrogateKey,
	@classification_code 	smClassificationCode,
	@classification_description		smStdDescription,		
	@last_modified_date 	varchar(30),
	@modified_by 	smUserID
) as

declare @error int



SELECT @last_modified_date = RTRIM(@last_modified_date) IF @last_modified_date = "" SELECT @last_modified_date = NULL




insert into amastcls
(
	company_id,
	classification_id,
	co_asset_id,
	classification_code,
	last_modified_date,
	modified_by
)
values
(
	@company_id,
	@classification_id,
	@co_asset_id,
	@classification_code,
	@last_modified_date,
	@modified_by
)
return @@error
GO
GRANT EXECUTE ON  [dbo].[amastcls_vwInsert_sp] TO [public]
GO
