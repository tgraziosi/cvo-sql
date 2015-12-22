CREATE TABLE [dbo].[organizationsecurity]
(
[timestamp] [timestamp] NOT NULL,
[organization_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[sequence_id] [int] NOT NULL,
[security_token] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[create_date] [datetime] NOT NULL,
[create_username] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[last_change_date] [datetime] NOT NULL,
[last_change_username] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[inherited_flag] [smallint] NOT NULL CONSTRAINT [DF_orgsec_inherited_flag] DEFAULT ((0))
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [organizationsecurity_ind_1] ON [dbo].[organizationsecurity] ([organization_id]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [organizationsecurity_ind_3] ON [dbo].[organizationsecurity] ([organization_id], [security_token]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [organizationsecurity_ind_2] ON [dbo].[organizationsecurity] ([security_token]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[organizationsecurity] TO [public]
GO
GRANT SELECT ON  [dbo].[organizationsecurity] TO [public]
GO
GRANT INSERT ON  [dbo].[organizationsecurity] TO [public]
GO
GRANT DELETE ON  [dbo].[organizationsecurity] TO [public]
GO
GRANT UPDATE ON  [dbo].[organizationsecurity] TO [public]
GO
