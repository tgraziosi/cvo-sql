CREATE TABLE [dbo].[cvo_charge_sc]
(
[order_no] [int] NULL,
[order_ext] [int] NULL,
[sc_no] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[sc_order_no] [int] NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [cvo_charge_sc_ind0] ON [dbo].[cvo_charge_sc] ([order_no], [order_ext]) ON [PRIMARY]
GO
GRANT DELETE ON  [dbo].[cvo_charge_sc] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_charge_sc] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_charge_sc] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_charge_sc] TO [public]
GO
