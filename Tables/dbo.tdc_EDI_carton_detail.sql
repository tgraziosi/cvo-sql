CREATE TABLE [dbo].[tdc_EDI_carton_detail]
(
[ASN] [int] NOT NULL,
[carton_no] [int] NOT NULL,
[order_no] [int] NOT NULL,
[line_no] [int] NOT NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[qty_packed] [decimal] (20, 8) NOT NULL,
[uom] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[weight] [decimal] (20, 8) NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tdc_EDI_carton_detail] ADD CONSTRAINT [PK_tdc_EDI_carton_detail] PRIMARY KEY NONCLUSTERED  ([ASN], [carton_no], [order_no], [line_no], [part_no]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_EDI_carton_detail] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_EDI_carton_detail] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_EDI_carton_detail] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_EDI_carton_detail] TO [public]
GO
