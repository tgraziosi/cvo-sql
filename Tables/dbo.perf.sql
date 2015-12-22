CREATE TABLE [dbo].[perf]
(
[process_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[procedure_name] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[line_nbr] [smallint] NOT NULL,
[time_event] [datetime] NOT NULL,
[time_elapsed] [int] NOT NULL,
[comment] [varchar] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[perf] TO [public]
GO
GRANT SELECT ON  [dbo].[perf] TO [public]
GO
GRANT INSERT ON  [dbo].[perf] TO [public]
GO
GRANT DELETE ON  [dbo].[perf] TO [public]
GO
GRANT UPDATE ON  [dbo].[perf] TO [public]
GO
