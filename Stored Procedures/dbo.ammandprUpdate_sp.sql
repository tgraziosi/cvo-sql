SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[ammandprUpdate_sp] 
( 
	@timestamp 	timestamp,
	@co_asset_book_id 	smSurrogateKey, 
	@fiscal_period_end 	varchar(30), 
	@last_modified_date 	varchar(30), 
	@modified_by 	smUserID, 
	@posting_flag 	smPostingState, 
	@depr_expense 	smMoneyZero 
) as 
declare @rowcount int 
declare @error int 
declare @ts timestamp 
declare @message varchar(255)

SELECT @fiscal_period_end = RTRIM(@fiscal_period_end) IF @fiscal_period_end = "" SELECT @fiscal_period_end = NULL
SELECT @last_modified_date = RTRIM(@last_modified_date) IF @last_modified_date = "" SELECT @last_modified_date = NULL

update ammandpr set 
	last_modified_date 	= @last_modified_date,
	modified_by 	= @modified_by,
	posting_flag 	= @posting_flag,
	depr_expense 	= @depr_expense 
where 
	co_asset_book_id 	= @co_asset_book_id and 
	fiscal_period_end 	= @fiscal_period_end and 
	timestamp 	= @timestamp 
select @error = @@error, @rowcount = @@rowcount 
if @error <> 0  
	return @error 
if @rowcount = 0  
begin 
	 
	select @ts = timestamp from ammandpr where 
	co_asset_book_id = @co_asset_book_id and 
	fiscal_period_end = @fiscal_period_end 
	select @error = @@error, @rowcount = @@rowcount 
	if @error <> 0  
		return @error 
	if @rowcount = 0  
	begin 
	 	EXEC		amGetErrorMessage_sp 20004, "tmp/ammdprup.sp", 108, ammandpr, @error_message = @message out 
		IF @message IS NOT NULL RAISERROR 	20004 @message 
		return 		20004 
	end 
	if @ts <> @timestamp 
	begin 
		EXEC 		amGetErrorMessage_sp 20003, "tmp/ammdprup.sp", 114, ammandpr, @error_message = @message out 
		IF @message IS NOT NULL RAISERROR 	20003 @message 
		return 		20003 
	end 
end 
select 	@timestamp = timestamp 
from 	ammandpr 
where	 co_asset_book_id = @co_asset_book_id 
and fiscal_period_end = @fiscal_period_end 

return @@error 
GO
GRANT EXECUTE ON  [dbo].[ammandprUpdate_sp] TO [public]
GO
