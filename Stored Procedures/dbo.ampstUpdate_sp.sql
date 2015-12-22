SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[ampstUpdate_sp] 
( 
	@timestamp	timestamp,
	@company_id smCompanyID, @posting_code smPostingCode, @posting_code_description smStdDescription, @updated_by smUserID
		 
	) as 
declare @rowcount int, 
		@error int, 
		@ts timestamp, 
		@message varchar(255)

update ampsthdr 
set 	posting_code_description = @posting_code_description,
		last_updated					=		GETDATE(),
		updated_by						=		@updated_by
where	company_id = @company_id
and 	posting_code = @posting_code 
and 	timestamp = @timestamp 

select @error = @@error, 
		@rowcount = @@rowcount 

if @error <> 0  
	return @error 

if @rowcount = 0  
begin 
	 
	select @ts = timestamp 
	from ampsthdr 
	where company_id = @company_id
	and posting_code = @posting_code 

	select @error = @@error, 
			@rowcount = @@rowcount 

	if @error <> 0  
		return @error 

	if @rowcount = 0  
	begin 
		EXEC 		amGetErrorMessage_sp 20004, "tmp/ampstup.sp", 108, ampst, @error_message = @message out 
		IF @message IS NOT NULL RAISERROR 	20004 @message 
		return 		20004 
	end 

	if @ts <> @timestamp 
	begin 
		EXEC 		amGetErrorMessage_sp 20003, "tmp/ampstup.sp", 115, ampst, @error_message = @message out 
		IF @message IS NOT NULL RAISERROR 	20003 @message 
		return 		20003 
	end 
end 
return @@error 
GO
GRANT EXECUTE ON  [dbo].[ampstUpdate_sp] TO [public]
GO
