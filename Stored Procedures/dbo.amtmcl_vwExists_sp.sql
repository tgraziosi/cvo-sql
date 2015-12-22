SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[amtmcl_vwExists_sp]
(
	@template_code 	smTemplateCode,
	@company_id 	smCompanyID,
	@classification_id 	smSurrogateKey,
	@valid int output
) as


if exists (select 1 from amtmcl_vw where
	template_code =	@template_code and
	company_id 	=	@company_id and
	classification_id 	=	@classification_id
)
 select @valid = 1
else
 select @valid = 0
return @@error
GO
GRANT EXECUTE ON  [dbo].[amtmcl_vwExists_sp] TO [public]
GO
