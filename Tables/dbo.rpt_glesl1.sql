CREATE TABLE [dbo].[rpt_glesl1]
(
[esl_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[src_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[src_doc_num] [varchar] (36) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[nat_cur_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[date_applied] [int] NOT NULL,
[src_trx_id] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[esl_line_id] [int] NOT NULL,
[src_line_id] [int] NOT NULL,
[item_code] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[line_desc] [varchar] (60) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[to_ctry_code] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[amt_nat] [float] NOT NULL,
[esl_amt_rpt] [float] NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_glesl1] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_glesl1] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_glesl1] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_glesl1] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_glesl1] TO [public]
GO
