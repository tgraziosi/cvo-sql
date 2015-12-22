CREATE TABLE [dbo].[rpt_aruflchg]
(
[trx_type] [smallint] NOT NULL,
[chrg_type] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[customer_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[customer_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[fin_chg_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[price_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[currency_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[user_id] [smallint] NOT NULL,
[apply_to_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[apply_trx_type] [smallint] NOT NULL,
[sub_apply_to_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[sub_apply_to_type] [smallint] NOT NULL,
[date_aging] [int] NOT NULL,
[date_due] [int] NOT NULL,
[amount] [float] NOT NULL,
[rate] [float] NOT NULL,
[overdue_amt] [float] NOT NULL,
[chrg_days] [int] NOT NULL,
[currency_mask] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[amount_home] [float] NOT NULL,
[symbol] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[org_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_aruflchg] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_aruflchg] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_aruflchg] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_aruflchg] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_aruflchg] TO [public]
GO
