CREATE TABLE [dbo].[ntdocs]
(
[user_name] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[doc_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[trx_type] [smallint] NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[ntdocs] TO [public]
GO
GRANT SELECT ON  [dbo].[ntdocs] TO [public]
GO
GRANT INSERT ON  [dbo].[ntdocs] TO [public]
GO
GRANT DELETE ON  [dbo].[ntdocs] TO [public]
GO
GRANT UPDATE ON  [dbo].[ntdocs] TO [public]
GO
