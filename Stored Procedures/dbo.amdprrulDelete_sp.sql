SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[amdprrulDelete_sp] 
( 
	@timestamp timestamp,
	@depr_rule_code smDeprRuleCode 
) as 

declare @rowcount int 
declare @error int 
declare @ts timestamp 
declare @message varchar(255)
								 

delete from amdprrul where 
	depr_rule_code = @depr_rule_code and 
	timestamp = @timestamp 

select @error = @@error, @rowcount = @@rowcount 
if @error <> 0  
	return @error 
if @rowcount = 0  
begin 
	 
	select @ts = timestamp from amdprrul where 
		depr_rule_code = @depr_rule_code 
	select @error = @@error, @rowcount = @@rowcount 
	if @error <> 0  
		return @error 
	if @rowcount = 0  
	begin 
		EXEC 		amGetErrorMessage_sp 20002, "tmp/amdprldl.sp", 92, amdprrul, @error_message = @message out 
		IF @message IS NOT NULL RAISERROR 	20002 @message 
		return 		20002 
	end 
	if @ts <> @timestamp 
	begin 
		EXEC 		amGetErrorMessage_sp 20001, "tmp/amdprldl.sp", 98, amdprrul, @error_message = @message out 
		IF @message IS NOT NULL RAISERROR 	20001 @message 
		return 		20001 
	end 
end 
return @@error 
GO
GRANT EXECUTE ON  [dbo].[amdprrulDelete_sp] TO [public]
GO
