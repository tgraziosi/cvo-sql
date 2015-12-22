SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE [dbo].[cc_validate_credit_memo]
	@cm_number varchar(16)

AS
select count(*) from artrx where doc_ctrl_num = @cm_number

GO
GRANT EXECUTE ON  [dbo].[cc_validate_credit_memo] TO [public]
GO
