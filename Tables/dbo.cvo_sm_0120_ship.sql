CREATE TABLE [dbo].[cvo_sm_0120_ship]
(
[po_key] [int] NULL,
[po_type] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[po_date] [datetime] NULL,
[vendor] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[line] [int] NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[part_no] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[description] [varchar] (60) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[qty1] [int] NULL,
[shipped_0120] [int] NULL
) ON [PRIMARY]
GO
