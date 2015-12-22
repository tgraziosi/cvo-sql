CREATE TABLE [dbo].[rpt_arpatf_aging]
(
[trx_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[doc_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[date_aging] [int] NOT NULL,
[date_due] [int] NOT NULL,
[amount] [float] NOT NULL,
[customer_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[salesperson_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[territory_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[price_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[symbol] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_arpatf_aging] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_arpatf_aging] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_arpatf_aging] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_arpatf_aging] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_arpatf_aging] TO [public]
GO
