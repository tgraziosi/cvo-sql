SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[amlocUpdate_sp] 
( 
	@timestamp 	timestamp,
	@location_code 	smLocationCode, 
	@location_description 	smStdDescription 
) as 
declare @rowcount int 
declare @error int 
declare @ts timestamp 
declare @message varchar(255)


update amloc set 
	location_description 	= @location_description 
where 
	location_code 	= @location_code and 
	timestamp 	= @timestamp 
select @error = @@error, @rowcount = @@rowcount 
if @error <> 0  
	return @error 
if @rowcount = 0  
begin 
	 
	select @ts = timestamp from amloc where 
	location_code = @location_code 
	select @error = @@error, @rowcount = @@rowcount 
	if @error <> 0  
		return @error 
	if @rowcount = 0  
	begin 
		EXEC 		amGetErrorMessage_sp 20004, "tmp/amlocup.sp", 89, amloc, @error_message = @message out 
		IF @message IS NOT NULL RAISERROR 	20004 @message 
		return 		20004 
	end 
	if @ts <> @timestamp 
	begin 
		EXEC 		amGetErrorMessage_sp 20003, "tmp/amlocup.sp", 95, amloc, @error_message = @message out 
		IF @message IS NOT NULL RAISERROR 	20003 @message 
		return 		20003 
	end 
end 
return @@error 
GO
GRANT EXECUTE ON  [dbo].[amlocUpdate_sp] TO [public]
GO
