SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[amtrxdefFetch_sp] 
( 
	@rowsrequested smallint = 1,
	@trx_name smName 
) as 

SET ROWCOUNT @rowsrequested


SELECT timestamp, trx_type, system_defined, create_activity, display_activity, display_in_reports, copy_trx_on_replicate, allow_to_import, prd_to_prd_column, post_to_gl, summmarize_activity, trx_name, trx_short_name, trx_description, updated_by
FROM amtrxdef_vw
WHERE	trx_name >= @trx_name

SET ROWCOUNT 0

return @@error 
GO
GRANT EXECUTE ON  [dbo].[amtrxdefFetch_sp] TO [public]
GO
