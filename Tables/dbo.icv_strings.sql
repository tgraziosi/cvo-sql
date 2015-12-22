CREATE TABLE [dbo].[icv_strings]
(
[string_name] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[string_value] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[icv_strings] TO [public]
GO
GRANT SELECT ON  [dbo].[icv_strings] TO [public]
GO
GRANT INSERT ON  [dbo].[icv_strings] TO [public]
GO
GRANT DELETE ON  [dbo].[icv_strings] TO [public]
GO
GRANT UPDATE ON  [dbo].[icv_strings] TO [public]
GO
