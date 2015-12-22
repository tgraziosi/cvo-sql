CREATE TABLE [dbo].[rpt_arucrmemdet]
(
[trx_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[item_code] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[bulk_flag] [smallint] NOT NULL,
[location_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[line_desc] [varchar] (60) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[tax_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[gl_rev_acct] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[rma_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[return_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[weight] [float] NOT NULL,
[qty_returned] [float] NOT NULL,
[qty_prev_returned] [float] NOT NULL,
[unit_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[unit_price] [float] NOT NULL,
[extended_price] [float] NOT NULL,
[discount_prc] [float] NOT NULL,
[disc_prc_flag] [smallint] NOT NULL,
[date_entered] [int] NOT NULL,
[serial_id] [int] NOT NULL,
[oe_orig_flag] [smallint] NOT NULL,
[iv_post_flag] [smallint] NOT NULL,
[reference_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[trx_type] [smallint] NOT NULL,
[qty_shipped] [float] NOT NULL,
[discount_amt] [float] NOT NULL,
[symbol] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[org_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_arucrmemdet] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_arucrmemdet] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_arucrmemdet] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_arucrmemdet] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_arucrmemdet] TO [public]
GO
