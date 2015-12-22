CREATE TABLE [dbo].[ivabc]
(
[timestamp] [timestamp] NOT NULL,
[abc_value] [smallint] NOT NULL,
[abc_abbrev] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [ivabc_ind_0] ON [dbo].[ivabc] ([abc_value]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[ivabc] TO [public]
GO
GRANT SELECT ON  [dbo].[ivabc] TO [public]
GO
GRANT INSERT ON  [dbo].[ivabc] TO [public]
GO
GRANT DELETE ON  [dbo].[ivabc] TO [public]
GO
GRANT UPDATE ON  [dbo].[ivabc] TO [public]
GO
