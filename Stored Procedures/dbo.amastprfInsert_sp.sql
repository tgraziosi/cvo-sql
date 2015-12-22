SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[amastprfInsert_sp] 
( 
	@co_asset_book_id 	smSurrogateKey, 
	@fiscal_period_end 	varchar(30), 
	@current_cost 	smMoneyZero, 
	@accum_depr 	smMoneyZero, 
	@effective_date 	varchar(30)
) 
as 

declare @error int
declare @activity_state int
declare @is_new smLogicalTrue
declare @message varchar(255)



SELECT @activity_state	= activity_state, @is_new = is_new
FROM amasset a, 
 amastbk b
WHERE b.co_asset_book_id 	= @co_asset_book_id
AND	 b.co_asset_id		= a.co_asset_id

IF @activity_state <> 100 OR @is_new = 1 
BEGIN
	EXEC 		amGetErrorMessage_sp 20100, "tmp/amaspfin.sp", 107, amastprf, @error_message = @message out 	
	IF @message IS NOT NULL RAISERROR 	20100 @message 
	return 		20100 
END

 

 
SELECT @fiscal_period_end = RTRIM(@fiscal_period_end) IF @fiscal_period_end = "" SELECT @fiscal_period_end = NULL
SELECT @effective_date = RTRIM(@effective_date) IF @effective_date = "" SELECT @effective_date = NULL



 

insert into amastprf 
( 
	co_asset_book_id,
	fiscal_period_end,
	current_cost,
	accum_depr,
	effective_date 
)
values 
( 
	@co_asset_book_id,
	@fiscal_period_end,
	@current_cost,
	-@accum_depr,
	@effective_date 
)

return @@error 
GO
GRANT EXECUTE ON  [dbo].[amastprfInsert_sp] TO [public]
GO
