CREATE TABLE [dbo].[rpt_ib_map]
(
[controlling_org_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[detail_org_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[account_mask] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[recipient_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[originator_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_ib_map] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_ib_map] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_ib_map] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_ib_map] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_ib_map] TO [public]
GO
