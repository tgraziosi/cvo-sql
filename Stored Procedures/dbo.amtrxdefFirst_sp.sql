SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[amtrxdefFirst_sp] 
( 
	@rowsrequested smallint = 1
		 
) as 

DECLARE @result 				smErrorCode
declare @MSKtrx_name smName 

select @MSKtrx_name = min(trx_name) 
from amtrxdef_vw 


if @MSKtrx_name is null 
begin 
 return 
end 

SET ROWCOUNT @rowsrequested

select timestamp, trx_type, system_defined, create_activity, display_activity, display_in_reports, copy_trx_on_replicate, allow_to_import, prd_to_prd_column, post_to_gl, summmarize_activity, trx_name, trx_short_name, trx_description, updated_by
FROM amtrxdef_vw
where	trx_name >= @MSKtrx_name
	
select @result = @@error

SET ROWCOUNT 0	 
return @result

GO
GRANT EXECUTE ON  [dbo].[amtrxdefFirst_sp] TO [public]
GO
