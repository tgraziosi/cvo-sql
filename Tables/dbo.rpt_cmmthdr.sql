CREATE TABLE [dbo].[rpt_cmmthdr]
(
[seq_by] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[trx_ctrl_num] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[err_code] [int] NOT NULL,
[refer_to] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[field] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[entry_type] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[entry_str] [varchar] (65) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[entry_amt] [int] NOT NULL,
[entry_qty] [int] NOT NULL,
[entry_long] [int] NOT NULL,
[entry_date] [int] NOT NULL,
[entry_short] [int] NOT NULL,
[err_type] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[err_desc] [varchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_cmmthdr] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_cmmthdr] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_cmmthdr] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_cmmthdr] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_cmmthdr] TO [public]
GO
