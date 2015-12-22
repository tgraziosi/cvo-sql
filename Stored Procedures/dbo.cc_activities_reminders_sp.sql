SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE [dbo].[cc_activities_reminders_sp] 
	@user_id	smallint

AS
	DECLARE @today	int, @future int, @past_due int

	SELECT 	@today = COUNT(remind_time) 
	FROM 		cc_reminders 
	WHERE 	DATEDIFF(dd, '1/1/1753', remind_time) + 639906 = datediff(dd, '1/1/1753', convert(datetime, getdate())) + 639906
	AND		[user_id] = @user_id

	SELECT 	@future = COUNT(remind_time) 
	FROM 		cc_reminders 
	WHERE 	DATEDIFF(dd, '1/1/1753', remind_time) + 639906 > datediff(dd, '1/1/1753', convert(datetime, getdate())) + 639906
	AND		[user_id] = @user_id

	SELECT 	@past_due = COUNT(remind_time) 
	FROM 		cc_reminders 
	WHERE 	DATEDIFF(dd, '1/1/1753', remind_time) + 639906 < datediff(dd, '1/1/1753', convert(datetime, getdate())) + 639906
	AND		[user_id] = @user_id

	SELECT 	'Today' = @today, 
				'Past Due' = @past_due,
				'Future' = @future, 
				remind_time, 
				comment, 
				reminder_id
	FROM 		cc_reminders 
	WHERE 	[user_id] = @user_id
	ORDER BY remind_time

GO
GRANT EXECUTE ON  [dbo].[cc_activities_reminders_sp] TO [public]
GO
