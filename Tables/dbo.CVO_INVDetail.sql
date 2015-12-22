CREATE TABLE [dbo].[CVO_INVDetail]
(
[DocumentReferenceID] [varchar] (128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SequenceID] [int] NULL,
[Location] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ItemCode] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DateEntered] [varchar] (19) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[LineDescription] [varchar] (60) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[QtyOrdered] [float] NULL,
[QtyShipped] [float] NULL,
[SalesUOMCode] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[UnitPrice] [float] NULL,
[Weight] [float] NULL,
[TaxCode] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[GLRevAccount] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DiscPrcFlag] [smallint] NULL,
[AmountDiscount] [float] NULL,
[ReturnCode] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[QtyReturned] [float] NULL,
[DiscPrc] [float] NULL,
[ExtendedPrice] [float] NULL,
[GLReferenceCode] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[OEFlag] [int] NULL,
[CustomerPO] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[OrganizationID] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[CVO_INVDetail] TO [public]
GO
GRANT INSERT ON  [dbo].[CVO_INVDetail] TO [public]
GO
GRANT DELETE ON  [dbo].[CVO_INVDetail] TO [public]
GO
GRANT UPDATE ON  [dbo].[CVO_INVDetail] TO [public]
GO
