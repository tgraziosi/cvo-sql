CREATE TABLE [dbo].[atmtcsts]
(
[status] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[status_desc] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[atmtcsts] TO [public]
GO
GRANT SELECT ON  [dbo].[atmtcsts] TO [public]
GO
GRANT INSERT ON  [dbo].[atmtcsts] TO [public]
GO
GRANT DELETE ON  [dbo].[atmtcsts] TO [public]
GO
GRANT UPDATE ON  [dbo].[atmtcsts] TO [public]
GO
