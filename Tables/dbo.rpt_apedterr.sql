CREATE TABLE [dbo].[rpt_apedterr]
(
[seq_by] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[trx_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[err_code] [int] NOT NULL,
[refer_to] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[field_desc] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[err_type] [smallint] NOT NULL,
[err_desc] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[entry_type] [int] NOT NULL,
[entry_str] [varchar] (35) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[entry_amt] [float] NOT NULL,
[entry_qty] [float] NOT NULL,
[entry_long] [float] NOT NULL,
[entry_date] [int] NOT NULL,
[entry_short] [float] NOT NULL,
[vendor_code] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[amt_payment] [float] NOT NULL,
[vendor_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[addr_sort1] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[addr_sort2] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[addr_sort3] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[vend_class_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[settlement_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[org_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[date_applied] [int] NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_apedterr] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_apedterr] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_apedterr] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_apedterr] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_apedterr] TO [public]
GO
