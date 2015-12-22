CREATE TABLE [dbo].[rpt_glintsrc]
(
[int_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[int_line_id] [int] NOT NULL,
[src_line_id] [int] NOT NULL,
[src_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[src_doc_num] [varchar] (36) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[src_trx_desc] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[item_code] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[line_desc] [varchar] (60) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[date_applied] [int] NOT NULL,
[src_from_ctry] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[src_to_ctry] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[src_orig_ctry] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[nat_cur_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[amt_nat] [float] NOT NULL,
[src_amt_rpt] [float] NOT NULL,
[src_stat_amt_nat] [float] NOT NULL,
[src_stat_amt_rpt] [float] NOT NULL,
[src_qty_item] [float] NOT NULL,
[src_weight] [float] NOT NULL,
[src_supp_unit] [float] NOT NULL,
[err_code] [int] NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_glintsrc] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_glintsrc] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_glintsrc] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_glintsrc] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_glintsrc] TO [public]
GO
