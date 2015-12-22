CREATE TABLE [dbo].[ttarnarl]
(
[timestamp] [timestamp] NOT NULL,
[new] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[parent] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[child] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[relation_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [ttarnarl_ind_0] ON [dbo].[ttarnarl] ([relation_code], [parent], [child]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[ttarnarl] TO [public]
GO
GRANT SELECT ON  [dbo].[ttarnarl] TO [public]
GO
GRANT INSERT ON  [dbo].[ttarnarl] TO [public]
GO
GRANT DELETE ON  [dbo].[ttarnarl] TO [public]
GO
GRANT UPDATE ON  [dbo].[ttarnarl] TO [public]
GO
