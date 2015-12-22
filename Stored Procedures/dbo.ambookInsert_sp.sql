SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[ambookInsert_sp] 
( 
	@book_code 	smBookCode, 
	@book_description 	smStdDescription, 
	@capitalization_threshold 	smMoneyZero, 
	@currency_code 	smCurrencyCode, 
	@allow_revaluations 	smLogicalFalse, 
	@allow_writedowns 	smLogicalFalse, 
	@allow_adjustments 	smLogicalFalse, 
	@suspend_depr 	smLogicalFalse, 
	@post_to_gl 	smLogicalFalse, 
	@gl_book_code 	smBookCode,
	@depr_if_less_than_yr			smLogicalTrue 
) as 

declare @error int 

insert into ambook 
( 
	book_code,
	book_description,
	capitalization_threshold,
	currency_code,
	allow_revaluations,
	allow_writedowns,
	allow_adjustments,
	suspend_depr,
	post_to_gl,
	gl_book_code,
	depr_if_less_than_yr 
)
values 
( 
	@book_code,
	@book_description,
	@capitalization_threshold,
	@currency_code,
	@allow_revaluations,
	@allow_writedowns,
	@allow_adjustments,
	@suspend_depr,
	@post_to_gl,
	@gl_book_code,
	@depr_if_less_than_yr 
)

return @@error 
GO
GRANT EXECUTE ON  [dbo].[ambookInsert_sp] TO [public]
GO
