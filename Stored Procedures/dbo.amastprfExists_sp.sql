SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[amastprfExists_sp]
(
	@co_asset_book_id			smSurrogateKey,
	@fiscal_period_end			varchar(30),
	@valid int output
) as


if exists (select 1 from amastprf 
	where co_asset_book_id = @co_asset_book_id
	and fiscal_period_end = @fiscal_period_end
)
 select @valid = 1
else
 select @valid = 0
return @@error
GO
GRANT EXECUTE ON  [dbo].[amastprfExists_sp] TO [public]
GO
