CREATE TABLE [dbo].[cvo_expo_order_sync]
(
[id] [int] NOT NULL IDENTITY(1, 1),
[expo_id] [int] NULL,
[attendee_id] [int] NULL,
[hs_order_no] [int] NULL,
[ship_to] [char] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[order_date] [datetime] NULL,
[pcs] [int] NULL,
[order_value] [float] NULL,
[added_date] [datetime] NULL,
[expo_terr] [char] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[hs_cust_id] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[cust_code] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[order_category] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[order_status] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[account_type] [char] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[cvo_expo_order_sync] ADD CONSTRAINT [PK__cvo_expo_order_s__1E6000F7] PRIMARY KEY CLUSTERED  ([id]) ON [PRIMARY]
GO
