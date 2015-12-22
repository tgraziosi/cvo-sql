CREATE TABLE [dbo].[CVO_OutOfStock_DailyReportDIFFS]
(
[Movement] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Type] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Category] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Model] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Color] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Size] [varchar] (9) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[PART_NO] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Next PO Confirm Date] [datetime] NULL,
[Orig Next PO Inhouse Date] [datetime] NULL,
[Next PO Inhouse Date] [datetime] NULL,
[Next PO] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Open Order Qty] [decimal] (38, 8) NULL,
[in_stock] [int] NULL,
[Avail] [decimal] (38, 8) NULL,
[AsOfDate] [datetime] NULL,
[HIGHLIGHT] [varchar] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
