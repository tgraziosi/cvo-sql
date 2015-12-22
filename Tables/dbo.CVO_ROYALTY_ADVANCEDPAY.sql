CREATE TABLE [dbo].[CVO_ROYALTY_ADVANCEDPAY]
(
[Yr] [int] NULL,
[Brand] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ItemType] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Period1] [decimal] (8, 2) NULL,
[Period2] [decimal] (8, 2) NULL,
[Period3] [decimal] (8, 2) NULL,
[Period4] [decimal] (8, 2) NULL
) ON [PRIMARY]
GO
GRANT VIEW DEFINITION ON  [dbo].[CVO_ROYALTY_ADVANCEDPAY] TO [public]
GO
GRANT REFERENCES ON  [dbo].[CVO_ROYALTY_ADVANCEDPAY] TO [public]
GO
GRANT SELECT ON  [dbo].[CVO_ROYALTY_ADVANCEDPAY] TO [public]
GO
GRANT INSERT ON  [dbo].[CVO_ROYALTY_ADVANCEDPAY] TO [public]
GO
GRANT DELETE ON  [dbo].[CVO_ROYALTY_ADVANCEDPAY] TO [public]
GO
GRANT UPDATE ON  [dbo].[CVO_ROYALTY_ADVANCEDPAY] TO [public]
GO
