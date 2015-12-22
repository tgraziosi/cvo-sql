CREATE TABLE [dbo].[cvo_Vendor_MOQ]
(
[Vendor_Code] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[MOQ_info] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[cvo_Vendor_MOQ] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_Vendor_MOQ] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_Vendor_MOQ] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_Vendor_MOQ] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_Vendor_MOQ] TO [public]
GO
