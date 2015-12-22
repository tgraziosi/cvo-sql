CREATE TABLE [dbo].[ord_list_tax]
(
[timestamp] [timestamp] NOT NULL,
[order_no] [int] NOT NULL,
[order_ext] [int] NOT NULL,
[sequence_id] [int] NOT NULL,
[tax_type_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[amt_taxable] [float] NOT NULL,
[amt_gross] [float] NOT NULL,
[amt_tax] [float] NOT NULL,
[amt_final_tax] [float] NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [ord_list_tax_ind1] ON [dbo].[ord_list_tax] ([order_no], [order_ext], [sequence_id]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[ord_list_tax] TO [public]
GO
GRANT SELECT ON  [dbo].[ord_list_tax] TO [public]
GO
GRANT INSERT ON  [dbo].[ord_list_tax] TO [public]
GO
GRANT DELETE ON  [dbo].[ord_list_tax] TO [public]
GO
GRANT UPDATE ON  [dbo].[ord_list_tax] TO [public]
GO
