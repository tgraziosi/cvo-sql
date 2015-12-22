SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[amtmcl_vwInsert_sp]
(
	@company_id 	smCompanyID,
	@classification_id 	smSurrogateKey,
	@template_code 	smTemplateCode,
	@classification_code 	smClassificationCode,
	@classification_description		smStdDescription,		
	@last_modified_date 	varchar(30),
	@modified_by 	smUserID
) as

declare @error int



SELECT @last_modified_date = RTRIM(@last_modified_date) IF @last_modified_date = "" SELECT @last_modified_date = NULL



insert into amtmplcl
(
	company_id,
	classification_id,
	template_code,
	classification_code,
	last_modified_date,
	modified_by
)
values
(
	@company_id,
	@classification_id,
	@template_code,
	@classification_code,
	@last_modified_date,
	@modified_by
)
return @@error
GO
GRANT EXECUTE ON  [dbo].[amtmcl_vwInsert_sp] TO [public]
GO
