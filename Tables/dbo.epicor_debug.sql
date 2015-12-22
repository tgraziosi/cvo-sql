CREATE TABLE [dbo].[epicor_debug]
(
[strvalue] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[testvalue] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[epicor_debug] TO [public]
GO
GRANT SELECT ON  [dbo].[epicor_debug] TO [public]
GO
GRANT INSERT ON  [dbo].[epicor_debug] TO [public]
GO
GRANT DELETE ON  [dbo].[epicor_debug] TO [public]
GO
GRANT UPDATE ON  [dbo].[epicor_debug] TO [public]
GO
