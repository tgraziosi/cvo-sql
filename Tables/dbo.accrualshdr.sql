CREATE TABLE [dbo].[accrualshdr]
(
[timestamp] [timestamp] NOT NULL,
[accrual_number] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[org_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[user_id] [smallint] NOT NULL,
[period_end_date] [int] NOT NULL,
[posted_flag] [int] NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[accrualshdr] TO [public]
GO
GRANT SELECT ON  [dbo].[accrualshdr] TO [public]
GO
GRANT INSERT ON  [dbo].[accrualshdr] TO [public]
GO
GRANT DELETE ON  [dbo].[accrualshdr] TO [public]
GO
GRANT UPDATE ON  [dbo].[accrualshdr] TO [public]
GO
