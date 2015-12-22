CREATE TABLE [dbo].[aptermsd]
(
[timestamp] [timestamp] NOT NULL,
[terms_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[sequence_id] [smallint] NOT NULL,
[discount_days] [smallint] NOT NULL,
[discount_prc] [float] NOT NULL,
[date_discount] [int] NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [aptermsd_ind_0] ON [dbo].[aptermsd] ([terms_code], [sequence_id]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[aptermsd] TO [public]
GO
GRANT SELECT ON  [dbo].[aptermsd] TO [public]
GO
GRANT INSERT ON  [dbo].[aptermsd] TO [public]
GO
GRANT DELETE ON  [dbo].[aptermsd] TO [public]
GO
GRANT UPDATE ON  [dbo].[aptermsd] TO [public]
GO
