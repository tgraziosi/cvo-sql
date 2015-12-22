CREATE TABLE [dbo].[cvo_programsxref]
(
[Year] [float] NULL,
[Dates] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Order Type] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SKU] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Count Check] [float] NULL,
[DESCRIPTION] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Epicor Order Type] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Epicor Promo_ID] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Epicor Promo_Level] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[cvo_programsxref] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_programsxref] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_programsxref] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_programsxref] TO [public]
GO
