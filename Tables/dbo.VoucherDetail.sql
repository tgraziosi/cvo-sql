CREATE TABLE [dbo].[VoucherDetail]
(
[DocumentReferenceID] [varchar] (128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SequenceID] [int] NULL,
[QtyOrdered] [float] NULL,
[QtyReceived] [float] NULL,
[QtyReturned] [float] NULL,
[UnitPrice] [float] NULL,
[TaxCode] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ReturnCode] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[POControlNumber] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[AmountDiscount] [float] NULL,
[AmountFreight] [float] NULL,
[AmountTax] [float] NULL,
[AmountMisc] [float] NULL,
[AmountExtended] [float] NULL,
[GLExpenseAccount] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[LineDescription] [varchar] (60) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[UOM] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ItemCode] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[GLReferenceCode] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ApprovalCode] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[LocationCode] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ProjectCode] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[RevisionNum] [int] NULL,
[TaskUID] [int] NULL,
[ExpenseTypeCode] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ResourceID] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ExpenseID] [int] NULL,
[PrepaidFlag] [int] NULL,
[Origin] [int] NULL,
[ClosedFlag] [int] NULL,
[InterCompanyTransactionFlag] [int] NULL,
[ProjectSiteURN] [varchar] (128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CompanyID] [smallint] NULL,
[RecCompanyCode] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[OrganizationID] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[VoucherDetail] TO [public]
GO
GRANT INSERT ON  [dbo].[VoucherDetail] TO [public]
GO
GRANT DELETE ON  [dbo].[VoucherDetail] TO [public]
GO
GRANT UPDATE ON  [dbo].[VoucherDetail] TO [public]
GO
