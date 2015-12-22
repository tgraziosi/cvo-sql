CREATE TABLE [dbo].[glautxtp]
(
[aust_tax_type] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[description] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[glautxtp] TO [public]
GO
GRANT SELECT ON  [dbo].[glautxtp] TO [public]
GO
GRANT INSERT ON  [dbo].[glautxtp] TO [public]
GO
GRANT DELETE ON  [dbo].[glautxtp] TO [public]
GO
GRANT UPDATE ON  [dbo].[glautxtp] TO [public]
GO
