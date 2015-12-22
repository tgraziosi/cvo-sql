CREATE TABLE [dbo].[CVO_nose_pad]
(
[timestamp] [timestamp] NOT NULL,
[kys] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[description] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[void] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[void_who] [char] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[void_date] [datetime] NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [idx_cvo_nose_pad_cmi] ON [dbo].[CVO_nose_pad] ([description], [kys]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [idx_CVO_nose_pad] ON [dbo].[CVO_nose_pad] ([kys]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[CVO_nose_pad] TO [public]
GO
GRANT SELECT ON  [dbo].[CVO_nose_pad] TO [public]
GO
GRANT INSERT ON  [dbo].[CVO_nose_pad] TO [public]
GO
GRANT DELETE ON  [dbo].[CVO_nose_pad] TO [public]
GO
GRANT UPDATE ON  [dbo].[CVO_nose_pad] TO [public]
GO
