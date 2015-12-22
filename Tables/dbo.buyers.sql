CREATE TABLE [dbo].[buyers]
(
[timestamp] [timestamp] NOT NULL,
[kys] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[void] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[void_who] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[void_date] [datetime] NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [buyer1] ON [dbo].[buyers] ([kys]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[buyers] TO [public]
GO
GRANT SELECT ON  [dbo].[buyers] TO [public]
GO
GRANT INSERT ON  [dbo].[buyers] TO [public]
GO
GRANT DELETE ON  [dbo].[buyers] TO [public]
GO
GRANT UPDATE ON  [dbo].[buyers] TO [public]
GO
