CREATE TABLE [dbo].[cc_comments]
(
[comment_id] [int] NOT NULL,
[row_num] [int] NOT NULL,
[customer_code] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[user_name] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[comment_date] [datetime] NOT NULL,
[comments] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[log_type] [tinyint] NULL,
[doc_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[updated_comment_date] [datetime] NULL,
[updated_user_name] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[from_alerts] [smallint] NULL
) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [cc_comments_idx] ON [dbo].[cc_comments] ([comment_id], [row_num]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [cc_comments_idx_3] ON [dbo].[cc_comments] ([comment_id], [user_name]) ON [PRIMARY]
GO
CREATE CLUSTERED INDEX [cc_comments_idx_1] ON [dbo].[cc_comments] ([customer_code], [comment_id]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [cc_comments_idx_2] ON [dbo].[cc_comments] ([doc_ctrl_num]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[cc_comments] TO [public]
GO
GRANT SELECT ON  [dbo].[cc_comments] TO [public]
GO
GRANT INSERT ON  [dbo].[cc_comments] TO [public]
GO
GRANT DELETE ON  [dbo].[cc_comments] TO [public]
GO
GRANT UPDATE ON  [dbo].[cc_comments] TO [public]
GO
