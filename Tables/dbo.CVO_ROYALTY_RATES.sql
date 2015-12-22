CREATE TABLE [dbo].[CVO_ROYALTY_RATES]
(
[Yr] [int] NULL,
[Brand] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Regular] [float] NULL,
[CL] [float] NULL,
[CLP20] [float] NULL,
[Intl] [float] NULL,
[Adver_PR] [float] NULL
) ON [PRIMARY]
GO
GRANT VIEW DEFINITION ON  [dbo].[CVO_ROYALTY_RATES] TO [public]
GO
GRANT REFERENCES ON  [dbo].[CVO_ROYALTY_RATES] TO [public]
GO
GRANT SELECT ON  [dbo].[CVO_ROYALTY_RATES] TO [public]
GO
GRANT INSERT ON  [dbo].[CVO_ROYALTY_RATES] TO [public]
GO
GRANT DELETE ON  [dbo].[CVO_ROYALTY_RATES] TO [public]
GO
GRANT UPDATE ON  [dbo].[CVO_ROYALTY_RATES] TO [public]
GO
