CREATE TABLE [dbo].[CVO_OutOfStock_DailyReport_OLD]
(
[Type] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Category] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Model] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Color] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Size] [varchar] (9) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[PART_NO] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Next PO Confirm Date] [datetime] NULL,
[Orig Next PO Inhouse Date] [datetime] NULL,
[Next PO Inhouse Date] [datetime] NULL,
[Next PO] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Open Order Qty] [decimal] (38, 8) NULL,
[in_stock] [int] NULL,
[Avail] [decimal] (38, 8) NULL,
[AsOfDate] [datetime] NOT NULL,
[HIGHLIGHT] [varchar] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
