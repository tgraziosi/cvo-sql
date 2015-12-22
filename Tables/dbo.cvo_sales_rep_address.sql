CREATE TABLE [dbo].[cvo_sales_rep_address]
(
[territory] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[salesperson_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[slp_email] [varchar] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[addr1] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[addr2] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[addr3] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[addr4] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ship_via] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[city] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[state] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[zipcode] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
