SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[amacctypUpdate_sp] 
( 
	@timestamp	timestamp,
	@account_type smAccountTypeID, @system_defined smLogicalFalse, @income_account smLogicalTrue, @display_order smCounter, @account_type_name smName, @account_type_short_name smName, @account_type_description smStdDescription, @updated_by smUserID
		 
	) as 
declare @rowcount int, 
		@error int, 
		@ts timestamp, 
		@message varchar(255)

update amacctyp 
set 
		income_account 				= @income_account,
		display_order 				= @display_order,
		account_type 				= @account_type,
		account_type_short_name		= @account_type_short_name,
		account_type_description 	= @account_type_description, 
		last_updated				= GETDATE(),
		updated_by					= @updated_by
where	account_type_name = @account_type_name 
and 	timestamp = @timestamp 

select @error = @@error, 
		@rowcount = @@rowcount 

if @error <> 0  
	return @error 

if @rowcount = 0  
begin 
	 
	select @ts = timestamp 
	from amacctyp 
	where account_type_name = @account_type_name 

	select @error = @@error, 
			@rowcount = @@rowcount 

	if @error <> 0  
		return @error 

	if @rowcount = 0  
	begin 
		EXEC 		amGetErrorMessage_sp 20004, "tmp/amacpup.sp", 92, amacctyp, @error_message = @message out 
		IF @message IS NOT NULL RAISERROR 	20004 @message 
		return 		20004 
	end 

	if @ts <> @timestamp 
	begin 
		EXEC 		amGetErrorMessage_sp 20003, "tmp/amacpup.sp", 99, amacctyp, @error_message = @message out 
		IF @message IS NOT NULL RAISERROR 	20003 @message 
		return 		20003 
	end 
end 
return @@error 
GO
GRANT EXECUTE ON  [dbo].[amacctypUpdate_sp] TO [public]
GO
