SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[amcatbkInsert_sp] 
( 
	@category_code 	smCategoryCode, 
	@book_code 	smBookCode, 
	@effective_date 	varchar(30), 
	@depr_rule_code 	smDeprRuleCode, 
	@depr_rule_description			smStdDescription,
	@limit_rule_code 	smLimitRuleCode 
) as 

declare @error int 

 

SELECT @effective_date = RTRIM(@effective_date) IF @effective_date = "" SELECT @effective_date = NULL


 

insert into amcatbk 
( 
	category_code,
	book_code,
	effective_date,
	depr_rule_code,
	limit_rule_code 
)
values 
( 
	@category_code,
	@book_code,
	@effective_date,
	@depr_rule_code,
	@limit_rule_code 
)
return @@error 
GO
GRANT EXECUTE ON  [dbo].[amcatbkInsert_sp] TO [public]
GO
