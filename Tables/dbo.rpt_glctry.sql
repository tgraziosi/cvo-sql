CREATE TABLE [dbo].[rpt_glctry]
(
[country_code] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[country_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ctry_code_vat] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[vat_reg_mask] [varchar] (17) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[currency_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[rate_type_esl] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[rate_type_int] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[round_esl] [smallint] NOT NULL,
[round_int] [smallint] NOT NULL,
[flag_notr_two_digit] [smallint] NOT NULL,
[flag_vat_reg_num] [smallint] NOT NULL,
[flag_stat_manner] [smallint] NOT NULL,
[flag_regime] [smallint] NOT NULL,
[flag_harbour] [smallint] NOT NULL,
[flag_bundesland] [smallint] NOT NULL,
[flag_department] [smallint] NOT NULL,
[flag_amt] [smallint] NOT NULL,
[flag_trans] [smallint] NOT NULL,
[flag_dlvry] [smallint] NOT NULL,
[flag_stat_amt] [smallint] NOT NULL,
[flag_border_stat] [smallint] NOT NULL,
[flag_cur_ident] [smallint] NOT NULL,
[flag_cmdty_desc] [smallint] NOT NULL,
[flag_ctry_orig] [smallint] NOT NULL,
[def_cmdty_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[def_cmdty_desc] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_glctry] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_glctry] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_glctry] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_glctry] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_glctry] TO [public]
GO
