SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[amclshdrUpdate_sp] 
( 
	@timestamp	timestamp,
	@company_id smCompanyID, @classification_id smSurrogateKey, @classification_name smClassificationName, @acct_level smAcctLevel, @start_col smSmallCounter, @length smSmallCounter, @override_default smAccountOverride, @updated_by smUserID
		 
	) as 
declare @rowcount int, 
		@error int, 
		@ts timestamp, 
		@message varchar(255)

update amclshdr 
set 	acct_level 						= @acct_level,
		start_col 						= @start_col,
		length 							= @length,
		override_default 				= @override_default,
		last_updated					= GETDATE(),
		updated_by						= @updated_by
where	company_id = @company_id
and 	classification_id = @classification_id 
and 	timestamp = @timestamp 

select @error = @@error, 
		@rowcount = @@rowcount 

if @error <> 0  
	return @error 

if @rowcount = 0  
begin 
	 
	select @ts = timestamp 
	from amclshdr 
	where company_id = @company_id
	and classification_name = @classification_name 

	select @error = @@error, 
			@rowcount = @@rowcount 

	if @error <> 0  
		return @error 

	if @rowcount = 0  
	begin 
		EXEC 		amGetErrorMessage_sp 20004, "tmp/amclshdrup.sp", 93, amclshdr, @error_message = @message out 
		IF @message IS NOT NULL RAISERROR 	20004 @message 
		return 		20004 
	end 

	if @ts <> @timestamp 
	begin 
		EXEC 		amGetErrorMessage_sp 20003, "tmp/amclshdrup.sp", 100, amclshdr, @error_message = @message out 
		IF @message IS NOT NULL RAISERROR 	20003 @message 
		return 		20003 
	end 
end 
return @@error 
GO
GRANT EXECUTE ON  [dbo].[amclshdrUpdate_sp] TO [public]
GO
