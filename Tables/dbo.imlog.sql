CREATE TABLE [dbo].[imlog]
(
[now] [datetime] NULL CONSTRAINT [DF__imlog__now__699B2FDF] DEFAULT (getdate()),
[module] [char] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[rectype] [int] NULL,
[key1] [char] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[key2] [char] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[key3] [char] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[text] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[User_ID] [int] NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[imlog] TO [public]
GO
GRANT SELECT ON  [dbo].[imlog] TO [public]
GO
GRANT INSERT ON  [dbo].[imlog] TO [public]
GO
GRANT DELETE ON  [dbo].[imlog] TO [public]
GO
GRANT UPDATE ON  [dbo].[imlog] TO [public]
GO
