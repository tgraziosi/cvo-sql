CREATE TABLE [dbo].[tdc_EDI_carton_header]
(
[ASN] [int] NOT NULL,
[carton_no] [int] NOT NULL,
[package_type] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__tdc_EDI_c__packa__1B135B39] DEFAULT ('PP'),
[weight] [decimal] (20, 8) NOT NULL,
[weight_uom] [varchar] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[trailer_id] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[height] [decimal] (20, 8) NULL,
[width] [decimal] (20, 8) NULL,
[length] [decimal] (20, 8) NULL,
[EPC_TAG] [varchar] (24) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[tracking_no] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [tdc_EDI_carton_header_IDX1] ON [dbo].[tdc_EDI_carton_header] ([ASN], [carton_no]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_EDI_carton_header] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_EDI_carton_header] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_EDI_carton_header] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_EDI_carton_header] TO [public]
GO
