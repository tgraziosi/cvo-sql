CREATE TABLE [dbo].[gl_glintdet]
(
[timestamp] [timestamp] NOT NULL,
[int_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[line_id] [int] NOT NULL,
[err_code] [int] NOT NULL,
[num_of_trx] [int] NOT NULL,
[from_ctry_code_int] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[to_ctry_code_int] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[orig_ctry_code_int] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ref_ctrl_num] [varchar] (14) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[amt_rpt] [float] NOT NULL,
[f_notr_code] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[s_notr_code] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[trans_code_int] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[dlvry_code_int] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[cmdty_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[weight_flag] [smallint] NOT NULL,
[weight_value] [float] NOT NULL,
[supp_unit_flag] [smallint] NOT NULL,
[supp_unit_value] [float] NOT NULL,
[vat_reg_num] [varchar] (17) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[stat_manner] [varchar] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[regime] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[harbour] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[bundesland] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[department] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[stat_amt_rpt] [float] NOT NULL,
[cmdty_desc_1] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[cmdty_desc_2] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[cmdty_desc_3] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[cmdty_desc_4] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[cmdty_desc_5] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [gl_glintdet_0] ON [dbo].[gl_glintdet] ([int_ctrl_num], [line_id]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[gl_glintdet] TO [public]
GO
GRANT SELECT ON  [dbo].[gl_glintdet] TO [public]
GO
GRANT INSERT ON  [dbo].[gl_glintdet] TO [public]
GO
GRANT DELETE ON  [dbo].[gl_glintdet] TO [public]
GO
GRANT UPDATE ON  [dbo].[gl_glintdet] TO [public]
GO
