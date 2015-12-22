CREATE TABLE [dbo].[artemcus]
(
[timestamp] [timestamp] NULL,
[template_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[template_desc] [varchar] (60) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[status_type] [smallint] NULL,
[tax_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[terms_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[fob_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[freight_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[posting_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[dest_zone_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[territory_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[salesperson_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[fin_chg_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[price_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[payment_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[vendor_code] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[print_stmt_flag] [smallint] NULL,
[stmt_cycle_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[inv_comment_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[stmt_comment_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[dunn_message_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[trade_disc_percent] [float] NULL,
[invoice_copies] [smallint] NULL,
[check_credit_limit] [smallint] NULL,
[credit_limit] [float] NULL,
[check_aging_limit] [smallint] NULL,
[aging_limit_bracket] [smallint] NULL,
[bal_fwd_flag] [smallint] NULL,
[late_chg_type] [smallint] NULL,
[rate_type_home] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[rate_type_oper] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[limit_by_home] [smallint] NULL,
[nat_cur_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[one_cur_cust] [smallint] NULL,
[remit_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[forwarder_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[freight_to_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[price_level] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ship_via_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[writeoff_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[country_code] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[location_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[alt_location_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ship_complete_flag] [smallint] NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [artemcus_ind_0] ON [dbo].[artemcus] ([template_code]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[artemcus] TO [public]
GO
GRANT SELECT ON  [dbo].[artemcus] TO [public]
GO
GRANT INSERT ON  [dbo].[artemcus] TO [public]
GO
GRANT DELETE ON  [dbo].[artemcus] TO [public]
GO
GRANT UPDATE ON  [dbo].[artemcus] TO [public]
GO
