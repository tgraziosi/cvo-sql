CREATE TABLE [dbo].[ardnmsdt]
(
[timestamp] [timestamp] NOT NULL,
[message_id] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[sequence_id] [int] NOT NULL,
[message_detail] [varchar] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[ardnmsdt] ADD CONSTRAINT [PK__ardnmsdt__59A25D33] PRIMARY KEY CLUSTERED  ([message_id], [sequence_id]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[ardnmsdt] TO [public]
GO
GRANT SELECT ON  [dbo].[ardnmsdt] TO [public]
GO
GRANT INSERT ON  [dbo].[ardnmsdt] TO [public]
GO
GRANT DELETE ON  [dbo].[ardnmsdt] TO [public]
GO
GRANT UPDATE ON  [dbo].[ardnmsdt] TO [public]
GO
