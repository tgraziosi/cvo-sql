CREATE TABLE [dbo].[tdc_ord_list]
(
[order_no] [int] NOT NULL,
[order_ext] [int] NOT NULL,
[line_no] [int] NOT NULL,
[retail_part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[customer_partno] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tdc_ord_list] ADD CONSTRAINT [PK_tdc_ord_list_1__13] PRIMARY KEY CLUSTERED  ([order_no], [order_ext], [line_no]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_ord_list] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_ord_list] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_ord_list] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_ord_list] TO [public]
GO
