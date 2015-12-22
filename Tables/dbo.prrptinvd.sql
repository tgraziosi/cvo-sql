CREATE TABLE [dbo].[prrptinvd]
(
[trx_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[trx_type] [smallint] NULL,
[sequence_id] [int] NULL,
[symbol] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[curr_precision] [smallint] NULL,
[location_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[item_code] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[line_desc] [varchar] (60) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[qty_ordered] [float] NULL,
[qty_back_ordered] [float] NULL,
[qty_shipped] [float] NULL,
[unit_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[unit_price] [float] NULL,
[unit_cost] [float] NULL,
[weight] [float] NULL,
[serial_id] [int] NULL,
[tax_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[gl_rev_acct] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[disc_prc_flag] [smallint] NULL,
[discount_amt] [float] NULL,
[discount_prc] [float] NULL,
[extended_price] [float] NULL,
[calc_tax] [float] NULL,
[reference_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[prrptinvd] TO [public]
GO
GRANT SELECT ON  [dbo].[prrptinvd] TO [public]
GO
GRANT INSERT ON  [dbo].[prrptinvd] TO [public]
GO
GRANT DELETE ON  [dbo].[prrptinvd] TO [public]
GO
GRANT UPDATE ON  [dbo].[prrptinvd] TO [public]
GO
