SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[amasttypDelete_sp]
(
	@timestamp 	timestamp,
	@asset_type_code 	smAssetTypeCode
) as

declare @rowcount int
declare @error int
declare @ts timestamp
declare @message varchar(255)


delete from amasttyp where
	asset_type_code = @asset_type_code and
	timestamp = @timestamp

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
		EXEC 		amGetErrorMessage_sp 20002, "tmp/amastydl.sp", 87, amasttyp, @error_message = @message out
		IF @message IS NOT NULL RAISERROR 	20002 @message
		return 		20002
	end
	if @ts <> @timestamp
	begin
		EXEC	 	amGetErrorMessage_sp 20001, "tmp/amastydl.sp", 93, amasttyp, @error_message = @message out
		IF @message IS NOT NULL RAISERROR 	20001 @message
		return 		20001
	end
end
return @@error
GO
GRANT EXECUTE ON  [dbo].[amasttypDelete_sp] TO [public]
GO
