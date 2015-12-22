CREATE TABLE [dbo].[gl_glinphdr]
(
[timestamp] [timestamp] NOT NULL,
[src_trx_id] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[src_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[src_doc_num] [varchar] (36) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[post_flag] [smallint] NOT NULL,
[esl_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[disp_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[arr_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[home_ctry_code] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[rpt_ctry_code] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[date_applied] [int] NOT NULL,
[nat_cur_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[esl_rpt_cur_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[int_rpt_cur_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[trans_code] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[dlvry_code] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[vat_reg_num] [varchar] (17) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[rate_type] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [gl_glinphdr_0] ON [dbo].[gl_glinphdr] ([src_trx_id], [src_ctrl_num]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [gl_glinphdr_1] ON [dbo].[gl_glinphdr] ([src_trx_id], [src_doc_num]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[gl_glinphdr] TO [public]
GO
GRANT SELECT ON  [dbo].[gl_glinphdr] TO [public]
GO
GRANT INSERT ON  [dbo].[gl_glinphdr] TO [public]
GO
GRANT DELETE ON  [dbo].[gl_glinphdr] TO [public]
GO
GRANT UPDATE ON  [dbo].[gl_glinphdr] TO [public]
GO
