CREATE TABLE [dbo].[rpt_arpwroffMaster]
(
[trx_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[apply_to_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[settlement_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[gl_trx_id] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[line_desc] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[date_applied] [int] NOT NULL,
[inv_amt_wr_off] [real] NOT NULL,
[trx_type_desc] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[rate] [float] NOT NULL,
[nat_symbol] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[curr_symbol] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[org_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[region_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [rpt_arpwroffMaster_ind_0] ON [dbo].[rpt_arpwroffMaster] ([trx_ctrl_num], [apply_to_num]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_arpwroffMaster] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_arpwroffMaster] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_arpwroffMaster] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_arpwroffMaster] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_arpwroffMaster] TO [public]
GO
