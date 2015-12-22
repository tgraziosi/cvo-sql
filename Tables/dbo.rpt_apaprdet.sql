CREATE TABLE [dbo].[rpt_apaprdet]
(
[timestamp] [timestamp] NOT NULL,
[approval_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[user_name] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[amt_min] [float] NOT NULL,
[amt_max] [float] NOT NULL,
[sequence_id] [int] NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [rpt_apaprdet_idx_0] ON [dbo].[rpt_apaprdet] ([approval_code], [sequence_id]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_apaprdet] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_apaprdet] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_apaprdet] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_apaprdet] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_apaprdet] TO [public]
GO
