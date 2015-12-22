CREATE TABLE [dbo].[ardngphd]
(
[timestamp] [timestamp] NOT NULL,
[group_id] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[group_description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[group_sep_day] [int] NOT NULL CONSTRAINT [DF__ardngphd__group___57BA14C1] DEFAULT ((1))
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[ardngphd] ADD CONSTRAINT [PK__ardngphd__56C5F088] PRIMARY KEY CLUSTERED  ([group_id]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[ardngphd] TO [public]
GO
GRANT SELECT ON  [dbo].[ardngphd] TO [public]
GO
GRANT INSERT ON  [dbo].[ardngphd] TO [public]
GO
GRANT DELETE ON  [dbo].[ardngphd] TO [public]
GO
GRANT UPDATE ON  [dbo].[ardngphd] TO [public]
GO
