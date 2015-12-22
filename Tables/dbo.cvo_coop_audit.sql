CREATE TABLE [dbo].[cvo_coop_audit]
(
[customer_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[from_dollars] [decimal] (20, 8) NULL,
[to_dollars] [decimal] (20, 8) NULL,
[from_ytd] [decimal] (20, 8) NULL,
[to_ytd] [decimal] (20, 8) NULL,
[add_date] [datetime] NULL,
[add_user] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[cvo_coop_audit] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_coop_audit] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_coop_audit] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_coop_audit] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_coop_audit] TO [public]
GO
