SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[ammandprExists_sp]
(
	@co_asset_book_id		smSurrogateKey,
	@fiscal_period_end		varchar(30),
	@valid int output
) as


select @fiscal_period_end = rtrim(isnull(@fiscal_period_end,""))

if exists (select 1 from ammandpr 
where	co_asset_book_id = @co_asset_book_id
AND		fiscal_period_end = @fiscal_period_end
)
 select @valid = 1
else
 select @valid = 0
return @@error
GO
GRANT EXECUTE ON  [dbo].[ammandprExists_sp] TO [public]
GO
