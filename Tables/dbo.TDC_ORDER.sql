CREATE TABLE [dbo].[TDC_ORDER]
(
[Order_no] [int] NOT NULL,
[Order_ext] [int] NOT NULL,
[TDC_status] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[total_cartons] [int] NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[TDC_ORDER] ADD CONSTRAINT [pk_tdc_order] PRIMARY KEY NONCLUSTERED  ([Order_no], [Order_ext]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[TDC_ORDER] TO [public]
GO
GRANT INSERT ON  [dbo].[TDC_ORDER] TO [public]
GO
GRANT DELETE ON  [dbo].[TDC_ORDER] TO [public]
GO
GRANT UPDATE ON  [dbo].[TDC_ORDER] TO [public]
GO
