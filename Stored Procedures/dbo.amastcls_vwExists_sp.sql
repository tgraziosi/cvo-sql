SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[amastcls_vwExists_sp]
(
	@co_asset_id 	smSurrogateKey,
	@company_id 	smCompanyID,
	@classification_id 	smSurrogateKey,
	@valid int output
) as


if exists (select 1 from amastcls_vw where
	co_asset_id 	=	@co_asset_id and
	company_id 	=	@company_id and
	classification_id 	=	@classification_id
)
 select @valid = 1
else
 select @valid = 0
return @@error
GO
GRANT EXECUTE ON  [dbo].[amastcls_vwExists_sp] TO [public]
GO
