CREATE TABLE [dbo].[rpt_apcendet]
(
[timestamp] [timestamp] NOT NULL,
[cents_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[sequence_id] [int] NOT NULL,
[from_cent] [float] NOT NULL,
[to_cent] [float] NOT NULL,
[tax_cents] [float] NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [rpt_apcendet_idx_0] ON [dbo].[rpt_apcendet] ([cents_code], [sequence_id]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_apcendet] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_apcendet] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_apcendet] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_apcendet] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_apcendet] TO [public]
GO
