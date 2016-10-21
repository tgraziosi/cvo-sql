CREATE TABLE [dbo].[cvo_po_activity_log]
(
[id] [int] NOT NULL IDENTITY(1, 1),
[activity_date] [datetime] NULL,
[vendor_id] [int] NULL,
[po_no] [int] NULL,
[brand] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[model] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[stage] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[entity] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[euser] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[comment] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[response] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[release_date] [datetime] NULL,
[activity] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
