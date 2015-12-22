CREATE TABLE [dbo].[rpt_editlist]
(
[trx_ctrl_num] [char] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[refer_to] [char] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[field_desc] [char] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[err_type] [char] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[err_desc] [char] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[entry_type] [smallint] NOT NULL,
[entry_str] [char] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[entry_int] [int] NOT NULL,
[entry_float] [float] NOT NULL,
[entry_mask] [char] (35) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[entry_precision] [smallint] NOT NULL,
[entry_symbol] [char] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_editlist] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_editlist] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_editlist] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_editlist] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_editlist] TO [public]
GO
