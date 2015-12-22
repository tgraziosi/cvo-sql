SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[ammandprInsert_sp] 
( 
	@co_asset_book_id 	smSurrogateKey, 
	@fiscal_period_end 	varchar(30), 
	@last_modified_date 	varchar(30), 
	@modified_by 	smUserID, 
	@posting_flag 	smPostingState, 
	@depr_expense 	smMoneyZero 
) as 

declare @error int 

 

SELECT @fiscal_period_end = RTRIM(@fiscal_period_end) IF @fiscal_period_end = "" SELECT @fiscal_period_end = NULL
SELECT @last_modified_date = RTRIM(@last_modified_date) IF @last_modified_date = "" SELECT @last_modified_date = NULL

 

insert into ammandpr 
( 
	co_asset_book_id,
	fiscal_period_end,
	last_modified_date,
	modified_by,
	posting_flag,
	depr_expense 
)
values 
( 
	@co_asset_book_id,
	@fiscal_period_end,
	@last_modified_date,
	@modified_by,
	@posting_flag,
	@depr_expense 
)

 
 
 

return @@error 
GO
GRANT EXECUTE ON  [dbo].[ammandprInsert_sp] TO [public]
GO
