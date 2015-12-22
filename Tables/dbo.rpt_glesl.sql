CREATE TABLE [dbo].[rpt_glesl]
(
[home_ctry_code] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[rpt_yy_period] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[rpt_mm_period] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[from_date] [int] NOT NULL,
[to_date] [int] NOT NULL,
[rpt_cur_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[esl_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[amt_esl] [float] NOT NULL,
[num_line_esl] [int] NOT NULL,
[vat_num_prefix] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[vat_reg_num] [varchar] (17) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[vat_branch_id] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[agent_vat_num_prefix] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[agent_vat_reg_num] [varchar] (17) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[agent_vat_branch_id] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[company_name] [varchar] (35) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[line_id] [int] NOT NULL,
[to_ctry] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[cust_vat_reg_num] [varchar] (17) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[amt_rpt] [float] NOT NULL,
[indicator_esl] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_glesl] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_glesl] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_glesl] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_glesl] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_glesl] TO [public]
GO
