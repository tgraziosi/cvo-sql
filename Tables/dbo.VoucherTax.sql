CREATE TABLE [dbo].[VoucherTax]
(
[DocumentReferenceID] [varchar] (128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[TaxTypeCode] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[BaseAmount] [float] NULL,
[CalculatedTaxAmount] [float] NULL,
[FinalTaxAmount] [float] NULL,
[RecoverableFlag] [float] NULL,
[APFooterGLTaxChartofAccount] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SequenceID] [int] NULL,
[DetailSequenceID] [int] NULL,
[TaxIncludedFlag] [smallint] NULL,
[TaxAmount] [float] NULL
) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[VoucherTax] TO [public]
GO
GRANT INSERT ON  [dbo].[VoucherTax] TO [public]
GO
GRANT DELETE ON  [dbo].[VoucherTax] TO [public]
GO
GRANT UPDATE ON  [dbo].[VoucherTax] TO [public]
GO
