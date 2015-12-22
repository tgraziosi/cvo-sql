CREATE TABLE [dbo].[adm_orgvendrel]
(
[timestamp] [timestamp] NOT NULL,
[organization_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[related_org_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[vendor_code] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[use_ind] [int] NOT NULL,
[row_id] [int] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [adm_orgvendrel2] ON [dbo].[adm_orgvendrel] ([organization_id], [related_org_id]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [adm_orgvendrel3] ON [dbo].[adm_orgvendrel] ([row_id]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [adm_orgvendrel1] ON [dbo].[adm_orgvendrel] ([vendor_code]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[adm_orgvendrel] TO [public]
GO
GRANT SELECT ON  [dbo].[adm_orgvendrel] TO [public]
GO
GRANT INSERT ON  [dbo].[adm_orgvendrel] TO [public]
GO
GRANT DELETE ON  [dbo].[adm_orgvendrel] TO [public]
GO
GRANT UPDATE ON  [dbo].[adm_orgvendrel] TO [public]
GO
