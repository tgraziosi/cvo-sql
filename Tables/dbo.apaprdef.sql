CREATE TABLE [dbo].[apaprdef]
(
[timestamp] [timestamp] NOT NULL,
[branch_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[vendor_code] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[exp_acct_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[amt_min] [float] NOT NULL,
[po_flag] [smallint] NOT NULL,
[vouch_flag] [smallint] NOT NULL,
[check_flag] [smallint] NOT NULL,
[approval_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [apaprdef_ind_0] ON [dbo].[apaprdef] ([branch_code], [vendor_code], [exp_acct_code], [amt_min], [po_flag], [vouch_flag], [check_flag]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[apaprdef] TO [public]
GO
GRANT SELECT ON  [dbo].[apaprdef] TO [public]
GO
GRANT INSERT ON  [dbo].[apaprdef] TO [public]
GO
GRANT DELETE ON  [dbo].[apaprdef] TO [public]
GO
GRANT UPDATE ON  [dbo].[apaprdef] TO [public]
GO
