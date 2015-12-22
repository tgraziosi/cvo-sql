CREATE TABLE [dbo].[rpt_seclog]
(
[entry_user] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[entry_date] [datetime] NOT NULL,
[message_text] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_seclog] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_seclog] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_seclog] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_seclog] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_seclog] TO [public]
GO
