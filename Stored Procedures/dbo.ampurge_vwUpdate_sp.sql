SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[ampurge_vwUpdate_sp] 
( 
	@timestamp 	timestamp,
	@company_id smCompanyID, @date_purged char(8), @time_purged varchar(20), @co_asset_id smSurrogateKey, @asset_ctrl_num smControlNumber, @asset_description smStdDescription, @activity_state smSystemState, @mass_maintenance_id smSurrogateKey, @mass_description smStdDescription, @comment smLongDesc, @user_name smStdDescription, @date_acquisition char(8), @date_disposition char(8), @original_cost smMoneyZero, @lp_fiscal_period_end char(8), @lp_accum_depr smMoneyZero, @lp_current_cost smMoneyZero, @updated_by smUserID
	) as 
declare @rowcount 	int 
declare @error 		int 
declare @ts 		timestamp 
declare @message 	varchar(255)
declare @dt 		datetime


SELECT @dt = @date_purged + " " + @time_purged

update 	ampurge
set 	comment 	= @comment,
		updated_by				= @updated_by,
		last_updated			= GetDate()
where 	company_id 		= @company_id
AND		date_created			= @dt
AND		timestamp 	= @timestamp 

select @error = @@error, @rowcount = @@rowcount 
if @error <> 0  
	return @error 

if @rowcount = 0  
begin 
	 
	select 	@ts 				= timestamp 
	from 	ampurge 
 	where 	company_id 		= @company_id
	AND		date_created			= @dt
	
	select @error = @@error, @rowcount = @@rowcount 
	if @error <> 0  
		return @error 
	if @rowcount = 0  
	begin 
		EXEC 		amGetErrorMessage_sp 20004, "tmp/ampurgup.sp", 90, ampurge_vw, @error_message = @message out 
		raiserror 	20004 @message 
		return 		20004 
	end 
	if @ts <> @timestamp 
	begin 
		EXEC 		amGetErrorMessage_sp 20003, "tmp/ampurgup.sp", 96, ampurge_vw, @error_message = @message out 
		raiserror 	20003 @message 
		return 		20003 
	end 
end 
return @@error 
GO
GRANT EXECUTE ON  [dbo].[ampurge_vwUpdate_sp] TO [public]
GO
