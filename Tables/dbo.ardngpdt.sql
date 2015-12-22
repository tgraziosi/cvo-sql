CREATE TABLE [dbo].[ardngpdt]
(
[timestamp] [timestamp] NOT NULL,
[group_id] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[message_id] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[dunning_level] [smallint] NOT NULL,
[separation_days] [smallint] NOT NULL,
[fin_chg_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[ardngpdt] ADD CONSTRAINT [PK__ardngpdt__54DDA816] PRIMARY KEY CLUSTERED  ([dunning_level], [group_id]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[ardngpdt] TO [public]
GO
GRANT SELECT ON  [dbo].[ardngpdt] TO [public]
GO
GRANT INSERT ON  [dbo].[ardngpdt] TO [public]
GO
GRANT DELETE ON  [dbo].[ardngpdt] TO [public]
GO
GRANT UPDATE ON  [dbo].[ardngpdt] TO [public]
GO
