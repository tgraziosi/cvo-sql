CREATE TABLE [dbo].[CVO_Gender]
(
[timestamp] [timestamp] NOT NULL,
[kys] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[description] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[void] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[void_who] [char] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[void_date] [datetime] NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [idx_cvo_gender_cmi] ON [dbo].[CVO_Gender] ([description], [kys]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [idx_CVO_Gender] ON [dbo].[CVO_Gender] ([kys]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[CVO_Gender] TO [public]
GO
GRANT SELECT ON  [dbo].[CVO_Gender] TO [public]
GO
GRANT INSERT ON  [dbo].[CVO_Gender] TO [public]
GO
GRANT DELETE ON  [dbo].[CVO_Gender] TO [public]
GO
GRANT UPDATE ON  [dbo].[CVO_Gender] TO [public]
GO
