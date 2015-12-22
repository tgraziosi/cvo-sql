CREATE TABLE [dbo].[cc_followups]
(
[customer_code] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[comment_id] [int] NOT NULL,
[followup_date] [smalldatetime] NULL,
[priority] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [cc_followups_idx] ON [dbo].[cc_followups] ([customer_code]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[cc_followups] TO [public]
GO
GRANT SELECT ON  [dbo].[cc_followups] TO [public]
GO
GRANT INSERT ON  [dbo].[cc_followups] TO [public]
GO
GRANT DELETE ON  [dbo].[cc_followups] TO [public]
GO
GRANT UPDATE ON  [dbo].[cc_followups] TO [public]
GO
