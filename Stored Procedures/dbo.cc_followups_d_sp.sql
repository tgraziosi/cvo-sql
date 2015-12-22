SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE [dbo].[cc_followups_d_sp] 
	@customer_code		varchar(20),
	@comment_id		int

AS

	IF (	SELECT 	COUNT(*) 
			FROM 		cc_followups
			WHERE 	customer_code = @customer_code 
			AND		comment_id = @comment_id ) > 0

			DELETE 	cc_followups 
			WHERE 	customer_code = @customer_code
			AND		comment_id = @comment_id


GO
GRANT EXECUTE ON  [dbo].[cc_followups_d_sp] TO [public]
GO
