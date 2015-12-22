SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[amta_vwInsert_sp] 
( 
	@trx_type smTrxType, @account_type smAccountTypeID, @system_defined smLogicalFalse, @display_order smCounter, @account_type_name smName, @debit_positive smLogicalFalse, @credit_positive smLogicalFalse, @debit_negative smLogicalFalse, @credit_negative smLogicalFalse, @auto_balancing smLogicalFalse, @updated_by smUserID, @import_order smCounter 	 
	 
) as 

declare @error int
declare @todays smApplyDate

SELECT @todays = GETDATE() 


SELECT @account_type		= account_type
FROM	amacctyp
WHERE	account_type_name 	= @account_type_name

insert into amtrxact 
( 
	trx_type,
	account_type,	 
	display_order,
	import_order,
	debit_positive,
	credit_positive,
	debit_negative,
	credit_negative,
	auto_balancing,			 	
	last_updated,
	date_created,
	created_by,
	updated_by
	 
)
values 
( 
	@trx_type,
	@account_type,	 
	@display_order,
	@import_order,
	@debit_positive,
	@credit_positive,
	@debit_negative,
	@credit_negative,
	@auto_balancing,		 	
	@todays,
	@todays,
	@updated_by,
	@updated_by
		
)
return @@error 
GO
GRANT EXECUTE ON  [dbo].[amta_vwInsert_sp] TO [public]
GO
