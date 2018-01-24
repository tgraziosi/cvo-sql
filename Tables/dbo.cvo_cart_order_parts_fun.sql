CREATE TABLE [dbo].[cvo_cart_order_parts_fun]
(
[id] [int] NOT NULL IDENTITY(1, 1),
[tran_id] [int] NULL,
[order_no] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[part_no] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[pick_status] [tinyint] NULL,
[updated] [datetime] NULL,
[user_login] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[bin_no] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[upc_code] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[qty_to_process] [int] NULL,
[scanned] [int] NULL,
[isSkipped] [tinyint] NULL,
[bin_group_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[type_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[cart_no] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[cvo_cart_order_parts_fun] ADD CONSTRAINT [PK__cvo_cart_order_p__765471A2] PRIMARY KEY CLUSTERED  ([id]) ON [PRIMARY]
GO
