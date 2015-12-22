SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[amtrxdefInsert_sp] 
( 
	@trx_type smTrxType, @system_defined smLogicalFalse, @create_activity smCounter, @display_activity smLogicalTrue, @display_in_reports smCounter, @copy_trx_on_replicate smLogicalTrue, @allow_to_import smLogicalTrue, @prd_to_prd_column smCounter, @post_to_gl smLogicalTrue, @summmarize_activity smLogicalFalse, @trx_name smName, @trx_short_name smName, @trx_description smStdDescription, @updated_by smUserID 	 
	 
) as 

declare @error int
declare @todays smApplyDate

SELECT @todays = GETDATE() 

insert into amtrxdef 
( 
	
	trx_type,			 
	create_activity,
	display_activity,
	display_in_reports,
	copy_trx_on_replicate,
	allow_to_import,
	prd_to_prd_column,
	post_to_gl,
	summmarize_activity,			 	
	trx_name,			
	trx_short_name, 	
	trx_description, 
	last_updated,
	date_created,
	created_by,
	updated_by,
	effective_date_type
	 
)
values 
( 
	@trx_type,			 
	@create_activity,
	@display_activity,
	@display_in_reports,
	@copy_trx_on_replicate,
	@allow_to_import,
	@prd_to_prd_column,
	@post_to_gl,
	@summmarize_activity,	 	
	@trx_name,			
	@trx_short_name, 	
	@trx_description,
	@todays,
	@todays,
	@updated_by,
	@updated_by,
	1
		
)
return @@error 
GO
GRANT EXECUTE ON  [dbo].[amtrxdefInsert_sp] TO [public]
GO
