CREATE TABLE [dbo].[gl_glinthdr]
(
[timestamp] [timestamp] NOT NULL,
[rpt_ctry_code] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[int_period_id] [int] NOT NULL,
[rpt_yy_period] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[rpt_mm_period] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[from_date] [int] NOT NULL,
[to_date] [int] NOT NULL,
[post_flag] [smallint] NOT NULL,
[dist_sell_flag] [smallint] NOT NULL,
[rpt_cur_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[int_ctrl_root] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[disp_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[amt_disp] [float] NOT NULL,
[num_disp_line] [int] NOT NULL,
[disp_err_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[amt_err_disp] [float] NOT NULL,
[num_disp_err_line] [int] NOT NULL,
[arr_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[amt_arr] [float] NOT NULL,
[num_arr_line] [int] NOT NULL,
[arr_err_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[amt_err_arr] [float] NOT NULL,
[num_arr_err_line] [int] NOT NULL,
[vat_num_prefix] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[vat_reg_num] [varchar] (17) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[vat_branch_id] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[agent_flag] [smallint] NOT NULL,
[agent_vat_num_prefix] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[agent_vat_reg_num] [varchar] (17) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[agent_vat_branch_id] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[company_name] [varchar] (35) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
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
[flag_cur_ident] [smallint] NOT NULL,
[flag_cmdty_desc] [smallint] NOT NULL,
[flag_ctry_orig] [smallint] NOT NULL,
[rpt_cur_ident] [int] NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [gl_glinthdr_0] ON [dbo].[gl_glinthdr] ([rpt_ctry_code], [int_period_id]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[gl_glinthdr] TO [public]
GO
GRANT SELECT ON  [dbo].[gl_glinthdr] TO [public]
GO
GRANT INSERT ON  [dbo].[gl_glinthdr] TO [public]
GO
GRANT DELETE ON  [dbo].[gl_glinthdr] TO [public]
GO
GRANT UPDATE ON  [dbo].[gl_glinthdr] TO [public]
GO
