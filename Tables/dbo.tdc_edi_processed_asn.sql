CREATE TABLE [dbo].[tdc_edi_processed_asn]
(
[asn] [int] NOT NULL,
[cust_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[cust_po] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ship_to] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[date_added] [datetime] NULL
) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_edi_processed_asn] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_edi_processed_asn] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_edi_processed_asn] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_edi_processed_asn] TO [public]
GO
