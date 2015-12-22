SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[ampstExists_sp] 
( 
	@company_id smCompanyID, 
	@posting_code smPostingCode, 
	@valid int output 
) as 


if exists (select 1 from ampsthdr where 
	company_id = @company_id and 
	posting_code = @posting_code 
)
 select @valid = 1 
else 
 select @valid = 0 
return @@error 
GO
GRANT EXECUTE ON  [dbo].[ampstExists_sp] TO [public]
GO
