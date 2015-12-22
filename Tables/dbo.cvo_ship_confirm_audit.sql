CREATE TABLE [dbo].[cvo_ship_confirm_audit]
(
[process_run_date] [datetime] NULL,
[stage_no] [varchar] (11) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[masterpack_no] [int] NULL,
[masterpack_flag] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[carton_no] [int] NULL,
[error_result] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [cvo_ship_confirm_audit_ind0] ON [dbo].[cvo_ship_confirm_audit] ([stage_no]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[cvo_ship_confirm_audit] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_ship_confirm_audit] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_ship_confirm_audit] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_ship_confirm_audit] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_ship_confirm_audit] TO [public]
GO
