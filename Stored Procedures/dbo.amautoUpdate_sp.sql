SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[amautoUpdate_sp] 
( 
	@company_id smCompanyID, 
	@asset_timestamp timestamp,
	@asset_mask smControlNumber, 
	@asset_next smCounter, 
	@period_timestamp timestamp,
	@period_mask smControlNumber, 
	@period_next smCounter 

) as 
declare @rowcount int 
declare @error int 
declare @ts timestamp 
declare @message varchar(255)

 

UPDATE amauto set 
	 num_mask = @asset_mask,
	 automatic_next = @asset_next 
WHERE company_id = @company_id 
AND automatic_id = 1 
AND timestamp = @asset_timestamp 

select @error = @@error, @rowcount = @@rowcount 
if @error <> 0  
	return @error 
if @rowcount = 0  
begin 
	 
	select @ts = timestamp from amauto where 
	company_id = @company_id and 
	automatic_id = 1 
	select @error = @@error, @rowcount = @@rowcount 
	if @error <> 0  
		return @error 
	if @rowcount = 0  
	begin 
		EXEC 		amGetErrorMessage_sp 20004, "tmp/amautoup.sp", 105, amauto, @error_message = @message out 
		IF @message IS NOT NULL RAISERROR 	20004 @message 
		return 		20004 
	end 
	if @ts <> @asset_timestamp 
	begin 
		EXEC 		amGetErrorMessage_sp 20003, "tmp/amautoup.sp", 111, amauto, @error_message = @message out 
		IF @message IS NOT NULL RAISERROR 	20003 @message 
		return 		20003 
	end 
end 

 

UPDATE amauto 
set 
 num_mask = @period_mask,
 automatic_next = @period_next 
WHERE company_id = @company_id 
AND automatic_id = 2 
AND timestamp = @period_timestamp 

select @error = @@error, @rowcount = @@rowcount 
if @error <> 0  
	return @error 
if @rowcount = 0  
begin 
	 
	select @ts = timestamp from amauto where 
	company_id = @company_id and 
	automatic_id = 2 
	select @error = @@error, @rowcount = @@rowcount 
	if @error <> 0  
		return @error 
	if @rowcount = 0  
	begin 
		EXEC 		amGetErrorMessage_sp 20004, "tmp/amautoup.sp", 141, amauto, @error_message = @message out 
		IF @message IS NOT NULL RAISERROR 	20004 @message 
		return 		20004 
	end 
	if @ts <> @period_timestamp 
	begin 
		EXEC 		amGetErrorMessage_sp 20003, "tmp/amautoup.sp", 147, amauto, @error_message = @message out 
		IF @message IS NOT NULL RAISERROR 	20003 @message 
		return 		20003 
	end 
end 


return @@error 
GO
GRANT EXECUTE ON  [dbo].[amautoUpdate_sp] TO [public]
GO
