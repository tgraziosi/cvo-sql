CREATE TABLE [dbo].[cvo_replenish_schedule]
(
[replen_id] [int] NULL,
[bin_no] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[fill_opt] [int] NOT NULL,
[priority] [int] NOT NULL,
[station_id] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[userid] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[schedule_date] [datetime] NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[cvo_replenish_schedule] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_replenish_schedule] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_replenish_schedule] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_replenish_schedule] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_replenish_schedule] TO [public]
GO
