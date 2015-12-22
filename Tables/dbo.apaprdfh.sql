CREATE TABLE [dbo].[apaprdfh]
(
[timestamp] [timestamp] NOT NULL,
[branch_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[vendor_code] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[amt_min] [float] NOT NULL,
[po_flag] [smallint] NOT NULL,
[vouch_flag] [smallint] NOT NULL,
[check_flag] [smallint] NOT NULL,
[approval_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[sequence_id] [int] NOT NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [apaprdfh_ind_0] ON [dbo].[apaprdfh] ([sequence_id]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[apaprdfh] TO [public]
GO
GRANT SELECT ON  [dbo].[apaprdfh] TO [public]
GO
GRANT INSERT ON  [dbo].[apaprdfh] TO [public]
GO
GRANT DELETE ON  [dbo].[apaprdfh] TO [public]
GO
GRANT UPDATE ON  [dbo].[apaprdfh] TO [public]
GO
