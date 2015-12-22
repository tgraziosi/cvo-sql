SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[amastprfUpdate_sp] 
( 
	@timestamp 	timestamp,
	@co_asset_book_id 	smSurrogateKey, 
	@fiscal_period_end 	varchar(30), 
	@current_cost 	smMoneyZero, 
	@accum_depr 	smMoneyZero, 
	@effective_date 	varchar(30)
) as 
declare @rowcount int 
declare @error int 
declare @ts timestamp 
declare @message varchar(255)
declare @activity_state int
declare @is_new smLogicalTrue

SELECT @fiscal_period_end = RTRIM(@fiscal_period_end) IF @fiscal_period_end = "" SELECT @fiscal_period_end = NULL
SELECT @effective_date = RTRIM(@effective_date) IF @effective_date = "" SELECT @effective_date = NULL



SELECT @activity_state	= activity_state, @is_new = is_new
FROM amasset a, 
 amastbk b
WHERE b.co_asset_book_id 	= @co_asset_book_id
AND	 b.co_asset_id		= a.co_asset_id

IF @activity_state <> 100 OR @is_new = 1
BEGIN
	EXEC 		amGetErrorMessage_sp 20100, "tmp/amaspfup.sp", 110, amastprf, @error_message = @message out 	
	IF @message IS NOT NULL RAISERROR 	20100 @message 
	return 		20100 
END


update amastprf set 
	current_cost 	= @current_cost,
	accum_depr 	= -@accum_depr,
	effective_date 	= @effective_date 
where 
	co_asset_book_id 	= @co_asset_book_id and 
	fiscal_period_end 	= @fiscal_period_end and 
	timestamp 	= @timestamp 
select @error = @@error, @rowcount = @@rowcount 
if @error <> 0  
	return @error 
if @rowcount = 0  
begin 
	 
	select @ts = timestamp from amastprf where 
	co_asset_book_id = @co_asset_book_id and 
	fiscal_period_end = @fiscal_period_end 
	select @error = @@error, @rowcount = @@rowcount 
	if @error <> 0  
		return @error 
	if @rowcount = 0  
	begin 
		EXEC 		amGetErrorMessage_sp 20004, "tmp/amaspfup.sp", 138, amastpr, @error_message = @message out 
		IF @message IS NOT NULL RAISERROR 	20004 @message
		return 		20004 
	end 
	if @ts <> @timestamp 
	begin 
		EXEC 		amGetErrorMessage_sp 20003, "tmp/amaspfup.sp", 144, amastprf, @error_message = @message out 
		IF @message IS NOT NULL RAISERROR 	20003 @message 
		return 		20003 
	end 
end 

 
 
 
 

return @@error 
GO
GRANT EXECUTE ON  [dbo].[amastprfUpdate_sp] TO [public]
GO
