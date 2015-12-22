SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[ammasast_vwUpdate_sp] 
( 
	@timestamp	timestamp,
	@mass_maintenance_id smSurrogateKey, @company_id smCompanyID, @asset_ctrl_num smControlNumber, @asset_description smStdDescription, @activity_state smSystemState, @comment smLongDesc
		 
	) as 
declare @rowcount int, 
		@error int, 
		@ts timestamp, 
		@message varchar(255)

update ammasast 
set 
		error_message			= @comment
WHERE	mass_maintenance_id		= @mass_maintenance_id
AND		company_id				= @company_id
AND		asset_ctrl_num			= @asset_ctrl_num
and 	timestamp 	= @timestamp 

select @error = @@error, 
		@rowcount = @@rowcount 

if @error <> 0  
	return @error 

if @rowcount = 0  
begin 
	 
	select @ts = timestamp 
	from ammasast 
	WHERE	mass_maintenance_id		= @mass_maintenance_id
	AND		company_id				= @company_id
	AND		asset_ctrl_num			= @asset_ctrl_num
	

	select @error = @@error, 
			@rowcount = @@rowcount 

	if @error <> 0  
		return @error 

	if @rowcount = 0  
	begin 
		EXEC 		amGetErrorMessage_sp 20004, "tmp/ammasaup.sp", 91, ammasast_vw, @error_message = @message out 
		raiserror 	20004 @message 
		return 		20004 
	end 

	if @ts <> @timestamp 
	begin 
		EXEC 		amGetErrorMessage_sp 20003, "tmp/ammasaup.sp", 98, ammasast_vw, @error_message = @message out 
		raiserror 	20003 @message 
		return 		20003 
	end 
end 
return @@error 
GO
GRANT EXECUTE ON  [dbo].[ammasast_vwUpdate_sp] TO [public]
GO
