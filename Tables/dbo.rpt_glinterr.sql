CREATE TABLE [dbo].[rpt_glinterr]
(
[int_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[int_line_id] [int] NOT NULL,
[error_desc] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[src_trx_id] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[src_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[src_line_id] [int] NOT NULL,
[err_code] [int] NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_glinterr] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_glinterr] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_glinterr] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_glinterr] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_glinterr] TO [public]
GO
