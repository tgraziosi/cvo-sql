CREATE TABLE [dbo].[ESC_CashAppAudit]
(
[ProcessDate] [datetime] NULL,
[UserName] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ParentRecID] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ProcessHdr] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ProcessStepID] [int] NULL,
[ProcessStepName] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ProcessValue] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ProcessResult] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[ESC_CashAppAudit] TO [public]
GO
GRANT SELECT ON  [dbo].[ESC_CashAppAudit] TO [public]
GO
GRANT INSERT ON  [dbo].[ESC_CashAppAudit] TO [public]
GO
GRANT DELETE ON  [dbo].[ESC_CashAppAudit] TO [public]
GO
GRANT UPDATE ON  [dbo].[ESC_CashAppAudit] TO [public]
GO
