CREATE TABLE [dbo].[ESC_CashAppHdr]
(
[ParentRecID] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[PayerCustCode] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[UserName] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CheckNum] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CheckDate] [int] NULL,
[CheckAmt] [float] NULL,
[StatementDate] [int] NULL,
[PytCode] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[RemBalance] [float] NULL,
[RemChkBal] [float] NULL,
[RemCrmBal] [float] NULL
) ON [PRIMARY]
GO
CREATE CLUSTERED INDEX [ESC_CashAppHdr_ix0] ON [dbo].[ESC_CashAppHdr] ([ParentRecID]) WITH (ALLOW_PAGE_LOCKS=OFF) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [idx02] ON [dbo].[ESC_CashAppHdr] ([PayerCustCode]) WITH (ALLOW_PAGE_LOCKS=OFF) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [idx03] ON [dbo].[ESC_CashAppHdr] ([PayerCustCode], [CheckNum]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[ESC_CashAppHdr] TO [public]
GO
GRANT SELECT ON  [dbo].[ESC_CashAppHdr] TO [public]
GO
GRANT INSERT ON  [dbo].[ESC_CashAppHdr] TO [public]
GO
GRANT DELETE ON  [dbo].[ESC_CashAppHdr] TO [public]
GO
GRANT UPDATE ON  [dbo].[ESC_CashAppHdr] TO [public]
GO
