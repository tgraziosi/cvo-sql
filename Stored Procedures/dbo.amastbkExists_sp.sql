SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[amastbkExists_sp] 
( 
	@co_asset_book_id smSurrogateKey, 
	@valid int output 
) as 


if exists (select 1 from amastbk where 
	co_asset_book_id = @co_asset_book_id 
)
 select @valid = 1 
else 
 select @valid = 0 
return @@error 
GO
GRANT EXECUTE ON  [dbo].[amastbkExists_sp] TO [public]
GO
