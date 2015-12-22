SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE [dbo].[cc_followups_i_sp] 
	@customer_code		varchar(20),
	@comment_id		int,
	@followup_date		smalldatetime,
	@priority		char(1)

AS

IF (SELECT count(*) FROM cc_followups
		WHERE customer_code = @customer_code) > 0
	DELETE FROM cc_followups WHERE customer_code = @customer_code
 
INSERT cc_followups VALUES (@customer_code,
	@comment_id,
	@followup_date,
	@priority)

GO
GRANT EXECUTE ON  [dbo].[cc_followups_i_sp] TO [public]
GO
