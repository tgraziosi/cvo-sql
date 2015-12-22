CREATE TABLE [dbo].[ardnmshd]
(
[timestamp] [timestamp] NOT NULL,
[message_id] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[message_description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[ardnmshd] ADD CONSTRAINT [PK__ardnmshd__5B8AA5A5] PRIMARY KEY CLUSTERED  ([message_id]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[ardnmshd] TO [public]
GO
GRANT SELECT ON  [dbo].[ardnmshd] TO [public]
GO
GRANT INSERT ON  [dbo].[ardnmshd] TO [public]
GO
GRANT DELETE ON  [dbo].[ardnmshd] TO [public]
GO
GRANT UPDATE ON  [dbo].[ardnmshd] TO [public]
GO
