SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[amasttypExists_sp]
(
	@asset_type_code 	smAssetTypeCode,
	@valid int output
) as


if exists (select 1 from amasttyp where
	asset_type_code 	=	@asset_type_code
)
 select @valid = 1
else
 select @valid = 0
return @@error
GO
GRANT EXECUTE ON  [dbo].[amasttypExists_sp] TO [public]
GO
