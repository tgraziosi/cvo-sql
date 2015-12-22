SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO



CREATE PROC [dbo].[cc_rpt_cmnt_s_sp]
		@customer_code varchar(8)
AS
	SELECT 	comment 
	FROM	cc_rpt_comments 
	WHERE 	customer_code = @customer_code
GO
GRANT EXECUTE ON  [dbo].[cc_rpt_cmnt_s_sp] TO [public]
GO
