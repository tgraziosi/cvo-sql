CREATE TABLE [dbo].[cc_reminders]
(
[reminder_id] [int] NOT NULL,
[user_id] [smallint] NOT NULL,
[remind_time] [smalldatetime] NOT NULL,
[comment] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[cc_reminders] TO [public]
GO
GRANT SELECT ON  [dbo].[cc_reminders] TO [public]
GO
GRANT INSERT ON  [dbo].[cc_reminders] TO [public]
GO
GRANT DELETE ON  [dbo].[cc_reminders] TO [public]
GO
GRANT UPDATE ON  [dbo].[cc_reminders] TO [public]
GO
