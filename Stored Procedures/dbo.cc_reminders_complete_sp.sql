SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO



CREATE PROCEDURE [dbo].[cc_reminders_complete_sp]
	@reminder_id	int

AS

DELETE cc_reminders WHERE reminder_id = @reminder_id
GO
GRANT EXECUTE ON  [dbo].[cc_reminders_complete_sp] TO [public]
GO
