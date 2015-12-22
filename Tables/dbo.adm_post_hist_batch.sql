CREATE TABLE [dbo].[adm_post_hist_batch]
(
[timestamp] [timestamp] NOT NULL,
[post_batch_id] [int] NOT NULL IDENTITY(1, 1),
[post_id] [int] NOT NULL,
[process_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[start_time] [datetime] NOT NULL CONSTRAINT [DF__adm_post___start__6ECC5B55] DEFAULT (getdate()),
[end_time] [datetime] NULL,
[num_processed] [int] NULL,
[ret_code] [smallint] NULL
) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [adm_post_hist_batch2] ON [dbo].[adm_post_hist_batch] ([post_id], [process_ctrl_num]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[adm_post_hist_batch] TO [public]
GO
GRANT SELECT ON  [dbo].[adm_post_hist_batch] TO [public]
GO
GRANT INSERT ON  [dbo].[adm_post_hist_batch] TO [public]
GO
GRANT DELETE ON  [dbo].[adm_post_hist_batch] TO [public]
GO
GRANT UPDATE ON  [dbo].[adm_post_hist_batch] TO [public]
GO
