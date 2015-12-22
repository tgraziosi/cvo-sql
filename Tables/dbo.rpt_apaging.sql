CREATE TABLE [dbo].[rpt_apaging]
(
[trx_type] [smallint] NOT NULL,
[trx_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[doc_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[cash_acct_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[apply_to_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[apply_trx_type] [smallint] NOT NULL,
[branch_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[class_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[date_doc] [datetime] NULL,
[date_due] [datetime] NULL,
[date_aging] [datetime] NULL,
[date_applied] [datetime] NULL,
[amount] [float] NOT NULL,
[vendor_code] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[nat_cur_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[rate_type] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[rate_home] [float] NOT NULL,
[rate_oper] [float] NOT NULL,
[vendor_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[contact_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[contact_phone] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[attention_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[attention_phone] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[addr1] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[addr2] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[addr3] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[addr4] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[addr5] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[addr6] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[status_desc] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[groupby0] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[groupby1] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[groupby2] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[groupby3] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[groupby4] [datetime] NULL,
[bracket] [smallint] NOT NULL,
[trx_type_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[status_type] [smallint] NOT NULL,
[symbol] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[curr_precision] [smallint] NOT NULL,
[groupby1_desc] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[sort_date] [int] NOT NULL,
[num_currencies] [smallint] NOT NULL,
[days_aged] [smallint] NULL,
[org_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[region_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_apaging] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_apaging] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_apaging] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_apaging] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_apaging] TO [public]
GO
