SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE [dbo].[cc_reminders_u_sp] 
	@reminder_id	int, 
	@remind_time	smalldatetime,
	@comment	varchar(255) = NULL

AS

IF (@comment IS NULL)
	UPDATE cc_reminders SET remind_time = @remind_time
		WHERE reminder_id = @reminder_id
ELSE
	UPDATE cc_reminders SET remind_time = @remind_time,
		comment = @comment 
		WHERE reminder_id = @reminder_id

GO
GRANT EXECUTE ON  [dbo].[cc_reminders_u_sp] TO [public]
GO
