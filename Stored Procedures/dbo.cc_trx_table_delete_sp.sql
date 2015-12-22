SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO



CREATE PROC	[dbo].[cc_trx_table_delete_sp]	@my_id		varchar(255)

AS

	DELETE cc_trx_table WHERE my_id = @my_id


GO
GRANT EXECUTE ON  [dbo].[cc_trx_table_delete_sp] TO [public]
GO
