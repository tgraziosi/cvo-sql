SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE PROC [dbo].[cc_rpt_cmnt_i_sp]
	@customer_code	varchar(8),
	@comment	varchar(255) = ''
AS


	IF ISNULL(DATALENGTH(LTRIM(RTRIM(@comment))),0 ) > 0
		IF (SELECT COUNT(*) FROM cc_rpt_comments WHERE customer_code = @customer_code) > 0
			UPDATE 	cc_rpt_comments
			SET 	comment = @comment
			WHERE 	customer_code = @customer_code
		ELSE
			INSERT cc_rpt_comments 
			VALUES (@customer_code, @comment)
	ELSE
		DELETE cc_rpt_comments
		WHERE	customer_code = @customer_code

GO
GRANT EXECUTE ON  [dbo].[cc_rpt_cmnt_i_sp] TO [public]
GO
