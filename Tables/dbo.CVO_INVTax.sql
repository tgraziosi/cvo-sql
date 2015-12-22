CREATE TABLE [dbo].[CVO_INVTax]
(
[DocumentReferenceID] [varchar] (128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[TaxTypeCode] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[TaxAmount] [float] NULL,
[TaxIncludedFlag] [smallint] NULL
) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[CVO_INVTax] TO [public]
GO
GRANT INSERT ON  [dbo].[CVO_INVTax] TO [public]
GO
GRANT DELETE ON  [dbo].[CVO_INVTax] TO [public]
GO
GRANT UPDATE ON  [dbo].[CVO_INVTax] TO [public]
GO
