CREATE TABLE [dbo].[glactype]
(
[timestamp] [timestamp] NOT NULL,
[type_code] [smallint] NOT NULL,
[type_description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[consol_type] [smallint] NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [glactype_ind_0] ON [dbo].[glactype] ([type_code]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[glactype] TO [public]
GO
GRANT SELECT ON  [dbo].[glactype] TO [public]
GO
GRANT INSERT ON  [dbo].[glactype] TO [public]
GO
GRANT DELETE ON  [dbo].[glactype] TO [public]
GO
GRANT UPDATE ON  [dbo].[glactype] TO [public]
GO
