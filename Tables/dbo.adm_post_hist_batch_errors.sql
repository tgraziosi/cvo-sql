CREATE TABLE [dbo].[adm_post_hist_batch_errors]
(
[timestamp] [timestamp] NOT NULL,
[post_batch_err_id] [int] NOT NULL IDENTITY(1, 1),
[post_batch_id] [int] NOT NULL,
[order_no] [int] NOT NULL,
[order_ext] [int] NOT NULL,
[module_id] [smallint] NULL,
[err_code] [int] NULL,
[info1] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[info2] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[infoint] [int] NULL,
[infofloat] [float] NULL,
[flag1] [smallint] NULL,
[trx_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[sequence_id] [int] NULL,
[source_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[extra] [int] NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[adm_post_hist_batch_errors] TO [public]
GO
GRANT SELECT ON  [dbo].[adm_post_hist_batch_errors] TO [public]
GO
GRANT INSERT ON  [dbo].[adm_post_hist_batch_errors] TO [public]
GO
GRANT DELETE ON  [dbo].[adm_post_hist_batch_errors] TO [public]
GO
GRANT UPDATE ON  [dbo].[adm_post_hist_batch_errors] TO [public]
GO
