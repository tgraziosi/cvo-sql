SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[amacctypInsert_sp] 
( 
	@account_type smAccountTypeID, @system_defined smLogicalFalse, @income_account smLogicalTrue, @display_order smCounter, @account_type_name smName, @account_type_short_name smName, @account_type_description smStdDescription, @updated_by smUserID 	 
	 
) as 

declare @error int
declare @todays smApplyDate

SELECT @todays = GETDATE() 

insert into amacctyp 
( 
	
	account_type,			 
	income_account, 
	display_order,			 	
	account_type_name,			
	account_type_short_name, 	
	account_type_description, 
	last_updated,
	date_created,
	created_by,
	updated_by
	 
)
values 
( 
	@account_type,			 
	@income_account, 
	@display_order,			 	
	@account_type_name,			
	@account_type_short_name, 	
	@account_type_description,
	@todays,
	@todays,
	@updated_by,
	@updated_by
		
)
return @@error 
GO
GRANT EXECUTE ON  [dbo].[amacctypInsert_sp] TO [public]
GO
