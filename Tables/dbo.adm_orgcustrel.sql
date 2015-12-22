CREATE TABLE [dbo].[adm_orgcustrel]
(
[timestamp] [timestamp] NOT NULL,
[organization_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[related_org_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[customer_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[use_ind] [int] NOT NULL,
[row_id] [int] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [adm_orgcustrel1] ON [dbo].[adm_orgcustrel] ([customer_code]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [adm_orgcustrel2] ON [dbo].[adm_orgcustrel] ([organization_id], [related_org_id]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [adm_orgcustrel3] ON [dbo].[adm_orgcustrel] ([row_id]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[adm_orgcustrel] TO [public]
GO
GRANT SELECT ON  [dbo].[adm_orgcustrel] TO [public]
GO
GRANT INSERT ON  [dbo].[adm_orgcustrel] TO [public]
GO
GRANT DELETE ON  [dbo].[adm_orgcustrel] TO [public]
GO
GRANT UPDATE ON  [dbo].[adm_orgcustrel] TO [public]
GO
