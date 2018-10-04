CREATE TABLE [dbo].[cvo_svc_invites]
(
[id] [int] NOT NULL IDENTITY(1, 1),
[invite_date] [datetime] NULL,
[unique_code] [varchar] (128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[territory_code] [varchar] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[user_login] [varchar] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[account_no] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ship_to] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[contact] [varchar] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[email] [varchar] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[is_active] [tinyint] NULL CONSTRAINT [DF__cvo_svc_i__is_ac__6A6DBDAA] DEFAULT ('1'),
[order_no] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[order_date] [datetime] NULL,
[program] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[show_min_inv_qty] [int] NULL,
[order_min_qty] [int] NULL,
[is_closeout] [tinyint] NULL CONSTRAINT [DF__cvo_svc_i__is_cl__6B61E1E3] DEFAULT ('0'),
[is_read] [tinyint] NULL CONSTRAINT [DF__cvo_svc_i__is_re__6C56061C] DEFAULT ('0'),
[date_read] [datetime] NULL,
[isOpened] [tinyint] NULL CONSTRAINT [DF__cvo_svc_i__isOpe__6D4A2A55] DEFAULT ('0'),
[date_opened] [datetime] NULL,
[bch] [tinyint] NULL CONSTRAINT [DF__cvo_svc_inv__bch__3A005BD0] DEFAULT ((0)),
[bch_show] [int] NULL CONSTRAINT [DF__cvo_svc_i__bch_s__3AF48009] DEFAULT ((1)),
[bch_order] [int] NULL CONSTRAINT [DF__cvo_svc_i__bch_o__3BE8A442] DEFAULT ((36)),
[cst_bch] [tinyint] NULL CONSTRAINT [DF__cvo_svc_i__cst_b__3CDCC87B] DEFAULT ((0))
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[cvo_svc_invites] ADD CONSTRAINT [PK__cvo_svc_invites__69799971] PRIMARY KEY CLUSTERED  ([id]) ON [PRIMARY]
GO
