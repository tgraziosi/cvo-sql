CREATE TABLE [dbo].[rpt_amvch]
(
[asset_imm_exp_amount] [float] NULL,
[trx_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[doc_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[vendor_code] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[apply_date_hdr] [datetime] NULL,
[nat_currency_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[nat_currency_mask] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[amt_net] [float] NULL,
[sequence_id] [int] NULL,
[line_id] [int] NULL,
[asset_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[line_description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[fixed_asset_acct] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[fixed_asset_ref_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[imm_exp_acct] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[imm_exp_ref_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[quantity] [int] NULL,
[update_asset_quantity] [tinyint] NULL,
[asset_amount] [float] NULL,
[imm_exp_amount] [float] NULL,
[activity_type] [tinyint] NULL,
[apply_date_det] [datetime] NULL,
[create_item] [tinyint] NULL,
[symbol] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[curr_precision] [smallint] NULL,
[org_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[region_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_amvch] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_amvch] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_amvch] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_amvch] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_amvch] TO [public]
GO
