CREATE TABLE [dbo].[CVO_CreditHold_Sent]
(
[order_no] [int] NOT NULL,
[ext] [int] NOT NULL,
[notified] [datetime] NULL,
[hold_reason] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[cc_status] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[bg_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[cred_limit] [decimal] (20, 2) NULL,
[AR_balance] [decimal] (20, 2) NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [idx01] ON [dbo].[CVO_CreditHold_Sent] ([order_no], [ext]) ON [PRIMARY]
GO
