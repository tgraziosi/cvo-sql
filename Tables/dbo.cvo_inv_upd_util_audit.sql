CREATE TABLE [dbo].[cvo_inv_upd_util_audit]
(
[sku] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[process_user] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[process_date] [datetime] NULL,
[line_message] [varchar] (2500) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__cvo_inv_u__line___4CF63045] DEFAULT ('')
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[cvo_inv_upd_util_audit] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_inv_upd_util_audit] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_inv_upd_util_audit] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_inv_upd_util_audit] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_inv_upd_util_audit] TO [public]
GO
