CREATE TABLE [dbo].[cvo_price_log]
(
[trxdate] [datetime] NULL,
[ordno] [int] NULL,
[ext] [int] NULL,
[custcode] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[partno] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ordqty] [decimal] (20, 8) NULL,
[price] [decimal] (20, 8) NULL,
[mesg] [varchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
