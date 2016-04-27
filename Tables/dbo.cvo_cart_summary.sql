CREATE TABLE [dbo].[cvo_cart_summary]
(
[pick_date] [datetime] NULL,
[cart_no] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[pick_set] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[first_pick] [datetime] NULL,
[last_pick] [datetime] NULL,
[orders] [int] NULL,
[picks] [int] NULL,
[idle] [int] NULL,
[last_synced] [datetime] NULL
) ON [PRIMARY]
GO
