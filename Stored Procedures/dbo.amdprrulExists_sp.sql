SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[amdprrulExists_sp] 
( 
	@depr_rule_code smDeprRuleCode, 
	@valid int output 
) as 


if exists (select 1 from amdprrul where 
	depr_rule_code = @depr_rule_code 
)
 select @valid = 1 
else 
 select @valid = 0 
return @@error 
GO
GRANT EXECUTE ON  [dbo].[amdprrulExists_sp] TO [public]
GO
