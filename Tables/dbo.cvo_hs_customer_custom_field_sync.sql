CREATE TABLE [dbo].[cvo_hs_customer_custom_field_sync]
(
[account_no] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ship_to] [varchar] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[hs_obj_id] [bigint] NULL,
[accounttype] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[openAR] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Designations] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[LastSTDate] [datetime] NULL,
[last_sync_date] [datetime] NULL,
[sync_date] [datetime] NULL
) ON [PRIMARY]
GO
