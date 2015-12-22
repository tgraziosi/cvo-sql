CREATE TABLE [dbo].[rpt_ampostassetact]
(
[classification_id] [smallint] NULL,
[classification_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[book_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[account_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[account_reference_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[amount] [float] NULL,
[account_type_name] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[book_description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[trx_short_name] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[org_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[region_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_ampostassetact] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_ampostassetact] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_ampostassetact] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_ampostassetact] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_ampostassetact] TO [public]
GO
