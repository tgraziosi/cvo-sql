SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[amasttypUpdate_sp]
(
	@timestamp 	timestamp,
	@asset_type_code 	smAssetTypeCode,
	@asset_type_description 	smStdDescription,
	@asset_gl_override 	smAccountOverride,
	@accum_depr_gl_override 	smAccountOverride,
	@depr_exp_gl_override 	smAccountOverride,
	@last_modified_date 	varchar(30),
	@modified_by 	smUserID
) as
declare @rowcount int
declare @error int
declare @ts timestamp
declare @message varchar(255)

SELECT @last_modified_date = RTRIM(@last_modified_date) IF @last_modified_date = "" SELECT @last_modified_date = NULL


update amasttyp set
	asset_type_description 	=	@asset_type_description,
	asset_gl_override 	=	@asset_gl_override,
	accum_depr_gl_override 	=	@accum_depr_gl_override,
	depr_exp_gl_override 	=	@depr_exp_gl_override,
	last_modified_date 	=	@last_modified_date,
	modified_by 	=	@modified_by
where
	asset_type_code 	=	@asset_type_code and
	timestamp 	=	@timestamp
select @error = @@error, @rowcount = @@rowcount
if @error <> 0 
	return @error
if @rowcount = 0 
begin
	
	select @ts = timestamp from amasttyp where
	asset_type_code = @asset_type_code
	select @error = @@error, @rowcount = @@rowcount
	if @error <> 0 
		return @error
	if @rowcount = 0 
	begin
		EXEC 		amGetErrorMessage_sp 20004, "tmp/amastyup.sp", 107, amasttyp, @error_message = @message out
		IF @message IS NOT NULL RAISERROR 	20004 @message
		return 		20004
	end
	if @ts <> @timestamp
	begin
		EXEC 		amGetErrorMessage_sp 20003, "tmp/amastyup.sp", 113,amasttyp, @error_message = @message out
		IF @message IS NOT NULL RAISERROR 	20003 @message
		return 		20003
	end
end
return @@error
GO
GRANT EXECUTE ON  [dbo].[amasttypUpdate_sp] TO [public]
GO
