CREATE TABLE [dbo].[rpt_apuvcadjd]
(
[trx_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[trx_type] [smallint] NOT NULL,
[sequence_id] [int] NOT NULL,
[location_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[item_code] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[bulk_flag] [smallint] NOT NULL,
[qty_ordered] [float] NOT NULL,
[qty_received] [float] NOT NULL,
[qty_returned] [float] NOT NULL,
[qty_prev_returned] [float] NOT NULL,
[approval_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[tax_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[return_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[code_1099] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[po_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[unit_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[unit_price] [float] NOT NULL,
[amt_discount] [float] NOT NULL,
[amt_freight] [float] NOT NULL,
[amt_tax] [float] NOT NULL,
[amt_misc] [float] NOT NULL,
[amt_extended] [float] NOT NULL,
[calc_tax] [float] NOT NULL,
[date_entered] [int] NOT NULL,
[gl_exp_acct] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[new_gl_exp_acct] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[rma_num] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[line_desc] [varchar] (60) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[serial_id] [int] NOT NULL,
[company_id] [smallint] NOT NULL,
[iv_post_flag] [smallint] NOT NULL,
[po_orig_flag] [smallint] NOT NULL,
[rec_company_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[new_rec_company_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[symbol] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[reference_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[new_reference_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[org_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_apuvcadjd] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_apuvcadjd] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_apuvcadjd] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_apuvcadjd] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_apuvcadjd] TO [public]
GO
