CREATE TABLE [dbo].[rpt_ib_rel]
(
[controlling_org_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[detail_org_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[num_mapping] [int] NOT NULL,
[num_taxrel] [int] NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_ib_rel] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_ib_rel] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_ib_rel] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_ib_rel] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_ib_rel] TO [public]
GO
