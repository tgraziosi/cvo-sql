CREATE TABLE [dbo].[arcendet]
(
[timestamp] [timestamp] NOT NULL,
[cents_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[sequence_id] [int] NOT NULL,
[from_cent] [float] NOT NULL,
[to_cent] [float] NOT NULL,
[tax_cents] [float] NOT NULL
) ON [PRIMARY]
GO
CREATE CLUSTERED INDEX [arcendet_ind_0] ON [dbo].[arcendet] ([cents_code], [sequence_id]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[arcendet] TO [public]
GO
GRANT SELECT ON  [dbo].[arcendet] TO [public]
GO
GRANT INSERT ON  [dbo].[arcendet] TO [public]
GO
GRANT DELETE ON  [dbo].[arcendet] TO [public]
GO
GRANT UPDATE ON  [dbo].[arcendet] TO [public]
GO
