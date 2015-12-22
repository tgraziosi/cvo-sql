CREATE TABLE [dbo].[rpt_epmchdtl]
(
[match_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[match_sequence_id] [int] NOT NULL,
[po_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[po_sequence_id] [int] NOT NULL,
[receipt_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[receipt_sequence_id] [int] NOT NULL,
[item_code] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[item_desc] [varchar] (60) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[account_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[account_mask] [varchar] (35) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[reference_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[company_id] [int] NOT NULL,
[company_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[qty_received] [float] NOT NULL,
[qty_invoiced] [float] NOT NULL,
[unit_price] [float] NOT NULL,
[invoice_unit_price] [float] NOT NULL,
[tolerance_hold_flag] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_epmchdtl] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_epmchdtl] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_epmchdtl] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_epmchdtl] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_epmchdtl] TO [public]
GO
