CREATE TABLE [dbo].[CVO_PO_AUDIT]
(
[field_name] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[field_from] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[field_to] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[po_no] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[po_line] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[modified_date] [datetime] NULL,
[modified_by] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
