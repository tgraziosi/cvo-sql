CREATE TABLE [dbo].[CVOarnarelAudit]
(
[parent] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[child] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[relation_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[movement_flag] [smallint] NULL,
[audit_date] [int] NULL,
[audit_datetime] [smalldatetime] NULL
) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[CVOarnarelAudit] TO [public]
GO
GRANT INSERT ON  [dbo].[CVOarnarelAudit] TO [public]
GO
GRANT DELETE ON  [dbo].[CVOarnarelAudit] TO [public]
GO
GRANT UPDATE ON  [dbo].[CVOarnarelAudit] TO [public]
GO
