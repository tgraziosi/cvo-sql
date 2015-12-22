CREATE TABLE [dbo].[cvo_arterr]
(
[territory_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[territory_desc] [varchar] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[cvo_arterr] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_arterr] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_arterr] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_arterr] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_arterr] TO [public]
GO
