CREATE TABLE [dbo].[cvo_eyerep_actshp_tbl]
(
[ship_id] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[acct_id] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ship_name] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ship_addr1] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ship_addr2] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ship_city] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ship_state] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ship_postal] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[default_shpmth] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[cvo_eyerep_actshp_tbl] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_eyerep_actshp_tbl] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_eyerep_actshp_tbl] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_eyerep_actshp_tbl] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_eyerep_actshp_tbl] TO [public]
GO
