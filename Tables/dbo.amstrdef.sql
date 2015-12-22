CREATE TABLE [dbo].[amstrdef]
(
[str_id] [int] NOT NULL,
[str_seq_id] [int] NOT NULL,
[str_sdesc] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[str_text] [varchar] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [amstrdef_ind_0] ON [dbo].[amstrdef] ([str_id], [str_seq_id]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [amstrdef_ind_1] ON [dbo].[amstrdef] ([str_sdesc], [str_seq_id]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[amstrdef] TO [public]
GO
GRANT SELECT ON  [dbo].[amstrdef] TO [public]
GO
GRANT INSERT ON  [dbo].[amstrdef] TO [public]
GO
GRANT DELETE ON  [dbo].[amstrdef] TO [public]
GO
GRANT UPDATE ON  [dbo].[amstrdef] TO [public]
GO
