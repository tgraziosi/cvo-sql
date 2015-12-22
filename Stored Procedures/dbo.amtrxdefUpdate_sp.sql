SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[amtrxdefUpdate_sp] 
( 
	@timestamp	timestamp,
	@trx_type smTrxType, @system_defined smLogicalFalse, @create_activity smCounter, @display_activity smLogicalTrue, @display_in_reports smCounter, @copy_trx_on_replicate smLogicalTrue, @allow_to_import smLogicalTrue, @prd_to_prd_column smCounter, @post_to_gl smLogicalTrue, @summmarize_activity smLogicalFalse, @trx_name smName, @trx_short_name smName, @trx_description smStdDescription, @updated_by smUserID
		 
	) as 
declare @rowcount int, 
		@error int, 
		@ts timestamp, 
		@message varchar(255)

update amtrxdef 
set 
		create_activity					= @create_activity,
		display_activity				= @display_activity,
		display_in_reports				= @display_in_reports,
		copy_trx_on_replicate			= @copy_trx_on_replicate,
		allow_to_import					= @allow_to_import,
		prd_to_prd_column				= @prd_to_prd_column,
		post_to_gl		= @post_to_gl,
		summmarize_activity				= @summmarize_activity,
		trx_type 						= @trx_type,
		trx_short_name					= @trx_short_name,
		trx_description 				= @trx_description, 
		last_updated					= GETDATE(),
		updated_by						= @updated_by
where	trx_name 		= @trx_name 
and 	timestamp 		= @timestamp 

select @error = @@error, 
		@rowcount = @@rowcount 

if @error <> 0  
	return @error 

if @rowcount = 0  
begin 
	 
	select @ts = timestamp 
	from amtrxdef 
	where trx_name = @trx_name 

	select @error = @@error, 
			@rowcount = @@rowcount 

	if @error <> 0  
		return @error 

	if @rowcount = 0  
	begin 
		EXEC 		amGetErrorMessage_sp 20004, "tmp/amtdfup.sp", 98, amtrxdef, @error_message = @message out 
		IF @message IS NOT NULL RAISERROR 	20004 @message 
		return 		20004 
	end 

	if @ts <> @timestamp 
	begin 
		EXEC 		amGetErrorMessage_sp 20003, "tmp/amtdfup.sp", 105, amtrxdef, @error_message = @message out 
		IF @message IS NOT NULL RAISERROR 	20003 @message 
		return 		20003 
	end 
end 
return @@error 
GO
GRANT EXECUTE ON  [dbo].[amtrxdefUpdate_sp] TO [public]
GO
