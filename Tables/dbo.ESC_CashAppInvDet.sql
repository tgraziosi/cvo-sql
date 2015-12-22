CREATE TABLE [dbo].[ESC_CashAppInvDet]
(
[ParentRecID] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SeqID] [int] NULL,
[PytTrx] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[PytDoc] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[PytApp] [float] NULL,
[InvDoc] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ApplyType] [smallint] NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IDX01] ON [dbo].[ESC_CashAppInvDet] ([ParentRecID], [SeqID], [PytDoc]) ON [PRIMARY]
GO
CREATE CLUSTERED INDEX [ESC_CashAppInvDet_ix0] ON [dbo].[ESC_CashAppInvDet] ([ParentRecID], [SeqID], [PytTrx]) WITH (ALLOW_PAGE_LOCKS=OFF) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[ESC_CashAppInvDet] TO [public]
GO
GRANT SELECT ON  [dbo].[ESC_CashAppInvDet] TO [public]
GO
GRANT INSERT ON  [dbo].[ESC_CashAppInvDet] TO [public]
GO
GRANT DELETE ON  [dbo].[ESC_CashAppInvDet] TO [public]
GO
GRANT UPDATE ON  [dbo].[ESC_CashAppInvDet] TO [public]
GO
