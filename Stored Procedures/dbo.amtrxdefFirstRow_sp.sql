SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[amtrxdefFirstRow_sp]
			 
as 


declare @MSKtrx_name smName

select @MSKtrx_name = min(trx_name) 
from amtrxdef_vw
 
select timestamp, trx_type, system_defined, create_activity, display_activity, display_in_reports, copy_trx_on_replicate, allow_to_import, prd_to_prd_column, post_to_gl, summmarize_activity, trx_name, trx_short_name, trx_description, updated_by 	 
from amtrxdef_vw 
where 	trx_name = @MSKtrx_name 

return @@error 
GO
GRANT EXECUTE ON  [dbo].[amtrxdefFirstRow_sp] TO [public]
GO
