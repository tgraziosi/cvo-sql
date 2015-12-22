CREATE TABLE [dbo].[OrganizationOrganizationTrx]
(
[timestamp] [timestamp] NOT NULL,
[controlling_org_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[detail_org_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[sequence_id] [int] NOT NULL,
[trx_type] [int] NOT NULL,
[tax_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[create_date] [datetime] NOT NULL,
[create_username] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[last_change_date] [datetime] NOT NULL,
[last_change_username] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[inherited_flag] [smallint] NOT NULL CONSTRAINT [DF__Organizat__inher__4C5283B6] DEFAULT ((0))
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [ootrx_ind_1] ON [dbo].[OrganizationOrganizationTrx] ([controlling_org_id], [detail_org_id], [trx_type]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[OrganizationOrganizationTrx] TO [public]
GO
GRANT SELECT ON  [dbo].[OrganizationOrganizationTrx] TO [public]
GO
GRANT INSERT ON  [dbo].[OrganizationOrganizationTrx] TO [public]
GO
GRANT DELETE ON  [dbo].[OrganizationOrganizationTrx] TO [public]
GO
GRANT UPDATE ON  [dbo].[OrganizationOrganizationTrx] TO [public]
GO
