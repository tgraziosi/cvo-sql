CREATE TABLE [dbo].[rpt_apusrapv]
(
[timestamp] [timestamp] NOT NULL,
[user_id] [smallint] NOT NULL,
[user_name] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[manager_level] [smallint] NOT NULL,
[amt_max] [float] NOT NULL,
[alt_mgr_level] [smallint] NOT NULL,
[symbol] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[curr_precision] [smallint] NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_apusrapv] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_apusrapv] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_apusrapv] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_apusrapv] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_apusrapv] TO [public]
GO
