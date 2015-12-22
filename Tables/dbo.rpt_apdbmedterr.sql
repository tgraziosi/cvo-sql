CREATE TABLE [dbo].[rpt_apdbmedterr]
(
[seq_by] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[trx_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[vendor_code] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[entry_date] [int] NOT NULL,
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
[entry_short] [float] NOT NULL,
[amt_payment] [float] NOT NULL,
[user_trx_type_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[batch_code] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[po_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[branch_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[vendor_name] [varchar] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[org_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_apdbmedterr] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_apdbmedterr] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_apdbmedterr] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_apdbmedterr] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_apdbmedterr] TO [public]
GO
