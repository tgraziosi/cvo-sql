CREATE TABLE [dbo].[CVO_crhold]
(
[timestamp] [timestamp] NOT NULL,
[hold_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[hold_reason] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [CVO_crhold_pk] ON [dbo].[CVO_crhold] ([hold_code]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[CVO_crhold] TO [public]
GO
GRANT SELECT ON  [dbo].[CVO_crhold] TO [public]
GO
GRANT INSERT ON  [dbo].[CVO_crhold] TO [public]
GO
GRANT DELETE ON  [dbo].[CVO_crhold] TO [public]
GO
GRANT UPDATE ON  [dbo].[CVO_crhold] TO [public]
GO
