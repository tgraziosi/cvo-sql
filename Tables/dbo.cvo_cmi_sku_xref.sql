CREATE TABLE [dbo].[cvo_cmi_sku_xref]
(
[dim_id] [int] NOT NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[upc_code] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[date_added] [datetime] NULL
) ON [PRIMARY]
GO
