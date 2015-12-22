SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[amclsExists_sp]
(
	@company_id 	smCompanyID,
	@classification_id 	smSurrogateKey,
	@classification_code 	smClassificationCode,
	@valid int output
) as


if exists (select 1 from amcls where
	company_id 	=	@company_id and
	classification_id 	=	@classification_id and
	classification_code 	=	@classification_code
)
 select @valid = 1
else
 select @valid = 0
return @@error
GO
GRANT EXECUTE ON  [dbo].[amclsExists_sp] TO [public]
GO
