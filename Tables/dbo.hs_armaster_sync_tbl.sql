CREATE TABLE [dbo].[hs_armaster_sync_tbl]
(
[timestamp] [timestamp] NULL,
[customer_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ship_to_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[contact_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[contact_phone] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[tlx_twx] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[contact_email] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[added_by_date] [datetime] NULL,
[sync_date] [datetime] NULL
) ON [PRIMARY]
GO
