CREATE TABLE [dbo].[ESC_CashAppDet]
(
[ParentRecID] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[PayerCustCode] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CustCode] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[UserName] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SeqID] [int] NULL,
[TrxNum] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DocNum] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DocType] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DocDate] [int] NULL,
[DocDue] [int] NULL,
[DocAmt] [float] NULL,
[DocBal] [float] NULL,
[AmtApplied] [float] NULL,
[IncludeInPyt] [smallint] NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IDX01] ON [dbo].[ESC_CashAppDet] ([ParentRecID], [PayerCustCode], [CustCode], [SeqID]) WITH (ALLOW_PAGE_LOCKS=OFF) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ESC_CashAppDet_ix0] ON [dbo].[ESC_CashAppDet] ([ParentRecID], [SeqID]) WITH (ALLOW_PAGE_LOCKS=OFF) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[ESC_CashAppDet] TO [public]
GO
GRANT SELECT ON  [dbo].[ESC_CashAppDet] TO [public]
GO
GRANT INSERT ON  [dbo].[ESC_CashAppDet] TO [public]
GO
GRANT DELETE ON  [dbo].[ESC_CashAppDet] TO [public]
GO
GRANT UPDATE ON  [dbo].[ESC_CashAppDet] TO [public]
GO
