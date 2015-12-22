CREATE TABLE [dbo].[csg_frame_fix_backup]
(
[order_no] [int] NOT NULL,
[order_ext] [int] NOT NULL,
[line_no] [int] NOT NULL,
[add_case] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[add_pattern] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[from_line_no] [int] NULL,
[is_case] [int] NULL,
[is_pattern] [int] NULL,
[add_polarized] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[is_polarized] [int] NULL,
[is_pop_gif] [int] NULL,
[is_amt_disc] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[amt_disc] [decimal] (20, 8) NULL,
[is_customized] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[promo_item] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[list_price] [decimal] (20, 8) NULL,
[orig_list_price] [decimal] (20, 8) NULL,
[free_frame] [smallint] NULL
) ON [PRIMARY]
GO
