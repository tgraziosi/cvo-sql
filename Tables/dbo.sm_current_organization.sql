CREATE TABLE [dbo].[sm_current_organization]
(
[timestamp] [timestamp] NOT NULL,
[name] [sys].[sysname] NOT NULL,
[org_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[asof] [datetime] NOT NULL,
[organization_name] [varchar] (60) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[sm_current_organization] TO [public]
GO
GRANT SELECT ON  [dbo].[sm_current_organization] TO [public]
GO
GRANT INSERT ON  [dbo].[sm_current_organization] TO [public]
GO
GRANT DELETE ON  [dbo].[sm_current_organization] TO [public]
GO
GRANT UPDATE ON  [dbo].[sm_current_organization] TO [public]
GO
