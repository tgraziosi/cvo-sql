SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[amasttypInsert_sp]
(
	@asset_type_code 	smAssetTypeCode,
	@asset_type_description 	smStdDescription,
	@asset_gl_override 	smAccountOverride,
	@accum_depr_gl_override 	smAccountOverride,
	@depr_exp_gl_override 	smAccountOverride,
	@last_modified_date 	varchar(30),
	@modified_by 	smUserID
) as

declare @error int



SELECT @last_modified_date = RTRIM(@last_modified_date) IF @last_modified_date = "" SELECT @last_modified_date = NULL





insert into amasttyp
(
	asset_type_code,
	asset_type_description,
	asset_gl_override,
	accum_depr_gl_override,
	depr_exp_gl_override,
	last_modified_date,
	modified_by
)
values
(
	@asset_type_code,
	@asset_type_description,
	@asset_gl_override,
	@accum_depr_gl_override,
	@depr_exp_gl_override,
	@last_modified_date,
	@modified_by
)
return @@error
GO
GRANT EXECUTE ON  [dbo].[amasttypInsert_sp] TO [public]
GO
