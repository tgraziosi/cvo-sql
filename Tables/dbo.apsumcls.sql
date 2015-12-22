CREATE TABLE [dbo].[apsumcls]
(
[timestamp] [timestamp] NOT NULL,
[class_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[date_from] [int] NOT NULL,
[date_thru] [int] NOT NULL,
[num_vouch] [int] NOT NULL,
[num_vouch_paid] [int] NOT NULL,
[num_dm] [int] NOT NULL,
[num_adj] [int] NOT NULL,
[num_pyt] [int] NOT NULL,
[num_overdue_pyt] [int] NOT NULL,
[num_void] [int] NOT NULL,
[amt_vouch] [float] NOT NULL,
[amt_dm] [float] NOT NULL,
[amt_adj] [float] NOT NULL,
[amt_pyt] [float] NOT NULL,
[amt_void] [float] NOT NULL,
[amt_disc_given] [float] NOT NULL,
[amt_disc_taken] [float] NOT NULL,
[amt_disc_lost] [float] NOT NULL,
[amt_freight] [float] NOT NULL,
[amt_tax] [float] NOT NULL,
[avg_days_pay] [int] NOT NULL,
[avg_days_overdue] [int] NOT NULL,
[last_trx_time] [int] NOT NULL,
[amt_vouch_oper] [float] NULL,
[amt_dm_oper] [float] NULL,
[amt_adj_oper] [float] NULL,
[amt_pyt_oper] [float] NULL,
[amt_void_oper] [float] NULL,
[amt_disc_given_oper] [float] NULL,
[amt_disc_taken_oper] [float] NULL,
[amt_disc_lost_oper] [float] NULL,
[amt_freight_oper] [float] NULL,
[amt_tax_oper] [float] NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [apsumcls_ind_0] ON [dbo].[apsumcls] ([class_code], [date_thru]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[apsumcls] TO [public]
GO
GRANT SELECT ON  [dbo].[apsumcls] TO [public]
GO
GRANT INSERT ON  [dbo].[apsumcls] TO [public]
GO
GRANT DELETE ON  [dbo].[apsumcls] TO [public]
GO
GRANT UPDATE ON  [dbo].[apsumcls] TO [public]
GO
