CREATE TABLE [dbo].[cvo_tmp_sku_gen]
(
[id] [int] NOT NULL IDENTITY(1, 1),
[date_added] [datetime] NULL,
[collection] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[model] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[part_type] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[colorname] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[eye_size] [decimal] (20, 8) NULL,
[data] [varchar] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[message_desc] [varchar] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[severity] [varchar] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
