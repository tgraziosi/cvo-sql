CREATE TABLE [dbo].[rpt_appadedt]
(
[seq_by] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ttl_count] [int] NOT NULL,
[ttl_disc] [float] NOT NULL,
[ttl_pmts] [float] NOT NULL,
[hold_count] [int] NOT NULL,
[hold_disc] [float] NOT NULL,
[hold_pmts] [float] NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_appadedt] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_appadedt] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_appadedt] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_appadedt] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_appadedt] TO [public]
GO
