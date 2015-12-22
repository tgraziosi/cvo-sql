CREATE TABLE [dbo].[pr_config]
(
[item_name] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[text_value] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[int_value] [int] NULL,
[userid] [int] NOT NULL,
[sequence_id] [int] NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[pr_config] TO [public]
GO
GRANT SELECT ON  [dbo].[pr_config] TO [public]
GO
GRANT INSERT ON  [dbo].[pr_config] TO [public]
GO
GRANT DELETE ON  [dbo].[pr_config] TO [public]
GO
GRANT UPDATE ON  [dbo].[pr_config] TO [public]
GO
