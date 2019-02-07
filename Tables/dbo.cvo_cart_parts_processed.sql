CREATE TABLE [dbo].[cvo_cart_parts_processed]
(
[tran_id] [int] NULL,
[order_no] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[part_no] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[updated] [datetime] NULL,
[user_login] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[bin_no] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[qty_to_process] [int] NULL,
[scanned] [int] NULL,
[isPicked] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__cvo_cart___isPic__4B998E66] DEFAULT ('N'),
[upc_code] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[bin_group_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[pick_complete_dt] [datetime] NULL,
[type_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[cart_no] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[isSkipped] [tinyint] NULL CONSTRAINT [DF__cvo_cart___isSki__12676BC2] DEFAULT ((0)),
[pick_source] [varchar] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [PR_PARTS] ON [dbo].[cvo_cart_parts_processed] ([order_no], [user_login], [part_no], [cart_no], [type_code], [isPicked]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [cvo_cart_parts_tranid_idx] ON [dbo].[cvo_cart_parts_processed] ([tran_id]) INCLUDE ([isPicked]) ON [PRIMARY]
GO
