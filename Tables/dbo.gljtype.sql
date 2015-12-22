CREATE TABLE [dbo].[gljtype]
(
[timestamp] [timestamp] NOT NULL,
[journal_type] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[type_description] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [gljtype_ind_0] ON [dbo].[gljtype] ([journal_type]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[gljtype] TO [public]
GO
GRANT SELECT ON  [dbo].[gljtype] TO [public]
GO
GRANT INSERT ON  [dbo].[gljtype] TO [public]
GO
GRANT DELETE ON  [dbo].[gljtype] TO [public]
GO
GRANT UPDATE ON  [dbo].[gljtype] TO [public]
GO
