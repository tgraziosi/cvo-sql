CREATE TABLE [dbo].[apperror]
(
[timestamp] [timestamp] NOT NULL,
[form_id] [smallint] NOT NULL,
[form_number] [smallint] NOT NULL,
[error] [smallint] NOT NULL,
[date] [int] NOT NULL,
[time] [int] NOT NULL,
[message] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[user_name] [varchar] (31) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[application] [varchar] (31) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [apperror_ind_0] ON [dbo].[apperror] ([application], [user_name], [date], [time], [error]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[apperror] TO [public]
GO
GRANT SELECT ON  [dbo].[apperror] TO [public]
GO
GRANT INSERT ON  [dbo].[apperror] TO [public]
GO
GRANT DELETE ON  [dbo].[apperror] TO [public]
GO
GRANT UPDATE ON  [dbo].[apperror] TO [public]
GO
