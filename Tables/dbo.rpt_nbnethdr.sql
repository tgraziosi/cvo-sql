CREATE TABLE [dbo].[rpt_nbnethdr]
(
[net_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[vendor_code] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[customer_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[currency_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[payment_flag] [smallint] NOT NULL,
[amt_payment] [float] NOT NULL,
[date_entered] [int] NOT NULL,
[user_name] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[module_id] [int] NOT NULL,
[currency_symbol] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_nbnethdr] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_nbnethdr] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_nbnethdr] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_nbnethdr] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_nbnethdr] TO [public]
GO
