CREATE TABLE [dbo].[exc_credit_fix]
(
[CUSTNO] [float] NULL,
[DOCUMENT] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[LINENO] [float] NULL,
[PARTNO] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DESC] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[QTY] [float] NULL,
[SELL] [float] NULL,
[LIST] [float] NULL,
[NEWLIST] [float] NULL
) ON [PRIMARY]
GO
