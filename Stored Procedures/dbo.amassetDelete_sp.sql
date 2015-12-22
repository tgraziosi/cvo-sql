SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[amassetDelete_sp] 
( 
	@timestamp                      timestamp,
	@company_id                     smCompanyID, 
	@asset_ctrl_num                 smControlNumber 
) as 

declare @rowcount 	int,
		@error 		int,
		@ts 		timestamp, 
		@message 	varchar(255)

delete 
from 	amasset
where 	company_id		= @company_id 
and 	asset_ctrl_num	= @asset_ctrl_num 
and 	timestamp		= @timestamp 

select 	@error = @@error, 
		@rowcount = @@rowcount 

if @error <> 0   
	return @error 

if @rowcount = 0  
begin 
	 
	select 	@ts = timestamp 
	from 	amasset_org_vw 
	where 	company_id 		= @company_id 
	and 	asset_ctrl_num 	= @asset_ctrl_num 

	select @error = @@error, @rowcount = @@rowcount 
	if @error <> 0   
		return @error 
	if @rowcount = 0  
	begin 
		EXEC 		amGetErrorMessage_sp 20002, "amasetdl.cpp", 96, amasset, @error_message = @message out 
		IF @message IS NOT NULL RAISERROR 	20002 @message 
		RETURN 		20002 
	end 
	if @ts <> @timestamp 
	begin 
		EXEC 		amGetErrorMessage_sp 20001, "amasetdl.cpp", 102, amasset, @error_message = @message out 
		IF @message IS NOT NULL RAISERROR 	20001 @message 
		RETURN 		20001 
	end 
end 
return @@error 
GO
GRANT EXECUTE ON  [dbo].[amassetDelete_sp] TO [public]
GO
