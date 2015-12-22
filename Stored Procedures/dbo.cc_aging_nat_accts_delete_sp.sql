SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE PROC	[dbo].[cc_aging_nat_accts_delete_sp]	@my_id				varchar(255) = '0'
AS
	SET NOCOUNT ON

	DELETE 	cc_rpt_eboage
	WHERE		my_id = @my_id

GO
GRANT EXECUTE ON  [dbo].[cc_aging_nat_accts_delete_sp] TO [public]
GO
