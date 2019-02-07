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
[ship_to] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
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
[kd_order] [int] NULL CONSTRAINT [DF__cvo_svc_i__kd_or__5FD033A6] DEFAULT ('0'),
[bs] [tinyint] NULL,
[cst_kd] [tinyint] NULL,
[cst_bs] [tinyint] NULL,
[bs_show] [int] NULL,
[bs_order] [int] NULL,
[sdbt] [tinyint] NULL CONSTRAINT [DF__cvo_svc_in__sdbt__69999502] DEFAULT ((0)),
[sdbt_show] [int] NULL CONSTRAINT [DF__cvo_svc_i__sdbt___6A8DB93B] DEFAULT ((0)),
[sdbt_order] [int] NULL CONSTRAINT [DF__cvo_svc_i__sdbt___6B81DD74] DEFAULT ((0)),
[sdfs] [tinyint] NULL CONSTRAINT [DF__cvo_svc_in__sdfs__6C7601AD] DEFAULT ((0)),
[sdfs_show] [int] NULL CONSTRAINT [DF__cvo_svc_i__sdfs___6D6A25E6] DEFAULT ((0)),
[sdfs_order] [int] NULL CONSTRAINT [DF__cvo_svc_i__sdfs___6E5E4A1F] DEFAULT ((0)),
[sdop] [tinyint] NULL CONSTRAINT [DF__cvo_svc_in__sdop__6F526E58] DEFAULT ((0)),
[sdop_show] [int] NULL CONSTRAINT [DF__cvo_svc_i__sdop___70469291] DEFAULT ((0)),
[sdop_order] [int] NULL CONSTRAINT [DF__cvo_svc_i__sdop___713AB6CA] DEFAULT ((0)),
[sdrv] [tinyint] NULL CONSTRAINT [DF__cvo_svc_in__sdrv__722EDB03] DEFAULT ((0)),
[sdrv_show] [int] NULL CONSTRAINT [DF__cvo_svc_i__sdrv___7322FF3C] DEFAULT ((0)),
[sdrv_order] [int] NULL CONSTRAINT [DF__cvo_svc_i__sdrv___74172375] DEFAULT ((0)),
[cst_ssl] [tinyint] NULL CONSTRAINT [DF__cvo_svc_i__cst_s__6DDF2732] DEFAULT ((0)),
[cst_bts] [tinyint] NULL CONSTRAINT [DF__cvo_svc_i__cst_b__6ED34B6B] DEFAULT ((0)),
[cst_fss] [tinyint] NULL CONSTRAINT [DF__cvo_svc_i__cst_f__6FC76FA4] DEFAULT ((0)),
[cst_opp] [tinyint] NULL CONSTRAINT [DF__cvo_svc_i__cst_o__70BB93DD] DEFAULT ((0)),
[cst_rvs] [tinyint] NULL CONSTRAINT [DF__cvo_svc_i__cst_r__71AFB816] DEFAULT ((0)),
[rvsd] [tinyint] NULL CONSTRAINT [DF__cvo_svc_in__rvsd__72F8E20A] DEFAULT ((0)),
[rvsd_show] [int] NULL CONSTRAINT [DF__cvo_svc_i__rvsd___73ED0643] DEFAULT ((0)),
[rvsd_order] [int] NULL CONSTRAINT [DF__cvo_svc_i__rvsd___74E12A7C] DEFAULT ((0)),
[cst_revosd] [int] NULL CONSTRAINT [DF__cvo_svc_i__cst_r__75D54EB5] DEFAULT ((0)),
[kds] [tinyint] NULL CONSTRAINT [DF__cvo_svc_inv__kds__0E36E82B] DEFAULT ((0)),
[kds_show] [int] NULL CONSTRAINT [DF__cvo_svc_i__kds_s__0F2B0C64] DEFAULT ((1)),
[kds_order] [int] NULL CONSTRAINT [DF__cvo_svc_i__kds_o__101F309D] DEFAULT ((20)),
[cst_kds] [tinyint] NULL CONSTRAINT [DF__cvo_svc_i__cst_k__111354D6] DEFAULT ((0)),
[bch] [tinyint] NULL CONSTRAINT [DF__cvo_svc_inv__bch__3DD0ECB4] DEFAULT ((0)),
[bch_show] [int] NULL CONSTRAINT [DF__cvo_svc_i__bch_s__3EC510ED] DEFAULT ((1)),
[bch_order] [int] NULL CONSTRAINT [DF__cvo_svc_i__bch_o__3FB93526] DEFAULT ((36)),
[cst_bch] [tinyint] NULL CONSTRAINT [DF__cvo_svc_i__cst_b__40AD595F] DEFAULT ((0)),
[bsp] [tinyint] NULL CONSTRAINT [DF__cvo_svc_inv__bsp__54B4520C] DEFAULT ((0)),
[bsp_show] [int] NULL CONSTRAINT [DF__cvo_svc_i__bsp_s__55A87645] DEFAULT ((0)),
[bsp_order] [int] NULL CONSTRAINT [DF__cvo_svc_i__bsp_o__569C9A7E] DEFAULT ((0)),
[bnc] [tinyint] NULL CONSTRAINT [DF__cvo_svc_inv__bnc__5790BEB7] DEFAULT ((0)),
[bnc_show] [int] NULL CONSTRAINT [DF__cvo_svc_i__bnc_s__5884E2F0] DEFAULT ((0)),
[bnc_order] [int] NULL CONSTRAINT [DF__cvo_svc_i__bnc_o__59790729] DEFAULT ((0)),
[bpc] [tinyint] NULL CONSTRAINT [DF__cvo_svc_inv__bpc__5A6D2B62] DEFAULT ((0)),
[bpc_show] [int] NULL CONSTRAINT [DF__cvo_svc_i__bpc_s__5B614F9B] DEFAULT ((0)),
[bpc_order] [int] NULL CONSTRAINT [DF__cvo_svc_i__bpc_o__5C5573D4] DEFAULT ((0)),
[cst_bsp] [tinyint] NULL CONSTRAINT [DF__cvo_svc_i__cst_b__5D49980D] DEFAULT ((0)),
[cst_bnc] [tinyint] NULL CONSTRAINT [DF__cvo_svc_i__cst_b__5E3DBC46] DEFAULT ((0)),
[cst_bpc] [tinyint] NULL CONSTRAINT [DF__cvo_svc_i__cst_b__5F31E07F] DEFAULT ((0)),
[bsn] [tinyint] NULL CONSTRAINT [DF__cvo_svc_inv__bsn__602604B8] DEFAULT ((0)),
[bsn_show] [int] NULL CONSTRAINT [DF__cvo_svc_i__bsn_s__611A28F1] DEFAULT ((0)),
[bsn_order] [int] NULL CONSTRAINT [DF__cvo_svc_i__bsn_o__620E4D2A] DEFAULT ((0)),
[cst_bsn] [tinyint] NULL CONSTRAINT [DF__cvo_svc_i__cst_b__63027163] DEFAULT ((0)),
[percent_off] [tinyint] NULL,
[show_price] [tinyint] NULL CONSTRAINT [DF__cvo_svc_i__show___6F333E1E] DEFAULT ((0)),
[show_off_price] [tinyint] NULL CONSTRAINT [DF__cvo_svc_i__show___70276257] DEFAULT ((0)),
[discount_type] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[evite_program] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[isExternal] [tinyint] NULL CONSTRAINT [DF__cvo_svc_i__isExt__555E5D82] DEFAULT ((0)),
[customer_type] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__cvo_svc_i__custo__592EEE66] DEFAULT ('Customer')
) ON [PRIMARY]
GO
