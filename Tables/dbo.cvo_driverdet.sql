CREATE TABLE [dbo].[cvo_driverdet]
(
[row] [int] NOT NULL IDENTITY(1, 1),
[ter] [nvarchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[MC] [nvarchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[JAN] [float] NULL,
[FEB] [float] NULL,
[MAR] [float] NULL,
[APR] [float] NULL,
[MAY] [float] NULL,
[JUN] [float] NULL,
[JUL] [float] NULL,
[AUG] [float] NULL,
[SEP] [float] NULL,
[OCT] [float] NULL,
[NOV] [float] NULL,
[DEC] [float] NULL,
[YTD] [float] NULL
) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[cvo_driverdet] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_driverdet] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_driverdet] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_driverdet] TO [public]
GO
