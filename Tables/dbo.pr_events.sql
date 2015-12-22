CREATE TABLE [dbo].[pr_events]
(
[contract_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[sequence_id] [int] NOT NULL,
[process_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[post_date] [int] NOT NULL,
[customer_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[price_class] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[na_parent_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[vendor_code] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[vendor_class] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[part_category] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[source_trx_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[source_sequence_id] [int] NOT NULL,
[source_doc_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[source_trx_type] [int] NOT NULL,
[source_apply_date] [int] NOT NULL,
[source_qty_shipped] [float] NOT NULL,
[source_unit_price] [float] NOT NULL,
[source_amt_cost] [float] NOT NULL,
[source_gross_amount] [float] NOT NULL,
[source_discount_amount] [float] NOT NULL,
[amount_adjusted] [float] NOT NULL,
[void_flag] [int] NOT NULL,
[nat_cur_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[rate_type_home] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[rate_type_oper] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[rate_home] [float] NOT NULL,
[rate_oper] [float] NOT NULL,
[home_amount] [float] NOT NULL,
[oper_amount] [float] NOT NULL,
[home_adjusted] [float] NOT NULL,
[oper_adjusted] [float] NOT NULL,
[home_amt_cost] [float] NOT NULL,
[oper_amt_cost] [float] NOT NULL,
[userid] [int] NOT NULL,
[home_rebate_amount] [float] NULL,
[oper_rebate_amount] [float] NULL,
[kit_multiplier] [float] NOT NULL,
[kit_part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[all_parts_flag] [int] NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[pr_events] TO [public]
GO
GRANT SELECT ON  [dbo].[pr_events] TO [public]
GO
GRANT INSERT ON  [dbo].[pr_events] TO [public]
GO
GRANT DELETE ON  [dbo].[pr_events] TO [public]
GO
GRANT UPDATE ON  [dbo].[pr_events] TO [public]
GO
