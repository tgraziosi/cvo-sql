CREATE TABLE [dbo].[OrganizationOrganizationRel]
(
[timestamp] [timestamp] NOT NULL,
[controlling_org_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[detail_org_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[sequence_id] [int] NOT NULL,
[effective_date] [int] NOT NULL,
[create_date] [datetime] NOT NULL,
[create_username] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[last_change_date] [datetime] NOT NULL,
[last_change_username] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[inherited_flag] [smallint] NOT NULL CONSTRAINT [DF__Organizat__inher__4E3ACC28] DEFAULT ((0))
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [oor_ind_1] ON [dbo].[OrganizationOrganizationRel] ([controlling_org_id], [detail_org_id]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[OrganizationOrganizationRel] TO [public]
GO
GRANT SELECT ON  [dbo].[OrganizationOrganizationRel] TO [public]
GO
GRANT INSERT ON  [dbo].[OrganizationOrganizationRel] TO [public]
GO
GRANT DELETE ON  [dbo].[OrganizationOrganizationRel] TO [public]
GO
GRANT UPDATE ON  [dbo].[OrganizationOrganizationRel] TO [public]
GO
