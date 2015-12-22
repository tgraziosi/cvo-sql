SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[amdprhstExists_sp]
(
	@co_asset_book_id		smSurrogateKey,
	@effective_date			varchar(30),
	@valid int output
) as


if exists (select 1 from amdprhst 
where co_asset_book_id = @co_asset_book_id
and effective_date = @effective_date
)
 select @valid = 1
else
 select @valid = 0
return @@error
GO
GRANT EXECUTE ON  [dbo].[amdprhstExists_sp] TO [public]
GO
