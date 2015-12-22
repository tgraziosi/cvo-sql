CREATE TABLE [dbo].[rpt_gltrial]
(
[timestamp] [timestamp] NOT NULL,
[account_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[account_description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[account_type] [smallint] NOT NULL,
[beginning_balance] [float] NOT NULL,
[ending_balance] [float] NOT NULL,
[prior_fiscal_balance] [float] NOT NULL,
[oper_beginning_balance] [float] NOT NULL,
[oper_ending_balance] [float] NOT NULL,
[oper_prior_fiscal_balance] [float] NOT NULL,
[trx_flag] [smallint] NOT NULL,
[dirty_post] [smallint] NOT NULL,
[changed_flag] [smallint] NOT NULL,
[seg1_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[seg2_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[seg3_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[seg4_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[org_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[region_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_gltrial] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_gltrial] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_gltrial] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_gltrial] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_gltrial] TO [public]
GO
