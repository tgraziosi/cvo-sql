CREATE TABLE [dbo].[rpt_invrecon]
(
[account_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[description] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[apply_date] [datetime] NULL,
[reference_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[nat_cur_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[tran_id] [int] NULL,
[g_journal_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[g_sequence_id] [int] NULL,
[g_date_entered] [datetime] NULL,
[g_date_posted] [datetime] NULL,
[g_balance] [decimal] (20, 8) NULL,
[g_nat_balance] [decimal] (20, 8) NULL,
[g_balance_oper] [decimal] (20, 8) NULL,
[g_journal_description] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[g_row_id] [int] NULL,
[d_tran_date] [datetime] NULL,
[d_line_descr] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[d_date_posted] [datetime] NULL,
[d_balance] [decimal] (20, 8) NULL,
[d_nat_balance] [decimal] (20, 8) NULL,
[d_balance_oper] [decimal] (20, 8) NULL,
[d_row_id] [int] NULL,
[t_curr_date] [datetime] NULL,
[t_cost] [decimal] (20, 8) NULL,
[t_cost_type] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[t_inv_qty] [decimal] (20, 8) NULL,
[t_balance] [decimal] (20, 8) NULL,
[t_row_id] [int] NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_invrecon] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_invrecon] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_invrecon] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_invrecon] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_invrecon] TO [public]
GO
