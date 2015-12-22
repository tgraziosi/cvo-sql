CREATE TABLE [dbo].[cvo_interim_order_updates]
(
[id] [int] NOT NULL IDENTITY(1, 1),
[order_no] [int] NULL,
[terms] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[req_ship_date] [datetime] NULL,
[sch_ship_date] [datetime] NULL,
[allocation_date] [datetime] NULL,
[ship_via] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[freight_allowed_type] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[order_ext] [int] NULL,
[userid] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[proc_flag] [int] NULL,
[err_msg] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[date_time] [datetime] NULL CONSTRAINT [DF__cvo_inter__date___39B93E9F] DEFAULT (getdate())
) ON [PRIMARY]
GO
