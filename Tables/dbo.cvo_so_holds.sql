CREATE TABLE [dbo].[cvo_so_holds]
(
[order_no] [int] NULL,
[order_ext] [int] NULL,
[hold_reason] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[hold_priority] [int] NULL,
[hold_user] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[hold_date] [datetime] NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [cvo_so_holds_ind1] ON [dbo].[cvo_so_holds] ([order_no], [order_ext], [hold_priority], [hold_date]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [cvo_so_holds_ind0] ON [dbo].[cvo_so_holds] ([order_no], [order_ext], [hold_reason]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[cvo_so_holds] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_so_holds] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_so_holds] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_so_holds] TO [public]
GO
