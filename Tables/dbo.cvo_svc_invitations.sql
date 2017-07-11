CREATE TABLE [dbo].[cvo_svc_invitations]
(
[account_no] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[email] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[unique_code] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[territory] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[user_login] [varchar] (18) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[isActive] [smallint] NULL CONSTRAINT [DF__cvo_svc_i__isAct__7E273E6E] DEFAULT ((1)),
[order_no] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[invite_date] [datetime] NULL,
[order_date] [datetime] NULL,
[sv] [smallint] NULL CONSTRAINT [DF__cvo_svc_invi__sv__431D1DE7] DEFAULT ((0)),
[qop] [smallint] NULL CONSTRAINT [DF__cvo_svc_inv__qop__44114220] DEFAULT ((0)),
[eor] [smallint] NULL CONSTRAINT [DF__cvo_svc_inv__eor__45056659] DEFAULT ((0)),
[suns] [tinyint] NULL CONSTRAINT [DF__cvo_svc_in__suns__7257FB14] DEFAULT ((0)),
[sv_show] [int] NULL CONSTRAINT [DF__cvo_svc_i__sv_sh__5586B23C] DEFAULT ((1)),
[qop_show] [int] NULL CONSTRAINT [DF__cvo_svc_i__qop_s__567AD675] DEFAULT ((1)),
[eor_show] [int] NULL CONSTRAINT [DF__cvo_svc_i__eor_s__576EFAAE] DEFAULT ((1)),
[suns_show] [int] NULL CONSTRAINT [DF__cvo_svc_i__suns___58631EE7] DEFAULT ((1)),
[sv_order] [int] NULL CONSTRAINT [DF__cvo_svc_i__sv_or__59574320] DEFAULT ((1)),
[qop_order] [int] NULL CONSTRAINT [DF__cvo_svc_i__qop_o__5A4B6759] DEFAULT ((1)),
[eor_order] [int] NULL CONSTRAINT [DF__cvo_svc_i__eor_o__5B3F8B92] DEFAULT ((1)),
[suns_order] [int] NULL CONSTRAINT [DF__cvo_svc_i__suns___5C33AFCB] DEFAULT ((1)),
[isDefault] [tinyint] NULL CONSTRAINT [DF__cvo_svc_i__isDef__53345576] DEFAULT ((0)),
[isCustom] [tinyint] NULL CONSTRAINT [DF__cvo_svc_i__isCus__542879AF] DEFAULT ((0)),
[cst_sv] [tinyint] NULL CONSTRAINT [DF__cvo_svc_i__cst_s__551C9DE8] DEFAULT ((0)),
[cst_qop] [tinyint] NULL CONSTRAINT [DF__cvo_svc_i__cst_q__5610C221] DEFAULT ((0)),
[cst_eor] [tinyint] NULL CONSTRAINT [DF__cvo_svc_i__cst_e__5704E65A] DEFAULT ((0)),
[cst_show] [int] NULL CONSTRAINT [DF__cvo_svc_i__cst_s__57F90A93] DEFAULT ((1)),
[cst_order] [int] NULL CONSTRAINT [DF__cvo_svc_i__cst_o__58ED2ECC] DEFAULT ((1)),
[note] [varchar] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ship_to] [char] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[suns_sp] [smallint] NULL CONSTRAINT [DF__cvo_svc_i__suns___40AC5C3E] DEFAULT ((0)),
[suns_sp_show] [smallint] NULL CONSTRAINT [DF__cvo_svc_i__suns___41A08077] DEFAULT ((1)),
[suns_sp_order] [smallint] NULL CONSTRAINT [DF__cvo_svc_i__suns___4294A4B0] DEFAULT ((1)),
[cst_suns_sp] [smallint] NULL,
[aspire] [smallint] NULL CONSTRAINT [DF__cvo_svc_i__aspir__475959CD] DEFAULT ((0)),
[aspire_show] [smallint] NULL CONSTRAINT [DF__cvo_svc_i__aspir__484D7E06] DEFAULT ((1)),
[aspire_order] [smallint] NULL CONSTRAINT [DF__cvo_svc_i__aspir__4941A23F] DEFAULT ((1)),
[cst_aspire] [smallint] NULL,
[sv_pom] [tinyint] NULL CONSTRAINT [DF__cvo_svc_i__sv_po__63D7FEEF] DEFAULT ((0)),
[ch] [tinyint] NULL,
[ch_show] [tinyint] NULL,
[ch_order] [int] NULL,
[chs] [tinyint] NULL,
[chs_show] [int] NULL,
[chs_order] [int] NULL,
[sunps] [tinyint] NULL CONSTRAINT [DF__cvo_svc_i__sunps__765DC7EC] DEFAULT ('0'),
[sunps_show] [int] NULL CONSTRAINT [DF__cvo_svc_i__sunps__7751EC25] DEFAULT ('0'),
[sunps_order] [int] NULL CONSTRAINT [DF__cvo_svc_i__sunps__7846105E] DEFAULT ('0'),
[sunps_new] [int] NULL,
[sunps_new_show] [int] NULL,
[sunps_new_order] [int] NULL,
[incr] [tinyint] NULL CONSTRAINT [DF__cvo_svc_in__incr__62ABD4FA] DEFAULT ('1'),
[list_no] [int] NULL,
[isRead] [int] NULL CONSTRAINT [DF__cvo_svc_i__isRea__00072DB7] DEFAULT ('0'),
[isOpened] [int] NULL CONSTRAINT [DF__cvo_svc_i__isOpe__00FB51F0] DEFAULT ('0'),
[readDate] [datetime] NULL,
[openedDate] [datetime] NULL,
[response] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[me] [tinyint] NULL CONSTRAINT [DF__cvo_svc_invi__me__3D9A4BDC] DEFAULT ('0'),
[me_show] [tinyint] NULL CONSTRAINT [DF__cvo_svc_i__me_sh__3E8E7015] DEFAULT ('1'),
[me_order] [int] NULL,
[kd] [tinyint] NULL CONSTRAINT [DF__cvo_svc_invi__kd__5DE7EB34] DEFAULT ('0'),
[kd_show] [int] NULL CONSTRAINT [DF__cvo_svc_i__kd_sh__5EDC0F6D] DEFAULT ('0'),
[kd_order] [int] NULL CONSTRAINT [DF__cvo_svc_i__kd_or__5FD033A6] DEFAULT ('0')
) ON [PRIMARY]
GO
