CREATE TABLE [dbo].[glprd]
(
[timestamp] [timestamp] NOT NULL,
[period_type] [smallint] NOT NULL,
[period_description] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[period_start_date] [int] NOT NULL,
[period_end_date] [int] NOT NULL,
[initialized_flag] [smallint] NOT NULL,
[period_percentage] [float] NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [glprd_ind_2] ON [dbo].[glprd] ([period_end_date], [period_type]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [glprd_ind_0] ON [dbo].[glprd] ([period_start_date], [period_end_date]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [glprd_ind_1] ON [dbo].[glprd] ([period_start_date], [period_type]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[glprd] TO [public]
GO
GRANT SELECT ON  [dbo].[glprd] TO [public]
GO
GRANT INSERT ON  [dbo].[glprd] TO [public]
GO
GRANT DELETE ON  [dbo].[glprd] TO [public]
GO
GRANT UPDATE ON  [dbo].[glprd] TO [public]
GO
