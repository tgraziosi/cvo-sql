CREATE TABLE [dbo].[rpt_invcostlyr]
(
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[description] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[in_stock] [decimal] (20, 8) NOT NULL,
[hold_qty] [decimal] (20, 8) NOT NULL,
[inv_cost_method] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[acct_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[sequence] [int] NULL,
[tran_date] [datetime] NULL,
[tran_type] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[tran_no] [int] NULL,
[tran_ext] [int] NULL,
[tran_line] [int] NULL,
[quantity] [decimal] (20, 8) NOT NULL,
[balance] [decimal] (20, 8) NOT NULL,
[m_account_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[m_cost] [decimal] (20, 8) NULL,
[d_account_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[d_cost] [decimal] (20, 8) NULL,
[o_account_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[o_cost] [decimal] (20, 8) NULL,
[u_account_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[u_cost] [decimal] (20, 8) NULL,
[m_tot_cost] [decimal] (20, 8) NULL,
[d_tot_cost] [decimal] (20, 8) NULL,
[o_tot_cost] [decimal] (20, 8) NULL,
[u_tot_cost] [decimal] (20, 8) NULL,
[mtrl_cost] [decimal] (20, 8) NULL,
[dir_cost] [decimal] (20, 8) NULL,
[ovhd_cost] [decimal] (20, 8) NULL,
[util_cost] [decimal] (20, 8) NULL,
[layer_ind] [int] NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_invcostlyr] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_invcostlyr] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_invcostlyr] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_invcostlyr] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_invcostlyr] TO [public]
GO
