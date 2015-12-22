SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO



CREATE PROCEDURE [dbo].[cc_del_armrinv_sp]	@my_id	varchar(255) = '123456'
AS
	SET NOCOUNT ON
	SET QUOTED_IDENTIFIER OFF



	DELETE cc_rpt_pfinv
	WHERE		my_id = @my_id

	SET NOCOUNT OFF 

GO
GRANT EXECUTE ON  [dbo].[cc_del_armrinv_sp] TO [public]
GO
