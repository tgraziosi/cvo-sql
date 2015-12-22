CREATE TABLE [dbo].[rpt_arinpchgdtl]
(
[trx_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[item_code] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[trx_type] [smallint] NOT NULL,
[line_desc] [varchar] (60) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[location_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[bulk_flag] [smallint] NOT NULL,
[weight] [float] NOT NULL,
[tax_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[gl_rev_acct] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[qty_ordered] [float] NOT NULL,
[qty_shipped] [float] NOT NULL,
[unit_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[unit_price] [float] NOT NULL,
[discount_amt] [float] NOT NULL,
[disc_prc_flag] [smallint] NOT NULL,
[date_entered] [int] NOT NULL,
[serial_id] [int] NOT NULL,
[oe_orig_flag] [smallint] NOT NULL,
[iv_post_flag] [smallint] NOT NULL,
[extended_price] [float] NOT NULL,
[discount_prc] [float] NOT NULL,
[reference_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[cust_po] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[symbol] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[sequence_id] [int] NOT NULL,
[org_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_arinpchgdtl] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_arinpchgdtl] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_arinpchgdtl] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_arinpchgdtl] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_arinpchgdtl] TO [public]
GO
