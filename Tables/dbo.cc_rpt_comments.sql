CREATE TABLE [dbo].[cc_rpt_comments]
(
[customer_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[comment] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[cc_rpt_comments] TO [public]
GO
GRANT SELECT ON  [dbo].[cc_rpt_comments] TO [public]
GO
GRANT INSERT ON  [dbo].[cc_rpt_comments] TO [public]
GO
GRANT DELETE ON  [dbo].[cc_rpt_comments] TO [public]
GO
GRANT UPDATE ON  [dbo].[cc_rpt_comments] TO [public]
GO
