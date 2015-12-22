CREATE TABLE [dbo].[rpt_icvlog]
(
[entry_date] [datetime] NOT NULL,
[message_text] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_icvlog] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_icvlog] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_icvlog] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_icvlog] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_icvlog] TO [public]
GO
