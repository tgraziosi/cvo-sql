CREATE TABLE [dbo].[tdc_tx_print_routing_bkup]
(
[module] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[trans] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[trans_source] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[format_id] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[user_station_id] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[printer] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[quantity] [int] NULL
) ON [PRIMARY]
GO
