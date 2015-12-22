SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[amclsInsert_sp]
(
	@company_id 	smCompanyID,
	@classification_id 	smSurrogateKey,
	@classification_code 	smClassificationCode,
	@classification_description 	smStdDescription,
	@gl_override 	smAccountOverride,
	@last_modified_date 	varchar(30),
	@modified_by 	smUserID
) as

declare @error int


SELECT @last_modified_date = RTRIM(@last_modified_date) IF @last_modified_date = "" SELECT @last_modified_date = NULL




insert into amcls
(
	company_id,
	classification_id,
	classification_code,
	classification_description,
	gl_override,
	last_modified_date,
	modified_by
)
values
(
	@company_id,
	@classification_id,
	@classification_code,
	@classification_description,
	@gl_override,
	@last_modified_date,
	@modified_by
)
return @@error
GO
GRANT EXECUTE ON  [dbo].[amclsInsert_sp] TO [public]
GO
