CREATE TABLE [dbo].[OrganizationOrganizationDef]
(
[timestamp] [timestamp] NOT NULL,
[controlling_org_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[detail_org_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[sequence_id] [int] NOT NULL,
[account_mask] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[recipient_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[originator_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[create_date] [datetime] NOT NULL,
[create_username] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[last_change_date] [datetime] NOT NULL,
[last_change_username] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[inherited_flag] [smallint] NOT NULL CONSTRAINT [DF__Organizat__inher__5023149A] DEFAULT ((0))
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [ood_ind_1] ON [dbo].[OrganizationOrganizationDef] ([controlling_org_id], [detail_org_id], [sequence_id]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[OrganizationOrganizationDef] TO [public]
GO
GRANT SELECT ON  [dbo].[OrganizationOrganizationDef] TO [public]
GO
GRANT INSERT ON  [dbo].[OrganizationOrganizationDef] TO [public]
GO
GRANT DELETE ON  [dbo].[OrganizationOrganizationDef] TO [public]
GO
GRANT UPDATE ON  [dbo].[OrganizationOrganizationDef] TO [public]
GO
