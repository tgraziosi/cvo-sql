CREATE TABLE [dbo].[im_config]
(
[Item Name] [varchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Text Value] [nvarchar] (1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[INT Value] [int] NULL
) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [im_config Index 1] ON [dbo].[im_config] ([Item Name], [INT Value]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[im_config] TO [public]
GO
GRANT SELECT ON  [dbo].[im_config] TO [public]
GO
GRANT INSERT ON  [dbo].[im_config] TO [public]
GO
GRANT DELETE ON  [dbo].[im_config] TO [public]
GO
GRANT UPDATE ON  [dbo].[im_config] TO [public]
GO
