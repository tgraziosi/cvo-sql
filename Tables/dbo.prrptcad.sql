CREATE TABLE [dbo].[prrptcad]
(
[contract_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[customer_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[vendor_code] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[source_trx_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[source_doc_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[source_trx_type] [int] NULL,
[source_apply_date] [int] NULL,
[source_qty_shipped] [float] NULL,
[source_unit_price] [float] NULL,
[source_gross_amount] [float] NULL,
[source_discount_amount] [float] NULL,
[amount_adjusted] [float] NULL,
[nat_cur_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[converted_gross_amount] [float] NULL,
[trx_adjusted] [float] NULL,
[amt_accrued] [float] NULL,
[sum_qty_shipped] [int] NULL,
[sum_shipped_net] [float] NULL,
[sum_qty_returned] [int] NULL,
[sum_returned_net] [float] NULL,
[trx_type_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[currency_type] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[prrptcad] TO [public]
GO
GRANT SELECT ON  [dbo].[prrptcad] TO [public]
GO
GRANT INSERT ON  [dbo].[prrptcad] TO [public]
GO
GRANT DELETE ON  [dbo].[prrptcad] TO [public]
GO
GRANT UPDATE ON  [dbo].[prrptcad] TO [public]
GO
