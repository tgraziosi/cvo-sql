CREATE TABLE [dbo].[cvo_buying_group_switch_audit]
(
[audit_date] [datetime] NULL,
[userid] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[rec_type] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[parent] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[child] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[buying_group_no] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[action_date] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[cvo_buying_group_switch_audit] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_buying_group_switch_audit] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_buying_group_switch_audit] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_buying_group_switch_audit] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_buying_group_switch_audit] TO [public]
GO
