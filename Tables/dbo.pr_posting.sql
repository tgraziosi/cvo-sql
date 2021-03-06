CREATE TABLE [dbo].[pr_posting]
(
[id] [varchar] (36) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[section] [int] NOT NULL,
[contract_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[sequence_id] [int] NULL,
[process_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[post_date] [int] NULL,
[customer_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[price_class] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[na_parent_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[vendor_code] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[vendor_class] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[category] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[source_trx_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[source_sequence_id] [int] NULL,
[source_doc_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[source_trx_type] [int] NULL,
[source_apply_date] [int] NULL,
[source_qty_shipped] [float] NULL,
[source_unit_price] [float] NULL,
[source_gross_amount] [float] NULL,
[source_discount_amount] [float] NULL,
[amount_adjusted] [float] NULL,
[void] [int] NULL,
[nat_cur_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[rate_type_home] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[rate_type_oper] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[rate_home] [float] NULL,
[rate_oper] [float] NULL,
[home_amount] [float] NULL,
[oper_amount] [float] NULL,
[home_adjusted] [float] NULL,
[oper_adjusted] [float] NULL,
[userid] [int] NULL,
[customer_class] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[amount_rebate] [float] NULL,
[amount_accrued_oper] [float] NULL,
[amount_accrued_home] [float] NULL,
[flag] [int] NULL,
[part_category] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[exclude_promotions] [int] NULL,
[exclude_rebates] [int] NULL,
[exclude_2031] [int] NULL,
[exclude_2032] [int] NULL,
[exclude_4091] [int] NULL,
[exclude_4092] [int] NULL,
[table_name] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[trial_flag] [int] NULL,
[debug_flag] [int] NULL,
[accumulator] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[range] [varchar] (3000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[type] [int] NULL,
[rfrom] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[rto] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[contract_description] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[customer_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[customer_class_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[vendor_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[vendor_class_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[part_description] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[part_category_description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[natural_currency_mask] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[natural_currency_precision] [int] NULL,
[home_currency_mask] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[home_currency_precision] [int] NULL,
[oper_currency_mask] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[oper_currency_precision] [int] NULL,
[home_symbol] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[oper_symbol] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[symbol] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[home_rebate_amount] [float] NULL,
[oper_rebate_amount] [float] NULL,
[kit_multiplier] [float] NULL,
[kit_part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[home_amt_cost] [float] NULL,
[oper_amt_cost] [float] NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[pr_posting] TO [public]
GO
GRANT SELECT ON  [dbo].[pr_posting] TO [public]
GO
GRANT INSERT ON  [dbo].[pr_posting] TO [public]
GO
GRANT DELETE ON  [dbo].[pr_posting] TO [public]
GO
GRANT UPDATE ON  [dbo].[pr_posting] TO [public]
GO
