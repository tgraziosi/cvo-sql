CREATE TABLE [dbo].[cvo_cart_order_parts]
(
[id] [int] NOT NULL IDENTITY(1, 1),
[tran_id] [int] NULL,
[order_no] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[part_no] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[pick_status] [tinyint] NULL CONSTRAINT [DF__cvo_cart___pick___13F453C1] DEFAULT ((0)),
[updated] [datetime] NULL,
[user_login] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[bin_no] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[upc_code] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[qty_to_process] [int] NULL,
[scanned] [int] NULL,
[isSkipped] [tinyint] NULL CONSTRAINT [DF__cvo_cart___isSki__7683EC6B] DEFAULT ((0)),
[bin_group_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[type_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[cart_no] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[cvo_cart_order_parts] ADD CONSTRAINT [PK__cvo_cart_order_p__13002F88] PRIMARY KEY CLUSTERED  ([id]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [CT_PTS] ON [dbo].[cvo_cart_order_parts] ([order_no], [bin_no], [user_login], [upc_code], [tran_id]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [cartparts] ON [dbo].[cvo_cart_order_parts] ([order_no], [upc_code], [user_login]) ON [PRIMARY]
GO
