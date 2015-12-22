CREATE TABLE [dbo].[VoucherHeader]
(
[DocumentReferenceID] [varchar] (128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DocumentType] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DocumentControlNumber] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[POControlNumber] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[VendorOrderNumber] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[TicketNumber] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DateDocument] [varchar] (19) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DateApplied] [varchar] (19) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DateAging] [varchar] (19) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DateDue] [varchar] (19) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DateEntered] [varchar] (19) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DateReceived] [varchar] (19) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DateRequired] [varchar] (19) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DateDiscount] [varchar] (19) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[PostingCode] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[VendorCode] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[BranchCode] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ClassCode] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CommentCode] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[FobCode] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[TermsCode] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[PaymentCode] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[TaxCode] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[HoldFlag] [smallint] NULL,
[HoldDescription] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ApprovalFlag] [smallint] NULL,
[RecurringFlag] [smallint] NULL,
[RecurringCode] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[AmountFreight] [float] NULL,
[AmountMisc] [float] NULL,
[AmountDiscount] [float] NULL,
[DocDescription] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[PayToCode] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[PayToAddress1] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[PayToAddress2] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[PayToAddress3] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[PayToAddress4] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[PayToAddress5] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[PayToAddress6] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[AttentionName] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[AttentionPhone] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[TransactionCurrency] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[HomeRateType] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[OperationalRateType] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[HomeRate] [float] NULL,
[OperationalRate] [float] NULL,
[HomeRateOperator] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[OperationalRateOperator] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CalculateTaxMode] [smallint] NULL,
[ApplyToControlNumber] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[BackOfficeInterCompanyFlag] [smallint] NULL,
[OrganizationID] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ApprovalCode] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[user_trx_type_code] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[VoucherHeader] TO [public]
GO
GRANT INSERT ON  [dbo].[VoucherHeader] TO [public]
GO
GRANT DELETE ON  [dbo].[VoucherHeader] TO [public]
GO
GRANT UPDATE ON  [dbo].[VoucherHeader] TO [public]
GO
