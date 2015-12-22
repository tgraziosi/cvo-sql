SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[amcat_vwInsert_sp] 
( 
	@category_code smCategoryCode, 
	@category_description smStdDescription, 
	@posting_code smPostingCode,
	@posting_code_description		smStdDescription 
) as 

insert into amcat 
	(category_code,
	category_description,
	posting_code)
values 
	(@category_code,
	@category_description,
	@posting_code 
	)

return @@error 
GO
GRANT EXECUTE ON  [dbo].[amcat_vwInsert_sp] TO [public]
GO
