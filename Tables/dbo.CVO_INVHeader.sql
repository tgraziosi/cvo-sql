CREATE TABLE [dbo].[CVO_INVHeader]
(
[DocumentReferenceID] [varchar] (128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DocumentType] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DocDescription] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ApplyToControlNum] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[OrderControlNum] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DateEntered] [varchar] (19) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DateApply] [varchar] (19) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DateDocument] [varchar] (19) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DateShipped] [varchar] (19) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DateRequired] [varchar] (19) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DateDue] [varchar] (19) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DateAging] [varchar] (19) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CustomerCode] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ShipToCode] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SalesPersonCode] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[TerritoryCode] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CommentCode] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[FobCode] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[FreightCode] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[TermsCode] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[FinChargeCode] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[PriceCode] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DestZoneCode] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[PostingCode] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[RecurringFlag] [smallint] NULL,
[RecurringCode] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CustomerPO] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[TaxCode] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[TotalWeight] [float] NULL,
[AmountFreight] [float] NULL,
[HoldFlag] [smallint] NULL,
[HoldDescription] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CustomerAddress1] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CustomerAddress2] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CustomerAddress3] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CustomerAddress4] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CustomerAddress5] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CustomerAddress6] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ShipToAddress1] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ShipToAddress2] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ShipToAddress3] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ShipToAddress4] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ShipToAddress5] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ShipToAddress6] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[AttentionName] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[AttentionPhone] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SourceControlNumber] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[TransactionalCurrency] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[HomeRateType] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[OperationalRateType] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[HomeRate] [float] NULL,
[OperationalRate] [float] NULL,
[HomeRateOperator] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[OperationalRateOperator] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[TaxCalculatedMode] [smallint] NULL,
[PrintedFlag] [smallint] NULL,
[OrganizationID] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[CVO_INVHeader] TO [public]
GO
GRANT INSERT ON  [dbo].[CVO_INVHeader] TO [public]
GO
GRANT DELETE ON  [dbo].[CVO_INVHeader] TO [public]
GO
GRANT UPDATE ON  [dbo].[CVO_INVHeader] TO [public]
GO
