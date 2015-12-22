CREATE TABLE [dbo].[rpt_arwoedterr]
(
[seq_by] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[trx_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[err_code] [int] NOT NULL,
[sequence_id] [int] NOT NULL,
[refer_to] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[field_desc] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[entry_type] [smallint] NOT NULL,
[entry_str] [char] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[entry_amt] [float] NOT NULL,
[entry_qty] [float] NOT NULL,
[entry_long] [int] NOT NULL,
[entry_date] [int] NOT NULL,
[entry_short] [int] NOT NULL,
[e_level] [int] NOT NULL,
[err_desc] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[customer_code] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[batch_code] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[org_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_arwoedterr] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_arwoedterr] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_arwoedterr] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_arwoedterr] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_arwoedterr] TO [public]
GO
