CREATE TABLE [dbo].[cc_report_configs]
(
[config_name] [varchar] (65) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[aging_type] [smallint] NOT NULL CONSTRAINT [DF__cc_report__aging__5459F2E9] DEFAULT ((0)),
[sequence] [smallint] NOT NULL CONSTRAINT [DF__cc_report__seque__554E1722] DEFAULT ((0)),
[cbAllApplyTo] [smallint] NOT NULL CONSTRAINT [DF__cc_report__cbAll__56423B5B] DEFAULT ((1)),
[txtFromApplyTo] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__cc_report__txtFr__57365F94] DEFAULT (''),
[txtToApplyTo] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__cc_report__txtTo__582A83CD] DEFAULT (''),
[cbAllCust] [smallint] NOT NULL CONSTRAINT [DF__cc_report__cbAll__591EA806] DEFAULT ((1)),
[txtFromCust] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__cc_report__txtFr__5A12CC3F] DEFAULT (''),
[txtToCust] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__cc_report__txtTo__5B06F078] DEFAULT (''),
[cbAllName] [smallint] NOT NULL CONSTRAINT [DF__cc_report__cbAll__5BFB14B1] DEFAULT ((1)),
[txtFromName] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__cc_report__txtFr__5CEF38EA] DEFAULT (''),
[txtToName] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__cc_report__txtTo__5DE35D23] DEFAULT (''),
[cbAllAcctCode] [smallint] NOT NULL CONSTRAINT [DF__cc_report__cbAll__5ED7815C] DEFAULT ((1)),
[txtFromAcctCode] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__cc_report__txtFr__5FCBA595] DEFAULT (''),
[txtToAcctCode] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__cc_report__txtTo__60BFC9CE] DEFAULT (''),
[cbAllNatAcct] [smallint] NOT NULL CONSTRAINT [DF__cc_report__cbAll__61B3EE07] DEFAULT ((1)),
[txtFromNatAcct] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__cc_report__txtFr__62A81240] DEFAULT (''),
[txtToNatAcct] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__cc_report__txtTo__639C3679] DEFAULT (''),
[cbAllPriceCode] [smallint] NOT NULL CONSTRAINT [DF__cc_report__cbAll__64905AB2] DEFAULT ((1)),
[txtFromPrice] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__cc_report__txtFr__65847EEB] DEFAULT (''),
[txtToPrice] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__cc_report__txtTo__6678A324] DEFAULT (''),
[cbAllPostingCode] [smallint] NOT NULL CONSTRAINT [DF__cc_report__cbAll__676CC75D] DEFAULT ((1)),
[txtFromPostingCode] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__cc_report__txtFr__6860EB96] DEFAULT (''),
[txtToPostingCode] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__cc_report__txtTo__69550FCF] DEFAULT (''),
[cbAllSalesCode] [smallint] NOT NULL CONSTRAINT [DF__cc_report__cbAll__6A493408] DEFAULT ((1)),
[txtFromSales] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__cc_report__txtFr__6B3D5841] DEFAULT (''),
[txtToSales] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__cc_report__txtTo__6C317C7A] DEFAULT (''),
[cbAllTerr] [smallint] NOT NULL CONSTRAINT [DF__cc_report__cbAll__6D25A0B3] DEFAULT ((1)),
[txtFromTerr] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__cc_report__txtFr__6E19C4EC] DEFAULT (''),
[txtToTerr] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__cc_report__txtTo__6F0DE925] DEFAULT (''),
[cbAllWorkload] [smallint] NOT NULL CONSTRAINT [DF__cc_report__cbAll__70020D5E] DEFAULT ((1)),
[txtFromWorkload] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__cc_report__txtFr__70F63197] DEFAULT (''),
[txtToWorkload] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__cc_report__txtTo__71EA55D0] DEFAULT (''),
[dtAsOfDate] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__cc_report__dtAsO__72DE7A09] DEFAULT (''),
[title] [varchar] (60) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__cc_report__title__73D29E42] DEFAULT (''),
[order_by_currency] [smallint] NOT NULL CONSTRAINT [DF__cc_report__order__74C6C27B] DEFAULT ((0)),
[incl_future_trx] [smallint] NOT NULL CONSTRAINT [DF__cc_report__incl___75BAE6B4] DEFAULT ((0)),
[incl_trx_pif] [smallint] NOT NULL CONSTRAINT [DF__cc_report__incl___76AF0AED] DEFAULT ((0)),
[age_on_date] [smallint] NOT NULL CONSTRAINT [DF__cc_report__age_o__77A32F26] DEFAULT ((0)),
[prt_over_days] [smallint] NOT NULL CONSTRAINT [DF__cc_report__prt_o__7897535F] DEFAULT ((0)),
[over_days] [int] NOT NULL CONSTRAINT [DF__cc_report__over___798B7798] DEFAULT ((0)),
[prt_over_amt] [smallint] NOT NULL CONSTRAINT [DF__cc_report__prt_o__7A7F9BD1] DEFAULT ((0)),
[over_amt] [float] NOT NULL CONSTRAINT [DF__cc_report__over___7B73C00A] DEFAULT ((0)),
[prt_ovr_cd_lim] [smallint] NOT NULL CONSTRAINT [DF__cc_report__prt_o__7C67E443] DEFAULT ((0)),
[prt_ovr_ag_lim] [smallint] NOT NULL CONSTRAINT [DF__cc_report__prt_o__7D5C087C] DEFAULT ((0)),
[cond_req] [smallint] NOT NULL CONSTRAINT [DF__cc_report__cond___7E502CB5] DEFAULT ((0)),
[print_name] [smallint] NOT NULL CONSTRAINT [DF__cc_report__print__7F4450EE] DEFAULT ((1)),
[print_contact] [smallint] NOT NULL CONSTRAINT [DF__cc_report__print__00387527] DEFAULT ((1)),
[print_attention] [smallint] NOT NULL CONSTRAINT [DF__cc_report__print__012C9960] DEFAULT ((1)),
[print_address] [smallint] NOT NULL CONSTRAINT [DF__cc_report__print__0220BD99] DEFAULT ((1)),
[print_status] [smallint] NOT NULL CONSTRAINT [DF__cc_report__print__0314E1D2] DEFAULT ((1)),
[reference_num] [smallint] NOT NULL CONSTRAINT [DF__cc_report__refer__0409060B] DEFAULT ((0)),
[home_totals] [smallint] NOT NULL CONSTRAINT [DF__cc_report__home___04FD2A44] DEFAULT ((1)),
[apply_date_rate] [smallint] NOT NULL CONSTRAINT [DF__cc_report__apply__05F14E7D] DEFAULT ((0)),
[override_rate_type] [varchar] (9) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__cc_report__overr__06E572B6] DEFAULT (''),
[relation_code] [varchar] (17) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__cc_report__relat__07D996EF] DEFAULT ('STANDARD'),
[print_to] [smallint] NOT NULL CONSTRAINT [DF__cc_report__print__08CDBB28] DEFAULT ((0)),
[balance_type] [smallint] NOT NULL CONSTRAINT [DF__cc_report__balan__09C1DF61] DEFAULT ((0)),
[days_type] [smallint] NOT NULL CONSTRAINT [DF__cc_report__days___0AB6039A] DEFAULT ((0)),
[style] [smallint] NOT NULL CONSTRAINT [DF__cc_report__style__0BAA27D3] DEFAULT ((0)),
[territory_basis] [smallint] NOT NULL CONSTRAINT [DF__cc_report__terri__0C9E4C0C] DEFAULT ((0)),
[brackets] [smallint] NOT NULL CONSTRAINT [DF__cc_report__brack__0D927045] DEFAULT ((0)),
[exclude_on_acct] [smallint] NOT NULL CONSTRAINT [DF__cc_report__exclu__0E86947E] DEFAULT ((0)),
[include_comments] [smallint] NOT NULL CONSTRAINT [DF__cc_report__inclu__0F7AB8B7] DEFAULT ((0)),
[all_org_flag] [smallint] NOT NULL CONSTRAINT [DF__cc_report__all_o__106EDCF0] DEFAULT ((1)),
[from_org] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__cc_report__from___11630129] DEFAULT (''),
[to_org] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__cc_report__to_or__12572562] DEFAULT ('')
) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [cc_report_configs_idx] ON [dbo].[cc_report_configs] ([config_name], [aging_type]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[cc_report_configs] TO [public]
GO
GRANT SELECT ON  [dbo].[cc_report_configs] TO [public]
GO
GRANT INSERT ON  [dbo].[cc_report_configs] TO [public]
GO
GRANT DELETE ON  [dbo].[cc_report_configs] TO [public]
GO
GRANT UPDATE ON  [dbo].[cc_report_configs] TO [public]
GO
