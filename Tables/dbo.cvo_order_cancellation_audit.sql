CREATE TABLE [dbo].[cvo_order_cancellation_audit]
(
[order_no] [int] NULL,
[order_ext] [int] NULL,
[who_cancelled] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[when_cancelled] [datetime] NULL,
[change_type] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[cvo_order_cancellation_audit] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_order_cancellation_audit] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_order_cancellation_audit] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_order_cancellation_audit] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_order_cancellation_audit] TO [public]
GO
