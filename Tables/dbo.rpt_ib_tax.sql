CREATE TABLE [dbo].[rpt_ib_tax]
(
[controlling_org_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[detail_org_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[trx_type] [int] NOT NULL,
[description] [varchar] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[tax_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_ib_tax] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_ib_tax] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_ib_tax] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_ib_tax] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_ib_tax] TO [public]
GO
