CREATE TABLE [dbo].[cvo_eyerep_actext_tbl]
(
[acct_id] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[field_name] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[field_value] [varchar] (200) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[display_order] [int] NULL,
[rep_id] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[cvo_eyerep_actext_tbl] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_eyerep_actext_tbl] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_eyerep_actext_tbl] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_eyerep_actext_tbl] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_eyerep_actext_tbl] TO [public]
GO
