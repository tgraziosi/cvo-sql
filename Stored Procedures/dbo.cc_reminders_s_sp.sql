SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE [dbo].[cc_reminders_s_sp] @user_id	smallint,
																		@current_id	int = NULL

AS

IF (@current_id IS NULL)
	SELECT 	remind_time, 
					comment, 
					reminder_id, 
					DATEDIFF(dd, '1/1/1753', remind_time) + 639906,
					CONVERT(varchar(20),remind_time,108)
	FROM cc_reminders 
	WHERE user_id = @user_id
	AND remind_time = (	SELECT MIN(remind_time)
											FROM cc_reminders 
											WHERE user_id = @user_id)
	ORDER BY reminder_id
ELSE
	SELECT 	remind_time, 
					comment, 
					reminder_id, 
					DATEDIFF(dd, '1/1/1753', remind_time) + 639906,
					CONVERT(varchar(20),remind_time,108)
	FROM cc_reminders 
	WHERE user_id = @user_id
	AND remind_time = (	SELECT MIN(remind_time)
											FROM cc_reminders 
											WHERE user_id = @user_id
											AND reminder_id > @current_id)
	ORDER BY reminder_id

GO
GRANT EXECUTE ON  [dbo].[cc_reminders_s_sp] TO [public]
GO
