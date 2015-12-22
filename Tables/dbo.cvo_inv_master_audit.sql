CREATE TABLE [dbo].[cvo_inv_master_audit]
(
[field_name] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[field_from] [varchar] (60) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[field_to] [varchar] (60) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[part_no] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[movement_flag] [smallint] NULL,
[audit_date] [smalldatetime] NULL,
[user_id] [varchar] (60) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[id] [int] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [inv_master_add_audit_ind_0] ON [dbo].[cvo_inv_master_audit] ([id], [audit_date], [part_no]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[cvo_inv_master_audit] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_inv_master_audit] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_inv_master_audit] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_inv_master_audit] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_inv_master_audit] TO [public]
GO
