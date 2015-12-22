CREATE TABLE [dbo].[tdc_3pl_quotation_inventory_costs_tbl]
(
[quote_id] [int] NULL,
[line_no] [int] NULL,
[inv_cost_description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[inv_qty] [decimal] (20, 8) NOT NULL,
[inv_cost_amount] [decimal] (20, 8) NOT NULL
) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_3pl_quotation_inventory_costs_tbl] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_3pl_quotation_inventory_costs_tbl] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_3pl_quotation_inventory_costs_tbl] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_3pl_quotation_inventory_costs_tbl] TO [public]
GO
