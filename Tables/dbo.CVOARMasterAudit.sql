CREATE TABLE [dbo].[CVOARMasterAudit]
(
[field_name] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[field_from] [varchar] (60) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[field_to] [varchar] (60) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[customer_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ship_to_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[movement_flag] [smallint] NULL,
[audit_date] [smalldatetime] NULL,
[user_id] [varchar] (60) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[CVOARMasterAudit] TO [public]
GO
GRANT SELECT ON  [dbo].[CVOARMasterAudit] TO [public]
GO
GRANT INSERT ON  [dbo].[CVOARMasterAudit] TO [public]
GO
GRANT DELETE ON  [dbo].[CVOARMasterAudit] TO [public]
GO
GRANT UPDATE ON  [dbo].[CVOARMasterAudit] TO [public]
GO
