CREATE TABLE [dbo].[rpt_arrecontotal]
(
[account_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[account_description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ar_activity_tot] [float] NOT NULL,
[gl_activity_tot] [float] NOT NULL,
[org_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[region_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[symbol] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_arrecontotal] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_arrecontotal] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_arrecontotal] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_arrecontotal] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_arrecontotal] TO [public]
GO
