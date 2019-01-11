CREATE TABLE [dbo].[cvo_sunps_2018_hs]
(
[hs_order_no] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[order_date] [datetime] NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [idx_main] ON [dbo].[cvo_sunps_2018_hs] ([hs_order_no]) ON [PRIMARY]
GO
GRANT DELETE ON  [dbo].[cvo_sunps_2018_hs] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_sunps_2018_hs] TO [public]
GO
GRANT REFERENCES ON  [dbo].[cvo_sunps_2018_hs] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_sunps_2018_hs] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_sunps_2018_hs] TO [public]
GO
