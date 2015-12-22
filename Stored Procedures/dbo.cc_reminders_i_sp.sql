SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE [dbo].[cc_reminders_i_sp] 
	@user_id	smallint,
	@remind_time	smalldatetime,
	@comment	varchar(255)
AS

IF (SELECT COUNT(*) FROM cc_reminders 
	WHERE remind_time = @remind_time) > 0
	SELECT @remind_time = DATEADD(mi, 1, @remind_time) 
INSERT cc_reminders
	SELECT ISNULL(MAX(reminder_id), 0) + 1 ,
		@user_id,
		@remind_time,
		@comment
	FROM cc_reminders
GO
GRANT EXECUTE ON  [dbo].[cc_reminders_i_sp] TO [public]
GO
