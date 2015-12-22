SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[amstatusUpdate_sp] 
( 
	@timestamp 	timestamp,
	@status_code 	smStatusCode, 
	@status_description 	smStdDescription, 
	@activity_state 	smUserState 
) as 
declare @rowcount int 
declare @error int 
declare @ts timestamp 
declare @message varchar(255)


update amstatus set 
	status_description 	= @status_description,
	activity_state 	= @activity_state 
where 
	status_code 	= @status_code and 
	timestamp 	= @timestamp 
select @error = @@error, @rowcount = @@rowcount 
if @error <> 0  
	return @error 
if @rowcount = 0  
begin 
	 
	select @ts = timestamp from amstatus where 
	status_code = @status_code 
	select @error = @@error, @rowcount = @@rowcount 
	if @error <> 0  
		return @error 
	if @rowcount = 0  
	begin 
		EXEC 		amGetErrorMessage_sp 20004, "tmp/amstatup.sp", 91, amstatus, @error_message = @message out 
		IF @message IS NOT NULL RAISERROR 	20004 @message 
		return 		20004 
	end 
	if @ts <> @timestamp 
	begin 
		EXEC 		amGetErrorMessage_sp 20003, "tmp/amstatup.sp", 97, amstatus, @error_message = @message out 
		IF @message IS NOT NULL RAISERROR 	20003 @message 
		return 		20003 
	end 
end 
return @@error 
GO
GRANT EXECUTE ON  [dbo].[amstatusUpdate_sp] TO [public]
GO
