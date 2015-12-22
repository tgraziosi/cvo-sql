CREATE TABLE [dbo].[arinpcdt]
(
[timestamp] [timestamp] NOT NULL,
[trx_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[doc_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[sequence_id] [int] NOT NULL,
[trx_type] [smallint] NOT NULL,
[location_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[item_code] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[bulk_flag] [smallint] NOT NULL,
[date_entered] [int] NOT NULL,
[line_desc] [varchar] (60) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[qty_ordered] [float] NOT NULL,
[qty_shipped] [float] NOT NULL,
[unit_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[unit_price] [float] NOT NULL,
[unit_cost] [float] NOT NULL,
[weight] [float] NOT NULL,
[serial_id] [int] NOT NULL,
[tax_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[gl_rev_acct] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[disc_prc_flag] [smallint] NOT NULL,
[discount_amt] [float] NOT NULL,
[commission_flag] [smallint] NOT NULL,
[rma_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[return_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[qty_returned] [float] NOT NULL,
[qty_prev_returned] [float] NOT NULL,
[new_gl_rev_acct] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[iv_post_flag] [smallint] NOT NULL,
[oe_orig_flag] [smallint] NOT NULL,
[discount_prc] [float] NOT NULL,
[extended_price] [float] NOT NULL,
[calc_tax] [float] NOT NULL,
[reference_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[new_reference_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[cust_po] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[org_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [arinpcdt_ind_2] ON [dbo].[arinpcdt] ([doc_ctrl_num]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [arinpcdt_ind_0] ON [dbo].[arinpcdt] ([trx_ctrl_num], [trx_type], [sequence_id]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[arinpcdt] TO [public]
GO
GRANT SELECT ON  [dbo].[arinpcdt] TO [public]
GO
GRANT INSERT ON  [dbo].[arinpcdt] TO [public]
GO
GRANT DELETE ON  [dbo].[arinpcdt] TO [public]
GO
GRANT UPDATE ON  [dbo].[arinpcdt] TO [public]
GO
