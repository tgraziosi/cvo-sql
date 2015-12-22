CREATE TABLE [dbo].[arstrdef]
(
[str_id] [int] NOT NULL,
[str_seq_id] [int] NOT NULL,
[str_sdesc] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[str_text] [varchar] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [arstrdef_ind_0] ON [dbo].[arstrdef] ([str_id], [str_seq_id]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [arstrdef_ind_1] ON [dbo].[arstrdef] ([str_sdesc], [str_seq_id]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[arstrdef] TO [public]
GO
GRANT SELECT ON  [dbo].[arstrdef] TO [public]
GO
GRANT INSERT ON  [dbo].[arstrdef] TO [public]
GO
GRANT DELETE ON  [dbo].[arstrdef] TO [public]
GO
GRANT UPDATE ON  [dbo].[arstrdef] TO [public]
GO
