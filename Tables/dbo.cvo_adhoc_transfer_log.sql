CREATE TABLE [dbo].[cvo_adhoc_transfer_log]
(
[id] [int] NOT NULL IDENTITY(1, 1),
[userid] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[qty] [decimal] (20, 8) NOT NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[from_bin] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[to_bin] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[moveDate] [datetime] NULL
) ON [PRIMARY]
GO
