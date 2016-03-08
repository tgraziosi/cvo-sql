CREATE TABLE [dbo].[cvo_eyerep_biltrm_tbl]
(
[biltrm_id] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[biltrm_description] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[cvo_eyerep_biltrm_tbl] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_eyerep_biltrm_tbl] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_eyerep_biltrm_tbl] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_eyerep_biltrm_tbl] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_eyerep_biltrm_tbl] TO [public]
GO
