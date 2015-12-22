SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[amdprcrtUpdate_sp] 
( 
	@timestamp 	timestamp,
	@co_trx_id 	smSurrogateKey, 
	@field_type 	smFieldType, 
	@from_code 	smCriteriaCode, 
	@to_code 	smCriteriaCode 
) as 
declare @rowcount int 
declare @error int 
declare @ts timestamp 
declare @message varchar(255)


update amdprcrt set 
	from_code 	= @from_code,
	to_code 	= @to_code 
where 
	co_trx_id 	= @co_trx_id and 
	field_type 	= @field_type and 
	timestamp 	= @timestamp 
select @error = @@error, @rowcount = @@rowcount 
if @error <> 0  
	return @error 
if @rowcount = 0  
begin 
	 
	select @ts = timestamp from amdprcrt where 
	co_trx_id = @co_trx_id and 
	field_type = @field_type 
	select @error = @@error, @rowcount = @@rowcount 
	if @error <> 0  
		return @error 
	if @rowcount = 0  
	begin 
		EXEC 		amGetErrorMessage_sp 20004, "tmp/amdpcrup.sp", 95, amdprcrt, @error_message = @message out 
		IF @message IS NOT NULL RAISERROR 	20004 @message 
		return 		20004 
	end 
	if @ts <> @timestamp 
	begin 
		EXEC 		amGetErrorMessage_sp 20003, "tmp/amdpcrup.sp", 101, amdprcrt, @error_message = @message out 
		IF @message IS NOT NULL RAISERROR 	20003 @message 
		return 		20003 
	end 
end 
return @@error 
GO
GRANT EXECUTE ON  [dbo].[amdprcrtUpdate_sp] TO [public]
GO
