SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[amtmplasExists_sp] 
( 
	@company_id			smCompanyID, 
	@template_code		smTemplateCode, 
	@valid				int output 
) as 


if exists (select 1 
			from 	amtmplas 
			where 	company_id		= @company_id 
			and 	template_code	= @template_code 
)
 select @valid = 1 
else 
 select @valid = 0 
return @@error 
GO
GRANT EXECUTE ON  [dbo].[amtmplasExists_sp] TO [public]
GO
