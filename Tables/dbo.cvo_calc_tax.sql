CREATE TABLE [dbo].[cvo_calc_tax]
(
[order_no] [int] NULL,
[order_ext] [int] NULL,
[date_entered] [datetime] NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [cvo_calc_tax_ind0] ON [dbo].[cvo_calc_tax] ([order_no], [order_ext]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[cvo_calc_tax] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_calc_tax] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_calc_tax] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_calc_tax] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_calc_tax] TO [public]
GO
