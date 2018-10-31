CREATE TABLE [dbo].[cvo_single_piece_log]
(
[id] [int] NOT NULL IDENTITY(1, 1),
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[from_bin] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[to_bin] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[qty] [decimal] (20, 8) NOT NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[flag] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[addTime] [datetime] NULL,
[procTime] [datetime] NULL,
[sp_user] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
