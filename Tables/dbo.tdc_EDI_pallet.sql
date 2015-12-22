CREATE TABLE [dbo].[tdc_EDI_pallet]
(
[ASN] [int] NOT NULL,
[pallet_no] [int] NOT NULL,
[carton_no] [int] NOT NULL,
[EPC_TAG] [varchar] (24) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[num_of_cartons] [int] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tdc_EDI_pallet] ADD CONSTRAINT [PK_tdc_EDI_pallet] PRIMARY KEY NONCLUSTERED  ([ASN], [pallet_no], [carton_no]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_EDI_pallet] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_EDI_pallet] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_EDI_pallet] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_EDI_pallet] TO [public]
GO
