CREATE TABLE [dbo].[CVO_INVCommission]
(
[DocumentReferenceID] [varchar] (128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SequenceID] [int] NULL,
[SalesPersonCode] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CommissionAmount] [float] NULL,
[PercentFlag] [smallint] NULL,
[ExclusiveFlag] [smallint] NULL,
[SplitFlag] [smallint] NULL
) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[CVO_INVCommission] TO [public]
GO
GRANT INSERT ON  [dbo].[CVO_INVCommission] TO [public]
GO
GRANT DELETE ON  [dbo].[CVO_INVCommission] TO [public]
GO
GRANT UPDATE ON  [dbo].[CVO_INVCommission] TO [public]
GO
