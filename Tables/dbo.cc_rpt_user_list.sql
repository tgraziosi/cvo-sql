CREATE TABLE [dbo].[cc_rpt_user_list]
(
[my_id] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[user_name] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[cc_rpt_user_list] TO [public]
GO
GRANT SELECT ON  [dbo].[cc_rpt_user_list] TO [public]
GO
GRANT INSERT ON  [dbo].[cc_rpt_user_list] TO [public]
GO
GRANT DELETE ON  [dbo].[cc_rpt_user_list] TO [public]
GO
GRANT UPDATE ON  [dbo].[cc_rpt_user_list] TO [public]
GO
