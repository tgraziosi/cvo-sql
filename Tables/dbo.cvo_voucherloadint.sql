CREATE TABLE [dbo].[cvo_voucherloadint]
(
[row] [int] NOT NULL IDENTITY(1, 1),
[vendor] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[name] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[type] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Inv/Cr Memo] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[TY] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CURENCY] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CONV RATE] [float] NULL,
[due date] [datetime] NULL,
[balance] [float] NULL,
[current] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[1-31 days] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[31-60 days] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[61-90 days] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[91 + days] [float] NULL,
[MISSING VCH] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[MISSING INV DATE] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[cvo_voucherloadint] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_voucherloadint] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_voucherloadint] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_voucherloadint] TO [public]
GO
