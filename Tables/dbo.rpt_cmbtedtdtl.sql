CREATE TABLE [dbo].[rpt_cmbtedtdtl]
(
[seq_by] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[trx_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[err_code] [int] NOT NULL,
[line_num] [int] NOT NULL,
[refer_to] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[field] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[entry_type] [smallint] NOT NULL,
[entry_str] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[entry_amt] [float] NOT NULL,
[entry_qty] [float] NOT NULL,
[entry_long] [int] NOT NULL,
[entry_date] [int] NOT NULL,
[entry_short] [int] NOT NULL,
[err_type] [smallint] NOT NULL,
[err_desc] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_cmbtedtdtl] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_cmbtedtdtl] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_cmbtedtdtl] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_cmbtedtdtl] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_cmbtedtdtl] TO [public]
GO
