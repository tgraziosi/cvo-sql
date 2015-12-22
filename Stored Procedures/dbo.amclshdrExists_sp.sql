SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[amclshdrExists_sp] 
( 
	@company_id smCompanyID, 
	@classification_name				smClassificationName , 
	@valid int output 
) as 


if exists (select 1 from amclshdr
		where 	company_id = @company_id 
		and 	classification_name		 = @classification_name	
)
 select @valid = 1 
else 
 select @valid = 0 
return @@error 
GO
GRANT EXECUTE ON  [dbo].[amclshdrExists_sp] TO [public]
GO
