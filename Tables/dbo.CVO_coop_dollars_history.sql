CREATE TABLE [dbo].[CVO_coop_dollars_history]
(
[order_no] [int] NOT NULL,
[order_ext] [int] NOT NULL,
[coop_dollars] [decimal] (20, 8) NOT NULL,
[coop_date] [datetime] NOT NULL,
[customer_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [cvo_coop_ind_cust] ON [dbo].[CVO_coop_dollars_history] ([customer_code]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [cvo_coop_ind_cust_date] ON [dbo].[CVO_coop_dollars_history] ([customer_code], [coop_date]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_CVO_coop_dollars_history] ON [dbo].[CVO_coop_dollars_history] ([order_no], [order_ext]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[CVO_coop_dollars_history] TO [public]
GO
GRANT SELECT ON  [dbo].[CVO_coop_dollars_history] TO [public]
GO
GRANT INSERT ON  [dbo].[CVO_coop_dollars_history] TO [public]
GO
GRANT DELETE ON  [dbo].[CVO_coop_dollars_history] TO [public]
GO
GRANT UPDATE ON  [dbo].[CVO_coop_dollars_history] TO [public]
GO
