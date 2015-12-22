SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[amempUpdate_sp] 
( 
	@timestamp 	timestamp,
	@employee_code 	smEmployeeCode, 
	@employee_name 	smStdDescription, 
	@job_title 	smStdDescription 
) as 
declare @rowcount int 
declare @error int 
declare @ts timestamp 
declare @message varchar(255)


update amemp set 
	employee_name 	= @employee_name,
	job_title 	= @job_title 
where 
	employee_code 	= @employee_code and 
	timestamp 	= @timestamp 
select @error = @@error, @rowcount = @@rowcount 
if @error <> 0  
	return @error 
if @rowcount = 0  
begin 
	 
	select @ts = timestamp from amemp where 
	employee_code = @employee_code 
	select @error = @@error, @rowcount = @@rowcount 
	if @error <> 0  
		return @error 
	if @rowcount = 0  
	begin 
		EXEC 		amGetErrorMessage_sp 20004, "tmp/amempup.sp", 92, amemp, @error_message = @message out 
		IF @message IS NOT NULL RAISERROR 	20004 @message 
		return 		20004 
	end 
	if @ts <> @timestamp 
	begin 
		EXEC 		amGetErrorMessage_sp 20003, "tmp/amempup.sp", 98, amemp, @error_message = @message out 
		IF @message IS NOT NULL RAISERROR 	20003 @message 
		return 		20003 
	end 
end 
return @@error 
GO
GRANT EXECUTE ON  [dbo].[amempUpdate_sp] TO [public]
GO
