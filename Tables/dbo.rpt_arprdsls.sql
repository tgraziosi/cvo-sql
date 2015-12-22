CREATE TABLE [dbo].[rpt_arprdsls]
(
[customer_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[customer_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[location_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[item_code] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[unit_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[line_desc] [varchar] (60) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[doc_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[date_doc] [int] NOT NULL,
[date_shipped] [int] NOT NULL,
[date_required] [int] NOT NULL,
[trx_type] [smallint] NOT NULL,
[salesperson_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[price_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[territory_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[rate_home] [float] NOT NULL,
[rate_oper] [float] NOT NULL,
[qty_shipped] [float] NOT NULL,
[nat_cur_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[qty_returned] [float] NOT NULL,
[unit_price] [float] NOT NULL,
[discount_prc] [float] NOT NULL,
[discount_amt] [float] NOT NULL,
[extended_price] [float] NOT NULL,
[trx_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[symbol] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_arprdsls] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_arprdsls] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_arprdsls] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_arprdsls] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_arprdsls] TO [public]
GO
