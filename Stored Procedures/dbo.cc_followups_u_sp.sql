SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO



CREATE PROCEDURE [dbo].[cc_followups_u_sp] 
	@customer_code		varchar(20),
	@comment_id		int,
	@followup_date		smalldatetime

AS

	IF (	SELECT 	count(*) 
			FROM 		cc_followups
			WHERE 	customer_code = @customer_code
			AND		comment_id = @comment_id ) > 0

 
		UPDATE 	cc_followups 
		SET		followup_date = @followup_date
		WHERE 	customer_code = @customer_code
		AND		comment_id = @comment_id 


GO
GRANT EXECUTE ON  [dbo].[cc_followups_u_sp] TO [public]
GO
