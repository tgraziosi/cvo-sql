CREATE TABLE [dbo].[gl_glinpdet]
(
[timestamp] [timestamp] NOT NULL,
[src_trx_id] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[src_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[src_line_id] [int] NOT NULL,
[esl_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[esl_line_id] [int] NOT NULL,
[disp_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[disp_line_id] [int] NOT NULL,
[arr_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[arr_line_id] [int] NOT NULL,
[esl_err_code] [int] NOT NULL,
[int_err_code] [int] NOT NULL,
[from_ctry_code] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[to_ctry_code] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[orig_ctry_code] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[item_code] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[line_desc] [varchar] (60) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[qty_item] [float] NOT NULL,
[amt_nat] [float] NOT NULL,
[esl_amt_rpt] [float] NOT NULL,
[int_amt_rpt] [float] NOT NULL,
[indicator_esl] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[disp_flow_flag] [smallint] NOT NULL,
[disp_f_notr_code] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[disp_s_notr_code] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[arr_flow_flag] [smallint] NOT NULL,
[arr_f_notr_code] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[arr_s_notr_code] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[cmdty_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[weight_value] [float] NOT NULL,
[supp_unit_value] [float] NOT NULL,
[disp_stat_amt_nat] [float] NOT NULL,
[arr_stat_amt_nat] [float] NOT NULL,
[disp_stat_amt_rpt] [float] NOT NULL,
[arr_stat_amt_rpt] [float] NOT NULL,
[stat_manner] [varchar] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[regime] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[harbour] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[bundesland] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[department] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [gl_glinpdet_0] ON [dbo].[gl_glinpdet] ([src_trx_id], [src_ctrl_num], [src_line_id]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[gl_glinpdet] TO [public]
GO
GRANT SELECT ON  [dbo].[gl_glinpdet] TO [public]
GO
GRANT INSERT ON  [dbo].[gl_glinpdet] TO [public]
GO
GRANT DELETE ON  [dbo].[gl_glinpdet] TO [public]
GO
GRANT UPDATE ON  [dbo].[gl_glinpdet] TO [public]
GO
