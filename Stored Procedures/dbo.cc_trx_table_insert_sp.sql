SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO



CREATE PROC	[dbo].[cc_trx_table_insert_sp]	@trx_num	varchar(40),
																		@my_id		varchar(255)

AS

	INSERT cc_trx_table (trx_num, my_id)
	SELECT	@trx_num, @my_id


GO
GRANT EXECUTE ON  [dbo].[cc_trx_table_insert_sp] TO [public]
GO
