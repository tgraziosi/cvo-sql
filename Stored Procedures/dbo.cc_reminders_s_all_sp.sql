SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE [dbo].[cc_reminders_s_all_sp] 
	@user_id	smallint,
	@to_date	int = NULL

AS
DECLARE @max_date smalldatetime


SELECT @max_date = convert(datetime, dateadd(dd, @to_date - 639906, '1/1/1753'))
SELECT @max_date = dateadd(hh, 23, @max_date)
SELECT @max_date = dateadd(n, 59, @max_date)


IF (@to_date IS NULL)
	SELECT 	remind_time, 
					comment, 
					reminder_id, 
					DATEDIFF(dd, '1/1/1753', remind_time) + 639906,
					CONVERT(varchar(20),remind_time,108)
	FROM cc_reminders 
	WHERE user_id = @user_id
	ORDER BY remind_time
ELSE
	SELECT 	remind_time, 
					comment, 
					reminder_id, 
					DATEDIFF(dd, '1/1/1753', remind_time) + 639906,
					CONVERT(varchar(20),remind_time,108)
	FROM cc_reminders 
	WHERE user_id = @user_id
	AND remind_time <= @max_date
	ORDER BY remind_time

GO
GRANT EXECUTE ON  [dbo].[cc_reminders_s_all_sp] TO [public]
GO
