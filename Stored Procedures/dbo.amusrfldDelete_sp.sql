SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[amusrfldDelete_sp] 
( 
	@timestamp 	timestamp,
	@user_field_id 		smSurrogateKey 
) as 

declare @rowcount int 
declare @error int 
declare @ts timestamp 
declare @message varchar(255)


delete from amusrfld where 
	timestamp = @timestamp 
and user_field_id 		= @user_field_id 

select @error = @@error, @rowcount = @@rowcount 
if @error <> 0  
	return @error 
if @rowcount = 0  
begin 
	 
	select @ts = timestamp from amusrfld where user_field_id = @user_field_id 
	select @error = @@error, @rowcount = @@rowcount 
	if @error <> 0  
		return @error 
	if @rowcount = 0  
	begin 
		EXEC 		amGetErrorMessage_sp 20002, "tmp/amusfddl.sp", 86, amusrfld, @error_message = @message out 
		IF @message IS NOT NULL RAISERROR 	20002 @message 
		return 		20002 
	end 
	if @ts <> @timestamp 
	begin 
		EXEC 		amGetErrorMessage_sp 20001, "tmp/amusfddl.sp", 92, amusrfld, @error_message = @message out 
		IF @message IS NOT NULL RAISERROR 	20001 @message 
		return 		20001 
	end 
end 
return @@error 
GO
GRANT EXECUTE ON  [dbo].[amusrfldDelete_sp] TO [public]
GO
